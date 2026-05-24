import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/company.dart';
import '../models/property.dart';
import '../models/site_content.dart';
import '../models/owner.dart';
import '../models/user_profile.dart';

class SupabaseService {
  final SupabaseClient client = Supabase.instance.client;

  // ── Helpers ─────────────────────────────────────────────────────────────
  String getPublicUrl(String bucket, String path) {
    return client.storage.from(bucket).getPublicUrl(path);
  }

  // ── Selector base de propiedades ─────────────────────────────────────────
  static const _propertySelect = '*, property_details(*), gallery(image_url, is_main), listing_agent:profiles!properties_listing_agent_id_fkey(full_name)';

  // ═══════════════════════════════════════════════════════════════════════
  // PROPIEDADES
  // ═══════════════════════════════════════════════════════════════════════

  /// Inmuebles públicos de una empresa específica (visitante anónimo).
  Future<List<Property>> getPublicProperties(String companyId) async {
    final response = await client
        .from('properties')
        .select(_propertySelect)
        .eq('company_id', companyId)
        .eq('is_public', true)
        .order('created_at', ascending: false);
    return (response as List).map((json) => Property.fromJson(json)).toList();
  }

  /// Todos los inmuebles de una empresa (admin de empresa).
  Future<List<Property>> getAllProperties(String companyId) async {
    final response = await client
        .from('properties')
        .select(_propertySelect)
        .eq('company_id', companyId)
        .order('created_at', ascending: false);
    return (response as List).map((json) => Property.fromJson(json)).toList();
  }

  Future<List<Property>> getProperties({required String companyId}) => getAllProperties(companyId);

  /// Todos los inmuebles de TODAS las empresas (Super Admin / búsqueda global).
  Future<List<Property>> getAllPropertiesGlobal() async {
    final response = await client
        .from('properties')
        .select(_propertySelect)
        .eq('is_public', true)
        .order('created_at', ascending: false);
    return (response as List).map((json) => Property.fromJson(json)).toList();
  }

