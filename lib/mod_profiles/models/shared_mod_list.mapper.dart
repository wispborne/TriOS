// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'shared_mod_list.dart';

class SharedModListMapper extends ClassMapperBase<SharedModList> {
  SharedModListMapper._();

  static SharedModListMapper? _instance;
  static SharedModListMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = SharedModListMapper._());
      SharedModVariantMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'SharedModList';

  static String? _$id(SharedModList v) => v.id;
  static const Field<SharedModList, String> _f$id = Field(
    'id',
    _$id,
    opt: true,
  );
  static String? _$name(SharedModList v) => v.name;
  static const Field<SharedModList, String> _f$name = Field(
    'name',
    _$name,
    opt: true,
  );
  static String? _$description(SharedModList v) => v.description;
  static const Field<SharedModList, String> _f$description = Field(
    'description',
    _$description,
    opt: true,
  );
  static List<SharedModVariant> _$mods(SharedModList v) => v.mods;
  static const Field<SharedModList, List<SharedModVariant>> _f$mods = Field(
    'mods',
    _$mods,
  );
  static DateTime? _$dateCreated(SharedModList v) => v.dateCreated;
  static const Field<SharedModList, DateTime> _f$dateCreated = Field(
    'dateCreated',
    _$dateCreated,
    opt: true,
  );
  static DateTime? _$dateModified(SharedModList v) => v.dateModified;
  static const Field<SharedModList, DateTime> _f$dateModified = Field(
    'dateModified',
    _$dateModified,
    opt: true,
  );

  @override
  final MappableFields<SharedModList> fields = const {
    #id: _f$id,
    #name: _f$name,
    #description: _f$description,
    #mods: _f$mods,
    #dateCreated: _f$dateCreated,
    #dateModified: _f$dateModified,
  };

  static SharedModList _instantiate(DecodingData data) {
    return SharedModList(
      id: data.dec(_f$id),
      name: data.dec(_f$name),
      description: data.dec(_f$description),
      mods: data.dec(_f$mods),
      dateCreated: data.dec(_f$dateCreated),
      dateModified: data.dec(_f$dateModified),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static SharedModList fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<SharedModList>(map);
  }

  static SharedModList fromJson(String json) {
    return ensureInitialized().decodeJson<SharedModList>(json);
  }
}

mixin SharedModListMappable {
  String toJson() {
    return SharedModListMapper.ensureInitialized().encodeJson<SharedModList>(
      this as SharedModList,
    );
  }

  Map<String, dynamic> toMap() {
    return SharedModListMapper.ensureInitialized().encodeMap<SharedModList>(
      this as SharedModList,
    );
  }

  SharedModListCopyWith<SharedModList, SharedModList, SharedModList>
  get copyWith => _SharedModListCopyWithImpl<SharedModList, SharedModList>(
    this as SharedModList,
    $identity,
    $identity,
  );
  @override
  String toString() {
    return SharedModListMapper.ensureInitialized().stringifyValue(
      this as SharedModList,
    );
  }

  @override
  bool operator ==(Object other) {
    return SharedModListMapper.ensureInitialized().equalsValue(
      this as SharedModList,
      other,
    );
  }

  @override
  int get hashCode {
    return SharedModListMapper.ensureInitialized().hashValue(
      this as SharedModList,
    );
  }
}

