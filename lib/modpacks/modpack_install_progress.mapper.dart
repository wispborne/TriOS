// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'modpack_install_progress.dart';

class ModpackInstallProgressMapper
    extends ClassMapperBase<ModpackInstallProgress> {
  ModpackInstallProgressMapper._();

  static ModpackInstallProgressMapper? _instance;
  static ModpackInstallProgressMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ModpackInstallProgressMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'ModpackInstallProgress';

  static int _$finishedCount(ModpackInstallProgress v) => v.finishedCount;
  static const Field<ModpackInstallProgress, int> _f$finishedCount = Field(
    'finishedCount',
    _$finishedCount,
  );
  static int _$totalCount(ModpackInstallProgress v) => v.totalCount;
  static const Field<ModpackInstallProgress, int> _f$totalCount = Field(
    'totalCount',
    _$totalCount,
  );

  @override
  final MappableFields<ModpackInstallProgress> fields = const {
    #finishedCount: _f$finishedCount,
    #totalCount: _f$totalCount,
  };

  static ModpackInstallProgress _instantiate(DecodingData data) {
    return ModpackInstallProgress(
      finishedCount: data.dec(_f$finishedCount),
      totalCount: data.dec(_f$totalCount),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static ModpackInstallProgress fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<ModpackInstallProgress>(map);
  }

  static ModpackInstallProgress fromJson(String json) {
    return ensureInitialized().decodeJson<ModpackInstallProgress>(json);
  }
}

mixin ModpackInstallProgressMappable {
  String toJson() {
    return ModpackInstallProgressMapper.ensureInitialized()
        .encodeJson<ModpackInstallProgress>(this as ModpackInstallProgress);
  }

  Map<String, dynamic> toMap() {
    return ModpackInstallProgressMapper.ensureInitialized()
        .encodeMap<ModpackInstallProgress>(this as ModpackInstallProgress);
  }

  ModpackInstallProgressCopyWith<
    ModpackInstallProgress,
    ModpackInstallProgress,
    ModpackInstallProgress
  >
  get copyWith =>
      _ModpackInstallProgressCopyWithImpl<
        ModpackInstallProgress,
        ModpackInstallProgress
      >(this as ModpackInstallProgress, $identity, $identity);
  @override
  String toString() {
    return ModpackInstallProgressMapper.ensureInitialized().stringifyValue(
      this as ModpackInstallProgress,
    );
  }

  @override
  bool operator ==(Object other) {
    return ModpackInstallProgressMapper.ensureInitialized().equalsValue(
      this as ModpackInstallProgress,
      other,
    );
  }

  @override
  int get hashCode {
    return ModpackInstallProgressMapper.ensureInitialized().hashValue(
      this as ModpackInstallProgress,
    );
  }
}

extension ModpackInstallProgressValueCopy<$R, $Out>
    on ObjectCopyWith<$R, ModpackInstallProgress, $Out> {
  ModpackInstallProgressCopyWith<$R, ModpackInstallProgress, $Out>
  get $asModpackInstallProgress => $base.as(
    (v, t, t2) => _ModpackInstallProgressCopyWithImpl<$R, $Out>(v, t, t2),
  );
}

abstract class ModpackInstallProgressCopyWith<
  $R,
  $In extends ModpackInstallProgress,
  $Out
>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({int? finishedCount, int? totalCount});
  ModpackInstallProgressCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _ModpackInstallProgressCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, ModpackInstallProgress, $Out>
    implements
        ModpackInstallProgressCopyWith<$R, ModpackInstallProgress, $Out> {
  _ModpackInstallProgressCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<ModpackInstallProgress> $mapper =
      ModpackInstallProgressMapper.ensureInitialized();
  @override
  $R call({int? finishedCount, int? totalCount}) => $apply(
    FieldCopyWithData({
      if (finishedCount != null) #finishedCount: finishedCount,
      if (totalCount != null) #totalCount: totalCount,
    }),
  );
  @override
  ModpackInstallProgress $make(CopyWithData data) => ModpackInstallProgress(
    finishedCount: data.get(#finishedCount, or: $value.finishedCount),
    totalCount: data.get(#totalCount, or: $value.totalCount),
  );

  @override
  ModpackInstallProgressCopyWith<$R2, ModpackInstallProgress, $Out2>
  $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _ModpackInstallProgressCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

