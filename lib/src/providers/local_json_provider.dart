import 'dart:convert';
import 'package:flutter/services.dart';
import '../core/flag_provider.dart';

import '../models/feature_flag.dart';
import '../models/flag_value.dart';

/// A FlagProvider that loads feature flags from a local JSON asset file.
class LocalJsonProvider implements FlagProvider {
  final String assetPath;
  final Future<String> Function(String path)? customLoader;
  
  final Map<String, FeatureFlag> _flags = {};

  LocalJsonProvider({
    required this.assetPath,
    this.customLoader,
  });

  @override
  Future<void> initialize() async {
    // Initialization is deferred to fetchAndActivate for local assets.
  }

  @override
  Future<void> fetchAndActivate() async {
    try {
      final jsonString = customLoader != null
          ? await customLoader!(assetPath)
          : await rootBundle.loadString(assetPath);

      if (jsonString.trim().isEmpty) return;

      final dynamic decoded = jsonDecode(jsonString);
      
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Root of JSON must be a Map/Object');
      }

      _flags.clear();

      for (var entry in decoded.entries) {
        _flags[entry.key] = FeatureFlag(
          key: entry.key,
          defaultValue: FlagValue(entry.value),
        );
      }
    } catch (e) {
      // Intentionally swallow errors so the SDK gracefully falls back to default values.
      // In a real production app, we could optionally log this via a provided logger.
    }
  }

  @override
  FeatureFlag? getFlag(String key) {
    return _flags[key];
  }

  @override
  Stream<String>? get onFlagChanged => null;
}
