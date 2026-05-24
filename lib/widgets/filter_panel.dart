import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import '../models/property_filter.dart';
import '../services/app_themes.dart';
import '../services/app_localizations.dart';
import '../services/app_provider.dart';
import '../services/supabase_service.dart';
import 'package:provider/provider.dart';
import '../data/location_data.dart';
import '../providers/company_provider.dart';

class FilterPanel extends StatefulWidget {
  final PropertyFilter initialFilter;

  const FilterPanel({super.key, required this.initialFilter});

  @override
  State<FilterPanel> createState() => _FilterPanelState();
}

class _FilterPanelState extends State<FilterPanel> {
  late PropertyFilter _filter;
  List<Map<String, dynamic>>? _owners;

  final _minPriceCtrl = TextEditingController();
  final _maxPriceCtrl = TextEditingController();
  final _minAreaCtrl = TextEditingController();
  final _maxAreaCtrl = TextEditingController();
  final _minPlotAreaCtrl = TextEditingController();
  final _maxPlotAreaCtrl = TextEditingController();
  final _minYearCtrl = TextEditingController();
  final _maxYearCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  static const _residentialTypes = [
    'Casa', 'Apartamento', 'Townhouse', 'Dúplex', 'Ático', 'Loft', 'Estudio', 
    'Casa vacacional', 'Apartamento vacacional'
  ];
  static const _commercialTypes = [
    'Posada',
    'Galpon',
    'Tienda', 
    'Terreno', 
    'Hotel', 
    'Oficina', 
    'Patio Industrial', 
    'Centro Comercial',
    'Local', 
    'Otro'
  ];

  @override
  void initState() {
    super.initState();
    _filter = widget.initialFilter.copyWith();
    
    // Auto-detect category from filter
    if (_filter.category == null && _filter.types.isNotEmpty) {
      if (_residentialTypes.contains(_filter.types.first)) {
        _filter.category = 'Residential';
      } else {
        _filter.category = 'Commercial';
      }
    }
    // We intentionally allow _filter.category to remain null so no filter is applied tightly by default.
    
    if (_filter.minPrice != null) _minPriceCtrl.text = NumberFormat('#,###.00').format(_filter.minPrice);
    if (_filter.maxPrice != null) _maxPriceCtrl.text = NumberFormat('#,###.00').format(_filter.maxPrice);
    if (_filter.minArea != null) _minAreaCtrl.text = NumberFormat('#,###.##').format(_filter.minArea);
    if (_filter.maxArea != null) _maxAreaCtrl.text = NumberFormat('#,###.##').format(_filter.maxArea);
    if (_filter.minPlotArea != null) _minPlotAreaCtrl.text = NumberFormat('#,###.##').format(_filter.minPlotArea);
    if (_filter.maxPlotArea != null) _maxPlotAreaCtrl.text = NumberFormat('#,###.##').format(_filter.maxPlotArea);
    if (_filter.minYear != null) _minYearCtrl.text = _filter.minYear!.toString();
    if (_filter.maxYear != null) _maxYearCtrl.text = _filter.maxYear!.toString();
    if (_filter.address != null) _addressCtrl.text = _filter.address!;

    // Pre-select country from company if not already set
    if (_filter.country == null) {
      final companyProv = Provider.of<CompanyProvider>(context, listen: false);
      if (companyProv.country != null) {
        _filter.country = companyProv.country;
      }
    }

    _loadOwners();
  }

  Future<void> _loadOwners() async {
    try {
      final companyId = Provider.of<CompanyProvider>(context, listen: false).companyId;
      final owners = await SupabaseService().getOwners(companyId);
      if (mounted) setState(() => _owners = owners);
    } catch (e) {
      // Ignore
    }
  }

