import 'package:flutter_test/flutter_test.dart';
import 'package:feature_gate_pro/feature_gate_pro.dart';

void main() {
  group('Analytics Layer Tests', () {
    setUp(() {
      FlagFlow.registry.clear();
      FlagFlow.clearOverrides();
      FlagFlow.dispose();
    });

    test('FirebaseAnalyticsAdapter maps parameters correctly', () {
      String? loggedEvent;
      Map<String, dynamic>? loggedParams;

      final adapter = FirebaseAnalyticsAdapter(
        logEvent: (name, params) async {
          loggedEvent = name;
          loggedParams = params;
        },
      );

      final user = UserContext(id: 'usr123', country: 'US', platform: 'ios', appVersion: '1.0.0');
      
      adapter.trackEvaluation('test_flag', const FlagValue(true), context: user);

      expect(loggedEvent, 'feature_flag_evaluated');
      expect(loggedParams?['flag_key'], 'test_flag');
      expect(loggedParams?['flag_value'], 'true'); // asString handles bool to 'true'
      expect(loggedParams?['user_id'], 'usr123');
      expect(loggedParams?['country'], 'US');
      expect(loggedParams?['platform'], 'ios');
      expect(loggedParams?['app_version'], '1.0.0');
    });

    test('FlagFlow correctly samples at 0.0 (no events)', () async {
      int trackCount = 0;

      final analytics = MockAnalyticsProvider(0.0, () {
        trackCount++;
      });

      await FlagFlow.initialize(
        providers: [MockSimpleProvider({'sampled_flag': FlagValue('hello')})],
        analytics: analytics,
      );

      // Evaluate 100 times
      for (int i = 0; i < 100; i++) {
        FlagFlow.getString('sampled_flag');
      }

      // Because sampleRate is 0.0, it should never have tracked.
      expect(trackCount, 0);
    });

    test('FlagFlow correctly samples at 1.0 (all events)', () async {
      int trackCount = 0;

      final analytics = MockAnalyticsProvider(1.0, () {
        trackCount++;
      });

      await FlagFlow.initialize(
        providers: [MockSimpleProvider({'sampled_flag': FlagValue('hello')})],
        analytics: analytics,
      );

      // Evaluate 100 times
      for (int i = 0; i < 100; i++) {
        FlagFlow.getString('sampled_flag');
      }

      // Because sampleRate is 1.0, it should track every single one.
      expect(trackCount, 100);
    });
  });
}

class MockAnalyticsProvider implements AnalyticsProvider {
  @override
  final double sampleRate;
  final void Function() onTrack;

  MockAnalyticsProvider(this.sampleRate, this.onTrack);

  @override
  void trackEvaluation(String key, FlagValue evaluatedValue, {UserContext? context}) {
    onTrack();
  }

  @override
  void trackEvent(String eventName, {Map<String, dynamic>? properties}) {}
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
