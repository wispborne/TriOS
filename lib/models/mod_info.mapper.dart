// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'mod_info.dart';

class ModInfoMapper extends ClassMapperBase<ModInfo> {
  ModInfoMapper._();

  static ModInfoMapper? _instance;
  static ModInfoMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ModInfoMapper._());
      VersionMapper.ensureInitialized();
      DependencyMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'ModInfo';

  static String _$id(ModInfo v) => v.id;
  static const Field<ModInfo, String> _f$id = Field('id', _$id);
  static String? _$name(ModInfo v) => v.name;
  static const Field<ModInfo, String> _f$name =
      Field('name', _$name, opt: true);
  static Version? _$version(ModInfo v) => v.version;
  static const Field<ModInfo, Version> _f$version =
      Field('version', _$version, opt: true, hook: NullableVersionHook());
  static String? _$description(ModInfo v) => v.description;
  static const Field<ModInfo, String> _f$description =
      Field('description', _$description, opt: true);
  static String? _$gameVersion(ModInfo v) => v.gameVersion;
  static const Field<ModInfo, String> _f$gameVersion =
      Field('gameVersion', _$gameVersion, opt: true);
  static String? _$author(ModInfo v) => v.author;
  static const Field<ModInfo, String> _f$author =
      Field('author', _$author, opt: true);
  static List<Dependency> _$dependencies(ModInfo v) => v.dependencies;
  static const Field<ModInfo, List<Dependency>> _f$dependencies =
      Field('dependencies', _$dependencies, opt: true, def: const []);
  static String? _$originalGameVersion(ModInfo v) => v.originalGameVersion;
  static const Field<ModInfo, String> _f$originalGameVersion =
      Field('originalGameVersion', _$originalGameVersion, opt: true);
  static bool _$isUtility(ModInfo v) => v.isUtility;
  static const Field<ModInfo, bool> _f$isUtility =
      Field('isUtility', _$isUtility, opt: true, def: false);
  static bool _$isTotalConversion(ModInfo v) => v.isTotalConversion;
  static const Field<ModInfo, bool> _f$isTotalConversion =
      Field('isTotalConversion', _$isTotalConversion, opt: true, def: false);

  @override
  final MappableFields<ModInfo> fields = const {
    #id: _f$id,
    #name: _f$name,
    #version: _f$version,
    #description: _f$description,
    #gameVersion: _f$gameVersion,
    #author: _f$author,
    #dependencies: _f$dependencies,
    #originalGameVersion: _f$originalGameVersion,
    #isUtility: _f$isUtility,
    #isTotalConversion: _f$isTotalConversion,
  };

  static ModInfo _instantiate(DecodingData data) {
    return ModInfo(
        id: data.dec(_f$id),
        name: data.dec(_f$name),
        version: data.dec(_f$version),
        description: data.dec(_f$description),
        gameVersion: data.dec(_f$gameVersion),
        author: data.dec(_f$author),
        dependencies: data.dec(_f$dependencies),
        originalGameVersion: data.dec(_f$originalGameVersion),
        isUtility: data.dec(_f$isUtility),
        isTotalConversion: data.dec(_f$isTotalConversion));
  }

  @override
  final Function instantiate = _instantiate;

  static ModInfo fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<ModInfo>(map);
  }

  static ModInfo fromJson(String json) {
    return ensureInitialized().decodeJson<ModInfo>(json);
  }
}

mixin ModInfoMappable {
  String toJson() {
    return ModInfoMapper.ensureInitialized()
        .encodeJson<ModInfo>(this as ModInfo);
  }

  Map<String, dynamic> toMap() {
    return ModInfoMapper.ensureInitialized()
        .encodeMap<ModInfo>(this as ModInfo);
  }

  ModInfoCopyWith<ModInfo, ModInfo, ModInfo> get copyWith =>
      _ModInfoCopyWithImpl(this as ModInfo, $identity, $identity);
  @override
  String toString() {
    return ModInfoMapper.ensureInitialized().stringifyValue(this as ModInfo);
  }

  @override
  bool operator ==(Object other) {
    return ModInfoMapper.ensureInitialized()
        .equalsValue(this as ModInfo, other);
  }

  @override
  int get hashCode {
    return ModInfoMapper.ensureInitialized().hashValue(this as ModInfo);
  }
}

extension ModInfoValueCopy<$R, $Out> on ObjectCopyWith<$R, ModInfo, $Out> {
  ModInfoCopyWith<$R, ModInfo, $Out> get $asModInfo =>
      $base.as((v, t, t2) => _ModInfoCopyWithImpl(v, t, t2));
}

abstract class ModInfoCopyWith<$R, $In extends ModInfo, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  VersionCopyWith<$R, Version, Version>? get version;
  ListCopyWith<$R, Dependency, DependencyCopyWith<$R, Dependency, Dependency>>
      get dependencies;
  $R call(
      {String? id,
      String? name,
      Version? version,
      String? description,
      String? gameVersion,
      String? author,
      List<Dependency>? dependencies,
      String? originalGameVersion,
      bool? isUtility,
      bool? isTotalConversion});
  ModInfoCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _ModInfoCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, ModInfo, $Out>
    implements ModInfoCopyWith<$R, ModInfo, $Out> {
  _ModInfoCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<ModInfo> $mapper =
      ModInfoMapper.ensureInitialized();
  @override
  VersionCopyWith<$R, Version, Version>? get version =>
      $value.version?.copyWith.$chain((v) => call(version: v));
  @override
  ListCopyWith<$R, Dependency, DependencyCopyWith<$R, Dependency, Dependency>>
      get dependencies => ListCopyWith($value.dependencies,
          (v, t) => v.copyWith.$chain(t), (v) => call(dependencies: v));
  @override
  $R call(
          {String? id,
          Object? name = $none,
          Object? version = $none,
          Object? description = $none,
          Object? gameVersion = $none,
          Object? author = $none,
          List<Dependency>? dependencies,
          Object? originalGameVersion = $none,
          bool? isUtility,
          bool? isTotalConversion}) =>
      $apply(FieldCopyWithData({
        if (id != null) #id: id,
        if (name != $none) #name: name,
        if (version != $none) #version: version,
        if (description != $none) #description: description,
        if (gameVersion != $none) #gameVersion: gameVersion,
        if (author != $none) #author: author,
        if (dependencies != null) #dependencies: dependencies,
        if (originalGameVersion != $none)
          #originalGameVersion: originalGameVersion,
        if (isUtility != null) #isUtility: isUtility,
        if (isTotalConversion != null) #isTotalConversion: isTotalConversion
      }));
  @override
  ModInfo $make(CopyWithData data) => ModInfo(
      id: data.get(#id, or: $value.id),
      name: data.get(#name, or: $value.name),
      version: data.get(#version, or: $value.version),
      description: data.get(#description, or: $value.description),
      gameVersion: data.get(#gameVersion, or: $value.gameVersion),
      author: data.get(#author, or: $value.author),
      dependencies: data.get(#dependencies, or: $value.dependencies),
      originalGameVersion:
          data.get(#originalGameVersion, or: $value.originalGameVersion),
      isUtility: data.get(#isUtility, or: $value.isUtility),
      isTotalConversion:
          data.get(#isTotalConversion, or: $value.isTotalConversion));

  @override
  ModInfoCopyWith<$R2, ModInfo, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _ModInfoCopyWithImpl($value, $cast, t);
}
