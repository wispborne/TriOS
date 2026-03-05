// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'ship_system.dart';

class ShipSystemMapper extends ClassMapperBase<ShipSystem> {
  ShipSystemMapper._();

  static ShipSystemMapper? _instance;
  static ShipSystemMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ShipSystemMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'ShipSystem';

  static String _$id(ShipSystem v) => v.id;
  static const Field<ShipSystem, String> _f$id = Field('id', _$id);
  static String? _$name(ShipSystem v) => v.name;
  static const Field<ShipSystem, String> _f$name = Field(
    'name',
    _$name,
    opt: true,
  );

  @override
  final MappableFields<ShipSystem> fields = const {#id: _f$id, #name: _f$name};

  static ShipSystem _instantiate(DecodingData data) {
    return ShipSystem(id: data.dec(_f$id), name: data.dec(_f$name));
  }

  @override
  final Function instantiate = _instantiate;

  static ShipSystem fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<ShipSystem>(map);
  }

  static ShipSystem fromJson(String json) {
    return ensureInitialized().decodeJson<ShipSystem>(json);
  }
}

mixin ShipSystemMappable {
  String toJson() {
    return ShipSystemMapper.ensureInitialized().encodeJson<ShipSystem>(
      this as ShipSystem,
    );
  }

  Map<String, dynamic> toMap() {
    return ShipSystemMapper.ensureInitialized().encodeMap<ShipSystem>(
      this as ShipSystem,
    );
  }

  ShipSystemCopyWith<ShipSystem, ShipSystem, ShipSystem> get copyWith =>
      _ShipSystemCopyWithImpl<ShipSystem, ShipSystem>(
        this as ShipSystem,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return ShipSystemMapper.ensureInitialized().stringifyValue(
      this as ShipSystem,
    );
  }

  @override
  bool operator ==(Object other) {
    return ShipSystemMapper.ensureInitialized().equalsValue(
      this as ShipSystem,
      other,
    );
  }

  @override
  int get hashCode {
    return ShipSystemMapper.ensureInitialized().hashValue(this as ShipSystem);
  }
}

extension ShipSystemValueCopy<$R, $Out>
    on ObjectCopyWith<$R, ShipSystem, $Out> {
  ShipSystemCopyWith<$R, ShipSystem, $Out> get $asShipSystem =>
      $base.as((v, t, t2) => _ShipSystemCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class ShipSystemCopyWith<$R, $In extends ShipSystem, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({String? id, String? name});
  ShipSystemCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _ShipSystemCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, ShipSystem, $Out>
    implements ShipSystemCopyWith<$R, ShipSystem, $Out> {
  _ShipSystemCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<ShipSystem> $mapper =
      ShipSystemMapper.ensureInitialized();
  @override
  $R call({String? id, Object? name = $none}) => $apply(
    FieldCopyWithData({
      if (id != null) #id: id,
      if (name != $none) #name: name,
    }),
  );
  @override
  ShipSystem $make(CopyWithData data) => ShipSystem(
    id: data.get(#id, or: $value.id),
    name: data.get(#name, or: $value.name),
  );

  @override
  ShipSystemCopyWith<$R2, ShipSystem, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _ShipSystemCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

