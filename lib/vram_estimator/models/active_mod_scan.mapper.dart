// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'active_mod_scan.dart';

class ActiveModScanMapper extends ClassMapperBase<ActiveModScan> {
  ActiveModScanMapper._();

  static ActiveModScanMapper? _instance;
  static ActiveModScanMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ActiveModScanMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'ActiveModScan';

  static String _$modName(ActiveModScan v) => v.modName;
  static const Field<ActiveModScan, String> _f$modName = Field(
    'modName',
    _$modName,
  );
  static int _$filesScanned(ActiveModScan v) => v.filesScanned;
  static const Field<ActiveModScan, int> _f$filesScanned = Field(
    'filesScanned',
    _$filesScanned,
    opt: true,
    def: 0,
  );
  static int _$totalFiles(ActiveModScan v) => v.totalFiles;
  static const Field<ActiveModScan, int> _f$totalFiles = Field(
    'totalFiles',
    _$totalFiles,
    opt: true,
    def: 0,
  );
  static String? _$currentFilePath(ActiveModScan v) => v.currentFilePath;
  static const Field<ActiveModScan, String> _f$currentFilePath = Field(
    'currentFilePath',
    _$currentFilePath,
    opt: true,
  );

  @override
  final MappableFields<ActiveModScan> fields = const {
    #modName: _f$modName,
    #filesScanned: _f$filesScanned,
    #totalFiles: _f$totalFiles,
    #currentFilePath: _f$currentFilePath,
  };

  static ActiveModScan _instantiate(DecodingData data) {
    return ActiveModScan(
      modName: data.dec(_f$modName),
      filesScanned: data.dec(_f$filesScanned),
      totalFiles: data.dec(_f$totalFiles),
      currentFilePath: data.dec(_f$currentFilePath),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static ActiveModScan fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<ActiveModScan>(map);
  }

  static ActiveModScan fromJson(String json) {
    return ensureInitialized().decodeJson<ActiveModScan>(json);
  }
}

mixin ActiveModScanMappable {
  String toJson() {
    return ActiveModScanMapper.ensureInitialized().encodeJson<ActiveModScan>(
      this as ActiveModScan,
    );
  }

  Map<String, dynamic> toMap() {
    return ActiveModScanMapper.ensureInitialized().encodeMap<ActiveModScan>(
      this as ActiveModScan,
    );
  }

  ActiveModScanCopyWith<ActiveModScan, ActiveModScan, ActiveModScan>
  get copyWith => _ActiveModScanCopyWithImpl<ActiveModScan, ActiveModScan>(
    this as ActiveModScan,
    $identity,
    $identity,
  );
  @override
  String toString() {
    return ActiveModScanMapper.ensureInitialized().stringifyValue(
      this as ActiveModScan,
    );
  }

  @override
  bool operator ==(Object other) {
    return ActiveModScanMapper.ensureInitialized().equalsValue(
      this as ActiveModScan,
      other,
    );
  }

  @override
  int get hashCode {
    return ActiveModScanMapper.ensureInitialized().hashValue(
      this as ActiveModScan,
    );
  }
}

extension ActiveModScanValueCopy<$R, $Out>
    on ObjectCopyWith<$R, ActiveModScan, $Out> {
  ActiveModScanCopyWith<$R, ActiveModScan, $Out> get $asActiveModScan =>
      $base.as((v, t, t2) => _ActiveModScanCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class ActiveModScanCopyWith<$R, $In extends ActiveModScan, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({
    String? modName,
    int? filesScanned,
    int? totalFiles,
    String? currentFilePath,
  });
  ActiveModScanCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _ActiveModScanCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, ActiveModScan, $Out>
    implements ActiveModScanCopyWith<$R, ActiveModScan, $Out> {
  _ActiveModScanCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<ActiveModScan> $mapper =
      ActiveModScanMapper.ensureInitialized();
  @override
  $R call({
    String? modName,
    int? filesScanned,
    int? totalFiles,
    Object? currentFilePath = $none,
  }) => $apply(
    FieldCopyWithData({
      if (modName != null) #modName: modName,
      if (filesScanned != null) #filesScanned: filesScanned,
      if (totalFiles != null) #totalFiles: totalFiles,
      if (currentFilePath != $none) #currentFilePath: currentFilePath,
    }),
  );
  @override
  ActiveModScan $make(CopyWithData data) => ActiveModScan(
    modName: data.get(#modName, or: $value.modName),
    filesScanned: data.get(#filesScanned, or: $value.filesScanned),
    totalFiles: data.get(#totalFiles, or: $value.totalFiles),
    currentFilePath: data.get(#currentFilePath, or: $value.currentFilePath),
  );

  @override
  ActiveModScanCopyWith<$R2, ActiveModScan, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _ActiveModScanCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

