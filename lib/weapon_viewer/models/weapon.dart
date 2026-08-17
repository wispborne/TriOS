// weapon.dart

import 'dart:io';

import 'package:dart_mappable/dart_mappable.dart';
import 'package:trios/mod_manager/homebrew_grid/wisp_grid.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/utils/dart_mappable_utils.dart';
import 'package:trios/utils/game_data_merge.dart';
import 'package:trios/utils/mod_data_files.dart';
import 'package:trios/weapon_viewer/models/weapon_derived_stats.dart';

part 'weapon.mapper.dart';

@MappableClass(caseStyle: CaseStyle.lowerCase)
class Weapon with WeaponMappable implements WispGridItem {
  @override
  String get key => id;

  final String id;
  final String? name;
  final int? tier;
  final double? rarity;
  @MappableField(key: 'base value')
  final double? baseValue;
  final double? range;
  @MappableField(key: 'damage/second')
  final double? damagePerSecond;
  @MappableField(key: 'damage/shot')
  final double? damagePerShot;
  final double? emp;
  final double? impact;
  @MappableField(key: 'turn rate')
  final double? turnRate;
  final int? ops;
  final double? ammo;
  @MappableField(key: 'ammo/sec')
  final double? ammoPerSec;
  @MappableField(key: 'reload size')
  final double? reloadSize;

  /// The `type` column of `weapon_data.csv`, which holds the damage type
  /// (`KINETIC`, `HIGH_EXPLOSIVE`, and so on) — not the mount. The mount is
  /// [weaponType]. Kept raw; [damageType] is the one to read.
  final String? type;
  @MappableField(key: 'energy/shot')
  final double? energyPerShot;
  @MappableField(key: 'energy/second')
  final double? energyPerSecond;
  final double? chargeup;
  final double? chargedown;
  @MappableField(key: 'burst size')
  final double? burstSize;
  @MappableField(key: 'burst delay')
  final double? burstDelay;
  @MappableField(key: 'min spread')
  final double? minSpread;
  @MappableField(key: 'max spread')
  final double? maxSpread;
  @MappableField(key: 'spread/shot')
  final double? spreadPerShot;
  @MappableField(key: 'spread decay/sec')
  final double? spreadDecayPerSec;
  @MappableField(key: 'beam speed')
  final double? beamSpeed;
  @MappableField(key: 'proj speed')
  final double? projSpeed;
  @MappableField(key: 'launch speed')
  final double? launchSpeed;
  @MappableField(key: 'flight time')
  final double? flightTime;
  @MappableField(key: 'proj hitpoints')
  final double? projHitpoints;
  final double? autofireAccBonus;
  final double? extraArcForAI;
  final String? hints;
  final String? tags;
  final String? groupTag;
  @MappableField(key: 'tech/manufacturer')
  final String? techManufacturer;
  @MappableField(key: 'for weapon tooltip>>')
  final String? forWeaponTooltip;
  final String? primaryRoleStr;
  final String? speedStr;
  final String? trackingStr;
  final String? turnRateStr;
  final String? accuracyStr;
  final String? customPrimary;
  final String? customPrimaryHL;
  final String? customAncillary;
  final String? customAncillaryHL;
  final bool? noDPSInTooltip;

  // Fields from the .wpn files
  final String? specClass;

  /// The mount this weapon fits: `BALLISTIC`, `ENERGY` or `MISSILE`. The `.wpn`
  /// file calls this `type`; it is read under another name because
  /// `weapon_data.csv` uses `type` for the damage type, which is [type] here.
  @MappableField(key: 'mounttype')
  final String? weaponType;
  final String? size;
  final String? damageType;
  final String? turretSprite;
  final String? turretGunSprite;
  final String? hardpointSprite;
  final String? hardpointGunSprite;
  final String? turretUnderSprite;
  final String? hardpointUnderSprite;
  final String? turretGlowSprite;
  final String? hardpointGlowSprite;

  /// `[r, g, b, a]` (0-255) from the .wpn, used to tint the (additive) glow sprite.
  final List<double>? glowColor;

  /// Raw `renderHints` list from the .wpn, e.g. `RENDER_BARREL_BELOW`,
  /// `RENDER_LOADED_MISSILES`.
  final List<String>? renderHints;

  /// Projectile fired by this weapon; used to look up loaded-missile sprites.
  final String? projectileSpecId;

