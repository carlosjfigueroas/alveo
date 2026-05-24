import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/site_content.dart';
import '../models/user_profile.dart';
import 'supabase_service.dart';

class AppProvider extends ChangeNotifier {
  final SupabaseService _service = SupabaseService();
  ThemeMode _themeMode = ThemeMode.light;
  Locale _locale = const Locale('es');
  UserProfile? _userProfile;
  UserProfile? _agentContext;
  String? _referredBySalesperson;
  String? _salespersonName;
  String? _referrerEmail;
  bool _isLoading = false;

  List<AboutContent> _aboutContent = [];
  List<FaqEntry> _faqs = [];

  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;
  UserProfile? get userProfile => _userProfile;
  UserProfile? get agentContext => _agentContext;
  String? get referredBySalesperson => _referredBySalesperson;
  String? get salespersonName => _salespersonName;
  String? get referrerEmail => _referrerEmail;
  bool get isLoading => _isLoading;
  bool get isAdmin => _userProfile?.role == 'admin' ||
      _userProfile?.role == 'agent' ||
      _userProfile?.role == 'company_admin' ||
      _userProfile?.role == 'super_admin';

  bool get isSuperAdmin => _userProfile?.role == 'super_admin';
  bool get isCompanyAdmin => _userProfile?.role == 'company_admin' ||
      _userProfile?.role == 'admin';


  List<AboutContent> get aboutContent => _aboutContent;
  List<FaqEntry> get faqs => _faqs;

  AppProvider() {
    _loadPreferences();
    _checkInitialSession();
    // fetchSiteContent ahora requiere companyId — se llama desde HomeScreen
    // cuando el CompanyProvider ya está inicializado.
  }

  Future<void> fetchSiteContent(String companyId) async {
    try {
      _aboutContent = await _service.getAboutContent(companyId);
      _faqs = await _service.getFaqs(companyId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching site content: $e');
    }
  }

  void setUserProfile(UserProfile? profile) {
    _userProfile = profile;
    // Si el usuario es un agente, lo establecemos como contexto por defecto
    if (profile != null && profile.role == 'agent') {
      _agentContext = profile;
    }
    notifyListeners();
  }

  void setAgentContext(UserProfile? agent) {
    if (_agentContext?.id == agent?.id) return;
    _agentContext = agent;
    notifyListeners();
  }

  void setReferralContext({String? salespersonAlias, String? salespersonName, String? referrerEmail}) {
    _referredBySalesperson = salespersonAlias;
    _salespersonName = salespersonName;
    _referrerEmail = referrerEmail;
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  Future<void> _checkInitialSession() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      final profile = await _service.getUserProfile(session.user.id);
      _userProfile = profile;
      notifyListeners();
    }
  }

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    _savePreferences();
    notifyListeners();
  }

  void setLocale(Locale newLocale) {
    _locale = newLocale;
    _savePreferences();
    notifyListeners();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final isDarkMode = prefs.getBool('isDarkMode') ?? false;
    _themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;

    final String? savedLang = prefs.getString('languageCode');
    if (savedLang != null) {
      _locale = Locale(savedLang);
    } else {
      // Detección automática al iniciar (solo si no hay preferencia guardada)
      // Usamos el locale del sistema/navegador
      final String sysLang = WidgetsBinding.instance.platformDispatcher.locale.languageCode.toLowerCase();
      if (sysLang == 'en' || sysLang == 'es') {
        _locale = Locale(sysLang);
      } else {
        _locale = const Locale('es'); // Default
      }
    }
    notifyListeners();
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _themeMode == ThemeMode.dark);
    await prefs.setString('languageCode', _locale.languageCode);
  }
  
  Future<void> signOut() async {
    await Supabase.instance.client.auth.signOut();
    _userProfile = null;
    notifyListeners();
  }
}
