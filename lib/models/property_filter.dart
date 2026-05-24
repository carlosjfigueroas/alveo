import 'property.dart';

/// Holds all the filter criteria for the property list.
class PropertyFilter {
  // Operation type: null = both, 'Venta', 'Alquiler'
  String? operationType;
  
  // Category: 'Residential' or 'Commercial'
  String? category;

  // Property types (multi-select)
  Set<String> types;

  // Availability statuses (multi-select)
  Set<String> statuses;

  // Owners (multi-select): list of owner UUIDs
  Set<String> ownerIds;

  // Price range
  double? minPrice;
  double? maxPrice;

  // Area range (m2)
  double? minArea;
  double? maxArea;

  // Details
  int? minBathrooms;
  int? minParkingSpaces;

  bool? hasAirCon;
  bool? hasExtraStorage;
  bool? hasPool;
  bool? hasTerrace;
  bool? hasBalcony;
  bool? hasPatio;
  bool? hasGarage;
  bool? hasElevator;
  bool? hasSecurity;
  bool? isWaterfront;
  bool? hasSeaView;
  bool? hasBasement;
  bool? hasFittedKitchen;
  bool? hasTennisCourt;
  bool? hasGarden;
  bool? isFurnished;
  bool? hasPowerGenerator;
  bool? hasWaterTank;
  bool? hasGrill;
  bool? petsAllowed;
  bool? childrenAllowed;

  // New features
  String? deliveryStatus;
  bool? hasElectricity;
  bool? hasWaterConnections;
  bool? hasRestroomAccess;
  bool? hasAcConnection;
  String? floorLevel;
  bool? hasStorageOfficeArea;

  int? minYear;
  int? maxYear;
  double? minPlotArea;
  double? maxPlotArea;

  // Geolocation (hierarchical dropdowns)
  String? country;
  String? state;
  String? city;
  String? address; // Partial address search (sector, street, etc.)

  // Social
  int? minLikes;

  PropertyFilter({
    this.operationType,
    this.category,
    Set<String>? types,
    Set<String>? statuses,
    Set<String>? ownerIds,
    this.minPrice,
    this.maxPrice,
    this.minArea,
    this.maxArea,
    this.minBathrooms,
    this.minParkingSpaces,
    this.hasAirCon,
    this.hasExtraStorage,
    this.hasPool,
    this.hasTerrace,
    this.hasBalcony,
    this.hasPatio,
    this.hasGarage,
    this.hasElevator,
    this.hasSecurity,
    this.isWaterfront,
    this.hasSeaView,
    this.hasBasement,
    this.hasFittedKitchen,
    this.hasTennisCourt,
    this.hasGarden,
    this.isFurnished,
    this.minYear,
    this.maxYear,
    this.minPlotArea,
    this.maxPlotArea,
    this.country,
    this.state,
    this.city,
    this.address,
    this.minLikes,
    this.hasPowerGenerator,
    this.hasWaterTank,
    this.hasGrill,
    this.petsAllowed,
    this.childrenAllowed,
    this.deliveryStatus,
    this.hasElectricity,
    this.hasWaterConnections,
    this.hasRestroomAccess,
    this.hasAcConnection,
    this.floorLevel,
    this.hasStorageOfficeArea,
  })  : types = types ?? {},
        statuses = statuses ?? {},
        ownerIds = ownerIds ?? {};