  @override
  void dispose() {
    _minPriceCtrl.dispose();
    _maxPriceCtrl.dispose();
    _minAreaCtrl.dispose();
    _maxAreaCtrl.dispose();
    _minPlotAreaCtrl.dispose();
    _maxPlotAreaCtrl.dispose();
    _minYearCtrl.dispose();
    _maxYearCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  void _resetFilters() {
    setState(() {
      _filter = PropertyFilter();
      _minPriceCtrl.clear();
      _maxPriceCtrl.clear();
      _minAreaCtrl.clear();
      _maxAreaCtrl.clear();
      _minPlotAreaCtrl.clear();
      _maxPlotAreaCtrl.clear();
      _minYearCtrl.clear();
      _maxYearCtrl.clear();
      _addressCtrl.clear();
    });
  }

  void _applyFilters() {
    _filter = _filter.copyWith(
      minPrice: _minPriceCtrl.text.isNotEmpty ? double.tryParse(_minPriceCtrl.text.replaceAll(',', '')) : null,
      maxPrice: _maxPriceCtrl.text.isNotEmpty ? double.tryParse(_maxPriceCtrl.text.replaceAll(',', '')) : null,
      minArea: _minAreaCtrl.text.isNotEmpty ? double.tryParse(_minAreaCtrl.text.replaceAll(',', '')) : null,
      maxArea: _maxAreaCtrl.text.isNotEmpty ? double.tryParse(_maxAreaCtrl.text.replaceAll(',', '')) : null,
      minPlotArea: _minPlotAreaCtrl.text.isNotEmpty ? double.tryParse(_minPlotAreaCtrl.text.replaceAll(',', '')) : null,
      maxPlotArea: _maxPlotAreaCtrl.text.isNotEmpty ? double.tryParse(_maxPlotAreaCtrl.text.replaceAll(',', '')) : null,
      minYear: _minYearCtrl.text.isNotEmpty ? int.tryParse(_minYearCtrl.text) : null,
      maxYear: _maxYearCtrl.text.isNotEmpty ? int.tryParse(_maxYearCtrl.text) : null,
      address: _addressCtrl.text.isNotEmpty ? _addressCtrl.text : null,
    );
    Navigator.pop(context, _filter);
  }

  Widget _sectionTitle(String text, Color textColor) => Padding(
        padding: const EdgeInsets.only(top: 24, bottom: 12),
        child: Text(text, 
          style: TextStyle(
            fontWeight: FontWeight.bold, 
            fontSize: 18, 
            color: textColor,
          )
        ),
      );

  Widget _buildTypeCheckbox(String type, AppLocalizations l10n) {
    final isSelected = _filter.types.contains(type);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: () {
          setState(() {
            final updated = Set<String>.from(_filter.types);
            if (isSelected) updated.remove(type);
            else updated.add(type);
            _filter = _filter.copyWith(types: updated);
          });
        },
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: isSelected ? AppThemes.primaryGreen : Colors.grey[600]!, width: 2),
                color: isSelected ? AppThemes.primaryGreen : Colors.transparent,
              ),
              child: isSelected ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.get(type),
                style: TextStyle(
                  fontSize: 14,
                  color: (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Theme.of(context).colorScheme.onSurface),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final l10n = AppLocalizations(appProvider.locale);
    
    final isDark = appProvider.themeMode == ThemeMode.dark;
    final panelBg = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final secondaryBg = isDark ? const Color(0xFF2C2C2C) : Colors.grey[100];
    final textColor = isDark ? Colors.white : Colors.black87;
    final subColor = isDark ? Colors.white70 : Colors.black54;
    final accentColor = AppThemes.primaryGreen;

    final companyProv = Provider.of<CompanyProvider>(context, listen: false);

    return Theme(
      data: Theme.of(context).copyWith(
        brightness: isDark ? Brightness.dark : Brightness.light,
        scaffoldBackgroundColor: panelBg,
        cardColor: secondaryBg,
      ),
      child: Dialog(
        insetPadding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width < 600 ? 8 : 16, vertical: 24),
        backgroundColor: panelBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Text(l10n.get('advanced_filters'), style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor)),
                    const Spacer(),
                    IconButton(
                      icon: Icon(Icons.close, color: subColor),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Buy/Rent Toggle
                      Row(
                        children: [
                          _buildSegmentButton(l10n.get('buy'), _filter.operationType == 'Venta', () {
                            setState(() => _filter = _filter.copyWith(operationType: 'Venta'));
                          }),
                          const SizedBox(width: 12),
                          _buildSegmentButton(l10n.get('rent'), _filter.operationType == 'Alquiler', () {
                            setState(() => _filter = _filter.copyWith(operationType: 'Alquiler'));
                          }),
                        ],
                      ),

                      _sectionTitle(l10n.get('prop_type'), textColor),
                      
                      // Category Selector
                      Row(
                        children: [
                          _buildCategoryButton(
                            label: l10n.get('residential_cat'),
                            icon: Icons.home_outlined,
                            isSelected: _filter.category == 'Residential',
                            onTap: () => setState(() {
                              if (_filter.category == 'Residential') {
                                _filter = _filter.copyWith(category: null, types: {});
                              } else {
                                _filter = _filter.copyWith(category: 'Residential', types: {});
                              }
                            }),
                          ),
                          const SizedBox(width: 16),
                          _buildCategoryButton(
                            label: l10n.get('commercial_cat'),
                            icon: Icons.business_outlined,
                            isSelected: _filter.category == 'Commercial',
                            onTap: () => setState(() {
                              if (_filter.category == 'Commercial') {
                                _filter = _filter.copyWith(category: null, types: {});
                              } else {
                                _filter = _filter.copyWith(category: 'Commercial', types: {});
                              }
                            }),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),
                      _sectionTitle(l10n.get('bathrooms_field') + ' ' + l10n.get('minimum_suffix'), textColor),
                      _buildNumericOptions(
                        current: _filter.minBathrooms,
                        onChanged: (val) => setState(() => _filter = _filter.copyWith(minBathrooms: val)),
                      ),

                      _sectionTitle(l10n.get('parking_field') + ' ' + l10n.get('minimum_suffix'), textColor),
                      _buildNumericOptions(
                        current: _filter.minParkingSpaces,
                        onChanged: (val) => setState(() => _filter = _filter.copyWith(minParkingSpaces: val)),
                      ),

                      const SizedBox(height: 24),

                      // Types Grid
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 4.5,
                          crossAxisSpacing: 16,
                        ),
                        itemCount: () {
                          if (_filter.category == 'Residential') {
                            // Filter out vacation types if not in Rent mode
                            if (_filter.operationType != 'Alquiler') {
                              return _residentialTypes.where((t) => !t.contains('vacacional')).length;
                            }
                            return _residentialTypes.length;
                          }
                          return _commercialTypes.length;
                        }(),
                        itemBuilder: (context, index) {
                          final types = _filter.category == 'Residential' 
                            ? (_filter.operationType != 'Alquiler' 
                                ? _residentialTypes.where((t) => !t.contains('vacacional')).toList() 
                                : _residentialTypes)
                            : _commercialTypes;
                          return _buildTypeCheckbox(types[index], l10n);
                        },
                      ),

                      // Range Filters
                      const Divider(height: 48, color: Colors.white10),
                      


                      _rangeInputs(l10n.get('price_field'), _minPriceCtrl, _maxPriceCtrl, companyProv.currencySymbol),
                      _rangeInputs(l10n.get('area_field'), _minAreaCtrl, _maxAreaCtrl, companyProv.areaUnit),
                      
                      const SizedBox(height: 16),
                      // New Commercial Dropdowns
                      _buildDropdownFilter(
                        label: l10n.get('delivery_status_field'),
                        hint: l10n.get('any_value'),
                        icon: Icons.delivery_dining_outlined,
                        value: _filter.deliveryStatus,
                        items: ['obra_gris', 'semi_acabado', 'listo_para_ocupar'],
                        itemLabels: {
                          'obra_gris': l10n.get('obra_gris'),
                          'semi_acabado': l10n.get('semi_acabado'),
                          'listo_para_ocupar': l10n.get('listo_para_ocupar'),
                        },
                        onChanged: (v) => setState(() => _filter = _filter.copyWith(deliveryStatus: v)),
                      ),
                      const SizedBox(height: 12),
                      _buildDropdownFilter(
                        label: l10n.get('floor_level_field'),
                        hint: l10n.get('any_value'),
                        icon: Icons.layers_outlined,
                        value: _filter.floorLevel == 'incluido_en_direccion' ? null : _filter.floorLevel,
                        items: [
                          'planta_baja', 'mezzanina',
                          'primer_piso', 'segundo_piso', 'tercer_piso', 'cuarto_piso'
                        ],
                        itemLabels: {
                          'planta_baja': l10n.get('planta_baja'),
                          'mezzanina': l10n.get('mezzanina'),
                          'primer_piso': l10n.get('primer_piso'),
                          'segundo_piso': l10n.get('segundo_piso'),
                          'tercer_piso': l10n.get('tercer_piso'),
                          'cuarto_piso': l10n.get('cuarto_piso'),
                        },
                        onChanged: (v) => setState(() => _filter = _filter.copyWith(floorLevel: v)),
                      ),

                      const Divider(height: 48, color: Colors.white10),
                      _sectionTitle(l10n.get('popularity'), textColor),
                      _buildSwitchRow(
                        label: l10n.get('popularity_switch_label'),
                        value: (_filter.minLikes ?? 0) >= 5,
                        onChanged: (v) => setState(() => _filter = _filter.copyWith(minLikes: v ? 5 : null)),
                      ),

                      const Divider(height: 48, color: Colors.white10),
                      _sectionTitle(l10n.get('amenities_title'), textColor),
                      
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: MediaQuery.of(context).size.width < 600 ? 1 : 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 0,
                        childAspectRatio: MediaQuery.of(context).size.width < 600 ? 5 : 3.5,
                        children: [
                          _buildSwitchRow(label: l10n.get('pool_field'), value: _filter.hasPool ?? false, onChanged: (v) => setState(() => _filter = _filter.copyWith(hasPool: v))),
                          _buildSwitchRow(label: l10n.get('patio_field'), value: _filter.hasPatio ?? false, onChanged: (v) => setState(() => _filter = _filter.copyWith(hasPatio: v))),
                          _buildSwitchRow(label: l10n.get('fitted_kitchen_field'), value: _filter.hasFittedKitchen ?? false, onChanged: (v) => setState(() => _filter = _filter.copyWith(hasFittedKitchen: v))),
                          _buildSwitchRow(label: l10n.get('elevator_field'), value: _filter.hasElevator ?? false, onChanged: (v) => setState(() => _filter = _filter.copyWith(hasElevator: v))),
                          _buildSwitchRow(label: l10n.get('storage_field'), value: _filter.hasExtraStorage ?? false, onChanged: (v) => setState(() => _filter = _filter.copyWith(hasExtraStorage: v))),
                          _buildSwitchRow(label: l10n.get('power_generator_field'), value: _filter.hasPowerGenerator ?? false, onChanged: (v) => setState(() => _filter = _filter.copyWith(hasPowerGenerator: v))),
                          _buildSwitchRow(label: l10n.get('water_tank_field'), value: _filter.hasWaterTank ?? false, onChanged: (v) => setState(() => _filter = _filter.copyWith(hasWaterTank: v))),
                          _buildSwitchRow(label: l10n.get('air_con_field'), value: _filter.hasAirCon ?? false, onChanged: (v) => setState(() => _filter = _filter.copyWith(hasAirCon: v))),
                          _buildSwitchRow(label: l10n.get('terrace_field'), value: _filter.hasTerrace ?? false, onChanged: (v) => setState(() => _filter = _filter.copyWith(hasTerrace: v))),
                          _buildSwitchRow(label: l10n.get('balcony_field'), value: _filter.hasBalcony ?? false, onChanged: (v) => setState(() => _filter = _filter.copyWith(hasBalcony: v))),
                          _buildSwitchRow(label: l10n.get('garage_field'), value: _filter.hasGarage ?? false, onChanged: (v) => setState(() => _filter = _filter.copyWith(hasGarage: v))),
                          _buildSwitchRow(label: l10n.get('security_field'), value: _filter.hasSecurity ?? false, onChanged: (v) => setState(() => _filter = _filter.copyWith(hasSecurity: v))),
                          _buildSwitchRow(label: l10n.get('waterfront_field'), value: _filter.isWaterfront ?? false, onChanged: (v) => setState(() => _filter = _filter.copyWith(isWaterfront: v))),
                          _buildSwitchRow(label: l10n.get('seaview_field'), value: _filter.hasSeaView ?? false, onChanged: (v) => setState(() => _filter = _filter.copyWith(hasSeaView: v))),
                          _buildSwitchRow(label: l10n.get('garden_field'), value: _filter.hasGarden ?? false, onChanged: (v) => setState(() => _filter = _filter.copyWith(hasGarden: v))),
                          _buildSwitchRow(label: l10n.get('furnished_field'), value: _filter.isFurnished ?? false, onChanged: (v) => setState(() => _filter = _filter.copyWith(isFurnished: v))),
                           _buildSwitchRow(label: l10n.get('basement_field'), value: _filter.hasBasement ?? false, onChanged: (v) => setState(() => _filter = _filter.copyWith(hasBasement: v))),
                          _buildSwitchRow(label: l10n.get('grill_field'), value: _filter.hasGrill ?? false, onChanged: (v) => setState(() => _filter = _filter.copyWith(hasGrill: v))),
                          if (_filter.category == 'Residential' && _filter.operationType == 'Alquiler') ...[
                            _buildSwitchRow(label: l10n.get('pets_allowed_field'), value: _filter.petsAllowed ?? false, onChanged: (v) => setState(() => _filter = _filter.copyWith(petsAllowed: v))),
                            _buildSwitchRow(label: l10n.get('children_allowed_field'), value: _filter.childrenAllowed ?? false, onChanged: (v) => setState(() => _filter = _filter.copyWith(childrenAllowed: v))),
                          ],
                          _buildSwitchRow(label: l10n.get('has_electricity_field'), value: _filter.hasElectricity ?? false, onChanged: (v) => setState(() => _filter = _filter.copyWith(hasElectricity: v))),
                          _buildSwitchRow(label: l10n.get('has_water_connections_field'), value: _filter.hasWaterConnections ?? false, onChanged: (v) => setState(() => _filter = _filter.copyWith(hasWaterConnections: v))),
                          _buildSwitchRow(label: l10n.get('has_restroom_access_field'), value: _filter.hasRestroomAccess ?? false, onChanged: (v) => setState(() => _filter = _filter.copyWith(hasRestroomAccess: v))),
                          _buildSwitchRow(label: l10n.get('has_ac_connection_field'), value: _filter.hasAcConnection ?? false, onChanged: (v) => setState(() => _filter = _filter.copyWith(hasAcConnection: v))),
                          if (_filter.category == 'Commercial')
                            _buildSwitchRow(label: l10n.get('has_storage_office_area_field'), value: _filter.hasStorageOfficeArea ?? false, onChanged: (v) => setState(() => _filter = _filter.copyWith(hasStorageOfficeArea: v))),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // --- Geographic Location Section ---
                      _sectionTitle(l10n.get('location_section'), textColor),
                      // Country
                      _buildGeoDropdown(
                        label: l10n.get('filter_country'),
                        hint: l10n.get('geo_select_country'),
                        icon: Icons.flag_outlined,
                        value: _filter.country,
                        items: LocationData.countries,
                        onChanged: (v) => setState(() {
                          _filter = _filter.copyWith(country: v, state: null, city: null);
                        }),
                      ),
                      const SizedBox(height: 12),
                      // State (depends on country)
                      _buildGeoDropdown(
                        label: l10n.get('filter_state'),
                        hint: l10n.get('geo_select_state'),
                        icon: Icons.map_outlined,
                        value: _filter.state,
                        items: _filter.country != null ? LocationData.statesFor(_filter.country!) : [],
                        onChanged: _filter.country == null ? null : (v) => setState(() {
                          _filter = _filter.copyWith(state: v, city: null);
                        }),
                      ),
                      const SizedBox(height: 12),
                      // City (depends on state)
                      _buildGeoDropdown(
                        label: l10n.get('filter_city'),
                        hint: l10n.get('geo_select_city'),
                        icon: Icons.location_city_outlined,
                        value: _filter.city,
                        items: (_filter.country != null && _filter.state != null)
                            ? LocationData.citiesFor(_filter.country!, _filter.state!)
                            : [],
                        onChanged: (_filter.country == null || _filter.state == null) ? null : (v) => setState(() {
                          _filter = _filter.copyWith(city: v);
                        }),
                      ),
                      const SizedBox(height: 12),
                      // Address / Sector Search
                      Text(
                        l10n.get('filter_address_label'),
                        style: TextStyle(fontWeight: FontWeight.w600, color: subColor, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _addressCtrl,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          hintText: l10n.get('filter_address_hint'),
                          hintStyle: TextStyle(color: subColor.withValues(alpha: 0.5), fontSize: 14),
                          filled: true,
                          fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[100],
                          prefixIcon: Icon(Icons.search, size: 18, color: subColor),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),

              // Bottom Actions
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  children: [
                    TextButton(
                      onPressed: _resetFilters,
                      child: Text(l10n.get('reset'), style: TextStyle(color: subColor)),
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: _applyFilters,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(l10n.get('apply').toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownFilter({
    required String label,
    required String hint,
    required IconData icon,
    required String? value,
    required List<String> items,
    required Map<String, String> itemLabels,
    required Function(String?) onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black87)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? Colors.white10 : Colors.grey[300]!),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              hint: Text(hint, style: const TextStyle(fontSize: 14)),
              icon: const Icon(Icons.keyboard_arrow_down),
              items: [
                DropdownMenuItem<String>(value: null, child: Text(hint)),
                ...items.map((key) => DropdownMenuItem(
                  value: key,
                  child: Text(itemLabels[key] ?? key, style: const TextStyle(fontSize: 14)),
                )),
              ],
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGeoDropdown({
    required String label,
    required String hint,
    required IconData icon,
    required String? value,
    required List<String> items,
    required Function(String?)? onChanged,
  }) {
    final isDisabled = onChanged == null || items.isEmpty;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? Colors.white24 : Colors.grey[300]!;
    final fieldBg = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[100]!;
    final subColor = isDark ? Colors.white54 : Colors.black54;
    final dropdownBg = isDark ? const Color(0xFF2A2A2A) : Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: fieldBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDisabled ? (isDark ? Colors.white12 : Colors.grey[200]!) : borderColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: dropdownBg,
          icon: Icon(Icons.keyboard_arrow_down, color: subColor),
          hint: Row(
            children: [
              Icon(icon, size: 16, color: isDisabled ? (isDark ? Colors.white24 : Colors.grey[300]!) : subColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(color: isDisabled ? (isDark ? Colors.white24 : Colors.grey[300]!) : subColor, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          items: [
            DropdownMenuItem<String>(
              value: null,
              child: Text(hint, style: TextStyle(color: subColor, fontSize: 13)),
            ),
            ...items.map((item) => DropdownMenuItem<String>(
              value: item,
              child: Text(item, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 13)),
            )),
          ],
          onChanged: isDisabled ? null : (v) => onChanged(v == null || v.isEmpty ? null : v),
          selectedItemBuilder: (ctx) => [
            const SizedBox.shrink(),
            ...items.map((item) => Row(
              children: [
                const Icon(Icons.check, size: 16, color: AppThemes.primaryGreen),
                const SizedBox(width: 8),
                Expanded(child: Text(item, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 15), overflow: TextOverflow.ellipsis)),
              ],
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentButton(String label, bool isSelected, VoidCallback onTap) {

    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSelected ? AppThemes.primaryGreen : (Theme.of(context).brightness == Brightness.dark ? Colors.white24 : Colors.grey[300]!)),
            color: isSelected ? AppThemes.primaryGreen.withValues(alpha: 0.1) : Colors.transparent,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? AppThemes.primaryGreen : (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Theme.of(context).colorScheme.onSurface),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? AppThemes.primaryGreen : (isDark ? Colors.white12 : Colors.grey[300]!), width: 2),
            color: isSelected ? AppThemes.primaryGreen.withValues(alpha: 0.05) : Colors.transparent,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: isSelected ? AppThemes.primaryGreen : (isDark ? Colors.white38 : Colors.grey[400])),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? AppThemes.primaryGreen : (isDark ? Colors.white60 : Theme.of(context).colorScheme.onSurface),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChoiceChip(String status, bool isSelected) {
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            final updated = Set<String>.from(_filter.statuses);
            if (isSelected) updated.remove(status);
            else updated.add(status);
            _filter = _filter.copyWith(statuses: updated);
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: isSelected ? AppThemes.primaryGreen : (Theme.of(context).brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[200]),
            border: Border.all(color: isSelected ? AppThemes.primaryGreen : (Theme.of(context).brightness == Brightness.dark ? Colors.white24 : Colors.grey[300]!)),
          ),
          child: Center(
            child: Text(
              AppLocalizations.of(context).get(status),
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Theme.of(context).colorScheme.onSurface),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNumericOptions({int? current, required Function(int?) onChanged}) {
    final l10n = AppLocalizations.of(context);
    final options = [null, 1, 2, 3];
    return Row(
      children: options.map((val) {
        final isSelected = current == val;
        final label = val == null ? l10n.get('any_value') : (val == 3 ? '3+' : '$val');
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: InkWell(
              onTap: () => onChanged(val),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: isSelected ? AppThemes.primaryGreen : (Theme.of(context).brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[200]),
                  border: Border.all(color: isSelected ? AppThemes.primaryGreen : (Theme.of(context).brightness == Brightness.dark ? Colors.white24 : Colors.grey[300]!)),
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isSelected) 
                        const Padding(
                          padding: EdgeInsets.only(right: 4),
                          child: Icon(Icons.check, size: 14, color: Colors.white),
                        ),
                      Text(
                        label,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Colors.white : (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Theme.of(context).colorScheme.onSurface),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSwitchRow({required String label, required bool value, required ValueChanged<bool> onChanged}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label, 
              style: TextStyle(
                fontSize: 14, 
                color: isDark ? Colors.white70 : Theme.of(context).colorScheme.onSurface
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppThemes.primaryGreen,
          ),
        ],
      ),
    );
  }

  Widget _rangeInputs(String label, TextEditingController min, TextEditingController max, String unit) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subColor = isDark ? Colors.white70 : Colors.black54;
    final fieldBg = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[200];
    final textColor = isDark ? Colors.white : Colors.black87;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: subColor)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: min,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: textColor),
                  inputFormatters: label.toLowerCase().contains('precio') || label.toLowerCase().contains('price')
                      ? [CurrencyInputFormatter()]
                      : label.toLowerCase().contains('área') || label.toLowerCase().contains('area')
                          ? [DecimalInputFormatter()]
                          : [],
                  decoration: InputDecoration(
                    hintText: '${l10n.get('min_label')} $unit',
                    hintStyle: TextStyle(color: subColor.withValues(alpha: 0.5)),
                    filled: true,
                    fillColor: fieldBg,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('—', style: TextStyle(color: isDark ? Colors.white24 : Colors.grey[400])),
              ),
              Expanded(
                child: TextField(
                  controller: max,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: textColor),
                  inputFormatters: label.toLowerCase().contains('precio') || label.toLowerCase().contains('price')
                      ? [CurrencyInputFormatter()]
                      : label.toLowerCase().contains('área') || label.toLowerCase().contains('area')
                          ? [DecimalInputFormatter()]
                          : [],
                  decoration: InputDecoration(
                    hintText: '${l10n.get('max_label')} $unit',
                    hintStyle: TextStyle(color: subColor.withValues(alpha: 0.5)),
                    filled: true,
                    fillColor: fieldBg,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.selection.baseOffset == 0) return newValue;

    String cleanText = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanText.isEmpty) return newValue.copyWith(text: '');

    double value = double.parse(cleanText) / 100;
    final formatter = NumberFormat.currency(symbol: '', decimalDigits: 2);
    String newText = formatter.format(value).trim();

    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}

class DecimalInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;
    if (newValue.text == '.') return newValue;
    
    // Remove all non-numeric characters except first dot
    String cleanText = newValue.text.replaceAll(RegExp(r'[^\d.]'), '');
    int dotCount = '.'.allMatches(cleanText).length;
    if (dotCount > 1) return oldValue;
    
    // Split into integer and decimal parts
    final parts = cleanText.split('.');
    String integerPart = parts[0];
    String? decimalPart = parts.length > 1 ? parts[1] : null;

    // Format integer part with thousands separators
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
    }

    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
