import 'dart:async';
import 'dart:convert';
import '../core/flag_provider.dart';

import '../models/feature_flag.dart';
import '../models/flag_metadata.dart';
import '../models/flag_value.dart';

/// An adapter that integrates with Firebase Remote Config (or any Map-based remote config)
/// without introducing a hard dependency on Firebase packages in the SDK.
class FirebaseAdapterProvider implements FlagProvider {
  /// A callback that executes `FirebaseRemoteConfig.instance.fetchAndActivate()`.
  /// Must return a Future.
  final Future<void> Function() onFetchAndActivate;
  
  /// A callback that executes `FirebaseRemoteConfig.instance.getAll()`.
  /// Must return the Map of remote config values.
  final Map<String, dynamic> Function() onGetAll;
  
  final Map<String, FeatureFlag> _flags = {};

  FirebaseAdapterProvider({
    required this.onFetchAndActivate,
    required this.onGetAll,
  });

  @override
  Future<void> initialize() async {
    // Initialization is expected to be handled by the user (e.g. Firebase.initializeApp())
  }

  @override
  Future<void> fetchAndActivate() async {
    try {
      await onFetchAndActivate();

      _flags.clear();
      final allValues = onGetAll();
      
      for (final entry in allValues.entries) {
        final key = entry.key;
        
        String rawString;
        try {
          // Use dynamic dispatch to extract the string if it's a RemoteConfigValue
          // This avoids a hard dependency on the firebase package
          rawString = (entry.value as dynamic).asString() as String;
        } catch (_) {
          rawString = entry.value.toString();
        }
        
        dynamic parsedValue = rawString;

        if (rawString.toLowerCase() == 'true') {
          parsedValue = true;
        } else if (rawString.toLowerCase() == 'false') {
          parsedValue = false;
        } else if (int.tryParse(rawString) != null) {
          parsedValue = int.parse(rawString);
        } else if (double.tryParse(rawString) != null) {
          parsedValue = double.parse(rawString);
        } else {
          try {
            // Attempt to decode json objects/arrays
            final decoded = jsonDecode(rawString);
            if (decoded is Map || decoded is List) {
              parsedValue = decoded;
            }
          } catch (_) {}
        }

        FlagMetadata? metadata;

        if (parsedValue is Map<String, dynamic> && parsedValue.containsKey('value')) {
          if (parsedValue.containsKey('metadata') && parsedValue['metadata'] is Map) {
            metadata = FlagMetadata.fromJson(Map<String, dynamic>.from(parsedValue['metadata'] as Map));
          }
          parsedValue = parsedValue['value'];
        }

        _flags[key] = FeatureFlag(
          key: key,
          defaultValue: FlagValue(parsedValue),
          metadata: metadata,
        );
      }
    } catch (_) {
      // Catch all timeouts or connectivity errors gracefully
      // This allows the FlagFlow Merge Engine to fallback correctly
    }
  }

  @override
  FeatureFlag? getFlag(String key) {
    return _flags[key];
  }

  @override
  Stream<String>? get onFlagChanged => null;
}
