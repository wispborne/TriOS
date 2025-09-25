// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'weapon.dart';

class WeaponMapper extends ClassMapperBase<Weapon> {
  WeaponMapper._();

  static WeaponMapper? _instance;
  static WeaponMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = WeaponMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'Weapon';

  static String? _$name(Weapon v) => v.name;
  static const Field<Weapon, String> _f$name = Field('name', _$name);
  static String _$id(Weapon v) => v.id;
  static const Field<Weapon, String> _f$id = Field('id', _$id);
  static int? _$tier(Weapon v) => v.tier;
  static const Field<Weapon, int> _f$tier = Field('tier', _$tier, opt: true);
  static double? _$rarity(Weapon v) => v.rarity;
  static const Field<Weapon, double> _f$rarity = Field(
    'rarity',
    _$rarity,
    opt: true,
  );
  static double? _$baseValue(Weapon v) => v.baseValue;
  static const Field<Weapon, double> _f$baseValue = Field(
    'baseValue',
    _$baseValue,
    key: r'base value',
    opt: true,
  );
  static double? _$range(Weapon v) => v.range;
  static const Field<Weapon, double> _f$range = Field(
    'range',
    _$range,
    opt: true,
  );
  static double? _$damagePerSecond(Weapon v) => v.damagePerSecond;
  static const Field<Weapon, double> _f$damagePerSecond = Field(
    'damagePerSecond',
    _$damagePerSecond,
    key: r'damage/second',
    opt: true,
  );
  static double? _$damagePerShot(Weapon v) => v.damagePerShot;
  static const Field<Weapon, double> _f$damagePerShot = Field(
    'damagePerShot',
    _$damagePerShot,
    key: r'damage/shot',
    opt: true,
  );
  static double? _$emp(Weapon v) => v.emp;
  static const Field<Weapon, double> _f$emp = Field('emp', _$emp, opt: true);
  static double? _$impact(Weapon v) => v.impact;
  static const Field<Weapon, double> _f$impact = Field(
    'impact',
    _$impact,
    opt: true,
  );
  static double? _$turnRate(Weapon v) => v.turnRate;
  static const Field<Weapon, double> _f$turnRate = Field(
    'turnRate',
    _$turnRate,
    key: r'turn rate',
    opt: true,
  );
  static int? _$ops(Weapon v) => v.ops;
  static const Field<Weapon, int> _f$ops = Field(
    'ops',
    _$ops,
    key: r'OPs',
    opt: true,
  );
  static double? _$ammo(Weapon v) => v.ammo;
  static const Field<Weapon, double> _f$ammo = Field('ammo', _$ammo, opt: true);
  static double? _$ammoPerSec(Weapon v) => v.ammoPerSec;
  static const Field<Weapon, double> _f$ammoPerSec = Field(
    'ammoPerSec',
    _$ammoPerSec,
    key: r'ammo/sec',
    opt: true,
  );
  static double? _$reloadSize(Weapon v) => v.reloadSize;
  static const Field<Weapon, double> _f$reloadSize = Field(
    'reloadSize',
    _$reloadSize,
    key: r'reload size',
    opt: true,
  );
  static String? _$type(Weapon v) => v.type;
  static const Field<Weapon, String> _f$type = Field('type', _$type, opt: true);
  static double? _$energyPerShot(Weapon v) => v.energyPerShot;
  static const Field<Weapon, double> _f$energyPerShot = Field(
    'energyPerShot',
    _$energyPerShot,
    key: r'energy/shot',
    opt: true,
  );
  static double? _$energyPerSecond(Weapon v) => v.energyPerSecond;
  static const Field<Weapon, double> _f$energyPerSecond = Field(
    'energyPerSecond',
    _$energyPerSecond,
    key: r'energy/second',
    opt: true,
  );
  static double? _$chargeup(Weapon v) => v.chargeup;
  static const Field<Weapon, double> _f$chargeup = Field(
    'chargeup',
    _$chargeup,
    opt: true,
  );
  static double? _$chargedown(Weapon v) => v.chargedown;
  static const Field<Weapon, double> _f$chargedown = Field(
    'chargedown',
    _$chargedown,
    opt: true,
  );
  static int? _$burstSize(Weapon v) => v.burstSize;
  static const Field<Weapon, int> _f$burstSize = Field(
    'burstSize',
    _$burstSize,
    key: r'burst size',
    opt: true,
  );
  static double? _$burstDelay(Weapon v) => v.burstDelay;
  static const Field<Weapon, double> _f$burstDelay = Field(
    'burstDelay',
    _$burstDelay,
    key: r'burst delay',
    opt: true,
  );
  static double? _$minSpread(Weapon v) => v.minSpread;
  static const Field<Weapon, double> _f$minSpread = Field(
    'minSpread',
    _$minSpread,
    key: r'min spread',
    opt: true,
  );
  static double? _$maxSpread(Weapon v) => v.maxSpread;
  static const Field<Weapon, double> _f$maxSpread = Field(
    'maxSpread',
    _$maxSpread,
    key: r'max spread',
    opt: true,
  );
  static double? _$spreadPerShot(Weapon v) => v.spreadPerShot;
  static const Field<Weapon, double> _f$spreadPerShot = Field(
    'spreadPerShot',
    _$spreadPerShot,
    key: r'spread/shot',
    opt: true,
  );
  static double? _$spreadDecayPerSec(Weapon v) => v.spreadDecayPerSec;
  static const Field<Weapon, double> _f$spreadDecayPerSec = Field(
    'spreadDecayPerSec',
    _$spreadDecayPerSec,
    key: r'spread decay/sec',
    opt: true,
  );
  static double? _$beamSpeed(Weapon v) => v.beamSpeed;
  static const Field<Weapon, double> _f$beamSpeed = Field(
    'beamSpeed',
    _$beamSpeed,
    key: r'beam speed',
    opt: true,
  );
  static double? _$projSpeed(Weapon v) => v.projSpeed;
  static const Field<Weapon, double> _f$projSpeed = Field(
    'projSpeed',
    _$projSpeed,
    key: r'proj speed',
    opt: true,
  );
  static double? _$launchSpeed(Weapon v) => v.launchSpeed;
  static const Field<Weapon, double> _f$launchSpeed = Field(
    'launchSpeed',
    _$launchSpeed,
    key: r'launch speed',
    opt: true,
  );
  static double? _$flightTime(Weapon v) => v.flightTime;
  static const Field<Weapon, double> _f$flightTime = Field(
    'flightTime',
    _$flightTime,
    key: r'flight time',
    opt: true,
  );
  static double? _$projHitpoints(Weapon v) => v.projHitpoints;
  static const Field<Weapon, double> _f$projHitpoints = Field(
    'projHitpoints',
    _$projHitpoints,
    key: r'proj hitpoints',
    opt: true,
  );
  static double? _$autofireAccBonus(Weapon v) => v.autofireAccBonus;
  static const Field<Weapon, double> _f$autofireAccBonus = Field(
    'autofireAccBonus',
    _$autofireAccBonus,
    opt: true,
  );
  static String? _$extraArcForAI(Weapon v) => v.extraArcForAI;
  static const Field<Weapon, String> _f$extraArcForAI = Field(
    'extraArcForAI',
    _$extraArcForAI,
    opt: true,
  );
  static String? _$hints(Weapon v) => v.hints;
  static const Field<Weapon, String> _f$hints = Field(
    'hints',
    _$hints,
    opt: true,
  );
  static String? _$tags(Weapon v) => v.tags;
  static const Field<Weapon, String> _f$tags = Field('tags', _$tags, opt: true);
  static String? _$groupTag(Weapon v) => v.groupTag;
  static const Field<Weapon, String> _f$groupTag = Field(
    'groupTag',
    _$groupTag,
    opt: true,
  );
  static String? _$techManufacturer(Weapon v) => v.techManufacturer;
  static const Field<Weapon, String> _f$techManufacturer = Field(
    'techManufacturer',
    _$techManufacturer,
    key: r'tech/manufacturer',
    opt: true,
  );
  static String? _$forWeaponTooltip(Weapon v) => v.forWeaponTooltip;
  static const Field<Weapon, String> _f$forWeaponTooltip = Field(
    'forWeaponTooltip',
    _$forWeaponTooltip,
    key: r'for weapon tooltip>>',
    opt: true,
  );
  static String? _$primaryRoleStr(Weapon v) => v.primaryRoleStr;
  static const Field<Weapon, String> _f$primaryRoleStr = Field(
    'primaryRoleStr',
    _$primaryRoleStr,
    opt: true,
  );
  static String? _$speedStr(Weapon v) => v.speedStr;
  static const Field<Weapon, String> _f$speedStr = Field(
    'speedStr',
    _$speedStr,
    opt: true,
  );
  static String? _$trackingStr(Weapon v) => v.trackingStr;
  static const Field<Weapon, String> _f$trackingStr = Field(
    'trackingStr',
    _$trackingStr,
    opt: true,
  );
  static String? _$turnRateStr(Weapon v) => v.turnRateStr;
  static const Field<Weapon, String> _f$turnRateStr = Field(
    'turnRateStr',
    _$turnRateStr,
    opt: true,
  );
  static String? _$accuracyStr(Weapon v) => v.accuracyStr;
  static const Field<Weapon, String> _f$accuracyStr = Field(
    'accuracyStr',
    _$accuracyStr,
    opt: true,
  );
  static String? _$customPrimary(Weapon v) => v.customPrimary;
  static const Field<Weapon, String> _f$customPrimary = Field(
    'customPrimary',
    _$customPrimary,
    opt: true,
  );
  static String? _$customPrimaryHL(Weapon v) => v.customPrimaryHL;
  static const Field<Weapon, String> _f$customPrimaryHL = Field(
    'customPrimaryHL',
    _$customPrimaryHL,
    opt: true,
  );
  static String? _$customAncillary(Weapon v) => v.customAncillary;
  static const Field<Weapon, String> _f$customAncillary = Field(
    'customAncillary',
    _$customAncillary,
    opt: true,
  );
  static String? _$customAncillaryHL(Weapon v) => v.customAncillaryHL;
  static const Field<Weapon, String> _f$customAncillaryHL = Field(
    'customAncillaryHL',
    _$customAncillaryHL,
    opt: true,
  );
  static bool? _$noDPSInTooltip(Weapon v) => v.noDPSInTooltip;
  static const Field<Weapon, bool> _f$noDPSInTooltip = Field(
    'noDPSInTooltip',
    _$noDPSInTooltip,
    opt: true,
  );
  static double? _$number(Weapon v) => v.number;
  static const Field<Weapon, double> _f$number = Field(
    'number',
    _$number,
    opt: true,
  );
  static String? _$specClass(Weapon v) => v.specClass;
  static const Field<Weapon, String> _f$specClass = Field(
    'specClass',
    _$specClass,
    opt: true,
  );
  static String? _$weaponType(Weapon v) => v.weaponType;
  static const Field<Weapon, String> _f$weaponType = Field(
    'weaponType',
    _$weaponType,
    key: r'type',
    opt: true,
  );
  static String? _$size(Weapon v) => v.size;
  static const Field<Weapon, String> _f$size = Field('size', _$size, opt: true);
  static String? _$turretSprite(Weapon v) => v.turretSprite;
  static const Field<Weapon, String> _f$turretSprite = Field(
    'turretSprite',
    _$turretSprite,
    opt: true,
  );
  static String? _$turretGunSprite(Weapon v) => v.turretGunSprite;
  static const Field<Weapon, String> _f$turretGunSprite = Field(
    'turretGunSprite',
    _$turretGunSprite,
    opt: true,
  );
  static String? _$hardpointSprite(Weapon v) => v.hardpointSprite;
  static const Field<Weapon, String> _f$hardpointSprite = Field(
    'hardpointSprite',
    _$hardpointSprite,
    opt: true,
  );
  static String? _$hardpointGunSprite(Weapon v) => v.hardpointGunSprite;
  static const Field<Weapon, String> _f$hardpointGunSprite = Field(
    'hardpointGunSprite',
    _$hardpointGunSprite,
    opt: true,
  );
  static ModVariant? _$modVariant(Weapon v) => v.modVariant;
  static const Field<Weapon, ModVariant> _f$modVariant = Field(
    'modVariant',
    _$modVariant,
    mode: FieldMode.member,
  );
  static File _$csvFile(Weapon v) => v.csvFile;
  static const Field<Weapon, File> _f$csvFile = Field(
    'csvFile',
    _$csvFile,
    mode: FieldMode.member,
  );
  static File? _$wpnFile(Weapon v) => v.wpnFile;
  static const Field<Weapon, File> _f$wpnFile = Field(
    'wpnFile',
    _$wpnFile,
    mode: FieldMode.member,
  );
  static Set<String> _$hintsAsSet(Weapon v) => v.hintsAsSet;
  static const Field<Weapon, Set<String>> _f$hintsAsSet = Field(
    'hintsAsSet',
    _$hintsAsSet,
    mode: FieldMode.member,
  );
  static Set<String> _$tagsAsSet(Weapon v) => v.tagsAsSet;
  static const Field<Weapon, Set<String>> _f$tagsAsSet = Field(
    'tagsAsSet',
    _$tagsAsSet,
    mode: FieldMode.member,
  );

