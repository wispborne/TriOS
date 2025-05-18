// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'mod_profile.dart';

class ModProfilesMapper extends ClassMapperBase<ModProfiles> {
  ModProfilesMapper._();

  static ModProfilesMapper? _instance;
  static ModProfilesMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ModProfilesMapper._());
      ModProfileMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'ModProfiles';

  static List<ModProfile> _$modProfiles(ModProfiles v) => v.modProfiles;
  static const Field<ModProfiles, List<ModProfile>> _f$modProfiles =
      Field('modProfiles', _$modProfiles);

  @override
  final MappableFields<ModProfiles> fields = const {
    #modProfiles: _f$modProfiles,
  };

  static ModProfiles _instantiate(DecodingData data) {
    return ModProfiles(modProfiles: data.dec(_f$modProfiles));
  }

  @override
  final Function instantiate = _instantiate;

  static ModProfiles fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<ModProfiles>(map);
  }

  static ModProfiles fromJson(String json) {
    return ensureInitialized().decodeJson<ModProfiles>(json);
  }
}

mixin ModProfilesMappable {
  String toJson() {
    return ModProfilesMapper.ensureInitialized()
        .encodeJson<ModProfiles>(this as ModProfiles);
  }

  Map<String, dynamic> toMap() {
    return ModProfilesMapper.ensureInitialized()
        .encodeMap<ModProfiles>(this as ModProfiles);
  }

  ModProfilesCopyWith<ModProfiles, ModProfiles, ModProfiles> get copyWith =>
      _ModProfilesCopyWithImpl<ModProfiles, ModProfiles>(
          this as ModProfiles, $identity, $identity);
  @override
  String toString() {
    return ModProfilesMapper.ensureInitialized()
        .stringifyValue(this as ModProfiles);
  }

  @override
  bool operator ==(Object other) {
    return ModProfilesMapper.ensureInitialized()
        .equalsValue(this as ModProfiles, other);
  }

  @override
  int get hashCode {
    return ModProfilesMapper.ensureInitialized().hashValue(this as ModProfiles);
  }
}

