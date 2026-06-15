import 'package:flutter_test/flutter_test.dart';
import 'package:trios/widgets/smart_search/search_dsl_parser.dart';

void main() {
  group('SearchDslParser', () {
    test('plain text token', () {
      final q = SearchDslParser.parse('laser');
      expect(q.tokens, hasLength(1));
      expect(q.tokens.first, isA<TextToken>());
      expect((q.tokens.first as TextToken).text, 'laser');
    });

    test('field equality token', () {
      final q = SearchDslParser.parse('tracking:excellent');
      expect(q.tokens, hasLength(1));
      final t = q.tokens.first as FieldToken;
      expect(t.key, 'tracking');
      expect(t.operator, DslOperator.equals);
      expect(t.value, 'excellent');
      expect(t.negated, false);
    });

    test('negated field token', () {
      final q = SearchDslParser.parse('-type:missile');
      expect(q.tokens, hasLength(1));
      final t = q.tokens.first as FieldToken;
      expect(t.key, 'type');
      expect(t.operator, DslOperator.equals);
      expect(t.value, 'missile');
      expect(t.negated, true);
    });

    test('numeric greaterThan token', () {
      final q = SearchDslParser.parse('range:>800');
      expect(q.tokens, hasLength(1));
      final t = q.tokens.first as FieldToken;
      expect(t.key, 'range');
      expect(t.operator, DslOperator.greaterThan);
      expect(t.value, '800');
      expect(t.negated, false);
    });

    test('numeric lessThan token', () {
      final q = SearchDslParser.parse('op:<10');
      final t = q.tokens.first as FieldToken;
      expect(t.operator, DslOperator.lessThan);
      expect(t.value, '10');
    });

    test('numeric greaterThanOrEqual token', () {
      final q = SearchDslParser.parse('dps:>=500');
      final t = q.tokens.first as FieldToken;
      expect(t.operator, DslOperator.greaterThanOrEqual);
      expect(t.value, '500');
    });

    test('numeric lessThanOrEqual token', () {
      final q = SearchDslParser.parse('range:<=1000');
      final t = q.tokens.first as FieldToken;
      expect(t.operator, DslOperator.lessThanOrEqual);
      expect(t.value, '1000');
    });

    test('mixed query', () {
      final q = SearchDslParser.parse('laser tracking:excellent -size:large');
      expect(q.tokens, hasLength(3));
      expect(q.tokens[0], isA<TextToken>());
      expect((q.tokens[0] as TextToken).text, 'laser');
      final t1 = q.tokens[1] as FieldToken;
      expect(t1.key, 'tracking');
      expect(t1.operator, DslOperator.equals);
      expect(t1.value, 'excellent');
      expect(t1.negated, false);
      final t2 = q.tokens[2] as FieldToken;
      expect(t2.key, 'size');
      expect(t2.operator, DslOperator.equals);
      expect(t2.value, 'large');
      expect(t2.negated, true);
    });

    test('empty query produces empty ParsedQuery', () {
      final q = SearchDslParser.parse('');
      expect(q.isEmpty, true);
      expect(q.tokens, isEmpty);
    });

    test('whitespace-only query produces empty ParsedQuery', () {
      final q = SearchDslParser.parse('   ');
      expect(q.isEmpty, true);
    });

    test('unknown field token parses as FieldToken (fallback handled by caller)', () {
      // The parser always produces a FieldToken for field:value syntax;
      // callers decide how to handle unknown keys.
      final q = SearchDslParser.parse('unknownfield:somevalue');
      expect(q.tokens.first, isA<FieldToken>());
      final t = q.tokens.first as FieldToken;
      expect(t.key, 'unknownfield');
      expect(t.value, 'somevalue');
    });

    test('token with no colon is a TextToken', () {
      final q = SearchDslParser.parse('nocodon');
      expect(q.tokens.first, isA<TextToken>());
    });

    test('toQueryString roundtrip — equality', () {
      const t = FieldToken(
        key: 'tracking',
        operator: DslOperator.equals,
        value: 'excellent',
      );
      expect(t.toQueryString(), 'tracking:excellent');
    });

    test('toQueryString roundtrip — negated greaterThan', () {
      const t = FieldToken(
        key: 'range',
        operator: DslOperator.greaterThan,
        value: '800',
        negated: true,
      );
      expect(t.toQueryString(), '-range:>800');
    });

    test('toQueryString quotes values that contain spaces', () {
      const t = FieldToken(
        key: 'role',
        operator: DslOperator.equals,
        value: 'anti armor',
      );
      expect(t.toQueryString(), 'role:"anti armor"');
    });

    test('quoted field token parses correctly', () {
      final q = SearchDslParser.parse('role:"anti armor"');
      expect(q.tokens, hasLength(1));
      final t = q.tokens.first as FieldToken;
      expect(t.key, 'role');
      expect(t.value, 'anti armor');
      expect(t.negated, false);
    });

    test('negated quoted field token parses correctly', () {
      final q = SearchDslParser.parse('-role:"anti armor"');
      final t = q.tokens.first as FieldToken;
      expect(t.key, 'role');
      expect(t.value, 'anti armor');
      expect(t.negated, true);
    });

    test('mixed query with quoted value', () {
      final q = SearchDslParser.parse('laser role:"anti armor" -size:large');
      expect(q.tokens, hasLength(3));
      expect(q.tokens[0], isA<TextToken>());
      final t1 = q.tokens[1] as FieldToken;
      expect(t1.key, 'role');
      expect(t1.value, 'anti armor');
      final t2 = q.tokens[2] as FieldToken;
      expect(t2.key, 'size');
      expect(t2.value, 'large');
      expect(t2.negated, true);
    });

    test('toQueryString quoted roundtrip', () {
      const t = FieldToken(
        key: 'role',
        operator: DslOperator.equals,
        value: 'anti armor',
      );
      final q = SearchDslParser.parse(t.toQueryString());
      final roundtripped = q.tokens.first as FieldToken;
      expect(roundtripped.key, t.key);
      expect(roundtripped.value, t.value);
      expect(roundtripped.negated, t.negated);
    });
  });
}