  /// How the barrels fire, from the `.wpn`: `ALTERNATING` (default, one
  /// barrel per shot), `LINKED` (every barrel at once), `DUAL_LINKED` (two at
  /// once), or `ALTERNATING_BURST`. LINKED and DUAL_LINKED multiply each
  /// shot's damage and flux — see [barrelCount].
  final String? barrelMode;

  /// `.wpn` flag: the burst can be cut short by releasing the trigger. The
  /// game's tooltip then treats the weapon as firing single shots — no burst
  /// size row, no `xN` damage suffix, and the refire delay is just the
  /// chargedown (`CargoTooltipFactory`). The derived DPS is unaffected.
  final bool? interruptibleBurst;

  /// `.wpn` flag on burst beams: the beam only fires once fully charged, so
  /// the chargeup contributes no damage. The game zeroes the chargeup term of
  /// the burst-damage ramp (`WeaponSpreadsheetLoader`).
  final bool? beamFireOnlyOnFullCharge;

  /// `.wpn` flag on burst beams (IR Autolance): the game's tooltip displays
  /// the weapon as a continuous beam — no per-burst Damage row, and EMP is
  /// labeled `EMP DPS`.
  final bool? skipIdleFrameIfZeroBurstDelay;

  /// Fire-point offsets, flat `[x1, y1, x2, y2, ...]` (one pair per barrel/tube).
  /// `x` is along the barrel (weapon-forward), `y` is lateral.
  final List<double>? turretOffsets;
  final List<double>? hardpointOffsets;
  final List<double>? turretAngleOffsets;
  final List<double>? hardpointAngleOffsets;

  /// Loaded-missile render data, resolved from the `.proj` at parse time
  /// (only set when the weapon has the `RENDER_LOADED_MISSILES` hint and the
  /// projectile spec was found in the weapon's own mod folder).
  final String? loadedMissileSprite;
  final List<double>? loadedMissileSize;
  final List<double>? loadedMissileCenter;

  // ── Fields read from the weapon's missile `.proj`, when one was found ──

  /// The `.proj`'s `missileType` (`MISSILE`, `MIRV`, `ROCKET`, `BOMB`, ...).
  /// Null for gun projectiles and when no `.proj` matched [projectileSpecId].
  final String? missileType;

  /// MIRV submunition stats from the `.proj`'s `behaviorSpec`. The game
  /// derives a MIRV's per-shot damage as [mirvDamage] × [mirvNumShots] and
  /// displays the submunition EMP and hitpoints (`WeaponSpreadsheetLoader`,
  /// `CargoTooltipFactory`). Only meaningful when [isMirv].
  final double? mirvDamage;
  final double? mirvEmp;
  final int? mirvNumShots;
  final double? mirvHitpoints;

  /// Missile engine stats from the `.proj`'s `engineSpec` (`acc`,
  /// `turnRate`). With [projSpeed], these feed the game's computed
  /// Speed/Tracking words for MIRVs whose CSV strings are blank.
  final double? missileAcceleration;
  final double? missileMaxTurnRate;

  final String? mountTypeOverride;

  /// The mount type to show, and to check a slot against. The game does the
  /// same fallback: `mountTypeOverride` defaults to the `.wpn`'s `type`.
  String? get effectiveMountType => mountTypeOverride ?? weaponType;

  /// The mod that supplied this weapon's `weapon_data.csv` row.
  @MappableField(hook: SkipSerializationHook())
  late ModVariant? modVariant;

  /// The mod that supplied the `.wpn` file (sprite and spec). Can differ from
  /// [modVariant] when a mod overrides only the CSV row. Null for vanilla or
  /// when no `.wpn` file exists.
  @MappableField(hook: SkipSerializationHook())
  ModVariant? spriteModVariant;

  /// Mod attribution for the details dialog. Rebuilt each load, not serialized.
  @MappableField(hook: SkipSerializationHook())
  ItemModSources? modSources;

  /// Cells in `weapon_data.csv` that should have held a number but didn't,
  /// keyed by the field they belong to (`energyPerSecond`, not
  /// `energy/second`). The stat is null on this weapon; the message says what
  /// was in the file. Rebuilt each load, not serialized.
  @MappableField(hook: SkipSerializationHook())
  Map<String, String> fieldErrors = const {};

  @MappableField(hook: FileHook())
  File? csvFile;
  @MappableField(hook: FileHook())
  File? wpnFile;

