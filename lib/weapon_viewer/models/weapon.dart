// weapon.dart

import 'dart:io';
import 'dart:math' as math;

import 'package:dart_mappable/dart_mappable.dart';
import 'package:trios/mod_manager/homebrew_grid/wisp_grid.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/utils/dart_mappable_utils.dart';
import 'package:trios/utils/game_data_merge.dart';

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
  final String? extraArcForAI;
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
  @MappableField(key: 'type')
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

  final String? mountTypeOverride;

  /// Returns the effective mount type, considering mountTypeOverride.
  /// Use this wherever mount type display or slot compatibility is needed.
  String? get effectiveMountType => mountTypeOverride ?? type;

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

  @MappableField(hook: FileHook())
  File? csvFile;
  @MappableField(hook: FileHook())
  File? wpnFile;

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
    this.turretOffsets,
    this.hardpointOffsets,
    this.turretAngleOffsets,
    this.hardpointAngleOffsets,
    this.loadedMissileSprite,
    this.loadedMissileSize,
    this.loadedMissileCenter,
    this.mountTypeOverride,
  });

  /// Returns the hints as a set of strings, with each hint trimmed and lowercased.
  late final Set<String> hintsAsSet =
      hints?.split(',').map((hint) => hint.trim().toLowerCase()).toSet() ?? {};

  /// Returns the tags as a set of strings, with each tag trimmed and lowercased.
  late final Set<String> tagsAsSet =
      tags?.split(',').map((tag) => tag.trim().toLowerCase()).toSet() ?? {};

  // ── Derived weapon stats (faithful to WeaponSpreadsheetLoader) ──

  late final bool isBeam = specClass?.toLowerCase().contains('beam') == true;

  late final double _beamBurstDuration = isBeam
      ? (burstSize ?? 0).toDouble()
      : 0.0;

  late final bool isBurstBeam = isBeam && _beamBurstDuration > 0;

  late final int _projBurstSize = isBeam
      ? 1
      : (burstSize?.toInt().clamp(1, 99999) ?? 1);

  late final double _cu = chargeup ?? 0.0;
  late final double _cd = chargedown ?? 0.0;
  late final double _bd = burstDelay ?? 0.0;

  late final double _projCycleTime =
      _cu +
      _cd +
      _bd * (_projBurstSize > 1 ? (_projBurstSize - 1).toDouble() : 0.0);

  // 0.333 = average beam intensity during chargeup/chargedown ramps.
  late final double _beamDamageMultiplier =
      (_cu + _cd) * 0.333 + _beamBurstDuration;

  late final double? burstDamage = isBurstBeam
      ? (damagePerSecond ?? 0.0) * _beamDamageMultiplier
      : null;

  late final double? refireDelay = () {
    if (isBurstBeam) return _cu + _cd + _beamBurstDuration + _bd;
    if (!isBeam && _projCycleTime > 0) return _projCycleTime;
    return null;
  }();

  late final double? effectiveDps = () {
    if (isBurstBeam) {
      final d = burstDamage;
      final r = refireDelay;
      if (d != null && d > 0 && r != null && r > 0) return d / r;
      return null;
    }
    if (isBeam) {
      final v = damagePerSecond ?? 0;
      return v > 0 ? v.toDouble() : null;
    }
    final dmg = damagePerShot ?? 0.0;
    if (dmg > 0 && _projCycleTime > 0) {
      return dmg * _projBurstSize / _projCycleTime;
    }
    return null;
  }();

  late final double? sustainedDps = () {
    final dps = effectiveDps;
    if (dps == null || ammoPerSec == null || ammoPerSec! <= 0) return null;

    // Burst beams: sustained = burstDamage × ammoPerSec.
    // Projectiles: sustained = damagePerShot × ammoPerSec.
    final double? s;
    if (isBurstBeam) {
      s = burstDamage != null ? burstDamage! * ammoPerSec! : null;
    } else if (!isBeam && damagePerShot != null) {
      s = damagePerShot! * ammoPerSec!;
    } else {
      s = null;
    }
    if (s != null && (s - dps).abs() / dps >= 0.01) return s;
    return null;
  }();

  late final double? fluxPerDamage = () {
    if (isBurstBeam) {
      final bd = burstDamage;
      if (bd != null && bd > 0) {
        return (energyPerSecond ?? 0.0) * (_cu + _beamBurstDuration) / bd;
      }
    } else if (isBeam) {
      final dps = effectiveDps;
      if (dps != null && dps > 0 && (energyPerSecond ?? 0) > 0) {
        return energyPerSecond! / dps;
      }
    } else {
      final totalDmg = (damagePerShot ?? 0.0) * _projBurstSize;
      final totalFlux =
          _cu * (energyPerSecond ?? 0.0) +
          (energyPerShot ?? 0.0) * _projBurstSize;
      if (totalFlux > 0) return totalFlux / math.max(1.0, totalDmg);
    }
    return null;
  }();

  late final double? fluxPerSecond = () {
    final dps = effectiveDps;
    final fpd = fluxPerDamage;
    if (dps != null && fpd != null) return dps * fpd;
    if (isBeam && (energyPerSecond ?? 0) > 0) {
      return energyPerSecond!.toDouble();
    }
    return null;
  }();

  late final double? sustainedFluxPerSecond = () {
    final sdps = sustainedDps;
    final fpd = fluxPerDamage;
    if (sdps != null && fpd != null) return sdps * fpd;
    return null;
  }();

  late final double? empPerActivation = isBurstBeam && emp != null && emp! > 0
      ? emp! * _beamDamageMultiplier
      : emp;

  late final bool hasSustainedDps = sustainedDps != null;

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
