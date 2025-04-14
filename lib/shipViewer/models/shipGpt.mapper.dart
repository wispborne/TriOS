// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'shipGpt.dart';

class ShipMapper extends ClassMapperBase<Ship> {
  ShipMapper._();

  static ShipMapper? _instance;
  static ShipMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ShipMapper._());
      ShipWeaponSlotMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'Ship';

  static String _$id(Ship v) => v.id;
  static const Field<Ship, String> _f$id = Field('id', _$id);
  static String? _$name(Ship v) => v.name;
  static const Field<Ship, String> _f$name = Field('name', _$name, opt: true);
  static String? _$designation(Ship v) => v.designation;
  static const Field<Ship, String> _f$designation =
      Field('designation', _$designation, opt: true);
  static String? _$techManufacturer(Ship v) => v.techManufacturer;
  static const Field<Ship, String> _f$techManufacturer = Field(
      'techManufacturer', _$techManufacturer,
      key: 'tech/manufacturer', opt: true);
  static String? _$systemId(Ship v) => v.systemId;
  static const Field<Ship, String> _f$systemId =
      Field('systemId', _$systemId, key: 'system id', opt: true);
  static String? _$fleetPts(Ship v) => v.fleetPts;
  static const Field<Ship, String> _f$fleetPts =
      Field('fleetPts', _$fleetPts, key: 'fleet pts', opt: true);
  static String? _$hitpoints(Ship v) => v.hitpoints;
  static const Field<Ship, String> _f$hitpoints =
      Field('hitpoints', _$hitpoints, opt: true);
  static String? _$armorRating(Ship v) => v.armorRating;
  static const Field<Ship, String> _f$armorRating =
      Field('armorRating', _$armorRating, key: 'armor rating', opt: true);
  static String? _$maxFlux(Ship v) => v.maxFlux;
  static const Field<Ship, String> _f$maxFlux =
      Field('maxFlux', _$maxFlux, key: 'max flux', opt: true);
  static String? _$fluxPercent8654(Ship v) => v.fluxPercent8654;
  static const Field<Ship, String> _f$fluxPercent8654 =
      Field('fluxPercent8654', _$fluxPercent8654, key: '8/6/5/4%', opt: true);
  static String? _$fluxDissipation(Ship v) => v.fluxDissipation;
  static const Field<Ship, String> _f$fluxDissipation = Field(
      'fluxDissipation', _$fluxDissipation,
      key: 'flux dissipation', opt: true);
  static String? _$ordnancePoints(Ship v) => v.ordnancePoints;
  static const Field<Ship, String> _f$ordnancePoints = Field(
      'ordnancePoints', _$ordnancePoints,
      key: 'ordnance points', opt: true);
  static String? _$fighterBays(Ship v) => v.fighterBays;
  static const Field<Ship, String> _f$fighterBays =
      Field('fighterBays', _$fighterBays, key: 'fighter bays', opt: true);
  static String? _$maxSpeed(Ship v) => v.maxSpeed;
  static const Field<Ship, String> _f$maxSpeed =
      Field('maxSpeed', _$maxSpeed, key: 'max speed', opt: true);
  static String? _$acceleration(Ship v) => v.acceleration;
  static const Field<Ship, String> _f$acceleration =
      Field('acceleration', _$acceleration, opt: true);
  static String? _$deceleration(Ship v) => v.deceleration;
  static const Field<Ship, String> _f$deceleration =
      Field('deceleration', _$deceleration, opt: true);
  static String? _$maxTurnRate(Ship v) => v.maxTurnRate;
  static const Field<Ship, String> _f$maxTurnRate =
      Field('maxTurnRate', _$maxTurnRate, key: 'max turn rate', opt: true);
  static String? _$turnAcceleration(Ship v) => v.turnAcceleration;
  static const Field<Ship, String> _f$turnAcceleration = Field(
      'turnAcceleration', _$turnAcceleration,
      key: 'turn acceleration', opt: true);
  static String? _$mass(Ship v) => v.mass;
  static const Field<Ship, String> _f$mass = Field('mass', _$mass, opt: true);
  static String? _$shieldType(Ship v) => v.shieldType;
  static const Field<Ship, String> _f$shieldType =
      Field('shieldType', _$shieldType, key: 'shield type', opt: true);
  static String? _$defenseId(Ship v) => v.defenseId;
  static const Field<Ship, String> _f$defenseId =
      Field('defenseId', _$defenseId, key: 'defense id', opt: true);
  static String? _$shieldArc(Ship v) => v.shieldArc;
  static const Field<Ship, String> _f$shieldArc =
      Field('shieldArc', _$shieldArc, key: 'shield arc', opt: true);
  static String? _$shieldUpkeep(Ship v) => v.shieldUpkeep;
  static const Field<Ship, String> _f$shieldUpkeep =
      Field('shieldUpkeep', _$shieldUpkeep, key: 'shield upkeep', opt: true);
  static String? _$shieldEfficiency(Ship v) => v.shieldEfficiency;
  static const Field<Ship, String> _f$shieldEfficiency = Field(
      'shieldEfficiency', _$shieldEfficiency,
      key: 'shield efficiency', opt: true);
  static String? _$phaseCost(Ship v) => v.phaseCost;
  static const Field<Ship, String> _f$phaseCost =
      Field('phaseCost', _$phaseCost, key: 'phase cost', opt: true);
  static String? _$phaseUpkeep(Ship v) => v.phaseUpkeep;
  static const Field<Ship, String> _f$phaseUpkeep =
      Field('phaseUpkeep', _$phaseUpkeep, key: 'phase upkeep', opt: true);
  static String? _$minCrew(Ship v) => v.minCrew;
  static const Field<Ship, String> _f$minCrew =
      Field('minCrew', _$minCrew, key: 'min crew', opt: true);
  static String? _$maxCrew(Ship v) => v.maxCrew;
  static const Field<Ship, String> _f$maxCrew =
      Field('maxCrew', _$maxCrew, key: 'max crew', opt: true);
  static String? _$cargo(Ship v) => v.cargo;
  static const Field<Ship, String> _f$cargo =
      Field('cargo', _$cargo, opt: true);
  static String? _$fuel(Ship v) => v.fuel;
  static const Field<Ship, String> _f$fuel = Field('fuel', _$fuel, opt: true);
  static String? _$fuelPerLY(Ship v) => v.fuelPerLY;
  static const Field<Ship, String> _f$fuelPerLY =
      Field('fuelPerLY', _$fuelPerLY, key: 'fuel/ly', opt: true);
  static String? _$range(Ship v) => v.range;
  static const Field<Ship, String> _f$range =
      Field('range', _$range, opt: true);
  static String? _$maxBurn(Ship v) => v.maxBurn;
  static const Field<Ship, String> _f$maxBurn =
      Field('maxBurn', _$maxBurn, key: 'max burn', opt: true);
  static String? _$baseValue(Ship v) => v.baseValue;
  static const Field<Ship, String> _f$baseValue =
      Field('baseValue', _$baseValue, key: 'base value', opt: true);
  static String? _$crPercentPerDay(Ship v) => v.crPercentPerDay;
  static const Field<Ship, String> _f$crPercentPerDay =
      Field('crPercentPerDay', _$crPercentPerDay, key: 'cr %/day', opt: true);
  static String? _$crToDeploy(Ship v) => v.crToDeploy;
  static const Field<Ship, String> _f$crToDeploy =
      Field('crToDeploy', _$crToDeploy, key: 'cr to deploy', opt: true);
  static String? _$peakCrSec(Ship v) => v.peakCrSec;
  static const Field<Ship, String> _f$peakCrSec =
      Field('peakCrSec', _$peakCrSec, key: 'peak cr sec', opt: true);
  static String? _$crLossPerSec(Ship v) => v.crLossPerSec;
  static const Field<Ship, String> _f$crLossPerSec =
      Field('crLossPerSec', _$crLossPerSec, key: 'cr loss/sec', opt: true);
  static String? _$suppliesRec(Ship v) => v.suppliesRec;
  static const Field<Ship, String> _f$suppliesRec =
      Field('suppliesRec', _$suppliesRec, key: 'supplies/rec', opt: true);
  static String? _$suppliesMo(Ship v) => v.suppliesMo;
  static const Field<Ship, String> _f$suppliesMo =
      Field('suppliesMo', _$suppliesMo, key: 'supplies/mo', opt: true);
  static String? _$cPerS(Ship v) => v.cPerS;
  static const Field<Ship, String> _f$cPerS =
      Field('cPerS', _$cPerS, key: 'c/s', opt: true);
  static String? _$cPerF(Ship v) => v.cPerF;
  static const Field<Ship, String> _f$cPerF =
      Field('cPerF', _$cPerF, key: 'c/f', opt: true);
  static String? _$fPerS(Ship v) => v.fPerS;
  static const Field<Ship, String> _f$fPerS =
      Field('fPerS', _$fPerS, key: 'f/s', opt: true);
  static String? _$fPerF(Ship v) => v.fPerF;
  static const Field<Ship, String> _f$fPerF =
      Field('fPerF', _$fPerF, key: 'f/f', opt: true);
  static String? _$crewPerS(Ship v) => v.crewPerS;
  static const Field<Ship, String> _f$crewPerS =
      Field('crewPerS', _$crewPerS, key: 'crew/s', opt: true);
  static String? _$crewPerF(Ship v) => v.crewPerF;
  static const Field<Ship, String> _f$crewPerF =
      Field('crewPerF', _$crewPerF, key: 'crew/f', opt: true);
  static List<String>? _$hints(Ship v) => v.hints;
  static const Field<Ship, List<String>> _f$hints =
      Field('hints', _$hints, opt: true, hook: StringArrayHook());
  static List<String>? _$tags(Ship v) => v.tags;
  static const Field<Ship, List<String>> _f$tags =
      Field('tags', _$tags, opt: true, hook: StringArrayHook());
  static String? _$rarity(Ship v) => v.rarity;
  static const Field<Ship, String> _f$rarity =
      Field('rarity', _$rarity, opt: true);
  static String? _$breakProb(Ship v) => v.breakProb;
  static const Field<Ship, String> _f$breakProb =
      Field('breakProb', _$breakProb, opt: true);
  static String? _$minPieces(Ship v) => v.minPieces;
  static const Field<Ship, String> _f$minPieces =
      Field('minPieces', _$minPieces, opt: true);
  static String? _$maxPieces(Ship v) => v.maxPieces;
  static const Field<Ship, String> _f$maxPieces =
      Field('maxPieces', _$maxPieces, opt: true);
  static String? _$travelDrive(Ship v) => v.travelDrive;
  static const Field<Ship, String> _f$travelDrive =
      Field('travelDrive', _$travelDrive, key: 'travel drive', opt: true);
  static String? _$number(Ship v) => v.number;
  static const Field<Ship, String> _f$number =
      Field('number', _$number, opt: true);
  static List<double>? _$bounds(Ship v) => v.bounds;
  static const Field<Ship, List<double>> _f$bounds =
      Field('bounds', _$bounds, opt: true);
  static List<double>? _$center(Ship v) => v.center;
  static const Field<Ship, List<double>> _f$center =
      Field('center', _$center, opt: true);
  static double? _$collisionRadius(Ship v) => v.collisionRadius;
  static const Field<Ship, double> _f$collisionRadius =
      Field('collisionRadius', _$collisionRadius, opt: true);
  static double? _$height(Ship v) => v.height;
  static const Field<Ship, double> _f$height =
      Field('height', _$height, opt: true);
  static double? _$width(Ship v) => v.width;
  static const Field<Ship, double> _f$width =
      Field('width', _$width, opt: true);
  static String? _$hullName(Ship v) => v.hullName;
  static const Field<Ship, String> _f$hullName =
      Field('hullName', _$hullName, opt: true);
  static String? _$hullSize(Ship v) => v.hullSize;
  static const Field<Ship, String> _f$hullSize =
      Field('hullSize', _$hullSize, opt: true);
  static List<double>? _$shieldCenter(Ship v) => v.shieldCenter;
  static const Field<Ship, List<double>> _f$shieldCenter =
      Field('shieldCenter', _$shieldCenter, opt: true);
  static double? _$shieldRadius(Ship v) => v.shieldRadius;
  static const Field<Ship, double> _f$shieldRadius =
      Field('shieldRadius', _$shieldRadius, opt: true);
  static String? _$spriteName(Ship v) => v.spriteName;
  static const Field<Ship, String> _f$spriteName =
      Field('spriteName', _$spriteName, opt: true);
  static String? _$style(Ship v) => v.style;
  static const Field<Ship, String> _f$style =
      Field('style', _$style, opt: true);
  static double? _$viewOffset(Ship v) => v.viewOffset;
  static const Field<Ship, double> _f$viewOffset =
      Field('viewOffset', _$viewOffset, opt: true);
  static List<dynamic>? _$engineSlots(Ship v) => v.engineSlots;
  static const Field<Ship, List<dynamic>> _f$engineSlots =
      Field('engineSlots', _$engineSlots, opt: true);
  static List<ShipWeaponSlot>? _$weaponSlots(Ship v) => v.weaponSlots;
  static const Field<Ship, List<ShipWeaponSlot>> _f$weaponSlots =
      Field('weaponSlots', _$weaponSlots, opt: true);
  static Map<String, String>? _$builtInWeapons(Ship v) => v.builtInWeapons;
  static const Field<Ship, Map<String, String>> _f$builtInWeapons =
      Field('builtInWeapons', _$builtInWeapons, opt: true);
  static List<String>? _$builtInMods(Ship v) => v.builtInMods;
  static const Field<Ship, List<String>> _f$builtInMods =
      Field('builtInMods', _$builtInMods, opt: true);
  static List<String>? _$builtInWings(Ship v) => v.builtInWings;
  static const Field<Ship, List<String>> _f$builtInWings =
      Field('builtInWings', _$builtInWings, opt: true);
  static List<double>? _$moduleAnchor(Ship v) => v.moduleAnchor;
  static const Field<Ship, List<double>> _f$moduleAnchor =
      Field('moduleAnchor', _$moduleAnchor, opt: true);
  static String? _$modId(Ship v) => v.modId;
  static const Field<Ship, String> _f$modId =
      Field('modId', _$modId, opt: true);
  static String? _$modName(Ship v) => v.modName;
  static const Field<Ship, String> _f$modName =
      Field('modName', _$modName, opt: true);
  static Color? _$color(Ship v) => v.color;
  static const Field<Ship, Color> _f$color = Field('color', _$color, opt: true);
  static ModVariant? _$modVariant(Ship v) => v.modVariant;
  static const Field<Ship, ModVariant> _f$modVariant =
      Field('modVariant', _$modVariant, mode: FieldMode.member);
  static Map<String, String> _$shipSizesMap(Ship v) => v.shipSizesMap;
  static const Field<Ship, Map<String, String>> _f$shipSizesMap =
      Field('shipSizesMap', _$shipSizesMap, mode: FieldMode.member);

  @override
  final MappableFields<Ship> fields = const {
    #id: _f$id,
    #name: _f$name,
    #designation: _f$designation,
    #techManufacturer: _f$techManufacturer,
    #systemId: _f$systemId,
    #fleetPts: _f$fleetPts,
    #hitpoints: _f$hitpoints,
    #armorRating: _f$armorRating,
    #maxFlux: _f$maxFlux,
    #fluxPercent8654: _f$fluxPercent8654,
    #fluxDissipation: _f$fluxDissipation,
    #ordnancePoints: _f$ordnancePoints,
    #fighterBays: _f$fighterBays,
    #maxSpeed: _f$maxSpeed,
    #acceleration: _f$acceleration,
    #deceleration: _f$deceleration,
    #maxTurnRate: _f$maxTurnRate,
    #turnAcceleration: _f$turnAcceleration,
    #mass: _f$mass,
    #shieldType: _f$shieldType,
    #defenseId: _f$defenseId,
    #shieldArc: _f$shieldArc,
    #shieldUpkeep: _f$shieldUpkeep,
    #shieldEfficiency: _f$shieldEfficiency,
    #phaseCost: _f$phaseCost,
    #phaseUpkeep: _f$phaseUpkeep,
    #minCrew: _f$minCrew,
    #maxCrew: _f$maxCrew,
    #cargo: _f$cargo,
    #fuel: _f$fuel,
    #fuelPerLY: _f$fuelPerLY,
    #range: _f$range,
    #maxBurn: _f$maxBurn,
    #baseValue: _f$baseValue,
    #crPercentPerDay: _f$crPercentPerDay,
    #crToDeploy: _f$crToDeploy,
    #peakCrSec: _f$peakCrSec,
    #crLossPerSec: _f$crLossPerSec,
    #suppliesRec: _f$suppliesRec,
    #suppliesMo: _f$suppliesMo,
    #cPerS: _f$cPerS,
    #cPerF: _f$cPerF,
    #fPerS: _f$fPerS,
    #fPerF: _f$fPerF,
    #crewPerS: _f$crewPerS,
    #crewPerF: _f$crewPerF,
    #hints: _f$hints,
    #tags: _f$tags,
    #rarity: _f$rarity,
    #breakProb: _f$breakProb,
    #minPieces: _f$minPieces,
    #maxPieces: _f$maxPieces,
    #travelDrive: _f$travelDrive,
    #number: _f$number,
    #bounds: _f$bounds,
    #center: _f$center,
    #collisionRadius: _f$collisionRadius,
    #height: _f$height,
    #width: _f$width,
    #hullName: _f$hullName,
    #hullSize: _f$hullSize,
    #shieldCenter: _f$shieldCenter,
    #shieldRadius: _f$shieldRadius,
    #spriteName: _f$spriteName,
    #style: _f$style,
    #viewOffset: _f$viewOffset,
    #engineSlots: _f$engineSlots,
    #weaponSlots: _f$weaponSlots,
    #builtInWeapons: _f$builtInWeapons,
    #builtInMods: _f$builtInMods,
    #builtInWings: _f$builtInWings,
    #moduleAnchor: _f$moduleAnchor,
    #modId: _f$modId,
    #modName: _f$modName,
    #color: _f$color,
    #modVariant: _f$modVariant,
    #shipSizesMap: _f$shipSizesMap,
  };

  static Ship _instantiate(DecodingData data) {
    return Ship(
        id: data.dec(_f$id),
        name: data.dec(_f$name),
        designation: data.dec(_f$designation),
        techManufacturer: data.dec(_f$techManufacturer),
        systemId: data.dec(_f$systemId),
        fleetPts: data.dec(_f$fleetPts),
        hitpoints: data.dec(_f$hitpoints),
        armorRating: data.dec(_f$armorRating),
        maxFlux: data.dec(_f$maxFlux),
        fluxPercent8654: data.dec(_f$fluxPercent8654),
        fluxDissipation: data.dec(_f$fluxDissipation),
        ordnancePoints: data.dec(_f$ordnancePoints),
        fighterBays: data.dec(_f$fighterBays),
        maxSpeed: data.dec(_f$maxSpeed),
        acceleration: data.dec(_f$acceleration),
        deceleration: data.dec(_f$deceleration),
        maxTurnRate: data.dec(_f$maxTurnRate),
        turnAcceleration: data.dec(_f$turnAcceleration),
        mass: data.dec(_f$mass),
        shieldType: data.dec(_f$shieldType),
        defenseId: data.dec(_f$defenseId),
        shieldArc: data.dec(_f$shieldArc),
        shieldUpkeep: data.dec(_f$shieldUpkeep),
        shieldEfficiency: data.dec(_f$shieldEfficiency),
        phaseCost: data.dec(_f$phaseCost),
        phaseUpkeep: data.dec(_f$phaseUpkeep),
        minCrew: data.dec(_f$minCrew),
        maxCrew: data.dec(_f$maxCrew),
        cargo: data.dec(_f$cargo),
        fuel: data.dec(_f$fuel),
        fuelPerLY: data.dec(_f$fuelPerLY),
        range: data.dec(_f$range),
        maxBurn: data.dec(_f$maxBurn),
        baseValue: data.dec(_f$baseValue),
        crPercentPerDay: data.dec(_f$crPercentPerDay),
        crToDeploy: data.dec(_f$crToDeploy),
        peakCrSec: data.dec(_f$peakCrSec),
        crLossPerSec: data.dec(_f$crLossPerSec),
        suppliesRec: data.dec(_f$suppliesRec),
        suppliesMo: data.dec(_f$suppliesMo),
        cPerS: data.dec(_f$cPerS),
        cPerF: data.dec(_f$cPerF),
        fPerS: data.dec(_f$fPerS),
        fPerF: data.dec(_f$fPerF),
        crewPerS: data.dec(_f$crewPerS),
        crewPerF: data.dec(_f$crewPerF),
        hints: data.dec(_f$hints),
        tags: data.dec(_f$tags),
        rarity: data.dec(_f$rarity),
        breakProb: data.dec(_f$breakProb),
        minPieces: data.dec(_f$minPieces),
        maxPieces: data.dec(_f$maxPieces),
        travelDrive: data.dec(_f$travelDrive),
        number: data.dec(_f$number),
        bounds: data.dec(_f$bounds),
        center: data.dec(_f$center),
        collisionRadius: data.dec(_f$collisionRadius),
        height: data.dec(_f$height),
        width: data.dec(_f$width),
        hullName: data.dec(_f$hullName),
        hullSize: data.dec(_f$hullSize),
        shieldCenter: data.dec(_f$shieldCenter),
        shieldRadius: data.dec(_f$shieldRadius),
        spriteName: data.dec(_f$spriteName),
        style: data.dec(_f$style),
        viewOffset: data.dec(_f$viewOffset),
        engineSlots: data.dec(_f$engineSlots),
        weaponSlots: data.dec(_f$weaponSlots),
        builtInWeapons: data.dec(_f$builtInWeapons),
        builtInMods: data.dec(_f$builtInMods),
        builtInWings: data.dec(_f$builtInWings),
        moduleAnchor: data.dec(_f$moduleAnchor),
        modId: data.dec(_f$modId),
        modName: data.dec(_f$modName),
        color: data.dec(_f$color));
  }

  @override
  final Function instantiate = _instantiate;

  static Ship fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<Ship>(map);
  }

  static Ship fromJson(String json) {
    return ensureInitialized().decodeJson<Ship>(json);
  }
}

