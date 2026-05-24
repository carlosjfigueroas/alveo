import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/company.dart';
import '../models/payment.dart';
import 'company_service.dart';

class SubscriptionService {
  final SupabaseClient _client = Supabase.instance.client;

  // ─── LÓGICA DE CRON MANUAL ──────────────────────────────────────────────
  Future<void> checkAndUpdateSubscriptions() async {
    final response = await _client.from('companies').select();
    final companies = (response as List).map((json) => Company.fromJson(json)).toList();

    for (final company in companies) {
      if (company.subscriptionStatus == 'trial') {
        if (company.trialEndsAt != null && company.trialEndsAt!.isBefore(DateTime.now())) {
          await suspendCompany(company.id);
        }
      } else if (company.subscriptionStatus == 'active') {
        if (company.subscriptionEndsAt != null && company.subscriptionEndsAt!.isBefore(DateTime.now())) {
          if (company.graceEndsAt != null && company.graceEndsAt!.isBefore(DateTime.now())) {
            await suspendCompany(company.id);
          } else if (company.graceEndsAt == null) {
            await _client.from('companies').update({
              'grace_ends_at': company.subscriptionEndsAt!.add(const Duration(days: 5)).toIso8601String(),
            }).eq('id', company.id);
          }
        }
      }
    }
  }

  Future<void> reportPayment({
    required String companyId,
    required String reference,
    required String billingCycle,
    required double amount,
    String? receiptUrl,
    String? notes,
  }) async {
    // Calcular periodos basados en el ciclo
    final now = DateTime.now();
    DateTime start = now;
    
    // Si la empresa ya tiene una suscripción activa que no ha vencido, el nuevo periodo empieza cuando vence la actual
    final companyRaw = await _client.from('companies').select('subscription_ends_at, subscription_status').eq('id', companyId).single();
    if (companyRaw['subscription_status'] == 'active' && companyRaw['subscription_ends_at'] != null) {
      final currentEnd = DateTime.parse(companyRaw['subscription_ends_at']);
      if (currentEnd.isAfter(now)) {
        start = currentEnd;
      }
    }

    final end = billingCycle == 'annual' 
        ? start.add(const Duration(days: 365)) 
        : start.add(const Duration(days: 30));

    await _client.from('payments').insert({
      'company_id': companyId,
      'amount': amount,
      'billing_cycle': billingCycle,
      'period_start': start.toIso8601String().split('T')[0],
      'period_end': end.toIso8601String().split('T')[0],
      'status': 'pending',
      'reference': reference,
      'notes': notes,
      'receipt_url': receiptUrl,
      'payment_method': 'bank_transfer',
    });

    // Notificar al Super Admin vía Edge Function (opcional, pero buena práctica)
    try {
      await _client.functions.invoke('send-subscription-email', body: {
        'type': 'payment_reported',
        'company_id': companyId,
      });
    } catch (e) {
      debugPrint('Error sending reported payment email: $e');
    }
  }

