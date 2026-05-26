import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/company.dart';
import '../../services/supabase_service.dart';
import '../../services/app_localizations.dart';
import '../../providers/company_provider.dart';
import '../../services/app_themes.dart';
import '../../widgets/admin_drawer.dart';
import '../../utils/image_utils.dart';
import '../../services/app_provider.dart';
import '../../data/location_data.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../utils/payment_dialog_utils.dart';
import 'admin_billing_history_screen.dart';

class AdminCompanySettings extends StatefulWidget {
  const AdminCompanySettings({super.key});

  @override
  State<AdminCompanySettings> createState() => _AdminCompanySettingsState();
}

class _AdminCompanySettingsState extends State<AdminCompanySettings> {
  final _formKey = GlobalKey<FormState>();
  final _service = SupabaseService();
  bool _isSaving = false;

  late TextEditingController _nameController;
  late TextEditingController _nameEsController;
  late TextEditingController _nameEnController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _whatsappController;
  late TextEditingController _instagramController;
  late TextEditingController _facebookController;
  late TextEditingController _telegramController;
  late TextEditingController _linkedinController;
  late TextEditingController _primaryColorController;
  late TextEditingController _secondaryColorController;
  late TextEditingController _defaultCommissionController;
  late TextEditingController _defaultManagementController;
  late TextEditingController _defaultSaleCommissionController;
  late TextEditingController _defaultAgencySplitController;
  late TextEditingController _defaultAgentsSplitController;
  late TextEditingController _defaultResidentialRentalMonthsController;
  late TextEditingController _defaultCommercialRentalMonthsController;
  late TextEditingController _defaultAdminCommissionController;
  late TextEditingController _taxLabelController;
  late TextEditingController _taxPercentageController;

  String? _logoUrl;
  String? _logoAbbrUrl;
  bool _showCarousel = true;
  String _carouselStrategy = 'manual';
  String _areaUnit = 'm²';
  String _carouselAnimation = 'slide';
  bool _showReferralMenu = true;
  bool _showOrganicAffiliate = true;
  bool _hasAiAgent = true;
  String _aiModel = 'gemini-flash-latest';
  String _acquisitionChannel = 'organic';
  String _referredAlias = '';
  String _referralEmail = '';
  int _activeReferralsCount = 0;
  String _language = 'es';
  String _billingCycle = 'monthly';

  // Regional
  String? _country;
  String? _state;
  String? _city;
  String _currencyCode = 'USD';

