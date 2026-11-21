import 'dart:convert';

String normalizeLegacyStorage(String raw) {
  try {
    if (jsonDecode(raw) is String) return raw;
  } on FormatException {
    // Preserve malformed data; the normal loaders handle it.
  }
  return jsonEncode(raw);
}