  Future<void> approvePayment(String paymentId) async {
    // 1. Obtener los datos del pago
    final paymentRaw = await _client.from('payments').select().eq('id', paymentId).single();
    final payment = Payment.fromJson(paymentRaw);
    final String companyId = payment.companyId;

    // 2. Usar la lógica existente de confirmPayment pero adaptada al ID existente
    // Reutilizamos la lógica de comisiones y activación de confirmPayment
    
    // 2.1 Actualizar el pago a confirmado
    await _client.from('payments').update({
      'status': 'confirmed',
      'confirmed_by': _client.auth.currentUser?.email ?? 'Super Admin',
      'confirmed_at': DateTime.now().toIso8601String(),
    }).eq('id', paymentId);

    // 2.2 Manejar Comisiones
    final companyRaw = await _client.from('companies').select().eq('id', companyId).single();
    final company = Company.fromJson(companyRaw);
    final strategy = await CompanyService.getActiveStrategy();

    if (strategy == 'strategy_2' && company.acquisitionChannel == 'salesperson' && company.referredBySalesperson != null) {
      final salesperson = await _client.from('salespersons')
          .select()
          .eq('alias', company.referredBySalesperson!)
          .maybeSingle();

      if (salesperson != null) {
        final double pct = (salesperson['commission_pct'] as num).toDouble();
        final double earning = payment.amount * (pct / 100.0);

        await _client.from('commissions').insert({
          'salesperson_id': salesperson['id'],
          'company_id': companyId,
          'payment_id': paymentId,
          'amount': earning,
          'status': 'pending',
        });
      }
    }

    // 2.3 Activar la empresa
    await _client.from('companies').update({
      'subscription_status': 'active',
      'subscription_starts_at': payment.periodStart.toIso8601String(),
      'subscription_ends_at': payment.periodEnd.toIso8601String(),
      'suspended_at': null,
      'grace_ends_at': null,
    }).eq('id', companyId);

    // 2.4 Activar referidos
    await activateReferral(companyId);

    // 2.5 Email de confirmación
    try {
      await _client.functions.invoke('send-subscription-email', body: {
        'type': 'payment_confirmed',
        'company_id': companyId,
      });
    } catch (e) {
      debugPrint('Error sending confirmation email: $e');
    }
  }

  Future<void> rejectPayment(String paymentId) async {
    // 1. Obtener el ID de la empresa antes de actualizar
    final paymentRaw = await _client.from('payments').select('company_id').eq('id', paymentId).single();
    final String companyId = paymentRaw['company_id'];

    // 2. Actualizar el pago a rechazado
    await _client.from('payments').update({
      'status': 'rejected',
      'confirmed_by': _client.auth.currentUser?.email ?? 'Super Admin',
      'confirmed_at': DateTime.now().toIso8601String(),
    }).eq('id', paymentId);

    // 3. Notificar al cliente vía Edge Function
    try {
      await _client.functions.invoke('send-subscription-email', body: {
        'type': 'payment_rejected',
        'company_id': companyId,
      });
    } catch (e) {
      debugPrint('Error sending rejection email: $e');
    }
  }

  Future<List<Payment>> getPendingPayments() async {
    final response = await _client.from('payments').select('*, companies(name)')
        .eq('status', 'pending')
        .order('created_at', ascending: false);
    return (response as List).map((json) => Payment.fromJson(json)).toList();
  }

  // ─── ACCIONES DE SUPER ADMIN ────────────────────────────────────────────
  Future<void> confirmPayment({
    required String companyId,
    required double amount,
    required String reference,
    required DateTime periodStart,
    required DateTime periodEnd,
    required String billingCycle,
    String? notes,
  }) async {
    // 0. Obtener info de la empresa para comisiones
    final companyRaw = await _client.from('companies').select().eq('id', companyId).single();
    final company = Company.fromJson(companyRaw);
    final strategy = await CompanyService.getActiveStrategy();

    // 1. Crear el pago
    final paymentRes = await _client.from('payments').insert({
      'company_id': companyId,
      'amount': amount,
      'billing_cycle': billingCycle,
      'period_start': periodStart.toIso8601String().split('T')[0],
      'period_end': periodEnd.toIso8601String().split('T')[0],
      'status': 'confirmed',
      'reference': reference,
      'notes': notes,
      'confirmed_by': _client.auth.currentUser?.email ?? 'Super Admin',
      'confirmed_at': DateTime.now().toIso8601String(),
    }).select().single();

    // 2. Manejar Comisiones (Estrategia 2 + Vendedor)
    if (strategy == 'strategy_2' && company.acquisitionChannel == 'salesperson' && company.referredBySalesperson != null) {
      final salesperson = await _client.from('salespersons')
          .select()
          .eq('alias', company.referredBySalesperson!)
          .maybeSingle();

      if (salesperson != null) {
        final double pct = (salesperson['commission_pct'] as num).toDouble();
        final double earning = amount * (pct / 100.0);

        await _client.from('commissions').insert({
          'salesperson_id': salesperson['id'],
          'company_id': companyId,
          'payment_id': paymentRes['id'],
          'amount': earning,
          'status': 'pending',
        });
      }
    }

    // 3. Activar la empresa
    await _client.from('companies').update({
      'subscription_status': 'active',
      'subscription_starts_at': periodStart.toIso8601String(),
      'subscription_ends_at': periodEnd.toIso8601String(),
      'suspended_at': null,
      'grace_ends_at': null,
    }).eq('id', companyId);

    // 4. Activar posibles referidos pendientes y recalcular
    await activateReferral(companyId);

    // 5. Invocar Edge Function de email (pago confirmado)
    try {
      await _client.functions.invoke('send-subscription-email', body: {
        'type': 'payment_confirmed',
        'company_id': companyId,
      });
    } catch (e) {
      debugPrint('Error sending payment email: $e');
    }
  }

