import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/company.dart';

class CompanyService {
  static final SupabaseClient _client = Supabase.instance.client;
  static const _bucket = 'property-images';

  static Future<Company> detectCompany() async {
    String host = kIsWeb ? Uri.base.host : 'alveo-demo.web.app';
    
    // Normalizar host: quitar www. para facilitar el match
    if (host.startsWith('www.')) {
      host = host.substring(4);
    }

    // Si estamos en el dominio raíz sin subdominio, redireccionar a www.demo.alveo.fyi (Regla #8)
    if (kIsWeb && (host == 'alveo.fyi')) host = 'demo.alveo.fyi';

    final globalLimits = await getGlobalLimits();

    // Si estamos en el demo oficial o localhost, cargar modo demo
    if (host == 'demo.alveo.fyi' || host == 'alveo-demo.web.app' || host == 'localhost:5000') {
      try {
        final demo = await _client.from('companies').select().eq('is_demo', true).eq('is_active', true).maybeSingle();
        if (demo != null) return Company.fromJson(demo, globalLimits: globalLimits);
      } catch (_) {}
    }

    try {
      // Intentar match exacto con el dominio (que ahora es el subdominio.alveo.fyi)
      final res = await _client.from('companies').select().eq('domain', host).eq('is_active', true).maybeSingle();
      if (res != null) return Company.fromJson(res, globalLimits: globalLimits);
    } catch (_) {}

    // Fallback al modo demo si falla todo
    try {
      final demo = await _client.from('companies').select().eq('is_demo', true).eq('is_active', true).maybeSingle();
      if (demo != null) return Company.fromJson(demo, globalLimits: globalLimits);
    } catch (_) {}
    
    return Company.empty;
  }

  static Future<List<Company>> getAllCompanies() async {
    final globalLimits = await getGlobalLimits();
    final res = await _client.from('companies').select().order('name');
    return (res as List).map((j) => Company.fromJson(j, globalLimits: globalLimits)).toList();
  }

  static Future<Company?> getCompanyById(String id) async {
    try {
      final globalLimits = await getGlobalLimits();
      final res = await _client.from('companies').select().eq('id', id).single();
      return Company.fromJson(res, globalLimits: globalLimits);
    } catch (e) {
      debugPrint('[CompanyService] Error getCompanyById: $e');
      return null;
    }
  }

  static Future<Map<String, int>> getGlobalLimits() async {
    try {
      final res = await _client.from('app_settings').select().eq('key', 'default_limits').maybeSingle();
      if (res != null && res['value'] != null) {
        final val = res['value'] as Map<String, dynamic>;
        return {
          'max_properties': val['max_properties'] as int? ?? 20,
          'max_photos_per_property': val['max_photos_per_property'] as int? ?? 10,
        };
      }
    } catch (e) {
      debugPrint('[CompanyService] Error getGlobalLimits: $e');
    }
    return {'max_properties': 20, 'max_photos_per_property': 10};
  }

  static Future<Company> upsertCompany(Company company) async {
    final data = company.toJson();
    final globalLimits = await getGlobalLimits();
    dynamic res;
    if (company.id.isNotEmpty) {
      data['id'] = company.id;
      res = await _client.from('companies').update(data).eq('id', company.id).select().single();
    } else {
      res = await _client.from('companies').insert(data).select().single();
    }
    return Company.fromJson(res, globalLimits: globalLimits);
  }

  /// Sube logo a property-images/logos/$companyId/ usando XHR directo
  /// para evitar el bug de MIME type del SDK de Flutter Web (image/blob:http...).
  static Future<String?> uploadCompanyLogo(String companyId, Uint8List bytes, {bool isAbbreviated = false}) async {
    try {
      final fileName = isAbbreviated ? 'logo_abbr.png' : 'logo.png';
      final path = 'logos/$companyId/$fileName';
      await _client.storage.from(_bucket).uploadBinary(
        path,
        bytes,
        fileOptions: const FileOptions(
          contentType: 'image/png',
          upsert: true,
        ),
      );

      final url = _client.storage.from(_bucket).getPublicUrl(path);
      // Forzamos actualización de la URL con un timestamp para evitar cache
      final cacheBusterUrl = '$url?t=${DateTime.now().millisecondsSinceEpoch}';
      
      final column = isAbbreviated ? 'logo_abbr_url' : 'logo_url';
      await _client.from('companies').update({column: cacheBusterUrl}).eq('id', companyId);

      debugPrint('[Alveo] ✅ Logo ${isAbbreviated ? 'Abbr' : 'Full'} → $path');
      return cacheBusterUrl;
    } catch (e) {
      debugPrint('[Alveo] ❌ Error subiendo logo: $e');
      return null;
    }
  }

