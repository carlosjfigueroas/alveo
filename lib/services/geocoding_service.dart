import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class GeocodingService {
  static const _nominatimBase = 'https://nominatim.openstreetmap.org';
  static const _userAgent = 'AlveoApp/1.0';

  /// Converts a human-readable address to [LatLng] coordinates.
  /// Returns null if not found or on error.
  static Future<LatLng?> searchAddress(String address) async {
    if (address.trim().isEmpty) return null;
    try {
      final uri = Uri.parse(_nominatimBase).replace(
        path: '/search',
        queryParameters: {
          'q': address,
          'format': 'json',
          'limit': '1',
        },
      );
      final response = await http.get(uri, headers: {
        'User-Agent': _userAgent,
        'Accept-Language': 'es,en',
      }).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          final lat = double.tryParse(data[0]['lat'] ?? '');
          final lon = double.tryParse(data[0]['lon'] ?? '');
          if (lat != null && lon != null) return LatLng(lat, lon);
        }
      }
    } catch (e) {
      debugPrint('[GeocodingService] searchAddress error: $e');
    }
    return null;
  }

  /// Converts [LatLng] coordinates to a human-readable address string.
  /// Returns null on error.
  static Future<String?> reverseGeocode(LatLng point) async {
    try {
      final uri = Uri.parse(_nominatimBase).replace(
        path: '/reverse',
        queryParameters: {
          'lat': point.latitude.toString(),
          'lon': point.longitude.toString(),
          'format': 'json',
        },
      );
      final response = await http.get(uri, headers: {
        'User-Agent': _userAgent,
        'Accept-Language': 'es,en',
      }).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['display_name'] as String?;
      }
    } catch (e) {
      debugPrint('[GeocodingService] reverseGeocode error: $e');
    }
    return null;
  }
}
