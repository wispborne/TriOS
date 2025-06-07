// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'graphics_lib_lunaconfig.dart';

class GraphicsLibLunaConfigMapper
    extends ClassMapperBase<GraphicsLibLunaConfig> {
  GraphicsLibLunaConfigMapper._();

  static GraphicsLibLunaConfigMapper? _instance;
  static GraphicsLibLunaConfigMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = GraphicsLibLunaConfigMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'GraphicsLibLunaConfig';

  static bool _$aaCompatMode(GraphicsLibLunaConfig v) => v.aaCompatMode;
  static const Field<GraphicsLibLunaConfig, bool> _f$aaCompatMode = Field(
    'aaCompatMode',
    _$aaCompatMode,
    opt: true,
    def: false,
  );
  static bool _$autoGenNormals(GraphicsLibLunaConfig v) => v.autoGenNormals;
  static const Field<GraphicsLibLunaConfig, bool> _f$autoGenNormals = Field(
    'autoGenNormals',
    _$autoGenNormals,
    opt: true,
    def: true,
  );
  static bool _$enableNormal(GraphicsLibLunaConfig v) => v.enableNormal;
  static const Field<GraphicsLibLunaConfig, bool> _f$enableNormal = Field(
    'enableNormal',
    _$enableNormal,
    opt: true,
    def: true,
  );
  static bool _$enableShaders(GraphicsLibLunaConfig v) => v.enableShaders;
  static const Field<GraphicsLibLunaConfig, bool> _f$enableShaders = Field(
    'enableShaders',
    _$enableShaders,
    opt: true,
    def: true,
  );
  static bool _$loadMaterial(GraphicsLibLunaConfig v) => v.loadMaterial;
  static const Field<GraphicsLibLunaConfig, bool> _f$loadMaterial = Field(
    'loadMaterial',
    _$loadMaterial,
    opt: true,
    def: true,
  );
  static bool _$loadSurface(GraphicsLibLunaConfig v) => v.loadSurface;
  static const Field<GraphicsLibLunaConfig, bool> _f$loadSurface = Field(
    'loadSurface',
    _$loadSurface,
    opt: true,
    def: true,
  );
  static bool _$optimizeNormals(GraphicsLibLunaConfig v) => v.optimizeNormals;
  static const Field<GraphicsLibLunaConfig, bool> _f$optimizeNormals = Field(
    'optimizeNormals',
    _$optimizeNormals,
    opt: true,
    def: false,
  );
  static bool _$preloadAllMaps(GraphicsLibLunaConfig v) => v.preloadAllMaps;
  static const Field<GraphicsLibLunaConfig, bool> _f$preloadAllMaps = Field(
    'preloadAllMaps',
    _$preloadAllMaps,
    opt: true,
    def: false,
  );

  @override
  final MappableFields<GraphicsLibLunaConfig> fields = const {
    #aaCompatMode: _f$aaCompatMode,
    #autoGenNormals: _f$autoGenNormals,
    #enableNormal: _f$enableNormal,
    #enableShaders: _f$enableShaders,
    #loadMaterial: _f$loadMaterial,
    #loadSurface: _f$loadSurface,
    #optimizeNormals: _f$optimizeNormals,
    #preloadAllMaps: _f$preloadAllMaps,
  };

  static GraphicsLibLunaConfig _instantiate(DecodingData data) {
    return GraphicsLibLunaConfig(
      aaCompatMode: data.dec(_f$aaCompatMode),
      autoGenNormals: data.dec(_f$autoGenNormals),
      enableNormal: data.dec(_f$enableNormal),
      enableShaders: data.dec(_f$enableShaders),
      loadMaterial: data.dec(_f$loadMaterial),
      loadSurface: data.dec(_f$loadSurface),
      optimizeNormals: data.dec(_f$optimizeNormals),
      preloadAllMaps: data.dec(_f$preloadAllMaps),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static GraphicsLibLunaConfig fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<GraphicsLibLunaConfig>(map);
  }

  static GraphicsLibLunaConfig fromJson(String json) {
    return ensureInitialized().decodeJson<GraphicsLibLunaConfig>(json);
  }
}

mixin GraphicsLibLunaConfigMappable {
  String toJson() {
    return GraphicsLibLunaConfigMapper.ensureInitialized()
        .encodeJson<GraphicsLibLunaConfig>(this as GraphicsLibLunaConfig);
  }

  Map<String, dynamic> toMap() {
    return GraphicsLibLunaConfigMapper.ensureInitialized()
        .encodeMap<GraphicsLibLunaConfig>(this as GraphicsLibLunaConfig);
  }

  GraphicsLibLunaConfigCopyWith<
    GraphicsLibLunaConfig,
    GraphicsLibLunaConfig,
    GraphicsLibLunaConfig
  >
  get copyWith =>
      _GraphicsLibLunaConfigCopyWithImpl<
        GraphicsLibLunaConfig,
        GraphicsLibLunaConfig
      >(this as GraphicsLibLunaConfig, $identity, $identity);
  @override
  String toString() {
    return GraphicsLibLunaConfigMapper.ensureInitialized().stringifyValue(
      this as GraphicsLibLunaConfig,
    );
  }

  @override
  bool operator ==(Object other) {
    return GraphicsLibLunaConfigMapper.ensureInitialized().equalsValue(
      this as GraphicsLibLunaConfig,
      other,
    );
  }

  @override
  int get hashCode {
    return GraphicsLibLunaConfigMapper.ensureInitialized().hashValue(
      this as GraphicsLibLunaConfig,
    );
  }
}

extension GraphicsLibLunaConfigValueCopy<$R, $Out>
    on ObjectCopyWith<$R, GraphicsLibLunaConfig, $Out> {
  GraphicsLibLunaConfigCopyWith<$R, GraphicsLibLunaConfig, $Out>
  get $asGraphicsLibLunaConfig => $base.as(
    (v, t, t2) => _GraphicsLibLunaConfigCopyWithImpl<$R, $Out>(v, t, t2),
  );
}

abstract class GraphicsLibLunaConfigCopyWith<
  $R,
  $In extends GraphicsLibLunaConfig,
  $Out
>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({
    bool? aaCompatMode,
    bool? autoGenNormals,
    bool? enableNormal,
    bool? enableShaders,
    bool? loadMaterial,
    bool? loadSurface,
    bool? optimizeNormals,
    bool? preloadAllMaps,
  });
  GraphicsLibLunaConfigCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _GraphicsLibLunaConfigCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, GraphicsLibLunaConfig, $Out>
    implements GraphicsLibLunaConfigCopyWith<$R, GraphicsLibLunaConfig, $Out> {
  _GraphicsLibLunaConfigCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<GraphicsLibLunaConfig> $mapper =
      GraphicsLibLunaConfigMapper.ensureInitialized();
  @override
  $R call({
    bool? aaCompatMode,
    bool? autoGenNormals,
    bool? enableNormal,
    bool? enableShaders,
    bool? loadMaterial,
    bool? loadSurface,
    bool? optimizeNormals,
    bool? preloadAllMaps,
  }) => $apply(
    FieldCopyWithData({
      if (aaCompatMode != null) #aaCompatMode: aaCompatMode,
      if (autoGenNormals != null) #autoGenNormals: autoGenNormals,
      if (enableNormal != null) #enableNormal: enableNormal,
      if (enableShaders != null) #enableShaders: enableShaders,
      if (loadMaterial != null) #loadMaterial: loadMaterial,
      if (loadSurface != null) #loadSurface: loadSurface,
      if (optimizeNormals != null) #optimizeNormals: optimizeNormals,
      if (preloadAllMaps != null) #preloadAllMaps: preloadAllMaps,
    }),
  );
  @override
  GraphicsLibLunaConfig $make(CopyWithData data) => GraphicsLibLunaConfig(
    aaCompatMode: data.get(#aaCompatMode, or: $value.aaCompatMode),
    autoGenNormals: data.get(#autoGenNormals, or: $value.autoGenNormals),
    enableNormal: data.get(#enableNormal, or: $value.enableNormal),
    enableShaders: data.get(#enableShaders, or: $value.enableShaders),
    loadMaterial: data.get(#loadMaterial, or: $value.loadMaterial),
    loadSurface: data.get(#loadSurface, or: $value.loadSurface),
    optimizeNormals: data.get(#optimizeNormals, or: $value.optimizeNormals),
    preloadAllMaps: data.get(#preloadAllMaps, or: $value.preloadAllMaps),
  );

  @override
  GraphicsLibLunaConfigCopyWith<$R2, GraphicsLibLunaConfig, $Out2>
  $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _GraphicsLibLunaConfigCopyWithImpl<$R2, $Out2>($value, $cast, t);
}
