import 'dart:async';
import 'dart:math';
import 'flag_registry.dart';
import 'flag_provider.dart';
import 'cache_provider.dart';
import 'analytics_provider.dart';
import 'user_context.dart';
import '../models/feature_flag.dart';
import '../models/flag_value.dart';
import '../rollout/rollout_engine.dart';
import '../targeting/targeting_engine.dart';

/// The main entry point for the FlagFlow SDK.
class FlagFlow {
  static final FlagRegistry _registry = FlagRegistry();
  static List<FlagProvider>? _providers;
  static CacheProvider? _cache;
  static AnalyticsProvider? _analytics;
  static UserContext? _userContext;
  static bool _initialized = false;
  
  static bool _isRefreshing = false;
  static Future<void>? _refreshFuture;
  static Timer? _refreshTimer;

  static final Map<String, FlagValue> _overrides = {};
  
  /// Set to true to print detailed evaluation logs.
  static bool enableDebugLogging = false;

  /// Private constructor to prevent instantiation.
  FlagFlow._();

  /// Exposes the registry for advanced use cases.
  static FlagRegistry get registry => _registry;

  /// Exposes the current user context.
  static UserContext? get context => _userContext;

  /// Exposes all active runtime overrides.
  static Map<String, FlagValue> get overrides => Map.unmodifiable(_overrides);

  /// Forces a flag to evaluate to the given [value], bypassing all rules and providers.
  static void setOverride(String key, FlagValue value) {
    _overrides[key] = value;
    // Trigger a watcher update
    _evaluate(key, FlagValue(null));
  }

  /// Removes a runtime override for the given [key].
  static void removeOverride(String key) {
    _overrides.remove(key);
    // Trigger a watcher update
    _evaluate(key, FlagValue(null));
  }

  /// Clears all runtime overrides.
  static void clearOverrides() {
    final keys = _overrides.keys.toList();
    _overrides.clear();
    for (final key in keys) {
      _evaluate(key, FlagValue(null));
    }
  }

  /// Initializes the FlagFlow SDK.
  /// 
  /// * [providers] - A list of `FlagProvider`s. They are evaluated in order.
  /// * [cache] - An optional `CacheProvider` to persist flags locally.
  /// * [analytics] - An optional `AnalyticsProvider` to track A/B testing variants.
  /// * [userContext] - An optional `UserContext` used for Audience Targeting and Rollouts.
  /// * [refreshInterval] - If provided, the SDK will automatically fetch new flags in the background.
  static Future<void> initialize({
    List<FlagProvider>? providers,
    CacheProvider? cache,
    AnalyticsProvider? analytics,
    UserContext? userContext,
    Duration? refreshInterval,
  }) async {
    _providers = providers;
    _cache = cache;
    _analytics = analytics;
    _userContext = userContext;

    if (_cache != null) {
      await _cache!.initialize();
      final cachedFlags = await _cache!.getAllFlags();
      cachedFlags.forEach((key, flag) {
        _registry.updateFlag(flag);
      });
    }

    if (_providers != null) {
      for (final provider in _providers!) {
        await provider.initialize();
        await provider.fetchAndActivate();
        
        provider.onFlagChanged?.listen((key) {
          // Evaluate the flag to trigger a watcher update
          _evaluate(key, FlagValue(null));
        });
      }
    }

    _initialized = true;

    if (refreshInterval != null) {
      _refreshTimer = Timer.periodic(refreshInterval, (_) => refresh());
    }
  }

  /// Manually registers or updates a flag in the registry.
  static void registerFlag(FeatureFlag flag) {
    _registry.updateFlag(flag);
  }

  /// Updates the user context for flag evaluations (e.g. after login).
  static void setContext(UserContext? context) {
    _userContext = context;
  }

  /// Triggers a fetch and activate across all registered providers.
  /// Uses a mutex lock to prevent duplicate parallel fetches.
  static Future<void> refresh() {
    if (_isRefreshing && _refreshFuture != null) {
      return _refreshFuture!;
    }

    _isRefreshing = true;
    _refreshFuture = _doRefresh().whenComplete(() {
      _isRefreshing = false;
      _refreshFuture = null;
    });

    return _refreshFuture!;
  }

  static Future<void> _doRefresh() async {
    if (_providers != null) {
      for (final provider in _providers!) {
        await provider.fetchAndActivate();
      }
      
      // Trigger a re-evaluation for all flags currently rendered in the UI
      // This ensures FeatureFlagWidget and FeatureFlagBuilder instantly rebuild!
      for (final key in _registry.activeWatchers) {
        _evaluate(key, const FlagValue(null));
      }
    }
  }