mixin ShipMappable {
  String toJson() {
    return ShipMapper.ensureInitialized().encodeJson<Ship>(this as Ship);
  }

  Map<String, dynamic> toMap() {
    return ShipMapper.ensureInitialized().encodeMap<Ship>(this as Ship);
  }

  ShipCopyWith<Ship, Ship, Ship> get copyWith =>
      _ShipCopyWithImpl(this as Ship, $identity, $identity);
  @override
  String toString() {
    return ShipMapper.ensureInitialized().stringifyValue(this as Ship);
  }

  @override
  bool operator ==(Object other) {
    return ShipMapper.ensureInitialized().equalsValue(this as Ship, other);
  }

  @override
  int get hashCode {
    return ShipMapper.ensureInitialized().hashValue(this as Ship);
  }
}

extension ShipValueCopy<$R, $Out> on ObjectCopyWith<$R, Ship, $Out> {
  ShipCopyWith<$R, Ship, $Out> get $asShip =>
      $base.as((v, t, t2) => _ShipCopyWithImpl(v, t, t2));
}

abstract class ShipCopyWith<$R, $In extends Ship, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>>? get hints;
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>>? get tags;
  ListCopyWith<$R, double, ObjectCopyWith<$R, double, double>>? get bounds;
  ListCopyWith<$R, double, ObjectCopyWith<$R, double, double>>? get center;
  ListCopyWith<$R, double, ObjectCopyWith<$R, double, double>>?
      get shieldCenter;
  ListCopyWith<$R, dynamic, ObjectCopyWith<$R, dynamic, dynamic>>?
      get engineSlots;
  ListCopyWith<$R, ShipWeaponSlot,
          ShipWeaponSlotCopyWith<$R, ShipWeaponSlot, ShipWeaponSlot>>?
      get weaponSlots;
  MapCopyWith<$R, String, String, ObjectCopyWith<$R, String, String>>?
      get builtInWeapons;
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>>? get builtInMods;
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>>?
      get builtInWings;
  ListCopyWith<$R, double, ObjectCopyWith<$R, double, double>>?
      get moduleAnchor;
  $R call(
      {String? id,
      String? name,
      String? designation,
      String? techManufacturer,
      String? systemId,
      String? fleetPts,
      String? hitpoints,
      String? armorRating,
      String? maxFlux,
      String? fluxPercent8654,
      String? fluxDissipation,
      String? ordnancePoints,
      String? fighterBays,
      String? maxSpeed,
      String? acceleration,
      String? deceleration,
      String? maxTurnRate,
      String? turnAcceleration,
      String? mass,
      String? shieldType,
      String? defenseId,
      String? shieldArc,
      String? shieldUpkeep,
      String? shieldEfficiency,
      String? phaseCost,
      String? phaseUpkeep,
      String? minCrew,
      String? maxCrew,
      String? cargo,
      String? fuel,
      String? fuelPerLY,
      String? range,
      String? maxBurn,
      String? baseValue,
      String? crPercentPerDay,
      String? crToDeploy,
      String? peakCrSec,
      String? crLossPerSec,
      String? suppliesRec,
      String? suppliesMo,
      String? cPerS,
      String? cPerF,
      String? fPerS,
      String? fPerF,
      String? crewPerS,
      String? crewPerF,
      List<String>? hints,
      List<String>? tags,
      String? rarity,
      String? breakProb,
      String? minPieces,
      String? maxPieces,
      String? travelDrive,
      String? number,
      List<double>? bounds,
      List<double>? center,
      double? collisionRadius,
      double? height,
      double? width,
      String? hullName,
      String? hullSize,
      List<double>? shieldCenter,
      double? shieldRadius,
      String? spriteName,
      String? style,
      double? viewOffset,
      List<dynamic>? engineSlots,
      List<ShipWeaponSlot>? weaponSlots,
      Map<String, String>? builtInWeapons,
      List<String>? builtInMods,
      List<String>? builtInWings,
      List<double>? moduleAnchor,
      String? modId,
      String? modName,
      Color? color});
  ShipCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _ShipCopyWithImpl<$R, $Out> extends ClassCopyWithBase<$R, Ship, $Out>
    implements ShipCopyWith<$R, Ship, $Out> {
  _ShipCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<Ship> $mapper = ShipMapper.ensureInitialized();
  @override
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>>? get hints =>
      $value.hints != null
          ? ListCopyWith($value.hints!,
              (v, t) => ObjectCopyWith(v, $identity, t), (v) => call(hints: v))
          : null;
  @override
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>>? get tags =>
      $value.tags != null
          ? ListCopyWith($value.tags!,
              (v, t) => ObjectCopyWith(v, $identity, t), (v) => call(tags: v))
          : null;
  @override
  ListCopyWith<$R, double, ObjectCopyWith<$R, double, double>>? get bounds =>
      $value.bounds != null
          ? ListCopyWith($value.bounds!,
              (v, t) => ObjectCopyWith(v, $identity, t), (v) => call(bounds: v))
          : null;
  @override
  ListCopyWith<$R, double, ObjectCopyWith<$R, double, double>>? get center =>
      $value.center != null
          ? ListCopyWith($value.center!,
              (v, t) => ObjectCopyWith(v, $identity, t), (v) => call(center: v))
          : null;
  @override
  ListCopyWith<$R, double, ObjectCopyWith<$R, double, double>>?
      get shieldCenter => $value.shieldCenter != null
          ? ListCopyWith(
              $value.shieldCenter!,
              (v, t) => ObjectCopyWith(v, $identity, t),
              (v) => call(shieldCenter: v))
          : null;
  @override
  ListCopyWith<$R, dynamic, ObjectCopyWith<$R, dynamic, dynamic>>?
      get engineSlots => $value.engineSlots != null
          ? ListCopyWith(
              $value.engineSlots!,
              (v, t) => ObjectCopyWith(v, $identity, t),
              (v) => call(engineSlots: v))
          : null;
  @override
  ListCopyWith<$R, ShipWeaponSlot,
          ShipWeaponSlotCopyWith<$R, ShipWeaponSlot, ShipWeaponSlot>>?
      get weaponSlots => $value.weaponSlots != null
          ? ListCopyWith($value.weaponSlots!, (v, t) => v.copyWith.$chain(t),
              (v) => call(weaponSlots: v))
          : null;
  @override
  MapCopyWith<$R, String, String, ObjectCopyWith<$R, String, String>>?
      get builtInWeapons => $value.builtInWeapons != null
          ? MapCopyWith(
              $value.builtInWeapons!,
              (v, t) => ObjectCopyWith(v, $identity, t),
              (v) => call(builtInWeapons: v))
          : null;
  @override
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>>?
      get builtInMods => $value.builtInMods != null
          ? ListCopyWith(
              $value.builtInMods!,
              (v, t) => ObjectCopyWith(v, $identity, t),
              (v) => call(builtInMods: v))
          : null;
  @override
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>>?
      get builtInWings => $value.builtInWings != null
          ? ListCopyWith(
              $value.builtInWings!,
              (v, t) => ObjectCopyWith(v, $identity, t),
              (v) => call(builtInWings: v))
          : null;
  @override
  ListCopyWith<$R, double, ObjectCopyWith<$R, double, double>>?
      get moduleAnchor => $value.moduleAnchor != null
          ? ListCopyWith(
              $value.moduleAnchor!,
              (v, t) => ObjectCopyWith(v, $identity, t),
              (v) => call(moduleAnchor: v))
          : null;
  @override
  $R call(
          {String? id,
          Object? name = $none,
          Object? designation = $none,
          Object? techManufacturer = $none,
          Object? systemId = $none,
          Object? fleetPts = $none,
          Object? hitpoints = $none,
          Object? armorRating = $none,
          Object? maxFlux = $none,
          Object? fluxPercent8654 = $none,
          Object? fluxDissipation = $none,
          Object? ordnancePoints = $none,
          Object? fighterBays = $none,
          Object? maxSpeed = $none,
          Object? acceleration = $none,
          Object? deceleration = $none,
          Object? maxTurnRate = $none,
          Object? turnAcceleration = $none,
          Object? mass = $none,
          Object? shieldType = $none,
          Object? defenseId = $none,
          Object? shieldArc = $none,
          Object? shieldUpkeep = $none,
          Object? shieldEfficiency = $none,
          Object? phaseCost = $none,
          Object? phaseUpkeep = $none,
          Object? minCrew = $none,
          Object? maxCrew = $none,
          Object? cargo = $none,
          Object? fuel = $none,
          Object? fuelPerLY = $none,
          Object? range = $none,
          Object? maxBurn = $none,
          Object? baseValue = $none,
          Object? crPercentPerDay = $none,
          Object? crToDeploy = $none,
          Object? peakCrSec = $none,
          Object? crLossPerSec = $none,
          Object? suppliesRec = $none,
          Object? suppliesMo = $none,
          Object? cPerS = $none,
          Object? cPerF = $none,
          Object? fPerS = $none,
          Object? fPerF = $none,
          Object? crewPerS = $none,
          Object? crewPerF = $none,
          Object? hints = $none,
          Object? tags = $none,
          Object? rarity = $none,
          Object? breakProb = $none,
          Object? minPieces = $none,
          Object? maxPieces = $none,
          Object? travelDrive = $none,
          Object? number = $none,
          Object? bounds = $none,
          Object? center = $none,
          Object? collisionRadius = $none,
          Object? height = $none,
          Object? width = $none,
          Object? hullName = $none,
          Object? hullSize = $none,
          Object? shieldCenter = $none,
          Object? shieldRadius = $none,
          Object? spriteName = $none,
          Object? style = $none,
          Object? viewOffset = $none,
          Object? engineSlots = $none,
          Object? weaponSlots = $none,
          Object? builtInWeapons = $none,
          Object? builtInMods = $none,
          Object? builtInWings = $none,
          Object? moduleAnchor = $none,
          Object? modId = $none,
          Object? modName = $none,
          Object? color = $none}) =>
      $apply(FieldCopyWithData({
        if (id != null) #id: id,
        if (name != $none) #name: name,
        if (designation != $none) #designation: designation,
        if (techManufacturer != $none) #techManufacturer: techManufacturer,
        if (systemId != $none) #systemId: systemId,
        if (fleetPts != $none) #fleetPts: fleetPts,
        if (hitpoints != $none) #hitpoints: hitpoints,
        if (armorRating != $none) #armorRating: armorRating,
        if (maxFlux != $none) #maxFlux: maxFlux,
        if (fluxPercent8654 != $none) #fluxPercent8654: fluxPercent8654,
        if (fluxDissipation != $none) #fluxDissipation: fluxDissipation,
        if (ordnancePoints != $none) #ordnancePoints: ordnancePoints,
        if (fighterBays != $none) #fighterBays: fighterBays,
        if (maxSpeed != $none) #maxSpeed: maxSpeed,
        if (acceleration != $none) #acceleration: acceleration,
        if (deceleration != $none) #deceleration: deceleration,
        if (maxTurnRate != $none) #maxTurnRate: maxTurnRate,
        if (turnAcceleration != $none) #turnAcceleration: turnAcceleration,
        if (mass != $none) #mass: mass,
        if (shieldType != $none) #shieldType: shieldType,
        if (defenseId != $none) #defenseId: defenseId,
        if (shieldArc != $none) #shieldArc: shieldArc,
        if (shieldUpkeep != $none) #shieldUpkeep: shieldUpkeep,
        if (shieldEfficiency != $none) #shieldEfficiency: shieldEfficiency,
        if (phaseCost != $none) #phaseCost: phaseCost,
        if (phaseUpkeep != $none) #phaseUpkeep: phaseUpkeep,
        if (minCrew != $none) #minCrew: minCrew,
        if (maxCrew != $none) #maxCrew: maxCrew,
        if (cargo != $none) #cargo: cargo,
        if (fuel != $none) #fuel: fuel,
        if (fuelPerLY != $none) #fuelPerLY: fuelPerLY,
        if (range != $none) #range: range,
        if (maxBurn != $none) #maxBurn: maxBurn,
        if (baseValue != $none) #baseValue: baseValue,
        if (crPercentPerDay != $none) #crPercentPerDay: crPercentPerDay,
        if (crToDeploy != $none) #crToDeploy: crToDeploy,
        if (peakCrSec != $none) #peakCrSec: peakCrSec,
        if (crLossPerSec != $none) #crLossPerSec: crLossPerSec,
        if (suppliesRec != $none) #suppliesRec: suppliesRec,
        if (suppliesMo != $none) #suppliesMo: suppliesMo,
        if (cPerS != $none) #cPerS: cPerS,
        if (cPerF != $none) #cPerF: cPerF,
        if (fPerS != $none) #fPerS: fPerS,
        if (fPerF != $none) #fPerF: fPerF,
        if (crewPerS != $none) #crewPerS: crewPerS,
        if (crewPerF != $none) #crewPerF: crewPerF,
        if (hints != $none) #hints: hints,
        if (tags != $none) #tags: tags,
        if (rarity != $none) #rarity: rarity,
        if (breakProb != $none) #breakProb: breakProb,
        if (minPieces != $none) #minPieces: minPieces,
        if (maxPieces != $none) #maxPieces: maxPieces,
        if (travelDrive != $none) #travelDrive: travelDrive,
        if (number != $none) #number: number,
        if (bounds != $none) #bounds: bounds,
        if (center != $none) #center: center,
        if (collisionRadius != $none) #collisionRadius: collisionRadius,
        if (height != $none) #height: height,
        if (width != $none) #width: width,
        if (hullName != $none) #hullName: hullName,
        if (hullSize != $none) #hullSize: hullSize,
        if (shieldCenter != $none) #shieldCenter: shieldCenter,
        if (shieldRadius != $none) #shieldRadius: shieldRadius,
        if (spriteName != $none) #spriteName: spriteName,
        if (style != $none) #style: style,
        if (viewOffset != $none) #viewOffset: viewOffset,
        if (engineSlots != $none) #engineSlots: engineSlots,
        if (weaponSlots != $none) #weaponSlots: weaponSlots,
        if (builtInWeapons != $none) #builtInWeapons: builtInWeapons,
        if (builtInMods != $none) #builtInMods: builtInMods,
        if (builtInWings != $none) #builtInWings: builtInWings,
        if (moduleAnchor != $none) #moduleAnchor: moduleAnchor,
        if (modId != $none) #modId: modId,
        if (modName != $none) #modName: modName,
        if (color != $none) #color: color
      }));
  @override
  Ship $make(CopyWithData data) => Ship(
      id: data.get(#id, or: $value.id),
      name: data.get(#name, or: $value.name),
      designation: data.get(#designation, or: $value.designation),
      techManufacturer:
          data.get(#techManufacturer, or: $value.techManufacturer),
      systemId: data.get(#systemId, or: $value.systemId),
      fleetPts: data.get(#fleetPts, or: $value.fleetPts),
      hitpoints: data.get(#hitpoints, or: $value.hitpoints),
      armorRating: data.get(#armorRating, or: $value.armorRating),
      maxFlux: data.get(#maxFlux, or: $value.maxFlux),
      fluxPercent8654: data.get(#fluxPercent8654, or: $value.fluxPercent8654),
      fluxDissipation: data.get(#fluxDissipation, or: $value.fluxDissipation),
      ordnancePoints: data.get(#ordnancePoints, or: $value.ordnancePoints),
      fighterBays: data.get(#fighterBays, or: $value.fighterBays),
      maxSpeed: data.get(#maxSpeed, or: $value.maxSpeed),
      acceleration: data.get(#acceleration, or: $value.acceleration),
      deceleration: data.get(#deceleration, or: $value.deceleration),
      maxTurnRate: data.get(#maxTurnRate, or: $value.maxTurnRate),
      turnAcceleration:
          data.get(#turnAcceleration, or: $value.turnAcceleration),
      mass: data.get(#mass, or: $value.mass),
      shieldType: data.get(#shieldType, or: $value.shieldType),
      defenseId: data.get(#defenseId, or: $value.defenseId),
      shieldArc: data.get(#shieldArc, or: $value.shieldArc),
      shieldUpkeep: data.get(#shieldUpkeep, or: $value.shieldUpkeep),
      shieldEfficiency:
          data.get(#shieldEfficiency, or: $value.shieldEfficiency),
      phaseCost: data.get(#phaseCost, or: $value.phaseCost),
      phaseUpkeep: data.get(#phaseUpkeep, or: $value.phaseUpkeep),
      minCrew: data.get(#minCrew, or: $value.minCrew),
      maxCrew: data.get(#maxCrew, or: $value.maxCrew),
      cargo: data.get(#cargo, or: $value.cargo),
      fuel: data.get(#fuel, or: $value.fuel),
      fuelPerLY: data.get(#fuelPerLY, or: $value.fuelPerLY),
      range: data.get(#range, or: $value.range),
      maxBurn: data.get(#maxBurn, or: $value.maxBurn),
      baseValue: data.get(#baseValue, or: $value.baseValue),
      crPercentPerDay: data.get(#crPercentPerDay, or: $value.crPercentPerDay),
      crToDeploy: data.get(#crToDeploy, or: $value.crToDeploy),
      peakCrSec: data.get(#peakCrSec, or: $value.peakCrSec),
      crLossPerSec: data.get(#crLossPerSec, or: $value.crLossPerSec),
      suppliesRec: data.get(#suppliesRec, or: $value.suppliesRec),
      suppliesMo: data.get(#suppliesMo, or: $value.suppliesMo),
      cPerS: data.get(#cPerS, or: $value.cPerS),
      cPerF: data.get(#cPerF, or: $value.cPerF),
      fPerS: data.get(#fPerS, or: $value.fPerS),
      fPerF: data.get(#fPerF, or: $value.fPerF),
      crewPerS: data.get(#crewPerS, or: $value.crewPerS),
      crewPerF: data.get(#crewPerF, or: $value.crewPerF),
      hints: data.get(#hints, or: $value.hints),
      tags: data.get(#tags, or: $value.tags),
      rarity: data.get(#rarity, or: $value.rarity),
      breakProb: data.get(#breakProb, or: $value.breakProb),
      minPieces: data.get(#minPieces, or: $value.minPieces),
      maxPieces: data.get(#maxPieces, or: $value.maxPieces),
      travelDrive: data.get(#travelDrive, or: $value.travelDrive),
      number: data.get(#number, or: $value.number),
      bounds: data.get(#bounds, or: $value.bounds),
      center: data.get(#center, or: $value.center),
      collisionRadius: data.get(#collisionRadius, or: $value.collisionRadius),
      height: data.get(#height, or: $value.height),
      width: data.get(#width, or: $value.width),
      hullName: data.get(#hullName, or: $value.hullName),
      hullSize: data.get(#hullSize, or: $value.hullSize),
      shieldCenter: data.get(#shieldCenter, or: $value.shieldCenter),
      shieldRadius: data.get(#shieldRadius, or: $value.shieldRadius),
      spriteName: data.get(#spriteName, or: $value.spriteName),
      style: data.get(#style, or: $value.style),
      viewOffset: data.get(#viewOffset, or: $value.viewOffset),
      engineSlots: data.get(#engineSlots, or: $value.engineSlots),
      weaponSlots: data.get(#weaponSlots, or: $value.weaponSlots),
      builtInWeapons: data.get(#builtInWeapons, or: $value.builtInWeapons),
      builtInMods: data.get(#builtInMods, or: $value.builtInMods),
      builtInWings: data.get(#builtInWings, or: $value.builtInWings),
      moduleAnchor: data.get(#moduleAnchor, or: $value.moduleAnchor),
      modId: data.get(#modId, or: $value.modId),
      modName: data.get(#modName, or: $value.modName),
      color: data.get(#color, or: $value.color));

  @override
  ShipCopyWith<$R2, Ship, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _ShipCopyWithImpl($value, $cast, t);
}
