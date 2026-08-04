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

/// How a chip group treats the values the user marked "include".
enum ChipLogicMode {
  /// The item needs at least one of the included values. This is the default
  /// and how chip groups have always worked.
  any,

  /// The item needs every included value. Lets you ask for combinations, e.g.
  /// a ship with both a large ballistic slot and a large missile slot.
  all,
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

  /// Key used to store [logicMode] alongside the chip states in the persisted
  /// map. Starts with an underscore so it can't collide with a real value.
  static const String logicKey = '_logic';

  /// Whether included values are combined with "any" or "all".
  ChipLogicMode logicMode;

  /// Every value the current data has, as of the last [updateKnownValues].
  /// Empty means "we haven't looked", and nothing is treated as unknown.
  Set<String> _knownValues = const {};

  ChipFilterGroup({
    required this.id,
    required this.name,
    required this.valueGetter,
    this.valuesGetter,
    this.displayNameGetter,
    this.sortComparator,
    this.useDefaultSort = false,
    this.collapsedByDefault = false,
    this.logicMode = ChipLogicMode.any,
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
  ///    must have at least one included value ("any" mode) or all of them
  ///    ("all" mode).
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
      if (logicMode == ChipLogicMode.all) {
        return requiredValues.every(values.contains);
      }
      return values.any((v) => filterStates[v] == true);
    }

    return true;
  }

  /// The included values "all" mode actually asks for.
  ///
  /// Picks stay put when a mod is turned off, so a group can hold values the
  /// current data has never heard of and shows no chip for. In "any" mode
  /// those sit there harmlessly; in "all" mode they would demand something
  /// nothing has, emptying the list with nothing on screen to explain it. So
  /// they're skipped, the same way the rest of the engine leaves values it
  /// doesn't recognise inert.
  Iterable<String> get requiredValues => _knownValues.isEmpty
      ? includedValues
      : includedValues.where(_knownValues.contains);

  /// Record which values [items] actually have, for [requiredValues].
  void updateKnownValues(Iterable<T> items) {
    final seen = <String>{};
    for (final item in items) {
      if (valuesGetter != null) {
        seen.addAll(valuesGetter!(item));
      } else {
        seen.add(valueGetter(item));
      }
    }
    _knownValues = seen;
  }

  @override
  Map<String, Object?> serialize() => {
    ...filterStates,
    if (logicMode != ChipLogicMode.any) logicKey: logicMode.name,
  };

  @override
  void restore(Map<String, Object?> selections) {
    filterStates.clear();
    restoreLogicMode(selections[logicKey]);
    for (final e in selections.entries) {
      if (e.key == logicKey) continue;
      final v = e.value;
      if (v == null) {
        filterStates[e.key] = null;
      } else if (v is bool) {
        filterStates[e.key] = v;
      }
    }
  }

  /// Reads a persisted logic mode name. Anything unrecognised falls back to
  /// [ChipLogicMode.any].
  void restoreLogicMode(Object? value) {
    for (final mode in ChipLogicMode.values) {
      if (mode.name == value) {
        logicMode = mode;
        return;
      }
    }
    logicMode = ChipLogicMode.any;
  }

  @override
  void clear() {
    filterStates.clear();
    logicMode = ChipLogicMode.any;
  }

  /// Replace all selections with [states].
  void setSelections(Map<String, bool?> states) {
    filterStates.clear();
    filterStates.addAll(states);
  }
}

/// Numeric range group, shown as a two-handle slider.
///
/// [min] and [max] are the range found in the data; call [updateRange] when
/// the item list changes. [curMin] and [curMax] are what the user picked. The
/// group only filters while the handles are inside the data range.
///
/// Items with no value for this stat (a null getter result) are dropped while
/// the filter is on — "between 10 and 30" can't be true of a missing number.
class RangeFilterGroup<T> extends FilterGroup<T> {
  @override
  final String id;

  @override
  final String name;

  final num? Function(T) valueGetter;

  /// Shown after the numbers, e.g. "su" or "%". Optional.
  final String? suffix;

  /// When true, the top handle at the far right means "and above", so nothing
  /// falls off the end when new mods add higher values.
  final bool allowGreater;

  num min = 0;
  num max = 0;
  num curMin = 0;
  num curMax = 0;

  /// Every distinct value in the data, sorted. Handles snap to these.
  List<num> stops = const [];

  /// True once [updateRange] has seen at least one item with a value.
  bool hasData = false;

  // Selection read from settings before the data was loaded. Applied (and
  // clamped) by the next [updateRange].
  num? _pendingMin;
  num? _pendingMax;

