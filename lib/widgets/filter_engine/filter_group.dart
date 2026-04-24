/// Sealed taxonomy of filter groups used by viewer pages.
///
/// All subtypes live in this library so Dart's sealed-class exhaustiveness
/// applies in switch expressions in the renderer.
sealed class FilterGroup<T> {
  String get id;
  String get name;
  bool get isActive;
  int get activeCount;

  bool matches(T item);

  Map<String, Object?> serialize();

  /// Restore state from a persisted `selections` map. Unknown keys and
  /// wrong-typed values MUST be ignored.
  void restore(Map<String, Object?> selections);

  /// Reset to the group's declared default state.
  void clear();
}

/// Tri-state multi-value chip group (the former `GridFilter<T>`).
///
/// State map values: `true` = include, `false` = exclude, `null` = no filter.
class ChipFilterGroup<T> extends FilterGroup<T> {
  @override
  final String id;

  @override
  final String name;

  final String Function(T) valueGetter;
  final List<String> Function(T)? valuesGetter;
  final String Function(String)? displayNameGetter;
  final Comparator<String>? sortComparator;
  final bool useDefaultSort;
  final bool collapsedByDefault;

  final Map<String, bool?> filterStates = {};

  ChipFilterGroup({
    required this.id,
    required this.name,
    required this.valueGetter,
    this.valuesGetter,
    this.displayNameGetter,
    this.sortComparator,
    this.useDefaultSort = false,
    this.collapsedByDefault = false,
  });

  Set<String> get includedValues => filterStates.entries
      .where((e) => e.value == true)
      .map((e) => e.key)
      .toSet();

  Set<String> get excludedValues => filterStates.entries
      .where((e) => e.value == false)
      .map((e) => e.key)
      .toSet();

  @override
  bool get isActive => filterStates.isNotEmpty;

  @override
  int get activeCount => filterStates.length;

  /// Canonical chip-match algorithm (ported from the hullmods variant):
  ///
  /// 1. If any of the item's values is explicitly excluded, reject.
  /// 2. Else if any value in the state map is explicitly included, the item
  ///    must have at least one included value.
  /// 3. Else (only exclusions or empty state), accept.
  @override
  bool matches(T item) {
    if (filterStates.isEmpty) return true;

    final values = valuesGetter != null
        ? valuesGetter!(item)
        : <String>[valueGetter(item)];

    if (values.any((v) => filterStates[v] == false)) return false;

    final hasIncluded = filterStates.values.contains(true);
    if (hasIncluded) {
      return values.any((v) => filterStates[v] == true);
    }

    return true;
  }

  @override
  Map<String, Object?> serialize() => Map<String, Object?>.from(filterStates);

  @override
  void restore(Map<String, Object?> selections) {
    filterStates.clear();
    for (final e in selections.entries) {
      final v = e.value;
      if (v == null) {
        filterStates[e.key] = null;
      } else if (v is bool) {
        filterStates[e.key] = v;
      }
    }
  }

  @override
  void clear() => filterStates.clear();

  /// Replace all selections with [states].
  void setSelections(Map<String, bool?> states) {
    filterStates.clear();
    filterStates.addAll(states);
  }
}

/// A single field inside a [CompositeFilterGroup].
sealed class FilterField<T> {
  String get id;
  String get label;
  bool get isActive;

  bool matches(T item);

  Object? serialize();

  void restoreFrom(Object? value);

  void clear();
}

/// Checkbox field. Predicate applies only when the field is `true`.
class BoolField<T> extends FilterField<T> {
  @override
  final String id;

  @override
  final String label;

  final String? tooltip;
  final bool defaultValue;
  final bool Function(T) predicate;

  bool value;

  BoolField({
    required this.id,
    required this.label,
    required this.predicate,
    this.defaultValue = false,
    this.tooltip,
  }) : value = defaultValue;

  @override
  bool get isActive => value != defaultValue;

