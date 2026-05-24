import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/company.dart';
import '../../models/payment.dart';
import '../../services/subscription_service.dart';
import '../../services/app_localizations.dart';
import '../../providers/company_provider.dart';
import '../../services/invoice_service.dart';

class AdminBillingHistoryScreen extends StatefulWidget {
  const AdminBillingHistoryScreen({super.key});

  @override
  State<AdminBillingHistoryScreen> createState() => _AdminBillingHistoryScreenState();
}

class _AdminBillingHistoryScreenState extends State<AdminBillingHistoryScreen> {
  final _service = SubscriptionService();
  bool _isLoading = true;
  List<Payment> _payments = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    try {
      final companyId = Provider.of<CompanyProvider>(context, listen: false).companyId;
      final payments = await _service.getCompanyPayments(companyId);
      setState(() => _payments = payments);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isSpanish = l10n.locale.languageCode == 'es';
    final company = Provider.of<CompanyProvider>(context).currentCompany;

    return Scaffold(
      appBar: AppBar(
        title: Text(isSpanish ? 'Historial de Pagos' : 'Billing History'),
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _payments.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history_outlined, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        isSpanish ? 'No tienes pagos registrados aún.' : 'No payment history yet.',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _payments.length,
                  itemBuilder: (context, index) {
                    final payment = _payments[index];
                    return _buildPaymentCard(payment, company, isSpanish);
                  },
                ),
    );
  }

  Widget _buildPaymentCard(Payment payment, Company company, bool isSpanish) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    Color statusColor;
    String statusText;

    switch (payment.status) {
      case 'confirmed':
        statusColor = Colors.green;
        statusText = isSpanish ? 'CONFIRMADO' : 'CONFIRMED';
        break;
      case 'pending':
        statusColor = Colors.orange;
        statusText = isSpanish ? 'PENDIENTE' : 'PENDING';
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusText = isSpanish ? 'RECHAZADO' : 'REJECTED';
        break;
      default:
        statusColor = Colors.grey;
        statusText = payment.status.toUpperCase();
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '\$${NumberFormat("#,###.00").format(payment.amount)}',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue),
                    ),
                    Text(
                      dateFormat.format(payment.createdAt),
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                const Icon(Icons.tag, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  'Ref: ${payment.reference}',
                  style: const TextStyle(fontSize: 13),
                ),
                const Spacer(),
                const Icon(Icons.repeat, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  payment.billingCycle == 'annual' ? (isSpanish ? 'Anual' : 'Annual') : (isSpanish ? 'Mensual' : 'Monthly'),
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
            if (payment.status == 'confirmed') ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => InvoiceService.generateAndPrintInvoice(
                    company: company,
                    payment: payment,
                  ),
                  icon: const Icon(Icons.picture_as_pdf, size: 18),
                  label: Text(isSpanish ? 'DESCARGAR RECIBO' : 'DOWNLOAD RECEIPT'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue,
                    side: const BorderSide(color: Colors.blue),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
            if (payment.status == 'rejected' && payment.notes != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Nota: ${payment.notes}',
                  style: TextStyle(color: Colors.red.shade900, fontSize: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
