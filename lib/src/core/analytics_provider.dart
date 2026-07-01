import '../models/flag_value.dart';
import 'user_context.dart';

/// Abstract class for tracking feature flag evaluations and events.
abstract class AnalyticsProvider {
  /// The percentage (0.0 to 1.0) of events that should be tracked.
  /// Defaults to 1.0 (100% of events).
  double get sampleRate => 1.0;

  /// Tracks when a flag is evaluated.
  void trackEvaluation(String key, FlagValue evaluatedValue, {UserContext? context});
  
  /// Tracks a custom event.
  void trackEvent(String eventName, {Map<String, dynamic>? properties});
}
