import 'package:trios/faction_viewer/models/faction.dart';
import 'package:trios/fighter_viewer/models/wing.dart';
import 'package:trios/hullmod_viewer/models/hullmod.dart';
import 'package:trios/ship_systems_manager/ship_system.dart';
import 'package:trios/ship_viewer/models/ship.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/weapon_viewer/models/weapon.dart';

/// The six Codex categories. One value per data type the Codex can hold.
enum CodexEntryType { ship, weapon, hullmod, shipSystem, wing, faction }

/// Called when a clickable cross-reference inside a codex card is tapped. Null
/// on the viewer tabs (references stay hover-only); set to the Codex
/// controller's `select` inside the Codex detail panel so a click navigates.
typedef CodexEntitySelected = void Function((CodexEntryType, String) key);

/// A single entry in the combined Codex index. One subclass per category, each
/// wrapping the existing data object (no data is copied). Kept Flutter-free —
/// icons are keyed off [type] in the page, not stored here.
///
/// `(type, id)` is the stable key used for links, history, and navigation.
sealed class CodexEntry {
  const CodexEntry();

  /// The game id. `(type, id)` is the stable key.
  String get id;

  CodexEntryType get type;

  /// Name shown in the list and detail panel.
  String get displayName;

  /// What alphabetical sort uses. Ships sort by their hull name.
  String get sortName;

  /// Grey second line on the list row. Null hides it.
  String? get subtitle;

  /// Mod ids this entry belongs to, for the mod filter. Empty = vanilla. A set
  /// because a faction can come from several mods at once.
  Set<String> get modIds;

  /// The stable key: `(type, id)`.
  (CodexEntryType, String) get key => (type, id);
}

class ShipCodexEntry extends CodexEntry {
  final Ship ship;

  const ShipCodexEntry(this.ship);

  @override
  String get id => ship.id;

  @override
  CodexEntryType get type => CodexEntryType.ship;

  @override
  String get displayName => ship.name ?? ship.id;

  @override
  String get sortName => ship.hullNameForDisplay();

  @override
  String? get subtitle => ship.designation;

  @override
  Set<String> get modIds => {?ship.modVariant?.modInfo.id};
}

class WeaponCodexEntry extends CodexEntry {
  final Weapon weapon;

  const WeaponCodexEntry(this.weapon);

  @override
  String get id => weapon.id;

  @override
  CodexEntryType get type => CodexEntryType.weapon;

  @override
  String get displayName => weapon.name ?? weapon.id;

  @override
  String get sortName => displayName;

  @override
  String? get subtitle {
    final size = weapon.size;
    final weaponType = weapon.weaponType;
    if (size == null || weaponType == null) return null;
    return '${size.toTitleCase()} ${weaponType.toLowerCase()} weapon';
  }

  @override
  Set<String> get modIds => {?weapon.modVariant?.modInfo.id};
}

class HullmodCodexEntry extends CodexEntry {
  final Hullmod hullmod;

  const HullmodCodexEntry(this.hullmod);

  @override
  String get id => hullmod.id;

  @override
  CodexEntryType get type => CodexEntryType.hullmod;

  @override
  String get displayName => hullmod.name ?? hullmod.id;

  @override
  String get sortName => displayName;

  @override
  String? get subtitle => hullmod.uiTags;

  @override
  Set<String> get modIds => {?hullmod.modVariant?.modInfo.id};
}

class ShipSystemCodexEntry extends CodexEntry {
  final ShipSystem system;

  /// The description's short "type" line (`text2`), resolved by the index
  /// provider (the model itself can't read descriptions). Also drives the Type
  /// facet ("Special" when null).
  final String? shortType;

  const ShipSystemCodexEntry(this.system, {this.shortType});

  @override
  String get id => system.id;

  @override
  CodexEntryType get type => CodexEntryType.shipSystem;

  @override
  String get displayName => system.name ?? system.id;

  @override
  String get sortName => displayName;

  @override
  String? get subtitle => shortType;

  @override
  Set<String> get modIds => {?system.modVariant?.modInfo.id};
}

class WingCodexEntry extends CodexEntry {
  final Wing wing;

  /// Name of the ship behind the wing, resolved by the index provider (the wing
  /// row itself has no name column). Falls back to the wing id when the ship
  /// could not be resolved.
  final String? shipName;

  const WingCodexEntry(this.wing, {this.shipName});

  @override
  String get id => wing.id;

  @override
  CodexEntryType get type => CodexEntryType.wing;

  @override
  String get displayName => shipName ?? wing.id;

  @override
  String get sortName => displayName;

  @override
  String? get subtitle => wing.role?.toTitleCase();

  @override
  Set<String> get modIds => {?wing.modVariant?.modInfo.id};
}

class FactionCodexEntry extends CodexEntry {
  final Faction faction;

  const FactionCodexEntry(this.faction);

  @override
  String get id => faction.id;

  @override
  CodexEntryType get type => CodexEntryType.faction;

  @override
  String get displayName => faction.displayNameBest;

  @override
  String get sortName => displayName;

  @override
  String? get subtitle => null;

  @override
  Set<String> get modIds => faction.sources
      .map((s) => s.modVariant?.modInfo.id as String?)
      .whereType<String>()
      .toSet();
}
