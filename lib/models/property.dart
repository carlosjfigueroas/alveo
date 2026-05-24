class Property {
  final String id;
  final String title;
  final String? description;
  final double price;
  final String address;
  final String type;
  final String operationType;
  final String status;
  final String? ownerId;
  final String? adminId;
  final bool isPublic;
  final DateTime createdAt;
  final List<String> imageUrls;
  final PropertyDetails? details;
  final int? refNumber;
  final String? listingAgentId;
  final String? listingAgentName;

  // Geolocation
  final String? country;
  final String? state;
  final String? city;

  // Multi-tenant
  final String? companyId;

  // Geolocation
  final double? latitude;
  final double? longitude;
  final double? adminCommissionPct;
  bool get hasCoordinates => latitude != null && longitude != null;

  Property({
    required this.id,
    required this.title,
    this.description,
    required this.price,
    required this.address,
    required this.type,
    required this.operationType,
    required this.status,
    this.ownerId,
    this.adminId,
    required this.isPublic,
    required this.createdAt,
    this.imageUrls = const [],
    this.details,
    this.refNumber,
    this.country,
    this.state,
    this.city,
    this.companyId,
    this.latitude,
    this.longitude,
    this.adminCommissionPct,
    this.listingAgentId,
    this.listingAgentName,
  });

  factory Property.fromJson(Map<String, dynamic> json) {
    return Property(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Sin Título',
      description: json['description']?.toString(),
      price: (json['price'] as num? ?? 0).toDouble(),
      address: json['address']?.toString() ?? '',
      type: json['type']?.toString() ?? 'Local',
      operationType: json['operation_type']?.toString() ?? 'Alquiler',
      status: json['status']?.toString() ?? 'Disponible',
      ownerId: json['owner_id']?.toString(),
      adminId: json['admin_id']?.toString(),
      isPublic: json['is_public'] ?? false,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'].toString()) : DateTime.now(),
      imageUrls: (() {
        final List? gallery = json['gallery'] as List?;
        if (gallery == null) return <String>[];
        final sortedGallery = List.from(gallery);
        sortedGallery.sort((a, b) {
          final aMain = a['is_main'] == true ? 1 : 0;
          final bMain = b['is_main'] == true ? 1 : 0;
          return bMain.compareTo(aMain);
        });
        return sortedGallery.map((item) => item['image_url']?.toString() ?? '').where((url) => url.isNotEmpty).toList();
      })(),
      details: json['property_details'] != null
          ? PropertyDetails.fromJson(json['property_details'])
          : null,
      refNumber: json['ref_number'] is int ? json['ref_number'] : (int.tryParse(json['ref_number']?.toString() ?? '')),
      country: json['country']?.toString(),
      state: json['state']?.toString(),
      city: json['city']?.toString(),
      companyId: json['company_id']?.toString(),
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
      adminCommissionPct: json['admin_commission_pct'] != null ? (json['admin_commission_pct'] as num).toDouble() : null,
      listingAgentId: json['listing_agent_id']?.toString(),
      listingAgentName: json['listing_agent']?['full_name']?.toString(),
    );
  }

  /// Returns a formatted location string: "Ciudad, Estado, País"
  String get locationLabel {
    final parts = [city, state, country].where((p) => p != null && p.isNotEmpty).toList();
    return parts.join(', ');
  }

  bool get isResidential => const {'Casa', 'Apartamento', 'Loft', 'Estudio'}.contains(type);
  bool get isAlquiler => operationType == 'Alquiler';
}

class PropertyDetails {
  final int bathrooms;
  final double areaM2;
  final int parkingSpaces;
  final bool hasAirCon;
  final bool hasExtraStorage;
  final int bedrooms;
  final int floors;
  final bool hasGarden;
  final bool isFurnished;
  final String? interiorLocation;

  // New features
  final int? yearBuilt;
  final double? plotAreaM2;
  final bool hasPool;
  final bool hasTerrace;
  final bool hasBalcony;
  final bool hasPatio;
  final bool hasGarage;
  final bool hasElevator;
  final bool hasSecurity;
  final bool isWaterfront;
  final bool hasSeaView;
  final bool hasBasement;
  final bool hasFittedKitchen;
  final bool hasTennisCourt;
  final bool hasPowerGenerator;
  final bool hasWaterTank;
  final bool hasGrill;
  final bool petsAllowed;
  final bool childrenAllowed;

  // Delivery & Installation fields
  final String? deliveryStatus;       // obra_gris | semi_acabado | listo_para_ocupar
  final bool? hasElectricity;
  final bool? hasWaterConnections;
  final bool? hasRestroomAccess;
  final bool? hasAcConnection;
  final String? floorLevel;           // incluido_en_direccion | planta_baja | mezzanina | primer_piso | segundo_piso | tercer_piso | cuarto_piso
  final bool? hasStorageOfficeArea;   // Commercial only