  /// Every mod's own `.wpn` file for this weapon, the effective one first.
  /// Usually just the one; a mod that rewrites another mod's weapon makes it
  /// two or more. Rebuilt each load, not serialized.
  @MappableField(hook: SkipSerializationHook())
  List<ModDataFile> wpnFiles = const [];

  /// Every `weapon_data.csv` with a row for this weapon, the one the game uses
  /// first. Rebuilt each load, not serialized.
  @MappableField(hook: SkipSerializationHook())
  List<ModDataFile> csvFiles = const [];

  Weapon({
    required this.name,
    required this.id,
    this.tier,
    this.rarity,
    this.baseValue,
    this.range,
    this.damagePerSecond,
    this.damagePerShot,
    this.emp,
    this.impact,
    this.turnRate,
    this.ops,
    this.ammo,
    this.ammoPerSec,
    this.reloadSize,
    this.type,
    this.energyPerShot,
    this.energyPerSecond,
    this.chargeup,
    this.chargedown,
    this.burstSize,
    this.burstDelay,
    this.minSpread,
    this.maxSpread,
    this.spreadPerShot,
    this.spreadDecayPerSec,
    this.beamSpeed,
    this.projSpeed,
    this.launchSpeed,
    this.flightTime,
    this.projHitpoints,
    this.autofireAccBonus,
    this.extraArcForAI,
    this.hints,
    this.tags,
    this.groupTag,
    this.techManufacturer,
    this.forWeaponTooltip,
    this.primaryRoleStr,
    this.speedStr,
    this.trackingStr,
    this.turnRateStr,
    this.accuracyStr,
    this.customPrimary,
    this.customPrimaryHL,
    this.customAncillary,
    this.customAncillaryHL,
    this.noDPSInTooltip,
    // .wpn file fields
    this.specClass,
    this.weaponType,
    this.size,
    this.damageType,
    this.turretSprite,
    this.turretGunSprite,
    this.hardpointSprite,
    this.hardpointGunSprite,
    this.turretUnderSprite,
    this.hardpointUnderSprite,
    this.turretGlowSprite,
    this.hardpointGlowSprite,
    this.glowColor,
    this.renderHints,
    this.projectileSpecId,
    this.barrelMode,
    this.interruptibleBurst,
    this.beamFireOnlyOnFullCharge,
    this.skipIdleFrameIfZeroBurstDelay,
    this.turretOffsets,
    this.hardpointOffsets,
    this.turretAngleOffsets,
    this.hardpointAngleOffsets,
    this.loadedMissileSprite,
    this.loadedMissileSize,
    this.loadedMissileCenter,
    this.missileType,
    this.mirvDamage,
    this.mirvEmp,
    this.mirvNumShots,
    this.mirvHitpoints,
    this.missileAcceleration,
    this.missileMaxTurnRate,
    this.mountTypeOverride,
  });

  /// Returns the hints as a set of strings, with each hint trimmed and lowercased.
  late final Set<String> hintsAsSet =
      hints?.split(',').map((hint) => hint.trim().toLowerCase()).toSet() ?? {};

  /// Returns the tags as a set of strings, with each tag trimmed and lowercased.
  late final Set<String> tagsAsSet =
      tags?.split(',').map((tag) => tag.trim().toLowerCase()).toSet() ?? {};

  // ── Derived weapon stats ──
  // The math lives in weapon_derived_stats.dart, organized branch-for-branch
  // like the game's WeaponSpreadsheetLoader (numbers) and CargoTooltipFactory
  // (display) so it stays easy to diff against the decompiled game code.

  late final bool isBeam = specClass?.toLowerCase().contains('beam') == true;

  /// A beam that fires in timed pulses; its `burst size` is seconds of
  /// uptime, not a shot count.
  late final bool isBurstBeam = isBeam && (burstSize ?? 0) > 0;

  /// Whether the CSV set an `ammo` cap. The game's sustained-DPS branch
  /// requires this on top of `ammo/sec` (`BaseWeaponSpec.usesAmmo()`).
  bool get usesAmmo => ammo != null;

  /// A missile whose `.proj` declares `"missileType":"MIRV"` (Sabot,
  /// Hurricane, Hydra). Their damage comes from the submunitions.
  late final bool isMirv = missileType?.trim().toUpperCase() == 'MIRV';