extension SharedModListValueCopy<$R, $Out>
    on ObjectCopyWith<$R, SharedModList, $Out> {
  SharedModListCopyWith<$R, SharedModList, $Out> get $asSharedModList =>
      $base.as((v, t, t2) => _SharedModListCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class SharedModListCopyWith<$R, $In extends SharedModList, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  ListCopyWith<
    $R,
    SharedModVariant,
    SharedModVariantCopyWith<$R, SharedModVariant, SharedModVariant>
  >
  get mods;
  $R call({
    String? id,
    String? name,
    String? description,
    List<SharedModVariant>? mods,
    DateTime? dateCreated,
    DateTime? dateModified,
  });
  SharedModListCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _SharedModListCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, SharedModList, $Out>
    implements SharedModListCopyWith<$R, SharedModList, $Out> {
  _SharedModListCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<SharedModList> $mapper =
      SharedModListMapper.ensureInitialized();
  @override
  ListCopyWith<
    $R,
    SharedModVariant,
    SharedModVariantCopyWith<$R, SharedModVariant, SharedModVariant>
  >
  get mods => ListCopyWith(
    $value.mods,
    (v, t) => v.copyWith.$chain(t),
    (v) => call(mods: v),
  );
  @override
  $R call({
    Object? id = $none,
    Object? name = $none,
    Object? description = $none,
    List<SharedModVariant>? mods,
    Object? dateCreated = $none,
    Object? dateModified = $none,
  }) => $apply(
    FieldCopyWithData({
      if (id != $none) #id: id,
      if (name != $none) #name: name,
      if (description != $none) #description: description,
      if (mods != null) #mods: mods,
      if (dateCreated != $none) #dateCreated: dateCreated,
      if (dateModified != $none) #dateModified: dateModified,
    }),
  );
  @override
  SharedModList $make(CopyWithData data) => SharedModList(
    id: data.get(#id, or: $value.id),
    name: data.get(#name, or: $value.name),
    description: data.get(#description, or: $value.description),
    mods: data.get(#mods, or: $value.mods),
    dateCreated: data.get(#dateCreated, or: $value.dateCreated),
    dateModified: data.get(#dateModified, or: $value.dateModified),
  );

  @override
  SharedModListCopyWith<$R2, SharedModList, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _SharedModListCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class SharedModVariantMapper extends ClassMapperBase<SharedModVariant> {
  SharedModVariantMapper._();

  static SharedModVariantMapper? _instance;
  static SharedModVariantMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = SharedModVariantMapper._());
      VersionMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'SharedModVariant';

  static String _$modId(SharedModVariant v) => v.modId;
  static const Field<SharedModVariant, String> _f$modId = Field(
    'modId',
    _$modId,
  );
  static String? _$modName(SharedModVariant v) => v.modName;
  static const Field<SharedModVariant, String> _f$modName = Field(
    'modName',
    _$modName,
    opt: true,
  );
  static String _$smolVariantId(SharedModVariant v) => v.smolVariantId;
  static const Field<SharedModVariant, String> _f$smolVariantId = Field(
    'smolVariantId',
    _$smolVariantId,
    key: r'variantId',
  );
  static Version? _$versionName(SharedModVariant v) => v.versionName;
  static const Field<SharedModVariant, Version> _f$versionName = Field(
    'versionName',
    _$versionName,
    opt: true,
    hook: VersionHook(),
  );

  @override
  final MappableFields<SharedModVariant> fields = const {
    #modId: _f$modId,
    #modName: _f$modName,
    #smolVariantId: _f$smolVariantId,
    #versionName: _f$versionName,
  };

  static SharedModVariant _instantiate(DecodingData data) {
    return SharedModVariant(
      modId: data.dec(_f$modId),
      modName: data.dec(_f$modName),
      smolVariantId: data.dec(_f$smolVariantId),
      versionName: data.dec(_f$versionName),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static SharedModVariant fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<SharedModVariant>(map);
  }

  static SharedModVariant fromJson(String json) {
    return ensureInitialized().decodeJson<SharedModVariant>(json);
  }
}

mixin SharedModVariantMappable {
  String toJson() {
    return SharedModVariantMapper.ensureInitialized()
        .encodeJson<SharedModVariant>(this as SharedModVariant);
  }

  Map<String, dynamic> toMap() {
    return SharedModVariantMapper.ensureInitialized()
        .encodeMap<SharedModVariant>(this as SharedModVariant);
  }

  SharedModVariantCopyWith<SharedModVariant, SharedModVariant, SharedModVariant>
  get copyWith =>
      _SharedModVariantCopyWithImpl<SharedModVariant, SharedModVariant>(
        this as SharedModVariant,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return SharedModVariantMapper.ensureInitialized().stringifyValue(
      this as SharedModVariant,
    );
  }

  @override
  bool operator ==(Object other) {
    return SharedModVariantMapper.ensureInitialized().equalsValue(
      this as SharedModVariant,
      other,
    );
  }

  @override
  int get hashCode {
    return SharedModVariantMapper.ensureInitialized().hashValue(
      this as SharedModVariant,
    );
  }
}

extension SharedModVariantValueCopy<$R, $Out>
    on ObjectCopyWith<$R, SharedModVariant, $Out> {
  SharedModVariantCopyWith<$R, SharedModVariant, $Out>
  get $asSharedModVariant =>
      $base.as((v, t, t2) => _SharedModVariantCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class SharedModVariantCopyWith<$R, $In extends SharedModVariant, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  VersionCopyWith<$R, Version, Version>? get versionName;
  $R call({
    String? modId,
    String? modName,
    String? smolVariantId,
    Version? versionName,
  });
  SharedModVariantCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _SharedModVariantCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, SharedModVariant, $Out>
    implements SharedModVariantCopyWith<$R, SharedModVariant, $Out> {
  _SharedModVariantCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<SharedModVariant> $mapper =
      SharedModVariantMapper.ensureInitialized();
  @override
  VersionCopyWith<$R, Version, Version>? get versionName =>
      $value.versionName?.copyWith.$chain((v) => call(versionName: v));
  @override
  $R call({
    String? modId,
    Object? modName = $none,
    String? smolVariantId,
    Object? versionName = $none,
  }) => $apply(
    FieldCopyWithData({
      if (modId != null) #modId: modId,
      if (modName != $none) #modName: modName,
      if (smolVariantId != null) #smolVariantId: smolVariantId,
      if (versionName != $none) #versionName: versionName,
    }),
  );
  @override
  SharedModVariant $make(CopyWithData data) => SharedModVariant(
    modId: data.get(#modId, or: $value.modId),
    modName: data.get(#modName, or: $value.modName),
    smolVariantId: data.get(#smolVariantId, or: $value.smolVariantId),
    versionName: data.get(#versionName, or: $value.versionName),
  );

  @override
  SharedModVariantCopyWith<$R2, SharedModVariant, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _SharedModVariantCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

