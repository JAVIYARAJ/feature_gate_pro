import '../models/feature_flag.dart';

/// Abstract class for caching feature flag values locally.
abstract class CacheProvider {
  /// TTL for cache expiration
  Duration get cacheTTL;

  /// Initializes the cache.
  Future<void> initialize();

  /// Retrieves a cached flag.
  Future<FeatureFlag?> getFlag(String key);

  /// Retrieves all cached flags.
  Future<Map<String, FeatureFlag>> getAllFlags();

  /// Saves a flag to the cache.
  Future<void> setFlag(String key, FeatureFlag flag);

  /// Saves multiple flags to the cache.
  Future<void> setAllFlags(Map<String, FeatureFlag> flags);

  /// Clears all cached flags.
  Future<void> clear();
}
