import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/company_service.dart';
import '../../services/app_localizations.dart';
import '../../models/salesperson.dart';
import '../../data/location_data.dart';
import '../../utils/formatters.dart';
import 'package:intl/intl.dart';

class SuperAdminMarketingTab extends StatefulWidget {
  const SuperAdminMarketingTab({super.key});

  @override
  State<SuperAdminMarketingTab> createState() => _SuperAdminMarketingTabState();
}

class _SuperAdminMarketingTabState extends State<SuperAdminMarketingTab> {
  String _activeStrategy = 'strategy_3';
  List<Salesperson> _salespersons = [];
  List<Map<String, dynamic>> _commissions = [];
  List<Map<String, dynamic>> _countryPricing = [];
  Map<String, int> _globalLimits = {'max_properties': 20, 'max_photos_per_property': 10};
  bool _isLoading = true;

  // Country pricing UI state
  String? _cpSearchQuery;
  final _cpSearchCtrl = TextEditingController();

  static const double _baseMonthly = 18.0;
  static const double _baseFloor   = 15.0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final strategy = await CompanyService.getActiveStrategy();
      final salesRaw = await CompanyService.getSalespersons();
      final comms    = await CompanyService.getCommissions();
      final pricing  = await CompanyService.getCountryPricing();
      final limits   = await CompanyService.getGlobalLimits();