extension ModProfilesValueCopy<$R, $Out>
    on ObjectCopyWith<$R, ModProfiles, $Out> {
  ModProfilesCopyWith<$R, ModProfiles, $Out> get $asModProfiles =>
      $base.as((v, t, t2) => _ModProfilesCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class ModProfilesCopyWith<$R, $In extends ModProfiles, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  ListCopyWith<$R, ModProfile, ModProfileCopyWith<$R, ModProfile, ModProfile>>
      get modProfiles;
  $R call({List<ModProfile>? modProfiles});
  ModProfilesCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _ModProfilesCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, ModProfiles, $Out>
    implements ModProfilesCopyWith<$R, ModProfiles, $Out> {
  _ModProfilesCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<ModProfiles> $mapper =
      ModProfilesMapper.ensureInitialized();
  @override
  ListCopyWith<$R, ModProfile, ModProfileCopyWith<$R, ModProfile, ModProfile>>
      get modProfiles => ListCopyWith($value.modProfiles,
          (v, t) => v.copyWith.$chain(t), (v) => call(modProfiles: v));
  @override
  $R call({List<ModProfile>? modProfiles}) => $apply(
      FieldCopyWithData({if (modProfiles != null) #modProfiles: modProfiles}));
  @override
  ModProfiles $make(CopyWithData data) =>
      ModProfiles(modProfiles: data.get(#modProfiles, or: $value.modProfiles));

  @override
  ModProfilesCopyWith<$R2, ModProfiles, $Out2> $chain<$R2, $Out2>(
          Then<$Out2, $R2> t) =>
      _ModProfilesCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class ModProfileMapper extends ClassMapperBase<ModProfile> {
  ModProfileMapper._();

  static ModProfileMapper? _instance;
  static ModProfileMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ModProfileMapper._());
      ShallowModVariantMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'ModProfile';

  static String _$id(ModProfile v) => v.id;
  static const Field<ModProfile, String> _f$id = Field('id', _$id);
  static String _$name(ModProfile v) => v.name;
  static const Field<ModProfile, String> _f$name = Field('name', _$name);
  static String _$description(ModProfile v) => v.description;
  static const Field<ModProfile, String> _f$description =
      Field('description', _$description);
  static int _$sortOrder(ModProfile v) => v.sortOrder;
  static const Field<ModProfile, int> _f$sortOrder =
      Field('sortOrder', _$sortOrder);
  static List<ShallowModVariant> _$enabledModVariants(ModProfile v) =>
      v.enabledModVariants;
  static const Field<ModProfile, List<ShallowModVariant>>
      _f$enabledModVariants = Field('enabledModVariants', _$enabledModVariants);
  static DateTime? _$dateCreated(ModProfile v) => v.dateCreated;
  static const Field<ModProfile, DateTime> _f$dateCreated =
      Field('dateCreated', _$dateCreated, opt: true);
  static DateTime? _$dateModified(ModProfile v) => v.dateModified;
  static const Field<ModProfile, DateTime> _f$dateModified =
      Field('dateModified', _$dateModified, opt: true);

  @override
  final MappableFields<ModProfile> fields = const {
    #id: _f$id,
    #name: _f$name,
    #description: _f$description,
    #sortOrder: _f$sortOrder,
    #enabledModVariants: _f$enabledModVariants,
    #dateCreated: _f$dateCreated,
    #dateModified: _f$dateModified,
  };

  static ModProfile _instantiate(DecodingData data) {
    return ModProfile(
        id: data.dec(_f$id),
        name: data.dec(_f$name),
        description: data.dec(_f$description),
        sortOrder: data.dec(_f$sortOrder),
        enabledModVariants: data.dec(_f$enabledModVariants),
        dateCreated: data.dec(_f$dateCreated),
        dateModified: data.dec(_f$dateModified));
  }

  @override
  final Function instantiate = _instantiate;

  static ModProfile fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<ModProfile>(map);
  }

  static ModProfile fromJson(String json) {
    return ensureInitialized().decodeJson<ModProfile>(json);
  }
}

mixin ModProfileMappable {
  String toJson() {
    return ModProfileMapper.ensureInitialized()
        .encodeJson<ModProfile>(this as ModProfile);
  }

  Map<String, dynamic> toMap() {
    return ModProfileMapper.ensureInitialized()
        .encodeMap<ModProfile>(this as ModProfile);
  }

  ModProfileCopyWith<ModProfile, ModProfile, ModProfile> get copyWith =>
      _ModProfileCopyWithImpl<ModProfile, ModProfile>(
          this as ModProfile, $identity, $identity);
  @override
  String toString() {
    return ModProfileMapper.ensureInitialized()
        .stringifyValue(this as ModProfile);
  }

  @override
  bool operator ==(Object other) {
    return ModProfileMapper.ensureInitialized()
        .equalsValue(this as ModProfile, other);
  }

  @override
  int get hashCode {
    return ModProfileMapper.ensureInitialized().hashValue(this as ModProfile);
  }
}

extension ModProfileValueCopy<$R, $Out>
    on ObjectCopyWith<$R, ModProfile, $Out> {
  ModProfileCopyWith<$R, ModProfile, $Out> get $asModProfile =>
      $base.as((v, t, t2) => _ModProfileCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class ModProfileCopyWith<$R, $In extends ModProfile, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  ListCopyWith<$R, ShallowModVariant,
          ShallowModVariantCopyWith<$R, ShallowModVariant, ShallowModVariant>>
      get enabledModVariants;
  $R call(
      {String? id,
      String? name,
      String? description,
      int? sortOrder,
      List<ShallowModVariant>? enabledModVariants,
      DateTime? dateCreated,
      DateTime? dateModified});
  ModProfileCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _ModProfileCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, ModProfile, $Out>
    implements ModProfileCopyWith<$R, ModProfile, $Out> {
  _ModProfileCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<ModProfile> $mapper =
      ModProfileMapper.ensureInitialized();
  @override
  ListCopyWith<$R, ShallowModVariant,
          ShallowModVariantCopyWith<$R, ShallowModVariant, ShallowModVariant>>
      get enabledModVariants => ListCopyWith($value.enabledModVariants,
          (v, t) => v.copyWith.$chain(t), (v) => call(enabledModVariants: v));
  @override
  $R call(
          {String? id,
          String? name,
          String? description,
          int? sortOrder,
          List<ShallowModVariant>? enabledModVariants,
          Object? dateCreated = $none,
          Object? dateModified = $none}) =>
      $apply(FieldCopyWithData({
        if (id != null) #id: id,
        if (name != null) #name: name,
        if (description != null) #description: description,
        if (sortOrder != null) #sortOrder: sortOrder,
        if (enabledModVariants != null) #enabledModVariants: enabledModVariants,
        if (dateCreated != $none) #dateCreated: dateCreated,
        if (dateModified != $none) #dateModified: dateModified
      }));
  @override
  ModProfile $make(CopyWithData data) => ModProfile(
      id: data.get(#id, or: $value.id),
      name: data.get(#name, or: $value.name),
      description: data.get(#description, or: $value.description),
      sortOrder: data.get(#sortOrder, or: $value.sortOrder),
      enabledModVariants:
          data.get(#enabledModVariants, or: $value.enabledModVariants),
      dateCreated: data.get(#dateCreated, or: $value.dateCreated),
      dateModified: data.get(#dateModified, or: $value.dateModified));

  @override
  ModProfileCopyWith<$R2, ModProfile, $Out2> $chain<$R2, $Out2>(
          Then<$Out2, $R2> t) =>
      _ModProfileCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class ShallowModVariantMapper extends ClassMapperBase<ShallowModVariant> {
  ShallowModVariantMapper._();

  static ShallowModVariantMapper? _instance;
  static ShallowModVariantMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ShallowModVariantMapper._());
      VersionMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'ShallowModVariant';

  static String _$modId(ShallowModVariant v) => v.modId;
  static const Field<ShallowModVariant, String> _f$modId =
      Field('modId', _$modId);
  static String? _$modName(ShallowModVariant v) => v.modName;
  static const Field<ShallowModVariant, String> _f$modName =
      Field('modName', _$modName, opt: true);
  static String _$smolVariantId(ShallowModVariant v) => v.smolVariantId;
  static const Field<ShallowModVariant, String> _f$smolVariantId =
      Field('smolVariantId', _$smolVariantId);
  static Version? _$version(ShallowModVariant v) => v.version;
  static const Field<ShallowModVariant, Version> _f$version =
      Field('version', _$version, opt: true, hook: VersionHook());

  @override
  final MappableFields<ShallowModVariant> fields = const {
    #modId: _f$modId,
    #modName: _f$modName,
    #smolVariantId: _f$smolVariantId,
    #version: _f$version,
  };

  static ShallowModVariant _instantiate(DecodingData data) {
    return ShallowModVariant(
        modId: data.dec(_f$modId),
        modName: data.dec(_f$modName),
        smolVariantId: data.dec(_f$smolVariantId),
        version: data.dec(_f$version));
  }

  @override
  final Function instantiate = _instantiate;

  static ShallowModVariant fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<ShallowModVariant>(map);
  }

  static ShallowModVariant fromJson(String json) {
    return ensureInitialized().decodeJson<ShallowModVariant>(json);
  }
}

mixin ShallowModVariantMappable {
  String toJson() {
    return ShallowModVariantMapper.ensureInitialized()
        .encodeJson<ShallowModVariant>(this as ShallowModVariant);
  }

  Map<String, dynamic> toMap() {
    return ShallowModVariantMapper.ensureInitialized()
        .encodeMap<ShallowModVariant>(this as ShallowModVariant);
  }

  ShallowModVariantCopyWith<ShallowModVariant, ShallowModVariant,
          ShallowModVariant>
      get copyWith =>
          _ShallowModVariantCopyWithImpl<ShallowModVariant, ShallowModVariant>(
              this as ShallowModVariant, $identity, $identity);
  @override
  String toString() {
    return ShallowModVariantMapper.ensureInitialized()
        .stringifyValue(this as ShallowModVariant);
  }

  @override
  bool operator ==(Object other) {
    return ShallowModVariantMapper.ensureInitialized()
        .equalsValue(this as ShallowModVariant, other);
  }

  @override
  int get hashCode {
    return ShallowModVariantMapper.ensureInitialized()
        .hashValue(this as ShallowModVariant);
  }
}

extension ShallowModVariantValueCopy<$R, $Out>
    on ObjectCopyWith<$R, ShallowModVariant, $Out> {
  ShallowModVariantCopyWith<$R, ShallowModVariant, $Out>
      get $asShallowModVariant => $base
          .as((v, t, t2) => _ShallowModVariantCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class ShallowModVariantCopyWith<$R, $In extends ShallowModVariant,
    $Out> implements ClassCopyWith<$R, $In, $Out> {
  VersionCopyWith<$R, Version, Version>? get version;
  $R call(
      {String? modId,
      String? modName,
      String? smolVariantId,
      Version? version});
  ShallowModVariantCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
      Then<$Out2, $R2> t);
}

class _ShallowModVariantCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, ShallowModVariant, $Out>
    implements ShallowModVariantCopyWith<$R, ShallowModVariant, $Out> {
  _ShallowModVariantCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<ShallowModVariant> $mapper =
      ShallowModVariantMapper.ensureInitialized();
  @override
  VersionCopyWith<$R, Version, Version>? get version =>
      $value.version?.copyWith.$chain((v) => call(version: v));
  @override
  $R call(
          {String? modId,
          Object? modName = $none,
          String? smolVariantId,
          Object? version = $none}) =>
      $apply(FieldCopyWithData({
        if (modId != null) #modId: modId,
        if (modName != $none) #modName: modName,
        if (smolVariantId != null) #smolVariantId: smolVariantId,
        if (version != $none) #version: version
      }));
  @override
  ShallowModVariant $make(CopyWithData data) => ShallowModVariant(
      modId: data.get(#modId, or: $value.modId),
      modName: data.get(#modName, or: $value.modName),
      smolVariantId: data.get(#smolVariantId, or: $value.smolVariantId),
      version: data.get(#version, or: $value.version));

  @override
  ShallowModVariantCopyWith<$R2, ShallowModVariant, $Out2> $chain<$R2, $Out2>(
          Then<$Out2, $R2> t) =>
      _ShallowModVariantCopyWithImpl<$R2, $Out2>($value, $cast, t);
}
