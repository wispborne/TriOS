// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'forum_llm_data.dart';

class LlmModRoleMapper extends EnumMapper<LlmModRole> {
  LlmModRoleMapper._();

  static LlmModRoleMapper? _instance;
  static LlmModRoleMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = LlmModRoleMapper._());
    }
    return _instance!;
  }

  static LlmModRole fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  LlmModRole decode(dynamic value) {
    switch (value) {
      case r'main':
        return LlmModRole.main;
      case r'addon':
        return LlmModRole.addon;
      case r'separate':
        return LlmModRole.separate;
      case r'unknown':
        return LlmModRole.unknown;
      default:
        return LlmModRole.values[3];
    }
  }

  @override
  dynamic encode(LlmModRole self) {
    switch (self) {
      case LlmModRole.main:
        return r'main';
      case LlmModRole.addon:
        return r'addon';
      case LlmModRole.separate:
        return r'separate';
      case LlmModRole.unknown:
        return r'unknown';
    }
  }
}

extension LlmModRoleMapperExtension on LlmModRole {
  String toValue() {
    LlmModRoleMapper.ensureInitialized();
    return MapperContainer.globals.toValue<LlmModRole>(this) as String;
  }
}

class LlmDownloadTypeMapper extends EnumMapper<LlmDownloadType> {
  LlmDownloadTypeMapper._();

  static LlmDownloadTypeMapper? _instance;
  static LlmDownloadTypeMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = LlmDownloadTypeMapper._());
    }
    return _instance!;
  }

  static LlmDownloadType fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  LlmDownloadType decode(dynamic value) {
    switch (value) {
      case r'trios':
        return LlmDownloadType.trios;
      case r'direct':
        return LlmDownloadType.direct;
      case r'mirror':
        return LlmDownloadType.mirror;
      case r'unknown':
        return LlmDownloadType.unknown;
      default:
        return LlmDownloadType.values[3];
    }
  }

  @override
  dynamic encode(LlmDownloadType self) {
    switch (self) {
      case LlmDownloadType.trios:
        return r'trios';
      case LlmDownloadType.direct:
        return r'direct';
      case LlmDownloadType.mirror:
        return r'mirror';
      case LlmDownloadType.unknown:
        return r'unknown';
    }
  }
}

extension LlmDownloadTypeMapperExtension on LlmDownloadType {
  String toValue() {
    LlmDownloadTypeMapper.ensureInitialized();
    return MapperContainer.globals.toValue<LlmDownloadType>(this) as String;
  }
}

class LlmDownloadConfidenceMapper extends EnumMapper<LlmDownloadConfidence> {
  LlmDownloadConfidenceMapper._();

  static LlmDownloadConfidenceMapper? _instance;
  static LlmDownloadConfidenceMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = LlmDownloadConfidenceMapper._());
    }
    return _instance!;
  }

  static LlmDownloadConfidence fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  LlmDownloadConfidence decode(dynamic value) {
    switch (value) {
      case r'high':
        return LlmDownloadConfidence.high;
      case r'medium':
        return LlmDownloadConfidence.medium;
      case r'low':
        return LlmDownloadConfidence.low;
      case r'unknown':
        return LlmDownloadConfidence.unknown;
      default:
        return LlmDownloadConfidence.values[3];
    }
  }

  @override
  dynamic encode(LlmDownloadConfidence self) {
    switch (self) {
      case LlmDownloadConfidence.high:
        return r'high';
      case LlmDownloadConfidence.medium:
        return r'medium';
      case LlmDownloadConfidence.low:
        return r'low';
      case LlmDownloadConfidence.unknown:
        return r'unknown';
    }
  }
}

extension LlmDownloadConfidenceMapperExtension on LlmDownloadConfidence {
  String toValue() {
    LlmDownloadConfidenceMapper.ensureInitialized();
    return MapperContainer.globals.toValue<LlmDownloadConfidence>(this)
        as String;
  }
}

class ForumLlmDataMapper extends ClassMapperBase<ForumLlmData> {
  ForumLlmDataMapper._();

  static ForumLlmDataMapper? _instance;
  static ForumLlmDataMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ForumLlmDataMapper._());
      ForumLlmModMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'ForumLlmData';

  static List<ForumLlmMod> _$mods(ForumLlmData v) => v.mods;
  static const Field<ForumLlmData, List<ForumLlmMod>> _f$mods = Field(
    'mods',
    _$mods,
    opt: true,
    def: const [],
  );

  @override
  final MappableFields<ForumLlmData> fields = const {#mods: _f$mods};

  static ForumLlmData _instantiate(DecodingData data) {
    return ForumLlmData(mods: data.dec(_f$mods));
  }

  @override
  final Function instantiate = _instantiate;

  static ForumLlmData fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<ForumLlmData>(map);
  }

  static ForumLlmData fromJson(String json) {
    return ensureInitialized().decodeJson<ForumLlmData>(json);
  }
}

mixin ForumLlmDataMappable {
  String toJson() {
    return ForumLlmDataMapper.ensureInitialized().encodeJson<ForumLlmData>(
      this as ForumLlmData,
    );
  }

  Map<String, dynamic> toMap() {
    return ForumLlmDataMapper.ensureInitialized().encodeMap<ForumLlmData>(
      this as ForumLlmData,
    );
  }

  ForumLlmDataCopyWith<ForumLlmData, ForumLlmData, ForumLlmData> get copyWith =>
      _ForumLlmDataCopyWithImpl<ForumLlmData, ForumLlmData>(
        this as ForumLlmData,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return ForumLlmDataMapper.ensureInitialized().stringifyValue(
      this as ForumLlmData,
    );
  }

  @override
  bool operator ==(Object other) {
    return ForumLlmDataMapper.ensureInitialized().equalsValue(
      this as ForumLlmData,
      other,
    );
  }

  @override
  int get hashCode {
    return ForumLlmDataMapper.ensureInitialized().hashValue(
      this as ForumLlmData,
    );
  }
}

