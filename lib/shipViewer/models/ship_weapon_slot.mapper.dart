// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'ship_weapon_slot.dart';

class ShipWeaponSlotMapper extends ClassMapperBase<ShipWeaponSlot> {
  ShipWeaponSlotMapper._();

  static ShipWeaponSlotMapper? _instance;
  static ShipWeaponSlotMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ShipWeaponSlotMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'ShipWeaponSlot';

  static double _$angle(ShipWeaponSlot v) => v.angle;
  static const Field<ShipWeaponSlot, double> _f$angle = Field(
    'angle',
    _$angle,
    opt: true,
    def: 0,
  );
  static double _$arc(ShipWeaponSlot v) => v.arc;
  static const Field<ShipWeaponSlot, double> _f$arc = Field(
    'arc',
    _$arc,
    opt: true,
    def: 0,
  );
  static String _$id(ShipWeaponSlot v) => v.id;
  static const Field<ShipWeaponSlot, String> _f$id = Field(
    'id',
    _$id,
    opt: true,
    def: '',
  );
  static List<double> _$locations(ShipWeaponSlot v) => v.locations;
  static const Field<ShipWeaponSlot, List<double>> _f$locations = Field(
    'locations',
    _$locations,
    opt: true,
    def: const [],
  );
  static List<double> _$position(ShipWeaponSlot v) => v.position;
  static const Field<ShipWeaponSlot, List<double>> _f$position = Field(
    'position',
    _$position,
    opt: true,
    def: const [],
  );
  static String _$mount(ShipWeaponSlot v) => v.mount;
  static const Field<ShipWeaponSlot, String> _f$mount = Field(
    'mount',
    _$mount,
    opt: true,
    def: '',
  );
  static String _$size(ShipWeaponSlot v) => v.size;
  static const Field<ShipWeaponSlot, String> _f$size = Field(
    'size',
    _$size,
    opt: true,
    def: '',
  );
  static String _$type(ShipWeaponSlot v) => v.type;
  static const Field<ShipWeaponSlot, String> _f$type = Field(
    'type',
    _$type,
    opt: true,
    def: '',
  );
  static double? _$renderOrderMod(ShipWeaponSlot v) => v.renderOrderMod;
  static const Field<ShipWeaponSlot, double> _f$renderOrderMod = Field(
    'renderOrderMod',
    _$renderOrderMod,
    opt: true,
  );

  @override
  final MappableFields<ShipWeaponSlot> fields = const {
    #angle: _f$angle,
    #arc: _f$arc,
    #id: _f$id,
    #locations: _f$locations,
    #position: _f$position,
    #mount: _f$mount,
    #size: _f$size,
    #type: _f$type,
    #renderOrderMod: _f$renderOrderMod,
  };