  /// A MIRV's real per-shot damage: submunition damage × count, the way the
  /// game derives it. Null when this isn't a MIRV or the `.proj` data is
  /// incomplete (the game falls back to the CSV damage then too).
  double? get mirvTotalDamage =>
      isMirv && mirvDamage != null && mirvNumShots != null
      ? mirvDamage! * mirvNumShots!
      : null;

  /// Projectiles per trigger pull from barrel wiring alone. The game fires
  /// every barrel at once for LINKED (one barrel per [turretOffsets] pair)
  /// and two for DUAL_LINKED, and multiplies shot damage and flux to match.
  /// Beams and the default ALTERNATING mode fire one barrel at a time. (Any
  /// other string, including plain `DUAL`, fails the game's enum parse and
  /// crashes it at load, so no working mod carries one.)
  late final int barrelCount = () {
    if (isBeam) return 1;
    final mode = barrelMode?.trim().toUpperCase();
    if (mode == 'LINKED') {
      final barrels = (turretOffsets?.length ?? 0) ~/ 2;
      return barrels > 1 ? barrels : 1;
    }
    if (mode == 'DUAL_LINKED') return 2;
    return 1;
  }();

  late final WeaponDerivedStats derivedStats = WeaponDerivedStats.of(this);
  late final WeaponTooltipDisplay tooltipDisplay = WeaponTooltipDisplay.of(
    this,
  );

  double? get burstDamage => derivedStats.burstDamage;

  double? get refireDelay => derivedStats.refireDelay;

  double? get effectiveDps => derivedStats.effectiveDps;

  double? get sustainedDps => derivedStats.sustainedDps;

  double? get fluxPerDamage => derivedStats.fluxPerDamage;

  double? get fluxPerSecond => derivedStats.fluxPerSecond;

  double? get sustainedFluxPerSecond => derivedStats.sustainedFluxPerSecond;

  double? get empPerActivation => derivedStats.empPerActivation;

  bool get hasSustainedDps => derivedStats.hasSustainedDps;

  /// The burst size to show, the way the game's tooltip counts it: shots per
  /// trigger pull across all barrels.
  int get displayBurstSize => tooltipDisplay.burstSize;

  bool isHidden() {
    if (weaponType?.toLowerCase() == "decorative") return true;
    if (hintsAsSet.contains("system") && !hintsAsSet.contains("show_in_codex"))
      return true;
    return false;
  }

  bool get renderBarrelBelow =>
      renderHints?.any(
        (h) => h.toUpperCase().contains('RENDER_BARREL_BELOW'),
      ) ??
      false;

  bool get renderLoadedMissiles =>
      renderHints?.any(
        (h) => h.toUpperCase().contains('RENDER_LOADED_MISSILES'),
      ) ??
      false;

  /// Prefer the turret form (what the in-game codex shows); fall back to
  /// hardpoint when no turret main sprite exists.
  late final bool _useTurret = turretSprite != null;

  String? get _underSprite =>
      _useTurret ? turretUnderSprite : hardpointUnderSprite;

  String? get mainSprite => _useTurret ? turretSprite : hardpointSprite;

  String? get _gunSprite => _useTurret ? turretGunSprite : hardpointGunSprite;

  String? get glowSprite => _useTurret ? turretGlowSprite : hardpointGlowSprite;

  /// Fire-point offsets for the preferred mount.
  List<double>? get mountOffsets =>
      _useTurret ? turretOffsets : hardpointOffsets;

  List<double>? get mountAngleOffsets =>
      _useTurret ? turretAngleOffsets : hardpointAngleOffsets;

  /// Full-frame sprite layers for the preferred mount, back (first) to front
  /// (last), matching the game's at-rest draw order. Glow and loaded missiles
  /// are handled separately by the painter.
  late final List<String> spriteLayers = [
    _underSprite,
    if (renderBarrelBelow) _gunSprite,
    mainSprite,
    if (!renderBarrelBelow) _gunSprite,
  ].whereType<String>().toList();

  /// Flat list of every sprite file (both mounts), for the detail dialog's
  /// per-file view.
  late final List<String> allSpriteFiles = [
    turretUnderSprite,
    turretSprite,
    turretGunSprite,
    turretGlowSprite,
    hardpointUnderSprite,
    hardpointSprite,
    hardpointGunSprite,
    hardpointGlowSprite,
  ].whereType<String>().toList();
}
