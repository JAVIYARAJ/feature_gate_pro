import 'package:flutter_test/flutter_test.dart';
import 'package:feature_gate_pro/feature_gate_pro.dart';

void main() {
  group('LocalJsonProvider Tests', () {
    
    test('parses valid json and evaluates correctly', () async {
      final jsonString = '''
      {
        "new_checkout": true,
        "max_items": 10,
        "theme": "dark",
        "locales": ["en", "fr"],
        "metadata": {"version": 1}
      }
      ''';

      final provider = LocalJsonProvider(
        assetPath: 'assets/flags.json',
        customLoader: (path) async => jsonString,
      );

      await provider.fetchAndActivate();

      // Test boolean
      expect(provider.getFlag('new_checkout')?.defaultValue.asBool ?? false, isTrue);
      // Test int
      expect(provider.getFlag('max_items')?.defaultValue.asInt ?? 0, 10);
      // Test string
      expect(provider.getFlag('theme')?.defaultValue.asString ?? '', 'dark');
      // Test list
      expect(provider.getFlag('locales')?.defaultValue.asList ?? [], ['en', 'fr']);
      // Test map
      expect(provider.getFlag('metadata')?.defaultValue.asJson ?? {}, {'version': 1});
      // Test fallback for missing key
      expect(provider.getFlag('missing_key')?.defaultValue.asBool ?? false, isFalse);
    });

    test('handles empty file gracefully', () async {
      final provider = LocalJsonProvider(
        assetPath: 'assets/flags.json',
        customLoader: (path) async => '',
      );

      await provider.fetchAndActivate();
      
      expect(provider.getFlag('missing_key')?.defaultValue.asBool ?? true, isTrue);
    });

    test('handles invalid json format gracefully', () async {
      final provider = LocalJsonProvider(
        assetPath: 'assets/flags.json',
        customLoader: (path) async => 'invalid_json_string',
      );

      await provider.fetchAndActivate();
      
      expect(provider.getFlag('missing_key')?.defaultValue.asBool ?? true, isTrue);
    });
    
    test('handles valid json array instead of object gracefully', () async {
      final provider = LocalJsonProvider(
        assetPath: 'assets/flags.json',
        customLoader: (path) async => '[{"key": "value"}]',
      );

      await provider.fetchAndActivate();
      
      expect(provider.getFlag('missing_key')?.defaultValue.asBool ?? true, isTrue);
    });
    
    test('handles duplicate keys by taking the last value (Dart default)', () async {
      final jsonString = '''
      {
        "duplicate": false,
        "duplicate": true
      }
      ''';

      final provider = LocalJsonProvider(
        assetPath: 'assets/flags.json',
        customLoader: (path) async => jsonString,
      );

      await provider.fetchAndActivate();
      
      expect(provider.getFlag('duplicate')?.defaultValue.asBool ?? false, isTrue);
    });

    test('handles missing file gracefully', () async {
      final provider = LocalJsonProvider(
        assetPath: 'assets/flags.json',
        customLoader: (path) async => throw Exception('File not found'),
      );

      await provider.fetchAndActivate();
      
      expect(provider.getFlag('missing_key')?.defaultValue.asBool ?? true, isTrue);
    });
  });
}