  @override
  bool matches(T item) {
    if (!value) return true;
    return predicate(item);
  }

  @override
  Object? serialize() => value;

  @override
  void restoreFrom(Object? v) {
    value = v is bool ? v : defaultValue;
  }

  @override
  void clear() => value = defaultValue;
}

/// Dropdown-backed field over a runtime-populated list of string choices.
///
/// Use this when the option list is data-driven (cannot be an `enum`). A
/// `null` selection represents the "any" / "all" choice. `isActive` reports
/// `selected != defaultValue`.
class StringChoiceField<T> extends FilterField<T> {
  @override
  final String id;

  @override
  final String label;

  final String? tooltip;
  final String? defaultValue;
  final List<String> options;
  final bool Function(T item, String? selected) predicate;
  final String Function(String)? optionLabel;
  final String? allLabel;

  String? selected;

  StringChoiceField({
    required this.id,
    required this.label,
    required this.options,
    required this.predicate,
    this.defaultValue,
    this.tooltip,
    this.optionLabel,
    this.allLabel,
  }) : selected = defaultValue;

  @override
  bool get isActive => selected != defaultValue;

  @override
  bool matches(T item) => predicate(item, selected);

  @override
  Object? serialize() => selected;

  @override
  void restoreFrom(Object? v) {
    if (v == null) {
      selected = null;
      return;
    }
    if (v is String) {
      if (options.contains(v)) {
        selected = v;
        return;
      }
    }
    selected = defaultValue;
  }

  @override
  void clear() => selected = defaultValue;

  void setSelected(String? value) {
    selected = value;
  }

  String labelFor(String? option) {
    if (option == null) return allLabel ?? 'All';
    return optionLabel?.call(option) ?? option;
  }
}

/// Dropdown-backed enum field.
///
/// `isActive` reports `selected != defaultValue`.
class EnumField<T, E extends Enum> extends FilterField<T> {
  @override
  final String id;

  @override
  final String label;

  final String? tooltip;
  final E defaultValue;
  final List<E> options;
  final bool Function(T item, E selected) predicate;
  final String Function(E)? optionLabel;
  final String? Function(E)? optionTooltip;

  /// Optional leading-icon data for dropdown entries. The renderer treats this
  /// as `IconData?`; stored as `Object?` so this data class avoids importing
  /// Flutter.
  final Object? Function(E)? optionIcon;

  E selected;

  EnumField({
    required this.id,
    required this.label,
    required this.defaultValue,
    required this.options,
    required this.predicate,
    this.tooltip,
    this.optionLabel,
    this.optionTooltip,
    this.optionIcon,
  }) : selected = defaultValue;

  @override
  bool get isActive => selected != defaultValue;

  @override
  bool matches(T item) => predicate(item, selected);

  @override
  Object? serialize() => selected.name;

  @override
  void restoreFrom(Object? v) {
    if (v is String) {
      for (final e in options) {
        if (e.name == v) {
          selected = e;
          return;
        }
      }
    }
    selected = defaultValue;
  }

  @override
  void clear() => selected = defaultValue;

  void setSelected(E value) {
    selected = value;
  }

  /// Opaque access used by the renderer to avoid leaking the `E` existential.
  List<Object> get optionValues => options.cast<Object>();

  Object get selectedAsObject => selected;

  void setFromObject(Object? v) {
    if (v is E) selected = v;
  }

  /// Opaque label lookup used by the renderer. Performs the `E` cast here so
  /// callers don't need to know about the existential type.
  String? labelFor(Object option) {
    if (option is! E) return null;
    return optionLabel?.call(option);
  }

  String? tooltipFor(Object option) {
    if (option is! E) return null;
    return optionTooltip?.call(option);
  }

  Object? iconFor(Object option) {
    if (option is! E) return null;
    return optionIcon?.call(option);
  }
}

/// Heterogeneous group holding an ordered list of [FilterField]s under a
/// single lock (one persistence unit).
///
/// `matches` is the AND of all field predicates; `isActive` is true if any
/// field is active.
class CompositeFilterGroup<T> extends FilterGroup<T> {
  @override
  final String id;

