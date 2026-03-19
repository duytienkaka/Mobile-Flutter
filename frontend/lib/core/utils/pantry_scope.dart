import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class PantryKeywordRule {
  final String key;
  final String label;
  final bool enabled;
  final bool isCustom;

  const PantryKeywordRule({
    required this.key,
    required this.label,
    required this.enabled,
    required this.isCustom,
  });
}

class PantryScope {
  const PantryScope._();

  static const String _disabledKeywordsStorageKey =
      'pantry_scope_disabled_keywords';
  static const String _customKeywordsStorageKey =
      'pantry_scope_custom_keywords';

  static const Map<String, String> _defaultKeywords = {
    'muoi': 'Muối',
    'duong': 'Đường',
    'hat nem': 'Hạt nêm',
    'nuoc mam': 'Nước mắm',
    'mam': 'Mắm',
    'dau an': 'Dầu ăn',
    'dau hao': 'Dầu hào',
    'xi dau': 'Xì dầu',
    'nuoc tuong': 'Nước tương',
    'tuong ot': 'Tương ớt',
    'tuong ca': 'Tương cà',
    'giam': 'Giấm',
    'bot ngot': 'Bột ngọt',
    'tieu': 'Tiêu',
    'ot bot': 'Ớt bột',
    'sa te': 'Sa tế',
  };

  static final Map<String, String> _keywordLabels = {
    ..._defaultKeywords,
  };

  static final Map<String, bool> _keywordEnabled = {
    for (final key in _defaultKeywords.keys) key: true,
  };

  static bool _initialized = false;

  static Future<void> ensureInitialized() async {
    if (_initialized) return;
    final prefs = await SharedPreferences.getInstance();

    final customRaw = prefs.getStringList(_customKeywordsStorageKey) ?? const [];
    for (final item in customRaw) {
      try {
        final decoded = jsonDecode(item);
        if (decoded is! Map<String, dynamic>) continue;
        final key = (decoded['key'] ?? '').toString().trim();
        final label = (decoded['label'] ?? '').toString().trim();
        if (key.isEmpty || label.isEmpty) continue;
        _keywordLabels[key] = label;
        _keywordEnabled.putIfAbsent(key, () => true);
      } catch (_) {
        continue;
      }
    }

    final disabled = prefs.getStringList(_disabledKeywordsStorageKey) ?? const [];
    final disabledSet = disabled.map((e) => e.trim()).toSet();
    for (final keyword in _keywordLabels.keys) {
      _keywordEnabled[keyword] = !disabledSet.contains(keyword);
    }
    _initialized = true;
  }

  static List<PantryKeywordRule> getRules() {
    return _keywordLabels.entries
        .map(
          (entry) => PantryKeywordRule(
            key: entry.key,
            label: entry.value,
            enabled: _keywordEnabled[entry.key] ?? true,
            isCustom: !_defaultKeywords.containsKey(entry.key),
          ),
        )
        .toList()
      ..sort((a, b) => a.label.compareTo(b.label));
  }

  static Future<PantryKeywordRule?> addKeyword(String label) async {
    await ensureInitialized();
    final rawLabel = label.trim();
    final key = _normalize(rawLabel);
    if (rawLabel.isEmpty || key.isEmpty) return null;
    if (_keywordLabels.containsKey(key)) {
      final current = _keywordLabels[key] ?? rawLabel;
      _keywordEnabled[key] = true;
      await _saveState();
      return PantryKeywordRule(
        key: key,
        label: current,
        enabled: true,
        isCustom: !_defaultKeywords.containsKey(key),
      );
    }

    _keywordLabels[key] = rawLabel;
    _keywordEnabled[key] = true;
    await _saveState();
    return PantryKeywordRule(
      key: key,
      label: rawLabel,
      enabled: true,
      isCustom: true,
    );
  }

