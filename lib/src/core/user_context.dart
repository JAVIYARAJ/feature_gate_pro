/// Defines the context of the current user for targeted feature flags.
class UserContext {
  /// A unique identifier for the user (e.g., database ID). Required for percentage rollouts.
  final String id;
  
  /// The user's email address.
  final String? email;
  
  /// The user's country code (e.g., 'US', 'IN').
  final String? country;
  
  /// The user's preferred language code (e.g., 'en', 'es').
  final String? language;
  
  /// The platform the user is on (e.g., 'ios', 'android', 'web').
  final String? platform;
  
  /// The current app version using semantic versioning (e.g., '1.0.0').
  final String? appVersion;
  
  /// Any additional custom attributes used for targeting rules.
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
