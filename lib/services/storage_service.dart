import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/prayer_session.dart';

class StorageService {
  static const _sessionsKey = 'prayer_sessions';
  static const _favoritesKey = 'favorite_chants';
  static const _settingsPrefix = 'setting_';

  late final SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // === Prayer Sessions ===
  List<PrayerSession> getSessions() {
    final raw = _prefs.getString(_sessionsKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => PrayerSession.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
  }

  Future<void> saveSession(PrayerSession session) async {
    final sessions = getSessions();
    final idx = sessions.indexWhere((s) => s.id == session.id);
    if (idx >= 0) {
      sessions[idx] = session;
    } else {
      sessions.insert(0, session);
    }
    await _prefs.setString(
      _sessionsKey,
      jsonEncode(sessions.map((s) => s.toJson()).toList()),
    );
  }

  Future<void> deleteSession(String id) async {
    final sessions = getSessions().where((s) => s.id != id).toList();
    await _prefs.setString(
      _sessionsKey,
      jsonEncode(sessions.map((s) => s.toJson()).toList()),
    );
  }

  // === Favorites ===
  Set<String> getFavorites() {
    return _prefs.getStringList(_favoritesKey)?.toSet() ?? {};
  }

  Future<void> toggleFavorite(String chantId) async {
    final favs = getFavorites();
    if (favs.contains(chantId)) {
      favs.remove(chantId);
    } else {
      favs.add(chantId);
    }
    await _prefs.setStringList(_favoritesKey, favs.toList());
  }

  bool isFavorite(String chantId) => getFavorites().contains(chantId);

  // === Settings ===
  T? getSetting<T>(String key) {
    final v = _prefs.get('$_settingsPrefix$key');
    return v is T ? v : null;
  }

  Future<void> setSetting<T>(String key, T value) async {
    final k = '$_settingsPrefix$key';
    switch (value) {
      case bool v:
        await _prefs.setBool(k, v);
      case int v:
        await _prefs.setInt(k, v);
      case double v:
        await _prefs.setDouble(k, v);
      case String v:
        await _prefs.setString(k, v);
      default:
        await _prefs.setString(k, jsonEncode(value));
    }
  }

  // === Stats ===
  int get totalSessions => getSessions().length;

  Duration get totalPrayerTime {
    return getSessions().fold(
      Duration.zero,
      (sum, s) => sum + s.duration,
    );
  }

  int get totalRounds {
    return getSessions().fold(0, (sum, s) => sum + s.roundsCompleted);
  }

  String get totalPrayerTimeFormatted {
    final d = totalPrayerTime;
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }
}
