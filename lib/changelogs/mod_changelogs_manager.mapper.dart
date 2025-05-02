// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'mod_changelogs_manager.dart';

class ModChangelogMapper extends ClassMapperBase<ModChangelog> {
  ModChangelogMapper._();

  static ModChangelogMapper? _instance;
  static ModChangelogMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ModChangelogMapper._());
      ChangelogVersionMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'ModChangelog';

  static String _$modId(ModChangelog v) => v.modId;
  static const Field<ModChangelog, String> _f$modId = Field('modId', _$modId);
  static String _$smolId(ModChangelog v) => v.smolId;
  static const Field<ModChangelog, String> _f$smolId =
      Field('smolId', _$smolId);
  static String _$changelog(ModChangelog v) => v.changelog;
  static const Field<ModChangelog, String> _f$changelog =
      Field('changelog', _$changelog);
  static String _$url(ModChangelog v) => v.url;
  static const Field<ModChangelog, String> _f$url = Field('url', _$url);
  static List<ChangelogVersion>? _$parsedVersions(ModChangelog v) =>
      v.parsedVersions;
  static const Field<ModChangelog, List<ChangelogVersion>> _f$parsedVersions =
      Field('parsedVersions', _$parsedVersions, opt: true);

  @override
  final MappableFields<ModChangelog> fields = const {
    #modId: _f$modId,
    #smolId: _f$smolId,
    #changelog: _f$changelog,
    #url: _f$url,
    #parsedVersions: _f$parsedVersions,
  };

  static ModChangelog _instantiate(DecodingData data) {
    return ModChangelog(
        modId: data.dec(_f$modId),
        smolId: data.dec(_f$smolId),
        changelog: data.dec(_f$changelog),
        url: data.dec(_f$url),
        parsedVersions: data.dec(_f$parsedVersions));
  }

  @override
  final Function instantiate = _instantiate;

  static ModChangelog fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<ModChangelog>(map);
  }

  static ModChangelog fromJson(String json) {
    return ensureInitialized().decodeJson<ModChangelog>(json);
  }
}

mixin ModChangelogMappable {
  String toJson() {
    return ModChangelogMapper.ensureInitialized()
        .encodeJson<ModChangelog>(this as ModChangelog);
  }

  Map<String, dynamic> toMap() {
    return ModChangelogMapper.ensureInitialized()
        .encodeMap<ModChangelog>(this as ModChangelog);
  }

  ModChangelogCopyWith<ModChangelog, ModChangelog, ModChangelog> get copyWith =>
      _ModChangelogCopyWithImpl(this as ModChangelog, $identity, $identity);
  @override
  String toString() {
    return ModChangelogMapper.ensureInitialized()
        .stringifyValue(this as ModChangelog);
  }

  @override
  bool operator ==(Object other) {
    return ModChangelogMapper.ensureInitialized()
        .equalsValue(this as ModChangelog, other);
  }

  @override
  int get hashCode {
    return ModChangelogMapper.ensureInitialized()
        .hashValue(this as ModChangelog);
  }
}

extension ModChangelogValueCopy<$R, $Out>
    on ObjectCopyWith<$R, ModChangelog, $Out> {
  ModChangelogCopyWith<$R, ModChangelog, $Out> get $asModChangelog =>
      $base.as((v, t, t2) => _ModChangelogCopyWithImpl(v, t, t2));
}

