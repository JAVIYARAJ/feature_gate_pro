import 'dart:async';
import 'package:flutter/widgets.dart';
import '../core/flag_flow.dart';
import '../models/flag_value.dart';

/// A reactive widget builder that passes the evaluated `FlagValue` directly to your builder function.
/// Useful for dynamically changing themes, limits, strings, or JSON configurations dynamically.
class FeatureFlagBuilder extends StatefulWidget {
  /// The exact key of the feature flag to evaluate.
  final String flagKey;
  
  /// The builder function that receives the active [BuildContext] and evaluated [FlagValue].
  /// This function will be called repeatedly whenever the underlying flag changes.
  final Widget Function(BuildContext context, FlagValue value) builder;
  
  /// The default raw value (string, map, bool, etc.) to use if the flag is missing from all providers.
  final dynamic defaultValue;
  
  /// If `true` (default), this widget will automatically rebuild whenever the underlying flag changes in the background.
  /// If `false`, it will read the flag once during initialization and ignore all future updates to prevent UI shifting.
  final bool listenToChanges;

  const FeatureFlagBuilder({
    super.key,
    required this.flagKey,
    required this.builder,
    this.defaultValue,
    this.listenToChanges = true,
  });

  @override
  State<FeatureFlagBuilder> createState() => _FeatureFlagBuilderState();
}

class _FeatureFlagBuilderState extends State<FeatureFlagBuilder> {
  late FlagValue _flagValue;
  StreamSubscription<FlagValue>? _subscription;

  @override
  void initState() {
    super.initState();
    // Synchronously grab initial state
    _flagValue = FlagFlow.getValue(widget.flagKey, defaultValue: widget.defaultValue);
    
    // Subscribe to background updates only if requested
    if (widget.listenToChanges) {
      _subscription = FlagFlow.watch(widget.flagKey).listen((value) {
        if (mounted) {
          setState(() {
            _flagValue = value;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    // Prevent memory leaks
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _flagValue);
  }
}
