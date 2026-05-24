import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../../utils/image_utils.dart';
import '../../services/supabase_service.dart';
import '../../services/app_localizations.dart';
import 'package:provider/provider.dart';
import '../services/app_provider.dart';
import '../data/location_data.dart';
import '../widgets/referral_dialog.dart';
import '../services/company_service.dart';
import '../services/subscription_service.dart';
import '../services/app_themes.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _client = Supabase.instance.client;

  final _companyCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _domainCtrl = TextEditingController();
  final _aliasCtrl = TextEditingController();
  
  final _instaCtrl = TextEditingController();
  final _fbCtrl = TextEditingController();
  final _tgCtrl = TextEditingController();
  final _wsCtrl = TextEditingController();
  
  final _primaryColorCtrl = TextEditingController(text: '#006837');
  final _secondaryColorCtrl = TextEditingController(text: '#A64F35');

  bool _isPassVisible = false;
  bool _termsAccepted = false;
  final _contractScrollCtrl = ScrollController();
  
  String _billingCycle = 'monthly';
  String? _referralEmail;
  String _acquisitionChannel = 'organic';
  String _activeStrategy = 'strategy_1';
  final _service = SupabaseService();
  final _subService = SubscriptionService();
  bool _isLoading = false;
  bool _isSavingLogo = false;
  bool _submitted = false;
  
  String? _logoUrl;
  String? _logoAbbrUrl;
  bool _isCheckingDomain = false;
  bool? _isDomainAvailable;
  bool _isOrganicForce = false;
  bool _isReferralLocked = false;
  bool _didInitArgs = false; // guard: run didChangeDependencies init only once
  Map<String, int> _globalLimits = {'max_properties': 30, 'max_photos_per_property': 10};

  // Salespersons list for Strategy 2 dropdown
  List<Map<String, dynamic>> _salespersons = [];
  String? _selectedSalespersonAlias; // selected value in the dropdown

  // Regional settings
  String? _country;
  String? _state;
  String? _city;
  String _currencyCode = 'USD';
  String _areaUnit = 'm²';

  // Country pricing
  double _priceMonthly = 18.0;
  double _priceAnnual  = 198.0;
  bool _isCustomPrice  = false;
  bool _isPriceFetching = false;

  // IP Geolocation
  bool _isDetectingCountry = true; // starts true while detecting
  bool _isCountryLocked    = false; // true if IP detection succeeded
  String? _geoWarning;             // shown if detection fails

  static List<Map<String, String>> _getCurrencies(AppLocalizations l10n) => [
    {'code': 'USD', 'symbol': '\$', 'name': 'USA / Dólar'},
    {'code': 'EUR', 'symbol': '€', 'name': 'Euro'},
    {'code': 'VES', 'symbol': 'Bs', 'name': 'Venezuela'},
    {'code': 'COP', 'symbol': '\$', 'name': 'Colombia'},
    {'code': 'MXN', 'symbol': '\$', 'name': 'México'},
    {'code': 'PEN', 'symbol': 'S/', 'name': 'Perú'},
    {'code': 'CLP', 'symbol': '\$', 'name': 'Chile'},
    {'code': 'ARS', 'symbol': '\$', 'name': 'Argentina'},
    {'code': 'USD_EC', 'symbol': '\$', 'name': 'Ecuador (USD)'},
    {'code': 'BOB', 'symbol': 'Bs.', 'name': 'Bolivia'},
    {'code': 'HNL', 'symbol': 'L', 'name': 'Honduras'},
    {'code': 'CRC', 'symbol': '₡', 'name': 'Costa Rica'},
    {'code': 'GTQ', 'symbol': 'Q', 'name': 'Guatemala'},
    {'code': 'PYG', 'symbol': '₲', 'name': 'Paraguay'},
    {'code': 'DOP', 'symbol': 'RD\$', 'name': 'R. Dominicana'},
    {'code': 'USD_PR', 'symbol': '\$', 'name': 'Puerto Rico (USD)'},
  ];

  @override
  void initState() {
    super.initState();
    _checkUrlParameters();
    _loadStrategy();
    _loadSalespersons();
    _detectCountryFromIp();
    _loadGlobalLimits();
  }

  Future<void> _loadGlobalLimits() async {
    try {
      final limits = await CompanyService.getGlobalLimits();
      if (mounted) setState(() => _globalLimits = limits);
    } catch (e) {
      debugPrint('[RegisterScreen] Error loading global limits: $e');
    }
  }

  @override
  void dispose() {
    _contractScrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSalespersons() async {
    try {
      final list = await CompanyService.getSalespersons();
      if (mounted) {
        setState(() {
          _salespersons = list;
          
          // Si se pasó un alias por URL/args pero no existe en la DB, lo liberamos
          if (_selectedSalespersonAlias != null) {
            final exists = list.any((s) => s['alias'] == _selectedSalespersonAlias);
            if (!exists) {
              _selectedSalespersonAlias = null;
              _aliasCtrl.clear();
              _isReferralLocked = false;
            }
          }
        });
      }
    } catch (e) {
      debugPrint('[RegisterScreen] Error loading salespersons: $e');
      if (mounted) {
        setState(() {
          _salespersons = [];
          if (_selectedSalespersonAlias != null) {
            _selectedSalespersonAlias = null;
            _aliasCtrl.clear();
            _isReferralLocked = false;
          }
        });
      }
    }
  }

  void _checkUrlParameters() {
    try {
      final uri = Uri.base;
      debugPrint('[DEBUG] uri: $uri');
      debugPrint('[DEBUG] uri.fragment: ${uri.fragment}');
      debugPrint('[DEBUG] uri.query: ${uri.query}');

      // Build query map from all possible sources (most reliable first):
      // 1. Direct query params — works in production (path URL strategy)
      // 2. Fragment parsing — fallback for #/register?ref=x
      // 3. Fragment parsing — fallback for #/register?ref=x
      Map<String, String> q = uri.queryParameters;

      if (q.isEmpty && uri.fragment.contains('?')) {
        final queryPart = uri.fragment.substring(uri.fragment.indexOf('?'));
        q = Uri.parse('x://x$queryPart').queryParameters;
        debugPrint('[DEBUG] parsed from fragment: $q');
      }

      debugPrint('[DEBUG] Final q: $q');

      // Strategy 1: Referral agency email
      final refEmail = q['ref_email'];
      if (refEmail != null && refEmail.isNotEmpty) {
        _validateUrlReferralEmail(refEmail);
      }

      // Strategy 2: Salesperson alias
      final refAlias = q['ref'] ?? q['alias'] ?? q['vendedor'];
      if (refAlias != null && refAlias.isNotEmpty) {
        _validateUrlReferralAlias(refAlias);
      }
    } catch (e) {
      debugPrint('[REGISTER] _checkUrlParameters ERROR: $e');
    }

    // Fallback: AppProvider context (set when user navigated via /<alias> route or banner)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      final providerAlias = appProvider.referredBySalesperson;
      if (providerAlias != null && providerAlias.isNotEmpty && !_isReferralLocked) {
        setState(() {
          _aliasCtrl.text = providerAlias;
          _selectedSalespersonAlias = providerAlias;
          _acquisitionChannel = 'salesperson';
          _activeStrategy = 'strategy_2';
          _isReferralLocked = true;
        });
      }
    });
  }

  Future<void> _validateUrlReferralEmail(String email) async {
    try {
      final String? referredCompanyId = await _subService.resolveReferralByEmail(email);
      if (!mounted) return;
      
      if (referredCompanyId != null) {
        setState(() {
          _referralEmail = email;
          _acquisitionChannel = 'broker';
          _activeStrategy = 'strategy_1';
          _isReferralLocked = true;
        });
      } else {
        debugPrint('[REGISTER] Invalid referral email from URL: $email');
        setState(() {
          _referralEmail = null;
          _acquisitionChannel = 'organic'; 
        });
      }
    } catch (e) {
      debugPrint('[REGISTER] Error validating referral email: $e');
    }
  }

  Future<void> _validateUrlReferralAlias(String alias) async {
    int attempts = 0;
    while (_salespersons.isEmpty && attempts < 10) {
      await Future.delayed(const Duration(milliseconds: 300));
      attempts++;
    }

    if (!mounted) return;

    final String target = alias.toLowerCase();
    Map<String, dynamic>? found;
    
    for (final s in _salespersons) {
      final String sAlias = (s['alias'] ?? '').toString().toLowerCase();
      if (sAlias == target) {
        found = s;
        break;
      }
    }

    if (found != null) {
      final String realAlias = (found['alias'] ?? '').toString();
      setState(() {
        _aliasCtrl.text = realAlias;
        _selectedSalespersonAlias = realAlias;
        _acquisitionChannel = 'salesperson';
        _activeStrategy = 'strategy_2';
        _isReferralLocked = true;
      });
    } else {
      debugPrint('[REGISTER] Invalid salesperson alias from URL: $alias');
      setState(() {
        _selectedSalespersonAlias = null;
        _acquisitionChannel = 'organic';
      });
    }
  }


  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitArgs) return; // only run once
    _didInitArgs = true;
    
    final Object? rawArgs = ModalRoute.of(context)?.settings.arguments;
    final Map<String, dynamic>? args = rawArgs is Map<String, dynamic> 
        ? rawArgs 
        : (rawArgs is Map ? Map<String, dynamic>.from(rawArgs) : null);

    // Strategy 2: salesperson alias passed from banner (Navigator args)
    final salespersonAlias = args?['salespersonAlias']?.toString();
    if (salespersonAlias != null && salespersonAlias.isNotEmpty) {
      setState(() {
        _aliasCtrl.text = salespersonAlias;
        _selectedSalespersonAlias = salespersonAlias;
        _acquisitionChannel = 'salesperson';
        _activeStrategy = 'strategy_2';
        _isReferralLocked = true;
      });
      return;
    }

    // Strategy 1: referral email passed from banner (Navigator args)
    final refEmail = args?['ref_email']?.toString();
    if (refEmail != null && refEmail.isNotEmpty) {
      setState(() {
        _referralEmail = refEmail;
        _acquisitionChannel = 'broker';
        _activeStrategy = 'strategy_1';
        _isReferralLocked = true;
      });
      return;
    }

    // Organic flag from banner
    if (args?['isOrganic'] == true) {
      _isOrganicForce = true;
      _acquisitionChannel = 'organic';
      return;
    }

    // Fallback: parse query params from the route name itself
    // Works when Flutter preserves the full route: /register?ref=login123
    final routeName = ModalRoute.of(context)?.settings.name ?? '';
    if (routeName.contains('?')) {
      try {
        final routeUri = Uri.parse('x://x$routeName');
        final q = routeUri.queryParameters;

        final rAlias = q['ref'] ?? q['alias'] ?? q['vendedor'];
        if (rAlias != null && rAlias.isNotEmpty && !_isReferralLocked) {
          setState(() {
            _aliasCtrl.text = rAlias;
            _selectedSalespersonAlias = rAlias;
            _acquisitionChannel = 'salesperson';
            _activeStrategy = 'strategy_2';
            _isReferralLocked = true;
          });
          return;
        }

        final rEmail = q['ref_email'];
        if (rEmail != null && rEmail.isNotEmpty && !_isReferralLocked) {
          setState(() {
            _referralEmail = rEmail;
            _acquisitionChannel = 'broker';
            _activeStrategy = 'strategy_1';
            _isReferralLocked = true;
          });
        }
      } catch (e) {
        debugPrint('[REGISTER] routeName parse error: $e');
      }
    }
  }


  Future<void> _loadStrategy() async {
    final strategy = await CompanyService.getActiveStrategy();
    if (mounted) setState(() => _activeStrategy = strategy);
  }

  Future<void> _detectCountryFromIp() async {
    try {
      final response = await http.get(
        Uri.parse('https://ipapi.co/json/'),
      ).timeout(const Duration(seconds: 6));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final detectedName = data['country_name'] as String?;
        if (detectedName != null && detectedName.isNotEmpty) {
          // Normalize names for common mismatches
          String searchName = detectedName.toLowerCase();
          if (searchName == 'united states' || searchName == 'us' || searchName == 'united states of america') {
            searchName = 'usa';
          }
          
          // Check if detected country exists in our LocationData
          final match = LocationData.countries.where(
            (c) => c.toLowerCase() == searchName
          ).firstOrNull;
          
          if (match != null && mounted) {
            setState(() {
              _country           = match;
              _isCountryLocked   = true;
              _isDetectingCountry = false;
            });
            await _fetchPriceForCountry(match);
            return;
          }
        }
      }
    } catch (_) {}
    // Fallback: detection failed or country not in list
    if (mounted) {
      setState(() {
        _isDetectingCountry = false;
        _isCountryLocked    = false;
        _geoWarning         = 'No fue posible detectar tu país automáticamente. Selecciónalo manualmente.';
      });
    }
  }

  Future<void> _pickImage(bool isAbbreviated) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image == null) return;

    setState(() => _isSavingLogo = true);
    try {
      final bytes = await image.readAsBytes();
      final compressed = await ImageUtils.compressImage(bytes);
      final extension = image.path.split('.').last;
      
      // Since company doesn't exist yet, we use a temp prefix and random string
      final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}_${(100 + (900 * (DateTime.now().millisecond / 1000)).toInt())}';
      final fileName = '${tempId}_${isAbbreviated ? "abbr" : "full"}.$extension';
      
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
      if (mounted) setState(() => _isSavingLogo = false);
    }
  }

  Future<void> _checkDomainAvailability() async {
    final domain = _domainCtrl.text.trim().toLowerCase();
    if (domain.isEmpty) return;
    
    setState(() {
      _isCheckingDomain = true;
      _isDomainAvailable = null;
    });

    try {
      // We check if any company has this subdomain (abbr or full domain match)
      final fullDomain = '$domain.alveo.fyi';
      final res = await _client.from('companies')
          .select('id')
          .or('domain.eq.$fullDomain,abbr.eq.$domain')
          .maybeSingle();
      
      setState(() {
        _isDomainAvailable = res == null;
      });
    } catch (e) {
      debugPrint('Error checking domain: $e');
    } finally {
      setState(() => _isCheckingDomain = false);
    }
  }

  Future<void> _fetchPriceForCountry(String? country) async {
    if (!mounted) return;
    setState(() => _isPriceFetching = true);
    final pricing = await CompanyService.getPriceForCountry(country);
    if (!mounted) return;
    setState(() {
      _priceMonthly   = pricing['monthly']!;
      _priceAnnual    = pricing['annual']!;
      _isCustomPrice  = _priceMonthly != 18.0;
      _isPriceFetching = false;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context);

    // Validate domain availability
    if (_isDomainAvailable != true) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l10n.get('register_domain_check_first')),
        backgroundColor: Colors.orange,
      ));
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Read language from AppProvider (app-wide locale)
      final lang = Provider.of<AppProvider>(context, listen: false).locale.languageCode;

      final currencies = _getCurrencies(l10n);
      final currencyEntry = currencies.firstWhere(
        (c) => c['code'] == _currencyCode,
        orElse: () => {'code': 'USD', 'symbol': '\$', 'name': 'USD'},
      );
      final realCurrencyCode = _currencyCode.startsWith('USD') ? 'USD' : _currencyCode;
      final currencySymbol = currencyEntry['symbol']!;

      final String acqChannel;
      if (_activeStrategy == 'strategy_2') {
        acqChannel = _acquisitionChannel;
      } else if (_isOrganicForce) {
        acqChannel = 'organic';
      } else {
        acqChannel = _acquisitionChannel;
      }

      final response = await _client.functions.invoke('handle-auto-registration', body: {
        'company_name': _companyCtrl.text.trim(),
        'contact_name': _nameCtrl.text.trim(),
        'contact_email': _emailCtrl.text.trim(),
        'contact_phone': _phoneCtrl.text.trim(),
        'contact_whatsapp': _wsCtrl.text.trim(),
        'password': _passCtrl.text.trim(),
        'desired_domain': _domainCtrl.text.trim().toLowerCase(),
        'language': lang,
        'billing_cycle': _billingCycle,
        'referral_email': acqChannel == 'broker' ? _referralEmail : null,
        'acquisition_channel': acqChannel,
        'referred_alias': acqChannel == 'salesperson' ? _aliasCtrl.text.trim().toLowerCase() : null,
        'currency_symbol': currencySymbol,
        'currency_code': realCurrencyCode,
        'area_unit': _areaUnit,
        'country': _country,
        'state': _state,
        'city': _city,
        'base_price': _billingCycle == 'monthly' ? _priceMonthly : _priceMonthly * 11,
        'terms_accepted_at': _termsAccepted ? DateTime.now().toIso8601String() : null,
        'logo_url': _logoUrl,
        'logo_abbr_url': _logoAbbrUrl,
        'instagram_url': _instaCtrl.text.trim(),
        'facebook_url': _fbCtrl.text.trim(),
        'telegram_url': _tgCtrl.text.trim(),
        'primary_color': _primaryColorCtrl.text.trim(),
        'secondary_color': _secondaryColorCtrl.text.trim(),
      });

      if (response.status != 200) {
        throw response.data['error'] ?? l10n.get('error_generic');
      }

      setState(() => _submitted = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${l10n.get("error_generic")} $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _askReferral() async {
    final l10n = AppLocalizations.of(context);
    final result = await ReferralDialog.show(context, l10n.locale.languageCode == 'es', _activeStrategy);
    if (result != null) {
      setState(() => _referralEmail = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bool isMobile = MediaQuery.of(context).size.width < 600;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    if (_submitted) {
      final domain = '${_domainCtrl.text.trim().toLowerCase()}.alveo.fyi';
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.rocket_launch, size: 80, color: Colors.green),
                const SizedBox(height: 24),
                Text(
                  l10n.get('register_success_title'),
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      Text(l10n.get('register_success_access')),
                      const SizedBox(height: 8),
                      SelectableText(
                        'https://' + domain + '/?clear_cache=1',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.get('register_success_email'),
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => launchUrl(
                    Uri.parse('https://$domain/?clear_cache=1'),
                    mode: LaunchMode.externalApplication,
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(l10n.get('register_go_portal')),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.get('register_welcome_email_sent', [_emailCtrl.text]),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Build: 2026-05-02-15:25',
                  style: TextStyle(color: Colors.grey, fontSize: 10),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.get('register_title')),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l10n.get('register_hero'), 
                     style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    _country != null
                        ? l10n.get('register_trial_info', [NumberFormat('#,###.##').format(_priceMonthly)])
                        : l10n.get('register_trial_info_unknown'),
                  ),
                  const SizedBox(height: 24),
                  
                  // Logo Pickers
                  Wrap(
                    spacing: 24,
                    runSpacing: 16,
                    children: [
                      _buildLogoPicker(l10n.get('register_logo_pc'), _logoUrl, false),
                      _buildLogoPicker(l10n.get('register_logo_mobile'), _logoAbbrUrl, true),
                    ],
                  ),
                  const SizedBox(height: 32),

                  TextFormField(
                    controller: _companyCtrl,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: l10n.get('register_company_name'), 
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.business),
                    ),
                    validator: (v) => v!.isEmpty ? l10n.get('required') : null,
                  ),
                  const SizedBox(height: 16),
                  
                  // SUBDOMAIN FIELD
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _domainCtrl,
                              maxLength: 10,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'[a-z0-9\-]')),
                              ],
                              onChanged: (v) {
                                setState(() => _isDomainAvailable = null);
                              },
                              decoration: InputDecoration(
                                labelText: l10n.get('register_domain_label'),
                                hintText: l10n.get('register_subdomain_hint'),
                                helperText: l10n.get('register_domain_helper'),
                                helperMaxLines: 2,
                                border: const OutlineInputBorder(),
                                prefixText: 'https://',
                                suffixText: '.alveo.fyi',
                                counterText: '',
                                errorText: _isDomainAvailable == false 
                                    ? l10n.get('register_domain_unavailable')
                                    : null,
                                prefixIcon: const Icon(Icons.language_outlined),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) return l10n.get('required');
                                if (v.length > 10) return 'Máx 10 car.';
                                if (!RegExp(r'^[a-z0-9-]+$').hasMatch(v.toLowerCase())) return l10n.get('required');
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isCheckingDomain ? null : _checkDomainAvailability,
                              style: ElevatedButton.styleFrom(
                                shape: const CircleBorder(),
                                padding: const EdgeInsets.all(16),
                              ),
                              child: _isCheckingDomain 
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.search),
                            ),
                          ),
                        ],
                      ),
                      if (_isDomainAvailable == true)
                        Padding(
                          padding: const EdgeInsets.only(top: 8, left: 4),
                          child: Text(
                            l10n.get('register_domain_available'),
                            style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.only(top: 8, left: 4),
                        child: Text(
                          '${l10n.get('register_url_preview')}: https://${_domainCtrl.text.isEmpty ? "..." : _domainCtrl.text.toLowerCase()}.alveo.fyi',
                          style: TextStyle(
                            color: _isDomainAvailable == true ? Colors.green : (Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : Colors.grey[600]), 
                            fontSize: 12, 
                            fontWeight: _isDomainAvailable == true ? FontWeight.bold : FontWeight.normal,
                            fontStyle: FontStyle.italic
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _nameCtrl,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(labelText: l10n.get('register_your_name'), border: const OutlineInputBorder()),
                    validator: (v) => v!.isEmpty ? l10n.get('required') : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailCtrl,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: l10n.get('register_email'),
                      hintText: l10n.get('register_email_hint'),
                      border: const OutlineInputBorder()
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => v!.contains('@') ? null : l10n.get('register_email_invalid'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passCtrl,
                    obscureText: !_isPassVisible,
                    decoration: InputDecoration(
                      labelText: l10n.get('register_password'),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(_isPassVisible ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() => _isPassVisible = !_isPassVisible),
                      ),
                    ),
                    validator: (v) => (v == null || v.length < 6) ? l10n.get('register_password_min') : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneCtrl,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: l10n.get('register_phone'), 
                      border: const OutlineInputBorder()
                    ),
                  ),
                  const SizedBox(height: 24),

                  // SOCIAL NETWORKS
                  Text(
                    l10n.get('register_social_networks'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  if (isMobile) ...[
                    TextFormField(
                      controller: _wsCtrl,
                      decoration: InputDecoration(
                        labelText: l10n.get('whatsapp_label'),
                        hintText: '+58 412 0000000',
                        prefixIcon: const Icon(Icons.chat_outlined, color: Colors.green),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? l10n.get('register_whatsapp_required')
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _instaCtrl,
                      decoration: InputDecoration(
                        labelText: l10n.get('instagram_label'),
                        prefixIcon: const Icon(Icons.camera_alt_outlined, color: Colors.purple),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ] else ...[
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _wsCtrl,
                            decoration: InputDecoration(
                              labelText: l10n.get('whatsapp_label'),
                              hintText: '+58 412 0000000',
                              prefixIcon: const Icon(Icons.chat_outlined, color: Colors.green),
                              border: const OutlineInputBorder(),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? l10n.get('register_whatsapp_required')
                                : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _instaCtrl,
                            decoration: InputDecoration(
                              labelText: l10n.get('instagram_label'),
                              prefixIcon: const Icon(Icons.camera_alt_outlined, color: Colors.purple),
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  if (isMobile) ...[
                    TextFormField(
                      controller: _fbCtrl,
                      decoration: InputDecoration(
                        labelText: l10n.get('facebook_label'),
                        prefixIcon: const Icon(Icons.facebook_outlined, color: Colors.blue),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _tgCtrl,
                      decoration: InputDecoration(
                        labelText: l10n.get('telegram_label'),
                        prefixIcon: const Icon(Icons.telegram_outlined, color: Colors.lightBlue),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ] else ...[
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _fbCtrl,
                            decoration: InputDecoration(
                              labelText: l10n.get('facebook_label'),
                              prefixIcon: const Icon(Icons.facebook_outlined, color: Colors.blue),
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _tgCtrl,
                            decoration: InputDecoration(
                              labelText: l10n.get('telegram_label'),
                              prefixIcon: const Icon(Icons.telegram_outlined, color: Colors.lightBlue),
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 24),
                    // Language + Plan toggles
                  if (isMobile) ...[
                    DropdownButtonFormField<String>(
                      value: Provider.of<AppProvider>(context).locale.languageCode,
                      decoration: InputDecoration(
                        labelText: l10n.get('register_language'), 
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'es', child: Text('Español')),
                        DropdownMenuItem(value: 'en', child: Text('English')),
                      ],
                      onChanged: (v) {
                        if (v != null) {
                          Provider.of<AppProvider>(context, listen: false).setLocale(Locale(v));
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _billingCycle,
                      decoration: InputDecoration(
                        labelText: l10n.get('register_plan'), 
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'monthly', 
                          child: Text(
                            l10n.get('register_plan_monthly', [NumberFormat('#,###.##').format(_priceMonthly)]),
                            style: const TextStyle(fontSize: 13),
                          )
                        ),
                        DropdownMenuItem(
                          value: 'annual', 
                          child: Text(
                            l10n.get('register_plan_annual', [NumberFormat('#,###.##').format(_priceMonthly * 11)]),
                            style: const TextStyle(fontSize: 13),
                          )
                        ),
                      ],
                      onChanged: (v) => setState(() => _billingCycle = v!),
                    ),
                  ] else ...[
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: Provider.of<AppProvider>(context).locale.languageCode,
                            decoration: InputDecoration(
                              labelText: l10n.get('register_language'), 
                              border: const OutlineInputBorder(),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'es', child: Text('Español')),
                              DropdownMenuItem(value: 'en', child: Text('English')),
                            ],
                            onChanged: (v) {
                              if (v != null) {
                                Provider.of<AppProvider>(context, listen: false).setLocale(Locale(v));
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _billingCycle,
                            decoration: InputDecoration(
                              labelText: l10n.get('register_plan'), 
                              border: const OutlineInputBorder(),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            items: [
                              DropdownMenuItem(
                                value: 'monthly', 
                                child: Text(
                                  l10n.get('register_plan_monthly', [NumberFormat('#,###.##').format(_priceMonthly)]),
                                  style: const TextStyle(fontSize: 13),
                                )
                              ),
                              DropdownMenuItem(
                                value: 'annual', 
                                child: Text(
                                  l10n.get('register_plan_annual', [NumberFormat('#,###.##').format(_priceMonthly * 11)]),
                                  style: const TextStyle(fontSize: 13),
                                )
                              ),
                            ],
                            onChanged: (v) => setState(() => _billingCycle = v!),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),

                                 if (MediaQuery.of(context).size.width < 600) ...[
                    // Mobile: Column layout
                    TextFormField(
                      initialValue: "${DateTime.now().day.toString().padLeft(2, '0')}/${DateTime.now().month.toString().padLeft(2, '0')}/${DateTime.now().year}",
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: l10n.get('register_trial_start'), 
                        prefixIcon: const Icon(Icons.calendar_today, size: 18, color: Colors.green),
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : Colors.grey.shade50,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: "${DateTime.now().add(const Duration(days: 7)).day.toString().padLeft(2, '0')}/${DateTime.now().add(const Duration(days: 7)).month.toString().padLeft(2, '0')}/${DateTime.now().add(const Duration(days: 7)).year}",
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: l10n.get('register_trial_end'), 
                        prefixIcon: const Icon(Icons.event_busy, size: 18, color: Colors.orange),
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : Colors.grey.shade50,
                      ),
                    ),
                  ] else ...[
                    // Desktop: Row layout
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: "${DateTime.now().day.toString().padLeft(2, '0')}/${DateTime.now().month.toString().padLeft(2, '0')}/${DateTime.now().year}",
                            readOnly: true,
                            decoration: InputDecoration(
                              labelText: l10n.get('register_trial_start'), 
                              prefixIcon: const Icon(Icons.calendar_today, size: 18, color: Colors.green),
                              border: const OutlineInputBorder(),
                              filled: true,
                              fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : Colors.grey.shade50,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            initialValue: "${DateTime.now().add(const Duration(days: 7)).day.toString().padLeft(2, '0')}/${DateTime.now().add(const Duration(days: 7)).month.toString().padLeft(2, '0')}/${DateTime.now().add(const Duration(days: 7)).year}",
                            readOnly: true,
                            decoration: InputDecoration(
                              labelText: l10n.get('register_trial_end'), 
                              prefixIcon: const Icon(Icons.event_busy, size: 18, color: Colors.orange),
                              border: const OutlineInputBorder(),
                              filled: true,
                              fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : Colors.grey.shade50,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 32),

                  // REGIONAL SETTINGS HEADER
                  Text(
                    l10n.get('register_regional'), 
                    style: TextStyle(
                      fontSize: 16, 
                      fontWeight: FontWeight.bold, 
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.blueGrey[200] : Colors.blueGrey
                    )
                  ),
                  const SizedBox(height: 16),

                  // Country detection indicator
                  if (_isDetectingCountry)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                          const SizedBox(width: 10),
                          Text(l10n.get('register_detecting'), style: const TextStyle(color: Colors.blueGrey, fontSize: 13)),
                        ],
                      ),
                    )
                  else if (_geoWarning != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber, color: Colors.orange, size: 18),
                          const SizedBox(width: 8),
                          Expanded(child: Text(_geoWarning!, style: const TextStyle(color: Colors.orange, fontSize: 12))),
                        ],
                      ),
                    )
                  else if (_isCountryLocked)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on, color: Colors.green, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l10n.get('register_detected', [_country ?? '']),
                              style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                          ),
                          Tooltip(
                            message: l10n.get('register_ip_locked'),
                            child: const Icon(Icons.info_outline, color: Colors.blueGrey, size: 16),
                          ),
                        ],
                      ),
                    ),
                  if (MediaQuery.of(context).size.width < 600) ...[
                    // Mobile: Column layout
                    Tooltip(
                      message: _isCountryLocked ? l10n.get('register_ip_locked') : '',
                      child: DropdownButtonFormField<String>(
                        value: _country,
                        decoration: InputDecoration(
                          labelText: l10n.get('country_field'),
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          suffixIcon: _isCountryLocked
                            ? Tooltip(
                                message: l10n.get('register_ip_lock_icon'),
                                child: const Icon(Icons.lock, size: 18, color: Colors.blueGrey),
                              )
                            : null,
                        ),
                        items: LocationData.countries.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13)))).toList(),
                        onChanged: _isCountryLocked || _isDetectingCountry ? null : (v) {
                          setState(() { _country = v; _state = null; _city = null; });
                          _fetchPriceForCountry(v);
                        },
                        validator: (v) => v == null ? l10n.get('required') : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _state,
                      decoration: InputDecoration(
                        labelText: l10n.get('state_label'), 
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: _country != null
                          ? LocationData.statesFor(_country!).map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis))).toList()
                          : [],
                      onChanged: (v) => setState(() { _state = v; _city = null; }),
                      validator: (v) => v == null ? l10n.get('required') : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _city,
                      decoration: InputDecoration(
                        labelText: l10n.get('city_field'), 
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: (_country != null && _state != null)
                          ? LocationData.citiesFor(_country!, _state!).map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis))).toList()
                          : [],
                      onChanged: (v) => setState(() => _city = v),
                      validator: (v) => v == null ? l10n.get('required') : null,
                    ),
                  ] else ...[
                    // Desktop/Tablet: Row layout
                    Row(
                      children: [
                        Expanded(
                          child: Tooltip(
                            message: _isCountryLocked ? l10n.get('register_ip_locked') : '',
                            child: DropdownButtonFormField<String>(
                              value: _country,
                              decoration: InputDecoration(
                                labelText: l10n.get('country_field'),
                                border: const OutlineInputBorder(),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                suffixIcon: _isCountryLocked
                                  ? Tooltip(
                                      message: l10n.get('register_ip_lock_icon'),
                                      child: const Icon(Icons.lock, size: 18, color: Colors.blueGrey),
                                    )
                                  : null,
                              ),
                              items: LocationData.countries.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13)))).toList(),
                              onChanged: _isCountryLocked || _isDetectingCountry ? null : (v) {
                                setState(() { _country = v; _state = null; _city = null; });
                                _fetchPriceForCountry(v);
                              },
                              validator: (v) => v == null ? l10n.get('required') : null,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _state,
                            decoration: InputDecoration(
                              labelText: l10n.get('state_label'), 
                              border: const OutlineInputBorder(),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            items: _country != null
                                ? LocationData.statesFor(_country!).map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis))).toList()
                                : [],
                            onChanged: (v) => setState(() { _state = v; _city = null; }),
                            validator: (v) => v == null ? l10n.get('required') : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _city,
                            decoration: InputDecoration(
                              labelText: l10n.get('city_field'), 
                              border: const OutlineInputBorder(),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            items: (_country != null && _state != null)
                                ? LocationData.citiesFor(_country!, _state!).map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis))).toList()
                                : [],
                            onChanged: (v) => setState(() => _city = v),
                            validator: (v) => v == null ? l10n.get('required') : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  if (_country != null) _buildPriceBadge(),
                  const SizedBox(height: 16),
                  if (MediaQuery.of(context).size.width < 600) ...[
                    // Mobile: Column layout
                    DropdownButtonFormField<String>(
                      value: _currencyCode,
                      decoration: InputDecoration(
                        labelText: l10n.get('currency_label_field'), 
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: _getCurrencies(l10n)
                          .fold<Map<String, Map<String, String>>>({}, (map, e) => map..putIfAbsent(e['code']!, () => e))
                          .values
                          .map((c) => DropdownMenuItem(value: c['code'], child: Text('${c['name']} (${c['symbol']})', style: const TextStyle(fontSize: 13))))
                          .toList(),
                      onChanged: (v) => setState(() => _currencyCode = v!),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _areaUnit,
                      decoration: InputDecoration(
                        labelText: l10n.get('unit_label_field'), 
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: [
                        DropdownMenuItem(value: 'm²', child: Text(l10n.get('meters_label'), style: const TextStyle(fontSize: 13))),
                        DropdownMenuItem(value: 'ft²', child: Text(l10n.get('feet_label'), style: const TextStyle(fontSize: 13))),
                      ],
                      onChanged: (v) => setState(() => _areaUnit = v!),
                    ),
                  ] else ...[
                    // Desktop: Row layout
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _currencyCode,
                            decoration: InputDecoration(
                              labelText: l10n.get('currency_label_field'), 
                              border: const OutlineInputBorder(),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            items: _getCurrencies(l10n)
                                .fold<Map<String, Map<String, String>>>({}, (map, e) => map..putIfAbsent(e['code']!, () => e))
                                .values
                                .map((c) => DropdownMenuItem(value: c['code'], child: Text('${c['name']} (${c['symbol']})', style: const TextStyle(fontSize: 13))))
                                .toList(),
                            onChanged: (v) => setState(() => _currencyCode = v!),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _areaUnit,
                            decoration: InputDecoration(
                              labelText: l10n.get('unit_label_field'), 
                              border: const OutlineInputBorder(),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            items: [
                              DropdownMenuItem(value: 'm²', child: Text(l10n.get('meters_label'), style: const TextStyle(fontSize: 13))),
                              DropdownMenuItem(value: 'ft²', child: Text(l10n.get('feet_label'), style: const TextStyle(fontSize: 13))),
                            ],
                            onChanged: (v) => setState(() => _areaUnit = v!),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 24),

                  // BRANDING
                  Text(
                    l10n.get('register_branding'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  if (MediaQuery.of(context).size.width < 600) ...[
                    // Mobile: Column layout
                    TextFormField(
                      controller: _primaryColorCtrl,
                      decoration: InputDecoration(
                        labelText: l10n.get('register_primary_color'),
                        hintText: '#006837',
                        border: const OutlineInputBorder(),
                        prefixIcon: Container(
                          margin: const EdgeInsets.all(12),
                          width: 15, height: 15,
                          decoration: BoxDecoration(
                            color: _parseColor(_primaryColorCtrl.text),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey[400]!),
                          ),
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _secondaryColorCtrl,
                      decoration: InputDecoration(
                        labelText: l10n.get('register_secondary_color'),
                        hintText: '#A64F35',
                        border: const OutlineInputBorder(),
                        prefixIcon: Container(
                          margin: const EdgeInsets.all(12),
                          width: 15, height: 15,
                          decoration: BoxDecoration(
                            color: _parseColor(_secondaryColorCtrl.text),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey[400]!),
                          ),
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ] else ...[
                    // Desktop: Row layout
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _primaryColorCtrl,
                            decoration: InputDecoration(
                              labelText: l10n.get('register_primary_color'),
                              hintText: '#006837',
                              border: const OutlineInputBorder(),
                              prefixIcon: Container(
                                margin: const EdgeInsets.all(12),
                                width: 15, height: 15,
                                decoration: BoxDecoration(
                                  color: _parseColor(_primaryColorCtrl.text),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.grey[400]!),
                                ),
                              ),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _secondaryColorCtrl,
                            decoration: InputDecoration(
                              labelText: l10n.get('register_secondary_color'),
                              hintText: '#A64F35',
                              border: const OutlineInputBorder(),
                              prefixIcon: Container(
                                margin: const EdgeInsets.all(12),
                                width: 15, height: 15,
                                decoration: BoxDecoration(
                                  color: _parseColor(_secondaryColorCtrl.text),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.grey[400]!),
                                ),
                              ),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                      ],
                    ),
                  ],
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: InkWell(
                      onTap: () => launchUrl(
                        Uri.parse('https://htmlcolorcodes.com'),
                        mode: LaunchMode.externalApplication,
                      ),
                      child: Text(
                        l10n.get('register_hex_link'),
                        style: const TextStyle(color: Colors.blue, fontSize: 12, decoration: TextDecoration.underline),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),



                  // ORIGIN / REFERRAL SECTION
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDark ? Colors.white10 : Colors.grey[300]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.help_outline, size: 20, color: AppThemes.primaryGreen),
                            const SizedBox(width: 8),
                            Text(l10n.get('register_how'),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // DROPDOWN — libre si es orgánico, bloqueado si hay estrategia activa
                        DropdownButtonFormField<String>(
                          key: const ValueKey('acquisition_channel_dropdown'),
                          value: _acquisitionChannel,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          items: [
                            DropdownMenuItem(value: 'organic',     child: Text(l10n.get('register_channel_organic'),     style: const TextStyle(fontSize: 13))),
                            DropdownMenuItem(value: 'salesperson', child: Text(l10n.get('register_channel_salesperson'), style: const TextStyle(fontSize: 13))),
                            DropdownMenuItem(value: 'broker',      child: Text(l10n.get('register_channel_broker'),      style: const TextStyle(fontSize: 13))),
                          ],
                          onChanged: _isReferralLocked ? null : (String? v) {
                            if (v != null) {
                              debugPrint('[REGISTER] Manual channel change: $v');
                              setState(() {
                                _acquisitionChannel = v;
                                if (v == 'organic') {
                                  _aliasCtrl.clear();
                                  _referralEmail = null;
                                }
                              });
                            }
                          },
                        ),

                        // ESTRATEGIA 2: Salesperson — dropdown con todos los vendedores
                        if (_acquisitionChannel == 'salesperson') ...[
                          const SizedBox(height: 16),
                          if (_salespersons.isEmpty)
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text('Cargando ejecutivos o no hay disponibles...', style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic)),
                            )
                          else
                            DropdownButtonFormField<String>(
                              key: const ValueKey('salesperson_dropdown'),
                              value: _salespersons.any((s) => (s['alias']?.toString() ?? '') == _selectedSalespersonAlias)
                                  ? _selectedSalespersonAlias
                                  : null,
                              decoration: InputDecoration(
                                labelText: 'Ejecutivo de venta',
                                prefixIcon: const Icon(Icons.badge_outlined),
                                border: const OutlineInputBorder(),
                                filled: _isReferralLocked,
                                fillColor: _isReferralLocked ? (isDark ? Colors.white10 : Colors.grey[200]) : null,
                              ),
                              items: _salespersons.map((s) {
                                final aliasStr = s['alias']?.toString() ?? '';
                                final nameStr = s['full_name']?.toString() ?? aliasStr;
                                return DropdownMenuItem<String>(
                                  value: aliasStr,
                                  child: Text('$aliasStr  —  $nameStr', style: const TextStyle(fontSize: 13)),
                                );
                              }).toList(),
                              onChanged: _isReferralLocked ? null : (String? v) {
                                if (v != null) {
                                  setState(() {
                                    _selectedSalespersonAlias = v;
                                    _aliasCtrl.text = v;
                                  });
                                }
                              },
                              validator: (_) => (_acquisitionChannel == 'salesperson' &&
                                      (_selectedSalespersonAlias == null || _selectedSalespersonAlias!.isEmpty))
                                  ? 'Selecciona un ejecutivo'
                                  : null,
                            ),
                        ],

                        // ESTRATEGIA 1: Broker — email pre-cargado (readonly) o botón para abrir diálogo
                        if (_acquisitionChannel == 'broker') ...[
                          const SizedBox(height: 16),
                          if (_isReferralLocked || _referralEmail != null)
                            Container(
                              key: const ValueKey('broker_active_display'),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.green),
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.green.withValues(alpha: 0.1),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle, color: Colors.green),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _referralEmail ?? '',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  if (!_isReferralLocked)
                                    IconButton(
                                      icon: const Icon(Icons.edit, size: 20),
                                      onPressed: _askReferral,
                                      tooltip: 'Cambiar agencia',
                                    )
                                ],
                              ),
                            )
                          else
                            Row(
                              key: const ValueKey('broker_ask_button'),
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    icon: const Icon(Icons.handshake),
                                    label: const Text('Indicar Correo de Agencia Referente'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                                      foregroundColor: isDark ? Colors.white : Colors.black87,
                                      elevation: 0,
                                      minimumSize: const Size(double.infinity, 50),
                                    ),
                                    onPressed: _askReferral,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ],
                    ),
                  ),

                  // CONTRACT SECTION
                  const SizedBox(height: 32),
                  _buildContractSection(l10n),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      backgroundColor: _termsAccepted ? AppThemes.primaryGreen : Colors.grey,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: (_isLoading || !_termsAccepted) ? null : _submit,
                    child: _isLoading 
                        ? const CircularProgressIndicator(color: Colors.white) 
                        : Text(l10n.get('register_submit'), style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _parseColor(String? hex) {
    if (hex == null || hex.length < 6) return Colors.transparent;
    try {
      final cleanHex = hex.replaceAll('#', '');
      return Color(int.parse('FF$cleanHex', radix: 16));
    } catch (_) {
      return Colors.transparent;
    }
  }

  Widget _buildContractSection(AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEs = l10n.locale.languageCode == 'es';
    
    final agencyName = _companyCtrl.text.trim().isEmpty ? '[Nombre de la Agencia]' : _companyCtrl.text.trim();
    final agencyRep  = _nameCtrl.text.trim().isEmpty ? '[Nombre del representante]' : _nameCtrl.text.trim();
    final agencyEmail = _emailCtrl.text.trim().isEmpty ? '[correo@agencia.com]' : _emailCtrl.text.trim();
    final agencyPhone = _phoneCtrl.text.trim().isEmpty ? '[Teléfono]' : _phoneCtrl.text.trim();
    final agencyDomain = _domainCtrl.text.trim().isEmpty ? '[dominio].alveo.fyi' : '${_domainCtrl.text.trim()}.alveo.fyi';
    final agencyCountry = _country ?? '[País]';
    final agencyCity = _city ?? '[Ciudad]';
    
    final planLabel = _billingCycle == 'annual' 
        ? (isEs ? 'Anual' : 'Annual') 
        : (isEs ? 'Mensual' : 'Monthly');
        
    final planPrice = _billingCycle == 'annual'
        ? NumberFormat.simpleCurrency().format(_priceMonthly * 11)
        : NumberFormat.simpleCurrency().format(_priceMonthly);
        
    final today = DateTime.now();
    final dateStr = isEs 
        ? '${today.day.toString().padLeft(2,'0')} de ${_monthName(today.month)} de ${today.year}'
        : '${_monthName(today.month)} ${today.day}, ${today.year}';

    final String contractText;
    if (isEs) {
      contractText = '''
CONTRATO DE PRESTACIÓN DE SERVICIOS SaaS (PMS INMOBILIARIO)

REUNIDOS

De una parte, Alveo - Asistente Inmobiliario, representada por Ricardo D. Figueroa A., en adelante el PRESTADOR.

De otra parte, $agencyName, representada por $agencyRep, en adelante el CLIENTE.

Ambas partes se reconocen capacidad legal suficiente y suscriben el presente contrato de acuerdo con las siguientes:

CLÁUSULAS

1. OBJETO DEL CONTRATO
El PRESTADOR otorga al CLIENTE una licencia de uso no exclusiva, intransferible y temporal para acceder y utilizar su software de gestión inmobiliaria (PMS) basado en la nube, denominado Alveo - Asistente Inmobiliario, para la gestión de activos, clientes, publicaciones en portales y procesos internos de la agencia.

2. SERVICIOS INCLUIDOS
El servicio comprende:
• Acceso a la plataforma 24/7 (salvo mantenimientos programados).
• Alojamiento de datos en servidores seguros.
• Copias de seguridad periódicas.
• Soporte técnico vía Email (alveo.soporte@gmail.com) en horario Lunes a Viernes, 9:00am – 6:00pm.
• Actualizaciones automáticas del software.

2b. CUOTAS Y LÍMITES DE USO (SaaS)
La suscripción base incluye:
• Hasta ${_globalLimits['max_properties']} inmuebles activos publicados simultáneamente.
• Hasta ${_globalLimits['max_photos_per_property']} fotografías por inmueble.
Estos límites son dinámicos y pueden ampliarse mediante el programa de referidos o acuerdo especial con el PRESTADOR.

3. PRECIO Y FORMA DE PAGO
El CLIENTE abonará la cantidad de $planPrice con una periodicidad $planLabel.

Método de pago: El pago se realizará mediante Transferencia Bancaria o Depósito. Los detalles de la cuenta bancaria para su región serán enviados en el correo electrónico de bienvenida.

Justificante: El CLIENTE deberá enviar el comprobante de la operación al correo alveo.soporte@gmail.com para la validación y renovación del servicio.

El impago de una cuota tras 5 días de su vencimiento facultará al PRESTADOR para suspender temporalmente el acceso al servicio.

4. PROPIEDAD INTELECTUAL Y DE LOS DATOS
Software: El PRESTADOR es el único titular de los derechos de propiedad intelectual de la plataforma Alveo.

Datos: El CLIENTE es el único propietario de los datos introducidos (propiedades, fotos, datos de clientes). En caso de rescisión, el PRESTADOR facilitará la exportación de estos datos en formato Excel durante un periodo de 15 días.

5. PROTECCIÓN DE DATOS (RGPD / LOPD)
Ambas partes cumplen con la normativa vigente de protección de datos. El PRESTADOR actúa como Encargado del Tratamiento, procesando los datos personales solo para la prestación del servicio y bajo las instrucciones del CLIENTE.

Los datos se almacenan en servidores ubicados en US East (AWS / Supabase).

6. DURACIÓN Y RESCISIÓN
El presente contrato tiene una duración $planLabel y se prorrogará automáticamente por periodos iguales salvo que una de las partes notifique su voluntad de no renovar con 15 días de antelación.

7. CONFIDENCIALIDAD
Ambas partes se obligan a mantener estricta confidencialidad sobre la información de negocio, estrategias y precios a la que tengan acceso durante la vigencia de este acuerdo.

8. LIMITACIÓN DE RESPONSABILIDAD
El PRESTADOR no será responsable de las interrupciones de servicio debidas a causas de fuerza mayor o fallos en las redes de telecomunicaciones ajenas a su control. La responsabilidad total máxima del PRESTADOR no excederá la suma de las cuotas pagadas por el CLIENTE en los últimos 3 meses.

Firmado en $agencyCity, $agencyCountry, el $dateStr.

El CLIENTE: $agencyName
Representado por: $agencyRep
Correo: $agencyEmail · Teléfono: $agencyPhone
Dominio: https://$agencyDomain · País: $agencyCountry

El PRESTADOR: Alveo - Asistente Inmobiliario
''';
    } else {
      contractText = '''
SaaS SERVICE AGREEMENT (REAL ESTATE PMS)

PARTIES

On the one hand, Alveo - Real Estate Assistant, represented by Ricardo D. Figueroa A., hereinafter the PROVIDER.

On the other hand, $agencyName, represented by $agencyRep, hereinafter the CLIENT.

Both parties recognize each other's legal capacity and subscribe to this contract in accordance with the following:

CLAUSES

1. PURPOSE OF THE CONTRACT
The PROVIDER grants the CLIENT a non-exclusive, non-transferable, and temporary license to access and use its cloud-based real estate management software (PMS), named Alveo - Real Estate Assistant, for managing assets, clients, portal listings, and agency internal processes.

2. SERVICES INCLUDED
The service includes:
• 24/7 access to the platform (except for scheduled maintenance).
• Data hosting on secure servers.
• Periodic backups.
• Technical support via Email (alveo.soporte@gmail.com) during Monday to Friday, 9:00am – 6:00pm.
• Automatic software updates.

2b. SaaS USAGE QUOTAS
The base subscription includes:
• Up to ${_globalLimits['max_properties']} active property listings simultaneously.
• Up to ${_globalLimits['max_photos_per_property']} photos per property.
These limits are dynamic and can be expanded through the referral program or special agreement with the PROVIDER.

3. PRICE AND PAYMENT METHOD
The CLIENT will pay the amount of $planPrice with a $planLabel periodicity.

Payment method: Payment shall be made via Bank Transfer or Deposit. Bank account details for your region will be provided in the welcome email.

Proof of payment: The CLIENT must send the operation receipt to alveo.soporte@gmail.com for service validation and renewal.

Non-payment of a fee 5 days after its due date will authorize the PROVIDER to temporarily suspend access to the service.

4. INTELLECTUAL PROPERTY AND DATA
Software: The PROVIDER is the sole owner of the intellectual property rights of the Alveo platform.

Data: The CLIENT is the sole owner of the data entered (properties, photos, client data). In case of termination, the PROVIDER will facilitate the export of this data in Excel format for a period of 15 days.

5. DATA PROTECTION (GDPR)
Both parties comply with current data protection regulations. THE PROVIDER acts as a Data Processor, processing personal data only for the provision of the service and under the CLIENT'S instructions.

Data is stored on servers located in US East (AWS / Supabase).

6. DURATION AND TERMINATION
This contract has a $planLabel duration and will be automatically extended for equal periods unless one of the parties notifies its intention not to renew 15 days in advance.

7. CONFIDENTIALITY
Both parties are obliged to maintain strict confidentiality regarding business information, strategies, and prices to which they have access during the term of this agreement.

8. LIMITATION OF LIABILITY
The PROVIDER will not be responsible for service interruptions due to force majeure or failures in telecommunications networks beyond its control. The maximum total liability of the PROVIDER shall not exceed the sum of the fees paid by the CLIENT in the last 3 months.

Signed in $agencyCity, $agencyCountry, on $dateStr.

THE CLIENT: $agencyName
Represented by: $agencyRep
Email: $agencyEmail · Phone: $agencyPhone
Domain: https://$agencyDomain · Country: $agencyCountry

THE PROVIDER: Alveo - Real Estate Assistant
''';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Icon(Icons.description_outlined, color: AppThemes.primaryGreen, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.get('contract_section_header'),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                  color: isDark ? Colors.white70 : Colors.blueGrey[700],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Contract text in scrollable container
        Container(
          height: 320,
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _termsAccepted
                  ? AppThemes.primaryGreen.withValues(alpha: 0.6)
                  : (isDark ? Colors.white12 : Colors.grey[300]!),
              width: _termsAccepted ? 1.5 : 1,
            ),
          ),
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(scrollbars: true),
            child: SingleChildScrollView(
              controller: _contractScrollCtrl,
              padding: const EdgeInsets.all(16),
              child: Text(
                contractText,
                style: TextStyle(
                  fontSize: 11.5,
                  height: 1.7,
                  fontFamily: 'monospace',
                  color: isDark ? Colors.white70 : Colors.grey[800],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Acceptance checkbox
        Container(
          decoration: BoxDecoration(
            color: _termsAccepted
                ? AppThemes.primaryGreen.withValues(alpha: 0.08)
                : (isDark ? Colors.white.withValues(alpha: 0.03) : Colors.grey[100]),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _termsAccepted
                  ? AppThemes.primaryGreen.withValues(alpha: 0.5)
                  : (isDark ? Colors.white12 : Colors.grey[300]!),
            ),
          ),
          child: CheckboxListTile(
            value: _termsAccepted,
            activeColor: AppThemes.primaryGreen,
            onChanged: (v) => setState(() => _termsAccepted = v ?? false),
            title: Text(
              l10n.get('contract_accept'),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.grey[850],
              ),
            ),
            subtitle: _termsAccepted
                ? Text(
                    '${l10n.get("contract_accept_date")}: $dateStr',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppThemes.primaryGreen,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                : Text(
                    l10n.get('contract_required'),
                    style: const TextStyle(fontSize: 11, color: Colors.orange),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () => _downloadContractPdf(contractText, isEs),
            icon: const Icon(Icons.picture_as_pdf, color: Colors.redAccent, size: 20),
            label: Text(
              isEs ? 'Descargar Contrato (PDF)' : 'Download Contract (PDF)',
              style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  String _monthName(int month) {
    return AppLocalizations.of(context).get('month_$month');
  }

  Future<void> _downloadContractPdf(String text, bool isEs) async {
    final pdf = pw.Document();
    
    // Cargar una fuente que soporte Unicode (para los bullet points y guiones)
    final font = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          final lines = text.split('\n');
          return [
            pw.Header(
              level: 0,
              child: pw.Text(
                isEs ? 'Contrato de Servicio' : 'Service Agreement',
                style: pw.TextStyle(font: fontBold, fontSize: 18),
              ),
            ),
            pw.SizedBox(height: 10),
            ...lines.map((line) {
              if (line.trim().isEmpty) return pw.SizedBox(height: 8);
              return pw.Paragraph(
                text: line,
                style: pw.TextStyle(font: font, fontSize: 10, lineSpacing: 1.2),
              );
            }),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: isEs ? 'Contrato_Alveo.pdf' : 'Alveo_Agreement.pdf',
    );
  }




  Widget _buildLogoPicker(String label, String? url, bool isAbbr) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _isSavingLogo ? null : () => _pickImage(isAbbr),
          child: Container(
            width: 120,
            height: 80,
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? Colors.white24 : Colors.grey[300]!),
            ),
            child: _isSavingLogo 
              ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
              : (url != null
                ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(url, fit: BoxFit.contain))
                : const Icon(Icons.add_a_photo, color: Colors.grey, size: 30)),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceBadge() {
    final l10n = AppLocalizations.of(context);
    if (_isPriceFetching) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
      );
    }
    
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: _isCustomPrice ? Colors.green.withValues(alpha: 0.1) : AppThemes.primaryGreen.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _isCustomPrice ? Colors.green.withValues(alpha: 0.3) : AppThemes.primaryGreen.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.stars, size: 16, color: _isCustomPrice ? Colors.green : AppThemes.primaryGreen),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                    _isCustomPrice 
                      ? l10n.get('special_price_for', [_country ?? ''])
                      : l10n.get('standard_price_for', [_country ?? '']),
                    style: TextStyle(
                      fontWeight: FontWeight.bold, 
                      color: _isCustomPrice 
                          ? (Theme.of(context).brightness == Brightness.dark ? Colors.greenAccent : Colors.green[700]) 
                          : (Theme.of(context).brightness == Brightness.dark ? Colors.lightGreenAccent : AppThemes.primaryGreen),
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${l10n.get('monthly_short')}: ${NumberFormat.simpleCurrency().format(_priceMonthly)}  ·  ${l10n.get('annual_short')}: ${NumberFormat.simpleCurrency().format(_priceMonthly * 11)}',
              style: const TextStyle(fontSize: 12),
            ),
        ],
      ),
    );
  }
}
