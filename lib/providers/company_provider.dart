import 'package:flutter/foundation.dart';
import '../models/company.dart';
import '../services/company_service.dart';
import '../data/location_data.dart';

/// Provee la empresa activa a todo el árbol de widgets.
/// Se inicializa una sola vez al arrancar la app (en main.dart).
class CompanyProvider extends ChangeNotifier {
  Company _currentCompany = Company.empty;
  bool _isLoading = true;
  bool _isGlobalMode = false; // true → buscador global (empresa demo)

  // ─── Getters ──────────────────────────────────────────────────────────────

  Company get currentCompany => _currentCompany;
  Company get company => _currentCompany; // alias conveniente
  bool get isLoading => _isLoading;
  bool get isGlobalMode => _isGlobalMode;

  String get companyId => _currentCompany.id;
  String get companyName => _currentCompany.name;
  String companyLocalizedName(String languageCode) =>
      _currentCompany.localizedName(languageCode);

  String? get logoUrl => _currentCompany.logoUrl;
  String get primaryColorHex => _currentCompany.primaryColorHex;
  String get secondaryColorHex => _currentCompany.secondaryColorHex;
  String? get contactEmail => _currentCompany.contactEmail;
  String? get contactPhone => _currentCompany.contactPhone;
  String? get contactWhatsapp => _currentCompany.contactWhatsapp;
  String? get instagramUrl => _currentCompany.instagramUrl;
  String? get facebookUrl => _currentCompany.facebookUrl;
  String? get telegramUrl => _currentCompany.telegramUrl;
  bool get isDemo => _currentCompany.isDemo;
  bool get isSuspended => _currentCompany.subscriptionStatus == 'suspended';
  
  String get currencySymbol => _currentCompany.currencySymbol;
  String get currencyCode => _currentCompany.currencyCode;
  String get areaUnit => _currentCompany.areaUnit;
  String? get country => _currentCompany.country;
  String? get state => _currentCompany.state;

  // ─── Inicialización ───────────────────────────────────────────────────────

  /// Llamar desde main.dart antes de pintar la UI.
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    _currentCompany = await CompanyService.detectCompany();

    // En modo demo → mostrar buscador global
    _isGlobalMode = _currentCompany.isDemo;

    // Cargar las ubicaciones dinámicas de la empresa detectada
    await LocationData.init(companyId: _currentCompany.isDemo ? null : _currentCompany.id);

    _isLoading = false;
    notifyListeners();

    debugPrint('[CompanyProvider] Empresa activa: ${_currentCompany.name}');
    debugPrint('[CompanyProvider] Modo global: $_isGlobalMode');
  }

  /// Recarga los datos de la empresa actual desde la base de datos.
  Future<void> refresh() async {
    try {
      final updated = await CompanyService.detectCompany();
      _currentCompany = updated;
      _isGlobalMode = _currentCompany.isDemo;
      await LocationData.init(companyId: _currentCompany.isDemo ? null : _currentCompany.id);
      notifyListeners();
    } catch (e) {
      debugPrint('[CompanyProvider] Error al refrescar empresa: $e');
    }
  }

  /// Permite al Super Admin cambiar de empresa manualmente (sin recargar página).
  Future<void> switchCompany(Company company) async {
    _currentCompany = company;
    _isGlobalMode = company.isDemo;
    await LocationData.init(companyId: company.isDemo ? null : company.id);
    notifyListeners();
  }

  /// Actualiza los datos de la empresa actual (por ejemplo tras editar desde el panel).
  void updateCurrentCompany(Company company) {
    if (company.id == _currentCompany.id) {
      _currentCompany = company;
      notifyListeners();
    }
  }

  /// Restablece el estado para volver a la pantalla de inicio "real" de la empresa
  void resetToHome() {
    _isGlobalMode = _currentCompany.isDemo;
    notifyListeners();
  }
}