  PropertyDetails({
    required this.bathrooms,
    required this.areaM2,
    required this.parkingSpaces,
    required this.hasAirCon,
    required this.hasExtraStorage,
    this.bedrooms = 0,
    this.floors = 1,
    this.hasGarden = false,
    this.isFurnished = false,
    this.interiorLocation,
    this.yearBuilt,
    this.plotAreaM2,
    this.hasPool = false,
    this.hasTerrace = false,
    this.hasBalcony = false,
    this.hasPatio = false,
    this.hasGarage = false,
    this.hasElevator = false,
    this.hasSecurity = false,
    this.isWaterfront = false,
    this.hasSeaView = false,
    this.hasBasement = false,
    this.hasFittedKitchen = false,
    this.hasTennisCourt = false,
    this.hasPowerGenerator = false,
    this.hasWaterTank = false,
    this.hasGrill = false,
    this.petsAllowed = true,
    this.childrenAllowed = true,
    this.deliveryStatus,
    this.hasElectricity,
    this.hasWaterConnections,
    this.hasRestroomAccess,
    this.hasAcConnection,
    this.floorLevel,
    this.hasStorageOfficeArea,
  });

  factory PropertyDetails.fromJson(Map<String, dynamic> json) {
    return PropertyDetails(
      bathrooms: json['bathrooms'] ?? 0,
      areaM2: (json['area_m2'] as num? ?? 0).toDouble(),
      parkingSpaces: json['parking_spaces'] ?? 0,
      hasAirCon: json['has_air_con'] ?? false,
      hasExtraStorage: json['has_extra_storage'] ?? false,
      bedrooms: json['bedrooms'] ?? 0,
      floors: json['floors'] ?? 1,
      hasGarden: json['has_garden'] ?? false,
      isFurnished: json['is_furnished'] ?? false,
      interiorLocation: json['interior_location']?.toString(),
      yearBuilt: json['year_built'],
      plotAreaM2: json['plot_area_m2'] != null ? (json['plot_area_m2'] as num).toDouble() : null,
      hasPool: json['has_pool'] ?? false,
      hasTerrace: json['has_terrace'] ?? false,
      hasBalcony: json['has_balcony'] ?? false,
      hasPatio: json['has_patio'] ?? false,
      hasGarage: json['has_garage'] ?? false,
      hasElevator: json['has_elevator'] ?? false,
      hasSecurity: json['has_security'] ?? false,
      isWaterfront: json['is_waterfront'] ?? false,
      hasSeaView: json['has_sea_view'] ?? false,
      hasBasement: json['has_basement'] ?? false,
      hasFittedKitchen: json['has_fitted_kitchen'] ?? false,
      hasTennisCourt: json['has_tennis_court'] ?? false,
      hasPowerGenerator: json['has_power_generator'] ?? false,
      hasWaterTank: json['has_water_tank'] ?? false,
      hasGrill: json['has_grill'] ?? false,
      petsAllowed: json['pets_allowed'] ?? true,
      childrenAllowed: json['children_allowed'] ?? true,
      deliveryStatus: json['delivery_status']?.toString(),
      hasElectricity: json['has_electricity'],
      hasWaterConnections: json['has_water_connections'],
      hasRestroomAccess: json['has_restroom_access'],
      hasAcConnection: json['has_ac_connection'],
      floorLevel: json['floor_level']?.toString(),
      hasStorageOfficeArea: json['has_storage_office_area'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bathrooms': bathrooms,
      'area_m2': areaM2,
      'parking_spaces': parkingSpaces,
      'has_air_con': hasAirCon,
      'has_extra_storage': hasExtraStorage,
      'bedrooms': bedrooms,
      'floors': floors,
      'has_garden': hasGarden,
      'is_furnished': isFurnished,
      'interior_location': interiorLocation,
      'year_built': yearBuilt,
      'plot_area_m2': plotAreaM2,
      'has_pool': hasPool,
      'has_terrace': hasTerrace,
      'has_balcony': hasBalcony,
      'has_patio': hasPatio,
      'has_garage': hasGarage,
      'has_elevator': hasElevator,
      'has_security': hasSecurity,
      'is_waterfront': isWaterfront,
      'has_sea_view': hasSeaView,
      'has_basement': hasBasement,
      'has_fitted_kitchen': hasFittedKitchen,
      'has_tennis_court': hasTennisCourt,
      'has_power_generator': hasPowerGenerator,
      'has_water_tank': hasWaterTank,
      'has_grill': hasGrill,
      'pets_allowed': petsAllowed,
      'children_allowed': childrenAllowed,
      'delivery_status': deliveryStatus,
      'has_electricity': hasElectricity,
      'has_water_connections': hasWaterConnections,
      'has_restroom_access': hasRestroomAccess,
      'has_ac_connection': hasAcConnection,
      'floor_level': floorLevel,
      'has_storage_office_area': hasStorageOfficeArea,
    };
  }
}
