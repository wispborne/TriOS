// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'vram_estimator_manager.dart';

class VramEstimatorManagerStateMapper
    extends ClassMapperBase<VramEstimatorManagerState> {
  VramEstimatorManagerStateMapper._();

  static VramEstimatorManagerStateMapper? _instance;
  static VramEstimatorManagerStateMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(
        _instance = VramEstimatorManagerStateMapper._(),
      );
      VramModMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'VramEstimatorManagerState';

  static Map<String, VramMod> _$modVramInfo(VramEstimatorManagerState v) =>
      v.modVramInfo;
  static const Field<VramEstimatorManagerState, Map<String, VramMod>>
  _f$modVramInfo = Field('modVramInfo', _$modVramInfo);
  static DateTime? _$lastUpdated(VramEstimatorManagerState v) => v.lastUpdated;
  static const Field<VramEstimatorManagerState, DateTime> _f$lastUpdated =
      Field('lastUpdated', _$lastUpdated);
  static bool _$isScanning(VramEstimatorManagerState v) => v.isScanning;
  static const Field<VramEstimatorManagerState, bool> _f$isScanning = Field(
    'isScanning',
    _$isScanning,
    mode: FieldMode.member,
  );
  static bool _$isCancelled(VramEstimatorManagerState v) => v.isCancelled;
  static const Field<VramEstimatorManagerState, bool> _f$isCancelled = Field(
    'isCancelled',
    _$isCancelled,
    mode: FieldMode.member,
  );

  @override
  final MappableFields<VramEstimatorManagerState> fields = const {
    #modVramInfo: _f$modVramInfo,
    #lastUpdated: _f$lastUpdated,
    #isScanning: _f$isScanning,
    #isCancelled: _f$isCancelled,
  };

  static VramEstimatorManagerState _instantiate(DecodingData data) {
    return VramEstimatorManagerState(
      modVramInfo: data.dec(_f$modVramInfo),
      lastUpdated: data.dec(_f$lastUpdated),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static VramEstimatorManagerState fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<VramEstimatorManagerState>(map);
  }

  static VramEstimatorManagerState fromJson(String json) {
    return ensureInitialized().decodeJson<VramEstimatorManagerState>(json);
  }
}

mixin VramEstimatorManagerStateMappable {
  String toJson() {
    return VramEstimatorManagerStateMapper.ensureInitialized()
        .encodeJson<VramEstimatorManagerState>(
          this as VramEstimatorManagerState,
        );
  }

  Map<String, dynamic> toMap() {
    return VramEstimatorManagerStateMapper.ensureInitialized()
        .encodeMap<VramEstimatorManagerState>(
          this as VramEstimatorManagerState,
        );
  }

  VramEstimatorManagerStateCopyWith<
    VramEstimatorManagerState,
    VramEstimatorManagerState,
    VramEstimatorManagerState
  >
  get copyWith =>
      _VramEstimatorManagerStateCopyWithImpl<
        VramEstimatorManagerState,
        VramEstimatorManagerState
      >(this as VramEstimatorManagerState, $identity, $identity);
  @override
  String toString() {
    return VramEstimatorManagerStateMapper.ensureInitialized().stringifyValue(
      this as VramEstimatorManagerState,
    );
  }

  @override
  bool operator ==(Object other) {
    return VramEstimatorManagerStateMapper.ensureInitialized().equalsValue(
      this as VramEstimatorManagerState,
      other,
    );
  }

  @override
  int get hashCode {
    return VramEstimatorManagerStateMapper.ensureInitialized().hashValue(
      this as VramEstimatorManagerState,
    );
  }
}

extension VramEstimatorManagerStateValueCopy<$R, $Out>
    on ObjectCopyWith<$R, VramEstimatorManagerState, $Out> {
  VramEstimatorManagerStateCopyWith<$R, VramEstimatorManagerState, $Out>
  get $asVramEstimatorManagerState => $base.as(
    (v, t, t2) => _VramEstimatorManagerStateCopyWithImpl<$R, $Out>(v, t, t2),
  );
}

abstract class VramEstimatorManagerStateCopyWith<
  $R,
  $In extends VramEstimatorManagerState,
  $Out
>
    implements ClassCopyWith<$R, $In, $Out> {
  MapCopyWith<$R, String, VramMod, VramModCopyWith<$R, VramMod, VramMod>>
  get modVramInfo;
  $R call({Map<String, VramMod>? modVramInfo, DateTime? lastUpdated});
  VramEstimatorManagerStateCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _VramEstimatorManagerStateCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, VramEstimatorManagerState, $Out>
    implements
        VramEstimatorManagerStateCopyWith<$R, VramEstimatorManagerState, $Out> {
  _VramEstimatorManagerStateCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<VramEstimatorManagerState> $mapper =
      VramEstimatorManagerStateMapper.ensureInitialized();
  @override
  MapCopyWith<$R, String, VramMod, VramModCopyWith<$R, VramMod, VramMod>>
  get modVramInfo => MapCopyWith(
    $value.modVramInfo,
    (v, t) => v.copyWith.$chain(t),
    (v) => call(modVramInfo: v),
  );
  @override
  $R call({Map<String, VramMod>? modVramInfo, Object? lastUpdated = $none}) =>
      $apply(
        FieldCopyWithData({
          if (modVramInfo != null) #modVramInfo: modVramInfo,
          if (lastUpdated != $none) #lastUpdated: lastUpdated,
        }),
      );
  @override
  VramEstimatorManagerState $make(CopyWithData data) =>
      VramEstimatorManagerState(
        modVramInfo: data.get(#modVramInfo, or: $value.modVramInfo),
        lastUpdated: data.get(#lastUpdated, or: $value.lastUpdated),
      );

  @override
  VramEstimatorManagerStateCopyWith<$R2, VramEstimatorManagerState, $Out2>
  $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _VramEstimatorManagerStateCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

