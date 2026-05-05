import 'dart:io';

import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter/material.dart';
import 'package:trios/mod_manager/homebrew_grid/wisp_grid.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/ship_viewer/models/ship_weapon_slot.dart';
import 'package:trios/utils/dart_mappable_utils.dart';
import 'package:trios/utils/extensions.dart';

part 'ship_gpt.mapper.dart';

@MappableClass(caseStyle: CaseStyle.lowerCase)
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
  @MappableField(hook: SafeDoubleHook())
  final double? crPercentPerDay;
  @MappableField(key: 'cr to deploy')
  @MappableField(hook: SafeDoubleHook())
  final double? crToDeploy;
  @MappableField(key: 'peak cr sec')
  @MappableField(hook: SafeDoubleHook())
  final double? peakCrSec;
  @MappableField(key: 'cr loss/sec')
  @MappableField(hook: SafeDoubleHook())
  final double? crLossPerSec;
  @MappableField(key: 'supplies/rec')
  @MappableField(hook: SafeDoubleHook())
  final double? suppliesRec;
  @MappableField(key: 'supplies/mo')
  @MappableField(hook: SafeDoubleHook())
  final double? suppliesMo;
  @MappableField(hook: StringArrayHook())
  final List<String>? hints;
  @MappableField(hook: StringArrayHook())
  final List<String>? tags;
  final String? rarity;
  final String? breakProb;
  @MappableField(hook: SafeDoubleHook())
  final double? minPieces;
  @MappableField(hook: SafeDoubleHook())
  final double? maxPieces;
  @MappableField(key: 'travel drive')
  final String? travelDrive;
  @MappableField(hook: SafeDoubleHook())
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

  /// Resolved absolute path to the ship sprite image.
  /// Derived from [spriteName] at parse time by [ship_manager.dart].
  final String? spriteFile;

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

  // Skin metadata
  final bool isSkin;
  final String? baseHullId;

  // Derived UI property
  final Color? color;

  @MappableField(hook: SkipSerializationHook())
  late ModVariant? modVariant;

  /// The ship_data.csv file this ship was loaded from.
  @MappableField(hook: FileHook())
  File? csvFile;

  /// The .ship or .skin file for this hull (null if not found during parsing).
  @MappableField(hook: FileHook())
  File? dataFile;

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
    this.spriteFile,
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
    this.isSkin = false,
    this.baseHullId,
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
  late final int mountableWeaponSlotCount =
      weaponSlots?.where((s) => s.isMountable).length ?? 0;

  /// Whether this hull is a station (orbital station, battlestation, etc.).
  late final bool isStation = hints?.contains('STATION') ?? false;

  /// Whether this ship has any STATION-type weapon slots (i.e., docks modules).
  late final bool hasStationSlots =
      weaponSlots?.any((s) => s.isStationModule) ?? false;

  double? get deploymentPoints => suppliesRec;

  /// Base sensor value for this hull size (same for profile and strength).
  late final int? _baseSensorValue = switch (hullSize?.toLowerCase()) {
    'frigate' => 30,
    'destroyer' => 60,
    'cruiser' => 90,
    'capital_ship' => 150,
    _ => null,
  };

  /// Sensor profile, adjusted for built-in hullmods.
  late final double? sensorProfile = _computeSensorProfile();

  double? _computeSensorProfile() {
    final base = _baseSensorValue;
    if (base == null) return null;
    var value = base.toDouble();
    final mods = builtInMods ?? [];
    if (mods.contains('civgrade')) value *= 2.0;
    if (mods.contains('degraded_engines')) value *= 1.5;
    if (mods.contains('faulty_grid')) value *= 1.5;
    if (mods.contains('insulatedengine')) value *= 0.5;
    return value;
  }

  /// Sensor strength, adjusted for built-in hullmods.
  late final double? sensorStrength = _computeSensorStrength();

  double? _computeSensorStrength() {
    final base = _baseSensorValue;
    if (base == null) return null;
    var value = base.toDouble();
    final mods = builtInMods ?? [];
    if (mods.contains('civgrade')) value *= 0.5;
    if (mods.contains('glitched_sensors')) value *= 0.5;
    // if (mods.contains('hiressensors')) value += base; // Applies to whole fleet, not individual ships
    return value;
  }
}
