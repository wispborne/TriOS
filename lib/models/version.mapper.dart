// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'version.dart';

class VersionMapper extends ClassMapperBase<Version> {
  VersionMapper._();

  static VersionMapper? _instance;
  static VersionMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = VersionMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'Version';

  static String? _$raw(Version v) => v.raw;
  static const Field<Version, String> _f$raw = Field('raw', _$raw, opt: true);
  static String _$major(Version v) => v.major;
  static const Field<Version, String> _f$major = Field(
    'major',
    _$major,
    opt: true,
    def: "0",
  );
  static String _$minor(Version v) => v.minor;
  static const Field<Version, String> _f$minor = Field(
    'minor',
    _$minor,
    opt: true,
    def: "0",
  );
  static String _$patch(Version v) => v.patch;
  static const Field<Version, String> _f$patch = Field(
    'patch',
    _$patch,
    opt: true,
    def: "0",
  );
  static String? _$build(Version v) => v.build;
  static const Field<Version, String> _f$build = Field(
    'build',
    _$build,
    opt: true,
  );

  @override
  final MappableFields<Version> fields = const {
    #raw: _f$raw,
    #major: _f$major,
    #minor: _f$minor,
    #patch: _f$patch,
    #build: _f$build,
  };

  static Version _instantiate(DecodingData data) {
    return Version(
      raw: data.dec(_f$raw),
      major: data.dec(_f$major),
      minor: data.dec(_f$minor),
      patch: data.dec(_f$patch),
      build: data.dec(_f$build),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static Version fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<Version>(map);
  }

  static Version fromJson(String json) {
    return ensureInitialized().decodeJson<Version>(json);
  }
}

mixin VersionMappable {
  String toJson() {
    return VersionMapper.ensureInitialized().encodeJson<Version>(
      this as Version,
    );
  }

  Map<String, dynamic> toMap() {
    return VersionMapper.ensureInitialized().encodeMap<Version>(
      this as Version,
    );
  }

  VersionCopyWith<Version, Version, Version> get copyWith =>
      _VersionCopyWithImpl<Version, Version>(
        this as Version,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return VersionMapper.ensureInitialized().stringifyValue(this as Version);
  }

  @override
  bool operator ==(Object other) {
    return VersionMapper.ensureInitialized().equalsValue(
      this as Version,
      other,
    );
  }

  @override
  int get hashCode {
    return VersionMapper.ensureInitialized().hashValue(this as Version);
  }
}

extension VersionValueCopy<$R, $Out> on ObjectCopyWith<$R, Version, $Out> {
  VersionCopyWith<$R, Version, $Out> get $asVersion =>
      $base.as((v, t, t2) => _VersionCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class VersionCopyWith<$R, $In extends Version, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({
    String? raw,
    String? major,
    String? minor,
    String? patch,
    String? build,
  });
  VersionCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _VersionCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, Version, $Out>
    implements VersionCopyWith<$R, Version, $Out> {
  _VersionCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<Version> $mapper =
      VersionMapper.ensureInitialized();
  @override
  $R call({
    Object? raw = $none,
    String? major,
    String? minor,
    String? patch,
    Object? build = $none,
  }) => $apply(
    FieldCopyWithData({
      if (raw != $none) #raw: raw,
      if (major != null) #major: major,
      if (minor != null) #minor: minor,
      if (patch != null) #patch: patch,
      if (build != $none) #build: build,
    }),
  );
  @override
  Version $make(CopyWithData data) => Version(
    raw: data.get(#raw, or: $value.raw),
    major: data.get(#major, or: $value.major),
    minor: data.get(#minor, or: $value.minor),
    patch: data.get(#patch, or: $value.patch),
    build: data.get(#build, or: $value.build),
  );

  @override
  VersionCopyWith<$R2, Version, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _VersionCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

