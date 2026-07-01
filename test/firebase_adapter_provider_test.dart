import 'package:flutter_test/flutter_test.dart';
import 'package:feature_gate_pro/feature_gate_pro.dart';

void main() {
  group('FirebaseAdapterProvider Tests', () {
    test('fetches, parses, and evaluates correctly', () async {
      final mockData = {
        'is_new': 'true',
        'price': '19.99',
        'title': 'Hello',
        'settings': '{"theme":"dark"}',
      };

      bool fetched = false;

      final provider = FirebaseAdapterProvider(
        onFetchAndActivate: () async {
          fetched = true;
        },
        onGetAll: () {
          return mockData;
        },
      );

      await provider.initialize();
      await provider.fetchAndActivate();

      expect(fetched, isTrue);
      expect(provider.getFlag('is_new')?.defaultValue.asBool ?? false, isTrue);
      expect(provider.getFlag('price')?.defaultValue.asDouble ?? 0.0, 19.99);
      expect(provider.getFlag('title')?.defaultValue.asString ?? '', 'Hello');
      expect(provider.getFlag('settings')?.defaultValue.asJson['theme'], 'dark');
      
      // Fallback
      expect(provider.getFlag('missing'), isNull);
    });

    test('handles exceptions gracefully', () async {
      final provider = FirebaseAdapterProvider(
        onFetchAndActivate: () async {
          throw Exception('Network error');
        },
        onGetAll: () {
          return {};
        },
      );
      
      await provider.initialize();
      // Should not throw
      await provider.fetchAndActivate();
      
      expect(provider.getFlag('missing'), isNull);
    });
  });
}