  static Future<bool> removeCustomKeyword(String keyword) async {
    await ensureInitialized();
    if (_defaultKeywords.containsKey(keyword)) {
      return false;
    }
    final existed = _keywordLabels.remove(keyword) != null;
    _keywordEnabled.remove(keyword);
    if (!existed) {
      return false;
    }
    await _saveState();
    return true;
  }

  static Future<void> resetToDefault() async {
    await ensureInitialized();
    _keywordLabels
      ..clear()
      ..addAll(_defaultKeywords);
    _keywordEnabled
      ..clear()
      ..addEntries(_defaultKeywords.keys.map((key) => MapEntry(key, true)));
    await _saveState();
  }

  static Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();

    final disabled = _keywordEnabled.entries
        .where((entry) => !entry.value)
        .map((entry) => entry.key)
        .toList();
    await prefs.setStringList(_disabledKeywordsStorageKey, disabled);

    final custom = _keywordLabels.entries
        .where((entry) => !_defaultKeywords.containsKey(entry.key))
        .map(
          (entry) => jsonEncode({
            'key': entry.key,
            'label': entry.value,
          }),
        )
        .toList();
    await prefs.setStringList(_customKeywordsStorageKey, custom);
  }

  static Future<void> setKeywordEnabled(String keyword, bool enabled) async {
    await ensureInitialized();
    if (!_keywordLabels.containsKey(keyword)) return;
    _keywordEnabled[keyword] = enabled;
    await _saveState();
  }

  static bool isPantryManagedIngredient(String name) {
    final normalized = _normalize(name);
    if (normalized.isEmpty) return true;
    for (final keyword in _keywordLabels.keys) {
      final enabled = _keywordEnabled[keyword] ?? true;
      if (!enabled) {
        continue;
      }
      if (normalized.contains(keyword)) {
        return false;
      }
    }
    return true;
  }

  static String _normalize(String input) {
    var text = input.trim().toLowerCase();
    if (text.isEmpty) return text;

    const map = {
      'á': 'a', 'à': 'a', 'ả': 'a', 'ã': 'a', 'ạ': 'a',
      'ă': 'a', 'ắ': 'a', 'ằ': 'a', 'ẳ': 'a', 'ẵ': 'a', 'ặ': 'a',
      'â': 'a', 'ấ': 'a', 'ầ': 'a', 'ẩ': 'a', 'ẫ': 'a', 'ậ': 'a',
      'é': 'e', 'è': 'e', 'ẻ': 'e', 'ẽ': 'e', 'ẹ': 'e',
      'ê': 'e', 'ế': 'e', 'ề': 'e', 'ể': 'e', 'ễ': 'e', 'ệ': 'e',
      'í': 'i', 'ì': 'i', 'ỉ': 'i', 'ĩ': 'i', 'ị': 'i',
      'ó': 'o', 'ò': 'o', 'ỏ': 'o', 'õ': 'o', 'ọ': 'o',
      'ô': 'o', 'ố': 'o', 'ồ': 'o', 'ổ': 'o', 'ỗ': 'o', 'ộ': 'o',
      'ơ': 'o', 'ớ': 'o', 'ờ': 'o', 'ở': 'o', 'ỡ': 'o', 'ợ': 'o',
      'ú': 'u', 'ù': 'u', 'ủ': 'u', 'ũ': 'u', 'ụ': 'u',
      'ư': 'u', 'ứ': 'u', 'ừ': 'u', 'ử': 'u', 'ữ': 'u', 'ự': 'u',
      'ý': 'y', 'ỳ': 'y', 'ỷ': 'y', 'ỹ': 'y', 'ỵ': 'y',
      'đ': 'd',
    };

    final buffer = StringBuffer();
    for (final rune in text.runes) {
      final ch = String.fromCharCode(rune);
      buffer.write(map[ch] ?? ch);
    }

    return buffer
        .toString()
        .replaceAll(RegExp(r'[^a-z0-9 ]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
