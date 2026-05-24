import 'package:flutter/material.dart';
import '../../services/company_service.dart';
import '../../services/app_localizations.dart';
import 'package:intl/intl.dart';

class SuperAdminRequestsTab extends StatefulWidget {
  final VoidCallback onApproved;
  const SuperAdminRequestsTab({super.key, required this.onApproved});

  @override
  State<SuperAdminRequestsTab> createState() => _SuperAdminRequestsTabState();
}

class _SuperAdminRequestsTabState extends State<SuperAdminRequestsTab> {
  List<Map<String, dynamic>> _requests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() => _isLoading = true);
    try {
      final reqs = await CompanyService.getRegistrationRequests();
      if (mounted) {
        setState(() {
          _requests = reqs.where((r) => r['status'] == 'pending').toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading requests: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _approve(Map<String, dynamic> request) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context).get('approve_request_title')),
        content: Text(AppLocalizations.of(context).get('approve_request_body', [request['company_name']])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppLocalizations.of(context).get('cancel'))),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: Text(AppLocalizations.of(context).get('approve_create_btn'))),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await CompanyService.approveRegistrationRequest(request);
      await _loadRequests();
      widget.onApproved();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).get('company_created_activated')), backgroundColor: Colors.green));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_requests.isEmpty) return Center(child: Text(l10n.get('no_pending_requests')));

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _requests.length,
      itemBuilder: (_, i) {
        final r = _requests[i];
        final date = DateTime.parse(r['created_at']);
        final channel = r['acquisition_channel'] ?? 'organic';

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(r['company_name'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                    const SizedBox(width: 8),
                    _channelBadge(channel),
                  ],
                ),
                const SizedBox(height: 8),
                Text('${l10n.get('contact_label_field')} ${r['contact_name']} (${r['contact_email']})'),
                Text('${l10n.get('domain_label_field')} ${r['desired_domain']}.alveo.pro'),
                const Divider(height: 24),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(DateFormat('dd MMM yyyy, HH:mm').format(date), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    const Spacer(),
                    if (r['referred_alias'] != null) ...[
                      const Icon(Icons.badge, size: 14, color: Colors.purple),
                      const SizedBox(width: 4),
                      Text('${l10n.get('salesperson')}: ${r['referred_alias']}', style: const TextStyle(fontSize: 12, color: Colors.purple, fontWeight: FontWeight.bold)),
                    ],
                    if (r['referral_email'] != null) ...[
                      const Icon(Icons.group, size: 14, color: Colors.blue),
                      const SizedBox(width: 4),
                      Text('Referido por: ${r['referral_email']}', style: const TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.bold)),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                // ── País detectado + Precio acordado ──
                _geoPriceBanner(r),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: Text(l10n.get('confirm_rejection_title')),
                              content: Text(l10n.get('confirm_rejection_msg')),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.get('cancel'))),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true), 
                                  child: Text(l10n.get('reject_btn'), style: const TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            setState(() => _isLoading = true);
                            try {
                              await CompanyService.rejectRegistrationRequest(r['id']);
                              await _loadRequests();
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                              setState(() => _isLoading = false);
                            }
                          }
                        },
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
                        child: Text(l10n.get('reject_btn')),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _approve(r),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                        child: Text(l10n.get('approve_activate_trial_btn')),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _channelBadge(String channel) {
    final l10n = AppLocalizations.of(context);
    final isSpanish = l10n.locale.languageCode == 'es';
    Color color = Colors.grey;
    String label = channel.toUpperCase();
    
    if (channel == 'organic') {
      color = Colors.green;
      label = 'ORGANIC';
    } else if (channel == 'salesperson') {
      color = Colors.purple;
      label = l10n.get('salesperson').toUpperCase();
    } else if (channel == 'broker') {
      color = Colors.blue;
      label = isSpanish ? 'CORREDOR' : 'BROKER';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w900),
      ),
    );
  }

  Widget _geoPriceBanner(Map<String, dynamic> r) {
    final l10n = AppLocalizations.of(context);
    final country   = r['country'] as String?;
    final state     = r['state'] as String?;
    final currency  = r['currency_code'] as String?;
    final areaUnit  = r['area_unit'] as String?;
    final basePrice = r['base_price'];
    final cycle     = r['billing_cycle'] as String? ?? 'monthly';

    final hasGeo   = country != null && country.isNotEmpty;
    final hasPrice = basePrice != null;

    // Determine if a custom (non-base) price was applied
    final priceVal      = hasPrice ? (basePrice as num).toDouble() : null;
    final isMonthly     = cycle == 'monthly';
    final monthlyEquiv  = priceVal != null ? (isMonthly ? priceVal : priceVal / 11) : null;
    final isCustomPrice = monthlyEquiv != null && monthlyEquiv != 18.0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCustomPrice ? Colors.green.withValues(alpha: 0.07) : Colors.blueGrey.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCustomPrice ? Colors.green.withValues(alpha: 0.4) : Colors.blueGrey.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Icon(
                isCustomPrice ? Icons.local_offer : Icons.public,
                size: 16,
                color: isCustomPrice ? Colors.green[700] : Colors.blueGrey,
              ),
              const SizedBox(width: 8),
              Text(
                isCustomPrice ? l10n.get('special_country_price') : l10n.get('standard_price'),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: isCustomPrice ? Colors.green[700] : Colors.blueGrey,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Info grid
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              if (hasGeo) _infoChip(Icons.location_on, '${country}${state != null ? ', $state' : ''}', Colors.teal),
              if (currency != null) _infoChip(Icons.attach_money, currency, Colors.blueGrey),
              if (areaUnit != null) _infoChip(Icons.square_foot, areaUnit, Colors.blueGrey),
              if (hasPrice)
                _infoChip(
                  Icons.credit_card,
                  isMonthly
                    ? '\$${NumberFormat("#,###.00").format(priceVal)}${l10n.get('per_month')}'
                    : '\$${NumberFormat("#,###.00").format(priceVal)}${l10n.get('per_year_annual')}',
                  isCustomPrice ? Colors.green[700]! : Colors.blueGrey,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
