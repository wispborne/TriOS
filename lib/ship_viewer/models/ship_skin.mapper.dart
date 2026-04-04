// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'ship_skin.dart';

class ShipSkinMapper extends ClassMapperBase<ShipSkin> {
  ShipSkinMapper._();

  static ShipSkinMapper? _instance;
  static ShipSkinMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ShipSkinMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'ShipSkin';

  static String _$baseHullId(ShipSkin v) => v.baseHullId;
  static const Field<ShipSkin, String> _f$baseHullId = Field(
    'baseHullId',
    _$baseHullId,
  );
  static String _$skinHullId(ShipSkin v) => v.skinHullId;
  static const Field<ShipSkin, String> _f$skinHullId = Field(
    'skinHullId',
    _$skinHullId,
  );
  static String? _$hullName(ShipSkin v) => v.hullName;
  static const Field<ShipSkin, String> _f$hullName = Field(
    'hullName',
    _$hullName,
    opt: true,
  );
  static String? _$hullDesignation(ShipSkin v) => v.hullDesignation;
  static const Field<ShipSkin, String> _f$hullDesignation = Field(
    'hullDesignation',
    _$hullDesignation,
    opt: true,
  );
  static String? _$manufacturer(ShipSkin v) => v.manufacturer;
  static const Field<ShipSkin, String> _f$manufacturer = Field(
    'manufacturer',
    _$manufacturer,
    opt: true,
  );
  static String? _$tech(ShipSkin v) => v.tech;
  static const Field<ShipSkin, String> _f$tech = Field(
    'tech',
    _$tech,
    opt: true,
  );
  static String? _$spriteName(ShipSkin v) => v.spriteName;
  static const Field<ShipSkin, String> _f$spriteName = Field(
    'spriteName',
    _$spriteName,
    opt: true,
  );
  static String? _$systemId(ShipSkin v) => v.systemId;
  static const Field<ShipSkin, String> _f$systemId = Field(
    'systemId',
    _$systemId,
    opt: true,
  );
  static String? _$descriptionId(ShipSkin v) => v.descriptionId;
  static const Field<ShipSkin, String> _f$descriptionId = Field(
    'descriptionId',
    _$descriptionId,
    opt: true,
  );
  static String? _$descriptionPrefix(ShipSkin v) => v.descriptionPrefix;
  static const Field<ShipSkin, String> _f$descriptionPrefix = Field(
    'descriptionPrefix',
    _$descriptionPrefix,
    opt: true,
  );
  static num? _$fleetPoints(ShipSkin v) => v.fleetPoints;
  static const Field<ShipSkin, num> _f$fleetPoints = Field(
    'fleetPoints',
    _$fleetPoints,
    opt: true,
  );
  static num? _$ordnancePoints(ShipSkin v) => v.ordnancePoints;
  static const Field<ShipSkin, num> _f$ordnancePoints = Field(
    'ordnancePoints',
    _$ordnancePoints,
    opt: true,
  );
  static num? _$baseValue(ShipSkin v) => v.baseValue;
  static const Field<ShipSkin, num> _f$baseValue = Field(
    'baseValue',
    _$baseValue,
    opt: true,
  );
  static double? _$baseValueMult(ShipSkin v) => v.baseValueMult;
  static const Field<ShipSkin, double> _f$baseValueMult = Field(
    'baseValueMult',
    _$baseValueMult,
    opt: true,
  );
  static num? _$fighterBays(ShipSkin v) => v.fighterBays;
  static const Field<ShipSkin, num> _f$fighterBays = Field(
    'fighterBays',
    _$fighterBays,
    opt: true,
  );
  static num? _$fpMod(ShipSkin v) => v.fpMod;
  static const Field<ShipSkin, num> _f$fpMod = Field(
    'fpMod',
    _$fpMod,
    opt: true,
  );
  static bool? _$restoreToBaseHull(ShipSkin v) => v.restoreToBaseHull;
  static const Field<ShipSkin, bool> _f$restoreToBaseHull = Field(
    'restoreToBaseHull',
    _$restoreToBaseHull,
    opt: true,
  );
  static List<String>? _$builtInMods(ShipSkin v) => v.builtInMods;
  static const Field<ShipSkin, List<String>> _f$builtInMods = Field(
    'builtInMods',
    _$builtInMods,
    opt: true,
  );
  static List<String>? _$removeBuiltInMods(ShipSkin v) => v.removeBuiltInMods;
  static const Field<ShipSkin, List<String>> _f$removeBuiltInMods = Field(
    'removeBuiltInMods',
    _$removeBuiltInMods,
    opt: true,
  );
  static Map<String, String>? _$builtInWeapons(ShipSkin v) => v.builtInWeapons;
  static const Field<ShipSkin, Map<String, String>> _f$builtInWeapons = Field(
    'builtInWeapons',
    _$builtInWeapons,
    opt: true,
  );
  static List<String>? _$removeBuiltInWeapons(ShipSkin v) =>
      v.removeBuiltInWeapons;
  static const Field<ShipSkin, List<String>> _f$removeBuiltInWeapons = Field(
    'removeBuiltInWeapons',
    _$removeBuiltInWeapons,
    opt: true,
  );
  static List<String>? _$removeWeaponSlots(ShipSkin v) => v.removeWeaponSlots;
  static const Field<ShipSkin, List<String>> _f$removeWeaponSlots = Field(
    'removeWeaponSlots',
    _$removeWeaponSlots,
    opt: true,
  );
  static Map<String, dynamic>? _$weaponSlotChanges(ShipSkin v) =>
      v.weaponSlotChanges;
  static const Field<ShipSkin, Map<String, dynamic>> _f$weaponSlotChanges =
      Field('weaponSlotChanges', _$weaponSlotChanges, opt: true);
  static List<String>? _$removeHints(ShipSkin v) => v.removeHints;
  static const Field<ShipSkin, List<String>> _f$removeHints = Field(
    'removeHints',
    _$removeHints,
    opt: true,
  );
  static List<String>? _$addHints(ShipSkin v) => v.addHints;
  static const Field<ShipSkin, List<String>> _f$addHints = Field(
    'addHints',
    _$addHints,
    opt: true,
  );
  static List<String>? _$tags(ShipSkin v) => v.tags;
  static const Field<ShipSkin, List<String>> _f$tags = Field(
    'tags',
    _$tags,
    opt: true,
  );
  static List<String>? _$builtInWings(ShipSkin v) => v.builtInWings;
  static const Field<ShipSkin, List<String>> _f$builtInWings = Field(
    'builtInWings',
    _$builtInWings,
    opt: true,
  );
  static List<int>? _$removeEngineSlots(ShipSkin v) => v.removeEngineSlots;
  static const Field<ShipSkin, List<int>> _f$removeEngineSlots = Field(
    'removeEngineSlots',
    _$removeEngineSlots,
    opt: true,
  );
  static Map<String, dynamic>? _$engineSlotChanges(ShipSkin v) =>
      v.engineSlotChanges;
  static const Field<ShipSkin, Map<String, dynamic>> _f$engineSlotChanges =
      Field('engineSlotChanges', _$engineSlotChanges, opt: true);
  static List<int>? _$coversColor(ShipSkin v) => v.coversColor;
  static const Field<ShipSkin, List<int>> _f$coversColor = Field(
    'coversColor',
    _$coversColor,
    opt: true,
  );