  PropertyFilter copyWith({
    Object? operationType = _sentinel,
    Object? category = _sentinel,
    Set<String>? types,
    Set<String>? statuses,
    Set<String>? ownerIds,
    Object? minPrice = _sentinel,
    Object? maxPrice = _sentinel,
    Object? minArea = _sentinel,
    Object? maxArea = _sentinel,
    Object? minBathrooms = _sentinel,
    Object? minParkingSpaces = _sentinel,
    Object? hasAirCon = _sentinel,
    Object? hasExtraStorage = _sentinel,
    Object? hasPool = _sentinel,
    Object? hasTerrace = _sentinel,
    Object? hasBalcony = _sentinel,
    Object? hasPatio = _sentinel,
    Object? hasGarage = _sentinel,
    Object? hasElevator = _sentinel,
    Object? hasSecurity = _sentinel,
    Object? isWaterfront = _sentinel,
    Object? hasSeaView = _sentinel,
    Object? hasBasement = _sentinel,
    Object? hasFittedKitchen = _sentinel,
    Object? hasTennisCourt = _sentinel,
    Object? hasGarden = _sentinel,
    Object? isFurnished = _sentinel,
    Object? minYear = _sentinel,
    Object? maxYear = _sentinel,
    Object? minPlotArea = _sentinel,
    Object? maxPlotArea = _sentinel,
    Object? country = _sentinel,
    Object? state = _sentinel,
    Object? city = _sentinel,
    Object? minLikes = _sentinel,
    Object? hasPowerGenerator = _sentinel,
    Object? hasWaterTank = _sentinel,
    Object? hasGrill = _sentinel,
    Object? petsAllowed = _sentinel,
    Object? childrenAllowed = _sentinel,
    Object? deliveryStatus = _sentinel,
    Object? hasElectricity = _sentinel,
    Object? hasWaterConnections = _sentinel,
    Object? hasRestroomAccess = _sentinel,
    Object? hasAcConnection = _sentinel,
    Object? floorLevel = _sentinel,
    Object? hasStorageOfficeArea = _sentinel,
    Object? address = _sentinel,
  }) {
    return PropertyFilter(
      operationType: operationType == _sentinel ? this.operationType : operationType as String?,
      category: category == _sentinel ? this.category : category as String?,
      types: types ?? Set.from(this.types),
      statuses: statuses ?? Set.from(this.statuses),
      ownerIds: ownerIds ?? Set.from(this.ownerIds),
      minPrice: minPrice == _sentinel ? this.minPrice : minPrice as double?,
      maxPrice: maxPrice == _sentinel ? this.maxPrice : maxPrice as double?,
      minArea: minArea == _sentinel ? this.minArea : minArea as double?,
      maxArea: maxArea == _sentinel ? this.maxArea : maxArea as double?,
      minBathrooms: minBathrooms == _sentinel ? this.minBathrooms : minBathrooms as int?,
      minParkingSpaces: minParkingSpaces == _sentinel ? this.minParkingSpaces : minParkingSpaces as int?,
      hasAirCon: hasAirCon == _sentinel ? this.hasAirCon : hasAirCon as bool?,
      hasExtraStorage: hasExtraStorage == _sentinel ? this.hasExtraStorage : hasExtraStorage as bool?,
      hasPool: hasPool == _sentinel ? this.hasPool : hasPool as bool?,
      hasTerrace: hasTerrace == _sentinel ? this.hasTerrace : hasTerrace as bool?,
      hasBalcony: hasBalcony == _sentinel ? this.hasBalcony : hasBalcony as bool?,
      hasPatio: hasPatio == _sentinel ? this.hasPatio : hasPatio as bool?,
      hasGarage: hasGarage == _sentinel ? this.hasGarage : hasGarage as bool?,
      hasElevator: hasElevator == _sentinel ? this.hasElevator : hasElevator as bool?,
      hasSecurity: hasSecurity == _sentinel ? this.hasSecurity : hasSecurity as bool?,
      isWaterfront: isWaterfront == _sentinel ? this.isWaterfront : isWaterfront as bool?,
      hasSeaView: hasSeaView == _sentinel ? this.hasSeaView : hasSeaView as bool?,
      hasBasement: hasBasement == _sentinel ? this.hasBasement : hasBasement as bool?,
      hasFittedKitchen: hasFittedKitchen == _sentinel ? this.hasFittedKitchen : hasFittedKitchen as bool?,
      hasTennisCourt: hasTennisCourt == _sentinel ? this.hasTennisCourt : hasTennisCourt as bool?,
      hasGarden: hasGarden == _sentinel ? this.hasGarden : hasGarden as bool?,
      isFurnished: isFurnished == _sentinel ? this.isFurnished : isFurnished as bool?,
      minYear: minYear == _sentinel ? this.minYear : minYear as int?,
      maxYear: maxYear == _sentinel ? this.maxYear : maxYear as int?,
      minPlotArea: minPlotArea == _sentinel ? this.minPlotArea : minPlotArea as double?,
      maxPlotArea: maxPlotArea == _sentinel ? this.maxPlotArea : maxPlotArea as double?,
      country: country == _sentinel ? this.country : country as String?,
      state: state == _sentinel ? this.state : state as String?,
      city: city == _sentinel ? this.city : city as String?,
      minLikes: minLikes == _sentinel ? this.minLikes : minLikes as int?,
      hasPowerGenerator: hasPowerGenerator == _sentinel ? this.hasPowerGenerator : hasPowerGenerator as bool?,
      hasWaterTank: hasWaterTank == _sentinel ? this.hasWaterTank : hasWaterTank as bool?,
      hasGrill: hasGrill == _sentinel ? this.hasGrill : hasGrill as bool?,
      petsAllowed: petsAllowed == _sentinel ? this.petsAllowed : petsAllowed as bool?,
      childrenAllowed: childrenAllowed == _sentinel ? this.childrenAllowed : childrenAllowed as bool?,
      deliveryStatus: deliveryStatus == _sentinel ? this.deliveryStatus : deliveryStatus as String?,
      hasElectricity: hasElectricity == _sentinel ? this.hasElectricity : hasElectricity as bool?,
      hasWaterConnections: hasWaterConnections == _sentinel ? this.hasWaterConnections : hasWaterConnections as bool?,
      hasRestroomAccess: hasRestroomAccess == _sentinel ? this.hasRestroomAccess : hasRestroomAccess as bool?,
      hasAcConnection: hasAcConnection == _sentinel ? this.hasAcConnection : hasAcConnection as bool?,
      floorLevel: floorLevel == _sentinel ? this.floorLevel : floorLevel as String?,
      hasStorageOfficeArea: hasStorageOfficeArea == _sentinel ? this.hasStorageOfficeArea : hasStorageOfficeArea as bool?,
      address: address == _sentinel ? this.address : address as String?,
    );
  }

