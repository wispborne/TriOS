import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter/material.dart';
import 'package:trios/mod_manager/homebrew_grid/wisp_grid.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/shipViewer/models/ship_weapon_slot.dart';
import 'package:trios/utils/dart_mappable_utils.dart';
import 'package:trios/utils/extensions.dart';

part 'shipGpt.mapper.dart';

@MappableClass()
class Ship with ShipMappable implements WispGridItem {
  @override
  String get key => id;

  final String id;
  final String? name;
  final String? designation;
  @MappableField(key: 'tech/manufacturer')
  final String? techManufacturer;
  @MappableField(key: 'system id')
  final String? systemId;
  @MappableField(key: 'fleet pts')
  final double? fleetPts;
  final double? hitpoints;
  @MappableField(key: 'armor rating')
  final double? armorRating;
  @MappableField(key: 'max flux')
  final double? maxFlux;
  @MappableField(key: 'flux dissipation')
  final double? fluxDissipation;
  @MappableField(key: 'ordnance points')
  final double? ordnancePoints;
  @MappableField(key: 'fighter bays')
  final double? fighterBays;
  @MappableField(key: 'max speed')
  final double? maxSpeed;
  final double? acceleration;
  final double? deceleration;
  @MappableField(key: 'max turn rate')
  final double? maxTurnRate;
  @MappableField(key: 'turn acceleration')
  final double? turnAcceleration;
  final double? mass;
  @MappableField(key: 'shield type')
  final String? shieldType;
  @MappableField(key: 'defense id')
  final String? defenseId;
  @MappableField(key: 'shield arc')
  final double? shieldArc;
  @MappableField(key: 'shield upkeep')
  final double? shieldUpkeep;
  @MappableField(key: 'shield efficiency')
  final double? shieldEfficiency;
  @MappableField(key: 'phase cost')
  final double? phaseCost;
  @MappableField(key: 'phase upkeep')
  final double? phaseUpkeep;
  @MappableField(key: 'min crew')
  final double? minCrew;
  @MappableField(key: 'max crew')
  final double? maxCrew;
  final double? cargo;
  final double? fuel;
  @MappableField(key: 'fuel/ly')
  final double? fuelPerLY;
  final double? range;
  @MappableField(key: 'max burn')
  final double? maxBurn;
  @MappableField(key: 'base value')
  final double? baseValue;
  @MappableField(key: 'cr %/day')
  final double? crPercentPerDay;
  @MappableField(key: 'cr to deploy')
  final double? crToDeploy;
  @MappableField(key: 'peak cr sec')
  final double? peakCrSec;
  @MappableField(key: 'cr loss/sec')
  final double? crLossPerSec;
  @MappableField(key: 'supplies/rec')
  final double? suppliesRec;
  @MappableField(key: 'supplies/mo')
  final double? suppliesMo;
  @MappableField(hook: StringArrayHook())
  final List<String>? hints;
  @MappableField(hook: StringArrayHook())
  final List<String>? tags;
  final String? rarity;
  final String? breakProb;
  final double? minPieces;
  final double? maxPieces;
  @MappableField(key: 'travel drive')
  final String? travelDrive;
  final double? number;

  // Visual and gameplay data
  final List<double>? bounds;
  final List<double>? center;
  final double? collisionRadius;
  final double? height;
  final double? width;
  final String? hullSize;
  final List<double>? shieldCenter;
  final double? shieldRadius;
  final String? spriteName;
  final String? style;
  final double? viewOffset;

  // Raw mod data
  final List<dynamic>? engineSlots;
  final List<ShipWeaponSlot>? weaponSlots;

  final Map<String, String>? builtInWeapons;
  final List<String>? builtInMods;
  final List<String>? builtInWings;
  final List<double>? moduleAnchor;

  // Metadata
  final String? modId;
  final String? modName;

  // Derived UI property
  final Color? color;

  late ModVariant? modVariant;

  Ship({
    required this.id,
    this.name,
    this.designation,
    this.techManufacturer,
    this.systemId,
    this.fleetPts,
    this.hitpoints,
    this.armorRating,
    this.maxFlux,
    this.fluxDissipation,
    this.ordnancePoints,
    this.fighterBays,
    this.maxSpeed,
    this.acceleration,
    this.deceleration,
    this.maxTurnRate,
    this.turnAcceleration,
    this.mass,
    this.shieldType,
    this.defenseId,
    this.shieldArc,
    this.shieldUpkeep,
    this.shieldEfficiency,
    this.phaseCost,
    this.phaseUpkeep,
    this.minCrew,
    this.maxCrew,
    this.cargo,
    this.fuel,
    this.fuelPerLY,
    this.range,
    this.maxBurn,
    this.baseValue,
    this.crPercentPerDay,
    this.crToDeploy,
    this.peakCrSec,
    this.crLossPerSec,
    this.suppliesRec,
    this.suppliesMo,
    this.hints,
    this.tags,
    this.rarity,
    this.breakProb,
    this.minPieces,
    this.maxPieces,
    this.travelDrive,
    this.number,
    this.bounds,
    this.center,
    this.collisionRadius,
    this.height,
    this.width,
    this.hullSize,
    this.shieldCenter,
    this.shieldRadius,
    this.spriteName,
    this.style,
    this.viewOffset,
    this.engineSlots,
    this.weaponSlots,
    this.builtInWeapons,
    this.builtInMods,
    this.builtInWings,
    this.moduleAnchor,
    this.modId,
    this.modName,
    this.color,
  });

  final shipSizesMap = {
    "frigate": "Frigate",
    "destroyer": "Destroyer",
    "cruiser": "Cruiser",
    "capital_ship": "Capital",
  };

  String hullSizeForDisplay() {
    return shipSizesMap[hullSize?.toLowerCase()] ??
        hullSize?.toTitleCase() ??
        "(unknown)";
  }

  String hullNameForDisplay() => name ?? designation ?? id;

  /// Number of weapon slots that accept mountable weapons (excludes
  /// decorative, system, built-in, launch bay, and station module slots).
  int get mountableWeaponSlotCount =>
      weaponSlots?.where((s) => s.isMountable).length ?? 0;
}
