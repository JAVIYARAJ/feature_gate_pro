import 'package:flutter_test/flutter_test.dart';
import 'package:feature_gate_pro/feature_gate_pro.dart';
import 'package:feature_gate_pro/src/targeting/targeting_engine.dart';

void main() {
  group('TargetingEngine Tests', () {
    test('returns true if rules are null or empty', () {
      expect(TargetingEngine.evaluate(null, null), isTrue);
      expect(TargetingEngine.evaluate([], null), isTrue);
    });

    test('returns false if rules exist but no user context', () {
      final rules = [
        {'attribute': 'country', 'operator': '==', 'value': 'US'}
      ];
      expect(TargetingEngine.evaluate(rules, null), isFalse);
    });

    test('evaluates in and not_in operators', () {
      final context = UserContext(id: '123', country: 'US');
      
      final ruleIn = [{'attribute': 'country', 'operator': 'in', 'value': ['US', 'CA']}];
      expect(TargetingEngine.evaluate(ruleIn, context), isTrue);

      final ruleNotIn = [{'attribute': 'country', 'operator': 'not_in', 'value': ['UK', 'FR']}];
      expect(TargetingEngine.evaluate(ruleNotIn, context), isTrue);

      final ruleFail = [{'attribute': 'country', 'operator': 'in', 'value': ['UK']}];
      expect(TargetingEngine.evaluate(ruleFail, context), isFalse);
    });

    test('evaluates exact matches', () {
      final context = UserContext(id: '123', platform: 'ios');
      
      final rule = [{'attribute': 'platform', 'operator': '==', 'value': 'ios'}];
      expect(TargetingEngine.evaluate(rule, context), isTrue);

      final ruleFail = [{'attribute': 'platform', 'operator': '!=', 'value': 'ios'}];
      expect(TargetingEngine.evaluate(ruleFail, context), isFalse);
    });

    test('evaluates custom attributes', () {
      final context = UserContext(id: '123', customAttributes: {'isPremium': true});
      
      // supports "custom.isPremium"
      final rule1 = [{'attribute': 'custom.isPremium', 'operator': '==', 'value': true}];
      expect(TargetingEngine.evaluate(rule1, context), isTrue);

      // or just "isPremium" directly
      final rule2 = [{'attribute': 'isPremium', 'operator': '==', 'value': true}];
      expect(TargetingEngine.evaluate(rule2, context), isTrue);
    });

    test('evaluates numerical conditions', () {
      final context = UserContext(id: '123', customAttributes: {'age': 25});
      
      final rule1 = [{'attribute': 'age', 'operator': '>=', 'value': 18}];
      expect(TargetingEngine.evaluate(rule1, context), isTrue);

      final rule2 = [{'attribute': 'age', 'operator': '<', 'value': 30}];
      expect(TargetingEngine.evaluate(rule2, context), isTrue);

      final ruleFail = [{'attribute': 'age', 'operator': '>', 'value': 25}];
      expect(TargetingEngine.evaluate(ruleFail, context), isFalse);
    });

    test('evaluates appVersion semantics', () {
      final context = UserContext(id: '123', appVersion: '2.1.0');
      
      final rule1 = [{'attribute': 'appVersion', 'operator': '>=', 'value': '2.0.0'}];
      expect(TargetingEngine.evaluate(rule1, context), isTrue);

      final rule2 = [{'attribute': 'appVersion', 'operator': '==', 'value': '2.1.0'}];
      expect(TargetingEngine.evaluate(rule2, context), isTrue);
    });

    test('fails if any rule in the AND list fails', () {
      final context = UserContext(id: '123', country: 'US', platform: 'android');
      
      final rules = [
        {'attribute': 'country', 'operator': '==', 'value': 'US'}, // Pass
        {'attribute': 'platform', 'operator': '==', 'value': 'ios'} // Fail
      ];
      
      expect(TargetingEngine.evaluate(rules, context), isFalse);
    });
  });
}
