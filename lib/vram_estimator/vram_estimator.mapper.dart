// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'vram_estimator.dart';

class VramEstimatorStateMapper extends ClassMapperBase<VramEstimatorState> {
  VramEstimatorStateMapper._();

  static VramEstimatorStateMapper? _instance;
  static VramEstimatorStateMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = VramEstimatorStateMapper._());
      VramModMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'VramEstimatorState';

  static Map<String, VramMod> _$modVramInfo(VramEstimatorState v) =>
      v.modVramInfo;
  static const Field<VramEstimatorState, Map<String, VramMod>> _f$modVramInfo =
      Field('modVramInfo', _$modVramInfo);
  static DateTime? _$lastUpdated(VramEstimatorState v) => v.lastUpdated;
  static const Field<VramEstimatorState, DateTime> _f$lastUpdated =
      Field('lastUpdated', _$lastUpdated);
  static bool _$isScanning(VramEstimatorState v) => v.isScanning;
  static const Field<VramEstimatorState, bool> _f$isScanning =
      Field('isScanning', _$isScanning, mode: FieldMode.member);
  static bool _$isCancelled(VramEstimatorState v) => v.isCancelled;
  static const Field<VramEstimatorState, bool> _f$isCancelled =
      Field('isCancelled', _$isCancelled, mode: FieldMode.member);

  @override
  final MappableFields<VramEstimatorState> fields = const {
    #modVramInfo: _f$modVramInfo,
    #lastUpdated: _f$lastUpdated,
    #isScanning: _f$isScanning,
    #isCancelled: _f$isCancelled,
  };

  static VramEstimatorState _instantiate(DecodingData data) {
    return VramEstimatorState(
        modVramInfo: data.dec(_f$modVramInfo),
        lastUpdated: data.dec(_f$lastUpdated));
  }

  @override
  final Function instantiate = _instantiate;

  static VramEstimatorState fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<VramEstimatorState>(map);
  }

  static VramEstimatorState fromJson(String json) {
    return ensureInitialized().decodeJson<VramEstimatorState>(json);
  }
}

mixin VramEstimatorStateMappable {
  String toJson() {
    return VramEstimatorStateMapper.ensureInitialized()
        .encodeJson<VramEstimatorState>(this as VramEstimatorState);
  }

  Map<String, dynamic> toMap() {
    return VramEstimatorStateMapper.ensureInitialized()
        .encodeMap<VramEstimatorState>(this as VramEstimatorState);
  }

  VramEstimatorStateCopyWith<VramEstimatorState, VramEstimatorState,
          VramEstimatorState>
      get copyWith => _VramEstimatorStateCopyWithImpl<VramEstimatorState,
          VramEstimatorState>(this as VramEstimatorState, $identity, $identity);
  @override
  String toString() {
    return VramEstimatorStateMapper.ensureInitialized()
        .stringifyValue(this as VramEstimatorState);
  }

  @override
  bool operator ==(Object other) {
    return VramEstimatorStateMapper.ensureInitialized()
        .equalsValue(this as VramEstimatorState, other);
  }

  @override
  int get hashCode {
    return VramEstimatorStateMapper.ensureInitialized()
        .hashValue(this as VramEstimatorState);
  }
}

extension VramEstimatorStateValueCopy<$R, $Out>
    on ObjectCopyWith<$R, VramEstimatorState, $Out> {
  VramEstimatorStateCopyWith<$R, VramEstimatorState, $Out>
      get $asVramEstimatorState => $base.as(
          (v, t, t2) => _VramEstimatorStateCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class VramEstimatorStateCopyWith<$R, $In extends VramEstimatorState,
    $Out> implements ClassCopyWith<$R, $In, $Out> {
  MapCopyWith<$R, String, VramMod, VramModCopyWith<$R, VramMod, VramMod>>
      get modVramInfo;
  $R call({Map<String, VramMod>? modVramInfo, DateTime? lastUpdated});
  VramEstimatorStateCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
      Then<$Out2, $R2> t);
}

class _VramEstimatorStateCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, VramEstimatorState, $Out>
    implements VramEstimatorStateCopyWith<$R, VramEstimatorState, $Out> {
  _VramEstimatorStateCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<VramEstimatorState> $mapper =
      VramEstimatorStateMapper.ensureInitialized();
  @override
  MapCopyWith<$R, String, VramMod, VramModCopyWith<$R, VramMod, VramMod>>
      get modVramInfo => MapCopyWith($value.modVramInfo,
          (v, t) => v.copyWith.$chain(t), (v) => call(modVramInfo: v));
  @override
  $R call({Map<String, VramMod>? modVramInfo, Object? lastUpdated = $none}) =>
      $apply(FieldCopyWithData({
        if (modVramInfo != null) #modVramInfo: modVramInfo,
        if (lastUpdated != $none) #lastUpdated: lastUpdated
      }));
  @override
  VramEstimatorState $make(CopyWithData data) => VramEstimatorState(
      modVramInfo: data.get(#modVramInfo, or: $value.modVramInfo),
      lastUpdated: data.get(#lastUpdated, or: $value.lastUpdated));

  @override
  VramEstimatorStateCopyWith<$R2, VramEstimatorState, $Out2> $chain<$R2, $Out2>(
          Then<$Out2, $R2> t) =>
      _VramEstimatorStateCopyWithImpl<$R2, $Out2>($value, $cast, t);
}
