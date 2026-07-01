import 'package:flutter/material.dart';
import '../core/flag_flow.dart';
import '../models/flag_value.dart';

/// A developer debug screen for inspecting and overriding feature flags.
class FeatureGateDebugScreen extends StatefulWidget {
  const FeatureGateDebugScreen({super.key});

  @override
  State<FeatureGateDebugScreen> createState() => _FeatureGateDebugScreenState();
}

class _FeatureGateDebugScreenState extends State<FeatureGateDebugScreen> {
  @override
  void initState() {
    super.initState();
    // Rebuild the UI when any flag changes to reflect the new state instantly.
    for (final key in FlagFlow.registry.allFlags.keys) {
      FlagFlow.watch(key).listen((_) {
        if (mounted) setState(() {});
      });
    }
  }

  void _showOverrideDialog(String key) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Override "$key"'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Force TRUE'),
                onTap: () {
                  FlagFlow.setOverride(key, FlagValue(true));
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Force FALSE'),
                onTap: () {
                  FlagFlow.setOverride(key, FlagValue(false));
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Clear Override'),
                onTap: () {
                  FlagFlow.removeOverride(key);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final flags = FlagFlow.registry.allFlags;
    final contextData = FlagFlow.context;

    return Scaffold(
      appBar: AppBar(
        title: const Text('FeatureGate Debug'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await FlagFlow.refresh();
              if (mounted) setState(() {});
            },
            tooltip: 'Force Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () {
              FlagFlow.clearOverrides();
              if (mounted) setState(() {});
            },
            tooltip: 'Clear All Overrides',
          )
        ],
      ),
      body: ListView(
        children: [
          if (contextData != null)
            ExpansionTile(
              title: const Text('User Context'),
              subtitle: Text(contextData.id),
              children: [
                ListTile(title: Text('Country: ${contextData.country ?? "N/A"}')),
                ListTile(title: Text('Language: ${contextData.language ?? "N/A"}')),
                ListTile(title: Text('Platform: ${contextData.platform ?? "N/A"}')),
                ListTile(title: Text('App Version: ${contextData.appVersion ?? "N/A"}')),
              ],
            ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Feature Flags',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          if (flags.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('No flags registered in the SDK yet.'),
            ),
          for (final flag in flags.values) ...[
            _buildFlagTile(flag.key),
          ]
        ],
      ),
    );
  }

  Widget _buildFlagTile(String key) {
    final value = FlagFlow.getValue(key);
    final hasOverride = FlagFlow.overrides.containsKey(key);

    return ListTile(
      title: Text(key, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text('Value: ${value.asDynamic}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasOverride)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('OVERRIDDEN', style: TextStyle(color: Colors.orange, fontSize: 10)),
            ),
          const SizedBox(width: 8),
          Icon(
            value.asBool ? Icons.check_circle : Icons.cancel,
            color: value.asBool ? Colors.green : Colors.grey,
          ),
        ],
      ),
      onTap: () => _showOverrideDialog(key),
    );
  }
}
