import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../core/flag_provider.dart';

import '../models/feature_flag.dart';
import '../models/flag_value.dart';

/// A FlagProvider that fetches feature flags from a custom REST API backend.
class RestApiProvider implements FlagProvider {
  final String endpoint;
  final Map<String, String>? headers;
  final Duration timeout;
  final int maxRetries;
  final Duration baseDelay;
  final http.Client? _customClient;

  final Map<String, FeatureFlag> _flags = {};

  RestApiProvider({
    required this.endpoint,
    this.headers,
    this.timeout = const Duration(seconds: 10),
    this.maxRetries = 3,
    this.baseDelay = const Duration(seconds: 1),
    http.Client? client,
  }) : _customClient = client;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> fetchAndActivate() async {
    final client = _customClient ?? http.Client();
    
    int attempt = 0;
    while (attempt <= maxRetries) {
      try {
        final response = await client.get(
          Uri.parse(endpoint),
          headers: headers,
        ).timeout(timeout);

        if (response.statusCode >= 200 && response.statusCode < 300) {
          final decoded = jsonDecode(response.body);
          if (decoded is Map<String, dynamic>) {
            _flags.clear();
            _parseAndStoreFlags(decoded);
          }
          break; // Success, exit retry loop
        } else {
          // Server error (5xx) or Client error (4xx) - throw to trigger retry for 5xx if desired, 
          // or just throw to retry. For simplicity, retry all non-2xx responses.
          throw Exception('HTTP ${response.statusCode}');
        }
      } catch (e) {
        if (attempt == maxRetries) {
          // Max retries reached, silently fail so the Merge Engine falls back to other providers
          break;
        }
        // Exponential backoff
        final delay = baseDelay.inMilliseconds * pow(2, attempt);
        await Future<void>.delayed(Duration(milliseconds: delay.toInt()));
      } finally {
        attempt++;
      }
    }

    if (_customClient == null) {
      client.close();
    }
  }

  void _parseAndStoreFlags(Map<String, dynamic> json) {
    for (final entry in json.entries) {
      _flags[entry.key] = FeatureFlag(
        key: entry.key,
        defaultValue: FlagValue(entry.value),
      );
    }
  }

  @override
  FeatureFlag? getFlag(String key) {
    return _flags[key];
  }

  @override
  Stream<String>? get onFlagChanged => null;
}