  @override
  final MappableFields<Weapon> fields = const {
    #name: _f$name,
    #id: _f$id,
    #tier: _f$tier,
    #rarity: _f$rarity,
    #baseValue: _f$baseValue,
    #range: _f$range,
    #damagePerSecond: _f$damagePerSecond,
    #damagePerShot: _f$damagePerShot,
    #emp: _f$emp,
    #impact: _f$impact,
    #turnRate: _f$turnRate,
    #ops: _f$ops,
    #ammo: _f$ammo,
    #ammoPerSec: _f$ammoPerSec,
    #reloadSize: _f$reloadSize,
    #type: _f$type,
    #energyPerShot: _f$energyPerShot,
    #energyPerSecond: _f$energyPerSecond,
    #chargeup: _f$chargeup,
    #chargedown: _f$chargedown,
    #burstSize: _f$burstSize,
    #burstDelay: _f$burstDelay,
    #minSpread: _f$minSpread,
    #maxSpread: _f$maxSpread,
    #spreadPerShot: _f$spreadPerShot,
    #spreadDecayPerSec: _f$spreadDecayPerSec,
    #beamSpeed: _f$beamSpeed,
    #projSpeed: _f$projSpeed,
    #launchSpeed: _f$launchSpeed,
    #flightTime: _f$flightTime,
    #projHitpoints: _f$projHitpoints,
    #autofireAccBonus: _f$autofireAccBonus,
    #extraArcForAI: _f$extraArcForAI,
    #hints: _f$hints,
    #tags: _f$tags,
    #groupTag: _f$groupTag,
    #techManufacturer: _f$techManufacturer,
    #forWeaponTooltip: _f$forWeaponTooltip,
    #primaryRoleStr: _f$primaryRoleStr,
    #speedStr: _f$speedStr,
    #trackingStr: _f$trackingStr,
    #turnRateStr: _f$turnRateStr,
    #accuracyStr: _f$accuracyStr,
    #customPrimary: _f$customPrimary,
    #customPrimaryHL: _f$customPrimaryHL,
    #customAncillary: _f$customAncillary,
    #customAncillaryHL: _f$customAncillaryHL,
    #noDPSInTooltip: _f$noDPSInTooltip,
    #number: _f$number,
    #specClass: _f$specClass,
    #weaponType: _f$weaponType,
    #size: _f$size,
    #turretSprite: _f$turretSprite,
    #turretGunSprite: _f$turretGunSprite,
    #hardpointSprite: _f$hardpointSprite,
    #hardpointGunSprite: _f$hardpointGunSprite,
    #modVariant: _f$modVariant,
    #csvFile: _f$csvFile,
    #wpnFile: _f$wpnFile,
    #hintsAsSet: _f$hintsAsSet,
    #tagsAsSet: _f$tagsAsSet,
  };