  Future<void> suspendCompany(String companyId) async {
    await _client.from('companies').update({
      'subscription_status': 'suspended',
      'suspended_at': DateTime.now().toIso8601String(),
    }).eq('id', companyId);
    
    try {
      await _client.functions.invoke('send-subscription-email', body: {
        'type': 'suspended',
        'company_id': companyId,
      });
    } catch (e) {
      debugPrint('Error sending suspension email: $e');
    }
  }

  Future<void> reactivateCompany(String companyId) async {
    await _client.from('companies').update({
      'subscription_status': 'active',
      'suspended_at': null,
      'grace_ends_at': null,
    }).eq('id', companyId);

    try {
      await _client.functions.invoke('send-subscription-email', body: {
        'type': 'reactivated',
        'company_id': companyId,
      });
    } catch (e) {
      debugPrint('Error sending reactivation email: $e');
    }
  }

  // ─── SISTEMA DE REFERIDOS ──────────────────────────────────────────────
  Future<String?> resolveReferralByEmail(String email) async {
    final response = await _client.from('companies').select('id').eq('contact_email', email).maybeSingle();
    return response?['id'] as String?;
  }

  Future<void> activateReferral(String referredCompanyId) async {
    final res = await _client.from('referrals').select()
      .eq('referred_company_id', referredCompanyId)
      .eq('status', 'pending')
      .maybeSingle();
      
    if (res != null) {
      final String referrerCompanyId = res['referrer_company_id'];
      final strategy = await CompanyService.getActiveStrategy();
      
      await _client.from('referrals').update({
        'status': 'active',
        'activated_at': DateTime.now().toIso8601String(),
      }).eq('id', res['id']);
      
      if (strategy == 'strategy_1') {
        await recalcReferralDiscount(referrerCompanyId);
      } else if (strategy == 'strategy_3') {
        await recalcReferralStrategy3(referrerCompanyId);
      } else {
        await recalcReferralCapacity(referrerCompanyId);
      }

      try {
        await _client.functions.invoke('send-subscription-email', body: {
          'type': 'referral_activated',
          'company_id': referrerCompanyId,
        });
      } catch (e) {
        debugPrint('Error sending referral email: $e');
      }
    }
  }

  Future<void> recalcReferralDiscount(String companyId) async {
    final res = await _client.from('referrals').select('id')
      .eq('referrer_company_id', companyId)
      .eq('status', 'active');
      
    final int activeCount = (res as List).length;
    final double discount = activeCount * 1.0; 

    await _client.from('companies').update({
      'referral_discount': discount,
      'referral_bonus_photos': 0, // Reset in S1
      'referral_bonus_properties': 0,
    }).eq('id', companyId);
  }

  Future<void> recalcReferralCapacity(String companyId) async {
    final res = await _client.from('referrals').select('id')
      .eq('referrer_company_id', companyId)
      .eq('status', 'active');
      
    final int activeCount = (res as List).length;
    
    // +2 fotos y +2 inmuebles por cada referido
    await _client.from('companies').update({
      'referral_discount': 0.0, // Reset in S2
      'referral_bonus_photos': activeCount * 2,
      'referral_bonus_properties': activeCount * 2,
    }).eq('id', companyId);
  }

