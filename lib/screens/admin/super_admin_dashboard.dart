import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../services/app_localizations.dart';
import '../../services/app_provider.dart';
import '../../services/company_service.dart';
import '../../services/supabase_service.dart';
import '../../models/company.dart';
import '../../utils/image_utils.dart';
import '../../data/location_data.dart';
import 'super_admin_requests_tab.dart';
import 'super_admin_users_screen.dart';
import 'super_admin_billing_tab.dart';
import 'super_admin_marketing_tab.dart';
import 'package:intl/intl.dart';

class SuperAdminDashboard extends StatefulWidget {
  const SuperAdminDashboard({super.key});
  @override
  State<SuperAdminDashboard> createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends State<SuperAdminDashboard> with SingleTickerProviderStateMixin {
  List<Company> _companies = [];
  Map<String, int> _globalLimits = {'max_properties': 20, 'max_photos_per_property': 10};
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadCompanies();
  }

  @override
  void dispose() { _tabController.dispose(); super.dispose(); }

  Future<void> _loadCompanies() async {
    setState(() => _isLoading = true);
    try { 
      _companies = await CompanyService.getAllCompanies(); 
      _globalLimits = await CompanyService.getGlobalLimits();
    } catch (e) { 
      debugPrint('Error: $e'); 
    } finally { 
      if (mounted) setState(() => _isLoading = false); 
    }
  }

