import 'package:flutter/material.dart';
import 'package:feature_gate_pro/feature_gate_pro.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize FlagFlow with a mocked provider demonstrating all features.
  await FlagFlow.initialize(
    providers: [
      MockDemoProvider({
        'new_checkout': const FlagValue(true),
        'welcome_message': const FlagValue('Welcome to FeatureGate Pro!'),
        'button_color': const FlagValue('blue'),
      })
    ],
    // Set up a default user context for targeting/rollout demos
    userContext: const UserContext(
      id: 'user_123',
      country: 'US',
      platform: 'android',
      appVersion: '1.0.0',
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FeatureGate Pro Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const DemoHomePage(),
    );
  }
}

class DemoHomePage extends StatelessWidget {
  const DemoHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FeatureGate Pro Demo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            tooltip: 'Open Debug Dashboard',
            onPressed: () {
              // Easily integrate the powerful QA Debug Dashboard
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FeatureGateDebugScreen()),
              );
            },
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 1. FeatureFlagWidget (declarative)
            const FeatureFlagWidget(
              flagKey: 'new_checkout',
              fallback: Text('Old Checkout System'),
              child: Card(
                color: Colors.greenAccent,
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('New Checkout Enabled!'),
                ),
              ),
            ),
            
            const SizedBox(height: 40),

            // 2. FeatureFlagBuilder (imperative strings/colors)
            FeatureFlagBuilder(
              flagKey: 'welcome_message',
              builder: (context, value) {
                return Text(
                  value.asString,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                );
              },
            ),

            const SizedBox(height: 20),

            FeatureFlagBuilder(
              flagKey: 'button_color',
              builder: (context, value) {
                final color = value.asString == 'blue' ? Colors.blue : Colors.red;
                return ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: color),
                  onPressed: () {},
                  child: const Text('Dynamic Button', style: TextStyle(color: Colors.white)),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// A simple mock provider to simulate remote configs for the example app.
class MockDemoProvider implements FlagProvider {
  final Map<String, FlagValue> flags;
  MockDemoProvider(this.flags);

  @override
  Future<void> fetchAndActivate() async {}
  
  @override
  FeatureFlag? getFlag(String key) {
    if (flags.containsKey(key)) {
      return FeatureFlag(key: key, defaultValue: flags[key]!);
    }
    return null;
  }
  
  @override
  Future<void> initialize() async {}
  
  @override
  Stream<String>? get onFlagChanged => null;
}
