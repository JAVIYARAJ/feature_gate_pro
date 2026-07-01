import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:feature_gate_pro/feature_gate_pro.dart';

void main() {
  group('FeatureGateDebugScreen Tests', () {
    setUp(() {
      FlagFlow.registry.clear();
      FlagFlow.clearOverrides();
      FlagFlow.dispose();
    });

    testWidgets('renders successfully', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: FeatureGateDebugScreen(),
        ),
      );

      // Verify basic UI elements
      expect(find.text('FeatureGate Debug'), findsOneWidget);
      expect(find.text('Feature Flags'), findsOneWidget);
      expect(find.text('No flags registered in the SDK yet.'), findsOneWidget);
    });
    
    testWidgets('displays registered flags', (WidgetTester tester) async {
      FlagFlow.registerFlag(FeatureFlag(key: 'demo_flag', defaultValue: FlagValue(true)));
      
      await tester.pumpWidget(
        const MaterialApp(
          home: FeatureGateDebugScreen(),
        ),
      );

      expect(find.text('demo_flag'), findsOneWidget);
      expect(find.text('Value: true'), findsOneWidget);
    });

    testWidgets('shows override indicator when flag is overridden', (WidgetTester tester) async {
      FlagFlow.registerFlag(FeatureFlag(key: 'demo_flag', defaultValue: FlagValue(false)));
      FlagFlow.setOverride('demo_flag', FlagValue(true));
      
      await tester.pumpWidget(
        const MaterialApp(
          home: FeatureGateDebugScreen(),
        ),
      );

      expect(find.text('demo_flag'), findsOneWidget);
      expect(find.text('Value: true'), findsOneWidget);
      expect(find.text('OVERRIDDEN'), findsOneWidget);
    });
  });
}
