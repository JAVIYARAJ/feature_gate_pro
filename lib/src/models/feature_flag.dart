import 'flag_value.dart';
import 'flag_metadata.dart';

/// Defines a feature flag and its properties.
class FeatureFlag {
  final String key;
  final FlagValue defaultValue;
  final FlagMetadata? metadata;

  const FeatureFlag({
    required this.key,
    required this.defaultValue,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'defaultValue': defaultValue.toJson(),
      'metadata': metadata?.toJson(),
    };
  }

  factory FeatureFlag.fromJson(Map<String, dynamic> json) {
    return FeatureFlag(
      key: json['key'] as String,
      defaultValue: FlagValue.fromJson(json['defaultValue']),
      metadata: json['metadata'] != null ? FlagMetadata.fromJson(json['metadata'] as Map<String, dynamic>) : null,
    );
  }
}
