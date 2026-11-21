import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';
import 'storage_migration_stub.dart'
    if (dart.library.js_interop) 'storage_migration_web.dart';

class LocalStorageService {
  static late SharedPreferencesWithCache _prefs;

  static Future<void> init() async {
    migrateWebStorage({_favKey, _historyKey, _directionsKey});
    _prefs = await SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(
        allowList: {_favKey, _historyKey, _directionsKey},
      ),
    );
  }

  static const _favKey = 'kinkin_favorites_v1';
  static const _historyKey = 'kinkin_history_v1';
  static const _directionsKey = 'kinkin_directions_v1';

  static Map<String, Restaurant> loadFavorites() {
    try {
      final raw = _prefs.getString(_favKey);
      if (raw == null || raw.isEmpty) return {};
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((key, value) =>
          MapEntry(key, Restaurant.fromJson(value as Map<String, dynamic>)));
    } catch (_) {
      return {};
    }
  }

  static Future<void> saveFavorites(Map<String, Restaurant> favorites) async {
    try {
      final encoded = jsonEncode(
          favorites.map((key, value) => MapEntry(key, value.toJson())));
      await _prefs.setString(_favKey, encoded);
    } catch (_) {}
  }

  static List<Restaurant> loadHistory() {
    try {
      final raw = _prefs.getString(_historyKey);
      if (raw == null || raw.isEmpty) return [];
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((item) => Restaurant.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveHistory(List<Restaurant> history) async {
    try {
      // เก็บประวัติล่าสุดสูงสุด 30 รายการ
      final trimmed =
          history.length > 30 ? history.sublist(history.length - 30) : history;
      final encoded = jsonEncode(trimmed.map((r) => r.toJson()).toList());
      await _prefs.setString(_historyKey, encoded);
    } catch (_) {}
  }

  static int loadDirectionsCount() {
    try {
      return int.tryParse(_prefs.getString(_directionsKey) ?? '0') ?? 0;
    } catch (_) {
      return 0;
    }
  }

  static Future<void> saveDirectionsCount(int count) async {
    try {
      await _prefs.setString(_directionsKey, '$count');
    } catch (_) {}
  }
}
