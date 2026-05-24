import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class VisitorService {
  static final _client = Supabase.instance.client;

  /// Registers a visit by doing an UPSERT on the visitor_sessions table.
  /// This ensures that last_seen_at is updated and no duplicate rows are created.
  static Future<void> registerVisit({
    required String visitorId,
    required String companyId,
  }) async {
    try {
      await _client.from('visitor_sessions').upsert({
        'visitor_id': visitorId,
        'company_id': companyId,
        'last_seen_at': DateTime.now().toIso8601String(),
      }, onConflict: 'visitor_id, company_id');
    } catch (e) {
      debugPrint('Error registering visit: $e');
    }
  }

  /// Gets the count of unique visitors in the last 7 days for a company.
  static Future<int> getWeeklyCount(String companyId) async {
    try {
      final res = await _client
          .from('weekly_visitors')
          .select('visitor_count')
          .eq('company_id', companyId)
          .maybeSingle();
      
      if (res == null) return 0;
      return (res['visitor_count'] as num).toInt();
    } catch (e) {
      debugPrint('Error getting weekly visitor count: $e');
      return 0;
    }
  }
}
