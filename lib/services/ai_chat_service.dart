import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AiChatService {
  static final _client = Supabase.instance.client;

  /// Sends a text message to Ava and returns the response.
  static Future<Map<String, dynamic>> sendMessage({
    required String message,
    required String companyId,
    required String locale,
    required String aiModel,
    List<Map<String, String>>? history,
  }) async {
    try {
      final response = await _client.functions.invoke(
        'alveo-ai-chat',
        body: {
          'type': 'text',
          'message': message,
          'company_id': companyId,
          'locale': locale,
          'ai_model': aiModel,
          'history': history ?? [],
        },
      );

      if (response.status != 200) {
        final errorData = response.data;
        final errorMsg = errorData is Map ? errorData['error'] ?? 'Unknown error' : 'Error ${response.status}';
        return {'error': errorMsg};
      }

      final data = response.data;
      if (data is Map<String, dynamic>) {
        return data;
      }
      // If data is a string, try to parse it
      if (data is String) {
        try {
          return jsonDecode(data) as Map<String, dynamic>;
        } catch (_) {
          return {'reply': data};
        }
      }
      return {'reply': data.toString()};
    } catch (e) {
      debugPrint('AiChatService.sendMessage error: $e');
      return {'error': e.toString()};
    }
  }

  /// Sends a voice note (base64 encoded) to Ava and returns the response.
  static Future<Map<String, dynamic>> sendVoiceNote({
    required String audioBase64,
    required String mimeType,
    required String companyId,
    required String locale,
    required String aiModel,
    List<Map<String, String>>? history,
  }) async {
    try {
      final response = await _client.functions.invoke(
        'alveo-ai-chat',
        body: {
          'type': 'audio',
          'audio_base64': audioBase64,
          'mime_type': mimeType,
          'company_id': companyId,
          'locale': locale,
          'ai_model': aiModel,
          'history': history ?? [],
        },
      );

      if (response.status != 200) {
        final errorData = response.data;
        final errorMsg = errorData is Map ? errorData['error'] ?? 'Unknown error' : 'Error ${response.status}';
        return {'error': errorMsg};
      }

      final data = response.data;
      if (data is Map<String, dynamic>) {
        return data;
      }
      if (data is String) {
        try {
          return jsonDecode(data) as Map<String, dynamic>;
        } catch (_) {
          return {'reply': data};
        }
      }
      return {'reply': data.toString()};
    } catch (e) {
      debugPrint('AiChatService.sendVoiceNote error: $e');
      return {'error': e.toString()};
    }
  }
}