  @override
  final MappableFields<ShipSkin> fields = const {
    #baseHullId: _f$baseHullId,
    #skinHullId: _f$skinHullId,
    #hullName: _f$hullName,
    #hullDesignation: _f$hullDesignation,
    #manufacturer: _f$manufacturer,
    #tech: _f$tech,
    #spriteName: _f$spriteName,
    #systemId: _f$systemId,
    #descriptionId: _f$descriptionId,
    #descriptionPrefix: _f$descriptionPrefix,
    #fleetPoints: _f$fleetPoints,
    #ordnancePoints: _f$ordnancePoints,
    #baseValue: _f$baseValue,
    #baseValueMult: _f$baseValueMult,
    #fighterBays: _f$fighterBays,
    #fpMod: _f$fpMod,
    #restoreToBaseHull: _f$restoreToBaseHull,
    #builtInMods: _f$builtInMods,
    #removeBuiltInMods: _f$removeBuiltInMods,
    #builtInWeapons: _f$builtInWeapons,
    #removeBuiltInWeapons: _f$removeBuiltInWeapons,
    #removeWeaponSlots: _f$removeWeaponSlots,
    #weaponSlotChanges: _f$weaponSlotChanges,
    #removeHints: _f$removeHints,
    #addHints: _f$addHints,
    #tags: _f$tags,
    #builtInWings: _f$builtInWings,
    #removeEngineSlots: _f$removeEngineSlots,
    #engineSlotChanges: _f$engineSlotChanges,
    #coversColor: _f$coversColor,
  };