  static Weapon _instantiate(DecodingData data) {
    return Weapon(
      name: data.dec(_f$name),
      id: data.dec(_f$id),
      tier: data.dec(_f$tier),
      rarity: data.dec(_f$rarity),
      baseValue: data.dec(_f$baseValue),
      range: data.dec(_f$range),
      damagePerSecond: data.dec(_f$damagePerSecond),
      damagePerShot: data.dec(_f$damagePerShot),
      emp: data.dec(_f$emp),
      impact: data.dec(_f$impact),
      turnRate: data.dec(_f$turnRate),
      ops: data.dec(_f$ops),
      ammo: data.dec(_f$ammo),
      ammoPerSec: data.dec(_f$ammoPerSec),
      reloadSize: data.dec(_f$reloadSize),
      type: data.dec(_f$type),
      energyPerShot: data.dec(_f$energyPerShot),
      energyPerSecond: data.dec(_f$energyPerSecond),
      chargeup: data.dec(_f$chargeup),
      chargedown: data.dec(_f$chargedown),
      burstSize: data.dec(_f$burstSize),
      burstDelay: data.dec(_f$burstDelay),
      minSpread: data.dec(_f$minSpread),
      maxSpread: data.dec(_f$maxSpread),
      spreadPerShot: data.dec(_f$spreadPerShot),
      spreadDecayPerSec: data.dec(_f$spreadDecayPerSec),
      beamSpeed: data.dec(_f$beamSpeed),
      projSpeed: data.dec(_f$projSpeed),
      launchSpeed: data.dec(_f$launchSpeed),
      flightTime: data.dec(_f$flightTime),
      projHitpoints: data.dec(_f$projHitpoints),
      autofireAccBonus: data.dec(_f$autofireAccBonus),
      extraArcForAI: data.dec(_f$extraArcForAI),
      hints: data.dec(_f$hints),
      tags: data.dec(_f$tags),
      groupTag: data.dec(_f$groupTag),
      techManufacturer: data.dec(_f$techManufacturer),
      forWeaponTooltip: data.dec(_f$forWeaponTooltip),
      primaryRoleStr: data.dec(_f$primaryRoleStr),
      speedStr: data.dec(_f$speedStr),
      trackingStr: data.dec(_f$trackingStr),
      turnRateStr: data.dec(_f$turnRateStr),
      accuracyStr: data.dec(_f$accuracyStr),
      customPrimary: data.dec(_f$customPrimary),
      customPrimaryHL: data.dec(_f$customPrimaryHL),
      customAncillary: data.dec(_f$customAncillary),
      customAncillaryHL: data.dec(_f$customAncillaryHL),
      noDPSInTooltip: data.dec(_f$noDPSInTooltip),
      number: data.dec(_f$number),
      specClass: data.dec(_f$specClass),
      weaponType: data.dec(_f$weaponType),
      size: data.dec(_f$size),
      turretSprite: data.dec(_f$turretSprite),
      turretGunSprite: data.dec(_f$turretGunSprite),
      hardpointSprite: data.dec(_f$hardpointSprite),
      hardpointGunSprite: data.dec(_f$hardpointGunSprite),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static Weapon fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<Weapon>(map);
  }

  static Weapon fromJson(String json) {
    return ensureInitialized().decodeJson<Weapon>(json);
  }
}

mixin WeaponMappable {
  String toJson() {
    return WeaponMapper.ensureInitialized().encodeJson<Weapon>(this as Weapon);
  }

  Map<String, dynamic> toMap() {
    return WeaponMapper.ensureInitialized().encodeMap<Weapon>(this as Weapon);
  }

  WeaponCopyWith<Weapon, Weapon, Weapon> get copyWith =>
      _WeaponCopyWithImpl<Weapon, Weapon>(this as Weapon, $identity, $identity);
  @override
  String toString() {
    return WeaponMapper.ensureInitialized().stringifyValue(this as Weapon);
  }

  @override
  bool operator ==(Object other) {
    return WeaponMapper.ensureInitialized().equalsValue(this as Weapon, other);
  }

  @override
  int get hashCode {
    return WeaponMapper.ensureInitialized().hashValue(this as Weapon);
  }
}

extension WeaponValueCopy<$R, $Out> on ObjectCopyWith<$R, Weapon, $Out> {
  WeaponCopyWith<$R, Weapon, $Out> get $asWeapon =>
      $base.as((v, t, t2) => _WeaponCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class WeaponCopyWith<$R, $In extends Weapon, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({
    String? name,
    String? id,
    int? tier,
    double? rarity,
    double? baseValue,
    double? range,
    double? damagePerSecond,
    double? damagePerShot,
    double? emp,
    double? impact,
    double? turnRate,
    int? ops,
    double? ammo,
    double? ammoPerSec,
    double? reloadSize,
    String? type,
    double? energyPerShot,
    double? energyPerSecond,
    double? chargeup,
    double? chargedown,
    int? burstSize,
    double? burstDelay,
    double? minSpread,
    double? maxSpread,
    double? spreadPerShot,
    double? spreadDecayPerSec,
    double? beamSpeed,
    double? projSpeed,
    double? launchSpeed,
    double? flightTime,
    double? projHitpoints,
    double? autofireAccBonus,
    String? extraArcForAI,
    String? hints,
    String? tags,
    String? groupTag,
    String? techManufacturer,
    String? forWeaponTooltip,
    String? primaryRoleStr,
    String? speedStr,
    String? trackingStr,
    String? turnRateStr,
    String? accuracyStr,
    String? customPrimary,
    String? customPrimaryHL,
    String? customAncillary,
    String? customAncillaryHL,
    bool? noDPSInTooltip,
    double? number,
    String? specClass,
    String? weaponType,
    String? size,
    String? turretSprite,
    String? turretGunSprite,
    String? hardpointSprite,
    String? hardpointGunSprite,
  });
  WeaponCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _WeaponCopyWithImpl<$R, $Out> extends ClassCopyWithBase<$R, Weapon, $Out>
    implements WeaponCopyWith<$R, Weapon, $Out> {
  _WeaponCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<Weapon> $mapper = WeaponMapper.ensureInitialized();
  @override
  $R call({
    Object? name = $none,
    String? id,
    Object? tier = $none,
    Object? rarity = $none,
    Object? baseValue = $none,
    Object? range = $none,
    Object? damagePerSecond = $none,
    Object? damagePerShot = $none,
    Object? emp = $none,
    Object? impact = $none,
    Object? turnRate = $none,
    Object? ops = $none,
    Object? ammo = $none,
    Object? ammoPerSec = $none,
    Object? reloadSize = $none,
    Object? type = $none,
    Object? energyPerShot = $none,
    Object? energyPerSecond = $none,
    Object? chargeup = $none,
    Object? chargedown = $none,
    Object? burstSize = $none,
    Object? burstDelay = $none,
    Object? minSpread = $none,
    Object? maxSpread = $none,
    Object? spreadPerShot = $none,
    Object? spreadDecayPerSec = $none,
    Object? beamSpeed = $none,
    Object? projSpeed = $none,
    Object? launchSpeed = $none,
    Object? flightTime = $none,
    Object? projHitpoints = $none,
    Object? autofireAccBonus = $none,
    Object? extraArcForAI = $none,
    Object? hints = $none,
    Object? tags = $none,
    Object? groupTag = $none,
    Object? techManufacturer = $none,
    Object? forWeaponTooltip = $none,
    Object? primaryRoleStr = $none,
    Object? speedStr = $none,
    Object? trackingStr = $none,
    Object? turnRateStr = $none,
    Object? accuracyStr = $none,
    Object? customPrimary = $none,
    Object? customPrimaryHL = $none,
    Object? customAncillary = $none,
    Object? customAncillaryHL = $none,
    Object? noDPSInTooltip = $none,
    Object? number = $none,
    Object? specClass = $none,
    Object? weaponType = $none,
    Object? size = $none,
    Object? turretSprite = $none,
    Object? turretGunSprite = $none,
    Object? hardpointSprite = $none,
    Object? hardpointGunSprite = $none,
  }) => $apply(
    FieldCopyWithData({
      if (name != $none) #name: name,
      if (id != null) #id: id,
      if (tier != $none) #tier: tier,
      if (rarity != $none) #rarity: rarity,
      if (baseValue != $none) #baseValue: baseValue,
      if (range != $none) #range: range,
      if (damagePerSecond != $none) #damagePerSecond: damagePerSecond,
      if (damagePerShot != $none) #damagePerShot: damagePerShot,
      if (emp != $none) #emp: emp,
      if (impact != $none) #impact: impact,
      if (turnRate != $none) #turnRate: turnRate,
      if (ops != $none) #ops: ops,
      if (ammo != $none) #ammo: ammo,
      if (ammoPerSec != $none) #ammoPerSec: ammoPerSec,
      if (reloadSize != $none) #reloadSize: reloadSize,
      if (type != $none) #type: type,
      if (energyPerShot != $none) #energyPerShot: energyPerShot,
      if (energyPerSecond != $none) #energyPerSecond: energyPerSecond,
      if (chargeup != $none) #chargeup: chargeup,
      if (chargedown != $none) #chargedown: chargedown,
      if (burstSize != $none) #burstSize: burstSize,
      if (burstDelay != $none) #burstDelay: burstDelay,
      if (minSpread != $none) #minSpread: minSpread,
      if (maxSpread != $none) #maxSpread: maxSpread,
      if (spreadPerShot != $none) #spreadPerShot: spreadPerShot,
      if (spreadDecayPerSec != $none) #spreadDecayPerSec: spreadDecayPerSec,
      if (beamSpeed != $none) #beamSpeed: beamSpeed,
      if (projSpeed != $none) #projSpeed: projSpeed,
      if (launchSpeed != $none) #launchSpeed: launchSpeed,
      if (flightTime != $none) #flightTime: flightTime,
      if (projHitpoints != $none) #projHitpoints: projHitpoints,
      if (autofireAccBonus != $none) #autofireAccBonus: autofireAccBonus,
      if (extraArcForAI != $none) #extraArcForAI: extraArcForAI,
      if (hints != $none) #hints: hints,
      if (tags != $none) #tags: tags,
      if (groupTag != $none) #groupTag: groupTag,
      if (techManufacturer != $none) #techManufacturer: techManufacturer,
      if (forWeaponTooltip != $none) #forWeaponTooltip: forWeaponTooltip,
      if (primaryRoleStr != $none) #primaryRoleStr: primaryRoleStr,
      if (speedStr != $none) #speedStr: speedStr,
      if (trackingStr != $none) #trackingStr: trackingStr,
      if (turnRateStr != $none) #turnRateStr: turnRateStr,
      if (accuracyStr != $none) #accuracyStr: accuracyStr,
      if (customPrimary != $none) #customPrimary: customPrimary,
      if (customPrimaryHL != $none) #customPrimaryHL: customPrimaryHL,
      if (customAncillary != $none) #customAncillary: customAncillary,
      if (customAncillaryHL != $none) #customAncillaryHL: customAncillaryHL,
      if (noDPSInTooltip != $none) #noDPSInTooltip: noDPSInTooltip,
      if (number != $none) #number: number,
      if (specClass != $none) #specClass: specClass,
      if (weaponType != $none) #weaponType: weaponType,
      if (size != $none) #size: size,
      if (turretSprite != $none) #turretSprite: turretSprite,
      if (turretGunSprite != $none) #turretGunSprite: turretGunSprite,
      if (hardpointSprite != $none) #hardpointSprite: hardpointSprite,
      if (hardpointGunSprite != $none) #hardpointGunSprite: hardpointGunSprite,
    }),
  );
  @override
  Weapon $make(CopyWithData data) => Weapon(
    name: data.get(#name, or: $value.name),
    id: data.get(#id, or: $value.id),
    tier: data.get(#tier, or: $value.tier),
    rarity: data.get(#rarity, or: $value.rarity),
    baseValue: data.get(#baseValue, or: $value.baseValue),
    range: data.get(#range, or: $value.range),
    damagePerSecond: data.get(#damagePerSecond, or: $value.damagePerSecond),
    damagePerShot: data.get(#damagePerShot, or: $value.damagePerShot),
    emp: data.get(#emp, or: $value.emp),
    impact: data.get(#impact, or: $value.impact),
    turnRate: data.get(#turnRate, or: $value.turnRate),
    ops: data.get(#ops, or: $value.ops),
    ammo: data.get(#ammo, or: $value.ammo),
    ammoPerSec: data.get(#ammoPerSec, or: $value.ammoPerSec),
    reloadSize: data.get(#reloadSize, or: $value.reloadSize),
    type: data.get(#type, or: $value.type),
    energyPerShot: data.get(#energyPerShot, or: $value.energyPerShot),
    energyPerSecond: data.get(#energyPerSecond, or: $value.energyPerSecond),
    chargeup: data.get(#chargeup, or: $value.chargeup),
    chargedown: data.get(#chargedown, or: $value.chargedown),
    burstSize: data.get(#burstSize, or: $value.burstSize),
    burstDelay: data.get(#burstDelay, or: $value.burstDelay),
    minSpread: data.get(#minSpread, or: $value.minSpread),
    maxSpread: data.get(#maxSpread, or: $value.maxSpread),
    spreadPerShot: data.get(#spreadPerShot, or: $value.spreadPerShot),
    spreadDecayPerSec: data.get(
      #spreadDecayPerSec,
      or: $value.spreadDecayPerSec,
    ),
    beamSpeed: data.get(#beamSpeed, or: $value.beamSpeed),
    projSpeed: data.get(#projSpeed, or: $value.projSpeed),
    launchSpeed: data.get(#launchSpeed, or: $value.launchSpeed),
    flightTime: data.get(#flightTime, or: $value.flightTime),
    projHitpoints: data.get(#projHitpoints, or: $value.projHitpoints),
    autofireAccBonus: data.get(#autofireAccBonus, or: $value.autofireAccBonus),
    extraArcForAI: data.get(#extraArcForAI, or: $value.extraArcForAI),
    hints: data.get(#hints, or: $value.hints),
    tags: data.get(#tags, or: $value.tags),
    groupTag: data.get(#groupTag, or: $value.groupTag),
    techManufacturer: data.get(#techManufacturer, or: $value.techManufacturer),
    forWeaponTooltip: data.get(#forWeaponTooltip, or: $value.forWeaponTooltip),
    primaryRoleStr: data.get(#primaryRoleStr, or: $value.primaryRoleStr),
    speedStr: data.get(#speedStr, or: $value.speedStr),
    trackingStr: data.get(#trackingStr, or: $value.trackingStr),
    turnRateStr: data.get(#turnRateStr, or: $value.turnRateStr),
    accuracyStr: data.get(#accuracyStr, or: $value.accuracyStr),
    customPrimary: data.get(#customPrimary, or: $value.customPrimary),
    customPrimaryHL: data.get(#customPrimaryHL, or: $value.customPrimaryHL),
    customAncillary: data.get(#customAncillary, or: $value.customAncillary),
    customAncillaryHL: data.get(
      #customAncillaryHL,
      or: $value.customAncillaryHL,
    ),
    noDPSInTooltip: data.get(#noDPSInTooltip, or: $value.noDPSInTooltip),
    number: data.get(#number, or: $value.number),
    specClass: data.get(#specClass, or: $value.specClass),
    weaponType: data.get(#weaponType, or: $value.weaponType),
    size: data.get(#size, or: $value.size),
    turretSprite: data.get(#turretSprite, or: $value.turretSprite),
    turretGunSprite: data.get(#turretGunSprite, or: $value.turretGunSprite),
    hardpointSprite: data.get(#hardpointSprite, or: $value.hardpointSprite),
    hardpointGunSprite: data.get(
      #hardpointGunSprite,
      or: $value.hardpointGunSprite,
    ),
  );

  @override
  WeaponCopyWith<$R2, Weapon, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _WeaponCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

