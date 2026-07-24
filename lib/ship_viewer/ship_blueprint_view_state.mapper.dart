// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'ship_blueprint_view_state.dart';

class ShipBlueprintViewStateMapper
    extends ClassMapperBase<ShipBlueprintViewState> {
  ShipBlueprintViewStateMapper._();

  static ShipBlueprintViewStateMapper? _instance;
  static ShipBlueprintViewStateMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ShipBlueprintViewStateMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'ShipBlueprintViewState';

  static bool _$showModules(ShipBlueprintViewState v) => v.showModules;
  static const Field<ShipBlueprintViewState, bool> _f$showModules = Field(
    'showModules',
    _$showModules,
    opt: true,
    def: true,
  );
  static bool _$showBounds(ShipBlueprintViewState v) => v.showBounds;
  static const Field<ShipBlueprintViewState, bool> _f$showBounds = Field(
    'showBounds',
    _$showBounds,
    opt: true,
    def: false,
  );
  static bool _$showMounts(ShipBlueprintViewState v) => v.showMounts;
  static const Field<ShipBlueprintViewState, bool> _f$showMounts = Field(
    'showMounts',
    _$showMounts,
    opt: true,
    def: true,
  );
  static bool _$showArcs(ShipBlueprintViewState v) => v.showArcs;
  static const Field<ShipBlueprintViewState, bool> _f$showArcs = Field(
    'showArcs',
    _$showArcs,
    opt: true,
    def: true,
  );
  static bool _$showWeapons(ShipBlueprintViewState v) => v.showWeapons;
  static const Field<ShipBlueprintViewState, bool> _f$showWeapons = Field(
    'showWeapons',
    _$showWeapons,
    opt: true,
    def: true,
  );
  static bool _$showDecorativeWeapons(ShipBlueprintViewState v) =>
      v.showDecorativeWeapons;
  static const Field<ShipBlueprintViewState, bool> _f$showDecorativeWeapons =
      Field(
        'showDecorativeWeapons',
        _$showDecorativeWeapons,
        opt: true,
        def: true,
      );
  static bool _$showEngineGlow(ShipBlueprintViewState v) => v.showEngineGlow;
  static const Field<ShipBlueprintViewState, bool> _f$showEngineGlow = Field(
    'showEngineGlow',
    _$showEngineGlow,
    opt: true,
    def: false,
  );
  static bool _$showShield(ShipBlueprintViewState v) => v.showShield;
  static const Field<ShipBlueprintViewState, bool> _f$showShield = Field(
    'showShield',
    _$showShield,
    opt: true,
    def: false,
  );
  static bool _$animateShields(ShipBlueprintViewState v) => v.animateShields;
  static const Field<ShipBlueprintViewState, bool> _f$animateShields = Field(
    'animateShields',
    _$animateShields,
    opt: true,
    def: true,
  );

  @override
  final MappableFields<ShipBlueprintViewState> fields = const {
    #showModules: _f$showModules,
    #showBounds: _f$showBounds,
    #showMounts: _f$showMounts,
    #showArcs: _f$showArcs,
    #showWeapons: _f$showWeapons,
    #showDecorativeWeapons: _f$showDecorativeWeapons,
    #showEngineGlow: _f$showEngineGlow,
    #showShield: _f$showShield,
    #animateShields: _f$animateShields,
  };

  static ShipBlueprintViewState _instantiate(DecodingData data) {
    return ShipBlueprintViewState(
      showModules: data.dec(_f$showModules),
      showBounds: data.dec(_f$showBounds),
      showMounts: data.dec(_f$showMounts),
      showArcs: data.dec(_f$showArcs),
      showWeapons: data.dec(_f$showWeapons),
      showDecorativeWeapons: data.dec(_f$showDecorativeWeapons),
      showEngineGlow: data.dec(_f$showEngineGlow),
      showShield: data.dec(_f$showShield),
      animateShields: data.dec(_f$animateShields),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static ShipBlueprintViewState fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<ShipBlueprintViewState>(map);
  }

  static ShipBlueprintViewState fromJson(String json) {
    return ensureInitialized().decodeJson<ShipBlueprintViewState>(json);
  }
}

mixin ShipBlueprintViewStateMappable {
  String toJson() {
    return ShipBlueprintViewStateMapper.ensureInitialized()
        .encodeJson<ShipBlueprintViewState>(this as ShipBlueprintViewState);
  }

  Map<String, dynamic> toMap() {
    return ShipBlueprintViewStateMapper.ensureInitialized()
        .encodeMap<ShipBlueprintViewState>(this as ShipBlueprintViewState);
  }

  ShipBlueprintViewStateCopyWith<
    ShipBlueprintViewState,
    ShipBlueprintViewState,
    ShipBlueprintViewState
  >
  get copyWith =>
      _ShipBlueprintViewStateCopyWithImpl<
        ShipBlueprintViewState,
        ShipBlueprintViewState
      >(this as ShipBlueprintViewState, $identity, $identity);
  @override
  String toString() {
    return ShipBlueprintViewStateMapper.ensureInitialized().stringifyValue(
      this as ShipBlueprintViewState,
    );
  }

  @override
  bool operator ==(Object other) {
    return ShipBlueprintViewStateMapper.ensureInitialized().equalsValue(
      this as ShipBlueprintViewState,
      other,
    );
  }

  @override
  int get hashCode {
    return ShipBlueprintViewStateMapper.ensureInitialized().hashValue(
      this as ShipBlueprintViewState,
    );
  }
}

extension ShipBlueprintViewStateValueCopy<$R, $Out>
    on ObjectCopyWith<$R, ShipBlueprintViewState, $Out> {
  ShipBlueprintViewStateCopyWith<$R, ShipBlueprintViewState, $Out>
  get $asShipBlueprintViewState => $base.as(
    (v, t, t2) => _ShipBlueprintViewStateCopyWithImpl<$R, $Out>(v, t, t2),
  );
}

abstract class ShipBlueprintViewStateCopyWith<
  $R,
  $In extends ShipBlueprintViewState,
  $Out
>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({
    bool? showModules,
    bool? showBounds,
    bool? showMounts,
    bool? showArcs,
    bool? showWeapons,
    bool? showDecorativeWeapons,
    bool? showEngineGlow,
    bool? showShield,
    bool? animateShields,
  });
  ShipBlueprintViewStateCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _ShipBlueprintViewStateCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, ShipBlueprintViewState, $Out>
    implements
        ShipBlueprintViewStateCopyWith<$R, ShipBlueprintViewState, $Out> {
  _ShipBlueprintViewStateCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<ShipBlueprintViewState> $mapper =
      ShipBlueprintViewStateMapper.ensureInitialized();
  @override
  $R call({
    bool? showModules,
    bool? showBounds,
    bool? showMounts,
    bool? showArcs,
    bool? showWeapons,
    bool? showDecorativeWeapons,
    bool? showEngineGlow,
    bool? showShield,
    bool? animateShields,
  }) => $apply(
    FieldCopyWithData({
      if (showModules != null) #showModules: showModules,
      if (showBounds != null) #showBounds: showBounds,
      if (showMounts != null) #showMounts: showMounts,
      if (showArcs != null) #showArcs: showArcs,
      if (showWeapons != null) #showWeapons: showWeapons,
      if (showDecorativeWeapons != null)
        #showDecorativeWeapons: showDecorativeWeapons,
      if (showEngineGlow != null) #showEngineGlow: showEngineGlow,
      if (showShield != null) #showShield: showShield,
      if (animateShields != null) #animateShields: animateShields,
    }),
  );
  @override
  ShipBlueprintViewState $make(CopyWithData data) => ShipBlueprintViewState(
    showModules: data.get(#showModules, or: $value.showModules),
    showBounds: data.get(#showBounds, or: $value.showBounds),
    showMounts: data.get(#showMounts, or: $value.showMounts),
    showArcs: data.get(#showArcs, or: $value.showArcs),
    showWeapons: data.get(#showWeapons, or: $value.showWeapons),
    showDecorativeWeapons: data.get(
      #showDecorativeWeapons,
      or: $value.showDecorativeWeapons,
    ),
    showEngineGlow: data.get(#showEngineGlow, or: $value.showEngineGlow),
    showShield: data.get(#showShield, or: $value.showShield),
    animateShields: data.get(#animateShields, or: $value.animateShields),
  );

  @override
  ShipBlueprintViewStateCopyWith<$R2, ShipBlueprintViewState, $Out2>
  $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _ShipBlueprintViewStateCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

