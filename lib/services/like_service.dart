import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class LikeService {
  static final _client = Supabase.instance.client;
  static String? _visitorId;

  /// Obtiene el visitor_id de localStorage o genera uno nuevo.
  static String getOrCreateVisitorId() {
    _visitorId ??= const Uuid().v4();
    return _visitorId!;
  }

  /// Toggle del like: INSERT o DELETE según el estado actual.
  static Future<bool> toggleLike({
    required String visitorId,
    required String propertyId,
    required String companyId,
  }) async {
    try {
      // 1. Verificar si ya existe
      final existing = await _client
          .from('property_likes')
          .select()
          .eq('visitor_id', visitorId)
          .eq('property_id', propertyId)
          .maybeSingle();

      if (existing != null) {
        // 2. Si existe, borrar (un-like)
        await _client
            .from('property_likes')
            .delete()
            .eq('visitor_id', visitorId)
            .eq('property_id', propertyId);
        return false;
      } else {
        // 3. Si no existe, insertar (like)
        await _client.from('property_likes').insert({
          'visitor_id': visitorId,
          'property_id': propertyId,
          'company_id': companyId,
        });
        return true;
      }
    } catch (e) {
      debugPrint('Error toggleLike: $e');
      rethrow;
    }
  }

  /// Obtiene los conteos de likes para una lista de propiedades.
  /// Retorna un mapa: property_id -> likes_count.
  static Future<Map<String, int>> batchGetLikeCounts(List<String> propertyIds) async {
    if (propertyIds.isEmpty) return {};
    try {
      final res = await _client
          .from('property_likes_count')
          .select()
          .inFilter('property_id', propertyIds);

      final map = <String, int>{};
      for (var row in (res as List)) {
        map[row['property_id']] = (row['likes_count'] as num).toInt();
      }
      return map;
    } catch (e) {
      debugPrint('Error batchGetLikeCounts: $e');
      return {};
    }
  }

  /// Verifica qué propiedades de una lista ya tienen like de este visitante.
  /// Retorna un conjunto de IDs.
  static Future<Set<String>> batchGetLikedByVisitor(String visitorId, List<String> propertyIds) async {
    if (propertyIds.isEmpty) return {};
    try {
      final res = await _client
          .from('property_likes')
          .select('property_id')
          .eq('visitor_id', visitorId)
          .inFilter('property_id', propertyIds);

      final set = <String>{};
      for (var row in (res as List)) {
        set.add(row['property_id']);
      }
      return set;
    } catch (e) {
      debugPrint('Error batchGetLikedByVisitor: $e');
      return {};
    }
  }

  /// Obtiene el Top 10 de propiedades más populares de una empresa.
  static Future<List<Map<String, dynamic>>> getTopLikedProperties(String companyId, {int limit = 10}) async {
    try {
      final res = await _client
          .from('top_liked_properties')
          .select()
          .eq('company_id', companyId)
          .limit(limit);
          
      final List<Map<String, dynamic>> properties = List<Map<String, dynamic>>.from(res);
      if (properties.isEmpty) return [];

      // 2. Traer las imágenes de la galería para estas propiedades
      final propertyIds = properties.map((p) => p['id']).toList();
      final galleryRes = await _client
          .from('gallery')
          .select()
          .inFilter('property_id', propertyIds);
          
      // 3. Adjuntar la lista de imágenes a cada propiedad como 'gallery'
      for (var p in properties) {
        p['gallery'] = (galleryRes as List).where((g) => g['property_id'] == p['id']).toList();
      }
      
      return properties;
    } catch (e) {
      debugPrint('Error getTopLikedProperties: $e');
      return [];
    }
  }
}
