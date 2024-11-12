// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'mod_info_json.dart';

class EnabledModsJsonModeMapper extends ClassMapperBase<EnabledModsJsonMode> {
  EnabledModsJsonModeMapper._();

  static EnabledModsJsonModeMapper? _instance;
  static EnabledModsJsonModeMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = EnabledModsJsonModeMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'EnabledModsJsonMode';

  static List<String> _$enabledMods(EnabledModsJsonMode v) => v.enabledMods;
  static const Field<EnabledModsJsonMode, List<String>> _f$enabledMods =
      Field('enabledMods', _$enabledMods);

  @override
  final MappableFields<EnabledModsJsonMode> fields = const {
    #enabledMods: _f$enabledMods,
  };

  static EnabledModsJsonMode _instantiate(DecodingData data) {
    return EnabledModsJsonMode(data.dec(_f$enabledMods));
  }

  @override
  final Function instantiate = _instantiate;

  static EnabledModsJsonMode fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<EnabledModsJsonMode>(map);
  }

  static EnabledModsJsonMode fromJson(String json) {
    return ensureInitialized().decodeJson<EnabledModsJsonMode>(json);
  }
}

mixin EnabledModsJsonModeMappable {
  String toJson() {
    return EnabledModsJsonModeMapper.ensureInitialized()
        .encodeJson<EnabledModsJsonMode>(this as EnabledModsJsonMode);
  }

  Map<String, dynamic> toMap() {
    return EnabledModsJsonModeMapper.ensureInitialized()
        .encodeMap<EnabledModsJsonMode>(this as EnabledModsJsonMode);
  }

  EnabledModsJsonModeCopyWith<EnabledModsJsonMode, EnabledModsJsonMode,
          EnabledModsJsonMode>
      get copyWith => _EnabledModsJsonModeCopyWithImpl(
          this as EnabledModsJsonMode, $identity, $identity);
  @override
  String toString() {
    return EnabledModsJsonModeMapper.ensureInitialized()
        .stringifyValue(this as EnabledModsJsonMode);
  }

  @override
  bool operator ==(Object other) {
    return EnabledModsJsonModeMapper.ensureInitialized()
        .equalsValue(this as EnabledModsJsonMode, other);
  }

  @override
  int get hashCode {
    return EnabledModsJsonModeMapper.ensureInitialized()
        .hashValue(this as EnabledModsJsonMode);
  }
}

extension EnabledModsJsonModeValueCopy<$R, $Out>
    on ObjectCopyWith<$R, EnabledModsJsonMode, $Out> {
  EnabledModsJsonModeCopyWith<$R, EnabledModsJsonMode, $Out>
      get $asEnabledModsJsonMode =>
          $base.as((v, t, t2) => _EnabledModsJsonModeCopyWithImpl(v, t, t2));
}

abstract class EnabledModsJsonModeCopyWith<$R, $In extends EnabledModsJsonMode,
    $Out> implements ClassCopyWith<$R, $In, $Out> {
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>> get enabledMods;
  $R call({List<String>? enabledMods});
  EnabledModsJsonModeCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
      Then<$Out2, $R2> t);
}