extension ForumLlmDataValueCopy<$R, $Out>
    on ObjectCopyWith<$R, ForumLlmData, $Out> {
  ForumLlmDataCopyWith<$R, ForumLlmData, $Out> get $asForumLlmData =>
      $base.as((v, t, t2) => _ForumLlmDataCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class ForumLlmDataCopyWith<$R, $In extends ForumLlmData, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  ListCopyWith<
    $R,
    ForumLlmMod,
    ForumLlmModCopyWith<$R, ForumLlmMod, ForumLlmMod>
  >
  get mods;
  $R call({List<ForumLlmMod>? mods});
  ForumLlmDataCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _ForumLlmDataCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, ForumLlmData, $Out>
    implements ForumLlmDataCopyWith<$R, ForumLlmData, $Out> {
  _ForumLlmDataCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<ForumLlmData> $mapper =
      ForumLlmDataMapper.ensureInitialized();
  @override
  ListCopyWith<
    $R,
    ForumLlmMod,
    ForumLlmModCopyWith<$R, ForumLlmMod, ForumLlmMod>
  >
  get mods => ListCopyWith(
    $value.mods,
    (v, t) => v.copyWith.$chain(t),
    (v) => call(mods: v),
  );
  @override
  $R call({List<ForumLlmMod>? mods}) =>
      $apply(FieldCopyWithData({if (mods != null) #mods: mods}));
  @override
  ForumLlmData $make(CopyWithData data) =>
      ForumLlmData(mods: data.get(#mods, or: $value.mods));

  @override
  ForumLlmDataCopyWith<$R2, ForumLlmData, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _ForumLlmDataCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class ForumLlmModMapper extends ClassMapperBase<ForumLlmMod> {
  ForumLlmModMapper._();

  static ForumLlmModMapper? _instance;
  static ForumLlmModMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ForumLlmModMapper._());
      LlmModRoleMapper.ensureInitialized();
      ForumLlmDownloadMapper.ensureInitialized();
      ForumLlmReleaseMapper.ensureInitialized();
      ForumLlmSaveCompatMapper.ensureInitialized();
      ForumLlmRequirementsMapper.ensureInitialized();
      ForumLlmConflictMapper.ensureInitialized();
      CatalogAiUseMapper.ensureInitialized();
      ForumLlmSourceCodeMapper.ensureInitialized();
      ForumLlmSupportLinkMapper.ensureInitialized();
      ForumLlmDescriptionMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'ForumLlmMod';

  static String _$name(ForumLlmMod v) => v.name;
  static const Field<ForumLlmMod, String> _f$name = Field('name', _$name);
  static LlmModRole _$role(ForumLlmMod v) => v.role;
  static const Field<ForumLlmMod, LlmModRole> _f$role = Field(
    'role',
    _$role,
    opt: true,
    def: LlmModRole.unknown,
  );
  static List<String>? _$parentMods(ForumLlmMod v) => v.parentMods;
  static const Field<ForumLlmMod, List<String>> _f$parentMods = Field(
    'parentMods',
    _$parentMods,
    key: r'parentMod',
    opt: true,
    hook: RequiredModsHook(),
  );
  static List<String>? _$types(ForumLlmMod v) => v.types;
  static const Field<ForumLlmMod, List<String>> _f$types = Field(
    'types',
    _$types,
    opt: true,
  );
  static List<ForumLlmDownload> _$downloads(ForumLlmMod v) => v.downloads;
  static const Field<ForumLlmMod, List<ForumLlmDownload>> _f$downloads = Field(
    'downloads',
    _$downloads,
    opt: true,
    def: const [],
  );
  static List<String>? _$nicknames(ForumLlmMod v) => v.nicknames;
  static const Field<ForumLlmMod, List<String>> _f$nicknames = Field(
    'nicknames',
    _$nicknames,
    opt: true,
  );
  static String? _$image(ForumLlmMod v) => v.image;
  static const Field<ForumLlmMod, String> _f$image = Field(
    'image',
    _$image,
    key: r'imageUrl',
    opt: true,
  );
  static ForumLlmRelease? _$release(ForumLlmMod v) => v.release;
  static const Field<ForumLlmMod, ForumLlmRelease> _f$release = Field(
    'release',
    _$release,
    opt: true,
  );
  static ForumLlmSaveCompat? _$saveCompat(ForumLlmMod v) => v.saveCompat;
  static const Field<ForumLlmMod, ForumLlmSaveCompat> _f$saveCompat = Field(
    'saveCompat',
    _$saveCompat,
    opt: true,
  );
  static ForumLlmRequirements? _$requirements(ForumLlmMod v) => v.requirements;
  static const Field<ForumLlmMod, ForumLlmRequirements> _f$requirements = Field(
    'requirements',
    _$requirements,
    opt: true,
  );
  static List<ForumLlmConflict>? _$conflicts(ForumLlmMod v) => v.conflicts;
  static const Field<ForumLlmMod, List<ForumLlmConflict>> _f$conflicts = Field(
    'conflicts',
    _$conflicts,
    opt: true,
  );
  static CatalogAiUse? _$aiUse(ForumLlmMod v) => v.aiUse;
  static const Field<ForumLlmMod, CatalogAiUse> _f$aiUse = Field(
    'aiUse',
    _$aiUse,
    opt: true,
  );
  static ForumLlmSourceCode? _$sourceCode(ForumLlmMod v) => v.sourceCode;
  static const Field<ForumLlmMod, ForumLlmSourceCode> _f$sourceCode = Field(
    'sourceCode',
    _$sourceCode,
    opt: true,
  );
  static List<ForumLlmSupportLink>? _$supportLinks(ForumLlmMod v) =>
      v.supportLinks;
  static const Field<ForumLlmMod, List<ForumLlmSupportLink>> _f$supportLinks =
      Field('supportLinks', _$supportLinks, opt: true);
  static ForumLlmDescription? _$description(ForumLlmMod v) => v.description;
  static const Field<ForumLlmMod, ForumLlmDescription> _f$description = Field(
    'description',
    _$description,
    opt: true,
  );

  @override
  final MappableFields<ForumLlmMod> fields = const {
    #name: _f$name,
    #role: _f$role,
    #parentMods: _f$parentMods,
    #types: _f$types,
    #downloads: _f$downloads,
    #nicknames: _f$nicknames,
    #image: _f$image,
    #release: _f$release,
    #saveCompat: _f$saveCompat,
    #requirements: _f$requirements,
    #conflicts: _f$conflicts,
    #aiUse: _f$aiUse,
    #sourceCode: _f$sourceCode,
    #supportLinks: _f$supportLinks,
    #description: _f$description,
  };

  @override
  final MappingHook hook = const OldLlmFormatHook();
  static ForumLlmMod _instantiate(DecodingData data) {
    return ForumLlmMod(
      name: data.dec(_f$name),
      role: data.dec(_f$role),
      parentMods: data.dec(_f$parentMods),
      types: data.dec(_f$types),
      downloads: data.dec(_f$downloads),
      nicknames: data.dec(_f$nicknames),
      image: data.dec(_f$image),
      release: data.dec(_f$release),
      saveCompat: data.dec(_f$saveCompat),
      requirements: data.dec(_f$requirements),
      conflicts: data.dec(_f$conflicts),
      aiUse: data.dec(_f$aiUse),
      sourceCode: data.dec(_f$sourceCode),
      supportLinks: data.dec(_f$supportLinks),
      description: data.dec(_f$description),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static ForumLlmMod fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<ForumLlmMod>(map);
  }

  static ForumLlmMod fromJson(String json) {
    return ensureInitialized().decodeJson<ForumLlmMod>(json);
  }
}

mixin ForumLlmModMappable {
  String toJson() {
    return ForumLlmModMapper.ensureInitialized().encodeJson<ForumLlmMod>(
      this as ForumLlmMod,
    );
  }

  Map<String, dynamic> toMap() {
    return ForumLlmModMapper.ensureInitialized().encodeMap<ForumLlmMod>(
      this as ForumLlmMod,
    );
  }

  ForumLlmModCopyWith<ForumLlmMod, ForumLlmMod, ForumLlmMod> get copyWith =>
      _ForumLlmModCopyWithImpl<ForumLlmMod, ForumLlmMod>(
        this as ForumLlmMod,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return ForumLlmModMapper.ensureInitialized().stringifyValue(
      this as ForumLlmMod,
    );
  }

  @override
  bool operator ==(Object other) {
    return ForumLlmModMapper.ensureInitialized().equalsValue(
      this as ForumLlmMod,
      other,
    );
  }

  @override
  int get hashCode {
    return ForumLlmModMapper.ensureInitialized().hashValue(this as ForumLlmMod);
  }
}

extension ForumLlmModValueCopy<$R, $Out>
    on ObjectCopyWith<$R, ForumLlmMod, $Out> {
  ForumLlmModCopyWith<$R, ForumLlmMod, $Out> get $asForumLlmMod =>
      $base.as((v, t, t2) => _ForumLlmModCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class ForumLlmModCopyWith<$R, $In extends ForumLlmMod, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>>? get parentMods;
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>>? get types;
  ListCopyWith<
    $R,
    ForumLlmDownload,
    ForumLlmDownloadCopyWith<$R, ForumLlmDownload, ForumLlmDownload>
  >
  get downloads;
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>>? get nicknames;
  ForumLlmReleaseCopyWith<$R, ForumLlmRelease, ForumLlmRelease>? get release;
  ForumLlmSaveCompatCopyWith<$R, ForumLlmSaveCompat, ForumLlmSaveCompat>?
  get saveCompat;
  ForumLlmRequirementsCopyWith<$R, ForumLlmRequirements, ForumLlmRequirements>?
  get requirements;
  ListCopyWith<
    $R,
    ForumLlmConflict,
    ForumLlmConflictCopyWith<$R, ForumLlmConflict, ForumLlmConflict>
  >?
  get conflicts;
  CatalogAiUseCopyWith<$R, CatalogAiUse, CatalogAiUse>? get aiUse;
  ForumLlmSourceCodeCopyWith<$R, ForumLlmSourceCode, ForumLlmSourceCode>?
  get sourceCode;
  ListCopyWith<
    $R,
    ForumLlmSupportLink,
    ForumLlmSupportLinkCopyWith<$R, ForumLlmSupportLink, ForumLlmSupportLink>
  >?
  get supportLinks;
  ForumLlmDescriptionCopyWith<$R, ForumLlmDescription, ForumLlmDescription>?
  get description;
  $R call({
    String? name,
    LlmModRole? role,
    List<String>? parentMods,
    List<String>? types,
    List<ForumLlmDownload>? downloads,
    List<String>? nicknames,
    String? image,
    ForumLlmRelease? release,
    ForumLlmSaveCompat? saveCompat,
    ForumLlmRequirements? requirements,
    List<ForumLlmConflict>? conflicts,
    CatalogAiUse? aiUse,
    ForumLlmSourceCode? sourceCode,
    List<ForumLlmSupportLink>? supportLinks,
    ForumLlmDescription? description,
  });
  ForumLlmModCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _ForumLlmModCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, ForumLlmMod, $Out>
    implements ForumLlmModCopyWith<$R, ForumLlmMod, $Out> {
  _ForumLlmModCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<ForumLlmMod> $mapper =
      ForumLlmModMapper.ensureInitialized();
  @override
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>>?
  get parentMods => $value.parentMods != null
      ? ListCopyWith(
          $value.parentMods!,
          (v, t) => ObjectCopyWith(v, $identity, t),
          (v) => call(parentMods: v),
        )
      : null;
  @override
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>>? get types =>
      $value.types != null
      ? ListCopyWith(
          $value.types!,
          (v, t) => ObjectCopyWith(v, $identity, t),
          (v) => call(types: v),
        )
      : null;
  @override
  ListCopyWith<
    $R,
    ForumLlmDownload,
    ForumLlmDownloadCopyWith<$R, ForumLlmDownload, ForumLlmDownload>
  >
  get downloads => ListCopyWith(
    $value.downloads,
    (v, t) => v.copyWith.$chain(t),
    (v) => call(downloads: v),
  );
  @override
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>>? get nicknames =>
      $value.nicknames != null
      ? ListCopyWith(
          $value.nicknames!,
          (v, t) => ObjectCopyWith(v, $identity, t),
          (v) => call(nicknames: v),
        )
      : null;
  @override
  ForumLlmReleaseCopyWith<$R, ForumLlmRelease, ForumLlmRelease>? get release =>
      $value.release?.copyWith.$chain((v) => call(release: v));
  @override
  ForumLlmSaveCompatCopyWith<$R, ForumLlmSaveCompat, ForumLlmSaveCompat>?
  get saveCompat =>
      $value.saveCompat?.copyWith.$chain((v) => call(saveCompat: v));
  @override
  ForumLlmRequirementsCopyWith<$R, ForumLlmRequirements, ForumLlmRequirements>?
  get requirements =>
      $value.requirements?.copyWith.$chain((v) => call(requirements: v));
  @override
  ListCopyWith<
    $R,
    ForumLlmConflict,
    ForumLlmConflictCopyWith<$R, ForumLlmConflict, ForumLlmConflict>
  >?
  get conflicts => $value.conflicts != null
      ? ListCopyWith(
          $value.conflicts!,
          (v, t) => v.copyWith.$chain(t),
          (v) => call(conflicts: v),
        )
      : null;
  @override
  CatalogAiUseCopyWith<$R, CatalogAiUse, CatalogAiUse>? get aiUse =>
      $value.aiUse?.copyWith.$chain((v) => call(aiUse: v));
  @override
  ForumLlmSourceCodeCopyWith<$R, ForumLlmSourceCode, ForumLlmSourceCode>?
  get sourceCode =>
      $value.sourceCode?.copyWith.$chain((v) => call(sourceCode: v));
  @override
  ListCopyWith<
    $R,
    ForumLlmSupportLink,
    ForumLlmSupportLinkCopyWith<$R, ForumLlmSupportLink, ForumLlmSupportLink>
  >?
  get supportLinks => $value.supportLinks != null
      ? ListCopyWith(
          $value.supportLinks!,
          (v, t) => v.copyWith.$chain(t),
          (v) => call(supportLinks: v),
        )
      : null;
  @override
  ForumLlmDescriptionCopyWith<$R, ForumLlmDescription, ForumLlmDescription>?
  get description =>
      $value.description?.copyWith.$chain((v) => call(description: v));
  @override
  $R call({
    String? name,
    LlmModRole? role,
    Object? parentMods = $none,
    Object? types = $none,
    List<ForumLlmDownload>? downloads,
    Object? nicknames = $none,
    Object? image = $none,
    Object? release = $none,
    Object? saveCompat = $none,
    Object? requirements = $none,
    Object? conflicts = $none,
    Object? aiUse = $none,
    Object? sourceCode = $none,
    Object? supportLinks = $none,
    Object? description = $none,
  }) => $apply(
    FieldCopyWithData({
      if (name != null) #name: name,
      if (role != null) #role: role,
      if (parentMods != $none) #parentMods: parentMods,
      if (types != $none) #types: types,
      if (downloads != null) #downloads: downloads,
      if (nicknames != $none) #nicknames: nicknames,
      if (image != $none) #image: image,
      if (release != $none) #release: release,
      if (saveCompat != $none) #saveCompat: saveCompat,
      if (requirements != $none) #requirements: requirements,
      if (conflicts != $none) #conflicts: conflicts,
      if (aiUse != $none) #aiUse: aiUse,
      if (sourceCode != $none) #sourceCode: sourceCode,
      if (supportLinks != $none) #supportLinks: supportLinks,
      if (description != $none) #description: description,
    }),
  );
  @override
  ForumLlmMod $make(CopyWithData data) => ForumLlmMod(
    name: data.get(#name, or: $value.name),
    role: data.get(#role, or: $value.role),
    parentMods: data.get(#parentMods, or: $value.parentMods),
    types: data.get(#types, or: $value.types),
    downloads: data.get(#downloads, or: $value.downloads),
    nicknames: data.get(#nicknames, or: $value.nicknames),
    image: data.get(#image, or: $value.image),
    release: data.get(#release, or: $value.release),
    saveCompat: data.get(#saveCompat, or: $value.saveCompat),
    requirements: data.get(#requirements, or: $value.requirements),
    conflicts: data.get(#conflicts, or: $value.conflicts),
    aiUse: data.get(#aiUse, or: $value.aiUse),
    sourceCode: data.get(#sourceCode, or: $value.sourceCode),
    supportLinks: data.get(#supportLinks, or: $value.supportLinks),
    description: data.get(#description, or: $value.description),
  );

  @override
  ForumLlmModCopyWith<$R2, ForumLlmMod, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _ForumLlmModCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class ForumLlmDownloadMapper extends ClassMapperBase<ForumLlmDownload> {
  ForumLlmDownloadMapper._();

  static ForumLlmDownloadMapper? _instance;
  static ForumLlmDownloadMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ForumLlmDownloadMapper._());
      LlmDownloadTypeMapper.ensureInitialized();
      LlmDownloadConfidenceMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'ForumLlmDownload';

  static String _$url(ForumLlmDownload v) => v.url;
  static const Field<ForumLlmDownload, String> _f$url = Field('url', _$url);
  static String _$label(ForumLlmDownload v) => v.label;
  static const Field<ForumLlmDownload, String> _f$label = Field(
    'label',
    _$label,
    opt: true,
    def: '',
  );
  static LlmDownloadType _$type(ForumLlmDownload v) => v.type;
  static const Field<ForumLlmDownload, LlmDownloadType> _f$type = Field(
    'type',
    _$type,
    opt: true,
    def: LlmDownloadType.unknown,
  );
  static LlmDownloadConfidence _$confidence(ForumLlmDownload v) => v.confidence;
  static const Field<ForumLlmDownload, LlmDownloadConfidence> _f$confidence =
      Field(
        'confidence',
        _$confidence,
        opt: true,
        def: LlmDownloadConfidence.unknown,
      );
  static bool _$requiresManualStep(ForumLlmDownload v) => v.requiresManualStep;
  static const Field<ForumLlmDownload, bool> _f$requiresManualStep = Field(
    'requiresManualStep',
    _$requiresManualStep,
    opt: true,
    def: false,
  );
  static String? _$sourceHost(ForumLlmDownload v) => v.sourceHost;
  static const Field<ForumLlmDownload, String> _f$sourceHost = Field(
    'sourceHost',
    _$sourceHost,
    opt: true,
  );
  static String? _$resolvedDirectUrl(ForumLlmDownload v) => v.resolvedDirectUrl;
  static const Field<ForumLlmDownload, String> _f$resolvedDirectUrl = Field(
    'resolvedDirectUrl',
    _$resolvedDirectUrl,
    opt: true,
  );
  static String? _$fileName(ForumLlmDownload v) => v.fileName;
  static const Field<ForumLlmDownload, String> _f$fileName = Field(
    'fileName',
    _$fileName,
    opt: true,
  );

  @override
  final MappableFields<ForumLlmDownload> fields = const {
    #url: _f$url,
    #label: _f$label,
    #type: _f$type,
    #confidence: _f$confidence,
    #requiresManualStep: _f$requiresManualStep,
    #sourceHost: _f$sourceHost,
    #resolvedDirectUrl: _f$resolvedDirectUrl,
    #fileName: _f$fileName,
  };

  static ForumLlmDownload _instantiate(DecodingData data) {
    return ForumLlmDownload(
      url: data.dec(_f$url),
      label: data.dec(_f$label),
      type: data.dec(_f$type),
      confidence: data.dec(_f$confidence),
      requiresManualStep: data.dec(_f$requiresManualStep),
      sourceHost: data.dec(_f$sourceHost),
      resolvedDirectUrl: data.dec(_f$resolvedDirectUrl),
      fileName: data.dec(_f$fileName),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static ForumLlmDownload fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<ForumLlmDownload>(map);
  }

  static ForumLlmDownload fromJson(String json) {
    return ensureInitialized().decodeJson<ForumLlmDownload>(json);
  }
}

mixin ForumLlmDownloadMappable {
  String toJson() {
    return ForumLlmDownloadMapper.ensureInitialized()
        .encodeJson<ForumLlmDownload>(this as ForumLlmDownload);
  }

  Map<String, dynamic> toMap() {
    return ForumLlmDownloadMapper.ensureInitialized()
        .encodeMap<ForumLlmDownload>(this as ForumLlmDownload);
  }

  ForumLlmDownloadCopyWith<ForumLlmDownload, ForumLlmDownload, ForumLlmDownload>
  get copyWith =>
      _ForumLlmDownloadCopyWithImpl<ForumLlmDownload, ForumLlmDownload>(
        this as ForumLlmDownload,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return ForumLlmDownloadMapper.ensureInitialized().stringifyValue(
      this as ForumLlmDownload,
    );
  }

  @override
  bool operator ==(Object other) {
    return ForumLlmDownloadMapper.ensureInitialized().equalsValue(
      this as ForumLlmDownload,
      other,
    );
  }

  @override
  int get hashCode {
    return ForumLlmDownloadMapper.ensureInitialized().hashValue(
      this as ForumLlmDownload,
    );
  }
}

extension ForumLlmDownloadValueCopy<$R, $Out>
    on ObjectCopyWith<$R, ForumLlmDownload, $Out> {
  ForumLlmDownloadCopyWith<$R, ForumLlmDownload, $Out>
  get $asForumLlmDownload =>
      $base.as((v, t, t2) => _ForumLlmDownloadCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class ForumLlmDownloadCopyWith<$R, $In extends ForumLlmDownload, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({
    String? url,
    String? label,
    LlmDownloadType? type,
    LlmDownloadConfidence? confidence,
    bool? requiresManualStep,
    String? sourceHost,
    String? resolvedDirectUrl,
    String? fileName,
  });
  ForumLlmDownloadCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _ForumLlmDownloadCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, ForumLlmDownload, $Out>
    implements ForumLlmDownloadCopyWith<$R, ForumLlmDownload, $Out> {
  _ForumLlmDownloadCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<ForumLlmDownload> $mapper =
      ForumLlmDownloadMapper.ensureInitialized();
  @override
  $R call({
    String? url,
    String? label,
    LlmDownloadType? type,
    LlmDownloadConfidence? confidence,
    bool? requiresManualStep,
    Object? sourceHost = $none,
    Object? resolvedDirectUrl = $none,
    Object? fileName = $none,
  }) => $apply(
    FieldCopyWithData({
      if (url != null) #url: url,
      if (label != null) #label: label,
      if (type != null) #type: type,
      if (confidence != null) #confidence: confidence,
      if (requiresManualStep != null) #requiresManualStep: requiresManualStep,
      if (sourceHost != $none) #sourceHost: sourceHost,
      if (resolvedDirectUrl != $none) #resolvedDirectUrl: resolvedDirectUrl,
      if (fileName != $none) #fileName: fileName,
    }),
  );
  @override
  ForumLlmDownload $make(CopyWithData data) => ForumLlmDownload(
    url: data.get(#url, or: $value.url),
    label: data.get(#label, or: $value.label),
    type: data.get(#type, or: $value.type),
    confidence: data.get(#confidence, or: $value.confidence),
    requiresManualStep: data.get(
      #requiresManualStep,
      or: $value.requiresManualStep,
    ),
    sourceHost: data.get(#sourceHost, or: $value.sourceHost),
    resolvedDirectUrl: data.get(
      #resolvedDirectUrl,
      or: $value.resolvedDirectUrl,
    ),
    fileName: data.get(#fileName, or: $value.fileName),
  );

  @override
  ForumLlmDownloadCopyWith<$R2, ForumLlmDownload, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _ForumLlmDownloadCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class ForumLlmReleaseMapper extends ClassMapperBase<ForumLlmRelease> {
  ForumLlmReleaseMapper._();

  static ForumLlmReleaseMapper? _instance;
  static ForumLlmReleaseMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ForumLlmReleaseMapper._());
      ForumLlmChangelogMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'ForumLlmRelease';

  static String? _$version(ForumLlmRelease v) => v.version;
  static const Field<ForumLlmRelease, String> _f$version = Field(
    'version',
    _$version,
    opt: true,
  );
  static ForumLlmChangelog? _$changelog(ForumLlmRelease v) => v.changelog;
  static const Field<ForumLlmRelease, ForumLlmChangelog> _f$changelog = Field(
    'changelog',
    _$changelog,
    opt: true,
  );

  @override
  final MappableFields<ForumLlmRelease> fields = const {
    #version: _f$version,
    #changelog: _f$changelog,
  };

  static ForumLlmRelease _instantiate(DecodingData data) {
    return ForumLlmRelease(
      version: data.dec(_f$version),
      changelog: data.dec(_f$changelog),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static ForumLlmRelease fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<ForumLlmRelease>(map);
  }

  static ForumLlmRelease fromJson(String json) {
    return ensureInitialized().decodeJson<ForumLlmRelease>(json);
  }
}

mixin ForumLlmReleaseMappable {
  String toJson() {
    return ForumLlmReleaseMapper.ensureInitialized()
        .encodeJson<ForumLlmRelease>(this as ForumLlmRelease);
  }

  Map<String, dynamic> toMap() {
    return ForumLlmReleaseMapper.ensureInitialized().encodeMap<ForumLlmRelease>(
      this as ForumLlmRelease,
    );
  }

  ForumLlmReleaseCopyWith<ForumLlmRelease, ForumLlmRelease, ForumLlmRelease>
  get copyWith =>
      _ForumLlmReleaseCopyWithImpl<ForumLlmRelease, ForumLlmRelease>(
        this as ForumLlmRelease,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return ForumLlmReleaseMapper.ensureInitialized().stringifyValue(
      this as ForumLlmRelease,
    );
  }

  @override
  bool operator ==(Object other) {
    return ForumLlmReleaseMapper.ensureInitialized().equalsValue(
      this as ForumLlmRelease,
      other,
    );
  }

  @override
  int get hashCode {
    return ForumLlmReleaseMapper.ensureInitialized().hashValue(
      this as ForumLlmRelease,
    );
  }
}

extension ForumLlmReleaseValueCopy<$R, $Out>
    on ObjectCopyWith<$R, ForumLlmRelease, $Out> {
  ForumLlmReleaseCopyWith<$R, ForumLlmRelease, $Out> get $asForumLlmRelease =>
      $base.as((v, t, t2) => _ForumLlmReleaseCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class ForumLlmReleaseCopyWith<$R, $In extends ForumLlmRelease, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  ForumLlmChangelogCopyWith<$R, ForumLlmChangelog, ForumLlmChangelog>?
  get changelog;
  $R call({String? version, ForumLlmChangelog? changelog});
  ForumLlmReleaseCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _ForumLlmReleaseCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, ForumLlmRelease, $Out>
    implements ForumLlmReleaseCopyWith<$R, ForumLlmRelease, $Out> {
  _ForumLlmReleaseCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<ForumLlmRelease> $mapper =
      ForumLlmReleaseMapper.ensureInitialized();
  @override
  ForumLlmChangelogCopyWith<$R, ForumLlmChangelog, ForumLlmChangelog>?
  get changelog => $value.changelog?.copyWith.$chain((v) => call(changelog: v));
  @override
  $R call({Object? version = $none, Object? changelog = $none}) => $apply(
    FieldCopyWithData({
      if (version != $none) #version: version,
      if (changelog != $none) #changelog: changelog,
    }),
  );
  @override
  ForumLlmRelease $make(CopyWithData data) => ForumLlmRelease(
    version: data.get(#version, or: $value.version),
    changelog: data.get(#changelog, or: $value.changelog),
  );

  @override
  ForumLlmReleaseCopyWith<$R2, ForumLlmRelease, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _ForumLlmReleaseCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class ForumLlmChangelogMapper extends ClassMapperBase<ForumLlmChangelog> {
  ForumLlmChangelogMapper._();

  static ForumLlmChangelogMapper? _instance;
  static ForumLlmChangelogMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ForumLlmChangelogMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'ForumLlmChangelog';

  static Map<String, String>? _$entries(ForumLlmChangelog v) => v.entries;
  static const Field<ForumLlmChangelog, Map<String, String>> _f$entries = Field(
    'entries',
    _$entries,
    opt: true,
  );
  static String? _$url(ForumLlmChangelog v) => v.url;
  static const Field<ForumLlmChangelog, String> _f$url = Field(
    'url',
    _$url,
    opt: true,
  );

  @override
  final MappableFields<ForumLlmChangelog> fields = const {
    #entries: _f$entries,
    #url: _f$url,
  };

  static ForumLlmChangelog _instantiate(DecodingData data) {
    return ForumLlmChangelog(
      entries: data.dec(_f$entries),
      url: data.dec(_f$url),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static ForumLlmChangelog fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<ForumLlmChangelog>(map);
  }

  static ForumLlmChangelog fromJson(String json) {
    return ensureInitialized().decodeJson<ForumLlmChangelog>(json);
  }
}

mixin ForumLlmChangelogMappable {
  String toJson() {
    return ForumLlmChangelogMapper.ensureInitialized()
        .encodeJson<ForumLlmChangelog>(this as ForumLlmChangelog);
  }

  Map<String, dynamic> toMap() {
    return ForumLlmChangelogMapper.ensureInitialized()
        .encodeMap<ForumLlmChangelog>(this as ForumLlmChangelog);
  }

  ForumLlmChangelogCopyWith<
    ForumLlmChangelog,
    ForumLlmChangelog,
    ForumLlmChangelog
  >
  get copyWith =>
      _ForumLlmChangelogCopyWithImpl<ForumLlmChangelog, ForumLlmChangelog>(
        this as ForumLlmChangelog,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return ForumLlmChangelogMapper.ensureInitialized().stringifyValue(
      this as ForumLlmChangelog,
    );
  }

  @override
  bool operator ==(Object other) {
    return ForumLlmChangelogMapper.ensureInitialized().equalsValue(
      this as ForumLlmChangelog,
      other,
    );
  }

  @override
  int get hashCode {
    return ForumLlmChangelogMapper.ensureInitialized().hashValue(
      this as ForumLlmChangelog,
    );
  }
}

extension ForumLlmChangelogValueCopy<$R, $Out>
    on ObjectCopyWith<$R, ForumLlmChangelog, $Out> {
  ForumLlmChangelogCopyWith<$R, ForumLlmChangelog, $Out>
  get $asForumLlmChangelog => $base.as(
    (v, t, t2) => _ForumLlmChangelogCopyWithImpl<$R, $Out>(v, t, t2),
  );
}

abstract class ForumLlmChangelogCopyWith<
  $R,
  $In extends ForumLlmChangelog,
  $Out
>
    implements ClassCopyWith<$R, $In, $Out> {
  MapCopyWith<$R, String, String, ObjectCopyWith<$R, String, String>>?
  get entries;
  $R call({Map<String, String>? entries, String? url});
  ForumLlmChangelogCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _ForumLlmChangelogCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, ForumLlmChangelog, $Out>
    implements ForumLlmChangelogCopyWith<$R, ForumLlmChangelog, $Out> {
  _ForumLlmChangelogCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<ForumLlmChangelog> $mapper =
      ForumLlmChangelogMapper.ensureInitialized();
  @override
  MapCopyWith<$R, String, String, ObjectCopyWith<$R, String, String>>?
  get entries => $value.entries != null
      ? MapCopyWith(
          $value.entries!,
          (v, t) => ObjectCopyWith(v, $identity, t),
          (v) => call(entries: v),
        )
      : null;
  @override
  $R call({Object? entries = $none, Object? url = $none}) => $apply(
    FieldCopyWithData({
      if (entries != $none) #entries: entries,
      if (url != $none) #url: url,
    }),
  );
  @override
  ForumLlmChangelog $make(CopyWithData data) => ForumLlmChangelog(
    entries: data.get(#entries, or: $value.entries),
    url: data.get(#url, or: $value.url),
  );

  @override
  ForumLlmChangelogCopyWith<$R2, ForumLlmChangelog, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _ForumLlmChangelogCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class ForumLlmSaveCompatMapper extends ClassMapperBase<ForumLlmSaveCompat> {
  ForumLlmSaveCompatMapper._();

  static ForumLlmSaveCompatMapper? _instance;
  static ForumLlmSaveCompatMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ForumLlmSaveCompatMapper._());
      CatalogSaveStatementMapper.ensureInitialized();
      ForumLlmUpdateNoteMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'ForumLlmSaveCompat';

  static CatalogSaveStatement? _$adding(ForumLlmSaveCompat v) => v.adding;
  static const Field<ForumLlmSaveCompat, CatalogSaveStatement> _f$adding =
      Field('adding', _$adding, opt: true);
  static CatalogSaveStatement? _$removing(ForumLlmSaveCompat v) => v.removing;
  static const Field<ForumLlmSaveCompat, CatalogSaveStatement> _f$removing =
      Field('removing', _$removing, opt: true);
  static List<ForumLlmUpdateNote>? _$updateNotes(ForumLlmSaveCompat v) =>
      v.updateNotes;
  static const Field<ForumLlmSaveCompat, List<ForumLlmUpdateNote>>
  _f$updateNotes = Field('updateNotes', _$updateNotes, opt: true);

  @override
  final MappableFields<ForumLlmSaveCompat> fields = const {
    #adding: _f$adding,
    #removing: _f$removing,
    #updateNotes: _f$updateNotes,
  };

  static ForumLlmSaveCompat _instantiate(DecodingData data) {
    return ForumLlmSaveCompat(
      adding: data.dec(_f$adding),
      removing: data.dec(_f$removing),
      updateNotes: data.dec(_f$updateNotes),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static ForumLlmSaveCompat fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<ForumLlmSaveCompat>(map);
  }

  static ForumLlmSaveCompat fromJson(String json) {
    return ensureInitialized().decodeJson<ForumLlmSaveCompat>(json);
  }
}

mixin ForumLlmSaveCompatMappable {
  String toJson() {
    return ForumLlmSaveCompatMapper.ensureInitialized()
        .encodeJson<ForumLlmSaveCompat>(this as ForumLlmSaveCompat);
  }

  Map<String, dynamic> toMap() {
    return ForumLlmSaveCompatMapper.ensureInitialized()
        .encodeMap<ForumLlmSaveCompat>(this as ForumLlmSaveCompat);
  }

  ForumLlmSaveCompatCopyWith<
    ForumLlmSaveCompat,
    ForumLlmSaveCompat,
    ForumLlmSaveCompat
  >
  get copyWith =>
      _ForumLlmSaveCompatCopyWithImpl<ForumLlmSaveCompat, ForumLlmSaveCompat>(
        this as ForumLlmSaveCompat,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return ForumLlmSaveCompatMapper.ensureInitialized().stringifyValue(
      this as ForumLlmSaveCompat,
    );
  }

  @override
  bool operator ==(Object other) {
    return ForumLlmSaveCompatMapper.ensureInitialized().equalsValue(
      this as ForumLlmSaveCompat,
      other,
    );
  }

  @override
  int get hashCode {
    return ForumLlmSaveCompatMapper.ensureInitialized().hashValue(
      this as ForumLlmSaveCompat,
    );
  }
}

extension ForumLlmSaveCompatValueCopy<$R, $Out>
    on ObjectCopyWith<$R, ForumLlmSaveCompat, $Out> {
  ForumLlmSaveCompatCopyWith<$R, ForumLlmSaveCompat, $Out>
  get $asForumLlmSaveCompat => $base.as(
    (v, t, t2) => _ForumLlmSaveCompatCopyWithImpl<$R, $Out>(v, t, t2),
  );
}

abstract class ForumLlmSaveCompatCopyWith<
  $R,
  $In extends ForumLlmSaveCompat,
  $Out
>
    implements ClassCopyWith<$R, $In, $Out> {
  CatalogSaveStatementCopyWith<$R, CatalogSaveStatement, CatalogSaveStatement>?
  get adding;
  CatalogSaveStatementCopyWith<$R, CatalogSaveStatement, CatalogSaveStatement>?
  get removing;
  ListCopyWith<
    $R,
    ForumLlmUpdateNote,
    ForumLlmUpdateNoteCopyWith<$R, ForumLlmUpdateNote, ForumLlmUpdateNote>
  >?
  get updateNotes;
  $R call({
    CatalogSaveStatement? adding,
    CatalogSaveStatement? removing,
    List<ForumLlmUpdateNote>? updateNotes,
  });
  ForumLlmSaveCompatCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _ForumLlmSaveCompatCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, ForumLlmSaveCompat, $Out>
    implements ForumLlmSaveCompatCopyWith<$R, ForumLlmSaveCompat, $Out> {
  _ForumLlmSaveCompatCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<ForumLlmSaveCompat> $mapper =
      ForumLlmSaveCompatMapper.ensureInitialized();
  @override
  CatalogSaveStatementCopyWith<$R, CatalogSaveStatement, CatalogSaveStatement>?
  get adding => $value.adding?.copyWith.$chain((v) => call(adding: v));
  @override
  CatalogSaveStatementCopyWith<$R, CatalogSaveStatement, CatalogSaveStatement>?
  get removing => $value.removing?.copyWith.$chain((v) => call(removing: v));
  @override
  ListCopyWith<
    $R,
    ForumLlmUpdateNote,
    ForumLlmUpdateNoteCopyWith<$R, ForumLlmUpdateNote, ForumLlmUpdateNote>
  >?
  get updateNotes => $value.updateNotes != null
      ? ListCopyWith(
          $value.updateNotes!,
          (v, t) => v.copyWith.$chain(t),
          (v) => call(updateNotes: v),
        )
      : null;
  @override
  $R call({
    Object? adding = $none,
    Object? removing = $none,
    Object? updateNotes = $none,
  }) => $apply(
    FieldCopyWithData({
      if (adding != $none) #adding: adding,
      if (removing != $none) #removing: removing,
      if (updateNotes != $none) #updateNotes: updateNotes,
    }),
  );
  @override
  ForumLlmSaveCompat $make(CopyWithData data) => ForumLlmSaveCompat(
    adding: data.get(#adding, or: $value.adding),
    removing: data.get(#removing, or: $value.removing),
    updateNotes: data.get(#updateNotes, or: $value.updateNotes),
  );

  @override
  ForumLlmSaveCompatCopyWith<$R2, ForumLlmSaveCompat, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _ForumLlmSaveCompatCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class ForumLlmUpdateNoteMapper extends ClassMapperBase<ForumLlmUpdateNote> {
  ForumLlmUpdateNoteMapper._();

  static ForumLlmUpdateNoteMapper? _instance;
  static ForumLlmUpdateNoteMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ForumLlmUpdateNoteMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'ForumLlmUpdateNote';

  static String? _$version(ForumLlmUpdateNote v) => v.version;
  static const Field<ForumLlmUpdateNote, String> _f$version = Field(
    'version',
    _$version,
    opt: true,
  );
  static String _$quote(ForumLlmUpdateNote v) => v.quote;
  static const Field<ForumLlmUpdateNote, String> _f$quote = Field(
    'quote',
    _$quote,
  );
  static String? _$answer(ForumLlmUpdateNote v) => v.answer;
  static const Field<ForumLlmUpdateNote, String> _f$answer = Field(
    'answer',
    _$answer,
    opt: true,
  );

  @override
  final MappableFields<ForumLlmUpdateNote> fields = const {
    #version: _f$version,
    #quote: _f$quote,
    #answer: _f$answer,
  };

  static ForumLlmUpdateNote _instantiate(DecodingData data) {
    return ForumLlmUpdateNote(
      version: data.dec(_f$version),
      quote: data.dec(_f$quote),
      answer: data.dec(_f$answer),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static ForumLlmUpdateNote fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<ForumLlmUpdateNote>(map);
  }

  static ForumLlmUpdateNote fromJson(String json) {
    return ensureInitialized().decodeJson<ForumLlmUpdateNote>(json);
  }
}

mixin ForumLlmUpdateNoteMappable {
  String toJson() {
    return ForumLlmUpdateNoteMapper.ensureInitialized()
        .encodeJson<ForumLlmUpdateNote>(this as ForumLlmUpdateNote);
  }

  Map<String, dynamic> toMap() {
    return ForumLlmUpdateNoteMapper.ensureInitialized()
        .encodeMap<ForumLlmUpdateNote>(this as ForumLlmUpdateNote);
  }

  ForumLlmUpdateNoteCopyWith<
    ForumLlmUpdateNote,
    ForumLlmUpdateNote,
    ForumLlmUpdateNote
  >
  get copyWith =>
      _ForumLlmUpdateNoteCopyWithImpl<ForumLlmUpdateNote, ForumLlmUpdateNote>(
        this as ForumLlmUpdateNote,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return ForumLlmUpdateNoteMapper.ensureInitialized().stringifyValue(
      this as ForumLlmUpdateNote,
    );
  }

  @override
  bool operator ==(Object other) {
    return ForumLlmUpdateNoteMapper.ensureInitialized().equalsValue(
      this as ForumLlmUpdateNote,
      other,
    );
  }

  @override
  int get hashCode {
    return ForumLlmUpdateNoteMapper.ensureInitialized().hashValue(
      this as ForumLlmUpdateNote,
    );
  }
}

extension ForumLlmUpdateNoteValueCopy<$R, $Out>
    on ObjectCopyWith<$R, ForumLlmUpdateNote, $Out> {
  ForumLlmUpdateNoteCopyWith<$R, ForumLlmUpdateNote, $Out>
  get $asForumLlmUpdateNote => $base.as(
    (v, t, t2) => _ForumLlmUpdateNoteCopyWithImpl<$R, $Out>(v, t, t2),
  );
}

abstract class ForumLlmUpdateNoteCopyWith<
  $R,
  $In extends ForumLlmUpdateNote,
  $Out
>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({String? version, String? quote, String? answer});
  ForumLlmUpdateNoteCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _ForumLlmUpdateNoteCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, ForumLlmUpdateNote, $Out>
    implements ForumLlmUpdateNoteCopyWith<$R, ForumLlmUpdateNote, $Out> {
  _ForumLlmUpdateNoteCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<ForumLlmUpdateNote> $mapper =
      ForumLlmUpdateNoteMapper.ensureInitialized();
  @override
  $R call({Object? version = $none, String? quote, Object? answer = $none}) =>
      $apply(
        FieldCopyWithData({
          if (version != $none) #version: version,
          if (quote != null) #quote: quote,
          if (answer != $none) #answer: answer,
        }),
      );
  @override
  ForumLlmUpdateNote $make(CopyWithData data) => ForumLlmUpdateNote(
    version: data.get(#version, or: $value.version),
    quote: data.get(#quote, or: $value.quote),
    answer: data.get(#answer, or: $value.answer),
  );

  @override
  ForumLlmUpdateNoteCopyWith<$R2, ForumLlmUpdateNote, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _ForumLlmUpdateNoteCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class ForumLlmRequirementsMapper extends ClassMapperBase<ForumLlmRequirements> {
  ForumLlmRequirementsMapper._();

  static ForumLlmRequirementsMapper? _instance;
  static ForumLlmRequirementsMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ForumLlmRequirementsMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'ForumLlmRequirements';

  static List<String>? _$required(ForumLlmRequirements v) => v.required;
  static const Field<ForumLlmRequirements, List<String>> _f$required = Field(
    'required',
    _$required,
    opt: true,
  );
  static List<String>? _$optional(ForumLlmRequirements v) => v.optional;
  static const Field<ForumLlmRequirements, List<String>> _f$optional = Field(
    'optional',
    _$optional,
    opt: true,
  );

  @override
  final MappableFields<ForumLlmRequirements> fields = const {
    #required: _f$required,
    #optional: _f$optional,
  };

  static ForumLlmRequirements _instantiate(DecodingData data) {
    return ForumLlmRequirements(
      required: data.dec(_f$required),
      optional: data.dec(_f$optional),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static ForumLlmRequirements fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<ForumLlmRequirements>(map);
  }

  static ForumLlmRequirements fromJson(String json) {
    return ensureInitialized().decodeJson<ForumLlmRequirements>(json);
  }
}

mixin ForumLlmRequirementsMappable {
  String toJson() {
    return ForumLlmRequirementsMapper.ensureInitialized()
        .encodeJson<ForumLlmRequirements>(this as ForumLlmRequirements);
  }

  Map<String, dynamic> toMap() {
    return ForumLlmRequirementsMapper.ensureInitialized()
        .encodeMap<ForumLlmRequirements>(this as ForumLlmRequirements);
  }

  ForumLlmRequirementsCopyWith<
    ForumLlmRequirements,
    ForumLlmRequirements,
    ForumLlmRequirements
  >
  get copyWith =>
      _ForumLlmRequirementsCopyWithImpl<
        ForumLlmRequirements,
        ForumLlmRequirements
      >(this as ForumLlmRequirements, $identity, $identity);
  @override
  String toString() {
    return ForumLlmRequirementsMapper.ensureInitialized().stringifyValue(
      this as ForumLlmRequirements,
    );
  }

  @override
  bool operator ==(Object other) {
    return ForumLlmRequirementsMapper.ensureInitialized().equalsValue(
      this as ForumLlmRequirements,
      other,
    );
  }

  @override
  int get hashCode {
    return ForumLlmRequirementsMapper.ensureInitialized().hashValue(
      this as ForumLlmRequirements,
    );
  }
}

extension ForumLlmRequirementsValueCopy<$R, $Out>
    on ObjectCopyWith<$R, ForumLlmRequirements, $Out> {
  ForumLlmRequirementsCopyWith<$R, ForumLlmRequirements, $Out>
  get $asForumLlmRequirements => $base.as(
    (v, t, t2) => _ForumLlmRequirementsCopyWithImpl<$R, $Out>(v, t, t2),
  );
}

abstract class ForumLlmRequirementsCopyWith<
  $R,
  $In extends ForumLlmRequirements,
  $Out
>
    implements ClassCopyWith<$R, $In, $Out> {
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>>? get required;
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>>? get optional;
  $R call({List<String>? required, List<String>? optional});
  ForumLlmRequirementsCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _ForumLlmRequirementsCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, ForumLlmRequirements, $Out>
    implements ForumLlmRequirementsCopyWith<$R, ForumLlmRequirements, $Out> {
  _ForumLlmRequirementsCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<ForumLlmRequirements> $mapper =
      ForumLlmRequirementsMapper.ensureInitialized();
  @override
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>>? get required =>
      $value.required != null
      ? ListCopyWith(
          $value.required!,
          (v, t) => ObjectCopyWith(v, $identity, t),
          (v) => call(required: v),
        )
      : null;
  @override
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>>? get optional =>
      $value.optional != null
      ? ListCopyWith(
          $value.optional!,
          (v, t) => ObjectCopyWith(v, $identity, t),
          (v) => call(optional: v),
        )
      : null;
  @override
  $R call({Object? required = $none, Object? optional = $none}) => $apply(
    FieldCopyWithData({
      if (required != $none) #required: required,
      if (optional != $none) #optional: optional,
    }),
  );
  @override
  ForumLlmRequirements $make(CopyWithData data) => ForumLlmRequirements(
    required: data.get(#required, or: $value.required),
    optional: data.get(#optional, or: $value.optional),
  );

  @override
  ForumLlmRequirementsCopyWith<$R2, ForumLlmRequirements, $Out2>
  $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _ForumLlmRequirementsCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class ForumLlmConflictMapper extends ClassMapperBase<ForumLlmConflict> {
  ForumLlmConflictMapper._();

  static ForumLlmConflictMapper? _instance;
  static ForumLlmConflictMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ForumLlmConflictMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'ForumLlmConflict';

  static String _$name(ForumLlmConflict v) => v.name;
  static const Field<ForumLlmConflict, String> _f$name = Field('name', _$name);
  static String _$quote(ForumLlmConflict v) => v.quote;
  static const Field<ForumLlmConflict, String> _f$quote = Field(
    'quote',
    _$quote,
  );

  @override
  final MappableFields<ForumLlmConflict> fields = const {
    #name: _f$name,
    #quote: _f$quote,
  };

  static ForumLlmConflict _instantiate(DecodingData data) {
    return ForumLlmConflict(name: data.dec(_f$name), quote: data.dec(_f$quote));
  }

  @override
  final Function instantiate = _instantiate;

  static ForumLlmConflict fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<ForumLlmConflict>(map);
  }

  static ForumLlmConflict fromJson(String json) {
    return ensureInitialized().decodeJson<ForumLlmConflict>(json);
  }
}

mixin ForumLlmConflictMappable {
  String toJson() {
    return ForumLlmConflictMapper.ensureInitialized()
        .encodeJson<ForumLlmConflict>(this as ForumLlmConflict);
  }

  Map<String, dynamic> toMap() {
    return ForumLlmConflictMapper.ensureInitialized()
        .encodeMap<ForumLlmConflict>(this as ForumLlmConflict);
  }

  ForumLlmConflictCopyWith<ForumLlmConflict, ForumLlmConflict, ForumLlmConflict>
  get copyWith =>
      _ForumLlmConflictCopyWithImpl<ForumLlmConflict, ForumLlmConflict>(
        this as ForumLlmConflict,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return ForumLlmConflictMapper.ensureInitialized().stringifyValue(
      this as ForumLlmConflict,
    );
  }

  @override
  bool operator ==(Object other) {
    return ForumLlmConflictMapper.ensureInitialized().equalsValue(
      this as ForumLlmConflict,
      other,
    );
  }

  @override
  int get hashCode {
    return ForumLlmConflictMapper.ensureInitialized().hashValue(
      this as ForumLlmConflict,
    );
  }
}

extension ForumLlmConflictValueCopy<$R, $Out>
    on ObjectCopyWith<$R, ForumLlmConflict, $Out> {
  ForumLlmConflictCopyWith<$R, ForumLlmConflict, $Out>
  get $asForumLlmConflict =>
      $base.as((v, t, t2) => _ForumLlmConflictCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class ForumLlmConflictCopyWith<$R, $In extends ForumLlmConflict, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({String? name, String? quote});
  ForumLlmConflictCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _ForumLlmConflictCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, ForumLlmConflict, $Out>
    implements ForumLlmConflictCopyWith<$R, ForumLlmConflict, $Out> {
  _ForumLlmConflictCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<ForumLlmConflict> $mapper =
      ForumLlmConflictMapper.ensureInitialized();
  @override
  $R call({String? name, String? quote}) => $apply(
    FieldCopyWithData({
      if (name != null) #name: name,
      if (quote != null) #quote: quote,
    }),
  );
  @override
  ForumLlmConflict $make(CopyWithData data) => ForumLlmConflict(
    name: data.get(#name, or: $value.name),
    quote: data.get(#quote, or: $value.quote),
  );

  @override
  ForumLlmConflictCopyWith<$R2, ForumLlmConflict, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _ForumLlmConflictCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class ForumLlmSourceCodeMapper extends ClassMapperBase<ForumLlmSourceCode> {
  ForumLlmSourceCodeMapper._();

  static ForumLlmSourceCodeMapper? _instance;
  static ForumLlmSourceCodeMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ForumLlmSourceCodeMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'ForumLlmSourceCode';

  static String? _$url(ForumLlmSourceCode v) => v.url;
  static const Field<ForumLlmSourceCode, String> _f$url = Field(
    'url',
    _$url,
    opt: true,
  );
  static String? _$license(ForumLlmSourceCode v) => v.license;
  static const Field<ForumLlmSourceCode, String> _f$license = Field(
    'license',
    _$license,
    opt: true,
  );

  @override
  final MappableFields<ForumLlmSourceCode> fields = const {
    #url: _f$url,
    #license: _f$license,
  };

  static ForumLlmSourceCode _instantiate(DecodingData data) {
    return ForumLlmSourceCode(
      url: data.dec(_f$url),
      license: data.dec(_f$license),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static ForumLlmSourceCode fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<ForumLlmSourceCode>(map);
  }

  static ForumLlmSourceCode fromJson(String json) {
    return ensureInitialized().decodeJson<ForumLlmSourceCode>(json);
  }
}

mixin ForumLlmSourceCodeMappable {
  String toJson() {
    return ForumLlmSourceCodeMapper.ensureInitialized()
        .encodeJson<ForumLlmSourceCode>(this as ForumLlmSourceCode);
  }

  Map<String, dynamic> toMap() {
    return ForumLlmSourceCodeMapper.ensureInitialized()
        .encodeMap<ForumLlmSourceCode>(this as ForumLlmSourceCode);
  }

  ForumLlmSourceCodeCopyWith<
    ForumLlmSourceCode,
    ForumLlmSourceCode,
    ForumLlmSourceCode
  >
  get copyWith =>
      _ForumLlmSourceCodeCopyWithImpl<ForumLlmSourceCode, ForumLlmSourceCode>(
        this as ForumLlmSourceCode,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return ForumLlmSourceCodeMapper.ensureInitialized().stringifyValue(
      this as ForumLlmSourceCode,
    );
  }

  @override
  bool operator ==(Object other) {
    return ForumLlmSourceCodeMapper.ensureInitialized().equalsValue(
      this as ForumLlmSourceCode,
      other,
    );
  }

  @override
  int get hashCode {
    return ForumLlmSourceCodeMapper.ensureInitialized().hashValue(
      this as ForumLlmSourceCode,
    );
  }
}

extension ForumLlmSourceCodeValueCopy<$R, $Out>
    on ObjectCopyWith<$R, ForumLlmSourceCode, $Out> {
  ForumLlmSourceCodeCopyWith<$R, ForumLlmSourceCode, $Out>
  get $asForumLlmSourceCode => $base.as(
    (v, t, t2) => _ForumLlmSourceCodeCopyWithImpl<$R, $Out>(v, t, t2),
  );
}

abstract class ForumLlmSourceCodeCopyWith<
  $R,
  $In extends ForumLlmSourceCode,
  $Out
>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({String? url, String? license});
  ForumLlmSourceCodeCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _ForumLlmSourceCodeCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, ForumLlmSourceCode, $Out>
    implements ForumLlmSourceCodeCopyWith<$R, ForumLlmSourceCode, $Out> {
  _ForumLlmSourceCodeCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<ForumLlmSourceCode> $mapper =
      ForumLlmSourceCodeMapper.ensureInitialized();
  @override
  $R call({Object? url = $none, Object? license = $none}) => $apply(
    FieldCopyWithData({
      if (url != $none) #url: url,
      if (license != $none) #license: license,
    }),
  );
  @override
  ForumLlmSourceCode $make(CopyWithData data) => ForumLlmSourceCode(
    url: data.get(#url, or: $value.url),
    license: data.get(#license, or: $value.license),
  );

  @override
  ForumLlmSourceCodeCopyWith<$R2, ForumLlmSourceCode, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _ForumLlmSourceCodeCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class ForumLlmSupportLinkMapper extends ClassMapperBase<ForumLlmSupportLink> {
  ForumLlmSupportLinkMapper._();

  static ForumLlmSupportLinkMapper? _instance;
  static ForumLlmSupportLinkMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ForumLlmSupportLinkMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'ForumLlmSupportLink';

  static String _$url(ForumLlmSupportLink v) => v.url;
  static const Field<ForumLlmSupportLink, String> _f$url = Field('url', _$url);
  static String _$type(ForumLlmSupportLink v) => v.type;
  static const Field<ForumLlmSupportLink, String> _f$type = Field(
    'type',
    _$type,
    opt: true,
    def: 'other',
  );

  @override
  final MappableFields<ForumLlmSupportLink> fields = const {
    #url: _f$url,
    #type: _f$type,
  };

  static ForumLlmSupportLink _instantiate(DecodingData data) {
    return ForumLlmSupportLink(url: data.dec(_f$url), type: data.dec(_f$type));
  }

  @override
  final Function instantiate = _instantiate;

  static ForumLlmSupportLink fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<ForumLlmSupportLink>(map);
  }

  static ForumLlmSupportLink fromJson(String json) {
    return ensureInitialized().decodeJson<ForumLlmSupportLink>(json);
  }
}

mixin ForumLlmSupportLinkMappable {
  String toJson() {
    return ForumLlmSupportLinkMapper.ensureInitialized()
        .encodeJson<ForumLlmSupportLink>(this as ForumLlmSupportLink);
  }

  Map<String, dynamic> toMap() {
    return ForumLlmSupportLinkMapper.ensureInitialized()
        .encodeMap<ForumLlmSupportLink>(this as ForumLlmSupportLink);
  }

  ForumLlmSupportLinkCopyWith<
    ForumLlmSupportLink,
    ForumLlmSupportLink,
    ForumLlmSupportLink
  >
  get copyWith =>
      _ForumLlmSupportLinkCopyWithImpl<
        ForumLlmSupportLink,
        ForumLlmSupportLink
      >(this as ForumLlmSupportLink, $identity, $identity);
  @override
  String toString() {
    return ForumLlmSupportLinkMapper.ensureInitialized().stringifyValue(
      this as ForumLlmSupportLink,
    );
  }

  @override
  bool operator ==(Object other) {
    return ForumLlmSupportLinkMapper.ensureInitialized().equalsValue(
      this as ForumLlmSupportLink,
      other,
    );
  }

  @override
  int get hashCode {
    return ForumLlmSupportLinkMapper.ensureInitialized().hashValue(
      this as ForumLlmSupportLink,
    );
  }
}

extension ForumLlmSupportLinkValueCopy<$R, $Out>
    on ObjectCopyWith<$R, ForumLlmSupportLink, $Out> {
  ForumLlmSupportLinkCopyWith<$R, ForumLlmSupportLink, $Out>
  get $asForumLlmSupportLink => $base.as(
    (v, t, t2) => _ForumLlmSupportLinkCopyWithImpl<$R, $Out>(v, t, t2),
  );
}

abstract class ForumLlmSupportLinkCopyWith<
  $R,
  $In extends ForumLlmSupportLink,
  $Out
>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({String? url, String? type});
  ForumLlmSupportLinkCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _ForumLlmSupportLinkCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, ForumLlmSupportLink, $Out>
    implements ForumLlmSupportLinkCopyWith<$R, ForumLlmSupportLink, $Out> {
  _ForumLlmSupportLinkCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<ForumLlmSupportLink> $mapper =
      ForumLlmSupportLinkMapper.ensureInitialized();
  @override
  $R call({String? url, String? type}) => $apply(
    FieldCopyWithData({
      if (url != null) #url: url,
      if (type != null) #type: type,
    }),
  );
  @override
  ForumLlmSupportLink $make(CopyWithData data) => ForumLlmSupportLink(
    url: data.get(#url, or: $value.url),
    type: data.get(#type, or: $value.type),
  );

  @override
  ForumLlmSupportLinkCopyWith<$R2, ForumLlmSupportLink, $Out2>
  $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _ForumLlmSupportLinkCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class ForumLlmDescriptionMapper extends ClassMapperBase<ForumLlmDescription> {
  ForumLlmDescriptionMapper._();

  static ForumLlmDescriptionMapper? _instance;
  static ForumLlmDescriptionMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ForumLlmDescriptionMapper._());
      ForumLlmSummaryMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'ForumLlmDescription';

  static ForumLlmSummary? _$summary(ForumLlmDescription v) => v.summary;
  static const Field<ForumLlmDescription, ForumLlmSummary> _f$summary = Field(
    'summary',
    _$summary,
    opt: true,
  );

  @override
  final MappableFields<ForumLlmDescription> fields = const {
    #summary: _f$summary,
  };

  static ForumLlmDescription _instantiate(DecodingData data) {
    return ForumLlmDescription(summary: data.dec(_f$summary));
  }

  @override
  final Function instantiate = _instantiate;

  static ForumLlmDescription fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<ForumLlmDescription>(map);
  }

  static ForumLlmDescription fromJson(String json) {
    return ensureInitialized().decodeJson<ForumLlmDescription>(json);
  }
}

mixin ForumLlmDescriptionMappable {
  String toJson() {
    return ForumLlmDescriptionMapper.ensureInitialized()
        .encodeJson<ForumLlmDescription>(this as ForumLlmDescription);
  }

  Map<String, dynamic> toMap() {
    return ForumLlmDescriptionMapper.ensureInitialized()
        .encodeMap<ForumLlmDescription>(this as ForumLlmDescription);
  }

  ForumLlmDescriptionCopyWith<
    ForumLlmDescription,
    ForumLlmDescription,
    ForumLlmDescription
  >
  get copyWith =>
      _ForumLlmDescriptionCopyWithImpl<
        ForumLlmDescription,
        ForumLlmDescription
      >(this as ForumLlmDescription, $identity, $identity);
  @override
  String toString() {
    return ForumLlmDescriptionMapper.ensureInitialized().stringifyValue(
      this as ForumLlmDescription,
    );
  }

  @override
  bool operator ==(Object other) {
    return ForumLlmDescriptionMapper.ensureInitialized().equalsValue(
      this as ForumLlmDescription,
      other,
    );
  }

  @override
  int get hashCode {
    return ForumLlmDescriptionMapper.ensureInitialized().hashValue(
      this as ForumLlmDescription,
    );
  }
}

extension ForumLlmDescriptionValueCopy<$R, $Out>
    on ObjectCopyWith<$R, ForumLlmDescription, $Out> {
  ForumLlmDescriptionCopyWith<$R, ForumLlmDescription, $Out>
  get $asForumLlmDescription => $base.as(
    (v, t, t2) => _ForumLlmDescriptionCopyWithImpl<$R, $Out>(v, t, t2),
  );
}

abstract class ForumLlmDescriptionCopyWith<
  $R,
  $In extends ForumLlmDescription,
  $Out
>
    implements ClassCopyWith<$R, $In, $Out> {
  ForumLlmSummaryCopyWith<$R, ForumLlmSummary, ForumLlmSummary>? get summary;
  $R call({ForumLlmSummary? summary});
  ForumLlmDescriptionCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _ForumLlmDescriptionCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, ForumLlmDescription, $Out>
    implements ForumLlmDescriptionCopyWith<$R, ForumLlmDescription, $Out> {
  _ForumLlmDescriptionCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<ForumLlmDescription> $mapper =
      ForumLlmDescriptionMapper.ensureInitialized();
  @override
  ForumLlmSummaryCopyWith<$R, ForumLlmSummary, ForumLlmSummary>? get summary =>
      $value.summary?.copyWith.$chain((v) => call(summary: v));
  @override
  $R call({Object? summary = $none}) =>
      $apply(FieldCopyWithData({if (summary != $none) #summary: summary}));
  @override
  ForumLlmDescription $make(CopyWithData data) =>
      ForumLlmDescription(summary: data.get(#summary, or: $value.summary));

  @override
  ForumLlmDescriptionCopyWith<$R2, ForumLlmDescription, $Out2>
  $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _ForumLlmDescriptionCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class ForumLlmSummaryMapper extends ClassMapperBase<ForumLlmSummary> {
  ForumLlmSummaryMapper._();

  static ForumLlmSummaryMapper? _instance;
  static ForumLlmSummaryMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ForumLlmSummaryMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'ForumLlmSummary';

  static String _$sentence(ForumLlmSummary v) => v.sentence;
  static const Field<ForumLlmSummary, String> _f$sentence = Field(
    'sentence',
    _$sentence,
  );
  static String? _$paragraph(ForumLlmSummary v) => v.paragraph;
  static const Field<ForumLlmSummary, String> _f$paragraph = Field(
    'paragraph',
    _$paragraph,
    opt: true,
  );

  @override
  final MappableFields<ForumLlmSummary> fields = const {
    #sentence: _f$sentence,
    #paragraph: _f$paragraph,
  };

  static ForumLlmSummary _instantiate(DecodingData data) {
    return ForumLlmSummary(
      sentence: data.dec(_f$sentence),
      paragraph: data.dec(_f$paragraph),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static ForumLlmSummary fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<ForumLlmSummary>(map);
  }

  static ForumLlmSummary fromJson(String json) {
    return ensureInitialized().decodeJson<ForumLlmSummary>(json);
  }
}

mixin ForumLlmSummaryMappable {
  String toJson() {
    return ForumLlmSummaryMapper.ensureInitialized()
        .encodeJson<ForumLlmSummary>(this as ForumLlmSummary);
  }

  Map<String, dynamic> toMap() {
    return ForumLlmSummaryMapper.ensureInitialized().encodeMap<ForumLlmSummary>(
      this as ForumLlmSummary,
    );
  }

  ForumLlmSummaryCopyWith<ForumLlmSummary, ForumLlmSummary, ForumLlmSummary>
  get copyWith =>
      _ForumLlmSummaryCopyWithImpl<ForumLlmSummary, ForumLlmSummary>(
        this as ForumLlmSummary,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return ForumLlmSummaryMapper.ensureInitialized().stringifyValue(
      this as ForumLlmSummary,
    );
  }

  @override
  bool operator ==(Object other) {
    return ForumLlmSummaryMapper.ensureInitialized().equalsValue(
      this as ForumLlmSummary,
      other,
    );
  }

  @override
  int get hashCode {
    return ForumLlmSummaryMapper.ensureInitialized().hashValue(
      this as ForumLlmSummary,
    );
  }
}

extension ForumLlmSummaryValueCopy<$R, $Out>
    on ObjectCopyWith<$R, ForumLlmSummary, $Out> {
  ForumLlmSummaryCopyWith<$R, ForumLlmSummary, $Out> get $asForumLlmSummary =>
      $base.as((v, t, t2) => _ForumLlmSummaryCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class ForumLlmSummaryCopyWith<$R, $In extends ForumLlmSummary, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({String? sentence, String? paragraph});
  ForumLlmSummaryCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _ForumLlmSummaryCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, ForumLlmSummary, $Out>
    implements ForumLlmSummaryCopyWith<$R, ForumLlmSummary, $Out> {
  _ForumLlmSummaryCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<ForumLlmSummary> $mapper =
      ForumLlmSummaryMapper.ensureInitialized();
  @override
  $R call({String? sentence, Object? paragraph = $none}) => $apply(
    FieldCopyWithData({
      if (sentence != null) #sentence: sentence,
      if (paragraph != $none) #paragraph: paragraph,
    }),
  );
  @override
  ForumLlmSummary $make(CopyWithData data) => ForumLlmSummary(
    sentence: data.get(#sentence, or: $value.sentence),
    paragraph: data.get(#paragraph, or: $value.paragraph),
  );

  @override
  ForumLlmSummaryCopyWith<$R2, ForumLlmSummary, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _ForumLlmSummaryCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

