import 'package:flutter/material.dart';
import '../models/company.dart';
import '../services/app_localizations.dart';
import '../services/subscription_service.dart';

class PaymentDialogUtils {
  static void showPaymentReportDialog(BuildContext context, Company company) {
    final l10n = AppLocalizations.of(context);
    final isSpanish = l10n.locale.languageCode == 'es';
    final refController = TextEditingController();
    final bankController = TextEditingController();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.account_balance_wallet_outlined, color: Colors.blue),
              const SizedBox(width: 12),
              Text(l10n.get('report_payment_title')),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.get('report_payment_desc'),
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: refController,
                  decoration: InputDecoration(
                    labelText: l10n.get('reference_number_label'),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.numbers),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: bankController,
                  decoration: InputDecoration(
                    labelText: l10n.get('origin_bank_label'),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.account_balance),
                    hintText: l10n.get('origin_bank_hint'),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade100),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 18, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.get('current_plan_label').replaceFirst('{0}', company.billingCycle == 'annual' ? (isSpanish ? 'Anual' : 'Annual') : (isSpanish ? 'Mensual' : 'Monthly')),
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(context), 
              child: Text(l10n.get('cancel'))
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: isSaving ? null : () async {
                final ref = refController.text.trim();
                if (ref.isEmpty) {
                   ScaffoldMessenger.of(context).showSnackBar(
                     SnackBar(content: Text(l10n.get('reference_required')), backgroundColor: Colors.red)
                   );
                   return;
                }
                
                setDialogState(() => isSaving = true);
                try {
                  final subService = SubscriptionService();
                  final amount = company.billingCycle == 'annual' 
                      ? company.effectivePrice * 12 
                      : company.effectivePrice;

                  await subService.reportPayment(
                    companyId: company.id,
                    reference: ref,
                    billingCycle: company.billingCycle,
                    amount: amount,
                    notes: bankController.text.trim().isEmpty ? null : bankController.text.trim(),
                  );

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.get('payment_reported_success')),
                        backgroundColor: Colors.green,
                      )
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red)
                    );
                  }
                } finally {
                  setDialogState(() => isSaving = false);
                }
              },
              child: isSaving 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(l10n.get('send')),
            ),
          ],
        ),
      ),
    );
  }
}
