// weapon.dart

import 'dart:io';
import 'dart:math' as math;

import 'package:dart_mappable/dart_mappable.dart';
import 'package:trios/mod_manager/homebrew_grid/wisp_grid.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/utils/dart_mappable_utils.dart';

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
  final double? number;

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
  final String? mountTypeOverride;

  /// Returns the effective mount type, considering mountTypeOverride.
  /// Use this wherever mount type display or slot compatibility is needed.
  String? get effectiveMountType => mountTypeOverride ?? type;

  @MappableField(hook: SkipSerializationHook())
  late ModVariant? modVariant;
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
    this.number,
    // .wpn file fields
    this.specClass,
    this.weaponType,
    this.size,
    this.damageType,
    this.turretSprite,
    this.turretGunSprite,
    this.hardpointSprite,
    this.hardpointGunSprite,
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
    if (hintsAsSet.contains("system") && !tagsAsSet.contains("show_in_codex"))
      return true;
    return false;
  }

  late final List<String> spritesForWeapon = [
    hardpointGunSprite,
    hardpointSprite,
    turretGunSprite,
    turretSprite,
  ].whereType<String>().toList();
}
