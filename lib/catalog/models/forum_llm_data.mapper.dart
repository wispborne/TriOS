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

class LlmDownloadKindMapper extends EnumMapper<LlmDownloadKind> {
  LlmDownloadKindMapper._();

  static LlmDownloadKindMapper? _instance;
  static LlmDownloadKindMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = LlmDownloadKindMapper._());
    }
    return _instance!;
  }

  static LlmDownloadKind fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  LlmDownloadKind decode(dynamic value) {
    switch (value) {
      case r'trios':
        return LlmDownloadKind.trios;
      case r'direct':
        return LlmDownloadKind.direct;
      case r'mirror':
        return LlmDownloadKind.mirror;
      case r'unknown':
        return LlmDownloadKind.unknown;
      default:
        return LlmDownloadKind.values[3];
    }
  }

  @override
  dynamic encode(LlmDownloadKind self) {
    switch (self) {
      case LlmDownloadKind.trios:
        return r'trios';
      case LlmDownloadKind.direct:
        return r'direct';
      case LlmDownloadKind.mirror:
        return r'mirror';
      case LlmDownloadKind.unknown:
        return r'unknown';
    }
  }
}

extension LlmDownloadKindMapperExtension on LlmDownloadKind {
  String toValue() {
    LlmDownloadKindMapper.ensureInitialized();
    return MapperContainer.globals.toValue<LlmDownloadKind>(this) as String;
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
      ForumLlmExtrasMapper.ensureInitialized();
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
  static List<String>? _$requires(ForumLlmMod v) => v.requires;
  static const Field<ForumLlmMod, List<String>> _f$requires = Field(
    'requires',
    _$requires,
    opt: true,
  );
  static List<ForumLlmDownload> _$downloads(ForumLlmMod v) => v.downloads;
  static const Field<ForumLlmMod, List<ForumLlmDownload>> _f$downloads = Field(
    'downloads',
    _$downloads,
    opt: true,
    def: const [],
  );
  static ForumLlmExtras? _$extras(ForumLlmMod v) => v.extras;
  static const Field<ForumLlmMod, ForumLlmExtras> _f$extras = Field(
    'extras',
    _$extras,
    opt: true,
  );

  @override
  final MappableFields<ForumLlmMod> fields = const {
    #name: _f$name,
    #role: _f$role,
    #requires: _f$requires,
    #downloads: _f$downloads,
    #extras: _f$extras,
  };

  static ForumLlmMod _instantiate(DecodingData data) {
    return ForumLlmMod(
      name: data.dec(_f$name),
      role: data.dec(_f$role),
      requires: data.dec(_f$requires),
      downloads: data.dec(_f$downloads),
      extras: data.dec(_f$extras),
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
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>>? get requires;
  ListCopyWith<
    $R,
    ForumLlmDownload,
    ForumLlmDownloadCopyWith<$R, ForumLlmDownload, ForumLlmDownload>
  >
  get downloads;
  ForumLlmExtrasCopyWith<$R, ForumLlmExtras, ForumLlmExtras>? get extras;
  $R call({
    String? name,
    LlmModRole? role,
    List<String>? requires,
    List<ForumLlmDownload>? downloads,
    ForumLlmExtras? extras,
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
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>>? get requires =>
      $value.requires != null
      ? ListCopyWith(
          $value.requires!,
          (v, t) => ObjectCopyWith(v, $identity, t),
          (v) => call(requires: v),
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
  ForumLlmExtrasCopyWith<$R, ForumLlmExtras, ForumLlmExtras>? get extras =>
      $value.extras?.copyWith.$chain((v) => call(extras: v));
  @override
  $R call({
    String? name,
    LlmModRole? role,
    Object? requires = $none,
    List<ForumLlmDownload>? downloads,
    Object? extras = $none,
  }) => $apply(
    FieldCopyWithData({
      if (name != null) #name: name,
      if (role != null) #role: role,
      if (requires != $none) #requires: requires,
      if (downloads != null) #downloads: downloads,
      if (extras != $none) #extras: extras,
    }),
  );
  @override
  ForumLlmMod $make(CopyWithData data) => ForumLlmMod(
    name: data.get(#name, or: $value.name),
    role: data.get(#role, or: $value.role),
    requires: data.get(#requires, or: $value.requires),
    downloads: data.get(#downloads, or: $value.downloads),
    extras: data.get(#extras, or: $value.extras),
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
      LlmDownloadKindMapper.ensureInitialized();
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
  static LlmDownloadKind _$kind(ForumLlmDownload v) => v.kind;
  static const Field<ForumLlmDownload, LlmDownloadKind> _f$kind = Field(
    'kind',
    _$kind,
    opt: true,
    def: LlmDownloadKind.unknown,
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
    #kind: _f$kind,
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
      kind: data.dec(_f$kind),
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
    LlmDownloadKind? kind,
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
    LlmDownloadKind? kind,
    LlmDownloadConfidence? confidence,
    bool? requiresManualStep,
    Object? sourceHost = $none,
    Object? resolvedDirectUrl = $none,
    Object? fileName = $none,
  }) => $apply(
    FieldCopyWithData({
      if (url != null) #url: url,
      if (label != null) #label: label,
      if (kind != null) #kind: kind,
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
    kind: data.get(#kind, or: $value.kind),
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

class ForumLlmExtrasMapper extends ClassMapperBase<ForumLlmExtras> {
  ForumLlmExtrasMapper._();

  static ForumLlmExtrasMapper? _instance;
  static ForumLlmExtrasMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ForumLlmExtrasMapper._());
      ForumLlmSummaryMapper.ensureInitialized();
      ForumLlmChangelogMapper.ensureInitialized();
      ForumLlmSupportLinkMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'ForumLlmExtras';

  static String? _$version(ForumLlmExtras v) => v.version;
  static const Field<ForumLlmExtras, String> _f$version = Field(
    'version',
    _$version,
    opt: true,
  );
  static ForumLlmSummary? _$summary(ForumLlmExtras v) => v.summary;
  static const Field<ForumLlmExtras, ForumLlmSummary> _f$summary = Field(
    'summary',
    _$summary,
    opt: true,
  );
  static ForumLlmChangelog? _$changelog(ForumLlmExtras v) => v.changelog;
  static const Field<ForumLlmExtras, ForumLlmChangelog> _f$changelog = Field(
    'changelog',
    _$changelog,
    opt: true,
  );
  static String? _$license(ForumLlmExtras v) => v.license;
  static const Field<ForumLlmExtras, String> _f$license = Field(
    'license',
    _$license,
    opt: true,
  );
  static List<ForumLlmSupportLink>? _$supportLinks(ForumLlmExtras v) =>
      v.supportLinks;
  static const Field<ForumLlmExtras, List<ForumLlmSupportLink>>
  _f$supportLinks = Field('supportLinks', _$supportLinks, opt: true);

  @override
  final MappableFields<ForumLlmExtras> fields = const {
    #version: _f$version,
    #summary: _f$summary,
    #changelog: _f$changelog,
    #license: _f$license,
    #supportLinks: _f$supportLinks,
  };

  static ForumLlmExtras _instantiate(DecodingData data) {
    return ForumLlmExtras(
      version: data.dec(_f$version),
      summary: data.dec(_f$summary),
      changelog: data.dec(_f$changelog),
      license: data.dec(_f$license),
      supportLinks: data.dec(_f$supportLinks),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static ForumLlmExtras fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<ForumLlmExtras>(map);
  }

  static ForumLlmExtras fromJson(String json) {
    return ensureInitialized().decodeJson<ForumLlmExtras>(json);
  }
}

mixin ForumLlmExtrasMappable {
  String toJson() {
    return ForumLlmExtrasMapper.ensureInitialized().encodeJson<ForumLlmExtras>(
      this as ForumLlmExtras,
    );
  }

  Map<String, dynamic> toMap() {
    return ForumLlmExtrasMapper.ensureInitialized().encodeMap<ForumLlmExtras>(
      this as ForumLlmExtras,
    );
  }

  ForumLlmExtrasCopyWith<ForumLlmExtras, ForumLlmExtras, ForumLlmExtras>
  get copyWith => _ForumLlmExtrasCopyWithImpl<ForumLlmExtras, ForumLlmExtras>(
    this as ForumLlmExtras,
    $identity,
    $identity,
  );
  @override
  String toString() {
    return ForumLlmExtrasMapper.ensureInitialized().stringifyValue(
      this as ForumLlmExtras,
    );
  }

  @override
  bool operator ==(Object other) {
    return ForumLlmExtrasMapper.ensureInitialized().equalsValue(
      this as ForumLlmExtras,
      other,
    );
  }

  @override
  int get hashCode {
    return ForumLlmExtrasMapper.ensureInitialized().hashValue(
      this as ForumLlmExtras,
    );
  }
}

extension ForumLlmExtrasValueCopy<$R, $Out>
    on ObjectCopyWith<$R, ForumLlmExtras, $Out> {
  ForumLlmExtrasCopyWith<$R, ForumLlmExtras, $Out> get $asForumLlmExtras =>
      $base.as((v, t, t2) => _ForumLlmExtrasCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class ForumLlmExtrasCopyWith<$R, $In extends ForumLlmExtras, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  ForumLlmSummaryCopyWith<$R, ForumLlmSummary, ForumLlmSummary>? get summary;
  ForumLlmChangelogCopyWith<$R, ForumLlmChangelog, ForumLlmChangelog>?
  get changelog;
  ListCopyWith<
    $R,
    ForumLlmSupportLink,
    ForumLlmSupportLinkCopyWith<$R, ForumLlmSupportLink, ForumLlmSupportLink>
  >?
  get supportLinks;
  $R call({
    String? version,
    ForumLlmSummary? summary,
    ForumLlmChangelog? changelog,
    String? license,
    List<ForumLlmSupportLink>? supportLinks,
  });
  ForumLlmExtrasCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _ForumLlmExtrasCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, ForumLlmExtras, $Out>
    implements ForumLlmExtrasCopyWith<$R, ForumLlmExtras, $Out> {
  _ForumLlmExtrasCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<ForumLlmExtras> $mapper =
      ForumLlmExtrasMapper.ensureInitialized();
  @override
  ForumLlmSummaryCopyWith<$R, ForumLlmSummary, ForumLlmSummary>? get summary =>
      $value.summary?.copyWith.$chain((v) => call(summary: v));
  @override
  ForumLlmChangelogCopyWith<$R, ForumLlmChangelog, ForumLlmChangelog>?
  get changelog => $value.changelog?.copyWith.$chain((v) => call(changelog: v));
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
  $R call({
    Object? version = $none,
    Object? summary = $none,
    Object? changelog = $none,
    Object? license = $none,
    Object? supportLinks = $none,
  }) => $apply(
    FieldCopyWithData({
      if (version != $none) #version: version,
      if (summary != $none) #summary: summary,
      if (changelog != $none) #changelog: changelog,
      if (license != $none) #license: license,
      if (supportLinks != $none) #supportLinks: supportLinks,
    }),
  );
  @override
  ForumLlmExtras $make(CopyWithData data) => ForumLlmExtras(
    version: data.get(#version, or: $value.version),
    summary: data.get(#summary, or: $value.summary),
    changelog: data.get(#changelog, or: $value.changelog),
    license: data.get(#license, or: $value.license),
    supportLinks: data.get(#supportLinks, or: $value.supportLinks),
  );

  @override
  ForumLlmExtrasCopyWith<$R2, ForumLlmExtras, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _ForumLlmExtrasCopyWithImpl<$R2, $Out2>($value, $cast, t);
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
  static String _$paragraph(ForumLlmSummary v) => v.paragraph;
  static const Field<ForumLlmSummary, String> _f$paragraph = Field(
    'paragraph',
    _$paragraph,
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
  $R call({String? sentence, String? paragraph}) => $apply(
    FieldCopyWithData({
      if (sentence != null) #sentence: sentence,
      if (paragraph != null) #paragraph: paragraph,
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
  static String? _$link(ForumLlmChangelog v) => v.link;
  static const Field<ForumLlmChangelog, String> _f$link = Field(
    'link',
    _$link,
    opt: true,
  );

  @override
  final MappableFields<ForumLlmChangelog> fields = const {
    #entries: _f$entries,
    #link: _f$link,
  };

  static ForumLlmChangelog _instantiate(DecodingData data) {
    return ForumLlmChangelog(
      entries: data.dec(_f$entries),
      link: data.dec(_f$link),
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
  $R call({Map<String, String>? entries, String? link});
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
  $R call({Object? entries = $none, Object? link = $none}) => $apply(
    FieldCopyWithData({
      if (entries != $none) #entries: entries,
      if (link != $none) #link: link,
    }),
  );
  @override
  ForumLlmChangelog $make(CopyWithData data) => ForumLlmChangelog(
    entries: data.get(#entries, or: $value.entries),
    link: data.get(#link, or: $value.link),
  );

  @override
  ForumLlmChangelogCopyWith<$R2, ForumLlmChangelog, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _ForumLlmChangelogCopyWithImpl<$R2, $Out2>($value, $cast, t);
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

