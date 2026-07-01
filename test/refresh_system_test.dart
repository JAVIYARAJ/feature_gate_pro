import 'package:flutter_test/flutter_test.dart';
import 'package:feature_gate_pro/feature_gate_pro.dart';
import 'package:fake_async/fake_async.dart';
import 'dart:async';

void main() {
  group('Refresh System Tests', () {
    setUp(() {
      FlagFlow.registry.clear();
      FlagFlow.dispose();
    });

    tearDown(() {
      FlagFlow.dispose();
    });

    test('concurrency lock prevents duplicate parallel fetch calls', () async {
      final provider = MockSlowProvider();
      await FlagFlow.initialize(providers: [provider]);

      // Fire 5 refreshes in parallel
      final futures = <Future<void>>[];
      for (int i = 0; i < 5; i++) {
        futures.add(FlagFlow.refresh());
      }
      
      await Future.wait(futures);

      // Even though we called refresh 5 times in parallel,
      // the provider should have only been fetched ONCE via refresh()
      // (plus the initial fetch from FlagFlow.initialize()).
      expect(provider.fetchCount, 2);
    });

    test('periodic timer triggers background refresh', () {
      fakeAsync((async) {
        final provider = MockSlowProvider();
        
        FlagFlow.initialize(
          providers: [provider],
          refreshInterval: const Duration(minutes: 15),
        );
        
        // At initialization, it calls fetchAndActivate once (not via refresh, but directly).
        // Let's resolve the init fetch.
        async.elapse(const Duration(milliseconds: 50));
        expect(provider.fetchCount, 1);

        // Fast forward 15 minutes
        async.elapse(const Duration(minutes: 15));
        
        // Timer should have triggered refresh, adding 1 to the fetch count.
        expect(provider.fetchCount, 2);

        // Fast forward another 15 minutes
        async.elapse(const Duration(minutes: 15));
        expect(provider.fetchCount, 3);
        
        FlagFlow.dispose();
      });
    });
  });
}

class MockSlowProvider implements FlagProvider {
  int fetchCount = 0;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> fetchAndActivate() async {
    fetchCount++;
    // Simulate a slow network request
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }

  @override
  FeatureFlag? getFlag(String key) => null;

  @override
  Stream<String>? get onFlagChanged => null;
}