  Future<void> _deleteCompany(Company c) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.get('delete_confirm_title')),
        content: Text('${l10n.get('delete_confirm_body')}\n\n${l10n.get('company_name')}: ${c.name}'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(l10n.get('cancel'))),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: Text(l10n.get('delete')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        await SupabaseService().deleteCompany(c.id);
        await _loadCompanies();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Agencia eliminada con éxito')));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  /// Abre el selector de archivo nativo del navegador y retorna los bytes reales.
  /// Evita el bug de ImagePicker en Flutter Web que devuelve blob URLs en vez de bytes.
  Future<Uint8List?> _pickImageBytes() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (image == null) return null;
    return image.readAsBytes();
  }

  Future<void> _showCompanyDialog([Company? existing]) async {
    final l10n = AppLocalizations.of(context);
    final isSpanish = l10n.locale.languageCode == 'es';
    final isEdit = existing != null;
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final abbrCtrl = TextEditingController(text: existing?.abbr ?? '');
    final domainCtrl = TextEditingController(text: existing?.domain ?? '');
    final primaryCtrl = TextEditingController(text: existing?.primaryColorHex ?? '#006837');
    final secondaryCtrl = TextEditingController(text: existing?.secondaryColorHex ?? '#A64F35');
    final emailCtrl = TextEditingController(text: existing?.contactEmail ?? '');
    final phoneCtrl = TextEditingController(text: existing?.contactPhone ?? '');
    final waCtrl = TextEditingController(text: existing?.contactWhatsapp ?? '');
    final igCtrl = TextEditingController(text: existing?.instagramUrl ?? '');
    final fbCtrl = TextEditingController(text: existing?.facebookUrl ?? '');
    final tgCtrl = TextEditingController(text: existing?.telegramUrl ?? '');
    final lnCtrl = TextEditingController(text: existing?.linkedinUrl ?? '');
    bool isActive = existing?.isActive ?? true;
    bool isDemo = existing?.isDemo ?? false;
    bool showCarousel = existing?.showCarousel ?? true;
    bool showReferralMenu = existing?.showReferralMenu ?? true;
    bool showOrganicAffiliate = existing?.showOrganicAffiliate ?? true;
    bool hasAiAgent = existing?.hasAiAgent ?? true;
    String aiModel = existing?.aiModel ?? 'gemini-flash-latest';
    
    // Limits & Prices
    final basePriceCtrl = TextEditingController(
      text: existing?.basePrice != null 
          ? NumberFormat("#,###.00").format(existing!.basePrice) 
          : '18.00'
    );
    final maxPropertiesCtrl = TextEditingController(text: existing?.maxProperties.toString() ?? _globalLimits['max_properties'].toString());
    final maxPhotosCtrl = TextEditingController(text: existing?.maxPhotosPerProperty.toString() ?? _globalLimits['max_photos_per_property'].toString());
    
    final currentDiscount = existing?.referralDiscount ?? 0.0;
    final lowerBound = (double.tryParse(basePriceCtrl.text) ?? 18.0) * 0.75;
    final bonusProps = existing?.referralBonusProperties ?? 0;
    final bonusPhotos = existing?.referralBonusPhotos ?? 0;
    final activeReferrals = currentDiscount.toInt(); // Aprox 1 usd = 1 ref
    
    // Regional
    String? country = existing?.country;
    String? state = existing?.state;
    String currencyCode = existing?.currencyCode ?? 'USD';
    String areaUnit = existing?.areaUnit ?? 'm²';
    String language = existing?.language ?? 'es';
    String billingCycle = existing?.billingCycle ?? 'monthly';
    
    Uint8List? pickedLogoBytes;
    Uint8List? pickedAbbrBytes;
    bool isSaving = false;

    // Currency list
    const currencies = [
      {'code': 'USD', 'symbol': '\$', 'name': 'USA / Dólar'},
      {'code': 'EUR', 'symbol': '€', 'name': 'Euro'},
      {'code': 'VES', 'symbol': 'Bs', 'name': 'Venezuela'},
      {'code': 'COP', 'symbol': '\$', 'name': 'Colombia'},
      {'code': 'MXN', 'symbol': '\$', 'name': 'México'},
      {'code': 'PEN', 'symbol': 'S/', 'name': 'Perú'},
      {'code': 'CLP', 'symbol': '\$', 'name': 'Chile'},
      {'code': 'ARS', 'symbol': '\$', 'name': 'Argentina'},
      {'code': 'BOB', 'symbol': 'Bs.', 'name': 'Bolivia'},
      {'code': 'HNL', 'symbol': 'L', 'name': 'Honduras'},
      {'code': 'CRC', 'symbol': '₡', 'name': 'Costa Rica'},
      {'code': 'GTQ', 'symbol': 'Q', 'name': 'Guatemala'},
      {'code': 'PYG', 'symbol': '₲', 'name': 'Paraguay'},
      {'code': 'DOP', 'symbol': 'RD\$', 'name': 'R. Dominicana'},
    ];

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDs) => AlertDialog(
          title: Text(isEdit ? l10n.get('edit_company') : l10n.get('new_company')),
          content: SizedBox(
            width: 540,
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                // ── LOGOS ─────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(children: [const Icon(Icons.image, size: 18, color: Colors.grey), const SizedBox(width: 6), Text(l10n.get('company_logos_title'), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade600, letterSpacing: 1))]),
                ),
                Row(children: [
                  // Logo Principal
                  Expanded(child: Column(children: [
                    Text(l10n.get('full_logo_label'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () async {
                        final bytes = await _pickImageBytes();
                        if (bytes != null) setDs(() => pickedLogoBytes = bytes);
                      },
                      child: Container(
                        width: 120, height: 80,
                        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
                        child: pickedLogoBytes != null ? Image.memory(pickedLogoBytes!, fit: BoxFit.contain) : (existing?.logoUrl != null ? Image.network(existing!.logoUrl!, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.add_photo_alternate, size: 32, color: Colors.blueGrey)) : const Icon(Icons.add_photo_alternate, size: 32, color: Colors.blueGrey)),
                      ),
                    ),
                  ])),
                  const SizedBox(width: 16),
                  // Logo Abreviado
                  Expanded(child: Column(children: [
                    Text(l10n.get('abbr_logo_label'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () async {
                        final bytes = await _pickImageBytes();
                        if (bytes != null) setDs(() => pickedAbbrBytes = bytes);
                      },
                      child: Container(
                        width: 120, height: 80,
                        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
                        child: pickedAbbrBytes != null ? Image.memory(pickedAbbrBytes!, fit: BoxFit.contain) : (existing?.logoAbbrUrl != null ? Image.network(existing!.logoAbbrUrl!, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.add_photo_alternate, size: 32, color: Colors.blueGrey)) : const Icon(Icons.add_photo_alternate, size: 32, color: Colors.blueGrey)),
                      ),
                    ),
                  ])),
                ]),
                const Divider(height: 24),
                // ── GENERAL ───────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(children: [const Icon(Icons.table_chart_outlined, size: 18, color: Colors.grey), const SizedBox(width: 6), Text(l10n.get('general_summary_title'), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade600, letterSpacing: 1))]),
                ),
                _field(nameCtrl, l10n.get('company_name')),
                _field(abbrCtrl, l10n.get('company_abbr')),
                _field(domainCtrl, l10n.get('company_domain')),
                _colorField(primaryCtrl, l10n.get('primary_color'), setDs),
                _colorField(secondaryCtrl, l10n.get('secondary_color'), setDs),
                const Divider(height: 24),
                // ── CONTACT ───────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(children: [const Icon(Icons.contacts_outlined, size: 18, color: Colors.grey), const SizedBox(width: 6), Text(l10n.get('contact_info_title'), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade600, letterSpacing: 1))]),
                ),
                _field(emailCtrl, l10n.get('contact_email')),
                _field(phoneCtrl, l10n.get('contact_phone')),
                _field(waCtrl, 'WhatsApp'),
                _field(igCtrl, 'Instagram'),
                _field(fbCtrl, 'Facebook'),
                _field(tgCtrl, 'Telegram'),
                _field(lnCtrl, 'LinkedIn'),
                const Divider(height: 24),
                // ── REGIONAL ──────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(children: [const Icon(Icons.public, size: 18, color: Colors.grey), const SizedBox(width: 6), Text(l10n.get('regional_settings_title'), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade600, letterSpacing: 1))]),
                ),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: country,
                        decoration: InputDecoration(labelText: l10n.get('country_field'), border: const OutlineInputBorder(), isDense: true),
                        isExpanded: true,
                        items: LocationData.countries.map((c) => DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis))).toList(),
                        onChanged: (v) => setDs(() { country = v; state = null; }),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: state,
                        decoration: InputDecoration(labelText: l10n.get('state_field'), border: const OutlineInputBorder(), isDense: true),
                        isExpanded: true,
                        items: country != null
                            ? LocationData.statesFor(country!).map((s) => DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis))).toList()
                            : [],
                        onChanged: (v) => setDs(() => state = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: currencyCode,
                        decoration: InputDecoration(labelText: l10n.get('currency_label'), border: const OutlineInputBorder(), isDense: true),
                        isExpanded: true,
                        items: currencies.map((c) => DropdownMenuItem(value: c['code'], child: Text('${c['code']} - ${c['name']!}', overflow: TextOverflow.ellipsis))).toList(),
                        onChanged: (v) => setDs(() => currencyCode = v!),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: areaUnit,
                        decoration: InputDecoration(labelText: l10n.get('area_unit_label'), border: const OutlineInputBorder(), isDense: true),
                        items: [
                          DropdownMenuItem(value: 'm²', child: Text(l10n.get('m2'))),
                          DropdownMenuItem(value: 'ft²', child: Text(l10n.get('ft2'))),
                        ],
                        onChanged: (v) => setDs(() => areaUnit = v!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    SizedBox(
                      width: 180,
                      child: DropdownButtonFormField<String>(
                        value: language,
                        decoration: InputDecoration(labelText: l10n.get('language'), border: const OutlineInputBorder(), isDense: true),
                        items: const [
                          DropdownMenuItem(value: 'es', child: Text('Español')),
                          DropdownMenuItem(value: 'en', child: Text('English')),
                        ],
                        onChanged: (v) => setDs(() => language = v!),
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
                const Divider(height: 24),
                // ── PLAN & LIMITS ──────────────────────────────────
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(children: [const Icon(Icons.tune, size: 18, color: Colors.grey), const SizedBox(width: 6), Text(l10n.get('plan_limits_title'), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade600, letterSpacing: 1))]),
                ),
                DropdownButtonFormField<String>(
                  value: billingCycle,
                  decoration: InputDecoration(labelText: l10n.get('billing_cycle_label'), border: const OutlineInputBorder(), isDense: true),
                  items: const [
                    DropdownMenuItem(value: 'monthly', child: Text('Mensual (\$18/mo)')),
                    DropdownMenuItem(value: 'annual', child: Text('Anual (\$198/yr)')),
                  ],
                  onChanged: (v) => setDs(() => billingCycle = v!),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        readOnly: true,
                        initialValue: existing?.subscriptionStatus == 'trial'
                            ? (existing?.trialEndsAt != null 
                                ? DateFormat('yyyy-MM-dd').format(existing!.trialEndsAt!.subtract(const Duration(days: 7)))
                                : 'N/A')
                            : (existing?.subscriptionStartsAt != null 
                                ? DateFormat('yyyy-MM-dd').format(existing!.subscriptionStartsAt!) 
                                : 'N/A'),
                        decoration: InputDecoration(labelText: l10n.get('start_date_label'), border: const OutlineInputBorder(), isDense: true, prefixIcon: const Icon(Icons.calendar_today, size: 14)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        readOnly: true,
                        initialValue: existing?.subscriptionStatus == 'trial'
                            ? (existing?.trialEndsAt != null 
                                ? DateFormat('yyyy-MM-dd').format(existing!.trialEndsAt!) 
                                : 'N/A')
                            : (existing?.subscriptionEndsAt != null 
                                ? DateFormat('yyyy-MM-dd').format(existing!.subscriptionEndsAt!) 
                                : 'N/A'),
                        decoration: InputDecoration(labelText: l10n.get('expiration_date_label'), border: const OutlineInputBorder(), isDense: true, prefixIcon: const Icon(Icons.event_busy, size: 14)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _field(basePriceCtrl, l10n.get('base_price_label'), keyboardType: const TextInputType.numberWithOptions(decimal: true))),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        decoration: BoxDecoration(color: Colors.grey.shade100, border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(4)),
                        child: Text(
                          '${l10n.get('min_limit_label')}: \$${NumberFormat("#,###.00").format(lowerBound)}',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _field(maxPropertiesCtrl, l10n.get('max_props_label'), keyboardType: TextInputType.number)),
                    const SizedBox(width: 8),
                    Expanded(child: _field(maxPhotosCtrl, l10n.get('max_photos_label'), keyboardType: TextInputType.number)),
                  ],
                ),
                if (existing != null && (currentDiscount > 0 || bonusProps > 0)) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(ctx).brightness == Brightness.dark 
                          ? Colors.purple.withValues(alpha: 0.15) 
                          : Colors.purple.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(ctx).brightness == Brightness.dark 
                            ? Colors.purple.withValues(alpha: 0.4) 
                            : Colors.purple.shade100,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'RENDIMIENTO DE REFERIDOS (Strategy 3)', 
                          style: TextStyle(
                            fontSize: 11, 
                            fontWeight: FontWeight.bold, 
                            color: Theme.of(ctx).brightness == Brightness.dark 
                                ? Colors.purple.shade200 
                                : Colors.purple,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '• Dto. Factura Acumulado: -\$${NumberFormat("#,###.00").format(currentDiscount)}', 
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(ctx).brightness == Brightness.dark 
                                ? Colors.grey.shade300 
                                : Colors.black87,
                          ),
                        ),
                        Text(
                          '• Capacidad Ganada: +$bonusProps Inm. / +$bonusPhotos Fts.', 
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(ctx).brightness == Brightness.dark 
                                ? Colors.grey.shade300 
                                : Colors.black87,
                          ),
                        ),
                        Text(
                          '• Referidos Activos: $activeReferrals agencias', 
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(ctx).brightness == Brightness.dark 
                                ? Colors.grey.shade300 
                                : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const Divider(height: 24),
                SwitchListTile(title: Text(l10n.get('is_demo')), value: isDemo, onChanged: (v) => setDs(() => isDemo = v)),
                SwitchListTile(title: Text(l10n.get('is_active')), value: isActive, onChanged: (v) => setDs(() => isActive = v)),
                SwitchListTile(title: Text(l10n.get('carousel_title')), value: showCarousel, onChanged: (v) => setDs(() => showCarousel = v)),
                SwitchListTile(title: Text(l10n.get('show_referral_option')), value: showReferralMenu, onChanged: (v) => setDs(() => showReferralMenu = v)),
                SwitchListTile(title: Text(l10n.get('show_organic_affiliate')), value: showOrganicAffiliate, onChanged: (v) => setDs(() => showOrganicAffiliate = v)),
                SwitchListTile(title: Text(isSpanish ? 'Activar Agente IA (Ava)' : 'Enable AI Agent (Ava)'), value: hasAiAgent, onChanged: (v) => setDs(() => hasAiAgent = v)),
                if (hasAiAgent) ...[
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: aiModel,
                    decoration: InputDecoration(
                      labelText: isSpanish ? 'Modelo del Agente IA' : 'AI Agent Model',
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'gemini-flash-latest',
                        child: Text(isSpanish ? 'Gemini Flash (En Vivo)' : 'Gemini Flash (Live)'),
                      ),
                      DropdownMenuItem(
                        value: 'mock-test',
                        child: Text(isSpanish ? 'Simulador de Pruebas (Gratis)' : 'Test Simulator (Free)'),
                      ),
                    ],
                    onChanged: (v) => setDs(() => aiModel = v!),
                  ),
                  const SizedBox(height: 8),
                ],
              ]),
            ),
          ),
          actions: [
            if (isSaving) const CircularProgressIndicator(),
            if (!isSaving) TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.get('cancel'))),
            if (!isSaving) ElevatedButton(
              onPressed: () async {
                setDs(() => isSaving = true);
                try {
                  final company = Company(
                    id: existing?.id ?? '',
                    name: nameCtrl.text.trim(),
                    abbr: abbrCtrl.text.trim(),
                    domain: domainCtrl.text.trim(),
                    primaryColorHex: primaryCtrl.text.trim(),
                    secondaryColorHex: secondaryCtrl.text.trim(),
                    logoUrl: existing?.logoUrl,
                    logoAbbrUrl: existing?.logoAbbrUrl,
                    contactEmail: emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
                    contactPhone: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                    contactWhatsapp: waCtrl.text.trim().isEmpty ? null : waCtrl.text.trim(),
                    instagramUrl: igCtrl.text.trim().isEmpty ? null : igCtrl.text.trim(),
                    facebookUrl: fbCtrl.text.trim().isEmpty ? null : fbCtrl.text.trim(),
                    telegramUrl: tgCtrl.text.trim().isEmpty ? null : tgCtrl.text.trim(),
                    linkedinUrl: lnCtrl.text.trim().isEmpty ? null : lnCtrl.text.trim(),
                    isDemo: isDemo,
                    isActive: isActive,
                    showCarousel: showCarousel,
                    showReferralMenu: showReferralMenu,
                    showOrganicAffiliate: showOrganicAffiliate,
                    hasAiAgent: hasAiAgent,
                    aiModel: aiModel,
                    currencyCode: currencyCode,
                    currencySymbol: currencies.firstWhere((c) => c['code'] == currencyCode)['symbol']!,
                    areaUnit: areaUnit,
                    country: country,
                    state: state,
                    basePrice: double.tryParse(basePriceCtrl.text.replaceAll(',', '')) ?? 18.0,
                    maxProperties: int.tryParse(maxPropertiesCtrl.text.replaceAll(',', '')) ?? 20,
                    maxPhotosPerProperty: int.tryParse(maxPhotosCtrl.text.replaceAll(',', '')) ?? 10,
                    language: language,
                    billingCycle: billingCycle,
                    // Preservar todas las propiedades existentes que no se editan en este formulario
                    subscriptionStatus: existing?.subscriptionStatus ?? 'trial',
                    trialEndsAt: existing?.trialEndsAt,
                    subscriptionStartsAt: existing?.subscriptionStartsAt,
                    subscriptionEndsAt: existing?.subscriptionEndsAt,
                    referralDiscount: existing?.referralDiscount ?? 0.0,
                    referralCode: existing?.referralCode,
                    referredByCompanyId: existing?.referredByCompanyId,
                    referralEmailEntered: existing?.referralEmailEntered,
                    suspendedAt: existing?.suspendedAt,
                    graceEndsAt: existing?.graceEndsAt,
                    carouselStrategy: existing?.carouselStrategy ?? 'manual',
                    carouselAnimation: existing?.carouselAnimation ?? 'slide',
                    city: existing?.city,
                    contactName: existing?.contactName,
                    referralBonusPhotos: existing?.referralBonusPhotos ?? 0,
                    referralBonusProperties: existing?.referralBonusProperties ?? 0,
                    referredBySalesperson: existing?.referredBySalesperson,
                    acquisitionChannel: existing?.acquisitionChannel ?? 'organic',
                    defaultCommissionPct: existing?.defaultCommissionPct ?? 5.0,
                    defaultManagementPct: existing?.defaultManagementPct ?? 10.0,
                    defaultSaleCommissionPct: existing?.defaultSaleCommissionPct ?? 5.0,
                    defaultAgencySplitPct: existing?.defaultAgencySplitPct ?? 50.0,
                    defaultResidentialRentalMonths: existing?.defaultResidentialRentalMonths ?? 1.0,
                    defaultCommercialRentalMonths: existing?.defaultCommercialRentalMonths ?? 1.0,
                    defaultAdminCommissionPct: existing?.defaultAdminCommissionPct ?? 10.0,
                    taxLabel: existing?.taxLabel ?? 'IVA',
                    taxPercentage: existing?.taxPercentage ?? 16.0,
                  );
                  final saved = await CompanyService.upsertCompany(company);
                  // Subir logos con bytes reales (no blob URLs)
                  if (pickedLogoBytes != null) {
                    final compressed = await ImageUtils.compressImage(pickedLogoBytes!);
                    await CompanyService.uploadCompanyLogo(saved.id, compressed, isAbbreviated: false);
                  }
                  if (pickedAbbrBytes != null) {
                    final compressed = await ImageUtils.compressImage(pickedAbbrBytes!);
                    await CompanyService.uploadCompanyLogo(saved.id, compressed, isAbbreviated: true);
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                  _loadCompanies();
                } catch (e) {
                  if (ctx.mounted) { setDs(() => isSaving = false); ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red)); }
                }
              },
              child: Text(l10n.get('save')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, {TextInputType? keyboardType}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: TextField(
      controller: ctrl, 
      keyboardType: keyboardType, 
      inputFormatters: keyboardType == TextInputType.number || keyboardType?.decimal == true ? [DecimalInputFormatter()] : null,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), isDense: true)
    ),
  );

  Widget _colorField(TextEditingController ctrl, String label, StateSetter setDs) {
    Color? parsed;
    try { final h = ctrl.text.trim().replaceAll('#', ''); if (h.length == 6) parsed = Color(int.parse('FF$h', radix: 16)); } catch (_) {}
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: ctrl,
        onChanged: (_) => setDs(() {}),
        decoration: InputDecoration(
          labelText: label, border: const OutlineInputBorder(), isDense: true,
          prefixIcon: parsed != null ? Container(width: 24, height: 24, margin: const EdgeInsets.all(12), decoration: BoxDecoration(color: parsed, shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade400))) : const Icon(Icons.color_lens_outlined),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final appProvider = context.watch<AppProvider>();
    return Scaffold(
      floatingActionButton: _tabController.index == 1
          ? FloatingActionButton.extended(onPressed: _showCompanyDialog, icon: const Icon(Icons.add_business), label: Text(l10n.get('new_company')))
          : null,
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l10n.get('super_admin_panel'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.white)),
          const Text('Alveo — Gestión Inmobiliaria', style: TextStyle(fontSize: 11, color: Colors.white70)),
        ]),
        actions: [
          IconButton(tooltip: l10n.get('refresh'), icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _loadCompanies),
          IconButton(tooltip: l10n.get('logout'), icon: const Icon(Icons.logout, color: Colors.white), onPressed: () async {
            await SupabaseService().signOut();
            appProvider.setUserProfile(null);
            if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
          }),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          onTap: (_) => setState(() {}),
          indicatorColor: Colors.amber, labelColor: Colors.white, unselectedLabelColor: Colors.white60,
          tabs: [
            Tab(icon: const Icon(Icons.notifications_active_outlined), text: l10n.get('tab_requests')),
            Tab(icon: const Icon(Icons.business), text: l10n.get('tab_companies')), 
            Tab(icon: const Icon(Icons.people), text: l10n.get('tab_users')),
            Tab(icon: const Icon(Icons.payment), text: l10n.get('super_admin_billing_tab_title')),
            Tab(icon: const Icon(Icons.campaign_outlined), text: l10n.get('tab_marketing')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          SuperAdminRequestsTab(onApproved: _loadCompanies),
          _isLoading ? const Center(child: CircularProgressIndicator()) : _companies.isEmpty ? Center(child: Text(l10n.get('no_companies')))
              : RefreshIndicator(onRefresh: _loadCompanies, child: ListView.builder(padding: const EdgeInsets.all(24), itemCount: _companies.length, itemBuilder: (_, i) => _companyCard(_companies[i], l10n))),
          const SuperAdminUsersScreen(),
          SuperAdminBillingTab(companies: _companies, onRefreshRequested: _loadCompanies),
          const SuperAdminMarketingTab(),
        ],
      ),
    );
  }

  Widget _companyCard(Company c, AppLocalizations l10n) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16), elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: c.isActive ? c.primaryColor : Colors.grey.shade400, width: 1.5)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        leading: CircleAvatar(backgroundColor: c.primaryColor, child: Text(c.abbr.isNotEmpty ? c.abbr.substring(0, 1).toUpperCase() : '?', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
        title: Row(children: [Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold)), const SizedBox(width: 8), if (c.isDemo) Chip(label: const Text('DEMO', style: TextStyle(fontSize: 10, color: Colors.white)), backgroundColor: Colors.orange, padding: EdgeInsets.zero, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap)]),
        subtitle: Text('${c.domain}  ·  abbr: ${c.abbr}', style: TextStyle(color: Colors.grey.shade600)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min, 
          children: [
            IconButton(tooltip: l10n.get('edit'), icon: const Icon(Icons.edit_outlined, color: Colors.blue), onPressed: () => _showCompanyDialog(c)), 
            const SizedBox(width: 4),
            IconButton(tooltip: l10n.get('delete'), icon: const Icon(Icons.delete_forever_outlined, color: Colors.red), onPressed: () => _deleteCompany(c)),
            const SizedBox(width: 8), 
            _statusChip(c, l10n)
          ]
        ),
      ),
    );
  }

  Widget _statusChip(Company c, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: c.isActive ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.isActive ? Colors.green.shade700 : Colors.red.shade700, width: 1),
      ),
      child: Text(c.isActive ? l10n.get('active') : l10n.get('inactive'), style: TextStyle(color: c.isActive ? Colors.green.shade800 : Colors.red.shade800, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}
class DecimalInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;
    if (newValue.text == '.') return newValue;
    
    String cleanText = newValue.text.replaceAll(RegExp(r'[^\d.]'), '');
    int dotCount = '.'.allMatches(cleanText).length;
    if (dotCount > 1) return oldValue;
    
    final parts = cleanText.split('.');
    String integerPart = parts[0];
    String? decimalPart = parts.length > 1 ? parts[1] : null;

    if (integerPart.isNotEmpty) {
      try {
        final formatter = NumberFormat('#,###');
        integerPart = formatter.format(int.parse(integerPart.replaceAll(',', '')));
      } catch (e) {
        return oldValue;
      }
    }

    String formatted = integerPart;
    if (decimalPart != null) {
      formatted += '.$decimalPart';
    } else if (cleanText.endsWith('.')) {
      formatted += '.';
    }

    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