  static ShipSkin _instantiate(DecodingData data) {
    return ShipSkin(
      baseHullId: data.dec(_f$baseHullId),
      skinHullId: data.dec(_f$skinHullId),
      hullName: data.dec(_f$hullName),
      hullDesignation: data.dec(_f$hullDesignation),
      manufacturer: data.dec(_f$manufacturer),
      tech: data.dec(_f$tech),
      spriteName: data.dec(_f$spriteName),
      systemId: data.dec(_f$systemId),
      descriptionId: data.dec(_f$descriptionId),
      descriptionPrefix: data.dec(_f$descriptionPrefix),
      fleetPoints: data.dec(_f$fleetPoints),
      ordnancePoints: data.dec(_f$ordnancePoints),
      baseValue: data.dec(_f$baseValue),
      baseValueMult: data.dec(_f$baseValueMult),
      fighterBays: data.dec(_f$fighterBays),
      fpMod: data.dec(_f$fpMod),
      restoreToBaseHull: data.dec(_f$restoreToBaseHull),
      builtInMods: data.dec(_f$builtInMods),
      removeBuiltInMods: data.dec(_f$removeBuiltInMods),
      builtInWeapons: data.dec(_f$builtInWeapons),
      removeBuiltInWeapons: data.dec(_f$removeBuiltInWeapons),
      removeWeaponSlots: data.dec(_f$removeWeaponSlots),
      weaponSlotChanges: data.dec(_f$weaponSlotChanges),
      removeHints: data.dec(_f$removeHints),
      addHints: data.dec(_f$addHints),
      tags: data.dec(_f$tags),
      builtInWings: data.dec(_f$builtInWings),
      removeEngineSlots: data.dec(_f$removeEngineSlots),
      engineSlotChanges: data.dec(_f$engineSlotChanges),
      coversColor: data.dec(_f$coversColor),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static ShipSkin fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<ShipSkin>(map);
  }

  static ShipSkin fromJson(String json) {
    return ensureInitialized().decodeJson<ShipSkin>(json);
  }
}

mixin ShipSkinMappable {
  String toJson() {
    return ShipSkinMapper.ensureInitialized().encodeJson<ShipSkin>(
      this as ShipSkin,
    );
  }

  Map<String, dynamic> toMap() {
    return ShipSkinMapper.ensureInitialized().encodeMap<ShipSkin>(
      this as ShipSkin,
    );
  }

  ShipSkinCopyWith<ShipSkin, ShipSkin, ShipSkin> get copyWith =>
      _ShipSkinCopyWithImpl<ShipSkin, ShipSkin>(
        this as ShipSkin,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return ShipSkinMapper.ensureInitialized().stringifyValue(this as ShipSkin);
  }

  @override
  bool operator ==(Object other) {
    return ShipSkinMapper.ensureInitialized().equalsValue(
      this as ShipSkin,
      other,
    );
  }

  @override
  int get hashCode {
    return ShipSkinMapper.ensureInitialized().hashValue(this as ShipSkin);
  }
}

extension ShipSkinValueCopy<$R, $Out> on ObjectCopyWith<$R, ShipSkin, $Out> {
  ShipSkinCopyWith<$R, ShipSkin, $Out> get $asShipSkin =>
      $base.as((v, t, t2) => _ShipSkinCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class ShipSkinCopyWith<$R, $In extends ShipSkin, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>>? get builtInMods;
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>>?
  get removeBuiltInMods;
  MapCopyWith<$R, String, String, ObjectCopyWith<$R, String, String>>?
  get builtInWeapons;
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>>?
  get removeBuiltInWeapons;
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>>?
  get removeWeaponSlots;
  MapCopyWith<$R, String, dynamic, ObjectCopyWith<$R, dynamic, dynamic>>?
  get weaponSlotChanges;
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>>? get removeHints;
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>>? get addHints;
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>>? get tags;
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>>?
  get builtInWings;
  ListCopyWith<$R, int, ObjectCopyWith<$R, int, int>>? get removeEngineSlots;
  MapCopyWith<$R, String, dynamic, ObjectCopyWith<$R, dynamic, dynamic>>?
  get engineSlotChanges;
  ListCopyWith<$R, int, ObjectCopyWith<$R, int, int>>? get coversColor;
  $R call({
    String? baseHullId,
    String? skinHullId,
    String? hullName,
    String? hullDesignation,
    String? manufacturer,
    String? tech,
    String? spriteName,
    String? systemId,
    String? descriptionId,
    String? descriptionPrefix,
    num? fleetPoints,
    num? ordnancePoints,
    num? baseValue,
    double? baseValueMult,
    num? fighterBays,
    num? fpMod,
    bool? restoreToBaseHull,
    List<String>? builtInMods,
    List<String>? removeBuiltInMods,
    Map<String, String>? builtInWeapons,
    List<String>? removeBuiltInWeapons,
    List<String>? removeWeaponSlots,
    Map<String, dynamic>? weaponSlotChanges,
    List<String>? removeHints,
    List<String>? addHints,
    List<String>? tags,
    List<String>? builtInWings,
    List<int>? removeEngineSlots,
    Map<String, dynamic>? engineSlotChanges,
    List<int>? coversColor,
  });
  ShipSkinCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _ShipSkinCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, ShipSkin, $Out>
    implements ShipSkinCopyWith<$R, ShipSkin, $Out> {
  _ShipSkinCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<ShipSkin> $mapper =
      ShipSkinMapper.ensureInitialized();
  @override
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>>?
  get builtInMods => $value.builtInMods != null
      ? ListCopyWith(
          $value.builtInMods!,
          (v, t) => ObjectCopyWith(v, $identity, t),
          (v) => call(builtInMods: v),
        )
      : null;
  @override
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>>?
  get removeBuiltInMods => $value.removeBuiltInMods != null
      ? ListCopyWith(
          $value.removeBuiltInMods!,
          (v, t) => ObjectCopyWith(v, $identity, t),
          (v) => call(removeBuiltInMods: v),
        )
      : null;
  @override
  MapCopyWith<$R, String, String, ObjectCopyWith<$R, String, String>>?
  get builtInWeapons => $value.builtInWeapons != null
      ? MapCopyWith(
          $value.builtInWeapons!,
          (v, t) => ObjectCopyWith(v, $identity, t),
          (v) => call(builtInWeapons: v),
        )
      : null;
  @override
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>>?
  get removeBuiltInWeapons => $value.removeBuiltInWeapons != null
      ? ListCopyWith(
          $value.removeBuiltInWeapons!,
          (v, t) => ObjectCopyWith(v, $identity, t),
          (v) => call(removeBuiltInWeapons: v),
        )
      : null;
  @override
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>>?
  get removeWeaponSlots => $value.removeWeaponSlots != null
      ? ListCopyWith(
          $value.removeWeaponSlots!,
          (v, t) => ObjectCopyWith(v, $identity, t),
          (v) => call(removeWeaponSlots: v),
        )
      : null;
  @override
  MapCopyWith<$R, String, dynamic, ObjectCopyWith<$R, dynamic, dynamic>>?
  get weaponSlotChanges => $value.weaponSlotChanges != null
      ? MapCopyWith(
          $value.weaponSlotChanges!,
          (v, t) => ObjectCopyWith(v, $identity, t),
          (v) => call(weaponSlotChanges: v),
        )
      : null;
  @override
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>>?
  get removeHints => $value.removeHints != null
      ? ListCopyWith(
          $value.removeHints!,
          (v, t) => ObjectCopyWith(v, $identity, t),
          (v) => call(removeHints: v),
        )
      : null;
  @override
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>>? get addHints =>
      $value.addHints != null
      ? ListCopyWith(
          $value.addHints!,
          (v, t) => ObjectCopyWith(v, $identity, t),
          (v) => call(addHints: v),
        )
      : null;
  @override
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>>? get tags =>
      $value.tags != null
      ? ListCopyWith(
          $value.tags!,
          (v, t) => ObjectCopyWith(v, $identity, t),
          (v) => call(tags: v),
        )
      : null;
  @override
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>>?
  get builtInWings => $value.builtInWings != null
      ? ListCopyWith(
          $value.builtInWings!,
          (v, t) => ObjectCopyWith(v, $identity, t),
          (v) => call(builtInWings: v),
        )
      : null;
  @override
  ListCopyWith<$R, int, ObjectCopyWith<$R, int, int>>? get removeEngineSlots =>
      $value.removeEngineSlots != null
      ? ListCopyWith(
          $value.removeEngineSlots!,
          (v, t) => ObjectCopyWith(v, $identity, t),
          (v) => call(removeEngineSlots: v),
        )
      : null;
  @override
  MapCopyWith<$R, String, dynamic, ObjectCopyWith<$R, dynamic, dynamic>>?
  get engineSlotChanges => $value.engineSlotChanges != null
      ? MapCopyWith(
          $value.engineSlotChanges!,
          (v, t) => ObjectCopyWith(v, $identity, t),
          (v) => call(engineSlotChanges: v),
        )
      : null;
  @override
  ListCopyWith<$R, int, ObjectCopyWith<$R, int, int>>? get coversColor =>
      $value.coversColor != null
      ? ListCopyWith(
          $value.coversColor!,
          (v, t) => ObjectCopyWith(v, $identity, t),
          (v) => call(coversColor: v),
        )
      : null;
  @override
  $R call({
    String? baseHullId,
    String? skinHullId,
    Object? hullName = $none,
    Object? hullDesignation = $none,
    Object? manufacturer = $none,
    Object? tech = $none,
    Object? spriteName = $none,
    Object? systemId = $none,
    Object? descriptionId = $none,
    Object? descriptionPrefix = $none,
    Object? fleetPoints = $none,
    Object? ordnancePoints = $none,
    Object? baseValue = $none,
    Object? baseValueMult = $none,
    Object? fighterBays = $none,
    Object? fpMod = $none,
    Object? restoreToBaseHull = $none,
    Object? builtInMods = $none,
    Object? removeBuiltInMods = $none,
    Object? builtInWeapons = $none,
    Object? removeBuiltInWeapons = $none,
    Object? removeWeaponSlots = $none,
    Object? weaponSlotChanges = $none,
    Object? removeHints = $none,
    Object? addHints = $none,
    Object? tags = $none,
    Object? builtInWings = $none,
    Object? removeEngineSlots = $none,
    Object? engineSlotChanges = $none,
    Object? coversColor = $none,
  }) => $apply(
    FieldCopyWithData({
      if (baseHullId != null) #baseHullId: baseHullId,
      if (skinHullId != null) #skinHullId: skinHullId,
      if (hullName != $none) #hullName: hullName,
      if (hullDesignation != $none) #hullDesignation: hullDesignation,
      if (manufacturer != $none) #manufacturer: manufacturer,
      if (tech != $none) #tech: tech,
      if (spriteName != $none) #spriteName: spriteName,
      if (systemId != $none) #systemId: systemId,
      if (descriptionId != $none) #descriptionId: descriptionId,
      if (descriptionPrefix != $none) #descriptionPrefix: descriptionPrefix,
      if (fleetPoints != $none) #fleetPoints: fleetPoints,
      if (ordnancePoints != $none) #ordnancePoints: ordnancePoints,
      if (baseValue != $none) #baseValue: baseValue,
      if (baseValueMult != $none) #baseValueMult: baseValueMult,
      if (fighterBays != $none) #fighterBays: fighterBays,
      if (fpMod != $none) #fpMod: fpMod,
      if (restoreToBaseHull != $none) #restoreToBaseHull: restoreToBaseHull,
      if (builtInMods != $none) #builtInMods: builtInMods,
      if (removeBuiltInMods != $none) #removeBuiltInMods: removeBuiltInMods,
      if (builtInWeapons != $none) #builtInWeapons: builtInWeapons,
      if (removeBuiltInWeapons != $none)
        #removeBuiltInWeapons: removeBuiltInWeapons,
      if (removeWeaponSlots != $none) #removeWeaponSlots: removeWeaponSlots,
      if (weaponSlotChanges != $none) #weaponSlotChanges: weaponSlotChanges,
      if (removeHints != $none) #removeHints: removeHints,
      if (addHints != $none) #addHints: addHints,
      if (tags != $none) #tags: tags,
      if (builtInWings != $none) #builtInWings: builtInWings,
      if (removeEngineSlots != $none) #removeEngineSlots: removeEngineSlots,
      if (engineSlotChanges != $none) #engineSlotChanges: engineSlotChanges,
      if (coversColor != $none) #coversColor: coversColor,
    }),
  );
  @override
  ShipSkin $make(CopyWithData data) => ShipSkin(
    baseHullId: data.get(#baseHullId, or: $value.baseHullId),
    skinHullId: data.get(#skinHullId, or: $value.skinHullId),
    hullName: data.get(#hullName, or: $value.hullName),
    hullDesignation: data.get(#hullDesignation, or: $value.hullDesignation),
    manufacturer: data.get(#manufacturer, or: $value.manufacturer),
    tech: data.get(#tech, or: $value.tech),
    spriteName: data.get(#spriteName, or: $value.spriteName),
    systemId: data.get(#systemId, or: $value.systemId),
    descriptionId: data.get(#descriptionId, or: $value.descriptionId),
    descriptionPrefix: data.get(
      #descriptionPrefix,
      or: $value.descriptionPrefix,
    ),
    fleetPoints: data.get(#fleetPoints, or: $value.fleetPoints),
    ordnancePoints: data.get(#ordnancePoints, or: $value.ordnancePoints),
    baseValue: data.get(#baseValue, or: $value.baseValue),
    baseValueMult: data.get(#baseValueMult, or: $value.baseValueMult),
    fighterBays: data.get(#fighterBays, or: $value.fighterBays),
    fpMod: data.get(#fpMod, or: $value.fpMod),
    restoreToBaseHull: data.get(
      #restoreToBaseHull,
      or: $value.restoreToBaseHull,
    ),
    builtInMods: data.get(#builtInMods, or: $value.builtInMods),
    removeBuiltInMods: data.get(
      #removeBuiltInMods,
      or: $value.removeBuiltInMods,
    ),
    builtInWeapons: data.get(#builtInWeapons, or: $value.builtInWeapons),
    removeBuiltInWeapons: data.get(
      #removeBuiltInWeapons,
      or: $value.removeBuiltInWeapons,
    ),
    removeWeaponSlots: data.get(
      #removeWeaponSlots,
      or: $value.removeWeaponSlots,
    ),
    weaponSlotChanges: data.get(
      #weaponSlotChanges,
      or: $value.weaponSlotChanges,
    ),
    removeHints: data.get(#removeHints, or: $value.removeHints),
    addHints: data.get(#addHints, or: $value.addHints),
    tags: data.get(#tags, or: $value.tags),
    builtInWings: data.get(#builtInWings, or: $value.builtInWings),
    removeEngineSlots: data.get(
      #removeEngineSlots,
      or: $value.removeEngineSlots,
    ),
    engineSlotChanges: data.get(
      #engineSlotChanges,
      or: $value.engineSlotChanges,
    ),
    coversColor: data.get(#coversColor, or: $value.coversColor),
  );

  @override
  ShipSkinCopyWith<$R2, ShipSkin, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _ShipSkinCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

