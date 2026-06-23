// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'sector.dart';

class SectorMapper extends ClassMapperBase<Sector> {
  SectorMapper._();

  static SectorMapper? _instance;
  static SectorMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = SectorMapper._());
      SectorSystemMapper.ensureInitialized();
      SectorConstellationMapper.ensureInitialized();
      SectorLandmarkMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'Sector';

  static List<SectorSystem> _$systems(Sector v) => v.systems;
  static const Field<Sector, List<SectorSystem>> _f$systems = Field(
    'systems',
    _$systems,
    opt: true,
    def: const [],
  );
  static List<SectorConstellation> _$constellations(Sector v) =>
      v.constellations;
  static const Field<Sector, List<SectorConstellation>> _f$constellations =
      Field('constellations', _$constellations, opt: true, def: const []);
  static List<SectorLandmark> _$landmarks(Sector v) => v.landmarks;
  static const Field<Sector, List<SectorLandmark>> _f$landmarks = Field(
    'landmarks',
    _$landmarks,
    opt: true,
    def: const [],
  );
  static double? _$playerX(Sector v) => v.playerX;
  static const Field<Sector, double> _f$playerX = Field(
    'playerX',
    _$playerX,
    opt: true,
  );
  static double? _$playerY(Sector v) => v.playerY;
  static const Field<Sector, double> _f$playerY = Field(
    'playerY',
    _$playerY,
    opt: true,
  );
  static String _$gameVersion(Sector v) => v.gameVersion;
  static const Field<Sector, String> _f$gameVersion = Field(
    'gameVersion',
    _$gameVersion,
    opt: true,
    def: '',
  );

  @override
  final MappableFields<Sector> fields = const {
    #systems: _f$systems,
    #constellations: _f$constellations,
    #landmarks: _f$landmarks,
    #playerX: _f$playerX,
    #playerY: _f$playerY,
    #gameVersion: _f$gameVersion,
  };

  static Sector _instantiate(DecodingData data) {
    return Sector(
      systems: data.dec(_f$systems),
      constellations: data.dec(_f$constellations),
      landmarks: data.dec(_f$landmarks),
      playerX: data.dec(_f$playerX),
      playerY: data.dec(_f$playerY),
      gameVersion: data.dec(_f$gameVersion),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static Sector fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<Sector>(map);
  }

  static Sector fromJson(String json) {
    return ensureInitialized().decodeJson<Sector>(json);
  }
}

mixin SectorMappable {
  String toJson() {
    return SectorMapper.ensureInitialized().encodeJson<Sector>(this as Sector);
  }

  Map<String, dynamic> toMap() {
    return SectorMapper.ensureInitialized().encodeMap<Sector>(this as Sector);
  }

  SectorCopyWith<Sector, Sector, Sector> get copyWith =>
      _SectorCopyWithImpl<Sector, Sector>(this as Sector, $identity, $identity);
  @override
  String toString() {
    return SectorMapper.ensureInitialized().stringifyValue(this as Sector);
  }

  @override
  bool operator ==(Object other) {
    return SectorMapper.ensureInitialized().equalsValue(this as Sector, other);
  }

  @override
  int get hashCode {
    return SectorMapper.ensureInitialized().hashValue(this as Sector);
  }
}

