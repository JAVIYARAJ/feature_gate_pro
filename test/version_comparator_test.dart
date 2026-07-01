import 'package:flutter_test/flutter_test.dart';
import 'package:feature_gate_pro/src/targeting/version_comparator.dart';

void main() {
  group('VersionComparator Tests', () {
    test('compares exact versions correctly', () {
      expect(VersionComparator.evaluate('1.0.0', '==', '1.0.0'), isTrue);
      expect(VersionComparator.evaluate('v1.0.0', '==', '1.0.0'), isTrue); // handles v prefix
      expect(VersionComparator.evaluate('1.2', '==', '1.2.0'), isTrue); // implicit 0
    });

    test('compares greater than correctly', () {
      expect(VersionComparator.evaluate('2.0.0', '>', '1.9.9'), isTrue);
      expect(VersionComparator.evaluate('1.1.1', '>', '1.1.0'), isTrue);
      expect(VersionComparator.evaluate('1.2.0', '>', '1.2.0'), isFalse);
    });

    test('compares less than correctly', () {
      expect(VersionComparator.evaluate('1.0.0', '<', '1.0.1'), isTrue);
      expect(VersionComparator.evaluate('0.9.9', '<', '1.0.0'), isTrue);
      expect(VersionComparator.evaluate('1.0.0', '<', '1.0.0'), isFalse);
    });

    test('compares greater than or equal correctly', () {
      expect(VersionComparator.evaluate('1.0.0', '>=', '1.0.0'), isTrue);
      expect(VersionComparator.evaluate('1.1.0', '>=', '1.0.0'), isTrue);
      expect(VersionComparator.evaluate('0.9.0', '>=', '1.0.0'), isFalse);
    });

    test('compares less than or equal correctly', () {
      expect(VersionComparator.evaluate('1.0.0', '<=', '1.0.0'), isTrue);
      expect(VersionComparator.evaluate('0.9.9', '<=', '1.0.0'), isTrue);
      expect(VersionComparator.evaluate('1.1.0', '<=', '1.0.0'), isFalse);
    });
    
    test('compares not equal correctly', () {
      expect(VersionComparator.evaluate('1.0.0', '!=', '1.0.1'), isTrue);
      expect(VersionComparator.evaluate('1.0.0', '!=', '1.0.0'), isFalse);
    });
  });
}
