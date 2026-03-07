import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/prayer_session.dart';

class SyncService {
  static const _defaultBaseUrl = 'https://xmanstudio.com/api/aipray';
  static const _queueKey = 'aipray_sync_queue';
  static const _syncTokenKey = 'aipray_sync_token';

  final String baseUrl;
  final http.Client _client;
  Timer? _retryTimer;
  bool _isSyncing = false;

  SyncService({this.baseUrl = _defaultBaseUrl}) : _client = http.Client();

  void dispose() {
    _retryTimer?.cancel();
    _client.close();
  }

  /// Try to flush any queued items on startup
  Future<void> init() async {
    _scheduleRetry();
  }

  // === Offline Queue ===

  Future<void> _enqueue(String type, Map<String, dynamic> payload) async {
    final prefs = await SharedPreferences.getInstance();
    final queue = prefs.getStringList(_queueKey) ?? [];
    queue.add(jsonEncode({
      'type': type,
      'payload': payload,
      'queued_at': DateTime.now().toIso8601String(),
    }));
    await prefs.setStringList(_queueKey, queue);
  }

  Future<void> flushQueue() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final queue = prefs.getStringList(_queueKey) ?? [];
      if (queue.isEmpty) return;

      final remaining = <String>[];
      for (final item in queue) {
        final data = jsonDecode(item) as Map<String, dynamic>;
        final ok = await _sendQueuedItem(data);
        if (!ok) remaining.add(item);
      }
      await prefs.setStringList(_queueKey, remaining);
    } catch (_) {
      // Will retry later
    } finally {
      _isSyncing = false;
    }
  }

  Future<bool> _sendQueuedItem(Map<String, dynamic> data) async {
    final type = data['type'] as String;
    final payload = data['payload'] as Map<String, dynamic>;

    switch (type) {
      case 'session':
        return _postJson('$baseUrl/sessions', payload);
      case 'audio':
        return _postJson('$baseUrl/audio/upload', payload);
      default:
        return true; // Unknown type, discard
    }
  }

  void _scheduleRetry() {
    _retryTimer?.cancel();
    _retryTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      flushQueue();
    });
  }

  // === Chant Sync ===

  Future<Map<String, dynamic>?> fetchChantUpdates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final syncToken = prefs.getString(_syncTokenKey);

      final uri = Uri.parse('$baseUrl/chants/sync');
      final response = await _client.post(
        uri,
        headers: _headers(),
        body: jsonEncode({
          if (syncToken != null) 'sync_token': syncToken,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body) as Map<String, dynamic>;
        // Store new sync token
        final newToken = result['sync_token'] as String?;
        if (newToken != null) {
          await prefs.setString(_syncTokenKey, newToken);
        }
        return result;
      }
    } catch (e) {
      debugPrint('Sync chants failed: $e');
    }
    return null;
  }

  // === Session Upload (with offline queue) ===

  Future<bool> uploadSession(PrayerSession session) async {
    final payload = session.toJson();
    final ok = await _postJson('$baseUrl/sessions', payload);
    if (!ok) {
      // Queue for later
      await _enqueue('session', payload);
    }
    return ok;
  }

  // === Audio Upload for AI Training (with offline queue) ===

  Future<bool> uploadAudioSample({
    required String chantId,
    required int lineIndex,
    required String audioBase64,
    required int durationMs,
    required String format,
    String? deviceInfo,
  }) async {
    final payload = {
      'chant_id': chantId,
      'line_index': lineIndex,
      'audio_data': audioBase64,
      'duration_ms': durationMs,
      'format': format,
      'device_info': deviceInfo ?? 'flutter_app',
    };

    final ok = await _postJson('$baseUrl/audio/upload', payload);
    if (!ok) {
      await _enqueue('audio', payload);
    }
    return ok;
  }

  // === Model Updates ===

  Future<Map<String, dynamic>?> checkModelUpdate(
      {String? currentVersion}) async {
    try {
      var uri = Uri.parse('$baseUrl/models/latest');
      if (currentVersion != null) {
        uri = uri.replace(queryParameters: {
          'current_version': currentVersion,
        });
      }
      final response = await _client
          .get(uri, headers: _headers())
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Model check failed: $e');
    }
    return null;
  }

  // === Community Chants ===

  Future<List<Map<String, dynamic>>?> fetchCommunityChants() async {
    try {
      final uri = Uri.parse('$baseUrl/chants/community');
      final response = await _client
          .get(uri, headers: _headers())
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['chants'] as List?)?.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      debugPrint('Community chants fetch failed: $e');
    }
    return null;
  }

  // === Global Stats ===

  Future<Map<String, dynamic>?> fetchStats() async {
    try {
      final uri = Uri.parse('$baseUrl/stats');
      final response = await _client
          .get(uri, headers: _headers())
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Stats fetch failed: $e');
    }
    return null;
  }

  // === Helpers ===

  Future<bool> _postJson(String url, Map<String, dynamic> body) async {
    try {
      final response = await _client
          .post(
            Uri.parse(url),
            headers: _headers(),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('POST $url failed: $e');
      return false;
    }
  }

  Map<String, String> _headers() => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-App-Version': '1.0.0',
      };
}
