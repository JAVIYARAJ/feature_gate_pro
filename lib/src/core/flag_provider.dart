
import '../models/feature_flag.dart';


/// Abstract class defining the source of feature flags.
abstract class FlagProvider {
  /// Initializes the provider.
  Future<void> initialize();

  /// Returns the FeatureFlag if it exists in this provider, or null.
  FeatureFlag? getFlag(String key);

  /// Syncs or fetches the latest flags from the remote source.
  Future<void> fetchAndActivate();

  /// Gets a stream of flag changes if supported.
  Stream<String>? get onFlagChanged => null;
}
