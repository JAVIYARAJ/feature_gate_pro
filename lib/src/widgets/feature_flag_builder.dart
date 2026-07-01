import 'dart:async';
import 'package:flutter/widgets.dart';
import '../core/flag_flow.dart';
import '../models/flag_value.dart';

/// A reactive widget builder that passes the evaluated `FlagValue` directly to your builder function.
/// Useful for dynamically changing themes, limits, strings, or JSON configurations dynamically.
class FeatureFlagBuilder extends StatefulWidget {
  final String flagKey;
  final Widget Function(BuildContext context, FlagValue value) builder;
  final dynamic defaultValue;

  const FeatureFlagBuilder({
    super.key,
    required this.flagKey,
    required this.builder,
    this.defaultValue,
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
    
    // Subscribe to background updates
    _subscription = FlagFlow.watch(widget.flagKey).listen((value) {
      if (mounted) {
        setState(() {
          _flagValue = value;
        });
      }
    });
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