extension SectorValueCopy<$R, $Out> on ObjectCopyWith<$R, Sector, $Out> {
  SectorCopyWith<$R, Sector, $Out> get $asSector =>
      $base.as((v, t, t2) => _SectorCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class SectorCopyWith<$R, $In extends Sector, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  ListCopyWith<
    $R,
    SectorSystem,
    SectorSystemCopyWith<$R, SectorSystem, SectorSystem>
  >
  get systems;
  ListCopyWith<
    $R,
    SectorConstellation,
    SectorConstellationCopyWith<$R, SectorConstellation, SectorConstellation>
  >
  get constellations;
  ListCopyWith<
    $R,
    SectorLandmark,
    SectorLandmarkCopyWith<$R, SectorLandmark, SectorLandmark>
  >
  get landmarks;
  $R call({
    List<SectorSystem>? systems,
    List<SectorConstellation>? constellations,
    List<SectorLandmark>? landmarks,
    double? playerX,
    double? playerY,
    String? gameVersion,
  });
  SectorCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _SectorCopyWithImpl<$R, $Out> extends ClassCopyWithBase<$R, Sector, $Out>
    implements SectorCopyWith<$R, Sector, $Out> {
  _SectorCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<Sector> $mapper = SectorMapper.ensureInitialized();
  @override
  ListCopyWith<
    $R,
    SectorSystem,
    SectorSystemCopyWith<$R, SectorSystem, SectorSystem>
  >
  get systems => ListCopyWith(
    $value.systems,
    (v, t) => v.copyWith.$chain(t),
    (v) => call(systems: v),
  );
  @override
  ListCopyWith<
    $R,
    SectorConstellation,
    SectorConstellationCopyWith<$R, SectorConstellation, SectorConstellation>
  >
  get constellations => ListCopyWith(
    $value.constellations,
    (v, t) => v.copyWith.$chain(t),
    (v) => call(constellations: v),
  );
  @override
  ListCopyWith<
    $R,
    SectorLandmark,
    SectorLandmarkCopyWith<$R, SectorLandmark, SectorLandmark>
  >
  get landmarks => ListCopyWith(
    $value.landmarks,
    (v, t) => v.copyWith.$chain(t),
    (v) => call(landmarks: v),
  );
  @override
  $R call({
    List<SectorSystem>? systems,
    List<SectorConstellation>? constellations,
    List<SectorLandmark>? landmarks,
    Object? playerX = $none,
    Object? playerY = $none,
    String? gameVersion,
  }) => $apply(
    FieldCopyWithData({
      if (systems != null) #systems: systems,
      if (constellations != null) #constellations: constellations,
      if (landmarks != null) #landmarks: landmarks,
      if (playerX != $none) #playerX: playerX,
      if (playerY != $none) #playerY: playerY,
      if (gameVersion != null) #gameVersion: gameVersion,
    }),
  );
  @override
  Sector $make(CopyWithData data) => Sector(
    systems: data.get(#systems, or: $value.systems),
    constellations: data.get(#constellations, or: $value.constellations),
    landmarks: data.get(#landmarks, or: $value.landmarks),
    playerX: data.get(#playerX, or: $value.playerX),
    playerY: data.get(#playerY, or: $value.playerY),
    gameVersion: data.get(#gameVersion, or: $value.gameVersion),
  );

  @override
  SectorCopyWith<$R2, Sector, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _SectorCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class SectorSystemMapper extends ClassMapperBase<SectorSystem> {
  SectorSystemMapper._();

  static SectorSystemMapper? _instance;
  static SectorSystemMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = SectorSystemMapper._());
      SectorMarketMapper.ensureInitialized();
      SectorPlanetMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'SectorSystem';

  static String _$id(SectorSystem v) => v.id;
  static const Field<SectorSystem, String> _f$id = Field('id', _$id);
  static String _$name(SectorSystem v) => v.name;
  static const Field<SectorSystem, String> _f$name = Field('name', _$name);
  static String _$baseName(SectorSystem v) => v.baseName;
  static const Field<SectorSystem, String> _f$baseName = Field(
    'baseName',
    _$baseName,
  );
  static String _$type(SectorSystem v) => v.type;
  static const Field<SectorSystem, String> _f$type = Field('type', _$type);
  static String? _$constellationId(SectorSystem v) => v.constellationId;
  static const Field<SectorSystem, String> _f$constellationId = Field(
    'constellationId',
    _$constellationId,
    opt: true,
  );
  static double _$x(SectorSystem v) => v.x;
  static const Field<SectorSystem, double> _f$x = Field('x', _$x);
  static double _$y(SectorSystem v) => v.y;
  static const Field<SectorSystem, double> _f$y = Field('y', _$y);
  static List<int>? _$starColor(SectorSystem v) => v.starColor;
  static const Field<SectorSystem, List<int>> _f$starColor = Field(
    'starColor',
    _$starColor,
    opt: true,
  );
  static List<SectorMarket> _$markets(SectorSystem v) => v.markets;
  static const Field<SectorSystem, List<SectorMarket>> _f$markets = Field(
    'markets',
    _$markets,
    opt: true,
    def: const [],
  );
  static List<SectorPlanet> _$planets(SectorSystem v) => v.planets;
  static const Field<SectorSystem, List<SectorPlanet>> _f$planets = Field(
    'planets',
    _$planets,
    opt: true,
    def: const [],
  );
  static int _$stableLocationCount(SectorSystem v) => v.stableLocationCount;
  static const Field<SectorSystem, int> _f$stableLocationCount = Field(
    'stableLocationCount',
    _$stableLocationCount,
    opt: true,
    def: 0,
  );

  @override
  final MappableFields<SectorSystem> fields = const {
    #id: _f$id,
    #name: _f$name,
    #baseName: _f$baseName,
    #type: _f$type,
    #constellationId: _f$constellationId,
    #x: _f$x,
    #y: _f$y,
    #starColor: _f$starColor,
    #markets: _f$markets,
    #planets: _f$planets,
    #stableLocationCount: _f$stableLocationCount,
  };

  static SectorSystem _instantiate(DecodingData data) {
    return SectorSystem(
      id: data.dec(_f$id),
      name: data.dec(_f$name),
      baseName: data.dec(_f$baseName),
      type: data.dec(_f$type),
      constellationId: data.dec(_f$constellationId),
      x: data.dec(_f$x),
      y: data.dec(_f$y),
      starColor: data.dec(_f$starColor),
      markets: data.dec(_f$markets),
      planets: data.dec(_f$planets),
      stableLocationCount: data.dec(_f$stableLocationCount),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static SectorSystem fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<SectorSystem>(map);
  }

  static SectorSystem fromJson(String json) {
    return ensureInitialized().decodeJson<SectorSystem>(json);
  }
}

mixin SectorSystemMappable {
  String toJson() {
    return SectorSystemMapper.ensureInitialized().encodeJson<SectorSystem>(
      this as SectorSystem,
    );
  }

  Map<String, dynamic> toMap() {
    return SectorSystemMapper.ensureInitialized().encodeMap<SectorSystem>(
      this as SectorSystem,
    );
  }

  SectorSystemCopyWith<SectorSystem, SectorSystem, SectorSystem> get copyWith =>
      _SectorSystemCopyWithImpl<SectorSystem, SectorSystem>(
        this as SectorSystem,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return SectorSystemMapper.ensureInitialized().stringifyValue(
      this as SectorSystem,
    );
  }

  @override
  bool operator ==(Object other) {
    return SectorSystemMapper.ensureInitialized().equalsValue(
      this as SectorSystem,
      other,
    );
  }

  @override
  int get hashCode {
    return SectorSystemMapper.ensureInitialized().hashValue(
      this as SectorSystem,
    );
  }
}

extension SectorSystemValueCopy<$R, $Out>
    on ObjectCopyWith<$R, SectorSystem, $Out> {
  SectorSystemCopyWith<$R, SectorSystem, $Out> get $asSectorSystem =>
      $base.as((v, t, t2) => _SectorSystemCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class SectorSystemCopyWith<$R, $In extends SectorSystem, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  ListCopyWith<$R, int, ObjectCopyWith<$R, int, int>>? get starColor;
  ListCopyWith<
    $R,
    SectorMarket,
    SectorMarketCopyWith<$R, SectorMarket, SectorMarket>
  >
  get markets;
  ListCopyWith<
    $R,
    SectorPlanet,
    SectorPlanetCopyWith<$R, SectorPlanet, SectorPlanet>
  >
  get planets;
  $R call({
    String? id,
    String? name,
    String? baseName,
    String? type,
    String? constellationId,
    double? x,
    double? y,
    List<int>? starColor,
    List<SectorMarket>? markets,
    List<SectorPlanet>? planets,
    int? stableLocationCount,
  });
  SectorSystemCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _SectorSystemCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, SectorSystem, $Out>
    implements SectorSystemCopyWith<$R, SectorSystem, $Out> {
  _SectorSystemCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<SectorSystem> $mapper =
      SectorSystemMapper.ensureInitialized();
  @override
  ListCopyWith<$R, int, ObjectCopyWith<$R, int, int>>? get starColor =>
      $value.starColor != null
      ? ListCopyWith(
          $value.starColor!,
          (v, t) => ObjectCopyWith(v, $identity, t),
          (v) => call(starColor: v),
        )
      : null;
  @override
  ListCopyWith<
    $R,
    SectorMarket,
    SectorMarketCopyWith<$R, SectorMarket, SectorMarket>
  >
  get markets => ListCopyWith(
    $value.markets,
    (v, t) => v.copyWith.$chain(t),
    (v) => call(markets: v),
  );
  @override
  ListCopyWith<
    $R,
    SectorPlanet,
    SectorPlanetCopyWith<$R, SectorPlanet, SectorPlanet>
  >
  get planets => ListCopyWith(
    $value.planets,
    (v, t) => v.copyWith.$chain(t),
    (v) => call(planets: v),
  );
  @override
  $R call({
    String? id,
    String? name,
    String? baseName,
    String? type,
    Object? constellationId = $none,
    double? x,
    double? y,
    Object? starColor = $none,
    List<SectorMarket>? markets,
    List<SectorPlanet>? planets,
    int? stableLocationCount,
  }) => $apply(
    FieldCopyWithData({
      if (id != null) #id: id,
      if (name != null) #name: name,
      if (baseName != null) #baseName: baseName,
      if (type != null) #type: type,
      if (constellationId != $none) #constellationId: constellationId,
      if (x != null) #x: x,
      if (y != null) #y: y,
      if (starColor != $none) #starColor: starColor,
      if (markets != null) #markets: markets,
      if (planets != null) #planets: planets,
      if (stableLocationCount != null)
        #stableLocationCount: stableLocationCount,
    }),
  );
  @override
  SectorSystem $make(CopyWithData data) => SectorSystem(
    id: data.get(#id, or: $value.id),
    name: data.get(#name, or: $value.name),
    baseName: data.get(#baseName, or: $value.baseName),
    type: data.get(#type, or: $value.type),
    constellationId: data.get(#constellationId, or: $value.constellationId),
    x: data.get(#x, or: $value.x),
    y: data.get(#y, or: $value.y),
    starColor: data.get(#starColor, or: $value.starColor),
    markets: data.get(#markets, or: $value.markets),
    planets: data.get(#planets, or: $value.planets),
    stableLocationCount: data.get(
      #stableLocationCount,
      or: $value.stableLocationCount,
    ),
  );

  @override
  SectorSystemCopyWith<$R2, SectorSystem, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _SectorSystemCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class SectorMarketMapper extends ClassMapperBase<SectorMarket> {
  SectorMarketMapper._();

  static SectorMarketMapper? _instance;
  static SectorMarketMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = SectorMarketMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'SectorMarket';

  static String _$factionId(SectorMarket v) => v.factionId;
  static const Field<SectorMarket, String> _f$factionId = Field(
    'factionId',
    _$factionId,
  );
  static int _$size(SectorMarket v) => v.size;
  static const Field<SectorMarket, int> _f$size = Field('size', _$size);
  static String _$name(SectorMarket v) => v.name;
  static const Field<SectorMarket, String> _f$name = Field('name', _$name);

  @override
  final MappableFields<SectorMarket> fields = const {
    #factionId: _f$factionId,
    #size: _f$size,
    #name: _f$name,
  };

  static SectorMarket _instantiate(DecodingData data) {
    return SectorMarket(
      factionId: data.dec(_f$factionId),
      size: data.dec(_f$size),
      name: data.dec(_f$name),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static SectorMarket fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<SectorMarket>(map);
  }

  static SectorMarket fromJson(String json) {
    return ensureInitialized().decodeJson<SectorMarket>(json);
  }
}

mixin SectorMarketMappable {
  String toJson() {
    return SectorMarketMapper.ensureInitialized().encodeJson<SectorMarket>(
      this as SectorMarket,
    );
  }

  Map<String, dynamic> toMap() {
    return SectorMarketMapper.ensureInitialized().encodeMap<SectorMarket>(
      this as SectorMarket,
    );
  }

  SectorMarketCopyWith<SectorMarket, SectorMarket, SectorMarket> get copyWith =>
      _SectorMarketCopyWithImpl<SectorMarket, SectorMarket>(
        this as SectorMarket,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return SectorMarketMapper.ensureInitialized().stringifyValue(
      this as SectorMarket,
    );
  }

  @override
  bool operator ==(Object other) {
    return SectorMarketMapper.ensureInitialized().equalsValue(
      this as SectorMarket,
      other,
    );
  }

  @override
  int get hashCode {
    return SectorMarketMapper.ensureInitialized().hashValue(
      this as SectorMarket,
    );
  }
}

extension SectorMarketValueCopy<$R, $Out>
    on ObjectCopyWith<$R, SectorMarket, $Out> {
  SectorMarketCopyWith<$R, SectorMarket, $Out> get $asSectorMarket =>
      $base.as((v, t, t2) => _SectorMarketCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class SectorMarketCopyWith<$R, $In extends SectorMarket, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({String? factionId, int? size, String? name});
  SectorMarketCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _SectorMarketCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, SectorMarket, $Out>
    implements SectorMarketCopyWith<$R, SectorMarket, $Out> {
  _SectorMarketCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<SectorMarket> $mapper =
      SectorMarketMapper.ensureInitialized();
  @override
  $R call({String? factionId, int? size, String? name}) => $apply(
    FieldCopyWithData({
      if (factionId != null) #factionId: factionId,
      if (size != null) #size: size,
      if (name != null) #name: name,
    }),
  );
  @override
  SectorMarket $make(CopyWithData data) => SectorMarket(
    factionId: data.get(#factionId, or: $value.factionId),
    size: data.get(#size, or: $value.size),
    name: data.get(#name, or: $value.name),
  );

  @override
  SectorMarketCopyWith<$R2, SectorMarket, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _SectorMarketCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class SectorPlanetMapper extends ClassMapperBase<SectorPlanet> {
  SectorPlanetMapper._();

  static SectorPlanetMapper? _instance;
  static SectorPlanetMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = SectorPlanetMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'SectorPlanet';

  static String _$name(SectorPlanet v) => v.name;
  static const Field<SectorPlanet, String> _f$name = Field(
    'name',
    _$name,
    opt: true,
    def: '',
  );
  static String _$type(SectorPlanet v) => v.type;
  static const Field<SectorPlanet, String> _f$type = Field('type', _$type);
  static List<String> _$conditionIds(SectorPlanet v) => v.conditionIds;
  static const Field<SectorPlanet, List<String>> _f$conditionIds = Field(
    'conditionIds',
    _$conditionIds,
    opt: true,
    def: const [],
  );
  static double _$hazardRating(SectorPlanet v) => v.hazardRating;
  static const Field<SectorPlanet, double> _f$hazardRating = Field(
    'hazardRating',
    _$hazardRating,
    opt: true,
    def: 1.0,
  );

  @override
  final MappableFields<SectorPlanet> fields = const {
    #name: _f$name,
    #type: _f$type,
    #conditionIds: _f$conditionIds,
    #hazardRating: _f$hazardRating,
  };

  static SectorPlanet _instantiate(DecodingData data) {
    return SectorPlanet(
      name: data.dec(_f$name),
      type: data.dec(_f$type),
      conditionIds: data.dec(_f$conditionIds),
      hazardRating: data.dec(_f$hazardRating),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static SectorPlanet fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<SectorPlanet>(map);
  }

  static SectorPlanet fromJson(String json) {
    return ensureInitialized().decodeJson<SectorPlanet>(json);
  }
}

mixin SectorPlanetMappable {
  String toJson() {
    return SectorPlanetMapper.ensureInitialized().encodeJson<SectorPlanet>(
      this as SectorPlanet,
    );
  }

  Map<String, dynamic> toMap() {
    return SectorPlanetMapper.ensureInitialized().encodeMap<SectorPlanet>(
      this as SectorPlanet,
    );
  }

  SectorPlanetCopyWith<SectorPlanet, SectorPlanet, SectorPlanet> get copyWith =>
      _SectorPlanetCopyWithImpl<SectorPlanet, SectorPlanet>(
        this as SectorPlanet,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return SectorPlanetMapper.ensureInitialized().stringifyValue(
      this as SectorPlanet,
    );
  }

  @override
  bool operator ==(Object other) {
    return SectorPlanetMapper.ensureInitialized().equalsValue(
      this as SectorPlanet,
      other,
    );
  }

  @override
  int get hashCode {
    return SectorPlanetMapper.ensureInitialized().hashValue(
      this as SectorPlanet,
    );
  }
}

extension SectorPlanetValueCopy<$R, $Out>
    on ObjectCopyWith<$R, SectorPlanet, $Out> {
  SectorPlanetCopyWith<$R, SectorPlanet, $Out> get $asSectorPlanet =>
      $base.as((v, t, t2) => _SectorPlanetCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class SectorPlanetCopyWith<$R, $In extends SectorPlanet, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>> get conditionIds;
  $R call({
    String? name,
    String? type,
    List<String>? conditionIds,
    double? hazardRating,
  });
  SectorPlanetCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _SectorPlanetCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, SectorPlanet, $Out>
    implements SectorPlanetCopyWith<$R, SectorPlanet, $Out> {
  _SectorPlanetCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<SectorPlanet> $mapper =
      SectorPlanetMapper.ensureInitialized();
  @override
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>>
  get conditionIds => ListCopyWith(
    $value.conditionIds,
    (v, t) => ObjectCopyWith(v, $identity, t),
    (v) => call(conditionIds: v),
  );
  @override
  $R call({
    String? name,
    String? type,
    List<String>? conditionIds,
    double? hazardRating,
  }) => $apply(
    FieldCopyWithData({
      if (name != null) #name: name,
      if (type != null) #type: type,
      if (conditionIds != null) #conditionIds: conditionIds,
      if (hazardRating != null) #hazardRating: hazardRating,
    }),
  );
  @override
  SectorPlanet $make(CopyWithData data) => SectorPlanet(
    name: data.get(#name, or: $value.name),
    type: data.get(#type, or: $value.type),
    conditionIds: data.get(#conditionIds, or: $value.conditionIds),
    hazardRating: data.get(#hazardRating, or: $value.hazardRating),
  );

  @override
  SectorPlanetCopyWith<$R2, SectorPlanet, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _SectorPlanetCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class SectorConstellationMapper extends ClassMapperBase<SectorConstellation> {
  SectorConstellationMapper._();

  static SectorConstellationMapper? _instance;
  static SectorConstellationMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = SectorConstellationMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'SectorConstellation';

  static String _$id(SectorConstellation v) => v.id;
  static const Field<SectorConstellation, String> _f$id = Field('id', _$id);
  static String _$name(SectorConstellation v) => v.name;
  static const Field<SectorConstellation, String> _f$name = Field(
    'name',
    _$name,
  );

  @override
  final MappableFields<SectorConstellation> fields = const {
    #id: _f$id,
    #name: _f$name,
  };

  static SectorConstellation _instantiate(DecodingData data) {
    return SectorConstellation(id: data.dec(_f$id), name: data.dec(_f$name));
  }

  @override
  final Function instantiate = _instantiate;

  static SectorConstellation fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<SectorConstellation>(map);
  }

  static SectorConstellation fromJson(String json) {
    return ensureInitialized().decodeJson<SectorConstellation>(json);
  }
}

mixin SectorConstellationMappable {
  String toJson() {
    return SectorConstellationMapper.ensureInitialized()
        .encodeJson<SectorConstellation>(this as SectorConstellation);
  }

  Map<String, dynamic> toMap() {
    return SectorConstellationMapper.ensureInitialized()
        .encodeMap<SectorConstellation>(this as SectorConstellation);
  }

  SectorConstellationCopyWith<
    SectorConstellation,
    SectorConstellation,
    SectorConstellation
  >
  get copyWith =>
      _SectorConstellationCopyWithImpl<
        SectorConstellation,
        SectorConstellation
      >(this as SectorConstellation, $identity, $identity);
  @override
  String toString() {
    return SectorConstellationMapper.ensureInitialized().stringifyValue(
      this as SectorConstellation,
    );
  }

  @override
  bool operator ==(Object other) {
    return SectorConstellationMapper.ensureInitialized().equalsValue(
      this as SectorConstellation,
      other,
    );
  }

  @override
  int get hashCode {
    return SectorConstellationMapper.ensureInitialized().hashValue(
      this as SectorConstellation,
    );
  }
}

extension SectorConstellationValueCopy<$R, $Out>
    on ObjectCopyWith<$R, SectorConstellation, $Out> {
  SectorConstellationCopyWith<$R, SectorConstellation, $Out>
  get $asSectorConstellation => $base.as(
    (v, t, t2) => _SectorConstellationCopyWithImpl<$R, $Out>(v, t, t2),
  );
}

abstract class SectorConstellationCopyWith<
  $R,
  $In extends SectorConstellation,
  $Out
>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({String? id, String? name});
  SectorConstellationCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _SectorConstellationCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, SectorConstellation, $Out>
    implements SectorConstellationCopyWith<$R, SectorConstellation, $Out> {
  _SectorConstellationCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<SectorConstellation> $mapper =
      SectorConstellationMapper.ensureInitialized();
  @override
  $R call({String? id, String? name}) => $apply(
    FieldCopyWithData({if (id != null) #id: id, if (name != null) #name: name}),
  );
  @override
  SectorConstellation $make(CopyWithData data) => SectorConstellation(
    id: data.get(#id, or: $value.id),
    name: data.get(#name, or: $value.name),
  );

  @override
  SectorConstellationCopyWith<$R2, SectorConstellation, $Out2>
  $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _SectorConstellationCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class SectorLandmarkMapper extends ClassMapperBase<SectorLandmark> {
  SectorLandmarkMapper._();

  static SectorLandmarkMapper? _instance;
  static SectorLandmarkMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = SectorLandmarkMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'SectorLandmark';

  static String _$typeId(SectorLandmark v) => v.typeId;
  static const Field<SectorLandmark, String> _f$typeId = Field(
    'typeId',
    _$typeId,
  );
  static String _$name(SectorLandmark v) => v.name;
  static const Field<SectorLandmark, String> _f$name = Field('name', _$name);
  static String _$systemId(SectorLandmark v) => v.systemId;
  static const Field<SectorLandmark, String> _f$systemId = Field(
    'systemId',
    _$systemId,
  );

  @override
  final MappableFields<SectorLandmark> fields = const {
    #typeId: _f$typeId,
    #name: _f$name,
    #systemId: _f$systemId,
  };

  static SectorLandmark _instantiate(DecodingData data) {
    return SectorLandmark(
      typeId: data.dec(_f$typeId),
      name: data.dec(_f$name),
      systemId: data.dec(_f$systemId),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static SectorLandmark fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<SectorLandmark>(map);
  }

  static SectorLandmark fromJson(String json) {
    return ensureInitialized().decodeJson<SectorLandmark>(json);
  }
}

mixin SectorLandmarkMappable {
  String toJson() {
    return SectorLandmarkMapper.ensureInitialized().encodeJson<SectorLandmark>(
      this as SectorLandmark,
    );
  }

  Map<String, dynamic> toMap() {
    return SectorLandmarkMapper.ensureInitialized().encodeMap<SectorLandmark>(
      this as SectorLandmark,
    );
  }

  SectorLandmarkCopyWith<SectorLandmark, SectorLandmark, SectorLandmark>
  get copyWith => _SectorLandmarkCopyWithImpl<SectorLandmark, SectorLandmark>(
    this as SectorLandmark,
    $identity,
    $identity,
  );
  @override
  String toString() {
    return SectorLandmarkMapper.ensureInitialized().stringifyValue(
      this as SectorLandmark,
    );
  }

  @override
  bool operator ==(Object other) {
    return SectorLandmarkMapper.ensureInitialized().equalsValue(
      this as SectorLandmark,
      other,
    );
  }

  @override
  int get hashCode {
    return SectorLandmarkMapper.ensureInitialized().hashValue(
      this as SectorLandmark,
    );
  }
}

extension SectorLandmarkValueCopy<$R, $Out>
    on ObjectCopyWith<$R, SectorLandmark, $Out> {
  SectorLandmarkCopyWith<$R, SectorLandmark, $Out> get $asSectorLandmark =>
      $base.as((v, t, t2) => _SectorLandmarkCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class SectorLandmarkCopyWith<$R, $In extends SectorLandmark, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({String? typeId, String? name, String? systemId});
  SectorLandmarkCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _SectorLandmarkCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, SectorLandmark, $Out>
    implements SectorLandmarkCopyWith<$R, SectorLandmark, $Out> {
  _SectorLandmarkCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<SectorLandmark> $mapper =
      SectorLandmarkMapper.ensureInitialized();
  @override
  $R call({String? typeId, String? name, String? systemId}) => $apply(
    FieldCopyWithData({
      if (typeId != null) #typeId: typeId,
      if (name != null) #name: name,
      if (systemId != null) #systemId: systemId,
    }),
  );
  @override
  SectorLandmark $make(CopyWithData data) => SectorLandmark(
    typeId: data.get(#typeId, or: $value.typeId),
    name: data.get(#name, or: $value.name),
    systemId: data.get(#systemId, or: $value.systemId),
  );

  @override
  SectorLandmarkCopyWith<$R2, SectorLandmark, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _SectorLandmarkCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

