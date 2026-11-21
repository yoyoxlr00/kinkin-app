import 'package:web/web.dart' as web;
import 'storage_migration.dart';

// The previous web implementation wrote raw JSON. Shared preferences stores
// our JSON strings with an additional JSON string encoding.
void migrateWebStorage(Iterable<String> keys) {
  for (final key in keys) {
    final raw = web.window.localStorage.getItem(key);
    if (raw == null) continue;
    final migrated = normalizeLegacyStorage(raw);
    if (migrated != raw) {
      web.window.localStorage.setItem(key, migrated);
    }
  }
}