  static const _sentinel = Object();

  /// Returns true if no filters are active.
  bool get isEmpty =>
      operationType == null &&
      category == null &&
      types.isEmpty &&
      statuses.isEmpty &&
      ownerIds.isEmpty &&
      minPrice == null &&
      maxPrice == null &&
      minArea == null &&
      maxArea == null &&
      minBathrooms == null &&
      minParkingSpaces == null &&
      hasAirCon == null &&
      hasExtraStorage == null &&
      hasPool == null &&
      hasTerrace == null &&
      hasBalcony == null &&
      hasPatio == null &&
      hasGarage == null &&
      hasElevator == null &&
      hasSecurity == null &&
      isWaterfront == null &&
      hasSeaView == null &&
      hasBasement == null &&
      hasFittedKitchen == null &&
      hasTennisCourt == null &&
      hasGarden == null &&
      isFurnished == null &&
      minYear == null &&
      maxYear == null &&
      minPlotArea == null &&
      maxPlotArea == null &&
      country == null &&
      state == null &&
      city == null &&
      minLikes == null &&
      hasPowerGenerator == null &&
      hasWaterTank == null &&
      hasGrill == null &&
      petsAllowed == null &&
      childrenAllowed == null &&
      deliveryStatus == null &&
      hasElectricity == null &&
      hasWaterConnections == null &&
      hasRestroomAccess == null &&
      hasAcConnection == null &&
      floorLevel == null &&
      hasStorageOfficeArea == null &&
      address == null;

  /// Returns how many individual filters are active.
  int get activeCount {
    int count = 0;
    if (operationType != null) count++;
    if (category != null) count++;
    if (types.isNotEmpty) count++;
    if (statuses.isNotEmpty) count++;
    if (ownerIds.isNotEmpty) count++;
    if (minPrice != null || maxPrice != null) count++;
    if (minArea != null || maxArea != null) count++;
    if (minBathrooms != null) count++;
    if (minParkingSpaces != null) count++;
    if (hasAirCon != null) count++;
    if (hasExtraStorage != null) count++;
    if (hasPool != null) count++;
    if (hasTerrace != null) count++;
    if (hasBalcony != null) count++;
    if (hasPatio != null) count++;
    if (hasGarage != null) count++;
    if (hasElevator != null) count++;
    if (hasSecurity != null) count++;
    if (isWaterfront != null) count++;
    if (hasSeaView != null) count++;
    if (hasBasement != null) count++;
    if (hasFittedKitchen != null) count++;
    if (hasTennisCourt != null) count++;
    if (hasGarden != null) count++;
    if (isFurnished != null) count++;
    if (minYear != null || maxYear != null) count++;
    if (minPlotArea != null || maxPlotArea != null) count++;
    if (country != null) count++;
    if (state != null) count++;
    if (city != null) count++;
    if (minLikes != null) count++;
    if (hasPowerGenerator != null) count++;
    if (hasWaterTank != null) count++;
    if (hasGrill != null) count++;
    if (petsAllowed != null) count++;
    if (childrenAllowed != null) count++;
    if (deliveryStatus != null) count++;
    if (hasElectricity != null) count++;
    if (hasWaterConnections != null) count++;
    if (hasRestroomAccess != null) count++;
    if (hasAcConnection != null) count++;
    if (floorLevel != null) count++;
    if (hasStorageOfficeArea != null) count++;
    if (address != null) count++;
    return count;
  }