  static const List<Map<String, String>> _currencies = [
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

  @override
  void initState() {
    super.initState();
    final company = Provider.of<CompanyProvider>(context, listen: false).currentCompany;
    _nameController = TextEditingController(text: company.name);
    _nameEsController = TextEditingController(text: company.nameEs ?? '');
    _nameEnController = TextEditingController(text: company.nameEn ?? '');
    _emailController = TextEditingController(text: company.contactEmail ?? '');
    _phoneController = TextEditingController(text: company.contactPhone ?? '');
    _whatsappController = TextEditingController(text: company.contactWhatsapp ?? '');
    _instagramController = TextEditingController(text: company.instagramUrl ?? '');
    _facebookController = TextEditingController(text: company.facebookUrl ?? '');
    _telegramController = TextEditingController(text: company.telegramUrl ?? '');
    _linkedinController = TextEditingController(text: company.linkedinUrl ?? '');
    _primaryColorController = TextEditingController(text: company.primaryColorHex);
    _secondaryColorController = TextEditingController(text: company.secondaryColorHex);
    _logoUrl = company.logoUrl;
    _logoAbbrUrl = company.logoAbbrUrl;
    _showCarousel = company.showCarousel;
    _carouselStrategy = company.carouselStrategy;
    _country = company.country;
    _state = company.state;
    _city = company.city;
    _currencyCode = company.currencyCode;
    _areaUnit = company.areaUnit;
    _carouselAnimation = company.carouselAnimation;
    _showReferralMenu = company.showReferralMenu;
    _showOrganicAffiliate = company.showOrganicAffiliate;
    _hasAiAgent = company.hasAiAgent;
    _aiModel = company.aiModel;
    _acquisitionChannel = company.acquisitionChannel;
    _referredAlias = company.referredBySalesperson ?? '';
    _referralEmail = company.referralEmailEntered ?? '';
    _activeReferralsCount = company.referralDiscount.toInt(); // Aprox \$1 = 1 referred company
    _language = company.language;
    _billingCycle = company.billingCycle;
    _defaultCommissionController = TextEditingController(text: company.defaultCommissionPct.toString());
    _defaultManagementController = TextEditingController(text: company.defaultManagementPct.toString());
    _defaultSaleCommissionController = TextEditingController(text: company.defaultSaleCommissionPct.toString());
    _defaultAgencySplitController = TextEditingController(text: company.defaultAgencySplitPct.toString());
    _defaultAgentsSplitController = TextEditingController(text: (100 - company.defaultAgencySplitPct).toString());
    _defaultResidentialRentalMonthsController = TextEditingController(text: company.defaultResidentialRentalMonths.toString());
    _defaultCommercialRentalMonthsController = TextEditingController(text: company.defaultCommercialRentalMonths.toString());
    _defaultAdminCommissionController = TextEditingController(text: company.defaultAdminCommissionPct.toString());
    _taxLabelController = TextEditingController(text: company.taxLabel);
    _taxPercentageController = TextEditingController(text: company.taxPercentage.toString());

    // Split logic: agents % = 100 - agency %
    _defaultAgencySplitController.addListener(() {
      final agency = double.tryParse(_defaultAgencySplitController.text) ?? 0;
      final agents = (100 - agency).clamp(0, 100);
      _defaultAgentsSplitController.text = agents.toString();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameEsController.dispose();
    _nameEnController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _instagramController.dispose();
    _facebookController.dispose();
    _telegramController.dispose();
    _linkedinController.dispose();
    _primaryColorController.dispose();
    _secondaryColorController.dispose();
    _defaultCommissionController.dispose();
    _defaultManagementController.dispose();
    _defaultSaleCommissionController.dispose();
    _defaultAgencySplitController.dispose();
    _defaultAgentsSplitController.dispose();
    _defaultResidentialRentalMonthsController.dispose();
    _defaultCommercialRentalMonthsController.dispose();
    _defaultAdminCommissionController.dispose();
    _taxLabelController.dispose();
    _taxPercentageController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool isAbbreviated) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image == null) return;

    setState(() => _isSaving = true);
    try {
      final bytes = await image.readAsBytes();
      final compressed = await ImageUtils.compressImage(bytes);
      final extension = image.path.split('.').last;
      final companyId = Provider.of<CompanyProvider>(context, listen: false).companyId;
      final fileName = '${companyId}_${isAbbreviated ? "abbr" : "full"}_${DateTime.now().millisecondsSinceEpoch}.$extension';
      
      final url = await _service.uploadCompanyLogo(fileName, compressed, contentType: 'image/jpeg');
      setState(() {
        if (isAbbreviated) {
          _logoAbbrUrl = url;
        } else {
          _logoUrl = url;
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final companyProv = Provider.of<CompanyProvider>(context, listen: false);
      final old = companyProv.currentCompany;
      
      debugPrint('[CompanySettings] Guardando empresa ID: ${old.id}');
      
      // Helper: convierte cadena vacía a null para campos opcionales en la BD
      String? _nullIfEmpty(String text) => text.trim().isEmpty ? null : text.trim();

      final updated = old.copyWith(
        name: _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : old.name,
        nameEs: _nullIfEmpty(_nameEsController.text),
        nameEn: _nullIfEmpty(_nameEnController.text),
        contactEmail: _nullIfEmpty(_emailController.text),
        contactPhone: _nullIfEmpty(_phoneController.text),
        contactWhatsapp: _nullIfEmpty(_whatsappController.text),
        instagramUrl: _nullIfEmpty(_instagramController.text),
        facebookUrl: _nullIfEmpty(_facebookController.text),
        telegramUrl: _nullIfEmpty(_telegramController.text),
        linkedinUrl: _nullIfEmpty(_linkedinController.text),
        primaryColorHex: _nullIfEmpty(_primaryColorController.text) ?? old.primaryColorHex,
        secondaryColorHex: _nullIfEmpty(_secondaryColorController.text) ?? old.secondaryColorHex,
        logoUrl: _logoUrl,
        logoAbbrUrl: _logoAbbrUrl,
        showCarousel: _showCarousel,
        carouselStrategy: _carouselStrategy,
        country: _country,
        state: _state,
        city: _city,
        currencyCode: _currencyCode,
        currencySymbol: _currencies.firstWhere((c) => c['code'] == _currencyCode, orElse: () => _currencies.first)['symbol']!,
        areaUnit: _areaUnit,
        carouselAnimation: _carouselAnimation,
        showReferralMenu: _showReferralMenu,
        showOrganicAffiliate: _showOrganicAffiliate,
        hasAiAgent: _hasAiAgent,
        aiModel: _aiModel,
        acquisitionChannel: _acquisitionChannel,
        referredBySalesperson: _nullIfEmpty(_referredAlias),
        referralEmailEntered: _nullIfEmpty(_referralEmail),
        language: _language,
        billingCycle: _billingCycle,
        defaultCommissionPct: double.tryParse(_defaultCommissionController.text) ?? old.defaultCommissionPct,
        defaultManagementPct: double.tryParse(_defaultManagementController.text) ?? old.defaultManagementPct,
        defaultSaleCommissionPct: double.tryParse(_defaultSaleCommissionController.text) ?? old.defaultSaleCommissionPct,
        defaultAgencySplitPct: double.tryParse(_defaultAgencySplitController.text) ?? old.defaultAgencySplitPct,
        defaultResidentialRentalMonths: double.tryParse(_defaultResidentialRentalMonthsController.text) ?? old.defaultResidentialRentalMonths,
        defaultCommercialRentalMonths: double.tryParse(_defaultCommercialRentalMonthsController.text) ?? old.defaultCommercialRentalMonths,
        defaultAdminCommissionPct: double.tryParse(_defaultAdminCommissionController.text) ?? old.defaultAdminCommissionPct,
        taxLabel: _taxLabelController.text.trim().isNotEmpty ? _taxLabelController.text.trim() : old.taxLabel,
        taxPercentage: double.tryParse(_taxPercentageController.text) ?? old.taxPercentage,
      );

      // 1. Guardar en BD
      await _service.updateCompany(updated);
      
      // 2. Recargar datos frescos desde BD para asegurar consistencia
      final freshRaw = await Supabase.instance.client
          .from('companies')
          .select()
          .eq('id', updated.id)
          .single();
      final freshCompany = Company.fromJson(freshRaw);
      companyProv.updateCurrentCompany(freshCompany);
      
      // 3. Refrescar campos del formulario con datos reales de BD
      if (mounted) {
        setState(() {
          _logoUrl = freshCompany.logoUrl;
          _logoAbbrUrl = freshCompany.logoAbbrUrl;
          _showCarousel = freshCompany.showCarousel;
          _carouselStrategy = freshCompany.carouselStrategy;
          _country = freshCompany.country;
          _state = freshCompany.state;
          _city = freshCompany.city;
          _currencyCode = freshCompany.currencyCode;
          _areaUnit = freshCompany.areaUnit;
          _carouselAnimation = freshCompany.carouselAnimation;
          _showReferralMenu = freshCompany.showReferralMenu;
          _showOrganicAffiliate = freshCompany.showOrganicAffiliate;
          _hasAiAgent = freshCompany.hasAiAgent;
          _aiModel = freshCompany.aiModel;
          _acquisitionChannel = freshCompany.acquisitionChannel;
          _referredAlias = freshCompany.referredBySalesperson ?? '';
          _referralEmail = freshCompany.referralEmailEntered ?? '';
          _activeReferralsCount = freshCompany.referralDiscount.toInt();
          _language = freshCompany.language;
          _billingCycle = freshCompany.billingCycle;
        });
        _nameController.text = freshCompany.name;
        _nameEsController.text = freshCompany.nameEs ?? '';
        _nameEnController.text = freshCompany.nameEn ?? '';
        _emailController.text = freshCompany.contactEmail ?? '';
        _phoneController.text = freshCompany.contactPhone ?? '';
        _whatsappController.text = freshCompany.contactWhatsapp ?? '';
        _instagramController.text = freshCompany.instagramUrl ?? '';
        _facebookController.text = freshCompany.facebookUrl ?? '';
        _telegramController.text = freshCompany.telegramUrl ?? '';
        _linkedinController.text = freshCompany.linkedinUrl ?? '';
        _primaryColorController.text = freshCompany.primaryColorHex;
        _secondaryColorController.text = freshCompany.secondaryColorHex;
        _defaultCommissionController.text = freshCompany.defaultCommissionPct.toString();
        _defaultManagementController.text = freshCompany.defaultManagementPct.toString();
        _defaultSaleCommissionController.text = freshCompany.defaultSaleCommissionPct.toString();
        _defaultAgencySplitController.text = freshCompany.defaultAgencySplitPct.toString();
        _defaultAgentsSplitController.text = (100 - freshCompany.defaultAgencySplitPct).toString();
        _defaultResidentialRentalMonthsController.text = freshCompany.defaultResidentialRentalMonths.toString();
        _defaultCommercialRentalMonthsController.text = freshCompany.defaultCommercialRentalMonths.toString();
        _defaultAdminCommissionController.text = freshCompany.defaultAdminCommissionPct.toString();
        _taxLabelController.text = freshCompany.taxLabel;
        _taxPercentageController.text = freshCompany.taxPercentage.toString();
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).get('success_company_updated')),
            backgroundColor: Colors.green,
          )
        );
      }
    } catch (e) {
      debugPrint('[CompanySettings] ❌ Error al guardar: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 8),
          )
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isSpanish = l10n.locale.languageCode == 'es';
    final userRole = context.watch<AppProvider>().userProfile?.role ?? 'agent';
    final isSuperAdmin = userRole == 'super_admin';

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.get('edit_company')),
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
      ),
      drawer: const AdminDrawer(),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(l10n.get('company_logos'), Icons.image_outlined),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildLogoPicker(l10n.get('full_logo'), _logoUrl, false),
                        const SizedBox(width: 24),
                        _buildLogoPicker(l10n.get('abbr_logo'), _logoAbbrUrl, true),
                      ],
                    ),
                    const Divider(height: 48),
                    _buildSectionHeader(l10n.get('summary_title'), Icons.business_outlined),
                    const SizedBox(height: 16),
                    _buildTextField(_nameController, l10n.get('company_name'), required: true),
                    const SizedBox(height: 16),
                    const Divider(height: 48),
                    _buildSectionHeader(l10n.get('contact_us'), Icons.contact_mail_outlined),
                    const SizedBox(height: 16),
                    _buildTextField(_emailController, l10n.get('contact_email'), isEmail: true),
                    _buildTextField(_phoneController, l10n.get('contact_phone')),
                    const Divider(height: 48),
                    _buildSectionHeader(l10n.get('social_networks'), Icons.share_outlined),
                    const SizedBox(height: 16),
                    _buildTextField(_whatsappController, l10n.get('whatsapp_full_label')),
                    _buildTextField(_instagramController, l10n.get('instagram_label') ?? 'Instagram URL'),
                    _buildTextField(_facebookController, l10n.get('facebook_label') ?? 'Facebook URL'),
                    _buildTextField(_telegramController, l10n.get('telegram_label') ?? 'Telegram URL'),
                    _buildTextField(_linkedinController, 'LinkedIn URL'),
                    const Divider(height: 48),
                    _buildSectionHeader(l10n.get('referral_affiliate_settings'), Icons.handshake_outlined),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: Text(l10n.get('show_referral_option')),
                      subtitle: Text(l10n.get('show_referral_option_desc')),
                      value: _showReferralMenu,
                      onChanged: (v) => setState(() => _showReferralMenu = v),
                      activeColor: Colors.purple,
                    ),
                    SwitchListTile(
                      title: Text(l10n.get('show_organic_affiliate')),
                      subtitle: Text(l10n.get('show_organic_affiliate_desc')),
                      value: _showOrganicAffiliate,
                      onChanged: (v) => setState(() => _showOrganicAffiliate = v),
                      activeColor: Colors.purple,
                    ),
                    const Divider(height: 48),
                    _buildSectionHeader(l10n.get('ava_title'), Icons.auto_awesome),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: Text(isSpanish ? 'Activar Ava (Asistente IA)' : 'Enable Ava (AI Assistant)'),
                      subtitle: Text(isSpanish 
                        ? 'Permite a los clientes chatear con Ava y buscar propiedades mediante texto o notas de voz.' 
                        : 'Allows clients to chat with Ava and search properties via text or voice notes.'),
                      value: _hasAiAgent,
                      onChanged: (v) => setState(() => _hasAiAgent = v),
                      activeColor: AppThemes.primaryGreen,
                    ),
                    if (_hasAiAgent) ...[
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: DropdownButtonFormField<String>(
                          value: _aiModel,
                          decoration: InputDecoration(
                            labelText: isSpanish ? 'Modelo del Agente IA' : 'AI Agent Model',
                            filled: true,
                            fillColor: Theme.of(context).cardColor,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                          items: [
                            DropdownMenuItem(
                              value: 'gemini-flash-latest',
                              child: Text(isSpanish ? 'Gemini Flash (Producción / En Vivo)' : 'Gemini Flash (Production / Live)'),
                            ),
                            DropdownMenuItem(
                              value: 'mock-test',
                              child: Text(isSpanish ? 'Simulador de Pruebas (Ilimitado / Gratis)' : 'Test Simulator (Unlimited / Free)'),
                            ),
                          ],
                          onChanged: (v) => setState(() => _aiModel = v!),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    // Conteo & Acquisition (ONLY FOR SUPER ADMIN)
                    if (isSuperAdmin) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark 
                              ? Colors.purple.withValues(alpha: 0.15) 
                              : Colors.purple.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Theme.of(context).brightness == Brightness.dark 
                                ? Colors.purple.withValues(alpha: 0.4) 
                                : Colors.purple.shade100,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.group_add, 
                              color: Theme.of(context).brightness == Brightness.dark 
                                  ? Colors.purple.shade200 
                                  : Colors.purple,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                l10n.get('referred_companies_count').replaceFirst('{0}', _activeReferralsCount.toString()),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold, 
                                  color: Theme.of(context).brightness == Brightness.dark 
                                      ? Colors.purple.shade100 
                                      : Colors.purple,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(l10n.get('who_acquired_company'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _acquisitionChannel,
                        decoration: InputDecoration(filled: true, fillColor: Theme.of(context).cardColor, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                        items: [
                          DropdownMenuItem(value: 'organic', child: Text(l10n.get('channel_organic'))),
                          DropdownMenuItem(value: 'salesperson', child: Text(l10n.get('channel_salesperson'))),
                          DropdownMenuItem(value: 'broker', child: Text(l10n.get('channel_broker'))),
                        ],
                        onChanged: (v) => setState(() => _acquisitionChannel = v!),
                      ),
                      if (_acquisitionChannel == 'salesperson') ...[
                        const SizedBox(height: 16),
                        TextFormField(
                          initialValue: _referredAlias,
                          onChanged: (v) => _referredAlias = v,
                          decoration: InputDecoration(labelText: l10n.get('salesperson_alias'), filled: true, fillColor: Theme.of(context).cardColor, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                        ),
                      ],
                      if (_acquisitionChannel == 'broker') ...[
                        const SizedBox(height: 16),
                        TextFormField(
                          initialValue: _referralEmail,
                          onChanged: (v) => _referralEmail = v,
                          decoration: InputDecoration(labelText: l10n.get('inviting_company_email'), filled: true, fillColor: Theme.of(context).cardColor, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                        ),
                      ],
                    ],
                    const Divider(height: 48),
                    _buildSectionHeader(l10n.get('regional_settings'), Icons.public_outlined),
                    const SizedBox(height: 16),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final bool isMobile = constraints.maxWidth < 600;
                        
                        Widget _buildDropdown({required Widget child}) {
                          return isMobile ? Padding(padding: const EdgeInsets.only(bottom: 16), child: child) : Expanded(child: child);
                        }
                        
                        final List<Widget> row1 = [
                          _buildDropdown(
                            child: DropdownButtonFormField<String>(
                              isExpanded: true,
                              value: _country,
                              decoration: InputDecoration(labelText: l10n.get('country_field'), filled: true, fillColor: Theme.of(context).cardColor, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                              items: LocationData.countries.map((c) => DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis))).toList(),
                              onChanged: (v) => setState(() { _country = v; _state = null; _city = null; }),
                            ),
                          ),
                          if (!isMobile) const SizedBox(width: 16),
                          _buildDropdown(
                            child: DropdownButtonFormField<String>(
                              isExpanded: true,
                              value: _state,
                              decoration: InputDecoration(labelText: l10n.get('state_field'), filled: true, fillColor: Theme.of(context).cardColor, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                              items: _country != null
                                  ? LocationData.statesFor(_country!).map((s) => DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis))).toList()
                                  : [],
                              onChanged: (v) => setState(() { _state = v; _city = null; }),
                            ),
                          ),
                          if (!isMobile) const SizedBox(width: 16),
                          _buildDropdown(
                            child: DropdownButtonFormField<String>(
                              isExpanded: true,
                              value: _city,
                              decoration: InputDecoration(labelText: l10n.get('city_field'), filled: true, fillColor: Theme.of(context).cardColor, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                              items: (_country != null && _state != null)
                                  ? LocationData.citiesFor(_country!, _state!).map((c) => DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis))).toList()
                                  : [],
                              onChanged: (v) => setState(() => _city = v),
                            ),
                          ),
                        ];

                        final List<Widget> row2 = [
                          _buildDropdown(
                            child: DropdownButtonFormField<String>(
                              isExpanded: true,
                              value: _currencyCode,
                              decoration: InputDecoration(labelText: l10n.get('currency_label_field'), filled: true, fillColor: Theme.of(context).cardColor, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                              items: _currencies.map((c) => DropdownMenuItem(value: c['code'], child: Text('${c['code']} - ${c['name']!}', overflow: TextOverflow.ellipsis))).toList(),
                              onChanged: (v) => setState(() => _currencyCode = v!),
                            ),
                          ),
                          if (!isMobile) const SizedBox(width: 16),
                          _buildDropdown(
                            child: DropdownButtonFormField<String>(
                              isExpanded: true,
                              value: _areaUnit,
                              decoration: InputDecoration(labelText: l10n.get('area_unit_label'), filled: true, fillColor: Theme.of(context).cardColor, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                              items: [
                                DropdownMenuItem(value: 'm²', child: Text(l10n.get('meters_unit'), overflow: TextOverflow.ellipsis)),
                                DropdownMenuItem(value: 'ft²', child: Text(l10n.get('feet_unit'), overflow: TextOverflow.ellipsis)),
                              ],
                              onChanged: (v) => setState(() => _areaUnit = v!),
                            ),
                          ),
                          if (!isMobile) const Spacer(),
                        ];

                        final List<Widget> row3 = [
                          _buildDropdown(
                            child: DropdownButtonFormField<String>(
                              isExpanded: true,
                              value: _language,
                              decoration: InputDecoration(
                                labelText: l10n.get('language_label'), 
                                filled: true,
                                fillColor: Theme.of(context).cardColor,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'es', child: Text('Español', overflow: TextOverflow.ellipsis)),
                                DropdownMenuItem(value: 'en', child: Text('English', overflow: TextOverflow.ellipsis)),
                              ],
                              onChanged: (v) => setState(() => _language = v!),
                            ),
                          ),
                          if (!isMobile) const Spacer(flex: 2),
                        ];

                        return Column(
                          children: [
                            if (isMobile) ...row1 else Row(children: row1),
                            if (!isMobile) const SizedBox(height: 16),
                            if (isMobile) ...row2 else Row(children: row2),
                            if (!isMobile) const SizedBox(height: 16),
                            if (isMobile) ...row3 else Row(children: row3),
                          ],
                        );
                      },
                    ),
                    const Divider(height: 48),
                    _buildSectionHeader(l10n.get('commission_settings'), Icons.account_balance_wallet_outlined),
                    const SizedBox(height: 16),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final bool isMobile = constraints.maxWidth < 600;
                        
                        Widget _buildCard({required String title, required List<Widget> children}) {
                          return Card(
                            elevation: 0,
                            color: Theme.of(context).cardColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppThemes.primaryGreen),
                                  ),
                                  const SizedBox(height: 16),
                                  ...children,
                                ],
                              ),
                            ),
                          );
                        }

                        final salesCard = _buildCard(
                          title: l10n.get('property_sales'),
                          children: [
                            _buildTextField(
                              _defaultSaleCommissionController, 
                              l10n.get('total_commission'),
                              isNumber: true,
                              suffix: const Text('%', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTextField(
                                    _defaultAgencySplitController, 
                                    l10n.get('agency_label'),
                                    isNumber: true,
                                    suffix: const Text('%', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildTextField(
                                    _defaultAgentsSplitController, 
                                    l10n.get('agents_label'),
                                    isNumber: true,
                                    enabled: false,
                                    suffix: const Text('%', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              l10n.get('split_auto_calc'),
                              style: const TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: Colors.grey),
                            ),
                          ],
                        );

                        final rentalsCard = _buildCard(
                          title: l10n.get('rentals_one_time'),
                          children: [
                            _buildTextField(
                              _defaultResidentialRentalMonthsController, 
                              l10n.get('residential_months'),
                              isNumber: true,
                              suffix: Icon(Icons.home_outlined, size: 18, color: Colors.grey.shade400),
                            ),
                            _buildTextField(
                              _defaultCommercialRentalMonthsController, 
                              l10n.get('commercial_months'),
                              isNumber: true,
                              suffix: Icon(Icons.business_outlined, size: 18, color: Colors.grey.shade400),
                            ),
                          ],
                        );

                        final adminCard = _buildCard(
                          title: l10n.get('rental_management_title'),
                          children: [
                            _buildTextField(
                              _defaultAdminCommissionController, 
                              l10n.get('monthly_commission'),
                              isNumber: true,
                              suffix: const Text('%', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.get('rental_fee_pct'),
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        );

                        final taxCard = _buildCard(
                          title: l10n.get('taxes_billing'),
                          children: [
                            _buildTextField(
                              _taxLabelController, 
                              l10n.get('tax_label_field'),
                              hint: 'IVA, TAX, IGV...',
                            ),
                            _buildTextField(
                              _taxPercentageController, 
                              l10n.get('tax_percentage_field'),
                              isNumber: true,
                              suffix: const Text('%', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            Text(
                              l10n.get('legal_entity_tax_note'),
                              style: const TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: Colors.grey),
                            ),
                          ],
                        );

                        if (isMobile) {
                          return Column(
                            children: [
                              salesCard,
                              const SizedBox(height: 12),
                              rentalsCard,
                              const SizedBox(height: 12),
                              adminCard,
                              const SizedBox(height: 12),
                              taxCard,
                            ],
                          );
                        } else {
                          return Column(
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: salesCard),
                                  const SizedBox(width: 12),
                                  Expanded(child: rentalsCard),
                                  const SizedBox(width: 12),
                                  Expanded(child: adminCard),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(child: taxCard),
                                  if (!isMobile) const Expanded(child: SizedBox()),
                                  if (!isMobile) const Expanded(child: SizedBox()),
                                ],
                              ),
                            ],
                          );
                        }
                      },
                    ),
                    const Divider(height: 48),

                    // PLAN & SUSCRIPCIÓN
                    _buildSectionHeader(l10n.get('plan_subscription'), Icons.credit_card_outlined),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark 
                            ? Colors.blue.withValues(alpha: 0.2) 
                            : Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).brightness == Brightness.dark 
                              ? Colors.blue.withValues(alpha: 0.5) 
                              : Colors.blue.shade100,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                l10n.get('plan_status'),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: context.watch<CompanyProvider>().currentCompany.subscriptionStatus == 'trial' ? Colors.orange : Colors.green,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  context.watch<CompanyProvider>().currentCompany.subscriptionStatus.toUpperCase(),
                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Icons.timer_outlined, size: 20, color: Colors.blue),
                              const SizedBox(width: 8),
                              Text(
                                l10n.get('days_remaining_label').replaceFirst('{0}', _calculateRemainingDays(context.watch<CompanyProvider>().currentCompany).toString()),
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: _billingCycle,
                            onChanged: context.watch<AppProvider>().isSuperAdmin 
                                ? (v) => setState(() => _billingCycle = v!) 
                                : null, // Disable if not SuperAdmin
                            decoration: InputDecoration(
                              labelText: l10n.get('billing_cycle_label'),
                              filled: true,
                              fillColor: Theme.of(context).brightness == Brightness.dark 
                                  ? Colors.black26 
                                  : Colors.white70,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            items: [
                              DropdownMenuItem(value: 'monthly', child: Text('${l10n.get('monthly_short')} (\$18/mes)')),
                              DropdownMenuItem(value: 'annual', child: Text('${l10n.get('annual_short')} (\$198/año)')),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  readOnly: true,
                                  initialValue: context.watch<CompanyProvider>().currentCompany.subscriptionStatus == 'trial'
                                      ? (context.watch<CompanyProvider>().currentCompany.trialEndsAt != null 
                                          ? DateFormat('yyyy-MM-dd').format(context.watch<CompanyProvider>().currentCompany.trialEndsAt!.subtract(const Duration(days: 7)))
                                          : 'N/A')
                                      : (context.watch<CompanyProvider>().currentCompany.subscriptionStartsAt != null 
                                          ? DateFormat('yyyy-MM-dd').format(context.watch<CompanyProvider>().currentCompany.subscriptionStartsAt!) 
                                          : 'N/A'),
                                  decoration: InputDecoration(
                                    labelText: l10n.get('start_date_label'),
                                    filled: true,
                                    fillColor: Theme.of(context).cardColor.withValues(alpha: 0.5),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                                    prefixIcon: const Icon(Icons.calendar_today, size: 16),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  readOnly: true,
                                  initialValue: context.watch<CompanyProvider>().currentCompany.subscriptionStatus == 'trial'
                                      ? (context.watch<CompanyProvider>().currentCompany.trialEndsAt != null 
                                          ? DateFormat('yyyy-MM-dd').format(context.watch<CompanyProvider>().currentCompany.trialEndsAt!) 
                                          : 'N/A')
                                      : (context.watch<CompanyProvider>().currentCompany.subscriptionEndsAt != null 
                                          ? DateFormat('yyyy-MM-dd').format(context.watch<CompanyProvider>().currentCompany.subscriptionEndsAt!) 
                                          : 'N/A'),
                                  decoration: InputDecoration(
                                    labelText: l10n.get('expiration_date_label'),
                                    filled: true,
                                    fillColor: Theme.of(context).cardColor.withValues(alpha: 0.5),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                                    prefixIcon: const Icon(Icons.event_busy, size: 16),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: TextButton.icon(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (context) => const AdminBillingHistoryScreen()),
                                );
                              },
                              icon: const Icon(Icons.history, size: 18),
                              label: Text(l10n.get('view_billing_history')),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.blue.shade700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // BOTÓN REPORTAR PAGO
                          if (context.watch<CompanyProvider>().currentCompany.subscriptionStatus != 'active' || 
                              _calculateRemainingDays(context.watch<CompanyProvider>().currentCompany) < 7)
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                icon: const Icon(Icons.send_to_mobile),
                                label: Text(l10n.get('register_payment')),
                                onPressed: () => PaymentDialogUtils.showPaymentReportDialog(context, context.read<CompanyProvider>().currentCompany),
                              ),
                            ),
                        ],
                      ),
                    ),

                    const Divider(height: 48),
                    _buildSectionHeader(l10n.get('register_branding'), Icons.palette_outlined),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            _primaryColorController, 
                            l10n.get('primary_color'), 
                            required: true,
                            hint: '#006837',
                            suffix: ValueListenableBuilder<TextEditingValue>(
                              valueListenable: _primaryColorController,
                              builder: (context, value, _) {
                                final color = _parseColor(value.text);
                                return Icon(Icons.circle, color: color);
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField(
                            _secondaryColorController, 
                            l10n.get('secondary_color'), 
                            required: true,
                            hint: '#A64F35',
                            suffix: ValueListenableBuilder<TextEditingValue>(
                              valueListenable: _secondaryColorController,
                              builder: (context, value, _) {
                                final color = _parseColor(value.text);
                                return Icon(Icons.circle, color: color);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    TextButton.icon(
                      onPressed: () => launchUrl(Uri.parse('https://htmlcolorcodes.com')),
                      icon: Icon(Icons.link, size: 16, color: Theme.of(context).brightness == Brightness.dark ? Colors.lightBlueAccent : Colors.blue),
                      label: Text(
                        l10n.get('register_hex_link'),
                        style: TextStyle(
                          fontSize: 12, 
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.lightBlueAccent : Colors.blue,
                          decoration: TextDecoration.underline,
                        )
                      ),
                    ),
                    const Divider(height: 48),
                    _buildSectionHeader(l10n.get('carousel_manager'), Icons.view_carousel_outlined),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: Text(l10n.get('carousel_title')),
                      subtitle: Text(isSpanish ? 'Mostrar carrusel en la página de inicio' : 'Show carousel on the home page'),
                      value: _showCarousel,
                      onChanged: (v) => setState(() => _showCarousel = v),
                      activeColor: AppThemes.primaryGreen,
                    ),
                    if (_showCarousel) ...[
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: DropdownButtonFormField<String>(
                          value: _carouselStrategy,
                          decoration: InputDecoration(
                            labelText: l10n.get('carousel_strategy'),
                            filled: true,
                            fillColor: Theme.of(context).cardColor,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                          items: [
                            DropdownMenuItem(value: 'manual', child: Text(l10n.get('carousel_strategy_manual'))),
                            DropdownMenuItem(value: 'popular', child: Text(l10n.get('carousel_strategy_popular'))),
                          ],
                          onChanged: (v) => setState(() => _carouselStrategy = v!),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: DropdownButtonFormField<String>(
                          value: _carouselAnimation,
                          decoration: InputDecoration(
                            labelText: isSpanish ? 'Transición de Carrusel' : 'Carousel Transition',
                            filled: true,
                            fillColor: Theme.of(context).cardColor,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                          items: [
                            DropdownMenuItem(value: 'slide', child: Text(isSpanish ? 'Deslizar (Slide)' : 'Slide')),
                            DropdownMenuItem(value: 'fade', child: Text(isSpanish ? 'Desvanecer (Fade)' : 'Fade')),
                          ],
                          onChanged: (v) => setState(() => _carouselAnimation = v!),
                        ),
                      ),
                    ],
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppThemes.primaryGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _save,
                        child: Text(l10n.get('save_changes').toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon, 
          color: Theme.of(context).brightness == Brightness.dark 
              ? Colors.greenAccent 
              : AppThemes.primaryGreen, 
          size: 20
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title.toUpperCase(), 
            style: TextStyle(
              fontWeight: FontWeight.w900, 
              letterSpacing: 1.1, 
              fontSize: 13, 
              color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade400 : Colors.grey.shade600
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildLogoPicker(String label, String? url, bool isAbbr) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _pickImage(isAbbr),
          child: Container(
            width: 120,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: url != null
                ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(url, fit: BoxFit.contain))
                : const Icon(Icons.add_a_photo, color: Colors.grey, size: 30),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {bool required = false, bool isEmail = false, bool isNumber = false, bool enabled = true, String? hint, Widget? suffix}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : (isEmail ? TextInputType.emailAddress : TextInputType.text),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          suffixIcon: suffix,
          filled: true,
          fillColor: enabled ? Theme.of(context).cardColor : Theme.of(context).cardColor.withValues(alpha: 0.5),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
        validator: (v) {
          if (required && (v == null || v.isEmpty)) return 'Requerido';
          if (isEmail && v != null && v.isNotEmpty && !v.contains('@')) return 'Email inválido';
          return null;
        },
      ),
    );
  }

  Color _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return Colors.transparent;
    try {
      final cleanHex = hex.replaceAll('#', '');
      if (cleanHex.length != 6) return Colors.transparent;
      return Color(int.parse('FF$cleanHex', radix: 16));
    } catch (_) {
      return Colors.transparent;
    }
  }

  int _calculateRemainingDays(Company company) {
    final now = DateTime.now();
    DateTime? target;
    if (company.subscriptionStatus == 'trial') {
      target = company.trialEndsAt;
    } else {
      target = company.subscriptionEndsAt;
    }
    
    if (target == null) return 0;
    final diff = target.difference(now).inDays;
    return diff < 0 ? 0 : diff;
  }

}
