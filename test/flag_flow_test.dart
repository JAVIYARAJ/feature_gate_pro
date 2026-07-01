import 'package:flutter_test/flutter_test.dart';
import 'package:feature_gate_pro/feature_gate_pro.dart';

void main() {
  group('FlagFlow Engine Tests', () {
    setUp(() {
      FlagFlow.registry.clear();
      // Initialize with no providers to test fallback logic
      FlagFlow.initialize();
    });

    test('isEnabled returns defaultValue when not in registry', () {
      expect(FlagFlow.isEnabled('new_checkout', defaultValue: true), isTrue);
      expect(FlagFlow.isEnabled('new_checkout', defaultValue: false), isFalse);
    });

    test('get typed values fall back to defaults correctly', () {
      expect(FlagFlow.getString('welcome_msg', defaultValue: 'Hello'), 'Hello');
      expect(FlagFlow.getInt('max_retries', defaultValue: 3), 3);
      expect(FlagFlow.getDouble('discount', defaultValue: 10.5), 10.5);
      expect(FlagFlow.getList('supported_locales', defaultValue: ['en', 'fr']), ['en', 'fr']);
      expect(FlagFlow.getJson('config', defaultValue: {'theme': 'dark'}), {'theme': 'dark'});
    });

    test('registry overrides default values', () {
      final flag = FeatureFlag(key: 'new_checkout', defaultValue: FlagValue(true));
      FlagFlow.registerFlag(flag);

      // Now if we check, it should return true even if defaultValue passed is false
      expect(FlagFlow.isEnabled('new_checkout', defaultValue: false), isTrue);
      expect(FlagFlow.getBool('new_checkout', defaultValue: false), isTrue);
    });

    test('watch emits values when flags are updated', () async {
      final stream = FlagFlow.watch('promo_banner');
      
      final flag = FeatureFlag(key: 'promo_banner', defaultValue: FlagValue(true));
      
      // Wait for the stream to emit
      expectLater(stream.map((v) => v.asBool), emits(true));
      
      // Add the flag to trigger the watcher
      FlagFlow.registerFlag(flag);
    });

    test('initialize loads cache into registry', () async {
      final mockCache = MockCacheProvider();
      await mockCache.setFlag('cached_key', FeatureFlag(key: 'cached_key', defaultValue: FlagValue('loaded')));
      
      await FlagFlow.initialize(cache: mockCache);
      
      expect(FlagFlow.getString('cached_key'), 'loaded');
    });

    test('merge engine prioritizes providers in order', () async {
      final provider1 = MockFlagProvider({'color': FlagValue('red'), 'size': FlagValue('large')});
      final provider2 = MockFlagProvider({'color': FlagValue('blue'), 'theme': FlagValue('dark')});

      await FlagFlow.initialize(providers: [provider1, provider2]);

      expect(FlagFlow.getString('color'), 'red');
      expect(FlagFlow.getString('size'), 'large');
      expect(FlagFlow.getString('theme'), 'dark');
      expect(FlagFlow.getString('missing', defaultValue: 'default'), 'default');
    });

    test('skips provider if user fails targeting rule', () async {
      final user = UserContext(id: '1', country: 'CA');
      
      final provider1 = MockFlagProvider({
        'feature': FlagValue('us_only_feature')
      }, customMetadata: {
        'feature': {
          'targeting': [{'attribute': 'country', 'operator': '==', 'value': 'US'}]
        }
      });
      
      final provider2 = MockFlagProvider({
        'feature': FlagValue('global_feature')
      });

      await FlagFlow.initialize(providers: [provider1, provider2]);
      FlagFlow.setContext(user);

      // Should skip provider1 because user is CA, and fall back to provider2
      expect(FlagFlow.getString('feature'), 'global_feature');
    });
  });
}

class MockCacheProvider implements CacheProvider {
  final Map<String, FeatureFlag> _flags = {};
  @override
  Duration get cacheTTL => const Duration(days: 1);

  @override
  Future<void> initialize() async {}

  @override
  Future<FeatureFlag?> getFlag(String key) async => _flags[key];

  @override
  Future<Map<String, FeatureFlag>> getAllFlags() async => _flags;

  @override
  Future<void> setFlag(String key, FeatureFlag flag) async {
    _flags[key] = flag;
  }

  @override
  Future<void> setAllFlags(Map<String, FeatureFlag> flags) async {
    _flags.addAll(flags);
  }

  @override
  Future<void> clear() async {
    _flags.clear();
  }
}

class MockFlagProvider implements FlagProvider {
  final Map<String, FlagValue> _flags;
  final Map<String, Map<String, dynamic>>? customMetadata;
  
  MockFlagProvider(this._flags, {this.customMetadata});

  @override
  Future<void> initialize() async {}

  @override
  Future<void> fetchAndActivate() async {}

  @override
  FeatureFlag? getFlag(String key) {
    if (_flags.containsKey(key)) {
      FlagMetadata? metadata;
      if (customMetadata != null && customMetadata!.containsKey(key)) {
        metadata = FlagMetadata(custom: customMetadata![key]);
      }
      return FeatureFlag(key: key, defaultValue: _flags[key]!, metadata: metadata);
    }
    return null;
  }

  @override
  Stream<String>? get onFlagChanged => null;
}
