import 'package:flutter_test/flutter_test.dart';
import 'package:trios/utils/dart_mappable_utils.dart';

void main() {
  const hook = SafeDoubleHook();

  group('SafeDoubleHook', () {
    test('returns null for null input', () {
      expect(hook.beforeDecode(null), isNull);
    });

    test('returns double for int input', () {
      expect(hook.beforeDecode(42), 42.0);
    });

    test('returns double for double input', () {
      expect(hook.beforeDecode(3.14), 3.14);
    });

    test('parses valid numeric string', () {
      expect(hook.beforeDecode('123.45'), 123.45);
    });

    test('returns null for non-numeric string', () {
      expect(hook.beforeDecode('jaaf1'), isNull);
    });

    test('returns null for arbitrary text', () {
      expect(hook.beforeDecode('not_a_number'), isNull);
    });

    test('parses negative numbers', () {
      expect(hook.beforeDecode('-5.5'), -5.5);
    });

    test('parses zero', () {
      expect(hook.beforeDecode('0'), 0.0);
    });
  });
}