      if (mounted) {
        setState(() {
          _activeStrategy = strategy;
          _salespersons   = salesRaw.map((e) => Salesperson.fromJson(e)).toList();
          _commissions    = comms;
          _countryPricing = pricing;
          _globalLimits   = limits;
          _isLoading      = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading marketing data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleStrategy(String strategy) async {
    try {
      await CompanyService.setActiveStrategy(strategy);
      setState(() => _activeStrategy = strategy);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).get('strategy_updated', [strategy])), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _showSalespersonDialog([Salesperson? existing]) async {
    final l10n = AppLocalizations.of(context);
    final aliasCtrl = TextEditingController(text: existing?.alias ?? '');
    final nameCtrl = TextEditingController(text: existing?.fullName ?? '');
    final emailCtrl = TextEditingController(text: existing?.email ?? '');
    final commCtrl = TextEditingController(text: NumberFormat("#,###.##").format(existing?.commissionPct ?? 20.0));
    bool isActive = existing?.isActive ?? true;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? l10n.get('new_salesperson') : l10n.get('edit_salesperson')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: aliasCtrl, decoration: InputDecoration(labelText: 'Alias (ej: lenin123)', enabled: existing == null)),
            TextField(controller: nameCtrl, decoration: InputDecoration(labelText: l10n.get('owner_full_name'))),
            TextField(controller: emailCtrl, decoration: InputDecoration(labelText: l10n.get('email'))),
            TextField(controller: commCtrl, decoration: InputDecoration(labelText: l10n.get('commission')), keyboardType: const TextInputType.numberWithOptions(decimal: true), inputFormatters: [DecimalInputFormatter()]),
            SwitchListTile(title: Text(l10n.get('active_btn')), value: isActive, onChanged: (v) => isActive = v),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              final alias = aliasCtrl.text.trim();
              final name = nameCtrl.text.trim();
              if (alias.isEmpty || name.isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(content: Text(l10n.get('alias_name_required')), backgroundColor: Colors.red),
                );
                return;
              }
              final salesperson = {
                if (existing != null) 'id': existing.id,
                'alias': alias.toLowerCase(),
                'full_name': name,
                'email': emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
                'commission_pct': double.tryParse(commCtrl.text.replaceAll(',', '')) ?? 20.0,
                'is_active': isActive,
              };
              await CompanyService.upsertSalesperson(salesperson);
              if (ctx.mounted) Navigator.pop(ctx);
              _loadData();
            },
            child: Text(l10n.get('save')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    final l10n = AppLocalizations.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── TOGGLE ESTRATEGIA ────────────────────────────────
          _sectionHeader(l10n.get('active_strategy'), Icons.settings_applications),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  RadioListTile<String>(
                    title: const Text('Estrategia 1'),
                    subtitle: Text(l10n.get('strategy_1_desc')),
                    value: 'strategy_1',
                    groupValue: _activeStrategy,
                    onChanged: (v) => _toggleStrategy(v!),
                  ),
                  RadioListTile<String>(
                    title: const Text('Estrategia 2'),
                    subtitle: Text(l10n.get('strategy_2_desc')),
                    value: 'strategy_2',
                    groupValue: _activeStrategy,
                    onChanged: (v) => _toggleStrategy(v!),
                  ),
                  RadioListTile<String>(
                    title: const Text('Estrategia 3 (Híbrida)'),
                    subtitle: Text(l10n.get('strategy_3_desc')),
                    value: 'strategy_3',
                    groupValue: _activeStrategy,
                    onChanged: (v) => _toggleStrategy(v!),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // ── PRECIOS POR PAÍS ─────────────────────────────────
          _sectionHeader(l10n.get('country_pricing'), Icons.public),
          _countryPricingSection(),
          const SizedBox(height: 32),

          // ── GESTIÓN DE VENDEDORES ────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _sectionHeader(l10n.get('freelance_executives'), Icons.badge),
              IconButton(onPressed: () => _showSalespersonDialog(), icon: const Icon(Icons.add_circle, color: Colors.green)),
            ],
          ),
          _salespersonsList(),
          const SizedBox(height: 32),

          // ── SEGUIMIENTO DE COMISIONES ────────────────────────
          _sectionHeader(l10n.get('commissions'), Icons.monetization_on),
          _commissionsTable(),
          const SizedBox(height: 32),

          // ── AJUSTES GLOBALES (LÍMITES) ───────────────────────
          _sectionHeader(l10n.get('global_settings_title') ?? 'Ajustes Globales (Por Defecto)', Icons.settings),
          _globalSettingsSection(),
        ],
      ),
    );
  }

  Widget _globalSettingsSection() {
    final l10n = AppLocalizations.of(context);
    final maxPropsCtrl = TextEditingController(text: _globalLimits['max_properties'].toString());
    final maxPhotosCtrl = TextEditingController(text: _globalLimits['max_photos_per_property'].toString());

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estos valores aplican por defecto a todas las empresas que no tengan un límite individual configurado.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: maxPropsCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: l10n.get('max_props_label') ?? 'Inmuebles (Global)',
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: maxPhotosCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: l10n.get('max_photos_label') ?? 'Fotos (Global)',
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: Text(l10n.get('save')),
                  onPressed: () async {
                    setState(() => _isLoading = true);
                    try {
                      final newProps = int.tryParse(maxPropsCtrl.text.replaceAll(',', '')) ?? 20;
                      final newPhotos = int.tryParse(maxPhotosCtrl.text.replaceAll(',', '')) ?? 10;
                      await Supabase.instance.client.from('app_settings').upsert({
                        'key': 'default_limits',
                        'company_id': null,
                        'value': {
                          'max_properties': newProps,
                          'max_photos_per_property': newPhotos,
                        },
                        'updated_at': DateTime.now().toIso8601String(),
                      }, onConflict: 'key');
                      
                      await _loadData();
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.get('save_success') ?? 'Guardado con éxito')));
                    } catch (e) {
                      if (mounted) {
                        setState(() => _isLoading = false);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                      }
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _countryPricingSection() {
    final l10n = AppLocalizations.of(context);
    final allCountries = LocationData.countries; // already sorted
    final pricingMap = { for (var r in _countryPricing) r['country'] as String: r };

    final filtered = _cpSearchQuery != null && _cpSearchQuery!.isNotEmpty
        ? allCountries.where((c) => c.toLowerCase().contains(_cpSearchQuery!.toLowerCase())).toList()
        : allCountries;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search bar
            TextField(
              controller: _cpSearchCtrl,
              decoration: InputDecoration(
                hintText: '${l10n.get('search')}...',
                prefixIcon: Icon(Icons.search),
                isDense: true,
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _cpSearchQuery = v.trim()),
            ),
            const SizedBox(height: 12),
            // Header row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(children: [
                Expanded(flex: 3, child: Text(l10n.get('country_header'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.blueGrey, letterSpacing: 0.8))),
                Expanded(flex: 2, child: Text(l10n.get('monthly_header'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.blueGrey, letterSpacing: 0.8), textAlign: TextAlign.right)),
                Expanded(flex: 2, child: Text(l10n.get('annual_header'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.blueGrey, letterSpacing: 0.8), textAlign: TextAlign.right)),
                Expanded(flex: 2, child: Text(l10n.get('floor_price_header'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.blueGrey, letterSpacing: 0.8), textAlign: TextAlign.right)),
                const SizedBox(width: 72),
              ]),
            ),
            const Divider(height: 8),
            // Base global row
            _cpRow(
              country: '🌐  Global (Base)',
              monthly: _baseMonthly,
              floor: _baseFloor,
              isBase: true,
              onEdit: null,
              onDelete: null,
            ),
            const Divider(height: 8),
            // Country rows
            ...filtered.map((country) {
              final row = pricingMap[country];
              final hasCustom = row != null && row['is_active'] == true;
              final monthly = hasCustom ? (row!['monthly_price'] as num).toDouble() : null;
              final floor   = hasCustom ? (row!['referral_floor'] as num).toDouble() : null;
              return _cpRow(
                country: country,
                monthly: monthly,
                floor: floor,
                isBase: false,
                onEdit: () => _showCountryPriceDialog(country, monthly, floor, row?['bank_info'] as String?),
                onDelete: hasCustom ? () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text(l10n.get('delete_country_price_title')),
                      content: Text(l10n.get('delete_country_price_body', [country])),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.get('cancel'))),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                          child: Text(l10n.get('delete')),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await CompanyService.deleteCountryPrice(country);
                    _loadData();
                  }
                } : null,
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _cpRow({
    required String country,
    required double? monthly,
    required double? floor,
    required bool isBase,
    required VoidCallback? onEdit,
    required VoidCallback? onDelete,
  }) {
    final hasCustom = monthly != null;
    final annual    = hasCustom ? monthly! * 11 : null;
    final formatter = NumberFormat("#,###.00");
    final monthlyTxt = hasCustom ? '\$${formatter.format(monthly)}' : '—';
    final annualTxt  = hasCustom ? '\$${formatter.format(annual)}' : '—';
    final floorTxt   = hasCustom ? '\$${formatter.format(floor)}' : '—';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 4),
      child: Row(children: [
        Expanded(flex: 3, child: Text(country, style: TextStyle(
          fontWeight: hasCustom ? FontWeight.bold : FontWeight.normal,
          color: isBase ? Colors.blueGrey : (isDark ? Colors.white70 : Colors.black87),
        ))),
        Expanded(flex: 2, child: Text(
          isBase ? '\$${NumberFormat("#,###.00").format(_baseMonthly)}' : monthlyTxt,
          textAlign: TextAlign.right,
          style: TextStyle(color: hasCustom ? Colors.green : Colors.grey, fontWeight: hasCustom ? FontWeight.bold : FontWeight.normal),
        )),
        Expanded(flex: 2, child: Text(
          isBase ? '\$${NumberFormat("#,###.00").format(_baseMonthly * 11)}' : annualTxt,
          textAlign: TextAlign.right,
          style: TextStyle(color: hasCustom ? Colors.green.shade700 : Colors.grey),
        )),
        Expanded(flex: 2, child: Text(
          isBase ? '\$${NumberFormat("#,###.00").format(_baseFloor)}' : floorTxt,
          textAlign: TextAlign.right,
          style: TextStyle(color: hasCustom ? Colors.orange : Colors.grey),
        )),
        SizedBox(width: 72, child: isBase ? const SizedBox.shrink() : Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            InkWell(
              onTap: onEdit,
              borderRadius: BorderRadius.circular(4),
              child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.edit_outlined, size: 18, color: Colors.blue)),
            ),
            if (onDelete != null)
              InkWell(
                onTap: onDelete,
                borderRadius: BorderRadius.circular(4),
                child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.delete_outline, size: 18, color: Colors.red)),
              ),
          ],
        )),
      ]),
    );
  }

  Future<void> _showCountryPriceDialog(String country, double? currentMonthly, double? currentFloor, String? currentBank) async {
    final l10n = AppLocalizations.of(context);
    final formatter = NumberFormat("#,###.00");
    final monthlyCtrl = TextEditingController(text: currentMonthly != null ? formatter.format(currentMonthly) : '18.00');
    final floorCtrl   = TextEditingController(text: currentFloor != null ? formatter.format(currentFloor) : '15.00');
    final bankCtrl    = TextEditingController(text: currentBank ?? '');
    bool isSaving = false;
    String? errorMsg;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDs) => AlertDialog(
          title: Row(children: [
            const Icon(Icons.public, color: Colors.blueGrey, size: 22),
            const SizedBox(width: 8),
            Expanded(child: Text('${l10n.get('price_field')}: $country', style: const TextStyle(fontSize: 16))),
          ]),
          content: SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: monthlyCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: l10n.get('monthly_price_label_field'),
                    prefixText: '\$ ',
                    border: const OutlineInputBorder(),
                    errorText: errorMsg,
                  ),
                  onChanged: (_) => setDs(() => errorMsg = null),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: floorCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: l10n.get('floor_price_label_field'),
                    prefixText: '\$ ',
                    border: const OutlineInputBorder(),
                    helperText: l10n.get('floor_price_helper'),
                  ),
                  onChanged: (_) => setDs(() => errorMsg = null),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: bankCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: l10n.get('bank_account_info_field'),
                    alignLabelWithHint: true,
                    border: const OutlineInputBorder(),
                    helperText: 'Información para depósitos locales',
                  ),
                ),
                const SizedBox(height: 12),
                ValueListenableBuilder(
                  valueListenable: monthlyCtrl,
                  builder: (_, __, ___) {
                    final m = double.tryParse(monthlyCtrl.text) ?? 0;
                    return Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
                      child: Row(children: [
                        const Icon(Icons.calendar_today, size: 16, color: Colors.green),
                        const SizedBox(width: 8),
                        Text('${l10n.get('annual_calculated')}${NumberFormat("#,###.00").format(m * 11)} ${l10n.get('one_month_free')}',
                          style: const TextStyle(fontSize: 13, color: Colors.green, fontWeight: FontWeight.bold)),
                      ]),
                    );
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: isSaving ? null : () => Navigator.pop(ctx), child: Text(l10n.get('cancel'))),
            if (isSaving)
              const Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator(strokeWidth: 2))
            else
              ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: Text(l10n.get('save')),
                onPressed: () async {
                  final monthly = double.tryParse(monthlyCtrl.text.trim().replaceAll(',', ''));
                  final floor   = double.tryParse(floorCtrl.text.trim().replaceAll(',', ''));
                  if (monthly == null || monthly < 5) { setDs(() => errorMsg = l10n.get('min_5_error')); return; }
                  if (floor == null || floor < 5)   { setDs(() => errorMsg = l10n.get('floor_min_5_error')); return; }
                  if (floor > monthly)               { setDs(() => errorMsg = l10n.get('floor_greater_error')); return; }
                  setDs(() => isSaving = true);
                  try {
                    await CompanyService.upsertCountryPrice(
                      country: country, 
                      monthlyPrice: monthly, 
                      referralFloor: floor,
                      bankInfo: bankCtrl.text.trim(),
                    );
                    if (ctx.mounted) Navigator.pop(ctx);
                    _loadData();
                  } catch (e) {
                    setDs(() { isSaving = false; errorMsg = 'Error: $e'; });
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        Icon(icon, size: 20, color: Colors.blueGrey),
        const SizedBox(width: 8),
        Text(title.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1, color: Colors.blueGrey)),
      ],
    ),
  );

  Widget _salespersonsList() {
    final l10n = AppLocalizations.of(context);
    if (_salespersons.isEmpty) return Card(child: ListTile(title: Text(l10n.get('no_salespersons'))));
    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _salespersons.length,
        separatorBuilder: (_, __) => const Divider(height: 0),
        itemBuilder: (_, i) {
          final s = _salespersons[i];
          final l10n = AppLocalizations.of(context);
          return ListTile(
            leading: CircleAvatar(child: Text(s.alias.isNotEmpty ? s.alias[0].toUpperCase() : (s.fullName.isNotEmpty ? s.fullName[0].toUpperCase() : '?'))),
            title: Text(s.fullName),
            subtitle: Text('@${s.alias}  ·  ${s.commissionPct}% comisión'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!s.isActive) Chip(label: Text(l10n.get('inactive_btn')), backgroundColor: Colors.redAccent),
                IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showSalespersonDialog(s)),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red), 
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text(l10n.get('deactivate_salesperson_title')),
                        content: Text(l10n.get('deactivate_salesperson_body', [s.fullName])),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.get('cancel'))),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                            child: Text(l10n.get('deactivate_btn')),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      try {
                        await CompanyService.deleteSalesperson(s.id);
                        _loadData();
                      } catch (e) {
                         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                      }
                    }
                  }
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _commissionsTable() {
    final l10n = AppLocalizations.of(context);
    if (_commissions.isEmpty) return Card(child: ListTile(title: Text(l10n.get('commissions_empty'))));
    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: [
            DataColumn(label: Text(l10n.get('date_header'))),
            DataColumn(label: Text(l10n.get('company_header'))),
            DataColumn(label: Text(l10n.get('salesperson'))),
            DataColumn(label: Text(l10n.get('amount_header'))),
            DataColumn(label: Text(l10n.get('status_header'))),
            DataColumn(label: Text(l10n.get('actions_header'))),
          ],
          rows: _commissions.map((c) {
            final l10n = AppLocalizations.of(context);
            final date = DateTime.parse(c['created_at']);
            final salesperson = c['salespersons'] ?? {};
            final company = c['companies'] ?? {};
            final isPending = c['status'] == 'pending';

            return DataRow(cells: [
              DataCell(Text(DateFormat('dd/MM/yy').format(date))),
              DataCell(Text(company['name'] ?? 'N/A')),
              DataCell(Text(salesperson['alias'] ?? 'N/A')),
              DataCell(Text('\$${NumberFormat("#,###.00").format(c['amount'])}')),
              DataCell(Chip(
                label: Text(c['status'].toUpperCase(), style: const TextStyle(fontSize: 10, color: Colors.white)),
                backgroundColor: isPending ? Colors.orange : Colors.green,
              )),
              DataCell(isPending 
                ? TextButton(
                    onPressed: () async {
                      await CompanyService.updateCommissionStatus(c['id'], 'paid');
                      _loadData();
                    }, 
                    child: Text(l10n.get('mark_paid'))
                  )
                : const Icon(Icons.check_circle, color: Colors.green)
              ),
            ]);
          }).toList(),
        ),
      ),
    );
  }
}

// Removed extension as standard NumberFormat is used