  static Future<void> setCompanyActive(String companyId, bool active) async {
    await _client.from('companies').update({'is_active': active}).eq('id', companyId);
  }

  // ── ESTRATEGIA DE REFERIDOS ───────────────────────────────────

  static Future<String> getActiveStrategy() async {
    try {
      final res = await _client.from('app_settings').select('value').eq('key', 'active_referral_strategy').maybeSingle();
      if (res != null) return res['value'] as String;
    } catch (e) { debugPrint('Error getActiveStrategy: $e'); }
    return 'strategy_1';
  }

  static Future<void> setActiveStrategy(String strategy) async {
    await _client.from('app_settings').upsert({
      'key': 'active_referral_strategy',
      'value': strategy,
      'company_id': null,
    });
  }

  // ── VENDEDORES (SALESPERSONS) ───────────────────────────────

  static Future<List<Map<String, dynamic>>> getSalespersons() async {
    return await _client.from('salespersons').select().order('alias');
  }

  static Future<Map<String, dynamic>?> getSalespersonByAlias(String alias) async {
    try {
      return await _client.from('salespersons')
          .select()
          .eq('alias', alias.toLowerCase())
          .eq('is_active', true)
          .maybeSingle();
    } catch (_) {
      return null;
    }
  }

  static Future<void> upsertSalesperson(Map<String, dynamic> data) async {
    await _client.from('salespersons').upsert(data);
  }

  static Future<void> deleteSalesperson(String id) async {
    // Aplicando política de Soft Delete para preservar integridad referencial
    await _client.from('salespersons').update({'is_active': false}).eq('id', id);
  }

  // ── COMISIONES (COMMISSIONS) ────────────────────────────────

  static Future<List<Map<String, dynamic>>> getCommissions() async {
    return await _client.from('commissions').select('*, salespersons(alias, full_name), companies(name)').order('created_at', ascending: false);
  }

  static Future<void> updateCommissionStatus(String id, String status) async {
    final data = {'status': status};
    if (status == 'paid') data['paid_at'] = DateTime.now().toIso8601String();
    await _client.from('commissions').update(data).eq('id', id);
  }

  // ── SOLICITUDES DE REGISTRO (REGISTRATION REQUESTS) ──────

  static Future<List<Map<String, dynamic>>> getRegistrationRequests() async {
    return await _client.from('company_registration_requests').select().order('created_at', ascending: false);
  }

  static Future<void> approveRegistrationRequest(Map<String, dynamic> request) async {
    // 1. Crear la empresa (Supabase genera el ID)
    final companyData = {
      'name': request['company_name'],
      'abbr': request['desired_domain'].toString().replaceAll('-', '').toLowerCase(), // Use the subdomain as abbreviation
      'domain': '${request['desired_domain']}.alveo.fyi', // Using the new suffix
      'contact_name': request['contact_name'],
      'contact_email': request['contact_email'],
      'contact_phone': request['contact_phone'],
      'language': request['language'] ?? 'es',
      'billing_cycle': request['billing_cycle'] ?? 'monthly',
      'is_active': true,
      'subscription_status': 'trial',
      'trial_ends_at': DateTime.now().add(const Duration(days: 7)).toIso8601String(),
      'acquisition_channel': request['acquisition_channel'] ?? 'organic',
      'referred_by_salesperson': request['referred_alias'],
      'currency_symbol': request['currency_symbol'] ?? '\$',
      'currency_code': request['currency_code'] ?? 'USD',
      'area_unit': request['area_unit'] ?? 'm²',
      'country': request['country'],
      'state': request['state'],
      'city': request['city'],
      'logo_url': request['logo_url'],
      'logo_abbr_url': request['logo_abbr_url'],
      'instagram_url': request['instagram_url'],
      'facebook_url': request['facebook_url'],
      'telegram_url': request['telegram_url'],
      'contact_whatsapp': request['contact_whatsapp'],
    };

    final newCompany = await _client.from('companies').insert(companyData).select().single();
    final String newId = newCompany['id'];

    // 2. Si es referido por corredor, crear entrada en 'referrals'
    Map<String, dynamic>? referrer;
    if (request['acquisition_channel'] == 'broker' && request['referral_email'] != null) {
      referrer = await _client.from('companies').select('id').eq('contact_email', request['referral_email']).maybeSingle();
      if (referrer != null) {
        await _client.from('referrals').insert({
          'referrer_company_id': referrer['id'],
          'referred_company_id': newId,
          'status': 'pending',
        });
      }
    }

    // 3. Aplicar beneficios según la estrategia activa
    final strategy = await getActiveStrategy();
    if (referrer != null) {
      final String referrerId = referrer['id'];
      await applyReferralReward(referrerId, strategy);
    }

    // 4. Marcar solicitud como aprobada
    await _client.from('company_registration_requests').update({'status': 'approved'}).eq('id', request['id']);
  }

