import 'dart:async';
import 'package:flutter/widgets.dart';
import '../core/flag_flow.dart';
import '../models/flag_value.dart';

/// A reactive widget that renders a child if a boolean feature flag is enabled.
/// If disabled, it optionally renders a fallback widget or an empty container.
class FeatureFlagWidget extends StatefulWidget {
  final String flagKey;
  final Widget child;
  final Widget? fallback;
  final bool defaultValue;

  const FeatureFlagWidget({
    super.key,
    required this.flagKey,
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

  @override
  void initState() {
    super.initState();
    // Synchronously grab initial state to prevent UI flicker
    _isEnabled = FlagFlow.isEnabled(widget.flagKey, defaultValue: widget.defaultValue);
    
    // Subscribe to background updates
    _subscription = FlagFlow.watch(widget.flagKey).listen((value) {
      if (mounted) {
        setState(() {
          _isEnabled = value.asBool;
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
