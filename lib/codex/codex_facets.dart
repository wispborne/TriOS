import 'package:trios/codex/models/codex_entry.dart';
import 'package:trios/ship_viewer/models/ship.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/widgets/filter_engine/filter_group.dart';

/// Builds the facet chip groups for [category], mirroring the viewer pages'
/// definitions (design section 6). Groups operate on [CodexEntry] and cast to
/// the category's subclass — safe because a category's list is all one type.
///
/// [itemsFor] returns the current spoiler+mod-filtered entries of the category
/// (used for the tech/manufacturer most-common-spelling label). [shipForHull]
/// resolves a wing's ship for the fighters' tech/manufacturer facet.
List<ChipFilterGroup<CodexEntry>> buildCodexFacetGroups(
  CodexEntryType category, {
  required List<CodexEntry> Function() itemsFor,
  required Ship? Function(String hullId) shipForHull,
}) {
  switch (category) {
    case CodexEntryType.ship:
      return [
        _techManufacturerGroup(
          itemsFor,
          (e) => (e as ShipCodexEntry).ship.techManufacturer,
        ),
        ChipFilterGroup<CodexEntry>(
          id: 'size',
          name: 'Size',
          valueGetter: (e) => (e as ShipCodexEntry).ship.hullSizeForDisplay(),
          useDefaultSort: true,
        ),
        ChipFilterGroup<CodexEntry>(
          id: 'type',
          name: 'Type',
          valueGetter: (e) => _shipType((e as ShipCodexEntry).ship),
        ),
      ];
    // Stations share the ship data type; they only need tech/manufacturer and
    // type facets (their size is always "Station").
    case CodexEntryType.station:
      return [
        _techManufacturerGroup(
          itemsFor,
          (e) => (e as ShipCodexEntry).ship.techManufacturer,
        ),
        ChipFilterGroup<CodexEntry>(
          id: 'type',
          name: 'Type',
          valueGetter: (e) => _shipType((e as ShipCodexEntry).ship),
        ),
      ];
    case CodexEntryType.weapon:
      return [
        _techManufacturerGroup(
          itemsFor,
          (e) => (e as WeaponCodexEntry).weapon.techManufacturer,
        ),
        ChipFilterGroup<CodexEntry>(
          id: 'size',
          name: 'Size',
          valueGetter: (e) => (e as WeaponCodexEntry).weapon.size ?? '',
          displayNameGetter: (v) => v.toTitleCase(),
          sortComparator: (a, b) {
            const order = ['SMALL', 'MEDIUM', 'LARGE'];
            // Unknown (modded) sizes sort after the known ones, alphabetically
            // among themselves — never all collapsed to the same rank.
            final ai = order.indexOf(a);
            final bi = order.indexOf(b);
            final ar = ai < 0 ? order.length : ai;
            final br = bi < 0 ? order.length : bi;
            return ar != br ? ar.compareTo(br) : a.compareTo(b);
          },
        ),
        ChipFilterGroup<CodexEntry>(
          id: 'type',
          name: 'Type',
          valueGetter: (e) => (e as WeaponCodexEntry).weapon.weaponType ?? '',
          displayNameGetter: (v) => v.toTitleCase(),
        ),
        ChipFilterGroup<CodexEntry>(
          id: 'mountType',
          name: 'Mount type',
          valueGetter: (e) {
            final w = (e as WeaponCodexEntry).weapon;
            return w.mountTypeOverride ?? w.weaponType ?? '';
          },
          displayNameGetter: (v) => v.toTitleCase(),
        ),
        ChipFilterGroup<CodexEntry>(
          id: 'damageType',
          name: 'Damage type',
          valueGetter: (e) => (e as WeaponCodexEntry).weapon.damageType ?? '',
          displayNameGetter: (v) => v.toTitleCase(),
        ),
      ];
    case CodexEntryType.hullmod:
      return [
        _techManufacturerGroup(
          itemsFor,
          (e) => (e as HullmodCodexEntry).hullmod.techManufacturer,
        ),
        ChipFilterGroup<CodexEntry>(
          id: 'type',
          name: 'Type',
          valueGetter: (e) => '',
          valuesGetter: (e) =>
              (e as HullmodCodexEntry).hullmod.uiTags
                  ?.split(',')
                  .map((t) => t.trim())
                  .where((t) => t.isNotEmpty)
                  .toList() ??
              const [],
          displayNameGetter: (v) => v.toTitleCase(),
        ),
      ];
    case CodexEntryType.wing:
      return [
        _techManufacturerGroup(itemsFor, (e) {
          final wing = (e as WingCodexEntry).wing;
          final hull = wing.hullId;
          return hull == null ? null : shipForHull(hull)?.techManufacturer;
        }),
        ChipFilterGroup<CodexEntry>(
          id: 'role',
          name: 'Role',
          valueGetter: (e) => (e as WingCodexEntry).wing.role ?? '',
          displayNameGetter: (v) => v.toTitleCase(),
        ),
      ];
    case CodexEntryType.shipSystem:
      return [
        ChipFilterGroup<CodexEntry>(
          id: 'type',
          name: 'Type',
          valueGetter: (e) =>
              (e as ShipSystemCodexEntry).shortType ?? 'Special',
        ),
      ];
    case CodexEntryType.faction:
      return const [];
  }
}

/// The ship's one Type value, by the game's precedence.
String _shipType(Ship ship) {
  if ((ship.fighterBays ?? 0) > 0) return 'Carrier';
  final hints = (ship.hints ?? const <String>[]).map((h) => h.toUpperCase());
  if (hints.contains('CIVILIAN')) return 'Civilian';
  if (ship.shieldType == 'PHASE' || hints.contains('PHASE')) return 'Phase';
  return 'Warship';
}

/// A tech/manufacturer group case-folded for grouping, labeled by the most
/// common original spelling (copying the ships page's approach).
ChipFilterGroup<CodexEntry> _techManufacturerGroup(
  List<CodexEntry> Function() itemsFor,
  String? Function(CodexEntry) rawOf,
) {
  // Labels need a full scan of the entry list, and the chip bar asks for every
  // chip's label on each rebuild — so build all labels once per list instance
  // rather than rescanning per chip.
  List<CodexEntry>? labeledItems;
  var labels = const <String, String>{};
  return ChipFilterGroup<CodexEntry>(
    id: 'techManufacturer',
    name: 'Tech/manufacturer',
    collapsedByDefault: true,
    valueGetter: (e) => (rawOf(e) ?? '').toUpperCase(),
    displayNameGetter: (upper) {
      final items = itemsFor();
      if (!identical(items, labeledItems)) {
        labels = _techLabels(items, rawOf);
        labeledItems = items;
      }
      return labels[upper] ?? upper.toTitleCase();
    },
  );
}

/// Maps each case-folded tech/manufacturer to its most common original
/// spelling among [entries].
Map<String, String> _techLabels(
  List<CodexEntry> entries,
  String? Function(CodexEntry) rawOf,
) {
  final spellingCountsByUpper = <String, Map<String, int>>{};
  for (final e in entries) {
    final raw = rawOf(e);
    if (raw == null || raw.isEmpty) continue;
    final bySpelling = spellingCountsByUpper.putIfAbsent(
      raw.toUpperCase(),
      () => {},
    );
    bySpelling[raw] = (bySpelling[raw] ?? 0) + 1;
  }
  return spellingCountsByUpper.map(
    (upper, bySpelling) => MapEntry(
      upper,
      bySpelling.entries.reduce((a, b) => b.value > a.value ? b : a).key,
    ),
  );
}
