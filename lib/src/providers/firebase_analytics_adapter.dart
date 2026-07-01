import 'dart:async';
import '../core/analytics_provider.dart';
import '../core/user_context.dart';
import '../models/flag_value.dart';

/// An adapter that integrates with Firebase Analytics (or similar providers)
/// without introducing a hard dependency on external packages.
class FirebaseAnalyticsAdapter implements AnalyticsProvider {
  /// The callback to log events to your actual analytics instance (e.g. `FirebaseAnalytics.instance.logEvent`).
  final Future<void> Function(String name, Map<String, Object>? parameters) logEvent;
  
  @override
  final double sampleRate;

  FirebaseAnalyticsAdapter({
    required this.logEvent,
    this.sampleRate = 1.0,
  });

  @override
  void trackEvaluation(String key, FlagValue evaluatedValue, {UserContext? context}) {
    final parameters = <String, Object>{
      'flag_key': key,
      'flag_value': evaluatedValue.asDynamic.toString(), // Convert to string for analytics safety
    };

    if (context != null) {
      parameters['user_id'] = context.id;
      if (context.country != null) parameters['country'] = context.country!;
      if (context.platform != null) parameters['platform'] = context.platform!;
      if (context.appVersion != null) parameters['app_version'] = context.appVersion!;
    }

    logEvent('feature_flag_evaluated', parameters);
  }

  @override
  void trackEvent(String eventName, {Map<String, Object>? properties}) {
    logEvent(eventName, properties);
  }
}
