import 'package:trios/widgets/smart_search/search_dsl_parser.dart';
export 'package:trios/widgets/smart_search/search_dsl_parser.dart'
    show DslOperator;

/// Untyped field metadata passed to the widget for autocomplete and info panel.
class SearchFieldMeta {
  final String key;
  final String description;
  final bool supportsNumeric;
  final bool supportsNegation;
  final List<String> Function() valueSuggestions;

  const SearchFieldMeta({
    required this.key,
    required this.description,
    this.supportsNumeric = false,
    this.supportsNegation = true,
    required this.valueSuggestions,
  });
}

/// Typed field definition owned by the page controller.
/// The widget only sees [SearchFieldMeta]; matching happens in the controller.
class SearchField<T> {
  final String key;
  final String description;
  final bool supportsNumeric;
  final bool supportsNegation;
  final List<String> Function(List<T> items) valueSuggestions;
  final bool Function(T item, DslOperator operator, String value) matches;

  const SearchField({
    required this.key,
    required this.description,
    this.supportsNumeric = false,
    this.supportsNegation = true,
    required this.valueSuggestions,
    required this.matches,
  });

  SearchFieldMeta toMeta(List<T> items) => SearchFieldMeta(
    key: key,
    description: description,
    supportsNumeric: supportsNumeric,
    supportsNegation: supportsNegation,
    valueSuggestions: () => valueSuggestions(items),
  );

  static SearchField<T> numeric<T>(
    String key,
    String description,
    num? Function(T) accessor,
  ) => SearchField<T>(
    key: key,
    description: '$description; supports numeric operators',
    supportsNumeric: true,
    valueSuggestions: (_) => [],
    matches: (item, op, value) {
      final numVal = double.tryParse(value);
      if (numVal == null) return false;
      final v = accessor(item);
      if (v == null) return false;
      return switch (op) {
        DslOperator.equals => v == numVal,
        DslOperator.greaterThan => v > numVal,
        DslOperator.lessThan => v < numVal,
        DslOperator.greaterThanOrEqual => v >= numVal,
        DslOperator.lessThanOrEqual => v <= numVal,
      };
    },
  );

  static SearchField<T> string<T>(
    String key,
    String description,
    String? Function(T) accessor,
  ) => SearchField<T>(
    key: key,
    description: description,
    valueSuggestions: (items) => items
        .map((i) => accessor(i)?.toLowerCase())
        .whereType<String>()
        .where((v) => v.isNotEmpty)
        .toSet()
        .toList()
      ..sort(),
    matches: (item, op, value) {
      if (op != DslOperator.equals) return false;
      return accessor(item)?.toLowerCase() == value.toLowerCase();
    },
  );

  static SearchField<T> multiValue<T>(
    String key,
    String description,
    List<String>? Function(T) accessor,
  ) => SearchField<T>(
    key: key,
    description: description,
    valueSuggestions: (items) => items
        .expand((i) => accessor(i) ?? <String>[])
        .map((v) => v.toLowerCase())
        .where((v) => v.isNotEmpty)
        .toSet()
        .toList()
      ..sort(),
    matches: (item, op, value) {
      if (op != DslOperator.equals) return false;
      return accessor(item)?.any(
        (v) => v.toLowerCase() == value.toLowerCase(),
      ) ?? false;
    },
  );

  /// Filter [items] using a DSL query string, matching against [fieldsByKey]
  /// for field tokens and falling back to substring search on [searchIndices]
  /// for plain text tokens.
  static List<T> applyQuery<T>(
    List<T> items,
    String query,
    Map<String, SearchField<T>> fieldsByKey,
    Map<String, List<String>> searchIndices,
    String Function(T) idOf,
  ) {
    if (query.trim().isEmpty) return items;

    final parsed = SearchDslParser.parse(query);
    if (parsed.isEmpty) return items;

    final preparedTokens = [
      for (final token in parsed.tokens)
        if (token is TextToken)
          (token: token, lowered: token.text.toLowerCase())
        else if (token is FieldToken)
          (
            token: token,
            lowered: fieldsByKey.containsKey(token.key)
                ? ''
                : token.toQueryString().toLowerCase(),
          ),
    ];

    return items.where((item) {
      final values = searchIndices[idOf(item)];
      for (final entry in preparedTokens) {
        final token = entry.token;
        if (token is TextToken) {
          if (!(values?.any((v) => v.contains(entry.lowered)) ?? false)) {
            return false;
          }
        } else if (token is FieldToken) {
          final field = fieldsByKey[token.key];
          final bool result;
          if (field == null) {
            result = values?.any((v) => v.contains(entry.lowered)) ?? false;
          } else {
            result = field.matches(item, token.operator, token.value);
          }
          if (token.negated ? result : !result) return false;
        }
      }
      return true;
    }).toList();
  }
}
