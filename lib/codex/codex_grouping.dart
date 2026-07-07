import 'package:trios/codex/models/codex_entry.dart';
import 'package:trios/widgets/filter_engine/filter_group.dart';

/// One way to group a category's list into labeled sections. Options mirror
/// the viewer pages' grid groupings: "None", "Mod", plus one per facet chip
/// group so section labels match the filter chips exactly.
class CodexGrouping {
  final String id;
  final String label;

  /// The raw group keys for an entry. Usually one; multi-value facets
  /// (hullmod tags) and multi-mod factions can give several. Empty puts the
  /// entry in the "Other" section.
  final List<String> Function(CodexEntry entry) keysOf;

  /// Turns a raw key into the section label. Null = use the key itself.
  final String Function(String key)? displayNameOf;

  /// Orders the raw keys. Null = alphabetical by label.
  final Comparator<String>? sortComparator;

  const CodexGrouping({
    required this.id,
    required this.label,
    required this.keysOf,
    this.displayNameOf,
    this.sortComparator,
  });

  bool get isNone => id == 'none';

  String labelOf(String key) =>
      key.isEmpty ? 'Other' : (displayNameOf?.call(key) ?? key);
}

/// The grouping options for a category. [facets] are the category's facet chip
/// groups; [modNameOf] resolves a mod id to its display name.
List<CodexGrouping> buildCodexGroupings({
  required List<ChipFilterGroup<CodexEntry>> facets,
  required String Function(String modId) modNameOf,
}) {
  return [
    CodexGrouping(id: 'none', label: 'None', keysOf: (_) => const []),
    CodexGrouping(
      id: 'mod',
      label: 'Mod',
      keysOf: (e) => e.modIds.isEmpty
          ? const ['Vanilla']
          : e.modIds.map(modNameOf).toList(),
      // Vanilla first, then mods alphabetically (same as the viewer grids).
      sortComparator: (a, b) {
        if (a == 'Vanilla') return b == 'Vanilla' ? 0 : -1;
        if (b == 'Vanilla') return 1;
        return a.toLowerCase().compareTo(b.toLowerCase());
      },
    ),
    for (final facet in facets)
      CodexGrouping(
        id: facet.id,
        label: facet.name,
        keysOf: (e) {
          final values = facet.valuesGetter != null
              ? facet.valuesGetter!(e)
              : [facet.valueGetter(e)];
          return values.where((v) => v.isNotEmpty).toList();
        },
        displayNameOf: facet.displayNameGetter,
        sortComparator: facet.sortComparator,
      ),
  ];
}