  /// Returns true if [property] matches all active filters.
  bool matches(Property property) {
    if (operationType != null && property.operationType != operationType) return false;

    if (category != null) {
      const residentialTypes = {
        'Casa', 'Apartamento', 'Townhouse', 'Estudio', 'Ático', 'Dúplex', 'Loft',
        'Casa vacacional', 'Apartamento vacacional'
      };
      final isResidential = residentialTypes.contains(property.type);
      if (category == 'Residential' && !isResidential) return false;
      if (category == 'Commercial' && isResidential) return false;
    }

    if (types.isNotEmpty && !types.contains(property.type)) return false;
    if (statuses.isNotEmpty && !statuses.contains(property.status)) return false;
    if (ownerIds.isNotEmpty && !ownerIds.contains(property.ownerId)) return false;
    if (minPrice != null && property.price < minPrice!) return false;
    if (maxPrice != null && property.price > maxPrice!) return false;

    // Geolocation filters (case-insensitive, trim, no-accents)
    final normalize = (String? s) {
      if (s == null) return null;
      var str = s.trim().toLowerCase();
      str = str.replaceAll(RegExp(r'[áàäâ]'), 'a');
      str = str.replaceAll(RegExp(r'[éèëê]'), 'e');
      str = str.replaceAll(RegExp(r'[íìïî]'), 'i');
      str = str.replaceAll(RegExp(r'[óòöô]'), 'o');
      str = str.replaceAll(RegExp(r'[úùüû]'), 'u');
      str = str.replaceAll(RegExp(r'[ñ]'), 'n');
      return str;
    };

    if (country != null && (normalize(property.country) != normalize(country))) return false;
    if (state != null && (normalize(property.state) != normalize(state))) return false;
    if (city != null && (normalize(property.city) != normalize(city))) return false;
    
    if (address != null) {
      final searchStr = normalize(address) ?? '';
      final pAddr = normalize(property.address) ?? '';
      final pTitle = normalize(property.title) ?? '';
      final pDesc = normalize(property.description) ?? '';
      
      if (!pAddr.contains(searchStr) && 
          !pTitle.contains(searchStr) && 
          !pDesc.contains(searchStr)) {
        return false;
      }
    }

    final d = property.details;
    if (d != null) {
      if (minArea != null && d.areaM2 < minArea!) return false;
      if (maxArea != null && d.areaM2 > maxArea!) return false;
      if (minBathrooms != null && d.bathrooms < minBathrooms!) return false;
      if (minParkingSpaces != null && d.parkingSpaces < minParkingSpaces!) return false;
      if (hasAirCon == true && !d.hasAirCon) return false;
      if (hasExtraStorage == true && !d.hasExtraStorage) return false;
      if (hasPool == true && !d.hasPool) return false;
      if (hasTerrace == true && !d.hasTerrace) return false;
      if (hasBalcony == true && !d.hasBalcony) return false;
      if (hasPatio == true && !d.hasPatio) return false;
      if (hasGarage == true && !d.hasGarage) return false;
      if (hasElevator == true && !d.hasElevator) return false;
      if (hasSecurity == true && !d.hasSecurity) return false;
      if (isWaterfront == true && !d.isWaterfront) return false;
      if (hasSeaView == true && !d.hasSeaView) return false;
      if (hasBasement == true && !d.hasBasement) return false;
      if (hasFittedKitchen == true && !d.hasFittedKitchen) return false;
      if (hasTennisCourt == true && !d.hasTennisCourt) return false;
      if (hasGarden == true && !d.hasGarden) return false;
      if (isFurnished == true && !d.isFurnished) return false;
      if (hasPowerGenerator == true && !d.hasPowerGenerator) return false;
      if (hasWaterTank == true && !d.hasWaterTank) return false;
      if (hasGrill == true && !d.hasGrill) return false;
      if (petsAllowed == true && !d.petsAllowed) return false;
      if (childrenAllowed == true && !d.childrenAllowed) return false;
      
      if (deliveryStatus != null && d.deliveryStatus != deliveryStatus) return false;
      if (hasElectricity == true && d.hasElectricity != true) return false;
      if (hasWaterConnections == true && d.hasWaterConnections != true) return false;
      if (hasRestroomAccess == true && d.hasRestroomAccess != true) return false;
      if (hasAcConnection == true && d.hasAcConnection != true) return false;
      if (floorLevel != null && d.floorLevel != floorLevel) return false;
      if (hasStorageOfficeArea == true && d.hasStorageOfficeArea != true) return false;
      
      if (minYear != null && (d.yearBuilt == null || d.yearBuilt! < minYear!)) return false;
      if (maxYear != null && (d.yearBuilt == null || d.yearBuilt! > maxYear!)) return false;
      if (minPlotArea != null && (d.plotAreaM2 == null || d.plotAreaM2! < minPlotArea!)) return false;
      if (maxPlotArea != null && (d.plotAreaM2 == null || d.plotAreaM2! > maxPlotArea!)) return false;
    }

    return true;
  }
}