  Future<void> recalcReferralStrategy3(String companyId) async {
    final res = await _client.from('referrals').select('id')
      .eq('referrer_company_id', companyId)
      .eq('status', 'active');
      
    final int activeCount = (res as List).length;
    final double discount = activeCount * 1.0; 
    
    // Strategy 3: +2 inmuebles, +2 fotos Y $1.00 de descuento
    await _client.from('companies').update({
      'referral_discount': discount,
      'referral_bonus_photos': activeCount * 2,
      'referral_bonus_properties': activeCount * 2,
    }).eq('id', companyId);
  }

  // ─── AVISOS POR LOTE ──────────────────────────────────────────────────
  Future<void> sendReminderToAll(int daysBeforeExpiry) async {
    final targetDate = DateTime.now().add(Duration(days: daysBeforeExpiry));
    final response = await _client.from('companies').select('id, subscription_ends_at')
      .eq('subscription_status', 'active')
      .not('subscription_ends_at', 'is', null);

    final companies = (response as List).map((json) => Company.fromJson(json)).toList();

    for (final company in companies) {
      if (company.subscriptionEndsAt != null) {
        final diff = company.subscriptionEndsAt!.difference(DateTime.now()).inDays;
        if (diff == daysBeforeExpiry) {
           try {
             await _client.functions.invoke('send-subscription-email', body: {
               'type': 'payment_reminder',
               'company_id': company.id,
             });
           } catch (e) {
             debugPrint('Error sending reminder email to ${company.id}: $e');
           }
        }
      }
    }
  }

  Future<List<Payment>> getCompanyPayments(String companyId) async {
    final response = await _client.from('payments').select()
        .eq('company_id', companyId)
        .order('created_at', ascending: false);
    return (response as List).map((json) => Payment.fromJson(json)).toList();
  }

  Future<List<Payment>> getAllPayments() async {
    final response = await _client.from('payments').select()
        .order('created_at', ascending: false);
    return (response as List).map((json) => Payment.fromJson(json)).toList();
  }

  Future<Map<String, dynamic>> getBillingMetrics() async {
    // 1. Obtener todas las empresas para contar estados y calcular MRR potencial
    final companiesRes = await _client.from('companies').select('subscription_status, base_price, referral_discount, billing_cycle');
    final companies = companiesRes as List;

    int active = 0;
    int trial = 0;
    int suspended = 0;
    double potentialMrr = 0;

    for (final c in companies) {
      final status = c['subscription_status'];
      final basePrice = (c['base_price'] as num).toDouble();
      final discount = (c['referral_discount'] as num).toDouble();
      final effective = (basePrice - discount).clamp(basePrice * 0.75, double.infinity);
      final cycle = c['billing_cycle'];

      if (status == 'active') {
        active++;
        potentialMrr += (cycle == 'annual' ? effective / 12 : effective);
      } else if (status == 'trial') {
        trial++;
      } else if (status == 'suspended') {
        suspended++;
      }
    }

    // 2. Obtener pagos confirmados en los últimos 30 días para MRR Real
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30)).toIso8601String();
    final paymentsRes = await _client.from('payments')
        .select('amount')
        .eq('status', 'confirmed')
        .gte('confirmed_at', thirtyDaysAgo);
    
    double realMrr = 0;
    for (final p in (paymentsRes as List)) {
      realMrr += (p['amount'] as num).toDouble();
    }

    // 3. Pagos pendientes por revisar
    final pendingRes = await _client.from('payments').select('id').eq('status', 'pending');
    final pendingCount = (pendingRes as List).length;

    return {
      'active_subscribers': active,
      'trial_users': trial,
      'suspended_users': suspended,
      'potential_mrr': potentialMrr,
      'real_mrr_30d': realMrr,
      'pending_approvals': pendingCount,
    };
  }
}
