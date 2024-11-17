// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'graphics_lib_info.dart';

class MapTypeMapper extends EnumMapper<MapType> {
  MapTypeMapper._();

  static MapTypeMapper? _instance;
  static MapTypeMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = MapTypeMapper._());
    }
    return _instance!;
  }

  static MapType fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  MapType decode(dynamic value) {
    switch (value) {
      case 'Normal':
        return MapType.Normal;
      case 'Material':
        return MapType.Material;
      case 'Surface':
        return MapType.Surface;
      default:
        throw MapperException.unknownEnumValue(value);
    }
  }

  @override
  dynamic encode(MapType self) {
    switch (self) {
      case MapType.Normal:
        return 'Normal';
      case MapType.Material:
        return 'Material';
      case MapType.Surface:
        return 'Surface';
    }
  }
}

extension MapTypeMapperExtension on MapType {
  String toValue() {
    MapTypeMapper.ensureInitialized();
    return MapperContainer.globals.toValue<MapType>(this) as String;
  }
}

class GraphicsLibInfoMapper extends ClassMapperBase<GraphicsLibInfo> {
  GraphicsLibInfoMapper._();

  static GraphicsLibInfoMapper? _instance;
  static GraphicsLibInfoMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = GraphicsLibInfoMapper._());
      MapTypeMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'GraphicsLibInfo';

  static MapType _$mapType(GraphicsLibInfo v) => v.mapType;
  static const Field<GraphicsLibInfo, MapType> _f$mapType =
      Field('mapType', _$mapType);
  static String _$relativeFilePath(GraphicsLibInfo v) => v.relativeFilePath;
  static const Field<GraphicsLibInfo, String> _f$relativeFilePath =
      Field('relativeFilePath', _$relativeFilePath);

  @override
  final MappableFields<GraphicsLibInfo> fields = const {
    #mapType: _f$mapType,
    #relativeFilePath: _f$relativeFilePath,
  };

  static GraphicsLibInfo _instantiate(DecodingData data) {
    return GraphicsLibInfo(data.dec(_f$mapType), data.dec(_f$relativeFilePath));
  }

  @override
  final Function instantiate = _instantiate;

  static GraphicsLibInfo fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<GraphicsLibInfo>(map);
  }

  static GraphicsLibInfo fromJson(String json) {
    return ensureInitialized().decodeJson<GraphicsLibInfo>(json);
  }
}

mixin GraphicsLibInfoMappable {
  String toJson() {
    return GraphicsLibInfoMapper.ensureInitialized()
        .encodeJson<GraphicsLibInfo>(this as GraphicsLibInfo);
  }

  Map<String, dynamic> toMap() {
    return GraphicsLibInfoMapper.ensureInitialized()
        .encodeMap<GraphicsLibInfo>(this as GraphicsLibInfo);
  }

  GraphicsLibInfoCopyWith<GraphicsLibInfo, GraphicsLibInfo, GraphicsLibInfo>
      get copyWith => _GraphicsLibInfoCopyWithImpl(
          this as GraphicsLibInfo, $identity, $identity);
  @override
  String toString() {
    return GraphicsLibInfoMapper.ensureInitialized()
        .stringifyValue(this as GraphicsLibInfo);
  }

  @override
  bool operator ==(Object other) {
    return GraphicsLibInfoMapper.ensureInitialized()
        .equalsValue(this as GraphicsLibInfo, other);
  }

  @override
  int get hashCode {
    return GraphicsLibInfoMapper.ensureInitialized()
        .hashValue(this as GraphicsLibInfo);
  }
}

extension GraphicsLibInfoValueCopy<$R, $Out>
    on ObjectCopyWith<$R, GraphicsLibInfo, $Out> {
  GraphicsLibInfoCopyWith<$R, GraphicsLibInfo, $Out> get $asGraphicsLibInfo =>
      $base.as((v, t, t2) => _GraphicsLibInfoCopyWithImpl(v, t, t2));
}

abstract class GraphicsLibInfoCopyWith<$R, $In extends GraphicsLibInfo, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({MapType? mapType, String? relativeFilePath});
  GraphicsLibInfoCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
      Then<$Out2, $R2> t);
}

class _GraphicsLibInfoCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, GraphicsLibInfo, $Out>
    implements GraphicsLibInfoCopyWith<$R, GraphicsLibInfo, $Out> {
  _GraphicsLibInfoCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<GraphicsLibInfo> $mapper =
      GraphicsLibInfoMapper.ensureInitialized();
  @override
  $R call({MapType? mapType, String? relativeFilePath}) =>
      $apply(FieldCopyWithData({
        if (mapType != null) #mapType: mapType,
        if (relativeFilePath != null) #relativeFilePath: relativeFilePath
      }));
  @override
  GraphicsLibInfo $make(CopyWithData data) => GraphicsLibInfo(
      data.get(#mapType, or: $value.mapType),
      data.get(#relativeFilePath, or: $value.relativeFilePath));

  @override
  GraphicsLibInfoCopyWith<$R2, GraphicsLibInfo, $Out2> $chain<$R2, $Out2>(
          Then<$Out2, $R2> t) =>
      _GraphicsLibInfoCopyWithImpl($value, $cast, t);
}
