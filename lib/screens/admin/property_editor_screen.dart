import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../services/supabase_service.dart';
import '../../models/property.dart';
import '../../services/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import '../../utils/image_utils.dart';
import '../../services/app_themes.dart';
import '../../data/location_data.dart';
import '../../providers/company_provider.dart';
import '../../services/geocoding_service.dart';
import '../../widgets/location_picker_dialog.dart';
import 'package:latlong2/latlong.dart';
import '../../widgets/property_history_widget.dart';

class PropertyEditorScreen extends StatefulWidget {
  final Property? property;
  const PropertyEditorScreen({super.key, this.property});

  @override
  State<PropertyEditorScreen> createState() => _PropertyEditorScreenState();
}

class _PropertyEditorScreenState extends State<PropertyEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = SupabaseService();
  
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _addressController;
  late TextEditingController _areaController;
  late TextEditingController _bathroomsController;
  late TextEditingController _parkingController;
  late TextEditingController _bedroomsController;
  late TextEditingController _floorsController;
  late TextEditingController _interiorLocationController;
  late TextEditingController _yearBuiltController;
  late TextEditingController _plotAreaController;
  late TextEditingController _adminCommissionController;

  String _type = 'Local';
  String _operationType = 'Alquiler';
  String _status = 'Disponible';
  String? _ownerId;
  bool _isPublic = true;
  bool _hasAirCon = false;
  bool _hasExtraStorage = false;
  bool _hasGarden = false;
  bool _isFurnished = false;
  bool _hasPool = false;
  bool _hasTerrace = false;
  bool _hasBalcony = false;
  bool _hasPatio = false;
  bool _hasGarage = false;
  bool _hasElevator = false;
  bool _hasSecurity = false;
  bool _isWaterfront = false;
  bool _hasSeaView = false;
  bool _hasBasement = false;
  bool _hasFittedKitchen = false;
  bool _hasTennisCourt = false;
  bool _hasPowerGenerator = false;
  bool _hasWaterTank = false;
  bool _hasGrill = false;
  bool _petsAllowed = true;
  bool _childrenAllowed = true;

  // Commercial / Delivery fields
  String? _deliveryStatus;
  bool _hasElectricity = false;
  bool _hasWaterConnections = false;
  bool _hasRestroomAccess = false;
  bool _hasAcConnection = false;
  String? _floorLevel;
  bool _hasStorageOfficeArea = false;
  String? _listingAgentId;
  List<Map<String, dynamic>> _agents = [];

  // Geolocation — Country/State/City
  String? _country;
  String? _state;
  String? _city;

  // Geolocation — Coordinates
  double? _latitude;
  double? _longitude;
  bool _isGeocodingAddress = false;
  
  List<Map<String, dynamic>> _owners = [];
  List<String> _galleryUrls = [];
  final _picker = ImagePicker();
  bool _isLoading = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    final companyProv = Provider.of<CompanyProvider>(context, listen: false);
    _titleController = TextEditingController(text: widget.property?.title);
    _descriptionController = TextEditingController(text: widget.property?.description);
    _priceController = TextEditingController(
      text: widget.property?.price != null 
          ? NumberFormat('#,###.00').format(widget.property!.price)
          : ''
    );
    _addressController = TextEditingController(text: widget.property?.address);
    _areaController = TextEditingController(
      text: widget.property?.details?.areaM2 != null 
          ? NumberFormat('#,###.##').format(widget.property!.details!.areaM2)
          : ''
    );
    _bathroomsController = TextEditingController(text: widget.property?.details?.bathrooms.toString());
    _parkingController = TextEditingController(text: widget.property?.details?.parkingSpaces.toString());
    _bedroomsController = TextEditingController(text: widget.property?.details?.bedrooms.toString());
    _floorsController = TextEditingController(text: widget.property?.details?.floors.toString());
    _interiorLocationController = TextEditingController(text: widget.property?.details?.interiorLocation);
    _yearBuiltController = TextEditingController(text: widget.property?.details?.yearBuilt?.toString());
    _plotAreaController = TextEditingController(
      text: widget.property?.details?.plotAreaM2 != null 
          ? NumberFormat('#,###.##').format(widget.property!.details!.plotAreaM2)
          : ''
    );
    _adminCommissionController = TextEditingController(
      text: widget.property?.adminCommissionPct != null 
          ? NumberFormat('#,###.##').format(widget.property!.adminCommissionPct!)
          : ''
    );
    
    if (widget.property != null) {
      _type = widget.property!.type;
      _operationType = widget.property!.operationType;
      _status = widget.property!.status;
      _ownerId = widget.property!.ownerId;
      _isPublic = widget.property!.isPublic;
      _hasAirCon = widget.property!.details?.hasAirCon ?? false;
      _hasExtraStorage = widget.property!.details?.hasExtraStorage ?? false;
      _hasGarden = widget.property!.details?.hasGarden ?? false;
      _isFurnished = widget.property!.details?.isFurnished ?? false;
      _hasPool = widget.property!.details?.hasPool ?? false;
      _hasTerrace = widget.property!.details?.hasTerrace ?? false;
      _hasBalcony = widget.property!.details?.hasBalcony ?? false;
      _hasPatio = widget.property!.details?.hasPatio ?? false;
      _hasGarage = widget.property!.details?.hasGarage ?? false;
      _hasElevator = widget.property!.details?.hasElevator ?? false;
      _hasSecurity = widget.property!.details?.hasSecurity ?? false;
      _isWaterfront = widget.property!.details?.isWaterfront ?? false;
      _hasSeaView = widget.property!.details?.hasSeaView ?? false;
      _hasBasement = widget.property!.details?.hasBasement ?? false;
      _hasFittedKitchen = widget.property!.details?.hasFittedKitchen ?? false;
      _hasTennisCourt = widget.property!.details?.hasTennisCourt ?? false;
      _hasPowerGenerator = widget.property!.details?.hasPowerGenerator ?? false;
      _hasWaterTank = widget.property!.details?.hasWaterTank ?? false;
      _hasGrill = widget.property!.details?.hasGrill ?? false;
      _petsAllowed = widget.property!.details?.petsAllowed ?? true;
      _childrenAllowed = widget.property!.details?.childrenAllowed ?? true;
      _galleryUrls = List<String>.from(widget.property!.imageUrls);
      _country = widget.property!.country ?? companyProv.country;
      _state = widget.property!.state ?? companyProv.state;
      _city = widget.property!.city;
      _latitude = widget.property!.latitude;
      _longitude = widget.property!.longitude;
      _deliveryStatus = widget.property!.details?.deliveryStatus;
      _hasElectricity = widget.property!.details?.hasElectricity ?? false;
      _hasWaterConnections = widget.property!.details?.hasWaterConnections ?? false;
      _hasRestroomAccess = widget.property!.details?.hasRestroomAccess ?? false;
      _hasAcConnection = widget.property!.details?.hasAcConnection ?? false;
      _floorLevel = widget.property!.details?.floorLevel;
      _hasStorageOfficeArea = widget.property!.details?.hasStorageOfficeArea ?? false;
      _listingAgentId = widget.property!.listingAgentId;
    } else {
      _country = companyProv.country;
      _state = companyProv.state;
      _listingAgentId = _service.currentUser?.id;
    }
    
    _loadOwners();
    _loadAgents();
  }

  @override
  void dispose() {
    _adminCommissionController.dispose();
    super.dispose();
  }

  Future<void> _loadOwners() async {
    final companyId = Provider.of<CompanyProvider>(context, listen: false).companyId;
    final owners = await _service.getOwners(companyId);
    setState(() => _owners = owners);
  }

  Future<void> _loadAgents() async {
    // Priority: 1. Property's company, 2. Current selected company, 3. Null (Super Admin default)
    final String? companyId = widget.property?.companyId ?? Provider.of<CompanyProvider>(context, listen: false).companyId;
    
    debugPrint('[PropertyEditor] Loading agents for companyId: $companyId');
    
    if (companyId == null) {
      debugPrint('[PropertyEditor] No companyId available for agent loading (Super Admin global mode?)');
      // For Super Admins with no company context, we could fetch all agents, 
      // but for now let's just avoid resetting if possible.
      return;
    }

    final agents = await _service.getCompanyUsers(companyId);
    setState(() {
      _agents = agents;
      final agentIds = agents.map((e) => e['id'] as String).toSet();
      
      // If the current agent is not in the list, but it's not null, 
      // we only reset it if we are sure it SHOULD be in this list.
      if (_listingAgentId != null && !agentIds.contains(_listingAgentId)) {
        debugPrint('[PropertyEditor] _listingAgentId=$_listingAgentId not found in agents of company=$companyId — resetting to null');
        _listingAgentId = null;
      }
    });
  }

  Future<void> _geocodeAddress() async {
    if (_addressController.text.isEmpty) return;
    
    setState(() => _isGeocodingAddress = true);
    final l10n = AppLocalizations.of(context);
    
    try {
      final query = '${_addressController.text}, ${_city ?? ""}, ${_state ?? ""}, ${_country ?? ""}';
      final result = await GeocodingService.searchAddress(query);
      
      if (result != null && mounted) {
        setState(() {
          _latitude = result.latitude;
          _longitude = result.longitude;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Icon(Icons.check_circle, color: Colors.white)),
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.get('location_not_found').replaceAll('{0}', _addressController.text))),
          );
        }
      }
    } catch (e) {
      debugPrint('Geocoding error: $e');
    } finally {
      if (mounted) setState(() => _isGeocodingAddress = false);
    }
  }

  Future<void> _openMapPicker() async {
    final initialLoc = (_latitude != null && _longitude != null) 
        ? LatLng(_latitude!, _longitude!)
        : const LatLng(10.4806, -66.9036); // Caracas default if null

    final result = await showDialog<LatLng>(
      context: context,
      builder: (_) => LocationPickerDialog(
        initialLat: _latitude,
        initialLng: _longitude,
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _latitude = result.latitude;
        _longitude = result.longitude;
      });
    }
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    try {
      final price = double.tryParse(_priceController.text.replaceAll(',', '')) ?? 0.0;
      final area = double.tryParse(_areaController.text.replaceAll(',', '')) ?? 0.0;
      final bathrooms = int.tryParse(_bathroomsController.text) ?? 0;
      final parking = int.tryParse(_parkingController.text) ?? 0;
      final bedrooms = int.tryParse(_bedroomsController.text) ?? 0;
      final floors = int.tryParse(_floorsController.text) ?? 1;
      final yearBuilt = int.tryParse(_yearBuiltController.text);
      final plotArea = double.tryParse(_plotAreaController.text.replaceAll(',', ''));

      if (_ownerId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.get('owner_required'))),
          );
        }
        return;
      }

      final companyId = Provider.of<CompanyProvider>(context, listen: false).companyId;
      
      // Preserve existing company_id if editing as a super_admin to avoid 
      // accidentally nullifying the property's company association.
      final targetCompanyId = widget.property?.companyId ?? companyId;

      final propertyData = {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'price': price,
        'address': _addressController.text,
        'type': _type,
        'operation_type': _operationType,
        'status': _status,
        'owner_id': _ownerId,
        'is_public': _isPublic,
        'country': _country,
        'state': _state,
        'city': _city,
        'company_id': targetCompanyId,
        'latitude': _latitude,
        'longitude': _longitude,
        'admin_commission_pct': double.tryParse(_adminCommissionController.text.replaceAll(',', '')),
        'listing_agent_id': _listingAgentId,
      };

      debugPrint('[PropertyEditor] DATA PRE-SAVE:');
      debugPrint('  - Title: ${propertyData['title']}');
      debugPrint('  - Address: ${propertyData['address']}');
      debugPrint('  - Price: ${propertyData['price']}');
      debugPrint('  - AgentID: ${propertyData['listing_agent_id']}');
      debugPrint('  - CompanyID: ${propertyData['company_id']}');

      final detailsData = {
        'area_m2': area,
        'bathrooms': bathrooms,
        'parking_spaces': parking,
        'has_air_con': _hasAirCon,
        'has_extra_storage': _hasExtraStorage,
        'bedrooms': bedrooms,
        'floors': floors,
        'has_garden': _hasGarden,
        'is_furnished': _isFurnished,
        'interior_location': _interiorLocationController.text,
        'year_built': yearBuilt,
        'plot_area_m2': plotArea,
        'has_pool': _hasPool,
        'has_terrace': _hasTerrace,
        'has_balcony': _hasBalcony,
        'has_patio': _hasPatio,
        'has_garage': _hasGarage,
        'has_elevator': _hasElevator,
        'has_security': _hasSecurity,
        'is_waterfront': _isWaterfront,
        'has_sea_view': _hasSeaView,
        'has_basement': _hasBasement,
        'has_fitted_kitchen': _hasFittedKitchen,
        'has_tennis_court': _hasTennisCourt,
        'has_power_generator': _hasPowerGenerator,
        'has_water_tank': _hasWaterTank,
        'has_grill': _hasGrill,
        'pets_allowed': _petsAllowed,
        'children_allowed': _childrenAllowed,
        'delivery_status': _deliveryStatus,
        'has_electricity': _hasElectricity,
        'has_water_connections': _hasWaterConnections,
        'has_restroom_access': _hasRestroomAccess,
        'has_ac_connection': _hasAcConnection,
        'floor_level': _floorLevel,
        'has_storage_office_area': _hasStorageOfficeArea,
      };

      if (widget.property == null) {
        await _service.createProperty(propertyData, detailsData);
      } else {
        await _service.updateProperty(widget.property!.id, propertyData, detailsData);
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.get('save_error') + e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAndUploadImage() async {
    final l10n = AppLocalizations.of(context);
    if (widget.property == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.get('save_first'))),
      );
      return;
    }

    final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    setState(() => _isUploading = true);
    try {
      final bytes = await file.readAsBytes();
      final compressed = await ImageUtils.compressImage(bytes);
      
      final fileName = 'prop_${widget.property!.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = 'properties/${widget.property!.id}/$fileName';
      
      final url = await _service.uploadPropertyImage(path, compressed);
      await _service.savePropertyGallery(widget.property!.id, url, _galleryUrls.isEmpty);
      
      setState(() {
        _galleryUrls.add(url);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.get('error_generic') + e.toString())));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _deleteImage(String url) async {
    setState(() => _isLoading = true);
    try {
      await _service.deleteGalleryImage(widget.property!.id, url);
      setState(() {
        _galleryUrls.remove(url);
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _setMainImage(String url) async {
    setState(() => _isLoading = true);
    try {
      await _service.setMainGalleryImage(widget.property!.id, url);
      setState(() {
         final index = _galleryUrls.indexOf(url);
         if (index != -1) {
           final item = _galleryUrls.removeAt(index);
           _galleryUrls.insert(0, item);
         }
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildFeatureSwitch(String label, bool value, Function(bool) onChanged) {
    return SizedBox(
      width: 200,
      child: SwitchListTile(
        title: Text(label, style: const TextStyle(fontSize: 14)),
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isSpanish = l10n.locale.languageCode == 'es';
    final companyProv = Provider.of<CompanyProvider>(context);
    final company = companyProv.company;

    return DefaultTabController(
      length: widget.property == null ? 1 : 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.property == null ? l10n.get('add_property') : l10n.get('edit')),
          actions: [
            if (_isLoading)
              const Center(child: CircularProgressIndicator(color: Colors.white))
            else
              IconButton(icon: const Icon(Icons.check), onPressed: _save),
          ],
          bottom: widget.property == null 
            ? null 
            : TabBar(
                tabs: [
                  Tab(text: isSpanish ? 'Datos' : 'Details'),
                  Tab(text: isSpanish ? 'Historial' : 'History'),
                ],
              ),
        ),
        body: widget.property == null 
          ? _buildForm(l10n, isSpanish, companyProv, company)
          : TabBarView(
              children: [
                _buildForm(l10n, isSpanish, companyProv, company),
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: PropertyHistoryWidget(propertyId: widget.property!.id),
                ),
              ],
            ),
      ),
    );
  }

  Widget _buildForm(AppLocalizations l10n, bool isSpanish, CompanyProvider companyProv, dynamic company) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(labelText: l10n.get('title_field')),
                validator: (v) => v!.isEmpty ? l10n.get('required') : null,
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: l10n.get('description_field')),
                maxLines: 3,
              ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      decoration: InputDecoration(labelText: '${l10n.get('price_field')} (${companyProv.currencySymbol})'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [CurrencyInputFormatter()],
                      validator: (v) => (v == null || v.isEmpty) ? l10n.get('required') : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      // Rule #14: Guard against missing values in hardcoded list
                      value: [
                        'Casa', 'Apartamento', 'Dúplex', 'Ático', 'Townhouse', 'Loft', 'Estudio',
                        'Casa vacacional', 'Apartamento vacacional', 'Local', 'Oficina', 'Almacén',
                        'Galpon', 'Tienda', 'Terreno', 'Posada', 'Hotel', 'Patio Industrial',
                        'Agricultura y bosques', 'Centro Comercial', 'Otro'
                      ].contains(_type) ? _type : null,
                      decoration: InputDecoration(labelText: l10n.get('type_field')),
                      items: [
                        DropdownMenuItem(value: 'Casa', child: Text(l10n.get('Casa'))),
                        DropdownMenuItem(value: 'Apartamento', child: Text(l10n.get('Apartamento'))),
                        DropdownMenuItem(value: 'Dúplex', child: Text(l10n.get('Dúplex'))),
                        DropdownMenuItem(value: 'Ático', child: Text(l10n.get('Ático'))),
                        DropdownMenuItem(value: 'Townhouse', child: Text(l10n.get('Townhouse'))),
                        DropdownMenuItem(value: 'Loft', child: Text(l10n.get('Loft'))),
                        DropdownMenuItem(value: 'Estudio', child: Text(l10n.get('Estudio'))),
                        DropdownMenuItem(value: 'Casa vacacional', child: Text(l10n.get('Casa vacacional'))),
                        DropdownMenuItem(value: 'Apartamento vacacional', child: Text(l10n.get('Apartamento vacacional'))),
                        DropdownMenuItem(value: 'Local', child: Text(l10n.get('Local'))),
                        DropdownMenuItem(value: 'Oficina', child: Text(l10n.get('Oficina'))),
                        DropdownMenuItem(value: 'Almacén', child: Text(l10n.get('Almacén'))),
                        DropdownMenuItem(value: 'Galpon', child: Text(l10n.get('Galpon'))),
                        DropdownMenuItem(value: 'Tienda', child: Text(l10n.get('Tienda'))),
                        DropdownMenuItem(value: 'Terreno', child: Text(l10n.get('Terreno'))),
                        DropdownMenuItem(value: 'Posada', child: Text(l10n.get('Posada'))),
                        DropdownMenuItem(value: 'Hotel', child: Text(l10n.get('Hotel'))),
                        DropdownMenuItem(value: 'Patio Industrial', child: Text(l10n.get('Patio Industrial'))),
                        DropdownMenuItem(value: 'Agricultura y bosques', child: Text(l10n.get('Agricultura y bosques'))),
                        DropdownMenuItem(value: 'Centro Comercial', child: Text(l10n.get('Centro Comercial'))),
                        DropdownMenuItem(value: 'Otro', child: Text(l10n.get('Otro'))),
                      ],
                      onChanged: (v) => setState(() => _type = v!),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(labelText: l10n.get('address_field')),
                validator: (v) => (v == null || v.isEmpty) ? l10n.get('required') : null,
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l10n.get('location_section'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _country,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: l10n.get('country_field'),
                  prefixIcon: const Icon(Icons.flag_outlined),
                ),
                hint: Text(l10n.get('geo_select_country')),
                items: LocationData.countries
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _country = v),
                validator: (v) => v == null ? l10n.get('required') : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _state,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: l10n.get('state_field'),
                  prefixIcon: const Icon(Icons.map_outlined),
                ),
                hint: Text(l10n.get('geo_select_state')),
                items: (_country == null ? <String>[] : LocationData.statesFor(_country!))
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: _country == null ? null : (v) => setState(() {
                  _state = v;
                  _city = null;
                }),
                validator: (v) => v == null ? l10n.get('required') : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _city,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: l10n.get('city_field'),
                  prefixIcon: const Icon(Icons.location_city_outlined),
                ),
                items: () {
                  final items = (_country == null || _state == null ? <String>[] : LocationData.citiesFor(_country!, _state!));
                  if (_city != null && !items.contains(_city)) {
                    items.add(_city!);
                  }
                  return items.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList();
                }(),
                onChanged: (_country == null || _state == null) ? null : (v) => setState(() => _city = v),
                validator: (v) => v == null ? l10n.get('required') : null,
              ),
              const SizedBox(height: 16),
              // ── GEOLOCATION SECTION ───────────────────────────────────
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 20, color: AppThemes.primaryGreen),
                        const SizedBox(width: 8),
                        Text(
                          l10n.get('assign_on_map'),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.get('coordinates_field'),
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                (_latitude != null && _longitude != null)
                                    ? '${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}'
                                    : l10n.get('loc_not_specified'),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: (_latitude != null) ? null : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_isGeocodingAddress)
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                          )
                        else
                          IconButton(
                            onPressed: _geocodeAddress,
                            icon: const Icon(Icons.auto_fix_high),
                            tooltip: l10n.get('geocode_address'),
                            color: AppThemes.primaryGreen,
                          ),
                        ElevatedButton.icon(
                          onPressed: _openMapPicker,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppThemes.primaryGreen,
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.map, size: 18),
                          label: Text(l10n.get('assign_on_map')),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.get('gallery'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(
                        '${_galleryUrls.length} / ${company.totalAllowedPhotosPerProperty}',
                        style: TextStyle(
                          fontSize: 12, 
                          color: _galleryUrls.length >= company.totalAllowedPhotosPerProperty ? Colors.orange : Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (_isUploading)
                    const CircularProgressIndicator(strokeWidth: 2)
                  else
                    TextButton.icon(
                      onPressed: _galleryUrls.length >= company.totalAllowedPhotosPerProperty
                        ? () => ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(l10n.get('photo_limit_reached') ?? 'Límite de fotos alcanzado'),
                              backgroundColor: Colors.orange,
                            )
                          )
                        : _pickAndUploadImage, 
                      icon: Icon(
                        _galleryUrls.length >= company.totalAllowedPhotosPerProperty ? Icons.lock_outline : Icons.add_a_photo,
                        color: _galleryUrls.length >= company.totalAllowedPhotosPerProperty ? Colors.grey : null,
                      ), 
                      label: Text(
                        l10n.get('add_image'),
                        style: TextStyle(color: _galleryUrls.length >= company.totalAllowedPhotosPerProperty ? Colors.grey : null),
                      )
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (_galleryUrls.isEmpty)
                Container(
                  height: 100,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(child: Text(l10n.get('no_results'), style: const TextStyle(color: Colors.grey))),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                  ),
                  itemCount: _galleryUrls.length,
                  itemBuilder: (context, index) {
                    final url = _galleryUrls[index];
                    final isMain = index == 0;
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.network(url, width: double.infinity, height: double.infinity, fit: BoxFit.cover),
                        ),
                        if (isMain)
                          Positioned(
                            top: 2, left: 2,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                              decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(2)),
                              child: Text(l10n.get('main_photo'), style: const TextStyle(color: Colors.white, fontSize: 8)),
                            ),
                          ),
                        Positioned(
                          right: -10, top: -10,
                          child: PopupMenuButton<String>(
                            onSelected: (val) async {
                              if (val == 'delete') {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: Text(l10n.get('delete')),
                                    content: Text(l10n.get('delete_confirm')),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.get('cancel'))),
                                      TextButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.get('delete'), style: const TextStyle(color: Colors.red))),
                                    ],
                                  ),
                                );
                                if (confirm == true) _deleteImage(url);
                              }
                              if (val == 'main') _setMainImage(url);
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(value: 'main', child: Text(l10n.get('set_main'))),
                              PopupMenuItem(value: 'delete', child: Text(l10n.get('delete_image'), style: const TextStyle(color: Colors.red))),
                            ],
                            icon: const Icon(Icons.more_vert, color: Colors.white, size: 16),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              const Divider(height: 32),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _operationType,
                      decoration: InputDecoration(labelText: l10n.get('operation_field')),
                      items: [
                        DropdownMenuItem(value: 'Venta', child: Text(l10n.get('op_sale'))),
                        DropdownMenuItem(value: 'Alquiler', child: Text(l10n.get('op_rent'))),
                      ],
                      onChanged: (v) => setState(() => _operationType = v!),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _status,
                      decoration: InputDecoration(labelText: l10n.get('status_field')),
                      items: [
                        DropdownMenuItem(value: 'Disponible', child: Text(l10n.get('st_available'))),
                        DropdownMenuItem(value: 'Reservado', child: Text(l10n.get('st_reserved'))),
                        DropdownMenuItem(value: 'Vendido', child: Text(l10n.get('st_sold'))),
                      ],
                      onChanged: (v) => setState(() => _status = v!),
                    ),
                  ),
                ],
              ),
              DropdownButtonFormField<String>(
                value: _ownerId,
                decoration: InputDecoration(labelText: l10n.get('owner_field')),
                items: _owners.map((e) => DropdownMenuItem(value: e['id'] as String, child: Text(e['full_name'] as String))).toList(),
                onChanged: (v) => setState(() => _ownerId = v),
                validator: (v) => v == null ? l10n.get('required') : null,
              ),
              SwitchListTile(
                title: Text(l10n.get('public_field')),
                value: _isPublic,
                onChanged: (v) => setState(() => _isPublic = v),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                // Guard: only bind the value when it exists in the loaded items
                // list. Before agents load (async), items is empty and Flutter
                // would silently treat a non-null value as null, corrupting the
                // field on validate/save.
                value: _agents.any((e) => e['id'] == _listingAgentId)
                    ? _listingAgentId
                    : null,
                decoration: InputDecoration(
                  labelText: isSpanish ? 'Agente Captador' : 'Listing Agent',
                  prefixIcon: const Icon(Icons.person_pin_outlined),
                  hintText: _agents.isEmpty
                      ? (isSpanish ? 'Cargando agentes...' : 'Loading agents...')
                      : (isSpanish ? 'Seleccionar agente (opcional)' : 'Select agent (optional)'),
                ),
                items: _agents
                    .map((e) => DropdownMenuItem(
                          value: e['id'] as String,
                          child: Text(e['full_name'] as String),
                        ))
                    .toList(),
                onChanged: _agents.isEmpty
                    ? null
                    : (v) => setState(() => _listingAgentId = v),
                // Field is optional — a property can exist without an assigned agent.
                // The required validator was the root cause of silent null saves:
                // if agents hadn't loaded yet the validator received null and
                // blocked save without a visible error (form scrolled away).
              ),
              const Divider(height: 32),
              /* TextFormField(
                controller: _interiorLocationController,
                decoration: InputDecoration(
                  labelText: l10n.get('interior_location_field'),
                  hintText: l10n.get('interior_location_hint'),
                ),
              ), */
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _areaController,
                      decoration: InputDecoration(labelText: '${l10n.get('area_field')} (${companyProv.areaUnit})'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [DecimalInputFormatter()],
                    ),
                  ),
                  const SizedBox(width: 16),
                    Expanded(
                        child: TextFormField(
                        controller: _bathroomsController,
                        decoration: InputDecoration(labelText: l10n.get('bathrooms_field')),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [DecimalInputFormatter()],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _yearBuiltController,
                        decoration: InputDecoration(
                          labelText: l10n.get('year_built_field'),
                          hintText: 'YYYY',
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _parkingController,
                        decoration: InputDecoration(labelText: l10n.get('parking_field')),
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Divider(),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    l10n.get('commercial'),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: _deliveryStatus ?? 'listo_para_ocupar',
                        decoration: InputDecoration(
                          labelText: l10n.get('delivery_status_field'),
                          isDense: true,
                        ),
                        items: [
                          DropdownMenuItem(value: 'obra_gris', child: Text(l10n.get('obra_gris'), overflow: TextOverflow.ellipsis)),
                          DropdownMenuItem(value: 'semi_acabado', child: Text(l10n.get('semi_acabado'), overflow: TextOverflow.ellipsis)),
                          DropdownMenuItem(value: 'listo_para_ocupar', child: Text(l10n.get('listo_para_ocupar'), overflow: TextOverflow.ellipsis)),
                        ],
                        onChanged: (v) => setState(() => _deliveryStatus = v),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: _floorLevel ?? 'incluido_en_direccion',
                        decoration: InputDecoration(
                          labelText: l10n.get('floor_level_field'),
                          isDense: true,
                        ),
                        items: [
                          DropdownMenuItem(value: 'incluido_en_direccion', child: Text(l10n.get('incluido_en_direccion'), overflow: TextOverflow.ellipsis)),
                          DropdownMenuItem(value: 'planta_baja', child: Text(l10n.get('planta_baja'), overflow: TextOverflow.ellipsis)),
                          DropdownMenuItem(value: 'mezzanina', child: Text(l10n.get('mezzanina'), overflow: TextOverflow.ellipsis)),
                          DropdownMenuItem(value: 'primer_piso', child: Text(l10n.get('primer_piso'), overflow: TextOverflow.ellipsis)),
                          DropdownMenuItem(value: 'segundo_piso', child: Text(l10n.get('segundo_piso'), overflow: TextOverflow.ellipsis)),
                          DropdownMenuItem(value: 'tercer_piso', child: Text(l10n.get('tercer_piso'), overflow: TextOverflow.ellipsis)),
                          DropdownMenuItem(value: 'cuarto_piso', child: Text(l10n.get('cuarto_piso'), overflow: TextOverflow.ellipsis)),
                        ],
                        onChanged: (v) => setState(() => _floorLevel = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const SizedBox(height: 16),
                /* Wrap(
                  spacing: 16,
                  children: [
                    _buildFeatureSwitch(l10n.get('has_electricity_field'), _hasElectricity, (v) => setState(() => _hasElectricity = v)),
                    _buildFeatureSwitch(l10n.get('has_water_connections_field'), _hasWaterConnections, (v) => setState(() => _hasWaterConnections = v)),
                    _buildFeatureSwitch(l10n.get('has_restroom_access_field'), _hasRestroomAccess, (v) => setState(() => _hasRestroomAccess = v)),
                    _buildFeatureSwitch(l10n.get('has_ac_connection_field'), _hasAcConnection, (v) => setState(() => _hasAcConnection = v)),
                    if (['Local', 'Oficina', 'Almacén', 'Galpon', 'Tienda', 'Centro Comercial'].contains(_type))
                      _buildFeatureSwitch(l10n.get('has_storage_office_area_field'), _hasStorageOfficeArea, (v) => setState(() => _hasStorageOfficeArea = v)),
                  ],
                ), */
              if (['Casa', 'Apartamento', 'Loft', 'Estudio', 'Terreno', 'Casa vacacional', 'Apartamento vacacional'].contains(_type))
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Column(
                    children: [
                      if (_type != 'Terreno')
                        TextFormField(
                          controller: _bedroomsController,
                          decoration: InputDecoration(labelText: l10n.get('bedrooms_field')),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        ),
                      if (_type == 'Casa') ...[
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _floorsController,
                          decoration: InputDecoration(labelText: l10n.get('floors_field')),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        ),
                      ],
                      if (_type == 'Terreno' || _type == 'Casa') ...[
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _plotAreaController,
                          decoration: InputDecoration(labelText: l10n.get('plot_area_field')),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [DecimalInputFormatter()],
                        ),
                      ],
                      const SizedBox(height: 16),
                      const SizedBox(height: 16),

                    ],
                  ),
                ),
              const SizedBox(height: 16),
              Text(l10n.get('additional_features'), style: const TextStyle(fontWeight: FontWeight.bold)),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                   // --- Residential Only ---
                  if (['Casa', 'Apartamento', 'Loft', 'Estudio', 'Casa vacacional', 'Apartamento vacacional'].contains(_type)) ...[
                    SizedBox(
                      width: 200,
                      child: SwitchListTile(
                        title: Text(l10n.get('pool_field'), style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface)),
                        value: _hasPool,
                        onChanged: (v) => setState(() => _hasPool = v),
                      ),
                    ),
                    SizedBox(
                      width: 200,
                      child: SwitchListTile(
                        title: Text(l10n.get('patio_field'), style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface)),
                        value: _hasPatio,
                        onChanged: (v) => setState(() => _hasPatio = v),
                      ),
                    ),
                    SizedBox(
                      width: 200,
                      child: SwitchListTile(
                        title: Text(l10n.get('fitted_kitchen_field'), style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface)),
                        value: _hasFittedKitchen,
                        onChanged: (v) => setState(() => _hasFittedKitchen = v),
                      ),
                    ),
                  ],

                  // --- Commercial Only ---
                  if (!['Casa', 'Apartamento', 'Loft', 'Estudio', 'Casa vacacional', 'Apartamento vacacional'].contains(_type)) ...[
                    SizedBox(
                      width: 200,
                      child: SwitchListTile(
                        title: Text(l10n.get('elevator_field'), style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface)),
                        value: _hasElevator,
                        onChanged: (v) => setState(() => _hasElevator = v),
                      ),
                    ),
                    SizedBox(
                      width: 200,
                      child: SwitchListTile(
                        title: Text(l10n.get('storage_field'), style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface)),
                        value: _hasExtraStorage,
                        onChanged: (v) => setState(() => _hasExtraStorage = v),
                      ),
                    ),
                  ],

                  // --- Utilities (Both) ---
                  SizedBox(
                    width: 200,
                    child: SwitchListTile(
                      title: Text(l10n.get('power_generator_field'), style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface)),
                      value: _hasPowerGenerator,
                      onChanged: (v) => setState(() => _hasPowerGenerator = v),
                    ),
                  ),
                  SizedBox(
                    width: 200,
                    child: SwitchListTile(
                      title: Text(l10n.get('water_tank_field'), style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface)),
                      value: _hasWaterTank,
                      onChanged: (v) => setState(() => _hasWaterTank = v),
                    ),
                  ),
                  SizedBox(
                    width: 200,
                    child: SwitchListTile(
                      title: Text(l10n.get('grill_field'), style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface)),
                      value: _hasGrill,
                      onChanged: (v) => setState(() => _hasGrill = v),
                    ),
                  ),

                  // --- Common ---
                  SizedBox(
                    width: 200,
                    child: SwitchListTile(
                      title: Text(l10n.get('terrace_field'), style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface)),
                      value: _hasTerrace,
                      onChanged: (v) => setState(() => _hasTerrace = v),
                    ),
                  ),
                  SizedBox(
                    width: 200,
                    child: SwitchListTile(
                      title: Text(l10n.get('balcony_field'), style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface)),
                      value: _hasBalcony,
                      onChanged: (v) => setState(() => _hasBalcony = v),
                    ),
                  ),
                  SizedBox(
                    width: 200,
                    child: SwitchListTile(
                      title: Text(l10n.get('garage_field'), style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface)),
                      value: _hasGarage,
                      onChanged: (v) => setState(() => _hasGarage = v),
                    ),
                  ),
                  SizedBox(
                    width: 200,
                    child: SwitchListTile(
                      title: Text(l10n.get('security_field'), style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface)),
                      value: _hasSecurity,
                      onChanged: (v) => setState(() => _hasSecurity = v),
                    ),
                  ),
                  SizedBox(
                    width: 200,
                    child: SwitchListTile(
                      title: Text(l10n.get('waterfront_field'), style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface)),
                      value: _isWaterfront,
                      onChanged: (v) => setState(() => _isWaterfront = v),
                    ),
                  ),
                  SizedBox(
                    width: 200,
                    child: SwitchListTile(
                      title: Text(l10n.get('seaview_field'), style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface)),
                      value: _hasSeaView,
                      onChanged: (v) => setState(() => _hasSeaView = v),
                    ),
                  ),
                  SizedBox(
                    width: 200,
                    child: SwitchListTile(
                      title: Text(l10n.get('basement_field'), style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface)),
                      value: _hasBasement,
                      onChanged: (v) => setState(() => _hasBasement = v),
                    ),
                  ),
                   SizedBox(
                    width: 200,
                    child: SwitchListTile(
                      title: Text(l10n.get('garden_field'), style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface)),
                      value: _hasGarden,
                      onChanged: (v) => setState(() => _hasGarden = v),
                    ),
                  ),
                  SizedBox(
                    width: 200,
                    child: SwitchListTile(
                      title: Text(l10n.get('furnished_field'), style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface)),
                      value: _isFurnished,
                      onChanged: (v) => setState(() => _isFurnished = v),
                    ),
                  ),

                  // --- Operation Rules ---
                  if (_operationType == 'Alquiler') ...[
                    _buildFeatureSwitch(l10n.get('pets_allowed_field'), _petsAllowed, (v) => setState(() => _petsAllowed = v)),
                    _buildFeatureSwitch(l10n.get('children_allowed_field'), _childrenAllowed, (v) => setState(() => _childrenAllowed = v)),
                  ],

                  // --- Commercial Infrastructure ---
                  _buildFeatureSwitch(l10n.get('has_electricity_field'), _hasElectricity, (v) => setState(() => _hasElectricity = v)),
                  _buildFeatureSwitch(l10n.get('has_water_connections_field'), _hasWaterConnections, (v) => setState(() => _hasWaterConnections = v)),
                  _buildFeatureSwitch(l10n.get('has_restroom_access_field'), _hasRestroomAccess, (v) => setState(() => _hasRestroomAccess = v)),
                  _buildFeatureSwitch(l10n.get('has_ac_connection_field'), _hasAcConnection, (v) => setState(() => _hasAcConnection = v)),
                  if (['Local', 'Oficina', 'Almacén', 'Galpon', 'Tienda', 'Centro Comercial'].contains(_type))
                    _buildFeatureSwitch(l10n.get('has_storage_office_area_field'), _hasStorageOfficeArea, (v) => setState(() => _hasStorageOfficeArea = v)),

                ],
              ),
              if (_operationType == 'Alquiler') ...[
                const Divider(height: 32),
                TextFormField(
                  controller: _adminCommissionController,
                  decoration: InputDecoration(
                    labelText: isSpanish ? 'Comisión por gestión de cobro (%)' : 'Collection management commission (%)',
                    hintText: '${isSpanish ? "Por defecto" : "Default"}: ${NumberFormat('#,###.##').format(companyProv.company.defaultAdminCommissionPct)}%',
                    suffixText: '%',
                    helperText: isSpanish 
                      ? 'Deja vacío para usar el valor por defecto de la agencia' 
                      : 'Leave empty to use company default value',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [DecimalInputFormatter()],
                ),
              ],
            ],
          ),
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
