// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'graphics_lib_config.dart';

class GraphicsLibConfigMapper extends ClassMapperBase<GraphicsLibConfig> {
  GraphicsLibConfigMapper._();

  static GraphicsLibConfigMapper? _instance;
  static GraphicsLibConfigMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = GraphicsLibConfigMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'GraphicsLibConfig';

  static bool _$areAnyEffectsEnabled(GraphicsLibConfig v) =>
      v.areAnyEffectsEnabled;
  static const Field<GraphicsLibConfig, bool> _f$areAnyEffectsEnabled = Field(
    'areAnyEffectsEnabled',
    _$areAnyEffectsEnabled,
    key: r'enableShaders',
  );
  static bool _$areGfxLibNormalMapsEnabled(GraphicsLibConfig v) =>
      v.areGfxLibNormalMapsEnabled;
  static const Field<GraphicsLibConfig, bool> _f$areGfxLibNormalMapsEnabled =
      Field(
        'areGfxLibNormalMapsEnabled',
        _$areGfxLibNormalMapsEnabled,
        key: r'enableNormal',
      );
  static bool _$areGfxLibMaterialMapsEnabled(GraphicsLibConfig v) =>
      v.areGfxLibMaterialMapsEnabled;
  static const Field<GraphicsLibConfig, bool> _f$areGfxLibMaterialMapsEnabled =
      Field(
        'areGfxLibMaterialMapsEnabled',
        _$areGfxLibMaterialMapsEnabled,
        key: r'loadMaterial',
      );
  static bool _$areGfxLibSurfaceMapsEnabled(GraphicsLibConfig v) =>
      v.areGfxLibSurfaceMapsEnabled;
  static const Field<GraphicsLibConfig, bool> _f$areGfxLibSurfaceMapsEnabled =
      Field(
        'areGfxLibSurfaceMapsEnabled',
        _$areGfxLibSurfaceMapsEnabled,
        key: r'loadSurface',
      );
  static bool _$autoGenNormals(GraphicsLibConfig v) => v.autoGenNormals;
  static const Field<GraphicsLibConfig, bool> _f$autoGenNormals = Field(
    'autoGenNormals',
    _$autoGenNormals,
  );
  static bool _$preloadAllMaps(GraphicsLibConfig v) => v.preloadAllMaps;
  static const Field<GraphicsLibConfig, bool> _f$preloadAllMaps = Field(
    'preloadAllMaps',
    _$preloadAllMaps,
  );

  @override
  final MappableFields<GraphicsLibConfig> fields = const {
    #areAnyEffectsEnabled: _f$areAnyEffectsEnabled,
    #areGfxLibNormalMapsEnabled: _f$areGfxLibNormalMapsEnabled,
    #areGfxLibMaterialMapsEnabled: _f$areGfxLibMaterialMapsEnabled,
    #areGfxLibSurfaceMapsEnabled: _f$areGfxLibSurfaceMapsEnabled,
    #autoGenNormals: _f$autoGenNormals,
    #preloadAllMaps: _f$preloadAllMaps,
  };

