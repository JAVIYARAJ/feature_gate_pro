import 'dart:async';
import '../models/feature_flag.dart';
import '../models/flag_value.dart';

/// Registry responsible for storing and broadcasting feature flags.
class FlagRegistry {
  final Map<String, FeatureFlag> _flags = {};
  final Map<String, StreamController<FlagValue>> _watchers = {};

  /// Exposes all currently registered flags.
  Map<String, FeatureFlag> get allFlags => Map.unmodifiable(_flags);

  /// Exposes the keys of flags that are currently being actively watched by UI widgets.
  Set<String> get activeWatchers => _watchers.keys.toSet();

  /// Updates or adds a flag in the registry and notifies watchers.
  void updateFlag(FeatureFlag flag, {FlagValue? evaluatedValue}) {
    _flags[flag.key] = flag;
    broadcast(flag.key, evaluatedValue ?? flag.defaultValue);
  }
  
  /// Broadcasts a new evaluated value to all active watchers for the given key.
  void broadcast(String key, FlagValue evaluatedValue) {
    if (_watchers.containsKey(key)) {
      _watchers[key]?.add(evaluatedValue);
    }
  }

  /// Retrieves a flag configuration by key.
  FeatureFlag? getFlag(String key) => _flags[key];

  /// Returns a stream that emits when the evaluated value of a flag changes.
  Stream<FlagValue> watch(String key) {
    if (!_watchers.containsKey(key)) {
      _watchers[key] = StreamController<FlagValue>.broadcast();
    }
    return _watchers[key]!.stream;
  }

  /// Clears the registry.
  void clear() {
    _flags.clear();
    for (var controller in _watchers.values) {
      controller.close();
    }
    _watchers.clear();
  }
}
