import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:feature_gate_pro/feature_gate_pro.dart';

void main() {
  group('RestApiProvider Tests', () {
    test('successfully fetches and parses flags on 200 OK', () async {
      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode({
          'is_new': true,
          'price': 19.99,
          'title': 'Hello API',
        }), 200);
      });

      final provider = RestApiProvider(
        endpoint: 'https://api.example.com/flags',
        client: mockClient,
      );

      await provider.initialize();
      await provider.fetchAndActivate();

      expect(provider.getFlag('is_new')?.defaultValue.asBool ?? false, isTrue);
      expect(provider.getFlag('price')?.defaultValue.asDouble ?? 0.0, 19.99);
      expect(provider.getFlag('title')?.defaultValue.asString ?? '', 'Hello API');
      expect(provider.getFlag('missing'), isNull);
    });

    test('retries on 500 server error and succeeds', () async {
      int attempts = 0;
      final mockClient = MockClient((request) async {
        attempts++;
        if (attempts < 3) {
          return http.Response('Server Error', 500);
        }
        return http.Response(jsonEncode({'recovered': true}), 200);
      });

      final provider = RestApiProvider(
        endpoint: 'https://api.example.com/flags',
        client: mockClient,
        maxRetries: 3,
        baseDelay: const Duration(milliseconds: 10), // Fast for testing
      );

      await provider.fetchAndActivate();

      expect(attempts, 3);
      expect(provider.getFlag('recovered')?.defaultValue.asBool ?? false, isTrue);
    });

    test('fails gracefully after max retries', () async {
      int attempts = 0;
      final mockClient = MockClient((request) async {
        attempts++;
        return http.Response('Not Found', 404);
      });

      final provider = RestApiProvider(
        endpoint: 'https://api.example.com/flags',
        client: mockClient,
        maxRetries: 2,
        baseDelay: const Duration(milliseconds: 10),
      );

      // Should not throw
      await provider.fetchAndActivate();

      expect(attempts, 3); // Initial (1) + 2 retries
      expect(provider.getFlag('anything'), isNull);
    });

    test('handles exceptions (like socket errors/timeouts) gracefully with retries', () async {
      int attempts = 0;
      final mockClient = MockClient((request) async {
        attempts++;
        throw Exception('Network unreachable');
      });

      final provider = RestApiProvider(
        endpoint: 'https://api.example.com/flags',
        client: mockClient,
        maxRetries: 1,
        baseDelay: const Duration(milliseconds: 10),
      );

      // Should not throw
      await provider.fetchAndActivate();

      expect(attempts, 2); // Initial (1) + 1 retry
    });
  });
}
