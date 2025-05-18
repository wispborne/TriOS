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
  final String? fleetPts;
  final String? hitpoints;
  @MappableField(key: 'armor rating')
  final String? armorRating;
  @MappableField(key: 'max flux')
  final String? maxFlux;
  @MappableField(key: '8/6/5/4%')
  final String? fluxPercent8654;
  @MappableField(key: 'flux dissipation')
  final String? fluxDissipation;
  @MappableField(key: 'ordnance points')
  final String? ordnancePoints;
  @MappableField(key: 'fighter bays')
  final String? fighterBays;
  @MappableField(key: 'max speed')
  final String? maxSpeed;
  final String? acceleration;
  final String? deceleration;
  @MappableField(key: 'max turn rate')
  final String? maxTurnRate;
  @MappableField(key: 'turn acceleration')
  final String? turnAcceleration;
  final String? mass;
  @MappableField(key: 'shield type')
  final String? shieldType;
  @MappableField(key: 'defense id')
  final String? defenseId;
  @MappableField(key: 'shield arc')
  final String? shieldArc;
  @MappableField(key: 'shield upkeep')
  final String? shieldUpkeep;
  @MappableField(key: 'shield efficiency')
  final String? shieldEfficiency;
  @MappableField(key: 'phase cost')
  final String? phaseCost;
  @MappableField(key: 'phase upkeep')
  final String? phaseUpkeep;
  @MappableField(key: 'min crew')
  final String? minCrew;
  @MappableField(key: 'max crew')
  final String? maxCrew;
  final String? cargo;
  final String? fuel;
  @MappableField(key: 'fuel/ly')
  final String? fuelPerLY;
  final String? range;
  @MappableField(key: 'max burn')
  final String? maxBurn;
  @MappableField(key: 'base value')
  final String? baseValue;
  @MappableField(key: 'cr %/day')
  final String? crPercentPerDay;
  @MappableField(key: 'cr to deploy')
  final String? crToDeploy;
  @MappableField(key: 'peak cr sec')
  final String? peakCrSec;
  @MappableField(key: 'cr loss/sec')
  final String? crLossPerSec;
  @MappableField(key: 'supplies/rec')
  final String? suppliesRec;
  @MappableField(key: 'supplies/mo')
  final String? suppliesMo;
  @MappableField(key: 'c/s')
  final String? cPerS;
  @MappableField(key: 'c/f')
  final String? cPerF;
  @MappableField(key: 'f/s')
  final String? fPerS;
  @MappableField(key: 'f/f')
  final String? fPerF;
  @MappableField(key: 'crew/s')
  final String? crewPerS;
  @MappableField(key: 'crew/f')
  final String? crewPerF;
  @MappableField(hook: StringArrayHook())
  final List<String>? hints;
  @MappableField(hook: StringArrayHook())
  final List<String>? tags;
  final String? rarity;
  final String? breakProb;
  final String? minPieces;
  final String? maxPieces;
  @MappableField(key: 'travel drive')
  final String? travelDrive;
  final String? number;

  // Visual and gameplay data
  final List<double>? bounds;
  final List<double>? center;
  final double? collisionRadius;
  final double? height;
  final double? width;
  final String? hullName;
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
    this.fluxPercent8654,
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
    this.cPerS,
    this.cPerF,
    this.fPerS,
    this.fPerF,
    this.crewPerS,
    this.crewPerF,
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
    this.hullName,
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
}
