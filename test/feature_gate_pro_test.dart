import 'package:flutter_test/flutter_test.dart';
import 'package:feature_gate_pro/feature_gate_pro.dart';

void main() {
  group('FlagValue Tests', () {
    test('parses boolean correctly', () {
      final flag = FlagValue(true);
      expect(flag.asBool, isTrue);
      expect(flag.isNull, isFalse);
    });

    test('parses int correctly', () {
      final flag = FlagValue(42);
      expect(flag.asInt, 42);
    });

    test('parses double correctly', () {
      final flag = FlagValue(3.14);
      expect(flag.asDouble, 3.14);
    });

    test('parses string correctly', () {
      final flag = FlagValue('test');
      expect(flag.asString, 'test');
    });

    test('parses json correctly', () {
      final flag = FlagValue({'key': 'value'});
      expect(flag.asJson, {'key': 'value'});
    });
    
    test('parses list correctly', () {
      final flag = FlagValue(['a', 'b']);
      expect(flag.asList, ['a', 'b']);
    });

    test('handles null correctly', () {
      final flag = FlagValue(null);
      expect(flag.isNull, isTrue);
      expect(flag.asBool, isFalse);
      expect(flag.asList, isEmpty);
    });
  });
}
