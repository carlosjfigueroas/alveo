import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/app_provider.dart';
import '../providers/company_provider.dart';
import '../services/subscription_service.dart';

class SuspendedScreen extends StatelessWidget {
  const SuspendedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final languageCode = Provider.of<AppProvider>(context).locale.languageCode;
    final isEs = languageCode == 'es';
    final company = context.watch<CompanyProvider>().currentCompany;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline, size: 80, color: Colors.orange),
                const SizedBox(height: 24),
                Text(
                  isEs ? 'Servicio Temporalmente Suspendido' : 'Service Temporarily Suspended',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  isEs
                      ? 'Su cuenta ha sido suspendida por falta de pago. '
                        'Para reactivar su servicio, realice el pago pendiente '
                        'y repórtelo aquí.'
                      : 'Your account has been suspended due to non-payment. '
                        'To reactivate your service, complete the pending payment '
                        'and report it here.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Colors.black54, height: 1.5),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () => _showReportDialog(context, isEs, company),
                  icon: const Icon(Icons.receipt_long),
                  label: Text(isEs ? 'Reportar Pago' : 'Report Payment'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 48),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade100),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.email_outlined, color: Colors.blue),
                      SizedBox(width: 12),
                      Text(
                        'alveo.soporte@gmail.com',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showReportDialog(BuildContext context, bool isEs, dynamic company) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _ReportPaymentDialog(isEs: isEs, company: company),
    );
  }
}

class _ReportPaymentDialog extends StatefulWidget {
  final bool isEs;
  final dynamic company;

  const _ReportPaymentDialog({required this.isEs, required this.company});

  @override
  State<_ReportPaymentDialog> createState() => _ReportPaymentDialogState();
}

class _ReportPaymentDialogState extends State<_ReportPaymentDialog> {
  final _refCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _refCtrl.dispose();
    _urlCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final ref = _refCtrl.text.trim();
    if (ref.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.isEs ? 'Ingrese el número de referencia' : 'Enter reference number'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final subService = SubscriptionService();
      
      // La empresa ya trae su billingCycle y su basePrice (o calculate effectivePrice si hay referralDiscount)
      final amount = widget.company.billingCycle == 'annual' 
          ? widget.company.effectivePrice * 12 
          : widget.company.effectivePrice;

      await subService.reportPayment(
        companyId: widget.company.id,
        reference: ref,
        billingCycle: widget.company.billingCycle,
        amount: amount,
        notes: _urlCtrl.text.trim().isEmpty ? null : _urlCtrl.text.trim(),
      );

      if (!mounted) return;
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEs 
              ? 'Pago reportado exitosamente. Será verificado en breve.' 
              : 'Payment reported successfully. It will be verified shortly.'
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.isEs ? 'Error al reportar pago' : 'Error reporting payment'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cycle = widget.company.billingCycle;
    final cycleLabel = cycle == 'annual' 
        ? (widget.isEs ? 'Anual' : 'Annual') 
        : (widget.isEs ? 'Mensual' : 'Monthly');
        
    final amount = cycle == 'annual' 
        ? widget.company.effectivePrice * 12 
        : widget.company.effectivePrice;
        
    final formattedAmount = NumberFormat.currency(
      symbol: widget.company.currencySymbol, 
      decimalDigits: 2
    ).format(amount);

    return AlertDialog(
      title: Text(widget.isEs ? 'Reportar Pago' : 'Report Payment'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.isEs ? 'Detalles de Facturación:' : 'Billing Details:',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(widget.isEs ? 'Ciclo:' : 'Cycle:'),
                      Text(cycleLabel, style: const TextStyle(fontWeight: FontWeight.w500)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(widget.isEs ? 'Monto a Pagar:' : 'Amount to Pay:'),
                      Text(formattedAmount, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.green)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _refCtrl,
              decoration: InputDecoration(
                labelText: widget.isEs ? 'Número de Referencia *' : 'Reference Number *',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.numbers),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _urlCtrl, // used for bank origin now
              decoration: InputDecoration(
                labelText: widget.isEs ? 'Banco Origen' : 'Origin Bank',
                prefixIcon: const Icon(Icons.account_balance),
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(widget.isEs ? 'Cancelar' : 'Cancel'),
        ),
        _isLoading
            ? const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator()),
              )
            : ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                child: Text(widget.isEs ? 'Enviar Pago' : 'Submit Payment'),
              ),
      ],
    );
  }
}
