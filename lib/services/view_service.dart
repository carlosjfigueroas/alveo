import 'package:supabase_flutter/supabase_flutter.dart';

class ViewService {
  static final _client = Supabase.instance.client;
  static final Set<String> _sessionViewed = <String>{};

  /// Session-storage key for a given property so we register at most 1 view per tab session.
  static String _sessionKey(String propertyId) => 'alveo_view_$propertyId';

  /// Records a view. Silently skips if this tab already registered a view for this property.
  static Future<void> recordView({
    required String propertyId,
    required String companyId,
    required String visitorId,
  }) async {
    if (propertyId.isEmpty || visitorId.isEmpty) return;

    // Session-based dedup: skip if already viewed this tab session
    final key = _sessionKey(propertyId);
    if (_sessionViewed.contains(key)) return;

    try {
      await _client.from('property_views').upsert({
        'property_id': propertyId,
        'visitor_id': visitorId,
        'company_id': companyId,
      }, onConflict: 'property_id,visitor_id');

      // Mark as viewed for this session
      _sessionViewed.add(key);
    } catch (e) {
      // Non-critical — silently ignore
    }
  }

  /// Returns a map of property_id -> views_count for a list of property IDs.
  static Future<Map<String, int>> batchGetViewCounts(
      List<String> propertyIds) async {
    if (propertyIds.isEmpty) return {};
    try {
      final res = await _client
          .from('property_views_count')
          .select()
          .inFilter('property_id', propertyIds);

      final map = <String, int>{};
      for (var row in (res as List)) {
        map[row['property_id']] = (row['views_count'] as num).toInt();
      }
      return map;
    } catch (e) {
      return {};
    }
  }

  /// Returns the top N most-viewed properties for a company (with gallery).
  static Future<List<Map<String, dynamic>>> getTopViewedProperties(
      String companyId,
      {int limit = 5}) async {
    try {
      final res = await _client
          .from('top_viewed_properties')
          .select()
          .eq('company_id', companyId)
          .limit(limit);

      final List<Map<String, dynamic>> properties =
          List<Map<String, dynamic>>.from(res);
      if (properties.isEmpty) return [];

      final propertyIds = properties.map((p) => p['id']).toList();
      final galleryRes = await _client
          .from('gallery')
          .select()
          .inFilter('property_id', propertyIds);

      for (var p in properties) {
        p['gallery'] = (galleryRes as List)
            .where((g) => g['property_id'] == p['id'])
            .toList();
      }

      return properties;
    } catch (e) {
      return [];
    }
  }
}