  static ShipWeaponSlot _instantiate(DecodingData data) {
    return ShipWeaponSlot(
      angle: data.dec(_f$angle),
      arc: data.dec(_f$arc),
      id: data.dec(_f$id),
      locations: data.dec(_f$locations),
      position: data.dec(_f$position),
      mount: data.dec(_f$mount),
      size: data.dec(_f$size),
      type: data.dec(_f$type),
      renderOrderMod: data.dec(_f$renderOrderMod),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static ShipWeaponSlot fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<ShipWeaponSlot>(map);
  }

  static ShipWeaponSlot fromJson(String json) {
    return ensureInitialized().decodeJson<ShipWeaponSlot>(json);
  }
}

mixin ShipWeaponSlotMappable {
  String toJson() {
    return ShipWeaponSlotMapper.ensureInitialized().encodeJson<ShipWeaponSlot>(
      this as ShipWeaponSlot,
    );
  }

  Map<String, dynamic> toMap() {
    return ShipWeaponSlotMapper.ensureInitialized().encodeMap<ShipWeaponSlot>(
      this as ShipWeaponSlot,
    );
  }

  ShipWeaponSlotCopyWith<ShipWeaponSlot, ShipWeaponSlot, ShipWeaponSlot>
  get copyWith => _ShipWeaponSlotCopyWithImpl<ShipWeaponSlot, ShipWeaponSlot>(
    this as ShipWeaponSlot,
    $identity,
    $identity,
  );
  @override
  String toString() {
    return ShipWeaponSlotMapper.ensureInitialized().stringifyValue(
      this as ShipWeaponSlot,
    );
  }

  @override
  bool operator ==(Object other) {
    return ShipWeaponSlotMapper.ensureInitialized().equalsValue(
      this as ShipWeaponSlot,
      other,
    );
  }

  @override
  int get hashCode {
    return ShipWeaponSlotMapper.ensureInitialized().hashValue(
      this as ShipWeaponSlot,
    );
  }
}

extension ShipWeaponSlotValueCopy<$R, $Out>
    on ObjectCopyWith<$R, ShipWeaponSlot, $Out> {
  ShipWeaponSlotCopyWith<$R, ShipWeaponSlot, $Out> get $asShipWeaponSlot =>
      $base.as((v, t, t2) => _ShipWeaponSlotCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class ShipWeaponSlotCopyWith<$R, $In extends ShipWeaponSlot, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  ListCopyWith<$R, double, ObjectCopyWith<$R, double, double>> get locations;
  ListCopyWith<$R, double, ObjectCopyWith<$R, double, double>> get position;
  $R call({
    double? angle,
    double? arc,
    String? id,
    List<double>? locations,
    List<double>? position,
    String? mount,
    String? size,
    String? type,
    double? renderOrderMod,
  });
  ShipWeaponSlotCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _ShipWeaponSlotCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, ShipWeaponSlot, $Out>
    implements ShipWeaponSlotCopyWith<$R, ShipWeaponSlot, $Out> {
  _ShipWeaponSlotCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<ShipWeaponSlot> $mapper =
      ShipWeaponSlotMapper.ensureInitialized();
  @override
  ListCopyWith<$R, double, ObjectCopyWith<$R, double, double>> get locations =>
      ListCopyWith(
        $value.locations,
        (v, t) => ObjectCopyWith(v, $identity, t),
        (v) => call(locations: v),
      );
  @override
  ListCopyWith<$R, double, ObjectCopyWith<$R, double, double>> get position =>
      ListCopyWith(
        $value.position,
        (v, t) => ObjectCopyWith(v, $identity, t),
        (v) => call(position: v),
      );
  @override
  $R call({
    double? angle,
    double? arc,
    String? id,
    List<double>? locations,
    List<double>? position,
    String? mount,
    String? size,
    String? type,
    Object? renderOrderMod = $none,
  }) => $apply(
    FieldCopyWithData({
      if (angle != null) #angle: angle,
      if (arc != null) #arc: arc,
      if (id != null) #id: id,
      if (locations != null) #locations: locations,
      if (position != null) #position: position,
      if (mount != null) #mount: mount,
      if (size != null) #size: size,
      if (type != null) #type: type,
      if (renderOrderMod != $none) #renderOrderMod: renderOrderMod,
    }),
  );
  @override
  ShipWeaponSlot $make(CopyWithData data) => ShipWeaponSlot(
    angle: data.get(#angle, or: $value.angle),
    arc: data.get(#arc, or: $value.arc),
    id: data.get(#id, or: $value.id),
    locations: data.get(#locations, or: $value.locations),
    position: data.get(#position, or: $value.position),
    mount: data.get(#mount, or: $value.mount),
    size: data.get(#size, or: $value.size),
    type: data.get(#type, or: $value.type),
    renderOrderMod: data.get(#renderOrderMod, or: $value.renderOrderMod),
  );

  @override
  ShipWeaponSlotCopyWith<$R2, ShipWeaponSlot, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _ShipWeaponSlotCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

