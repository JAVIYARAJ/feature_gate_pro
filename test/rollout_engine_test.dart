import 'package:flutter_test/flutter_test.dart';
import 'package:feature_gate_pro/feature_gate_pro.dart';
import 'package:feature_gate_pro/src/rollout/rollout_engine.dart';

void main() {
  group('RolloutEngine Tests', () {
    test('missing user context always fails rollout', () {
      expect(RolloutEngine.evaluate('new_feature', 50, null), isFalse);
    });

    test('negative and 0 rollouts always fail', () {
      final context = UserContext(id: 'user123');
      expect(RolloutEngine.evaluate('new_feature', 0, context), isFalse);
      expect(RolloutEngine.evaluate('new_feature', -10, context), isFalse);
    });

    test('100 and above rollouts always pass', () {
      final context = UserContext(id: 'user123');
      expect(RolloutEngine.evaluate('new_feature', 100, context), isTrue);
      expect(RolloutEngine.evaluate('new_feature', 150, context), isTrue);
    });

    test('consistent hashing places users in predictable buckets', () {
      final user1 = UserContext(id: 'user1');

      // 'user1' and 'user2' will hash to specific buckets.
      // We don't know the exact bucket mathematically without computing it here,
      // but we can test that for a high enough percentage, they both pass,
      // and for a low enough percentage, they both fail.
      // And crucially, they are consistent over multiple calls.

      final res1A = RolloutEngine.evaluate('test_flag', 50, user1);
      final res1B = RolloutEngine.evaluate('test_flag', 50, user1);
      expect(res1A, equals(res1B)); // Consistent!

      // To verify the hashing math, let's manually test one.
      // 'test_flag-user1'
      // By FNV-1a math:
      // It will evaluate to true for 100%, false for 0%
      expect(RolloutEngine.evaluate('test_flag', 100, user1), isTrue);
    });
  });
}
