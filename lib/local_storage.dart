import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'models.dart';

class LocalStorageService {
  static const _favKey = 'kinkin_favorites_v1';
  static const _historyKey = 'kinkin_history_v1';
  static const _directionsKey = 'kinkin_directions_v1';

  static Map<String, Restaurant> loadFavorites() {
    try {
      final raw = html.window.localStorage[_favKey];
      if (raw == null || raw.isEmpty) return {};
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((key, value) =>
          MapEntry(key, Restaurant.fromJson(value as Map<String, dynamic>)));
    } catch (_) {
      return {};
    }
  }

  static void saveFavorites(Map<String, Restaurant> favorites) {
    try {
      final encoded = jsonEncode(
          favorites.map((key, value) => MapEntry(key, value.toJson())));
      html.window.localStorage[_favKey] = encoded;
    } catch (_) {}
  }

  static List<Restaurant> loadHistory() {
    try {
      final raw = html.window.localStorage[_historyKey];
      if (raw == null || raw.isEmpty) return [];
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((item) => Restaurant.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static void saveHistory(List<Restaurant> history) {
    try {
      // เก็บประวัติล่าสุดสูงสุด 30 รายการ
      final trimmed =
          history.length > 30 ? history.sublist(history.length - 30) : history;
      final encoded = jsonEncode(trimmed.map((r) => r.toJson()).toList());
      html.window.localStorage[_historyKey] = encoded;
    } catch (_) {}
  }

  static int loadDirectionsCount() {
    try {
      return int.tryParse(html.window.localStorage[_directionsKey] ?? '0') ?? 0;
    } catch (_) {
      return 0;
    }
  }

  static void saveDirectionsCount(int count) {
    try {
      html.window.localStorage[_directionsKey] = '$count';
    } catch (_) {}
  }
}