  static GraphicsLibConfig _instantiate(DecodingData data) {
    return GraphicsLibConfig(
      areAnyEffectsEnabled: data.dec(_f$areAnyEffectsEnabled),
      areGfxLibNormalMapsEnabled: data.dec(_f$areGfxLibNormalMapsEnabled),
      areGfxLibMaterialMapsEnabled: data.dec(_f$areGfxLibMaterialMapsEnabled),
      areGfxLibSurfaceMapsEnabled: data.dec(_f$areGfxLibSurfaceMapsEnabled),
      autoGenNormals: data.dec(_f$autoGenNormals),
      preloadAllMaps: data.dec(_f$preloadAllMaps),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static GraphicsLibConfig fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<GraphicsLibConfig>(map);
  }

  static GraphicsLibConfig fromJson(String json) {
    return ensureInitialized().decodeJson<GraphicsLibConfig>(json);
  }
}

mixin GraphicsLibConfigMappable {
  String toJson() {
    return GraphicsLibConfigMapper.ensureInitialized()
        .encodeJson<GraphicsLibConfig>(this as GraphicsLibConfig);
  }

  Map<String, dynamic> toMap() {
    return GraphicsLibConfigMapper.ensureInitialized()
        .encodeMap<GraphicsLibConfig>(this as GraphicsLibConfig);
  }

  GraphicsLibConfigCopyWith<
    GraphicsLibConfig,
    GraphicsLibConfig,
    GraphicsLibConfig
  >
  get copyWith =>
      _GraphicsLibConfigCopyWithImpl<GraphicsLibConfig, GraphicsLibConfig>(
        this as GraphicsLibConfig,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return GraphicsLibConfigMapper.ensureInitialized().stringifyValue(
      this as GraphicsLibConfig,
    );
  }

  @override
  bool operator ==(Object other) {
    return GraphicsLibConfigMapper.ensureInitialized().equalsValue(
      this as GraphicsLibConfig,
      other,
    );
  }

  @override
  int get hashCode {
    return GraphicsLibConfigMapper.ensureInitialized().hashValue(
      this as GraphicsLibConfig,
    );
  }
}

extension GraphicsLibConfigValueCopy<$R, $Out>
    on ObjectCopyWith<$R, GraphicsLibConfig, $Out> {
  GraphicsLibConfigCopyWith<$R, GraphicsLibConfig, $Out>
  get $asGraphicsLibConfig => $base.as(
    (v, t, t2) => _GraphicsLibConfigCopyWithImpl<$R, $Out>(v, t, t2),
  );
}

abstract class GraphicsLibConfigCopyWith<
  $R,
  $In extends GraphicsLibConfig,
  $Out
>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({
    bool? areAnyEffectsEnabled,
    bool? areGfxLibNormalMapsEnabled,
    bool? areGfxLibMaterialMapsEnabled,
    bool? areGfxLibSurfaceMapsEnabled,
    bool? autoGenNormals,
    bool? preloadAllMaps,
  });
  GraphicsLibConfigCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _GraphicsLibConfigCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, GraphicsLibConfig, $Out>
    implements GraphicsLibConfigCopyWith<$R, GraphicsLibConfig, $Out> {
  _GraphicsLibConfigCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<GraphicsLibConfig> $mapper =
      GraphicsLibConfigMapper.ensureInitialized();
  @override
  $R call({
    bool? areAnyEffectsEnabled,
    bool? areGfxLibNormalMapsEnabled,
    bool? areGfxLibMaterialMapsEnabled,
    bool? areGfxLibSurfaceMapsEnabled,
    bool? autoGenNormals,
    bool? preloadAllMaps,
  }) => $apply(
    FieldCopyWithData({
      if (areAnyEffectsEnabled != null)
        #areAnyEffectsEnabled: areAnyEffectsEnabled,
      if (areGfxLibNormalMapsEnabled != null)
        #areGfxLibNormalMapsEnabled: areGfxLibNormalMapsEnabled,
      if (areGfxLibMaterialMapsEnabled != null)
        #areGfxLibMaterialMapsEnabled: areGfxLibMaterialMapsEnabled,
      if (areGfxLibSurfaceMapsEnabled != null)
        #areGfxLibSurfaceMapsEnabled: areGfxLibSurfaceMapsEnabled,
      if (autoGenNormals != null) #autoGenNormals: autoGenNormals,
      if (preloadAllMaps != null) #preloadAllMaps: preloadAllMaps,
    }),
  );
  @override
  GraphicsLibConfig $make(CopyWithData data) => GraphicsLibConfig(
    areAnyEffectsEnabled: data.get(
      #areAnyEffectsEnabled,
      or: $value.areAnyEffectsEnabled,
    ),
    areGfxLibNormalMapsEnabled: data.get(
      #areGfxLibNormalMapsEnabled,
      or: $value.areGfxLibNormalMapsEnabled,
    ),
    areGfxLibMaterialMapsEnabled: data.get(
      #areGfxLibMaterialMapsEnabled,
      or: $value.areGfxLibMaterialMapsEnabled,
    ),
    areGfxLibSurfaceMapsEnabled: data.get(
      #areGfxLibSurfaceMapsEnabled,
      or: $value.areGfxLibSurfaceMapsEnabled,
    ),
    autoGenNormals: data.get(#autoGenNormals, or: $value.autoGenNormals),
    preloadAllMaps: data.get(#preloadAllMaps, or: $value.preloadAllMaps),
  );

  @override
  GraphicsLibConfigCopyWith<$R2, GraphicsLibConfig, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _GraphicsLibConfigCopyWithImpl<$R2, $Out2>($value, $cast, t);
}