abstract class ModChangelogCopyWith<$R, $In extends ModChangelog, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  ListCopyWith<$R, ChangelogVersion,
          ChangelogVersionCopyWith<$R, ChangelogVersion, ChangelogVersion>>?
      get parsedVersions;
  $R call(
      {String? modId,
      String? smolId,
      String? changelog,
      String? url,
      List<ChangelogVersion>? parsedVersions});
  ModChangelogCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _ModChangelogCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, ModChangelog, $Out>
    implements ModChangelogCopyWith<$R, ModChangelog, $Out> {
  _ModChangelogCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<ModChangelog> $mapper =
      ModChangelogMapper.ensureInitialized();
  @override
  ListCopyWith<$R, ChangelogVersion,
          ChangelogVersionCopyWith<$R, ChangelogVersion, ChangelogVersion>>?
      get parsedVersions => $value.parsedVersions != null
          ? ListCopyWith($value.parsedVersions!, (v, t) => v.copyWith.$chain(t),
              (v) => call(parsedVersions: v))
          : null;
  @override
  $R call(
          {String? modId,
          String? smolId,
          String? changelog,
          String? url,
          Object? parsedVersions = $none}) =>
      $apply(FieldCopyWithData({
        if (modId != null) #modId: modId,
        if (smolId != null) #smolId: smolId,
        if (changelog != null) #changelog: changelog,
        if (url != null) #url: url,
        if (parsedVersions != $none) #parsedVersions: parsedVersions
      }));
  @override
  ModChangelog $make(CopyWithData data) => ModChangelog(
      modId: data.get(#modId, or: $value.modId),
      smolId: data.get(#smolId, or: $value.smolId),
      changelog: data.get(#changelog, or: $value.changelog),
      url: data.get(#url, or: $value.url),
      parsedVersions: data.get(#parsedVersions, or: $value.parsedVersions));

  @override
  ModChangelogCopyWith<$R2, ModChangelog, $Out2> $chain<$R2, $Out2>(
          Then<$Out2, $R2> t) =>
      _ModChangelogCopyWithImpl($value, $cast, t);
}

class ChangelogVersionMapper extends ClassMapperBase<ChangelogVersion> {
  ChangelogVersionMapper._();

  static ChangelogVersionMapper? _instance;
  static ChangelogVersionMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ChangelogVersionMapper._());
      VersionMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'ChangelogVersion';

  static Version _$version(ChangelogVersion v) => v.version;
  static const Field<ChangelogVersion, Version> _f$version =
      Field('version', _$version);
  static String _$changelog(ChangelogVersion v) => v.changelog;
  static const Field<ChangelogVersion, String> _f$changelog =
      Field('changelog', _$changelog);

  @override
  final MappableFields<ChangelogVersion> fields = const {
    #version: _f$version,
    #changelog: _f$changelog,
  };

  static ChangelogVersion _instantiate(DecodingData data) {
    return ChangelogVersion(data.dec(_f$version), data.dec(_f$changelog));
  }

  @override
  final Function instantiate = _instantiate;

  static ChangelogVersion fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<ChangelogVersion>(map);
  }

  static ChangelogVersion fromJson(String json) {
    return ensureInitialized().decodeJson<ChangelogVersion>(json);
  }
}

mixin ChangelogVersionMappable {
  String toJson() {
    return ChangelogVersionMapper.ensureInitialized()
        .encodeJson<ChangelogVersion>(this as ChangelogVersion);
  }

  Map<String, dynamic> toMap() {
    return ChangelogVersionMapper.ensureInitialized()
        .encodeMap<ChangelogVersion>(this as ChangelogVersion);
  }

  ChangelogVersionCopyWith<ChangelogVersion, ChangelogVersion, ChangelogVersion>
      get copyWith => _ChangelogVersionCopyWithImpl(
          this as ChangelogVersion, $identity, $identity);
  @override
  String toString() {
    return ChangelogVersionMapper.ensureInitialized()
        .stringifyValue(this as ChangelogVersion);
  }

  @override
  bool operator ==(Object other) {
    return ChangelogVersionMapper.ensureInitialized()
        .equalsValue(this as ChangelogVersion, other);
  }

  @override
  int get hashCode {
    return ChangelogVersionMapper.ensureInitialized()
        .hashValue(this as ChangelogVersion);
  }
}

extension ChangelogVersionValueCopy<$R, $Out>
    on ObjectCopyWith<$R, ChangelogVersion, $Out> {
  ChangelogVersionCopyWith<$R, ChangelogVersion, $Out>
      get $asChangelogVersion =>
          $base.as((v, t, t2) => _ChangelogVersionCopyWithImpl(v, t, t2));
}

abstract class ChangelogVersionCopyWith<$R, $In extends ChangelogVersion, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  VersionCopyWith<$R, Version, Version> get version;
  $R call({Version? version, String? changelog});
  ChangelogVersionCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
      Then<$Out2, $R2> t);
}

class _ChangelogVersionCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, ChangelogVersion, $Out>
    implements ChangelogVersionCopyWith<$R, ChangelogVersion, $Out> {
  _ChangelogVersionCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<ChangelogVersion> $mapper =
      ChangelogVersionMapper.ensureInitialized();
  @override
  VersionCopyWith<$R, Version, Version> get version =>
      $value.version.copyWith.$chain((v) => call(version: v));
  @override
  $R call({Version? version, String? changelog}) => $apply(FieldCopyWithData({
        if (version != null) #version: version,
        if (changelog != null) #changelog: changelog
      }));
  @override
  ChangelogVersion $make(CopyWithData data) => ChangelogVersion(
      data.get(#version, or: $value.version),
      data.get(#changelog, or: $value.changelog));

  @override
  ChangelogVersionCopyWith<$R2, ChangelogVersion, $Out2> $chain<$R2, $Out2>(
          Then<$Out2, $R2> t) =>
      _ChangelogVersionCopyWithImpl($value, $cast, t);
}
