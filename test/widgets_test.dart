import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:feature_gate_pro/feature_gate_pro.dart';

void main() {
  setUp(() async {
    // Re-initialize FlagFlow for each test
    await FlagFlow.initialize();
    FlagFlow.registry.clear(); // Ensure clean slate
  });

  group('FeatureFlagWidget Tests', () {
    testWidgets('renders child when flag is true', (WidgetTester tester) async {
      FlagFlow.registerFlag(FeatureFlag(key: 'show_banner', defaultValue: FlagValue(true)));

      await tester.pumpWidget(
        MaterialApp(
          home: FeatureFlagWidget(
            flagKey: 'show_banner',
            fallback: const Text('Banner is hidden'),
            child: const Text('Banner is visible'),
          ),
        ),
      );

      expect(find.text('Banner is visible'), findsOneWidget);
      expect(find.text('Banner is hidden'), findsNothing);
    });

    testWidgets('renders fallback when flag is false', (WidgetTester tester) async {
      FlagFlow.registerFlag(FeatureFlag(key: 'show_banner', defaultValue: FlagValue(false)));

      await tester.pumpWidget(
        MaterialApp(
          home: FeatureFlagWidget(
            flagKey: 'show_banner',
            fallback: const Text('Banner is hidden'),
            child: const Text('Banner is visible'),
          ),
        ),
      );

      expect(find.text('Banner is visible'), findsNothing);
      expect(find.text('Banner is hidden'), findsOneWidget);
    });

    testWidgets('reactively rebuilds when flag changes', (WidgetTester tester) async {
      // Initially false
      FlagFlow.registerFlag(FeatureFlag(key: 'show_banner', defaultValue: FlagValue(false)));

      await tester.pumpWidget(
        MaterialApp(
          home: FeatureFlagWidget(
            flagKey: 'show_banner',
            fallback: const Text('Banner is hidden'),
            child: const Text('Banner is visible'),
          ),
        ),
      );

      expect(find.text('Banner is hidden'), findsOneWidget);

      // Change flag to true
      FlagFlow.registerFlag(FeatureFlag(key: 'show_banner', defaultValue: FlagValue(true)));
      
      // Wait for stream to emit and widget to rebuild
      await tester.pumpAndSettle();

      expect(find.text('Banner is visible'), findsOneWidget);
      expect(find.text('Banner is hidden'), findsNothing);
    });
  });

  group('FeatureFlagBuilder Tests', () {
    testWidgets('provides evaluated value to builder', (WidgetTester tester) async {
      FlagFlow.registerFlag(FeatureFlag(key: 'max_items', defaultValue: FlagValue(10)));

      await tester.pumpWidget(
        MaterialApp(
          home: FeatureFlagBuilder(
            flagKey: 'max_items',
            builder: (context, value) {
              return Text('Max items: ${value.asInt}');
            },
          ),
        ),
      );

      expect(find.text('Max items: 10'), findsOneWidget);
    });

    testWidgets('reactively rebuilds dynamic value when flag changes', (WidgetTester tester) async {
      FlagFlow.registerFlag(FeatureFlag(key: 'max_items', defaultValue: FlagValue(10)));

      await tester.pumpWidget(
        MaterialApp(
          home: FeatureFlagBuilder(
            flagKey: 'max_items',
            builder: (context, value) {
              return Text('Max items: ${value.asInt}');
            },
          ),
        ),
      );

      expect(find.text('Max items: 10'), findsOneWidget);

      // Change flag
      FlagFlow.registerFlag(FeatureFlag(key: 'max_items', defaultValue: FlagValue(50)));
      await tester.pumpAndSettle();

      expect(find.text('Max items: 50'), findsOneWidget);
    });
  });
}