  /// Stops the periodic background refresh timer.
  static void stopPeriodicRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  /// Disposes of the SDK resources (cancels timers, etc).
  static void dispose() {
    stopPeriodicRefresh();
    _initialized = false;
  }

  /// Checks if a boolean feature flag is enabled.
  static bool isEnabled(String key, {bool defaultValue = false}) {
    return getBool(key, defaultValue: defaultValue);
  }

  /// Retrieves a boolean feature flag value.
  static bool getBool(String key, {bool defaultValue = false}) {
    return _evaluate(key, FlagValue(defaultValue)).asBool;
  }

  /// Retrieves the raw FlagValue for advanced dynamic typing.
  static FlagValue getValue(String key, {dynamic defaultValue}) {
    return _evaluate(key, FlagValue(defaultValue));
  }

  /// Retrieves a string feature flag value.
  static String getString(String key, {String defaultValue = ''}) {
    return _evaluate(key, FlagValue(defaultValue)).asString;
  }

  /// Retrieves an integer feature flag value.
  static int getInt(String key, {int defaultValue = 0}) {
    return _evaluate(key, FlagValue(defaultValue)).asInt;
  }

  /// Retrieves a double feature flag value.
  static double getDouble(String key, {double defaultValue = 0.0}) {
    return _evaluate(key, FlagValue(defaultValue)).asDouble;
  }

  /// Retrieves a list feature flag value.
  static List<dynamic> getList(String key, {List<dynamic> defaultValue = const []}) {
    return _evaluate(key, FlagValue(defaultValue)).asList;
  }

  /// Retrieves a JSON (Map) feature flag value.
  static Map<String, dynamic> getJson(String key, {Map<String, dynamic> defaultValue = const {}}) {
    return _evaluate(key, FlagValue(defaultValue)).asJson;
  }

  /// Watches a feature flag for changes.
  static Stream<FlagValue> watch(String key) {
    return _registry.watch(key);
  }

  /// Internal evaluation engine.
  static FlagValue _evaluate(String key, FlagValue defaultVal) {
    FlagValue result = defaultVal;
    String evaluationSource = 'Default Fallback';

    // 1. Highest Priority: Runtime Overrides
    if (_overrides.containsKey(key)) {
      result = _overrides[key]!;
      evaluationSource = 'Runtime Override';
    } else {
      bool found = false;

      // 2. Evaluate via providers if available (Merge Engine Priority)
      if (_providers != null) {
        for (final provider in _providers!) {
          final flag = provider.getFlag(key);
          if (flag != null) {
            
            // 2a. Process Targeting Rules
            if (flag.metadata?.custom?['targeting'] != null) {
              final rules = flag.metadata!.custom!['targeting'] as List<dynamic>?;
              final passesTargeting = TargetingEngine.evaluate(rules, _userContext);
              if (!passesTargeting) {
                continue; // Skip provider if targeting fails
              }
            }

            // 2b. Process Rollout Rules
            if (flag.metadata?.custom?['rollout'] != null) {
              final rolloutRaw = flag.metadata!.custom!['rollout'];
              int rolloutPercentage = 0;
              if (rolloutRaw is int) {
                rolloutPercentage = rolloutRaw;
              } else if (rolloutRaw is String) {
                rolloutPercentage = int.tryParse(rolloutRaw) ?? 0;
              }

              final isRolledOut = RolloutEngine.evaluate(key, rolloutPercentage, _userContext);
              
              if (!isRolledOut) {
                continue; 
              }
            }
            
            result = flag.defaultValue;
            evaluationSource = 'Provider (${provider.runtimeType})';
            found = true;
            break;
          }
        }
      }
      
      if (!found) {
        if (result.isNull || result == defaultVal) {
          // 3. Fallback to registry default
          final flag = _registry.getFlag(key);
          if (flag != null) {
            result = flag.defaultValue;
            evaluationSource = 'Registry Cache / Default';
          }
        }
      }
    }
    
    // Debug Logging
    if (enableDebugLogging) {
      // ignore: avoid_print
      print('[FlagFlow Debug] Evaluated \'$key\' to \'${result.asDynamic}\' (Source: $evaluationSource)');
    }

    // Update the registry watchers only if there is a flag in the registry
    if (_initialized) {
       final storedFlag = _registry.getFlag(key);
       if (storedFlag != null) {
          _registry.updateFlag(storedFlag, evaluatedValue: result);
       }
    }

    // 4. Track evaluation
    if (_initialized && _analytics != null) {
      if (_analytics!.sampleRate >= 1.0 || Random().nextDouble() < _analytics!.sampleRate) {
        _analytics!.trackEvaluation(key, result, context: _userContext);
      }
    }

    return result;
  }
}
