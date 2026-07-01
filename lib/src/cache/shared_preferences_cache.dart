import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/cache_provider.dart';
import '../models/feature_flag.dart';

/// A cache provider implementation using SharedPreferences.
class SharedPreferencesCacheProvider implements CacheProvider {
  static const String _prefix = 'flagflow_cache_';
  
  @override
  final Duration cacheTTL;
  
  SharedPreferences? _prefs;

  SharedPreferencesCacheProvider({
    this.cacheTTL = const Duration(hours: 24),
  });

  @override
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  @override
  Future<FeatureFlag?> getFlag(String key) async {
    if (_prefs == null) return null;
    
    final jsonString = _prefs!.getString('$_prefix$key');
    if (jsonString == null) return null;

    try {
      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
      final timestamp = decoded['timestamp'] as int;
      final now = DateTime.now().millisecondsSinceEpoch;

      if (now - timestamp > cacheTTL.inMilliseconds) {
        // Cache expired
        await _prefs!.remove('$_prefix$key');
        return null;
      }

      return FeatureFlag.fromJson(decoded['flag'] as Map<String, dynamic>);
    } catch (e) {
      // Corrupted cache or invalid schema
      await _prefs!.remove('$_prefix$key');
      return null;
    }
  }

  @override
  Future<Map<String, FeatureFlag>> getAllFlags() async {
    final Map<String, FeatureFlag> flags = {};
    if (_prefs == null) return flags;

    final keys = _prefs!.getKeys().where((k) => k.startsWith(_prefix)).toList();

    for (final key in keys) {
      final originalKey = key.replaceFirst(_prefix, '');
      final flag = await getFlag(originalKey);
      if (flag != null) {
        flags[originalKey] = flag;
      }
    }

    return flags;
  }

  @override
  Future<void> setFlag(String key, FeatureFlag flag) async {
    if (_prefs == null) return;

    final payload = {
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'flag': flag.toJson(),
    };

    await _prefs!.setString('$_prefix$key', jsonEncode(payload));
  }

  @override
  Future<void> setAllFlags(Map<String, FeatureFlag> flags) async {
    for (var entry in flags.entries) {
      await setFlag(entry.key, entry.value);
    }
  }

  @override
  Future<void> clear() async {
    if (_prefs == null) return;
    
    final keys = _prefs!.getKeys().where((k) => k.startsWith(_prefix)).toList();
    for (final key in keys) {
      await _prefs!.remove(key);
    }
  }
}