class _EnabledModsJsonModeCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, EnabledModsJsonMode, $Out>
    implements EnabledModsJsonModeCopyWith<$R, EnabledModsJsonMode, $Out> {
  _EnabledModsJsonModeCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<EnabledModsJsonMode> $mapper =
      EnabledModsJsonModeMapper.ensureInitialized();
  @override
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>>
      get enabledMods => ListCopyWith(
          $value.enabledMods,
          (v, t) => ObjectCopyWith(v, $identity, t),
          (v) => call(enabledMods: v));
  @override
  $R call({List<String>? enabledMods}) => $apply(
      FieldCopyWithData({if (enabledMods != null) #enabledMods: enabledMods}));
  @override
  EnabledModsJsonMode $make(CopyWithData data) =>
      EnabledModsJsonMode(data.get(#enabledMods, or: $value.enabledMods));

  @override
  EnabledModsJsonModeCopyWith<$R2, EnabledModsJsonMode, $Out2>
      $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
          _EnabledModsJsonModeCopyWithImpl($value, $cast, t);
}

class ModInfoJsonMapper extends ClassMapperBase<ModInfoJson> {
  ModInfoJsonMapper._();

  static ModInfoJsonMapper? _instance;
  static ModInfoJsonMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ModInfoJsonMapper._());
      VersionMapper.ensureInitialized();
      DependencyMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'ModInfoJson';

  static String _$id(ModInfoJson v) => v.id;
  static const Field<ModInfoJson, String> _f$id = Field('id', _$id);
  static String? _$name(ModInfoJson v) => v.name;
  static const Field<ModInfoJson, String> _f$name =
      Field('name', _$name, opt: true);
  static Version? _$version(ModInfoJson v) => v.version;
  static const Field<ModInfoJson, Version> _f$version =
      Field('version', _$version, opt: true, hook: NullableVersionHook());
  static String? _$author(ModInfoJson v) => v.author;
  static const Field<ModInfoJson, String> _f$author =
      Field('author', _$author, opt: true);
  static String? _$gameVersion(ModInfoJson v) => v.gameVersion;
  static const Field<ModInfoJson, String> _f$gameVersion =
      Field('gameVersion', _$gameVersion, opt: true);
  static List<Dependency> _$dependencies(ModInfoJson v) => v.dependencies;
  static const Field<ModInfoJson, List<Dependency>> _f$dependencies =
      Field('dependencies', _$dependencies, opt: true, def: const []);
  static String? _$description(ModInfoJson v) => v.description;
  static const Field<ModInfoJson, String> _f$description =
      Field('description', _$description, opt: true);
  static String? _$originalGameVersion(ModInfoJson v) => v.originalGameVersion;
  static const Field<ModInfoJson, String> _f$originalGameVersion =
      Field('originalGameVersion', _$originalGameVersion, opt: true);
  static bool _$utility(ModInfoJson v) => v.utility;
  static const Field<ModInfoJson, bool> _f$utility =
      Field('utility', _$utility, opt: true, def: false);
  static bool _$totalConversion(ModInfoJson v) => v.totalConversion;
  static const Field<ModInfoJson, bool> _f$totalConversion =
      Field('totalConversion', _$totalConversion, opt: true, def: false);

  @override
  final MappableFields<ModInfoJson> fields = const {
    #id: _f$id,
    #name: _f$name,
    #version: _f$version,
    #author: _f$author,
    #gameVersion: _f$gameVersion,
    #dependencies: _f$dependencies,
    #description: _f$description,
    #originalGameVersion: _f$originalGameVersion,
    #utility: _f$utility,
    #totalConversion: _f$totalConversion,
  };

  static ModInfoJson _instantiate(DecodingData data) {
    return ModInfoJson(data.dec(_f$id),
        name: data.dec(_f$name),
        version: data.dec(_f$version),
        author: data.dec(_f$author),
        gameVersion: data.dec(_f$gameVersion),
        dependencies: data.dec(_f$dependencies),
        description: data.dec(_f$description),
        originalGameVersion: data.dec(_f$originalGameVersion),
        utility: data.dec(_f$utility),
        totalConversion: data.dec(_f$totalConversion));
  }

  @override
  final Function instantiate = _instantiate;

  static ModInfoJson fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<ModInfoJson>(map);
  }

  static ModInfoJson fromJson(String json) {
    return ensureInitialized().decodeJson<ModInfoJson>(json);
  }
}

mixin ModInfoJsonMappable {
  String toJson() {
    return ModInfoJsonMapper.ensureInitialized()
        .encodeJson<ModInfoJson>(this as ModInfoJson);
  }

  Map<String, dynamic> toMap() {
    return ModInfoJsonMapper.ensureInitialized()
        .encodeMap<ModInfoJson>(this as ModInfoJson);
  }

  ModInfoJsonCopyWith<ModInfoJson, ModInfoJson, ModInfoJson> get copyWith =>
      _ModInfoJsonCopyWithImpl(this as ModInfoJson, $identity, $identity);
  @override
  String toString() {
    return ModInfoJsonMapper.ensureInitialized()
        .stringifyValue(this as ModInfoJson);
  }

  @override
  bool operator ==(Object other) {
    return ModInfoJsonMapper.ensureInitialized()
        .equalsValue(this as ModInfoJson, other);
  }

  @override
  int get hashCode {
    return ModInfoJsonMapper.ensureInitialized().hashValue(this as ModInfoJson);
  }
}

extension ModInfoJsonValueCopy<$R, $Out>
    on ObjectCopyWith<$R, ModInfoJson, $Out> {
  ModInfoJsonCopyWith<$R, ModInfoJson, $Out> get $asModInfoJson =>
      $base.as((v, t, t2) => _ModInfoJsonCopyWithImpl(v, t, t2));
}

abstract class ModInfoJsonCopyWith<$R, $In extends ModInfoJson, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  VersionCopyWith<$R, Version, Version>? get version;
  ListCopyWith<$R, Dependency, DependencyCopyWith<$R, Dependency, Dependency>>
      get dependencies;
  $R call(
      {String? id,
      String? name,
      Version? version,
      String? author,
      String? gameVersion,
      List<Dependency>? dependencies,
      String? description,
      String? originalGameVersion,
      bool? utility,
      bool? totalConversion});
  ModInfoJsonCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _ModInfoJsonCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, ModInfoJson, $Out>
    implements ModInfoJsonCopyWith<$R, ModInfoJson, $Out> {
  _ModInfoJsonCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<ModInfoJson> $mapper =
      ModInfoJsonMapper.ensureInitialized();
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
          Object? author = $none,
          Object? gameVersion = $none,
          List<Dependency>? dependencies,
          Object? description = $none,
          Object? originalGameVersion = $none,
          bool? utility,
          bool? totalConversion}) =>
      $apply(FieldCopyWithData({
        if (id != null) #id: id,
        if (name != $none) #name: name,
        if (version != $none) #version: version,
        if (author != $none) #author: author,
        if (gameVersion != $none) #gameVersion: gameVersion,
        if (dependencies != null) #dependencies: dependencies,
        if (description != $none) #description: description,
        if (originalGameVersion != $none)
          #originalGameVersion: originalGameVersion,
        if (utility != null) #utility: utility,
        if (totalConversion != null) #totalConversion: totalConversion
      }));
  @override
  ModInfoJson $make(CopyWithData data) => ModInfoJson(
      data.get(#id, or: $value.id),
      name: data.get(#name, or: $value.name),
      version: data.get(#version, or: $value.version),
      author: data.get(#author, or: $value.author),
      gameVersion: data.get(#gameVersion, or: $value.gameVersion),
      dependencies: data.get(#dependencies, or: $value.dependencies),
      description: data.get(#description, or: $value.description),
      originalGameVersion:
          data.get(#originalGameVersion, or: $value.originalGameVersion),
      utility: data.get(#utility, or: $value.utility),
      totalConversion: data.get(#totalConversion, or: $value.totalConversion));

  @override
  ModInfoJsonCopyWith<$R2, ModInfoJson, $Out2> $chain<$R2, $Out2>(
          Then<$Out2, $R2> t) =>
      _ModInfoJsonCopyWithImpl($value, $cast, t);
}

class DependencyMapper extends ClassMapperBase<Dependency> {
  DependencyMapper._();

  static DependencyMapper? _instance;
  static DependencyMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = DependencyMapper._());
      VersionMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'Dependency';

  static String? _$id(Dependency v) => v.id;
  static const Field<Dependency, String> _f$id = Field('id', _$id, opt: true);
  static String? _$name(Dependency v) => v.name;
  static const Field<Dependency, String> _f$name =
      Field('name', _$name, opt: true);
  static Version? _$version(Dependency v) => v.version;
  static const Field<Dependency, Version> _f$version =
      Field('version', _$version, opt: true, hook: NullableVersionHook());

  @override
  final MappableFields<Dependency> fields = const {
    #id: _f$id,
    #name: _f$name,
    #version: _f$version,
  };

  static Dependency _instantiate(DecodingData data) {
    return Dependency(
        id: data.dec(_f$id),
        name: data.dec(_f$name),
        version: data.dec(_f$version));
  }

  @override
  final Function instantiate = _instantiate;

  static Dependency fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<Dependency>(map);
  }

  static Dependency fromJson(String json) {
    return ensureInitialized().decodeJson<Dependency>(json);
  }
}

mixin DependencyMappable {
  String toJson() {
    return DependencyMapper.ensureInitialized()
        .encodeJson<Dependency>(this as Dependency);
  }

  Map<String, dynamic> toMap() {
    return DependencyMapper.ensureInitialized()
        .encodeMap<Dependency>(this as Dependency);
  }

  DependencyCopyWith<Dependency, Dependency, Dependency> get copyWith =>
      _DependencyCopyWithImpl(this as Dependency, $identity, $identity);
  @override
  String toString() {
    return DependencyMapper.ensureInitialized()
        .stringifyValue(this as Dependency);
  }

  @override
  bool operator ==(Object other) {
    return DependencyMapper.ensureInitialized()
        .equalsValue(this as Dependency, other);
  }

  @override
  int get hashCode {
    return DependencyMapper.ensureInitialized().hashValue(this as Dependency);
  }
}

extension DependencyValueCopy<$R, $Out>
    on ObjectCopyWith<$R, Dependency, $Out> {
  DependencyCopyWith<$R, Dependency, $Out> get $asDependency =>
      $base.as((v, t, t2) => _DependencyCopyWithImpl(v, t, t2));
}

abstract class DependencyCopyWith<$R, $In extends Dependency, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  VersionCopyWith<$R, Version, Version>? get version;
  $R call({String? id, String? name, Version? version});
  DependencyCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _DependencyCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, Dependency, $Out>
    implements DependencyCopyWith<$R, Dependency, $Out> {
  _DependencyCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<Dependency> $mapper =
      DependencyMapper.ensureInitialized();
  @override
  VersionCopyWith<$R, Version, Version>? get version =>
      $value.version?.copyWith.$chain((v) => call(version: v));
  @override
  $R call(
          {Object? id = $none,
          Object? name = $none,
          Object? version = $none}) =>
      $apply(FieldCopyWithData({
        if (id != $none) #id: id,
        if (name != $none) #name: name,
        if (version != $none) #version: version
      }));
  @override
  Dependency $make(CopyWithData data) => Dependency(
      id: data.get(#id, or: $value.id),
      name: data.get(#name, or: $value.name),
      version: data.get(#version, or: $value.version));

  @override
  DependencyCopyWith<$R2, Dependency, $Out2> $chain<$R2, $Out2>(
          Then<$Out2, $R2> t) =>
      _DependencyCopyWithImpl($value, $cast, t);
}

class VersionObjectMapper extends ClassMapperBase<VersionObject> {
  VersionObjectMapper._();

  static VersionObjectMapper? _instance;
  static VersionObjectMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = VersionObjectMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'VersionObject';

  static dynamic _$major(VersionObject v) => v.major;
  static const Field<VersionObject, dynamic> _f$major = Field('major', _$major);
  static dynamic _$minor(VersionObject v) => v.minor;
  static const Field<VersionObject, dynamic> _f$minor = Field('minor', _$minor);
  static dynamic _$patch(VersionObject v) => v.patch;
  static const Field<VersionObject, dynamic> _f$patch = Field('patch', _$patch);

  @override
  final MappableFields<VersionObject> fields = const {
    #major: _f$major,
    #minor: _f$minor,
    #patch: _f$patch,
  };

  static VersionObject _instantiate(DecodingData data) {
    return VersionObject(
        data.dec(_f$major), data.dec(_f$minor), data.dec(_f$patch));
  }

  @override
  final Function instantiate = _instantiate;

  static VersionObject fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<VersionObject>(map);
  }

  static VersionObject fromJson(String json) {
    return ensureInitialized().decodeJson<VersionObject>(json);
  }
}

mixin VersionObjectMappable {
  String toJson() {
    return VersionObjectMapper.ensureInitialized()
        .encodeJson<VersionObject>(this as VersionObject);
  }

  Map<String, dynamic> toMap() {
    return VersionObjectMapper.ensureInitialized()
        .encodeMap<VersionObject>(this as VersionObject);
  }

  VersionObjectCopyWith<VersionObject, VersionObject, VersionObject>
      get copyWith => _VersionObjectCopyWithImpl(
          this as VersionObject, $identity, $identity);
  @override
  String toString() {
    return VersionObjectMapper.ensureInitialized()
        .stringifyValue(this as VersionObject);
  }

  @override
  bool operator ==(Object other) {
    return VersionObjectMapper.ensureInitialized()
        .equalsValue(this as VersionObject, other);
  }

  @override
  int get hashCode {
    return VersionObjectMapper.ensureInitialized()
        .hashValue(this as VersionObject);
  }
}

extension VersionObjectValueCopy<$R, $Out>
    on ObjectCopyWith<$R, VersionObject, $Out> {
  VersionObjectCopyWith<$R, VersionObject, $Out> get $asVersionObject =>
      $base.as((v, t, t2) => _VersionObjectCopyWithImpl(v, t, t2));
}

abstract class VersionObjectCopyWith<$R, $In extends VersionObject, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({dynamic major, dynamic minor, dynamic patch});
  VersionObjectCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _VersionObjectCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, VersionObject, $Out>
    implements VersionObjectCopyWith<$R, VersionObject, $Out> {
  _VersionObjectCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<VersionObject> $mapper =
      VersionObjectMapper.ensureInitialized();
  @override
  $R call(
          {Object? major = $none,
          Object? minor = $none,
          Object? patch = $none}) =>
      $apply(FieldCopyWithData({
        if (major != $none) #major: major,
        if (minor != $none) #minor: minor,
        if (patch != $none) #patch: patch
      }));
  @override
  VersionObject $make(CopyWithData data) => VersionObject(
      data.get(#major, or: $value.major),
      data.get(#minor, or: $value.minor),
      data.get(#patch, or: $value.patch));

  @override
  VersionObjectCopyWith<$R2, VersionObject, $Out2> $chain<$R2, $Out2>(
          Then<$Out2, $R2> t) =>
      _VersionObjectCopyWithImpl($value, $cast, t);
}