  /// Inmuebles por propietario, filtrado por empresa.
  Future<List<Property>> getPropertiesByOwner(String ownerId, String companyId) async {
    final response = await client
        .from('properties')
        .select(_propertySelect)
        .eq('owner_id', ownerId)
        .eq('company_id', companyId)
        .order('created_at', ascending: false);
    return (response as List).map((json) => Property.fromJson(json)).toList();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // AUTH
  // ═══════════════════════════════════════════════════════════════════════

  Future<AuthResponse> signIn(String email, String password) async {
    return await client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await client.auth.signOut();
  }

  User? get currentUser => client.auth.currentUser;

  Future<UserProfile?> getUserProfile(String userId) async {
    final response = await client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    if (response == null) return null;
    return UserProfile.fromJson(response);
  }

  Future<UserProfile?> getProfileBySlug(String slug) async {
    final response = await client
        .from('profiles')
        .select()
        .eq('slug', slug)
        .maybeSingle();
    if (response == null) return null;
    return UserProfile.fromJson(response);
  }

  Future<void> updateUserProfile(String userId, Map<String, dynamic> data) async {
    await client
        .from('profiles')
        .update(data)
        .eq('id', userId);
  }

  // ═══════════════════════════════════════════════════════════════════════
  // GALERÍA / IMÁGENES
  // ═══════════════════════════════════════════════════════════════════════

  Future<String> uploadPropertyImage(String path, dynamic file, {String? contentType}) async {
    await client.storage.from('property-images').uploadBinary(
      path,
      file,
      fileOptions: FileOptions(contentType: contentType ?? 'image/jpeg', upsert: true),
    );
    return client.storage.from('property-images').getPublicUrl(path);
  }

  /// Sube un logo de empresa (completo o abreviado) a Supabase Storage.
  Future<String> uploadCompanyLogo(String path, dynamic file, {String? contentType}) async {
    final storagePath = 'logos/$path';
    await client.storage.from('property-images').uploadBinary(
      storagePath,
      file,
      fileOptions: FileOptions(contentType: contentType ?? 'image/png', upsert: true),
    );
    return client.storage.from('property-images').getPublicUrl(storagePath);
  }

  Future<String> uploadFile(String bucket, String path, dynamic file, {String? contentType}) async {
    await client.storage.from(bucket).uploadBinary(
      path,
      file,
      fileOptions: FileOptions(contentType: contentType ?? 'application/octet-stream', upsert: true),
    );
    return client.storage.from(bucket).getPublicUrl(path);
  }

  Future<void> deleteGalleryImage(String propertyId, String imageUrl) async {
    await client.from('gallery').delete().eq('property_id', propertyId).eq('image_url', imageUrl);
    if (imageUrl.contains('property-images')) {
      final uri = Uri.parse(imageUrl);
      final path = uri.pathSegments
          .sublist(uri.pathSegments.indexOf('property-images') + 1)
          .join('/');
      try {
        await client.storage.from('property-images').remove([path]);
      } catch (e) {
        debugPrint('Error deleting from storage: $e');
      }
    }
  }

  Future<void> setMainGalleryImage(String propertyId, String imageUrl) async {
    await client.from('gallery').update({'is_main': false}).eq('property_id', propertyId);
    await client.from('gallery').update({'is_main': true}).eq('property_id', propertyId).eq('image_url', imageUrl);
  }

  Future<void> savePropertyGallery(String propertyId, String imageUrl, bool isMain) async {
    await client.from('gallery').insert({
      'property_id': propertyId,
      'image_url': imageUrl,
      'is_main': isMain,
    });
  }

  // ═══════════════════════════════════════════════════════════════════════
  // CAROUSEL
  // ═══════════════════════════════════════════════════════════════════════

  String getCarouselImageUrl(int slot, String companyId) {
    final name = 'carrusel_img_${slot.toString().padLeft(2, '0')}.jpg';
    return client.storage.from('property-images').getPublicUrl('carousel/$companyId/$name');
  }

  Future<List<String>> listCarouselImages(String companyId) async {
    try {
      final List<FileObject> objects =
          await client.storage.from('property-images').list(path: 'carousel/$companyId');
      return objects.map((e) => e.name).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> uploadCarouselImage(int slot, dynamic bytes, String mimeType, String companyId) async {
    final name = 'carrusel_img_${slot.toString().padLeft(2, '0')}.jpg';
    final path = 'carousel/$companyId/$name';
    try {
      await client.storage.from('property-images').remove([path]);
    } catch (_) {}
    await client.storage.from('property-images').uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(contentType: mimeType, upsert: true),
    );
  }

  /// Retorna un mapa {slot → action} para los slots que tienen acción configurada.
  Future<Map<int, String>> getCarouselActions(String companyId) async {
    try {
      final rows = await client
          .from('carousel_actions')
          .select('slot, action')
          .eq('company_id', companyId);
      final map = <int, String>{};
      for (final row in rows as List) {
        final slot = row['slot'] as int?;
        final action = row['action'] as String?;
        if (slot != null && action != null && action.isNotEmpty) {
          map[slot] = action;
        }
      }
      return map;
    } catch (_) {
      return {};
    }
  }

  /// Guarda o elimina la acción de un slot específico del carrusel.
  Future<void> setCarouselAction(String companyId, int slot, String? action) async {
    if (action == null || action.trim().isEmpty) {
      // Eliminar si existe
      await client
          .from('carousel_actions')
          .delete()
          .eq('company_id', companyId)
          .eq('slot', slot);
    } else {
      // Upsert
      await client.from('carousel_actions').upsert({
        'company_id': companyId,
        'slot': slot,
        'action': action.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'company_id,slot');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // SOLICITUDES DE PRESUPUESTO (LEADS)
  // ═══════════════════════════════════════════════════════════════════════

  /// Crea una solicitud, incluyendo el company_id para el aislamiento.
  Future<void> createBudgetRequest(Map<String, dynamic> data, String companyId) async {
    await client.from('budget_requests').insert({
      'client_name': data['name'] ?? '',
      'client_email': data['email'] ?? '',
      'phone': data['phone'] ?? '',
      'property_list': data['propertyIds'] ?? [],
      'notes': data['notes'] ?? '',
      'status': 'pending',
      'company_id': companyId,
      'is_appointment': false,
      'assigned_agent_id': data['assigned_agent_id'],
    });

    try {
      await client.functions.invoke('send-budget-email', body: data);
    } catch (e) {
      debugPrint('Error sending budget email: $e');
    }
  }

  /// Obtiene solicitudes de una empresa.
  Future<List<Map<String, dynamic>>> getBudgetRequests(String companyId, {String? agentId}) async {
    var query = client
        .from('budget_requests')
        .select()
        .eq('company_id', companyId)
        .eq('is_appointment', false);
        
    if (agentId != null) {
      query = query.eq('assigned_agent_id', agentId);
    }
        
    final response = await query.order('sent_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Obtiene TODAS las solicitudes (Super Admin).
  Future<List<Map<String, dynamic>>> getAllBudgetRequestsGlobal() async {
    final response = await client
        .from('budget_requests')
        .select()
        .eq('is_appointment', false)
        .order('sent_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> updateBudgetStatus(String id, String status) async {
    await client.from('budget_requests').update({
      'status': status,
      'responded_at': status == 'responded' ? DateTime.now().toIso8601String() : null,
    }).eq('id', id);
  }

  Future<void> deleteBudgetRequest(String id) async {
    await client.from('budget_requests').delete().eq('id', id);
  }

  // ═══════════════════════════════════════════════════════════════════════
  // AGENDA (CITAS)
  // ═══════════════════════════════════════════════════════════════════════

  Future<List<Map<String, dynamic>>> getAppointments(String companyId, {String? agentId}) async {
    var query = client
        .from('budget_requests')
        .select()
        .eq('company_id', companyId)
        .eq('is_appointment', true);
        
    if (agentId != null) {
      query = query.eq('assigned_agent_id', agentId);
    }
        
    final response = await query
        .order('appointment_date', ascending: true)
        .order('appointment_time', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getAllAppointmentsGlobal() async {
    final response = await client
        .from('budget_requests')
        .select()
        .eq('is_appointment', true)
        .order('appointment_date', ascending: true)
        .order('appointment_time', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> createAppointment(Map<String, dynamic> data, String companyId) async {
    await client.from('budget_requests').insert({
      'company_id': companyId,
      'is_appointment': true,
      'client_name': data['client_name'],
      'phone': data['phone'],
      'property_list': [data['property_id']],
      'appointment_date': data['date'],
      'appointment_time': data['time'],
      'appointment_status': data['status'] ?? 'pending',
      'status': 'pending', // Campo requerido de leads
      'client_email': 'agenda@local', // Constraint de la tabla budget_requests
      'assigned_agent_id': data['agent_id'],
    });
  }

  Future<void> updateAppointment(String id, Map<String, dynamic> data) async {
    await client.from('budget_requests').update({
      'client_name': data['client_name'],
      'phone': data['phone'],
      'property_list': [data['property_id']],
      'appointment_date': data['date'],
      'appointment_time': data['time'],
      'appointment_status': data['status'],
      'assigned_agent_id': data['agent_id'],
    }).eq('id', id);
  }

  Future<void> deleteAppointment(String id) async {
    await client.from('budget_requests').delete().eq('id', id);
  }

  Future<int> getTodayAppointmentsCount(String companyId, {String? agentId}) async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    var query = client
        .from('budget_requests')
        .select('id')
        .eq('company_id', companyId)
        .eq('is_appointment', true)
        .eq('appointment_date', today);
        
    if (agentId != null) {
      query = query.eq('assigned_agent_id', agentId);
    }
        
    final response = await query.count(CountOption.exact);
    return response.count ?? 0;
  }

  Future<List<Map<String, dynamic>>> getCompanyUsers(String companyId) async {
    final response = await client
        .from('profiles')
        .select('id, full_name, role')
        .eq('company_id', companyId)
        .order('full_name');
    return List<Map<String, dynamic>>.from(response);
  }

  // ═══════════════════════════════════════════════════════════════════════
  // PROPIETARIOS
  // ═══════════════════════════════════════════════════════════════════════

  /// Propietarios de una empresa.
  Future<List<Map<String, dynamic>>> getOwners(String companyId) async {
    final response = await client
        .from('owners')
        .select()
        .eq('company_id', companyId)
        .order('full_name');
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> createOwner(Map<String, dynamic> data) async {
    await client.from('owners').insert(data);
  }

  Future<void> updateOwner(String id, Map<String, dynamic> data) async {
    await client.from('owners').update(data).eq('id', id);
  }

  Future<void> deleteOwner(String id) async {
    await client.from('owners').delete().eq('id', id);
  }

  Future<Owner?> getOwner(String id) async {
    final res = await client.from('owners').select().eq('id', id).maybeSingle();
    if (res == null) return null;
    return Owner.fromJson(res);
  }

  // ═══════════════════════════════════════════════════════════════════════
  // PROPIEDADES CRUD
  // ═══════════════════════════════════════════════════════════════════════

  Future<void> createProperty(
    Map<String, dynamic> data,
    Map<String, dynamic> details,
  ) async {
    final propertyResponse =
        await client.from('properties').insert(data).select().single();
    final propertyId = propertyResponse['id'];
    await client.from('property_details').insert({
      'property_id': propertyId,
      ...details,
    });
  }

  Future<void> updateProperty(
    String id,
    Map<String, dynamic> data,
    Map<String, dynamic> details,
  ) async {
    await client.from('properties').update(data).eq('id', id);
    await client.from('property_details').update(details).eq('property_id', id);
  }

  Future<void> deleteProperty(String id) async {
    await client.from('properties').delete().eq('id', id);
  }

  // ═══════════════════════════════════════════════════════════════════════
  // REFERIDOS
  // ═══════════════════════════════════════════════════════════════════════

  Future<int> getReferralCount(String companyId) async {
    final response = await client
        .from('referrals')
        .select('id')
        .eq('referrer_company_id', companyId)
        .eq('status', 'active')
        .count(CountOption.exact);
    return response.count ?? 0;
  }

  // ═══════════════════════════════════════════════════════════════════════
  // DASHBOARD STATS — filtrado por empresa
  // ═══════════════════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> getDashboardStats(String companyId, {DateTime? startDate, DateTime? endDate, String? agentId}) async {
    var propsQuery = client
        .from('properties')
        .select('id, status, type, operation_type, owner_id, city, owners(full_name), property_details(*)')
        .eq('company_id', companyId);

    if (agentId != null) {
      propsQuery = propsQuery.eq('listing_agent_id', agentId);
    }
    
    final properties = await propsQuery;

    final ownersResp = await client
        .from('owners')
        .select('id')
        .eq('company_id', companyId);

    var leadsQuery = client
        .from('budget_requests')
        .select('id')
        .eq('company_id', companyId);

    var commissionsQuery = client
        .from('property_commissions')
        .select('total_collected, agency_retention_amount, commission_agents(amount, is_paid), closed_date')
        .eq('company_id', companyId);

    if (agentId != null) {
      leadsQuery = leadsQuery.eq('assigned_agent_id', agentId);
      // Para comisiones, idealmente filtraríamos por el agente en commission_agents.
      // Por simplicidad en esta fase, si es agente, la vista de comisiones global 
      // del dashboard ya suele estar filtrada o se maneja en su pantalla específica.
    }

    if (startDate != null) {
      leadsQuery = leadsQuery.gte('sent_at', startDate.toIso8601String());
      commissionsQuery = commissionsQuery.gte('closed_date', startDate.toIso8601String());
    }
    if (endDate != null) {
      leadsQuery = leadsQuery.lte('sent_at', endDate.toIso8601String());
      commissionsQuery = commissionsQuery.lte('closed_date', endDate.toIso8601String());
    }

    final leadsResp = await leadsQuery;

    final agentsResp = await client
        .from('profiles')
        .select('id')
        .eq('company_id', companyId)
        .eq('role', 'agent');

    final commissionsResp = await commissionsQuery;

    return _computeStats(
      properties as List, 
      ownersResp as List, 
      leadsResp as List, 
      agentsResp as List,
      commissionsResp as List,
    );
  }

  /// Stats globales para el Super Admin.
  Future<Map<String, dynamic>> getDashboardStatsGlobal({DateTime? startDate, DateTime? endDate}) async {
    final properties = await client
        .from('properties')
        .select('id, status, type, operation_type, owner_id, city, owners(full_name), property_details(*)');
    final ownersResp = await client.from('owners').select('id');
    
    var leadsQuery = client.from('budget_requests').select('id');
    var commissionsQuery = client
        .from('property_commissions')
        .select('total_collected, agency_retention_amount, commission_agents(amount, is_paid), closed_date');

    if (startDate != null) {
      leadsQuery = leadsQuery.gte('sent_at', startDate.toIso8601String());
      commissionsQuery = commissionsQuery.gte('closed_date', startDate.toIso8601String());
    }
    if (endDate != null) {
      leadsQuery = leadsQuery.lte('sent_at', endDate.toIso8601String());
      commissionsQuery = commissionsQuery.lte('closed_date', endDate.toIso8601String());
    }

    final leadsResp = await leadsQuery;
    final agentsResp = await client.from('profiles').select('id').eq('role', 'agent');
    final commissionsResp = await commissionsQuery;
    
    return _computeStats(
      properties as List, 
      ownersResp as List, 
      leadsResp as List, 
      agentsResp as List,
      commissionsResp as List,
    );
  }

  Map<String, dynamic> _computeStats(List properties, List owners, List leads, List agents, List commissions) {
    final total = properties.length;
    int resCount = 0, commCount = 0;
    double resTotalArea = 0, commTotalArea = 0;
    int resWithArea = 0, commWithArea = 0;

    final Map<String, int> typeCounts = {
      'Local': 0, 'Oficina': 0, 'Almacén': 0, 'Casa': 0, 'Apartamento': 0,
      'Terreno': 0, 'Ático': 0, 'Dúplex': 0, 'Loft': 0, 'Estudio': 0,
      'Inversión': 0, 'Tienda': 0, 'Hotel': 0, 'Restauración': 0, 'Patio Industrial': 0,
      'Agricultura y bosques': 0, 'Centro Comercial': 0, 'Otro': 0,
    };
    int venta = 0, alquiler = 0;
    int disponible = 0, reservado = 0, vendido = 0;
    final Map<String, int> amenities = {
      'Piscina': 0, 'Terraza': 0, 'Balcón': 0, 'Garaje': 0,
      'Seguridad': 0, 'Frente al mar': 0, 'Amoblado': 0,
      'Parrillera': 0, 'Planta Eléctrica': 0, 'Tanque de Agua': 0,
      'Cocina': 0, 'Sótano': 0,
    };
    double totalArea = 0, totalPlotArea = 0;
    int propertiesWithArea = 0, propertiesWithPlot = 0;
    int? oldestYear, newestYear;
    double sumYears = 0;
    int propertiesWithYear = 0;
    
    int totalBedrooms = 0, propertiesWithBedrooms = 0;
    int totalBathrooms = 0, propertiesWithBathrooms = 0;
    int totalParking = 0, propertiesWithParking = 0;
    
    final ownerCounts = <String, int>{};
    final cityCounts  = <String, int>{};
    const residentialTypes = {'Casa', 'Apartamento', 'Ático', 'Dúplex', 'Loft', 'Estudio'};

    for (var p in properties) {
      final t = (p['type'] as String?) ?? 'Otro';
      typeCounts[t] = (typeCounts[t] ?? 0) + 1;
      final isRes = residentialTypes.contains(t);
      if (isRes) resCount++; else commCount++;

      final op = p['operation_type'] as String?;
      if (op == 'Venta') venta++; else if (op == 'Alquiler') alquiler++;

      final st = p['status'] as String?;
      if (st == 'Disponible') disponible++;
      else if (st == 'Reservado') reservado++;
      else vendido++;

      final ownerName = p['owners']?['full_name'] ?? 'Desconocido';
      ownerCounts[ownerName] = (ownerCounts[ownerName] ?? 0) + 1;

      final city = p['city'] as String?;
      if (city != null && city.isNotEmpty) {
        cityCounts[city] = (cityCounts[city] ?? 0) + 1;
      }

      final d = p['property_details'];
      if (d != null) {
        if (d['has_pool']     == true) amenities['Piscina']       = amenities['Piscina']!      + 1;
        if (d['has_terrace']  == true) amenities['Terraza']       = amenities['Terraza']!      + 1;
        if (d['has_balcony']  == true) amenities['Balcón']        = amenities['Balcón']!       + 1;
        if (d['has_garage']   == true) amenities['Garaje']        = amenities['Garaje']!       + 1;
        if (d['has_security'] == true) amenities['Seguridad']     = amenities['Seguridad']!    + 1;
        if (d['is_waterfront']== true) amenities['Frente al mar'] = amenities['Frente al mar']!+ 1;
        if (d['is_furnished'] == true) amenities['Amoblado']     = amenities['Amoblado']!    + 1;
        if (d['has_grill']    == true) amenities['Parrillera']   = amenities['Parrillera']!  + 1;
        if (d['has_power_generator'] == true) amenities['Planta Eléctrica'] = amenities['Planta Eléctrica']! + 1;
        if (d['has_water_tank']      == true) amenities['Tanque de Agua']   = amenities['Tanque de Agua']!   + 1;
        if (d['has_fitted_kitchen']  == true) amenities['Cocina']           = amenities['Cocina']!           + 1;
        if (d['has_basement']        == true) amenities['Sótano']           = amenities['Sótano']!           + 1;

        final year = d['year_built'] as int?;
        if (year != null) {
          if (oldestYear == null || year < oldestYear) oldestYear = year;
          if (newestYear == null || year > newestYear) newestYear = year;
          sumYears += year; propertiesWithYear++;
        }
        final area = (d['area_m2'] as num?)?.toDouble() ?? 0.0;
        if (area > 0) {
          totalArea += area; propertiesWithArea++;
          if (isRes) { resTotalArea += area; resWithArea++; }
          else       { commTotalArea += area; commWithArea++; }
        }
        final plot = (d['plot_area_m2'] as num?)?.toDouble() ?? 0.0;
        if (plot > 0) { totalPlotArea += plot; propertiesWithPlot++; }

        final beds = (d['bedrooms'] as num?)?.toInt() ?? 0;
        if (beds > 0) { totalBedrooms += beds; propertiesWithBedrooms++; }

        final baths = (d['bathrooms'] as num?)?.toInt() ?? 0;
        if (baths > 0) { totalBathrooms += baths; propertiesWithBathrooms++; }

        final parking = (d['parking_spaces'] as num?)?.toInt() ?? 0;
        if (parking > 0) { totalParking += parking; propertiesWithParking++; }
      }
    }

    final ownerStatsList = ownerCounts.entries
        .map((e) => {'name': e.key, 'count': e.value}).toList()
      ..sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));

    final cityStatsList = cityCounts.entries
        .map((e) => {'name': e.key, 'count': e.value}).toList()
      ..sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));

    return {
      'total_properties': total,
      'res_count': resCount,
      'comm_count': commCount,
      'owners_count': owners.length,
      'leads_count': leads.length,
      'agents_count': agents.length,
      'oldest_year': oldestYear,
      'newest_year': newestYear,
      'avg_year_built': propertiesWithYear > 0 ? sumYears / propertiesWithYear : 0.0,
      'pool_density': total > 0 ? (amenities['Piscina']! / total) * 100 : 0,
      'security_density': total > 0 ? (amenities['Seguridad']! / total) * 100 : 0,
      'status_stats': {'Disponible': disponible, 'Reservado': reservado, 'Vendido/Alquilado': vendido},
      'op_stats': {'Venta': venta, 'Alquiler': alquiler},
      'type_stats': typeCounts,
      'amenity_stats': amenities,
      'avg_area': propertiesWithArea > 0 ? totalArea / propertiesWithArea : 0.0,
      'avg_res_area': resWithArea > 0 ? resTotalArea / resWithArea : 0.0,
      'avg_comm_area': commWithArea > 0 ? commTotalArea / commWithArea : 0.0,
      'avg_plot': propertiesWithPlot > 0 ? totalPlotArea / propertiesWithPlot : 0.0,
      'avg_bedrooms': propertiesWithBedrooms > 0 ? totalBedrooms / propertiesWithBedrooms : 0.0,
      'avg_bathrooms': propertiesWithBathrooms > 0 ? totalBathrooms / propertiesWithBathrooms : 0.0,
      'avg_parking': propertiesWithParking > 0 ? totalParking / propertiesWithParking : 0.0,
      'owner_stats': ownerStatsList,
      'city_stats': cityStatsList,
      'commissions_total': commissions.fold(0.0, (sum, c) => sum + ((c['total_collected'] as num?)?.toDouble() ?? 0.0)),
      'agency_retention_total': commissions.fold(0.0, (sum, c) => sum + ((c['agency_retention_amount'] as num?)?.toDouble() ?? 0.0)),
      'pending_agent_payouts': commissions.fold(0.0, (sum, c) {
        final agents = (c['commission_agents'] as List?) ?? [];
        final pending = agents.fold(0.0, (s, a) => s + (a['is_paid'] == false ? ((a['amount'] as num?)?.toDouble() ?? 0.0) : 0.0));
        return sum + pending;
      }),
      'commissions_by_month': _aggregateCommissionsByMonth(commissions),
    };
  }

  Map<String, Map<String, double>> _aggregateCommissionsByMonth(List commissions) {
    final Map<String, Map<String, double>> result = {};
    for (var c in commissions) {
      final dateStr = c['closed_date'] as String?;
      if (dateStr == null) continue;
      
      // Extract YYYY-MM
      final month = dateStr.substring(0, 7);
      
      final total = (c['total_collected'] as num?)?.toDouble() ?? 0.0;
      final retention = (c['agency_retention_amount'] as num?)?.toDouble() ?? 0.0;
      
      if (!result.containsKey(month)) {
        result[month] = {'total': 0.0, 'retention': 0.0};
      }
      
      result[month]!['total'] = result[month]!['total']! + total;
      result[month]!['retention'] = result[month]!['retention']! + retention;
    }
    
    // Sort by month ascending
    final sortedKeys = result.keys.toList()..sort();
    final Map<String, Map<String, double>> sortedResult = {};
    for (var key in sortedKeys) {
      sortedResult[key] = result[key]!;
    }
    
    return sortedResult;
  }

  // ═══════════════════════════════════════════════════════════════════════
  // GESTIÓN DE CONTENIDO (About Us, FAQs)
  // ═══════════════════════════════════════════════════════════════════════

  Future<List<AboutContent>> getAboutContent(String companyId) async {
    final res = await client
        .from('about_us')
        .select()
        .eq('company_id', companyId)
        .order('key');
    return (res as List).map((json) => AboutContent.fromJson(json)).toList();
  }

  Future<void> updateAboutContent(String key, String es, String en, String companyId) async {
    await client.from('about_us').upsert({
      'key': key,
      'value_es': es,
      'value_en': en,
      'company_id': companyId,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<FaqEntry>> getFaqs(String companyId) async {
    final res = await client
        .from('faqs')
        .select()
        .eq('company_id', companyId)
        .order('sort_order');
    return (res as List).map((json) => FaqEntry.fromJson(json)).toList();
  }

  Future<void> saveFaq(FaqEntry faq, String companyId) async {
    final data = {
      'question_es': faq.questionEs,
      'answer_es': faq.answerEs,
      'question_en': faq.questionEn,
      'answer_en': faq.answerEn,
      'sort_order': faq.sortOrder,
      'company_id': companyId,
    };
    if (faq.id.isNotEmpty && !faq.id.startsWith('temp_')) {
      data['id'] = faq.id;
    }
    await client.from('faqs').upsert(data);
  }

  Future<void> deleteFaq(String id) async {
    await client.from('faqs').delete().eq('id', id);
  }

  // ═══════════════════════════════════════════════════════════════════════
  // GESTIÓN DE EMPRESAS
  // ═══════════════════════════════════════════════════════════════════════

  Future<void> updateCompany(Company company) async {
    await client.from('companies').update({
      'name': company.name,
      'name_es': company.nameEs,
      'name_en': company.nameEn,
      'logo_url': company.logoUrl,
      'logo_abbr_url': company.logoAbbrUrl,
      'primary_color': company.primaryColorHex,
      'secondary_color': company.secondaryColorHex,
      'contact_email': company.contactEmail,
      'contact_phone': company.contactPhone,
      'contact_whatsapp': company.contactWhatsapp,
      'instagram_url': company.instagramUrl,
      'facebook_url': company.facebookUrl,
      'telegram_url': company.telegramUrl,
      'show_carousel': company.showCarousel,
      'carousel_strategy': company.carouselStrategy,
      'carousel_animation': company.carouselAnimation,
      'currency_symbol': company.currencySymbol,
      'currency_code': company.currencyCode,
      'area_unit': company.areaUnit,
      'country': company.country,
      'state': company.state,
      'city': company.city,
      'show_referral_menu': company.showReferralMenu,
      'show_organic_affiliate': company.showOrganicAffiliate,
      'acquisition_channel': company.acquisitionChannel,
      'referred_by_salesperson': company.referredBySalesperson,
      'referral_email_entered': company.referralEmailEntered,
      'default_sale_commission_pct': company.defaultSaleCommissionPct,
      'default_agency_split_pct': company.defaultAgencySplitPct,
      'default_residential_rental_months': company.defaultResidentialRentalMonths,
      'default_commercial_rental_months': company.defaultCommercialRentalMonths,
      'default_admin_commission_pct': company.defaultAdminCommissionPct,
      'tax_label': company.taxLabel,
      'tax_percentage': company.taxPercentage,
    }).eq('id', company.id);
  }

  Future<void> deleteCompany(String id) async {
    // 0. Limpiar archivos físicos en Storage (Carrusel y Logos)
    try {
      // Listar y borrar imágenes del carrusel
      final List<FileObject> carouselFiles =
          await client.storage.from('property-images').list(path: 'carousel/$id');
      if (carouselFiles.isNotEmpty) {
        final paths = carouselFiles.map((e) => 'carousel/$id/${e.name}').toList();
        await client.storage.from('property-images').remove(paths);
      }

      // Obtener URLs de logos para borrar los archivos físicos
      final companyData = await client
          .from('companies')
          .select('logo_url, logo_abbr_url')
          .eq('id', id)
          .maybeSingle();

      if (companyData != null) {
        final List<String> filesToDelete = [];
        for (final key in ['logo_url', 'logo_abbr_url']) {
          final url = companyData[key] as String?;
          if (url != null && url.contains('property-images')) {
            final uri = Uri.parse(url);
            final path = uri.pathSegments
                .sublist(uri.pathSegments.indexOf('property-images') + 1)
                .join('/');
            filesToDelete.add(path);
          }
        }
        if (filesToDelete.isNotEmpty) {
          await client.storage.from('property-images').remove(filesToDelete);
        }
      }
    } catch (e) {
      debugPrint('Error cleaning up storage for company $id: $e');
    }

    // 1. Borrar dependencias directas
    await client.from('budget_requests').delete().eq('company_id', id);
    await client.from('about_us').delete().eq('company_id', id);
    await client.from('faqs').delete().eq('company_id', id);
    await client.from('app_settings').delete().eq('company_id', id);
    await client.from('carousel_actions').delete().eq('company_id', id);
    await client.from('payments').delete().eq('company_id', id);
    
    // 2. Borrar Inmuebles (esto gatilla borrado de detalles y galería por FK CASCADE)
    // Nota: El borrado físico de fotos de galería de cada propiedad 
    // debería idealmente manejarse aquí también si se quiere limpieza total.
    await client.from('properties').delete().eq('company_id', id);
    
    // 3. Borrar Propietarios
    await client.from('owners').delete().eq('company_id', id);
    
    // 4. Borrar Usuarios (Profiles) asociados a esa empresa
    await client.from('profiles').delete().eq('company_id', id);
    
    // 5. Finalmente borrar la empresa
    await client.from('companies').delete().eq('id', id);
  }
}
