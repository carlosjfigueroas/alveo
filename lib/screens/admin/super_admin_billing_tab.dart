import 'package:flutter/material.dart';
import '../../services/app_localizations.dart';
import '../../services/subscription_service.dart';
import '../../models/company.dart';
import '../../models/payment.dart';
import 'package:intl/intl.dart';

class SuperAdminBillingTab extends StatefulWidget {
  final List<Company> companies;
  final VoidCallback onRefreshRequested;

  const SuperAdminBillingTab({
    super.key,
    required this.companies,
    required this.onRefreshRequested,
  });

  @override
  State<SuperAdminBillingTab> createState() => _SuperAdminBillingTabState();
}

class _SuperAdminBillingTabState extends State<SuperAdminBillingTab> {
  final SubscriptionService _subService = SubscriptionService();
  bool _isLoading = false;
  List<Payment> _pendingPayments = [];
  Map<String, dynamic>? _metrics;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _loadPendingPayments(),
      _loadMetrics(),
    ]);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadMetrics() async {
    try {
      final m = await _subService.getBillingMetrics();
      if (mounted) setState(() => _metrics = m);
    } catch (e) {
      debugPrint('Error loading metrics: $e');
    }
  }

  Future<void> _loadPendingPayments() async {
    try {
      final payments = await _subService.getPendingPayments();
      if (mounted) {
        setState(() {
          _pendingPayments = payments;
        });
      }
    } catch (e) {
      debugPrint('Error loading pending payments: $e');
    }
  }

  Future<void> _checkSubscriptions() async {
    setState(() => _isLoading = true);
    try {
      await _subService.checkAndUpdateSubscriptions();
      widget.onRefreshRequested();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Suscripciones verificadas con éxito')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmPaymentDialog(Company company) async {
    final l10n = AppLocalizations.of(context);
    final amountCtrl = TextEditingController(text: NumberFormat("#,###.00").format(company.effectivePrice));
    final refCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    
    // Predet. periodo a 1 mes desde hoy o desde vencimiento actual
    DateTime start = company.subscriptionEndsAt != null && company.subscriptionEndsAt!.isAfter(DateTime.now())
        ? company.subscriptionEndsAt!
        : DateTime.now();
    DateTime end = start.add(const Duration(days: 30)); // Aproximacion 1 mes

    bool isSubmitting = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDs) => AlertDialog(
          title: Text('${AppLocalizations.of(context).get('payment_confirm_title')} (${company.name})'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amountCtrl,
                  decoration: const InputDecoration(labelText: 'Monto (USD)'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                TextField(
                  controller: refCtrl,
                  decoration: InputDecoration(labelText: l10n.get('ref_placeholder')),
                ),
                TextField(
                  controller: notesCtrl,
                  decoration: InputDecoration(labelText: l10n.get('notes_placeholder')),
                ),
                const SizedBox(height: 16),
                Text('Inicio: ${start.toLocal().toString().split(' ')[0]}'),
                Text('Fin: ${end.toLocal().toString().split(' ')[0]}'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.get('cancel')),
            ),
            isSubmitting
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: () async {
                      if (amountCtrl.text.isEmpty || refCtrl.text.isEmpty) return;
                      setDs(() => isSubmitting = true);
                      try {
                        await _subService.confirmPayment(
                          companyId: company.id,
                          amount: double.parse(amountCtrl.text),
                          reference: refCtrl.text,
                          periodStart: start,
                          periodEnd: end,
                          billingCycle: company.billingCycle,
                          notes: notesCtrl.text.isEmpty ? null : notesCtrl.text,
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                        widget.onRefreshRequested();
                      } catch (e) {
                         setDs(() => isSubmitting = false);
                         ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    },
                    child: Text(l10n.get('confirm')),
                  ),
          ],
        ),
      ),
    );
  }

  Future<void> _suspendCompany(Company company) async {
    final l10n = AppLocalizations.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.get('suspend_company_q')),
        content: Text(l10n.get('suspend_company_warn', [company.name])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.get('cancel'))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.get('suspend_btn'), style: const TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await _subService.suspendCompany(company.id);
      widget.onRefreshRequested();
    } catch (e) {
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _reactivateCompany(Company company) async {
    setState(() => _isLoading = true);
    try {
      await _subService.reactivateCompany(company.id);
      widget.onRefreshRequested();
    } catch (e) {
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              _buildMetricsHeader(l10n),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.sync),
                      label: Text(l10n.get('check_subs')),
                      onPressed: _checkSubscriptions,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey, foregroundColor: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.email),
                      label: Text(l10n.get('batch_reminder')),
                      onPressed: () async {
                        setState(() => _isLoading = true);
                        await _subService.sendReminderToAll(5);
                        setState(() => _isLoading = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.get('reminders_sent'))),
                        );
                      },
                    ),
                    const SizedBox(width: 16),
                    // BOTÓN PAGOS PENDIENTES
                    if (_pendingPayments.isNotEmpty)
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          ElevatedButton.icon(
                            icon: const Icon(Icons.account_balance_wallet_outlined),
                            label: Text(l10n.get('pending_label')),
                            onPressed: _showPendingPaymentsDialog,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange.shade700,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          Positioned(
                            right: -5,
                            top: -5,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                              constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                              child: Text(
                                '${_pendingPayments.length}',
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: widget.companies.length,
                  itemBuilder: (context, index) {
                    final company = widget.companies[index];
                    if (company.isDemo) return const SizedBox.shrink(); // Omitir demo
                    
                    Color statusColor;
                    switch (company.subscriptionStatus) {
                      case 'active': statusColor = Colors.green; break;
                      case 'trial': statusColor = Colors.orange; break;
                      case 'suspended': statusColor = Colors.red; break;
                      default: statusColor = Colors.grey;
                    }

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: statusColor.withValues(alpha: 0.2),
                          child: Icon(Icons.business, color: statusColor),
                        ),
                        title: Row(
                          children: [
                            Flexible(
                              child: Text(
                                company.name, 
                                style: const TextStyle(fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _badge(company.subscriptionStatus.toUpperCase(), statusColor),
                            if (company.graceEndsAt != null && company.subscriptionStatus == 'active')
                              Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: _badge('GRACIA', Colors.purple),
                              ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${l10n.get('expiration_date_label')}: ${company.subscriptionEndsAt?.toLocal().toString().split(' ')[0] ?? "N/A"}'),
                            Text(
                              'Efectivo: \$${NumberFormat("#,###.00").format(company.effectivePrice)} / ${company.billingCycle}'
                              ' (Base: \$${NumberFormat("#,###.00").format(company.basePrice)}, Desc: -\$${NumberFormat("#,###.00").format(company.referralDiscount)})',
                              style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.blueGrey),
                            ),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (val) {
                            if (val == 'pay') _confirmPaymentDialog(company);
                            if (val == 'suspend') _suspendCompany(company);
                            if (val == 'reactivate') _reactivateCompany(company);
                          },
                          itemBuilder: (ctx) => [
                            PopupMenuItem(value: 'pay', child: Text(l10n.get('register_payment'))),
                            company.subscriptionStatus == 'suspended'
                                ? PopupMenuItem(value: 'reactivate', child: Text(l10n.get('reactivate_btn')))
                                : PopupMenuItem(value: 'suspend', child: Text(l10n.get('suspend_btn'))),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
  }

  Widget _buildMetricsHeader(AppLocalizations l10n) {
    if (_metrics == null) return const SizedBox.shrink();

    return Container(
      height: 120,
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _metricCard(l10n.get('mrr_real_label'), '\$${NumberFormat("#,###").format(_metrics!['real_mrr_30d'])}', Icons.monetization_on, Colors.green),
          _metricCard(l10n.get('mrr_potential_label'), '\$${NumberFormat("#,###").format(_metrics!['potential_mrr'])}', Icons.trending_up, Colors.blue),
          _metricCard(l10n.get('subscribers_label'), '${_metrics!['active_subscribers']}', Icons.check_circle, Colors.teal),
          _metricCard(l10n.get('trial_users_label'), '${_metrics!['trial_users']}', Icons.hourglass_top, Colors.orange),
          _metricCard(l10n.get('suspended_users_label'), '${_metrics!['suspended_users']}', Icons.block, Colors.red),
          _metricCard(l10n.get('pending_label'), '${_metrics!['pending_approvals']}', Icons.pending_actions, Colors.indigo),
        ],
      ),
    );
  }

  Widget _metricCard(String label, String value, IconData icon, Color color) {
    return Container(
      width: 115,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.8), fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  void _showPendingPaymentsDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(AppLocalizations.of(context).get('pending_approvals_title')),
          content: SizedBox(
            width: double.maxFinite,
            child: _pendingPayments.isEmpty
              ? Text(AppLocalizations.of(context).get('no_pending_payments'))
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: _pendingPayments.length,
                  itemBuilder: (context, index) {
                    final p = _pendingPayments[index];
                    return Card(
                      child: ExpansionTile(
                        title: Text(p.companyName ?? 'ID: ${p.companyId.substring(0,8)}...'),
                        subtitle: Text('Ref: ${p.reference} - \$${NumberFormat("#,###.##").format(p.amount)}'),
                        children: [
                          if (p.notes != null)
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(AppLocalizations.of(context).get('origin_bank'), style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Text(p.notes!),
                                ],
                              ),
                            ),
                          if (p.receiptUrl != null && p.receiptUrl!.startsWith('http'))
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                  children: [
                                    Text(AppLocalizations.of(context).get('receipt_label'), style: const TextStyle(fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 8),
                                    Image.network(p.receiptUrl!, height: 300, fit: BoxFit.contain),
                                    TextButton.icon(
                                      onPressed: () => _viewFullImage(p.receiptUrl!),
                                      icon: const Icon(Icons.fullscreen),
                                      label: Text(AppLocalizations.of(context).get('view_fullscreen')),
                                    ),
                                  ],
                                ),
                            ),
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: Text(AppLocalizations.of(context).get('confirm_rejection_title')),
                                        content: Text(AppLocalizations.of(context).get('confirm_rejection_msg')),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppLocalizations.of(context).get('cancel'))),
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx, true), 
                                            child: Text(AppLocalizations.of(context).get('reject_btn'), style: const TextStyle(color: Colors.red)),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (confirm == true) {
                                      try {
                                        await _subService.rejectPayment(p.id);
                                        await _loadPendingPayments();
                                        widget.onRefreshRequested();
                                        if (context.mounted) Navigator.pop(context);
                                      } catch (e) {
                                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                                      }
                                    }
                                  }, 
                                  child: Text(AppLocalizations.of(context).get('reject_btn'), style: const TextStyle(color: Colors.red)),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                                  onPressed: () async {
                                    try {
                                      await _subService.approvePayment(p.id);
                                      await _loadPendingPayments();
                                      widget.onRefreshRequested();
                                      if (context.mounted) Navigator.pop(context);
                                    } catch (e) {
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                                    }
                                  },
                                  child: Text(AppLocalizations.of(context).get('approve_activate_btn')),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(AppLocalizations.of(context).get('close_btn'))),
          ],
        ),
      ),
    );
  }

  void _viewFullImage(String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            InteractiveViewer(
              child: Center(child: Image.network(url)),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}
