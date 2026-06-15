enum DslOperator {
  equals,
  greaterThan,
  lessThan,
  greaterThanOrEqual,
  lessThanOrEqual,
}

extension DslOperatorString on DslOperator {
  String get symbol => switch (this) {
    DslOperator.equals => '',
    DslOperator.greaterThan => '>',
    DslOperator.lessThan => '<',
    DslOperator.greaterThanOrEqual => '>=',
    DslOperator.lessThanOrEqual => '<=',
  };
}

class FieldToken {
  final String key;
  final DslOperator operator;
  final String value;
  final bool negated;

  const FieldToken({
    required this.key,
    required this.operator,
    required this.value,
    this.negated = false,
  });

  String toQueryString() {
    final neg = negated ? '-' : '';
    final v = value.contains(' ') ? '"$value"' : value;
    return '$neg$key:${operator.symbol}$v';
  }
}

class TextToken {
  final String text;
  const TextToken(this.text);
}

class ParsedQuery {
  final List<Object> tokens; // List<FieldToken | TextToken>
  const ParsedQuery(this.tokens);

  bool get isEmpty =>
      tokens.isEmpty ||
      tokens.every((t) => t is TextToken && t.text.trim().isEmpty);
}

class SearchDslParser {
  static final _fieldPatternQuoted =
      RegExp(r'^([^:]+)(:\>=|:\<=|:>|:<|:)"([^"]*)"$');
  static final _fieldPattern = RegExp(r'^([^:]+)(:\>=|:\<=|:>|:<|:)(.+)$');

  static ParsedQuery parse(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const ParsedQuery([]);

    final parts = splitRespectingQuotes(trimmed);
    final tokens = <Object>[];
    for (final part in parts) {
      if (part.isNotEmpty) tokens.add(_parseToken(part));
    }
    return ParsedQuery(tokens);
  }

  /// Splits [text] on whitespace, but spaces inside double-quoted spans are
  /// not split points. An unclosed quote keeps the remainder as one token.
  static List<String> splitRespectingQuotes(String text) {
    final parts = <String>[];
    final current = StringBuffer();
    var inQuote = false;

    for (var i = 0; i < text.length; i++) {
      final c = text[i];
      if (c == '"') {
        inQuote = !inQuote;
        current.write(c);
      } else if (c == ' ' && !inQuote) {
        if (current.isNotEmpty) {
          parts.add(current.toString());
          current.clear();
        }
      } else {
        current.write(c);
      }
    }
    if (current.isNotEmpty) parts.add(current.toString());
    return parts;
  }

  static Object _parseToken(String raw) {
    var text = raw;
    var negated = false;

    if (text.startsWith('-') && text.length > 1) {
      negated = true;
      text = text.substring(1);
    }

    // Quoted value: field:"value with spaces"
    final quotedMatch = _fieldPatternQuoted.firstMatch(text);
    if (quotedMatch != null) {
      return FieldToken(
        key: quotedMatch.group(1)!,
        operator: _parseOp(quotedMatch.group(2)!),
        value: quotedMatch.group(3)!,
        negated: negated,
      );
    }

    // Plain (unquoted) value
    final match = _fieldPattern.firstMatch(text);
    if (match != null) {
      return FieldToken(
        key: match.group(1)!,
        operator: _parseOp(match.group(2)!),
        value: match.group(3)!,
        negated: negated,
      );
    }

    return TextToken(raw);
  }

  static DslOperator _parseOp(String opStr) => switch (opStr) {
    ':>=' => DslOperator.greaterThanOrEqual,
    ':<=' => DslOperator.lessThanOrEqual,
    ':>' => DslOperator.greaterThan,
    ':<' => DslOperator.lessThan,
    _ => DslOperator.equals,
  };
}
