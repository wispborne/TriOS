// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'version_checker_info.dart';

class VersionCheckerInfoMapper extends ClassMapperBase<VersionCheckerInfo> {
  VersionCheckerInfoMapper._();

  static VersionCheckerInfoMapper? _instance;
  static VersionCheckerInfoMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = VersionCheckerInfoMapper._());
      VersionObjectMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'VersionCheckerInfo';

  static String? _$modName(VersionCheckerInfo v) => v.modName;
  static const Field<VersionCheckerInfo, String> _f$modName =
      Field('modName', _$modName, opt: true);
  static String? _$masterVersionFile(VersionCheckerInfo v) =>
      v.masterVersionFile;
  static const Field<VersionCheckerInfo, String> _f$masterVersionFile =
      Field('masterVersionFile', _$masterVersionFile, opt: true);
  static String? _$modNexusId(VersionCheckerInfo v) => v.modNexusId;
  static const Field<VersionCheckerInfo, String> _f$modNexusId =
      Field('modNexusId', _$modNexusId, opt: true);
  static String? _$modThreadId(VersionCheckerInfo v) => v.modThreadId;
  static const Field<VersionCheckerInfo, String> _f$modThreadId =
      Field('modThreadId', _$modThreadId, opt: true);
  static VersionObject? _$modVersion(VersionCheckerInfo v) => v.modVersion;
  static const Field<VersionCheckerInfo, VersionObject> _f$modVersion =
      Field('modVersion', _$modVersion, opt: true);
  static String? _$directDownloadURL(VersionCheckerInfo v) =>
      v.directDownloadURL;
  static const Field<VersionCheckerInfo, String> _f$directDownloadURL =
      Field('directDownloadURL', _$directDownloadURL, opt: true);
  static String? _$changelogURL(VersionCheckerInfo v) => v.changelogURL;
  static const Field<VersionCheckerInfo, String> _f$changelogURL =
      Field('changelogURL', _$changelogURL, opt: true);

  @override
  final MappableFields<VersionCheckerInfo> fields = const {
    #modName: _f$modName,
    #masterVersionFile: _f$masterVersionFile,
    #modNexusId: _f$modNexusId,
    #modThreadId: _f$modThreadId,
    #modVersion: _f$modVersion,
    #directDownloadURL: _f$directDownloadURL,
    #changelogURL: _f$changelogURL,
  };

  static VersionCheckerInfo _instantiate(DecodingData data) {
    return VersionCheckerInfo(
        modName: data.dec(_f$modName),
        masterVersionFile: data.dec(_f$masterVersionFile),
        modNexusId: data.dec(_f$modNexusId),
        modThreadId: data.dec(_f$modThreadId),
        modVersion: data.dec(_f$modVersion),
        directDownloadURL: data.dec(_f$directDownloadURL),
        changelogURL: data.dec(_f$changelogURL));
  }

  @override
  final Function instantiate = _instantiate;

  static VersionCheckerInfo fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<VersionCheckerInfo>(map);
  }

  static VersionCheckerInfo fromJson(String json) {
    return ensureInitialized().decodeJson<VersionCheckerInfo>(json);
  }
}

mixin VersionCheckerInfoMappable {
  String toJson() {
    return VersionCheckerInfoMapper.ensureInitialized()
        .encodeJson<VersionCheckerInfo>(this as VersionCheckerInfo);
  }

  Map<String, dynamic> toMap() {
    return VersionCheckerInfoMapper.ensureInitialized()
        .encodeMap<VersionCheckerInfo>(this as VersionCheckerInfo);
  }

  VersionCheckerInfoCopyWith<VersionCheckerInfo, VersionCheckerInfo,
          VersionCheckerInfo>
      get copyWith => _VersionCheckerInfoCopyWithImpl<VersionCheckerInfo,
          VersionCheckerInfo>(this as VersionCheckerInfo, $identity, $identity);
  @override
  String toString() {
    return VersionCheckerInfoMapper.ensureInitialized()
        .stringifyValue(this as VersionCheckerInfo);
  }

  @override
  bool operator ==(Object other) {
    return VersionCheckerInfoMapper.ensureInitialized()
        .equalsValue(this as VersionCheckerInfo, other);
  }

  @override
  int get hashCode {
    return VersionCheckerInfoMapper.ensureInitialized()
        .hashValue(this as VersionCheckerInfo);
  }
}

extension VersionCheckerInfoValueCopy<$R, $Out>
    on ObjectCopyWith<$R, VersionCheckerInfo, $Out> {
  VersionCheckerInfoCopyWith<$R, VersionCheckerInfo, $Out>
      get $asVersionCheckerInfo => $base.as(
          (v, t, t2) => _VersionCheckerInfoCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class VersionCheckerInfoCopyWith<$R, $In extends VersionCheckerInfo,
    $Out> implements ClassCopyWith<$R, $In, $Out> {
  VersionObjectCopyWith<$R, VersionObject, VersionObject>? get modVersion;
  $R call(
      {String? modName,
      String? masterVersionFile,
      String? modNexusId,
      String? modThreadId,
      VersionObject? modVersion,
      String? directDownloadURL,
      String? changelogURL});
  VersionCheckerInfoCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
      Then<$Out2, $R2> t);
}

class _VersionCheckerInfoCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, VersionCheckerInfo, $Out>
    implements VersionCheckerInfoCopyWith<$R, VersionCheckerInfo, $Out> {
  _VersionCheckerInfoCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<VersionCheckerInfo> $mapper =
      VersionCheckerInfoMapper.ensureInitialized();
  @override
  VersionObjectCopyWith<$R, VersionObject, VersionObject>? get modVersion =>
      $value.modVersion?.copyWith.$chain((v) => call(modVersion: v));
  @override
  $R call(
          {Object? modName = $none,
          Object? masterVersionFile = $none,
          Object? modNexusId = $none,
          Object? modThreadId = $none,
          Object? modVersion = $none,
          Object? directDownloadURL = $none,
          Object? changelogURL = $none}) =>
      $apply(FieldCopyWithData({
        if (modName != $none) #modName: modName,
        if (masterVersionFile != $none) #masterVersionFile: masterVersionFile,
        if (modNexusId != $none) #modNexusId: modNexusId,
        if (modThreadId != $none) #modThreadId: modThreadId,
        if (modVersion != $none) #modVersion: modVersion,
        if (directDownloadURL != $none) #directDownloadURL: directDownloadURL,
        if (changelogURL != $none) #changelogURL: changelogURL
      }));
  @override
  VersionCheckerInfo $make(CopyWithData data) => VersionCheckerInfo(
      modName: data.get(#modName, or: $value.modName),
      masterVersionFile:
          data.get(#masterVersionFile, or: $value.masterVersionFile),
      modNexusId: data.get(#modNexusId, or: $value.modNexusId),
      modThreadId: data.get(#modThreadId, or: $value.modThreadId),
      modVersion: data.get(#modVersion, or: $value.modVersion),
      directDownloadURL:
          data.get(#directDownloadURL, or: $value.directDownloadURL),
      changelogURL: data.get(#changelogURL, or: $value.changelogURL));

  @override
  VersionCheckerInfoCopyWith<$R2, VersionCheckerInfo, $Out2> $chain<$R2, $Out2>(
          Then<$Out2, $R2> t) =>
      _VersionCheckerInfoCopyWithImpl<$R2, $Out2>($value, $cast, t);
}