  @override
  final String name;

  final List<FilterField<T>> fields;

  CompositeFilterGroup({
    required this.id,
    required this.name,
    required this.fields,
  });

  @override
  bool get isActive => fields.any((f) => f.isActive);

  @override
  int get activeCount => fields.where((f) => f.isActive).length;

  @override
  bool matches(T item) {
    for (final f in fields) {
      if (!f.matches(item)) return false;
    }
    return true;
  }

  @override
  Map<String, Object?> serialize() => {
    for (final f in fields) f.id: f.serialize(),
  };

  @override
  void restore(Map<String, Object?> selections) {
    for (final f in fields) {
      if (selections.containsKey(f.id)) {
        f.restoreFrom(selections[f.id]);
      }
    }
  }

  @override
  void clear() {
    for (final f in fields) {
      f.clear();
    }
  }

  FilterField<T>? fieldById(String fieldId) {
    for (final f in fields) {
      if (f.id == fieldId) return f;
    }
    return null;
  }
}

/// Standalone (non-composite) boolean filter group. Renders as a checkbox
/// with no lock (persistence only via wrapping in [CompositeFilterGroup]).
class BoolFilterGroup<T> extends FilterGroup<T> {
  @override
  final String id;

  @override
  final String name;

  final String? tooltip;
  final bool defaultValue;
  final bool Function(T) predicate;

  bool value;

  BoolFilterGroup({
    required this.id,
    required this.name,
    required this.predicate,
    this.defaultValue = false,
    this.tooltip,
  }) : value = defaultValue;

  @override
  bool get isActive => value != defaultValue;

  @override
  int get activeCount => isActive ? 1 : 0;

  @override
  bool matches(T item) => !value || predicate(item);

  @override
  Map<String, Object?> serialize() => {'value': value};

  @override
  void restore(Map<String, Object?> selections) {
    final v = selections['value'];
    value = v is bool ? v : defaultValue;
  }

  @override
  void clear() => value = defaultValue;
}

/// Standalone (non-composite) enum filter group. Renders as a dropdown with
/// no lock.
class EnumFilterGroup<T, E extends Enum> extends FilterGroup<T> {
  @override
  final String id;

  @override
  final String name;

  final String? tooltip;
  final E defaultValue;
  final List<E> options;
  final bool Function(T item, E selected) predicate;
  final String Function(E)? optionLabel;
  final String? Function(E)? optionTooltip;
  final Object? Function(E)? optionIcon;

  E selected;

  EnumFilterGroup({
    required this.id,
    required this.name,
    required this.defaultValue,
    required this.options,
    required this.predicate,
    this.tooltip,
    this.optionLabel,
    this.optionTooltip,
    this.optionIcon,
  }) : selected = defaultValue;

  @override
  bool get isActive => selected != defaultValue;

  @override
  int get activeCount => isActive ? 1 : 0;

  @override
  bool matches(T item) => predicate(item, selected);

  @override
  Map<String, Object?> serialize() => {'value': selected.name};

  @override
  void restore(Map<String, Object?> selections) {
    final v = selections['value'];
    if (v is String) {
      for (final e in options) {
        if (e.name == v) {
          selected = e;
          return;
        }
      }
    }
    selected = defaultValue;
  }

  @override
  void clear() => selected = defaultValue;

  List<Object> get optionValues => options.cast<Object>();

  Object get selectedAsObject => selected;

  void setFromObject(Object? v) {
    if (v is E) selected = v;
  }

  String? labelFor(Object option) {
    if (option is! E) return null;
    return optionLabel?.call(option);
  }

  String? tooltipFor(Object option) {
    if (option is! E) return null;
    return optionTooltip?.call(option);
  }

  Object? iconFor(Object option) {
    if (option is! E) return null;
    return optionIcon?.call(option);
  }
}
