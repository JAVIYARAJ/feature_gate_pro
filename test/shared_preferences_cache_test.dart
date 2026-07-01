import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:feature_gate_pro/feature_gate_pro.dart';

void main() {
  group('SharedPreferencesCacheProvider Tests', () {
    late SharedPreferencesCacheProvider cache;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      cache = SharedPreferencesCacheProvider(cacheTTL: const Duration(seconds: 1));
      await cache.initialize();
    });

    test('stores and retrieves a flag', () async {
      final flag = FeatureFlag(key: 'test_flag', defaultValue: FlagValue(true));
      await cache.setFlag('test_flag', flag);

      final retrieved = await cache.getFlag('test_flag');
      expect(retrieved, isNotNull);
      expect(retrieved!.key, 'test_flag');
      expect(retrieved.defaultValue.asBool, isTrue);
    });

    test('getAllFlags retrieves all stored flags', () async {
      await cache.setAllFlags({
        'flag1': FeatureFlag(key: 'flag1', defaultValue: FlagValue(1)),
        'flag2': FeatureFlag(key: 'flag2', defaultValue: FlagValue(2)),
      });

      final allFlags = await cache.getAllFlags();
      expect(allFlags.length, 2);
      expect(allFlags['flag1']!.defaultValue.asInt, 1);
      expect(allFlags['flag2']!.defaultValue.asInt, 2);
    });

    test('handles corrupted cache gracefully', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('flagflow_cache_corrupted', 'invalid_json');

      final retrieved = await cache.getFlag('corrupted');
      expect(retrieved, isNull);

      // Verify it was removed
      expect(prefs.containsKey('flagflow_cache_corrupted'), isFalse);
    });

    test('handles invalid schema gracefully', () async {
      final prefs = await SharedPreferences.getInstance();
      // Valid JSON but missing 'flag' key
      await prefs.setString('flagflow_cache_schema', '{"timestamp": 123}');

      final retrieved = await cache.getFlag('schema');
      expect(retrieved, isNull);

      // Verify it was removed
      expect(prefs.containsKey('flagflow_cache_schema'), isFalse);
    });

    test('expires cache based on TTL', () async {
      final flag = FeatureFlag(key: 'expire_test', defaultValue: FlagValue('stale'));
      await cache.setFlag('expire_test', flag);

      // Retrieve immediately should work
      var retrieved = await cache.getFlag('expire_test');
      expect(retrieved, isNotNull);

      // Wait for TTL (1 second) + small buffer
      await Future<void>.delayed(const Duration(milliseconds: 1100));

      // Retrieve after expiration should return null and clear it
      retrieved = await cache.getFlag('expire_test');
      expect(retrieved, isNull);
    });

    test('clears cache successfully', () async {
      await cache.setFlag('flag1', FeatureFlag(key: 'flag1', defaultValue: FlagValue(true)));
      await cache.clear();

      final allFlags = await cache.getAllFlags();
      expect(allFlags, isEmpty);
    });
  });
}