  RangeFilterGroup({
    required this.id,
    required this.name,
    required this.valueGetter,
    this.suffix,
    this.allowGreater = true,
  });

  @override
  bool get isActive => hasData && (curMin > min || curMax < max);

  @override
  int get activeCount => isActive ? 1 : 0;

  @override
  bool matches(T item) {
    if (!isActive) return true;
    final value = valueGetter(item);
    if (value == null) return false;
    if (value < curMin) return false;
    if (allowGreater && curMax >= max) return true;
    return value <= curMax;
  }

  /// Recompute [min]/[max]/[stops] from [items] and keep the user's selection
  /// sensible. A handle sitting at either end stays at that end.
  void updateRange(Iterable<T> items) {
    final values = <num>{};
    for (final item in items) {
      final value = valueGetter(item);
      if (value != null) values.add(value);
    }

    if (values.isEmpty) {
      hasData = false;
      min = 0;
      max = 0;
      curMin = 0;
      curMax = 0;
      stops = const [];
      return;
    }

    final sorted = values.toList()..sort();
    final wasAtBottom = !hasData || curMin <= min;
    final wasAtTop = !hasData || curMax >= max;

    stops = sorted;
    min = sorted.first;
    max = sorted.last;
    hasData = true;

    if (_pendingMin != null || _pendingMax != null) {
      curMin = (_pendingMin ?? min).clamp(min, max);
      curMax = (_pendingMax ?? max).clamp(min, max);
      _pendingMin = null;
      _pendingMax = null;
      return;
    }

    curMin = wasAtBottom ? min : curMin.clamp(min, max);
    curMax = wasAtTop ? max : curMax.clamp(min, max);
  }

  /// Position in [stops] of the value nearest [value].
  ///
  /// Sliders run over these positions rather than over the numbers
  /// themselves. Stats like hull run from 30 to ten million, so spacing a
  /// slider by value would squash every real ship into the first sliver of
  /// the track. One notch per real value keeps all of it reachable.
  int stopIndexFor(num value) {
    if (stops.isEmpty) return 0;
    var low = 0;
    var high = stops.length - 1;
    while (low < high) {
      final mid = (low + high) ~/ 2;
      if (stops[mid] < value) {
        low = mid + 1;
      } else {
        high = mid;
      }
    }
    // `low` is the first stop at or above the value; the one below it may be
    // the closer of the two.
    if (low > 0 &&
        (stops[low] - value).abs() > (value - stops[low - 1]).abs()) {
      return low - 1;
    }
    return low;
  }

  /// Nearest value that actually exists in the data, so handles land on
  /// meaningful stops instead of arbitrary decimals.
  num snapTo(num value) {
    if (stops.isEmpty) return value;
    return stops[stopIndexFor(value)];
  }

  void setRange(num newMin, num newMax) {
    curMin = newMin.clamp(min, max);
    curMax = newMax.clamp(min, max);
  }

  @override
  Map<String, Object?> serialize() => {'min': curMin, 'max': curMax};

  @override
  void restore(Map<String, Object?> selections) {
    final low = selections['min'];
    final high = selections['max'];
    _pendingMin = low is num ? low : null;
    _pendingMax = high is num ? high : null;
    if (hasData) {
      curMin = (_pendingMin ?? min).clamp(min, max);
      curMax = (_pendingMax ?? max).clamp(min, max);
      _pendingMin = null;
      _pendingMax = null;
    }
  }

  @override
  void clear() {
    _pendingMin = null;
    _pendingMax = null;
    curMin = min;
    curMax = max;
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

  /// Optional live count shown as a badge next to the field label (e.g. how
  /// many items currently match). Evaluated at render time; return 0 or less
  /// to hide the badge. Opt-in — most fields leave this null.
  final int Function()? badgeCount;

  bool value;

  BoolField({
    required this.id,
    required this.label,
    required this.predicate,
    this.defaultValue = false,
    bool? initialValue,
    this.tooltip,
    this.badgeCount,
  }) : value = initialValue ?? defaultValue;

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

  final bool alwaysActive;

  /// When set, the filter is considered "inactive" when [selected] equals this
  /// value instead of [defaultValue]. Useful when the initial selection should
  /// still count as an active filter (e.g. "No spoilers" hides content by
  /// default, so the user should see it flagged).
  final E? inactiveValue;

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
    this.alwaysActive = false,
    this.inactiveValue,
  }) : selected = defaultValue;

  @override
  bool get isActive =>
      alwaysActive || selected != (inactiveValue ?? defaultValue);

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
