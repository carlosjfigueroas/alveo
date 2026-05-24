import 'package:flutter/material.dart';
import '../models/company.dart';
import '../services/app_localizations.dart';
import '../utils/payment_dialog_utils.dart';

class SubscriptionBanner extends StatelessWidget {
  final Company company;

  const SubscriptionBanner({super.key, required this.company});

  @override
  Widget build(BuildContext context) {
    if (company.isDemo) return const SizedBox.shrink();
    
    final l10n = AppLocalizations.of(context);
    final isSpanish = l10n.locale.languageCode == 'es';
    final now = DateTime.now();
    
    // 1. Determinar fecha objetivo y tipo
    DateTime? targetDate;
    String message = '';
    Color bgColor = Colors.amber.shade700;
    IconData icon = Icons.warning_amber_rounded;
    bool isUrgent = false;

    if (company.subscriptionStatus == 'trial') {
      targetDate = company.trialEndsAt;
      if (targetDate != null) {
        final daysLeft = targetDate.difference(now).inDays;
        if (daysLeft >= 0 && daysLeft <= 3) {
          message = l10n.get('trial_ending_soon')
              .replaceFirst('{0}', daysLeft.toString())
              .replaceFirst('{1}', daysLeft == 1 ? (isSpanish ? 'día' : 'day') : (isSpanish ? 'días' : 'days'));
        }
      }
    } else if (company.subscriptionStatus == 'active') {
      targetDate = company.subscriptionEndsAt;
      if (targetDate != null) {
        final daysLeft = targetDate.difference(now).inDays;
        
        if (daysLeft < 0) {
          // Periodo de Gracia
          isUrgent = true;
          bgColor = Colors.red.shade700;
          icon = Icons.error_outline;
          message = l10n.get('subscription_expired_urgent');
        } else if (daysLeft <= 7) {
          // Próximo a vencer
          if (daysLeft <= 3) {
            isUrgent = true;
            bgColor = Colors.orange.shade800;
          }
          message = l10n.get('subscription_ending_soon')
              .replaceFirst('{0}', daysLeft.toString())
              .replaceFirst('{1}', daysLeft == 1 ? (isSpanish ? 'día' : 'day') : (isSpanish ? 'días' : 'days'));
        }
      }
    }

    if (message.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              PaymentDialogUtils.showPaymentReportDialog(context, company);
            },
            child: Text(
              l10n.get('register_payment'),
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}