  static Future<void> rejectRegistrationRequest(String requestId) async {
    await _client.from('company_registration_requests').update({'status': 'rejected'}).eq('id', requestId);
  }

  static Future<void> applyReferralReward(String companyId, String strategy) async {
    final company = await _client.from('companies').select().eq('id', companyId).single();
    final updates = <String, dynamic>{};

    if (strategy == 'strategy_1' || strategy == 'strategy_3') {
      // -$1 discount
      updates['referral_discount'] = (company['referral_discount'] as num? ?? 0.0) + 1.0;
    }
    
    if (strategy == 'strategy_2' || strategy == 'strategy_3') {
      // +2 properties / +2 photos
      updates['referral_bonus_properties'] = (company['referral_bonus_properties'] as int? ?? 0) + 2;
      updates['referral_bonus_photos'] = (company['referral_bonus_photos'] as int? ?? 0) + 2;
    }

    if (updates.isNotEmpty) {
      await _client.from('companies').update(updates).eq('id', companyId);
      debugPrint('[Alveo] Recompensa aplicada ($strategy) a $companyId: $updates');
    }
  }

  // ─── Country Pricing ──────────────────────────────────────────────────────

  static const double _baseMonthly = 18.0;
  static const double _baseFloor = 15.0;

  /// Devuelve todas las filas de country_pricing ordenadas por país.
  static Future<List<Map<String, dynamic>>> getCountryPricing() async {
    final res = await _client
        .from('country_pricing')
        .select()
        .order('country');
    return List<Map<String, dynamic>>.from(res);
  }

  /// Precio efectivo para un país. Si no hay fila → base global.
  static Future<Map<String, double>> getPriceForCountry(String? country) async {
    if (country == null || country.isEmpty) {
      return {'monthly': _baseMonthly, 'floor': _baseFloor, 'annual': _baseMonthly * 11};
    }
    try {
      final row = await _client
          .from('country_pricing')
          .select()
          .eq('country', country)
          .eq('is_active', true)
          .maybeSingle();
      if (row != null) {
        final monthly = (row['monthly_price'] as num).toDouble();
        final floor   = (row['referral_floor'] as num).toDouble();
        return {'monthly': monthly, 'floor': floor, 'annual': monthly * 11};
      }
    } catch (_) {}
    return {'monthly': _baseMonthly, 'floor': _baseFloor, 'annual': _baseMonthly * 11};
  }

  /// Crea o actualiza el precio especial de un país.
  static Future<void> upsertCountryPrice({
    required String country,
    required double monthlyPrice,
    required double referralFloor,
    String? bankInfo,
  }) async {
    await _client.from('country_pricing').upsert({
      'country': country,
      'monthly_price': monthlyPrice,
      'referral_floor': referralFloor,
      'bank_info': bankInfo,
      'is_active': true,
    }, onConflict: 'country');
  }

  /// Elimina el precio especial de un país (vuelve al base global).
  static Future<void> deleteCountryPrice(String country) async {
    await _client.from('country_pricing').delete().eq('country', country);
  }
}
