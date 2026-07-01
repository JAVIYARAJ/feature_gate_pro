/// Additional information about a feature flag.
class FlagMetadata {
  final String? description;
  final List<String>? tags;
  final Map<String, dynamic>? custom;

  const FlagMetadata({
    this.description,
    this.tags,
    this.custom,
  });

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'tags': tags,
      'custom': custom,
    };
  }

  factory FlagMetadata.fromJson(Map<String, dynamic> json) {
    return FlagMetadata(
      description: json['description'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>(),
      custom: json['custom'] as Map<String, dynamic>?,
    );
  }
}
