// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'ship_variant.dart';

class ShipVariantMapper extends ClassMapperBase<ShipVariant> {
  ShipVariantMapper._();

  static ShipVariantMapper? _instance;
  static ShipVariantMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ShipVariantMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'ShipVariant';

  static String _$variantId(ShipVariant v) => v.variantId;
  static const Field<ShipVariant, String> _f$variantId = Field(
    'variantId',
    _$variantId,
  );
  static String _$hullId(ShipVariant v) => v.hullId;
  static const Field<ShipVariant, String> _f$hullId = Field('hullId', _$hullId);
  static Map<String, String>? _$modules(ShipVariant v) => v.modules;
  static const Field<ShipVariant, Map<String, String>> _f$modules = Field(
    'modules',
    _$modules,
    opt: true,
  );

  @override
  final MappableFields<ShipVariant> fields = const {
    #variantId: _f$variantId,
    #hullId: _f$hullId,
    #modules: _f$modules,
  };

  static ShipVariant _instantiate(DecodingData data) {
    return ShipVariant(
      variantId: data.dec(_f$variantId),
      hullId: data.dec(_f$hullId),
      modules: data.dec(_f$modules),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static ShipVariant fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<ShipVariant>(map);
  }

  static ShipVariant fromJson(String json) {
    return ensureInitialized().decodeJson<ShipVariant>(json);
  }
}

mixin ShipVariantMappable {
  String toJson() {
    return ShipVariantMapper.ensureInitialized().encodeJson<ShipVariant>(
      this as ShipVariant,
    );
  }

  Map<String, dynamic> toMap() {
    return ShipVariantMapper.ensureInitialized().encodeMap<ShipVariant>(
      this as ShipVariant,
    );
  }

  ShipVariantCopyWith<ShipVariant, ShipVariant, ShipVariant> get copyWith =>
      _ShipVariantCopyWithImpl<ShipVariant, ShipVariant>(
        this as ShipVariant,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return ShipVariantMapper.ensureInitialized().stringifyValue(
      this as ShipVariant,
    );
  }

  @override
  bool operator ==(Object other) {
    return ShipVariantMapper.ensureInitialized().equalsValue(
      this as ShipVariant,
      other,
    );
  }

  @override
  int get hashCode {
    return ShipVariantMapper.ensureInitialized().hashValue(this as ShipVariant);
  }
}

extension ShipVariantValueCopy<$R, $Out>
    on ObjectCopyWith<$R, ShipVariant, $Out> {
  ShipVariantCopyWith<$R, ShipVariant, $Out> get $asShipVariant =>
      $base.as((v, t, t2) => _ShipVariantCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class ShipVariantCopyWith<$R, $In extends ShipVariant, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  MapCopyWith<$R, String, String, ObjectCopyWith<$R, String, String>>?
  get modules;
  $R call({String? variantId, String? hullId, Map<String, String>? modules});
  ShipVariantCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _ShipVariantCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, ShipVariant, $Out>
    implements ShipVariantCopyWith<$R, ShipVariant, $Out> {
  _ShipVariantCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<ShipVariant> $mapper =
      ShipVariantMapper.ensureInitialized();
  @override
  MapCopyWith<$R, String, String, ObjectCopyWith<$R, String, String>>?
  get modules => $value.modules != null
      ? MapCopyWith(
          $value.modules!,
          (v, t) => ObjectCopyWith(v, $identity, t),
          (v) => call(modules: v),
        )
      : null;
  @override
  $R call({String? variantId, String? hullId, Object? modules = $none}) =>
      $apply(
        FieldCopyWithData({
          if (variantId != null) #variantId: variantId,
          if (hullId != null) #hullId: hullId,
          if (modules != $none) #modules: modules,
        }),
      );
  @override
  ShipVariant $make(CopyWithData data) => ShipVariant(
    variantId: data.get(#variantId, or: $value.variantId),
    hullId: data.get(#hullId, or: $value.hullId),
    modules: data.get(#modules, or: $value.modules),
  );

  @override
  ShipVariantCopyWith<$R2, ShipVariant, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _ShipVariantCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

