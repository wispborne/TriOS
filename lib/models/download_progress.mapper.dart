// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'download_progress.dart';

class TriOSDownloadProgressMapper
    extends ClassMapperBase<TriOSDownloadProgress> {
  TriOSDownloadProgressMapper._();

  static TriOSDownloadProgressMapper? _instance;
  static TriOSDownloadProgressMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = TriOSDownloadProgressMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'TriOSDownloadProgress';

  static int _$bytesReceived(TriOSDownloadProgress v) => v.bytesReceived;
  static const Field<TriOSDownloadProgress, int> _f$bytesReceived =
      Field('bytesReceived', _$bytesReceived);
  static int _$bytesTotal(TriOSDownloadProgress v) => v.bytesTotal;
  static const Field<TriOSDownloadProgress, int> _f$bytesTotal =
      Field('bytesTotal', _$bytesTotal);
  static bool _$isIndeterminate(TriOSDownloadProgress v) => v.isIndeterminate;
  static const Field<TriOSDownloadProgress, bool> _f$isIndeterminate =
      Field('isIndeterminate', _$isIndeterminate, opt: true, def: false);
  static String? _$customStatus(TriOSDownloadProgress v) => v.customStatus;
  static const Field<TriOSDownloadProgress, String> _f$customStatus =
      Field('customStatus', _$customStatus, opt: true);

  @override
  final MappableFields<TriOSDownloadProgress> fields = const {
    #bytesReceived: _f$bytesReceived,
    #bytesTotal: _f$bytesTotal,
    #isIndeterminate: _f$isIndeterminate,
    #customStatus: _f$customStatus,
  };

  static TriOSDownloadProgress _instantiate(DecodingData data) {
    return TriOSDownloadProgress(
        data.dec(_f$bytesReceived), data.dec(_f$bytesTotal),
        isIndeterminate: data.dec(_f$isIndeterminate),
        customStatus: data.dec(_f$customStatus));
  }

  @override
  final Function instantiate = _instantiate;

  static TriOSDownloadProgress fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<TriOSDownloadProgress>(map);
  }

  static TriOSDownloadProgress fromJson(String json) {
    return ensureInitialized().decodeJson<TriOSDownloadProgress>(json);
  }
}

mixin TriOSDownloadProgressMappable {
  String toJson() {
    return TriOSDownloadProgressMapper.ensureInitialized()
        .encodeJson<TriOSDownloadProgress>(this as TriOSDownloadProgress);
  }

  Map<String, dynamic> toMap() {
    return TriOSDownloadProgressMapper.ensureInitialized()
        .encodeMap<TriOSDownloadProgress>(this as TriOSDownloadProgress);
  }

  TriOSDownloadProgressCopyWith<TriOSDownloadProgress, TriOSDownloadProgress,
      TriOSDownloadProgress> get copyWith => _TriOSDownloadProgressCopyWithImpl<
          TriOSDownloadProgress, TriOSDownloadProgress>(
      this as TriOSDownloadProgress, $identity, $identity);
  @override
  String toString() {
    return TriOSDownloadProgressMapper.ensureInitialized()
        .stringifyValue(this as TriOSDownloadProgress);
  }

  @override
  bool operator ==(Object other) {
    return TriOSDownloadProgressMapper.ensureInitialized()
        .equalsValue(this as TriOSDownloadProgress, other);
  }

  @override
  int get hashCode {
    return TriOSDownloadProgressMapper.ensureInitialized()
        .hashValue(this as TriOSDownloadProgress);
  }
}

extension TriOSDownloadProgressValueCopy<$R, $Out>
    on ObjectCopyWith<$R, TriOSDownloadProgress, $Out> {
  TriOSDownloadProgressCopyWith<$R, TriOSDownloadProgress, $Out>
      get $asTriOSDownloadProgress => $base.as(
          (v, t, t2) => _TriOSDownloadProgressCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class TriOSDownloadProgressCopyWith<
    $R,
    $In extends TriOSDownloadProgress,
    $Out> implements ClassCopyWith<$R, $In, $Out> {
  $R call(
      {int? bytesReceived,
      int? bytesTotal,
      bool? isIndeterminate,
      String? customStatus});
  TriOSDownloadProgressCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
      Then<$Out2, $R2> t);
}

class _TriOSDownloadProgressCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, TriOSDownloadProgress, $Out>
    implements TriOSDownloadProgressCopyWith<$R, TriOSDownloadProgress, $Out> {
  _TriOSDownloadProgressCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<TriOSDownloadProgress> $mapper =
      TriOSDownloadProgressMapper.ensureInitialized();
  @override
  $R call(
          {int? bytesReceived,
          int? bytesTotal,
          bool? isIndeterminate,
          Object? customStatus = $none}) =>
      $apply(FieldCopyWithData({
        if (bytesReceived != null) #bytesReceived: bytesReceived,
        if (bytesTotal != null) #bytesTotal: bytesTotal,
        if (isIndeterminate != null) #isIndeterminate: isIndeterminate,
        if (customStatus != $none) #customStatus: customStatus
      }));
  @override
  TriOSDownloadProgress $make(CopyWithData data) => TriOSDownloadProgress(
      data.get(#bytesReceived, or: $value.bytesReceived),
      data.get(#bytesTotal, or: $value.bytesTotal),
      isIndeterminate: data.get(#isIndeterminate, or: $value.isIndeterminate),
      customStatus: data.get(#customStatus, or: $value.customStatus));

  @override
  TriOSDownloadProgressCopyWith<$R2, TriOSDownloadProgress, $Out2>
      $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
          _TriOSDownloadProgressCopyWithImpl<$R2, $Out2>($value, $cast, t);
}
