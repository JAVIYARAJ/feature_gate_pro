import 'package:flutter_test/flutter_test.dart';
import 'package:feature_gate_pro/feature_gate_pro.dart';

void main() {
  group('Runtime Overrides Tests', () {
    setUp(() {
      FlagFlow.registry.clear();
      FlagFlow.clearOverrides();
      FlagFlow.dispose();
    });

    test('setOverride bypasses providers and registry', () async {
      // Setup a provider that defaults to false
      final provider = MockSimpleProvider({'feature_x': FlagValue(false)});
      await FlagFlow.initialize(providers: [provider]);

      expect(FlagFlow.getBool('feature_x'), isFalse);

      // Set override to true
      FlagFlow.setOverride('feature_x', FlagValue(true));

      expect(FlagFlow.getBool('feature_x'), isTrue);
      
      // Override takes precedence over everything
      expect(FlagFlow.overrides['feature_x']?.asBool, isTrue);
    });

    test('removeOverride restores default behavior', () async {
      final provider = MockSimpleProvider({'feature_x': FlagValue(false)});
      await FlagFlow.initialize(providers: [provider]);

      FlagFlow.setOverride('feature_x', FlagValue(true));
      expect(FlagFlow.getBool('feature_x'), isTrue);

      FlagFlow.removeOverride('feature_x');
      expect(FlagFlow.getBool('feature_x'), isFalse);
    });

    test('clearOverrides removes all overrides', () async {
      await FlagFlow.initialize(providers: []);
      
      FlagFlow.setOverride('a', FlagValue(true));
      FlagFlow.setOverride('b', FlagValue(true));

      expect(FlagFlow.getBool('a'), isTrue);
      expect(FlagFlow.getBool('b'), isTrue);

      FlagFlow.clearOverrides();

      expect(FlagFlow.getBool('a'), isFalse);
      expect(FlagFlow.getBool('b'), isFalse);
    });
    
    test('overrides trigger watcher streams', () async {
      await FlagFlow.initialize(providers: []);
      FlagFlow.registerFlag(FeatureFlag(key: 'stream_flag', defaultValue: FlagValue(false)));
      
      final stream = FlagFlow.watch('stream_flag');
      
      // We expect the stream to emit TRUE when we set the override
      expectLater(stream, emits(predicate<FlagValue>((v) => v.asBool == true)));
      
      // Give the stream listener a tick to attach
      await Future<void>.delayed(Duration.zero);
      
      FlagFlow.setOverride('stream_flag', FlagValue(true));
    });
  });
}

class MockSimpleProvider implements FlagProvider {
  final Map<String, FlagValue> flags;
  MockSimpleProvider(this.flags);

  @override
  Future<void> fetchAndActivate() async {}
  
  @override
  FeatureFlag? getFlag(String key) {
    if (flags.containsKey(key)) {
      return FeatureFlag(key: key, defaultValue: flags[key]!);
    }
    return null;
  }
  
  @override
  Future<void> initialize() async {}
  
  @override
  Stream<String>? get onFlagChanged => null;
}
