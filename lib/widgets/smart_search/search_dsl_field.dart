import 'package:trios/widgets/smart_search/search_dsl_parser.dart';

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
}
