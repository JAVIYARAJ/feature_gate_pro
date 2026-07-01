/// Defines the context of the current user for targeted feature flags.
class UserContext {
  final String id;
  final String? email;
  final String? country;
  final String? language;
  final String? platform;
  final String? appVersion;
  final Map<String, dynamic> customAttributes;

  const UserContext({
    required this.id,
    this.email,
    this.country,
    this.language,
    this.platform,
    this.appVersion,
    this.customAttributes = const {},
  });
}
