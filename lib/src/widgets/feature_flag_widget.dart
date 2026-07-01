import 'dart:async';
import 'package:flutter/widgets.dart';
import '../core/flag_flow.dart';
import '../models/flag_value.dart';

/// A reactive widget that renders a child if a boolean feature flag is enabled.
/// If disabled, it optionally renders a fallback widget or an empty container.
class FeatureFlagWidget extends StatefulWidget {
  /// The exact key of the feature flag to evaluate.
  final String flagKey;
  
  /// The widget to render if the flag evaluates to `true`.
  final Widget child;
  
  /// The widget to render if the flag evaluates to `false`.
  /// Defaults to an empty `SizedBox.shrink()` if not provided.
  final Widget? fallback;
  
  /// The default boolean value if the flag is missing from all providers.
  final bool defaultValue;

  /// Optional: If your flag is a JSON object, use this to extract a specific boolean key from it.
  /// Example: If flag is `{"auth": true}`, set `jsonKey: 'auth'`.
  final String? jsonKey;

  const FeatureFlagWidget({
    super.key,
    required this.flagKey,
    this.jsonKey,
    this.fallback,
    this.defaultValue = false,
    required this.child,
  });

  @override
  State<FeatureFlagWidget> createState() => _FeatureFlagWidgetState();
}

class _FeatureFlagWidgetState extends State<FeatureFlagWidget> {
  late bool _isEnabled;
  StreamSubscription<FlagValue>? _subscription;
  
  bool _evaluate(FlagValue value) {
    if (widget.jsonKey != null) {
      return value.asJson[widget.jsonKey] == true;
    }
    return value.asBool;
  }

  @override
  void initState() {
    super.initState();
    // Synchronously grab initial state to prevent UI flicker
    final initialValue = FlagFlow.getValue(widget.flagKey, defaultValue: widget.defaultValue);
    _isEnabled = _evaluate(initialValue);
    
    // Subscribe to background updates
    _subscription = FlagFlow.watch(widget.flagKey).listen((value) {
      if (mounted) {
        setState(() {
          _isEnabled = _evaluate(value);
        });
      }
    });
  }

  @override
  void dispose() {
    // Prevent memory leaks when widget is removed from tree
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isEnabled) {
      return widget.child;
    }
    return widget.fallback ?? const SizedBox.shrink();
  }
}
