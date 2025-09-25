// weapon.dart

import 'dart:io';

import 'package:dart_mappable/dart_mappable.dart';
import 'package:trios/mod_manager/homebrew_grid/wisp_grid.dart';
import 'package:trios/models/mod_variant.dart';

part 'weapon.mapper.dart';

@MappableClass()
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
  @MappableField(key: 'OPs')
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
  final int? burstSize;
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
  final String? turretSprite;
  final String? turretGunSprite;
  final String? hardpointSprite;
  final String? hardpointGunSprite;

  late ModVariant? modVariant;
  late File csvFile;
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
    this.turretSprite,
    this.turretGunSprite,
    this.hardpointSprite,
    this.hardpointGunSprite,
  });

  /// Returns the hints as a set of strings, with each hint trimmed and lowercased.
  late Set<String> hintsAsSet = hints?.split(',').map((hint) => hint.trim().toLowerCase()).toSet() ?? {};

  /// Returns the tags as a set of strings, with each tag trimmed and lowercased.
  late Set<String> tagsAsSet = tags?.split(',').map((tag) => tag.trim().toLowerCase()).toSet() ?? {};
}
