// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'catalog_extras.dart';

class CatalogSaveAnswerMapper extends EnumMapper<CatalogSaveAnswer> {
  CatalogSaveAnswerMapper._();

  static CatalogSaveAnswerMapper? _instance;
  static CatalogSaveAnswerMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = CatalogSaveAnswerMapper._());
    }
    return _instance!;
  }

  static CatalogSaveAnswer fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  CatalogSaveAnswer decode(dynamic value) {
    switch (value) {
      case r'yes':
        return CatalogSaveAnswer.yes;
      case r'no':
        return CatalogSaveAnswer.no;
      case r'depends':
        return CatalogSaveAnswer.depends;
      case r'unknown':
        return CatalogSaveAnswer.unknown;
      default:
        return CatalogSaveAnswer.values[3];
    }
  }

  @override
  dynamic encode(CatalogSaveAnswer self) {
    switch (self) {
      case CatalogSaveAnswer.yes:
        return r'yes';
      case CatalogSaveAnswer.no:
        return r'no';
      case CatalogSaveAnswer.depends:
        return r'depends';
      case CatalogSaveAnswer.unknown:
        return r'unknown';
    }
  }
}

extension CatalogSaveAnswerMapperExtension on CatalogSaveAnswer {
  String toValue() {
    CatalogSaveAnswerMapper.ensureInitialized();
    return MapperContainer.globals.toValue<CatalogSaveAnswer>(this) as String;
  }
}

class CatalogPictureKindMapper extends EnumMapper<CatalogPictureKind> {
  CatalogPictureKindMapper._();

  static CatalogPictureKindMapper? _instance;
  static CatalogPictureKindMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = CatalogPictureKindMapper._());
    }
    return _instance!;
  }

  static CatalogPictureKind fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  CatalogPictureKind decode(dynamic value) {
    switch (value) {
      case r'screenshot':
        return CatalogPictureKind.screenshot;
      case r'logo':
        return CatalogPictureKind.logo;
      case r'banner':
        return CatalogPictureKind.banner;
      case r'art':
        return CatalogPictureKind.art;
      case r'button':
        return CatalogPictureKind.button;
      case r'badge':
        return CatalogPictureKind.badge;
      case r'divider':
        return CatalogPictureKind.divider;
      case r'missing':
        return CatalogPictureKind.missing;
      case r'other':
        return CatalogPictureKind.other;
      case r'unknown':
        return CatalogPictureKind.unknown;
      default:
        return CatalogPictureKind.values[9];
    }
  }

  @override
  dynamic encode(CatalogPictureKind self) {
    switch (self) {
      case CatalogPictureKind.screenshot:
        return r'screenshot';
      case CatalogPictureKind.logo:
        return r'logo';
      case CatalogPictureKind.banner:
        return r'banner';
      case CatalogPictureKind.art:
        return r'art';
      case CatalogPictureKind.button:
        return r'button';
      case CatalogPictureKind.badge:
        return r'badge';
      case CatalogPictureKind.divider:
        return r'divider';
      case CatalogPictureKind.missing:
        return r'missing';
      case CatalogPictureKind.other:
        return r'other';
      case CatalogPictureKind.unknown:
        return r'unknown';
    }
  }
}

extension CatalogPictureKindMapperExtension on CatalogPictureKind {
  String toValue() {
    CatalogPictureKindMapper.ensureInitialized();
    return MapperContainer.globals.toValue<CatalogPictureKind>(this) as String;
  }
}

class CatalogPictureFitMapper extends EnumMapper<CatalogPictureFit> {
  CatalogPictureFitMapper._();

  static CatalogPictureFitMapper? _instance;
  static CatalogPictureFitMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = CatalogPictureFitMapper._());
    }
    return _instance!;
  }

  static CatalogPictureFit fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  CatalogPictureFit decode(dynamic value) {
    switch (value) {
      case r'good':
        return CatalogPictureFit.good;
      case r'okay':
        return CatalogPictureFit.okay;
      case r'poor':
        return CatalogPictureFit.poor;
      case r'unknown':
        return CatalogPictureFit.unknown;
      default:
        return CatalogPictureFit.values[3];
    }
  }

  @override
  dynamic encode(CatalogPictureFit self) {
    switch (self) {
      case CatalogPictureFit.good:
        return r'good';
      case CatalogPictureFit.okay:
        return r'okay';
      case CatalogPictureFit.poor:
        return r'poor';
      case CatalogPictureFit.unknown:
        return r'unknown';
    }
  }
}

extension CatalogPictureFitMapperExtension on CatalogPictureFit {
  String toValue() {
    CatalogPictureFitMapper.ensureInitialized();
    return MapperContainer.globals.toValue<CatalogPictureFit>(this) as String;
  }
}

class CatalogPictureSourceMapper extends EnumMapper<CatalogPictureSource> {
  CatalogPictureSourceMapper._();

  static CatalogPictureSourceMapper? _instance;
  static CatalogPictureSourceMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = CatalogPictureSourceMapper._());
    }
    return _instance!;
  }

  static CatalogPictureSource fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  CatalogPictureSource decode(dynamic value) {
    switch (value) {
      case r'forum':
        return CatalogPictureSource.forum;
      case r'discord':
        return CatalogPictureSource.discord;
      case r'nexus':
        return CatalogPictureSource.nexus;
      case r'unknown':
        return CatalogPictureSource.unknown;
      default:
        return CatalogPictureSource.values[3];
    }
  }

  @override
  dynamic encode(CatalogPictureSource self) {
    switch (self) {
      case CatalogPictureSource.forum:
        return r'forum';
      case CatalogPictureSource.discord:
        return r'discord';
      case CatalogPictureSource.nexus:
        return r'nexus';
      case CatalogPictureSource.unknown:
        return r'unknown';
    }
  }
}

extension CatalogPictureSourceMapperExtension on CatalogPictureSource {
  String toValue() {
    CatalogPictureSourceMapper.ensureInitialized();
    return MapperContainer.globals.toValue<CatalogPictureSource>(this)
        as String;
  }
}

class CatalogAiUseMapper extends ClassMapperBase<CatalogAiUse> {
  CatalogAiUseMapper._();

  static CatalogAiUseMapper? _instance;
  static CatalogAiUseMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = CatalogAiUseMapper._());
      CatalogAiUseEntryMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'CatalogAiUse';

  static bool? _$usesAi(CatalogAiUse v) => v.usesAi;
  static const Field<CatalogAiUse, bool> _f$usesAi = Field(
    'usesAi',
    _$usesAi,
    opt: true,
  );
  static List<CatalogAiUseEntry>? _$uses(CatalogAiUse v) => v.uses;
  static const Field<CatalogAiUse, List<CatalogAiUseEntry>> _f$uses = Field(
    'uses',
    _$uses,
    opt: true,
  );
  static List<String>? _$tools(CatalogAiUse v) => v.tools;
  static const Field<CatalogAiUse, List<String>> _f$tools = Field(
    'tools',
    _$tools,
    opt: true,
  );
  static String? _$quote(CatalogAiUse v) => v.quote;
  static const Field<CatalogAiUse, String> _f$quote = Field(
    'quote',
    _$quote,
    opt: true,
  );

  @override
  final MappableFields<CatalogAiUse> fields = const {
    #usesAi: _f$usesAi,
    #uses: _f$uses,
    #tools: _f$tools,
    #quote: _f$quote,
  };

  static CatalogAiUse _instantiate(DecodingData data) {
    return CatalogAiUse(
      usesAi: data.dec(_f$usesAi),
      uses: data.dec(_f$uses),
      tools: data.dec(_f$tools),
      quote: data.dec(_f$quote),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static CatalogAiUse fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<CatalogAiUse>(map);
  }

  static CatalogAiUse fromJson(String json) {
    return ensureInitialized().decodeJson<CatalogAiUse>(json);
  }
}

mixin CatalogAiUseMappable {
  String toJson() {
    return CatalogAiUseMapper.ensureInitialized().encodeJson<CatalogAiUse>(
      this as CatalogAiUse,
    );
  }

  Map<String, dynamic> toMap() {
    return CatalogAiUseMapper.ensureInitialized().encodeMap<CatalogAiUse>(
      this as CatalogAiUse,
    );
  }

  CatalogAiUseCopyWith<CatalogAiUse, CatalogAiUse, CatalogAiUse> get copyWith =>
      _CatalogAiUseCopyWithImpl<CatalogAiUse, CatalogAiUse>(
        this as CatalogAiUse,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return CatalogAiUseMapper.ensureInitialized().stringifyValue(
      this as CatalogAiUse,
    );
  }

  @override
  bool operator ==(Object other) {
    return CatalogAiUseMapper.ensureInitialized().equalsValue(
      this as CatalogAiUse,
      other,
    );
  }

  @override
  int get hashCode {
    return CatalogAiUseMapper.ensureInitialized().hashValue(
      this as CatalogAiUse,
    );
  }
}

extension CatalogAiUseValueCopy<$R, $Out>
    on ObjectCopyWith<$R, CatalogAiUse, $Out> {
  CatalogAiUseCopyWith<$R, CatalogAiUse, $Out> get $asCatalogAiUse =>
      $base.as((v, t, t2) => _CatalogAiUseCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class CatalogAiUseCopyWith<$R, $In extends CatalogAiUse, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  ListCopyWith<
    $R,
    CatalogAiUseEntry,
    CatalogAiUseEntryCopyWith<$R, CatalogAiUseEntry, CatalogAiUseEntry>
  >?
  get uses;
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>>? get tools;
  $R call({
    bool? usesAi,
    List<CatalogAiUseEntry>? uses,
    List<String>? tools,
    String? quote,
  });
  CatalogAiUseCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _CatalogAiUseCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, CatalogAiUse, $Out>
    implements CatalogAiUseCopyWith<$R, CatalogAiUse, $Out> {
  _CatalogAiUseCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<CatalogAiUse> $mapper =
      CatalogAiUseMapper.ensureInitialized();
  @override
  ListCopyWith<
    $R,
    CatalogAiUseEntry,
    CatalogAiUseEntryCopyWith<$R, CatalogAiUseEntry, CatalogAiUseEntry>
  >?
  get uses => $value.uses != null
      ? ListCopyWith(
          $value.uses!,
          (v, t) => v.copyWith.$chain(t),
          (v) => call(uses: v),
        )
      : null;
  @override
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>>? get tools =>
      $value.tools != null
      ? ListCopyWith(
          $value.tools!,
          (v, t) => ObjectCopyWith(v, $identity, t),
          (v) => call(tools: v),
        )
      : null;
  @override
  $R call({
    Object? usesAi = $none,
    Object? uses = $none,
    Object? tools = $none,
    Object? quote = $none,
  }) => $apply(
    FieldCopyWithData({
      if (usesAi != $none) #usesAi: usesAi,
      if (uses != $none) #uses: uses,
      if (tools != $none) #tools: tools,
      if (quote != $none) #quote: quote,
    }),
  );
  @override
  CatalogAiUse $make(CopyWithData data) => CatalogAiUse(
    usesAi: data.get(#usesAi, or: $value.usesAi),
    uses: data.get(#uses, or: $value.uses),
    tools: data.get(#tools, or: $value.tools),
    quote: data.get(#quote, or: $value.quote),
  );

  @override
  CatalogAiUseCopyWith<$R2, CatalogAiUse, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _CatalogAiUseCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class CatalogAiUseEntryMapper extends ClassMapperBase<CatalogAiUseEntry> {
  CatalogAiUseEntryMapper._();

  static CatalogAiUseEntryMapper? _instance;
  static CatalogAiUseEntryMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = CatalogAiUseEntryMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'CatalogAiUseEntry';

  static String _$area(CatalogAiUseEntry v) => v.area;
  static const Field<CatalogAiUseEntry, String> _f$area = Field('area', _$area);
  static String? _$how(CatalogAiUseEntry v) => v.how;
  static const Field<CatalogAiUseEntry, String> _f$how = Field(
    'how',
    _$how,
    opt: true,
  );
  static String? _$extent(CatalogAiUseEntry v) => v.extent;
  static const Field<CatalogAiUseEntry, String> _f$extent = Field(
    'extent',
    _$extent,
    opt: true,
  );
  static bool? _$isOptional(CatalogAiUseEntry v) => v.isOptional;
  static const Field<CatalogAiUseEntry, bool> _f$isOptional = Field(
    'isOptional',
    _$isOptional,
    opt: true,
  );

  @override
  final MappableFields<CatalogAiUseEntry> fields = const {
    #area: _f$area,
    #how: _f$how,
    #extent: _f$extent,
    #isOptional: _f$isOptional,
  };

  static CatalogAiUseEntry _instantiate(DecodingData data) {
    return CatalogAiUseEntry(
      area: data.dec(_f$area),
      how: data.dec(_f$how),
      extent: data.dec(_f$extent),
      isOptional: data.dec(_f$isOptional),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static CatalogAiUseEntry fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<CatalogAiUseEntry>(map);
  }

  static CatalogAiUseEntry fromJson(String json) {
    return ensureInitialized().decodeJson<CatalogAiUseEntry>(json);
  }
}

mixin CatalogAiUseEntryMappable {
  String toJson() {
    return CatalogAiUseEntryMapper.ensureInitialized()
        .encodeJson<CatalogAiUseEntry>(this as CatalogAiUseEntry);
  }

  Map<String, dynamic> toMap() {
    return CatalogAiUseEntryMapper.ensureInitialized()
        .encodeMap<CatalogAiUseEntry>(this as CatalogAiUseEntry);
  }

  CatalogAiUseEntryCopyWith<
    CatalogAiUseEntry,
    CatalogAiUseEntry,
    CatalogAiUseEntry
  >
  get copyWith =>
      _CatalogAiUseEntryCopyWithImpl<CatalogAiUseEntry, CatalogAiUseEntry>(
        this as CatalogAiUseEntry,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return CatalogAiUseEntryMapper.ensureInitialized().stringifyValue(
      this as CatalogAiUseEntry,
    );
  }

  @override
  bool operator ==(Object other) {
    return CatalogAiUseEntryMapper.ensureInitialized().equalsValue(
      this as CatalogAiUseEntry,
      other,
    );
  }

  @override
  int get hashCode {
    return CatalogAiUseEntryMapper.ensureInitialized().hashValue(
      this as CatalogAiUseEntry,
    );
  }
}

extension CatalogAiUseEntryValueCopy<$R, $Out>
    on ObjectCopyWith<$R, CatalogAiUseEntry, $Out> {
  CatalogAiUseEntryCopyWith<$R, CatalogAiUseEntry, $Out>
  get $asCatalogAiUseEntry => $base.as(
    (v, t, t2) => _CatalogAiUseEntryCopyWithImpl<$R, $Out>(v, t, t2),
  );
}

abstract class CatalogAiUseEntryCopyWith<
  $R,
  $In extends CatalogAiUseEntry,
  $Out
>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({String? area, String? how, String? extent, bool? isOptional});
  CatalogAiUseEntryCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _CatalogAiUseEntryCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, CatalogAiUseEntry, $Out>
    implements CatalogAiUseEntryCopyWith<$R, CatalogAiUseEntry, $Out> {
  _CatalogAiUseEntryCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<CatalogAiUseEntry> $mapper =
      CatalogAiUseEntryMapper.ensureInitialized();
  @override
  $R call({
    String? area,
    Object? how = $none,
    Object? extent = $none,
    Object? isOptional = $none,
  }) => $apply(
    FieldCopyWithData({
      if (area != null) #area: area,
      if (how != $none) #how: how,
      if (extent != $none) #extent: extent,
      if (isOptional != $none) #isOptional: isOptional,
    }),
  );
  @override
  CatalogAiUseEntry $make(CopyWithData data) => CatalogAiUseEntry(
    area: data.get(#area, or: $value.area),
    how: data.get(#how, or: $value.how),
    extent: data.get(#extent, or: $value.extent),
    isOptional: data.get(#isOptional, or: $value.isOptional),
  );

  @override
  CatalogAiUseEntryCopyWith<$R2, CatalogAiUseEntry, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _CatalogAiUseEntryCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class CatalogSaveStatementMapper extends ClassMapperBase<CatalogSaveStatement> {
  CatalogSaveStatementMapper._();

  static CatalogSaveStatementMapper? _instance;
  static CatalogSaveStatementMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = CatalogSaveStatementMapper._());
      CatalogSaveAnswerMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'CatalogSaveStatement';

  static String? _$quote(CatalogSaveStatement v) => v.quote;
  static const Field<CatalogSaveStatement, String> _f$quote = Field(
    'quote',
    _$quote,
    opt: true,
  );
  static CatalogSaveAnswer? _$answer(CatalogSaveStatement v) => v.answer;
  static const Field<CatalogSaveStatement, CatalogSaveAnswer> _f$answer = Field(
    'answer',
    _$answer,
    opt: true,
  );

  @override
  final MappableFields<CatalogSaveStatement> fields = const {
    #quote: _f$quote,
    #answer: _f$answer,
  };

  static CatalogSaveStatement _instantiate(DecodingData data) {
    return CatalogSaveStatement(
      quote: data.dec(_f$quote),
      answer: data.dec(_f$answer),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static CatalogSaveStatement fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<CatalogSaveStatement>(map);
  }

  static CatalogSaveStatement fromJson(String json) {
    return ensureInitialized().decodeJson<CatalogSaveStatement>(json);
  }
}

mixin CatalogSaveStatementMappable {
  String toJson() {
    return CatalogSaveStatementMapper.ensureInitialized()
        .encodeJson<CatalogSaveStatement>(this as CatalogSaveStatement);
  }

  Map<String, dynamic> toMap() {
    return CatalogSaveStatementMapper.ensureInitialized()
        .encodeMap<CatalogSaveStatement>(this as CatalogSaveStatement);
  }

  CatalogSaveStatementCopyWith<
    CatalogSaveStatement,
    CatalogSaveStatement,
    CatalogSaveStatement
  >
  get copyWith =>
      _CatalogSaveStatementCopyWithImpl<
        CatalogSaveStatement,
        CatalogSaveStatement
      >(this as CatalogSaveStatement, $identity, $identity);
  @override
  String toString() {
    return CatalogSaveStatementMapper.ensureInitialized().stringifyValue(
      this as CatalogSaveStatement,
    );
  }

  @override
  bool operator ==(Object other) {
    return CatalogSaveStatementMapper.ensureInitialized().equalsValue(
      this as CatalogSaveStatement,
      other,
    );
  }

  @override
  int get hashCode {
    return CatalogSaveStatementMapper.ensureInitialized().hashValue(
      this as CatalogSaveStatement,
    );
  }
}

extension CatalogSaveStatementValueCopy<$R, $Out>
    on ObjectCopyWith<$R, CatalogSaveStatement, $Out> {
  CatalogSaveStatementCopyWith<$R, CatalogSaveStatement, $Out>
  get $asCatalogSaveStatement => $base.as(
    (v, t, t2) => _CatalogSaveStatementCopyWithImpl<$R, $Out>(v, t, t2),
  );
}

abstract class CatalogSaveStatementCopyWith<
  $R,
  $In extends CatalogSaveStatement,
  $Out
>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({String? quote, CatalogSaveAnswer? answer});
  CatalogSaveStatementCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _CatalogSaveStatementCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, CatalogSaveStatement, $Out>
    implements CatalogSaveStatementCopyWith<$R, CatalogSaveStatement, $Out> {
  _CatalogSaveStatementCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<CatalogSaveStatement> $mapper =
      CatalogSaveStatementMapper.ensureInitialized();
  @override
  $R call({Object? quote = $none, Object? answer = $none}) => $apply(
    FieldCopyWithData({
      if (quote != $none) #quote: quote,
      if (answer != $none) #answer: answer,
    }),
  );
  @override
  CatalogSaveStatement $make(CopyWithData data) => CatalogSaveStatement(
    quote: data.get(#quote, or: $value.quote),
    answer: data.get(#answer, or: $value.answer),
  );

  @override
  CatalogSaveStatementCopyWith<$R2, CatalogSaveStatement, $Out2>
  $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _CatalogSaveStatementCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class CatalogSaveCompatMapper extends ClassMapperBase<CatalogSaveCompat> {
  CatalogSaveCompatMapper._();

  static CatalogSaveCompatMapper? _instance;
  static CatalogSaveCompatMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = CatalogSaveCompatMapper._());
      CatalogSaveStatementMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'CatalogSaveCompat';

  static CatalogSaveStatement? _$adding(CatalogSaveCompat v) => v.adding;
  static const Field<CatalogSaveCompat, CatalogSaveStatement> _f$adding = Field(
    'adding',
    _$adding,
    opt: true,
  );
  static CatalogSaveStatement? _$removing(CatalogSaveCompat v) => v.removing;
  static const Field<CatalogSaveCompat, CatalogSaveStatement> _f$removing =
      Field('removing', _$removing, opt: true);
  static CatalogSaveStatement? _$latestUpdateNote(CatalogSaveCompat v) =>
      v.latestUpdateNote;
  static const Field<CatalogSaveCompat, CatalogSaveStatement>
  _f$latestUpdateNote = Field(
    'latestUpdateNote',
    _$latestUpdateNote,
    opt: true,
  );

  @override
  final MappableFields<CatalogSaveCompat> fields = const {
    #adding: _f$adding,
    #removing: _f$removing,
    #latestUpdateNote: _f$latestUpdateNote,
  };

  static CatalogSaveCompat _instantiate(DecodingData data) {
    return CatalogSaveCompat(
      adding: data.dec(_f$adding),
      removing: data.dec(_f$removing),
      latestUpdateNote: data.dec(_f$latestUpdateNote),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static CatalogSaveCompat fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<CatalogSaveCompat>(map);
  }

  static CatalogSaveCompat fromJson(String json) {
    return ensureInitialized().decodeJson<CatalogSaveCompat>(json);
  }
}

mixin CatalogSaveCompatMappable {
  String toJson() {
    return CatalogSaveCompatMapper.ensureInitialized()
        .encodeJson<CatalogSaveCompat>(this as CatalogSaveCompat);
  }

  Map<String, dynamic> toMap() {
    return CatalogSaveCompatMapper.ensureInitialized()
        .encodeMap<CatalogSaveCompat>(this as CatalogSaveCompat);
  }

  CatalogSaveCompatCopyWith<
    CatalogSaveCompat,
    CatalogSaveCompat,
    CatalogSaveCompat
  >
  get copyWith =>
      _CatalogSaveCompatCopyWithImpl<CatalogSaveCompat, CatalogSaveCompat>(
        this as CatalogSaveCompat,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return CatalogSaveCompatMapper.ensureInitialized().stringifyValue(
      this as CatalogSaveCompat,
    );
  }

  @override
  bool operator ==(Object other) {
    return CatalogSaveCompatMapper.ensureInitialized().equalsValue(
      this as CatalogSaveCompat,
      other,
    );
  }

  @override
  int get hashCode {
    return CatalogSaveCompatMapper.ensureInitialized().hashValue(
      this as CatalogSaveCompat,
    );
  }
}

extension CatalogSaveCompatValueCopy<$R, $Out>
    on ObjectCopyWith<$R, CatalogSaveCompat, $Out> {
  CatalogSaveCompatCopyWith<$R, CatalogSaveCompat, $Out>
  get $asCatalogSaveCompat => $base.as(
    (v, t, t2) => _CatalogSaveCompatCopyWithImpl<$R, $Out>(v, t, t2),
  );
}

abstract class CatalogSaveCompatCopyWith<
  $R,
  $In extends CatalogSaveCompat,
  $Out
>
    implements ClassCopyWith<$R, $In, $Out> {
  CatalogSaveStatementCopyWith<$R, CatalogSaveStatement, CatalogSaveStatement>?
  get adding;
  CatalogSaveStatementCopyWith<$R, CatalogSaveStatement, CatalogSaveStatement>?
  get removing;
  CatalogSaveStatementCopyWith<$R, CatalogSaveStatement, CatalogSaveStatement>?
  get latestUpdateNote;
  $R call({
    CatalogSaveStatement? adding,
    CatalogSaveStatement? removing,
    CatalogSaveStatement? latestUpdateNote,
  });
  CatalogSaveCompatCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _CatalogSaveCompatCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, CatalogSaveCompat, $Out>
    implements CatalogSaveCompatCopyWith<$R, CatalogSaveCompat, $Out> {
  _CatalogSaveCompatCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<CatalogSaveCompat> $mapper =
      CatalogSaveCompatMapper.ensureInitialized();
  @override
  CatalogSaveStatementCopyWith<$R, CatalogSaveStatement, CatalogSaveStatement>?
  get adding => $value.adding?.copyWith.$chain((v) => call(adding: v));
  @override
  CatalogSaveStatementCopyWith<$R, CatalogSaveStatement, CatalogSaveStatement>?
  get removing => $value.removing?.copyWith.$chain((v) => call(removing: v));
  @override
  CatalogSaveStatementCopyWith<$R, CatalogSaveStatement, CatalogSaveStatement>?
  get latestUpdateNote => $value.latestUpdateNote?.copyWith.$chain(
    (v) => call(latestUpdateNote: v),
  );
  @override
  $R call({
    Object? adding = $none,
    Object? removing = $none,
    Object? latestUpdateNote = $none,
  }) => $apply(
    FieldCopyWithData({
      if (adding != $none) #adding: adding,
      if (removing != $none) #removing: removing,
      if (latestUpdateNote != $none) #latestUpdateNote: latestUpdateNote,
    }),
  );
  @override
  CatalogSaveCompat $make(CopyWithData data) => CatalogSaveCompat(
    adding: data.get(#adding, or: $value.adding),
    removing: data.get(#removing, or: $value.removing),
    latestUpdateNote: data.get(#latestUpdateNote, or: $value.latestUpdateNote),
  );

  @override
  CatalogSaveCompatCopyWith<$R2, CatalogSaveCompat, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _CatalogSaveCompatCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class CatalogRequirementsMapper extends ClassMapperBase<CatalogRequirements> {
  CatalogRequirementsMapper._();

  static CatalogRequirementsMapper? _instance;
  static CatalogRequirementsMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = CatalogRequirementsMapper._());
      CatalogNeedMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'CatalogRequirements';

  static List<CatalogNeed> _$required(CatalogRequirements v) => v.required;
  static const Field<CatalogRequirements, List<CatalogNeed>> _f$required =
      Field('required', _$required, opt: true, def: const []);
  static List<CatalogNeed> _$optional(CatalogRequirements v) => v.optional;
  static const Field<CatalogRequirements, List<CatalogNeed>> _f$optional =
      Field('optional', _$optional, opt: true, def: const []);

  @override
  final MappableFields<CatalogRequirements> fields = const {
    #required: _f$required,
    #optional: _f$optional,
  };

  static CatalogRequirements _instantiate(DecodingData data) {
    return CatalogRequirements(
      required: data.dec(_f$required),
      optional: data.dec(_f$optional),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static CatalogRequirements fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<CatalogRequirements>(map);
  }

  static CatalogRequirements fromJson(String json) {
    return ensureInitialized().decodeJson<CatalogRequirements>(json);
  }
}

mixin CatalogRequirementsMappable {
  String toJson() {
    return CatalogRequirementsMapper.ensureInitialized()
        .encodeJson<CatalogRequirements>(this as CatalogRequirements);
  }

  Map<String, dynamic> toMap() {
    return CatalogRequirementsMapper.ensureInitialized()
        .encodeMap<CatalogRequirements>(this as CatalogRequirements);
  }

  CatalogRequirementsCopyWith<
    CatalogRequirements,
    CatalogRequirements,
    CatalogRequirements
  >
  get copyWith =>
      _CatalogRequirementsCopyWithImpl<
        CatalogRequirements,
        CatalogRequirements
      >(this as CatalogRequirements, $identity, $identity);
  @override
  String toString() {
    return CatalogRequirementsMapper.ensureInitialized().stringifyValue(
      this as CatalogRequirements,
    );
  }

  @override
  bool operator ==(Object other) {
    return CatalogRequirementsMapper.ensureInitialized().equalsValue(
      this as CatalogRequirements,
      other,
    );
  }

  @override
  int get hashCode {
    return CatalogRequirementsMapper.ensureInitialized().hashValue(
      this as CatalogRequirements,
    );
  }
}

extension CatalogRequirementsValueCopy<$R, $Out>
    on ObjectCopyWith<$R, CatalogRequirements, $Out> {
  CatalogRequirementsCopyWith<$R, CatalogRequirements, $Out>
  get $asCatalogRequirements => $base.as(
    (v, t, t2) => _CatalogRequirementsCopyWithImpl<$R, $Out>(v, t, t2),
  );
}

abstract class CatalogRequirementsCopyWith<
  $R,
  $In extends CatalogRequirements,
  $Out
>
    implements ClassCopyWith<$R, $In, $Out> {
  ListCopyWith<
    $R,
    CatalogNeed,
    CatalogNeedCopyWith<$R, CatalogNeed, CatalogNeed>
  >
  get required;
  ListCopyWith<
    $R,
    CatalogNeed,
    CatalogNeedCopyWith<$R, CatalogNeed, CatalogNeed>
  >
  get optional;
  $R call({List<CatalogNeed>? required, List<CatalogNeed>? optional});
  CatalogRequirementsCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _CatalogRequirementsCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, CatalogRequirements, $Out>
    implements CatalogRequirementsCopyWith<$R, CatalogRequirements, $Out> {
  _CatalogRequirementsCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<CatalogRequirements> $mapper =
      CatalogRequirementsMapper.ensureInitialized();
  @override
  ListCopyWith<
    $R,
    CatalogNeed,
    CatalogNeedCopyWith<$R, CatalogNeed, CatalogNeed>
  >
  get required => ListCopyWith(
    $value.required,
    (v, t) => v.copyWith.$chain(t),
    (v) => call(required: v),
  );
  @override
  ListCopyWith<
    $R,
    CatalogNeed,
    CatalogNeedCopyWith<$R, CatalogNeed, CatalogNeed>
  >
  get optional => ListCopyWith(
    $value.optional,
    (v, t) => v.copyWith.$chain(t),
    (v) => call(optional: v),
  );
  @override
  $R call({List<CatalogNeed>? required, List<CatalogNeed>? optional}) => $apply(
    FieldCopyWithData({
      if (required != null) #required: required,
      if (optional != null) #optional: optional,
    }),
  );
  @override
  CatalogRequirements $make(CopyWithData data) => CatalogRequirements(
    required: data.get(#required, or: $value.required),
    optional: data.get(#optional, or: $value.optional),
  );

  @override
  CatalogRequirementsCopyWith<$R2, CatalogRequirements, $Out2>
  $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _CatalogRequirementsCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class CatalogNeedMapper extends ClassMapperBase<CatalogNeed> {
  CatalogNeedMapper._();

  static CatalogNeedMapper? _instance;
  static CatalogNeedMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = CatalogNeedMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'CatalogNeed';

  static String _$name(CatalogNeed v) => v.name;
  static const Field<CatalogNeed, String> _f$name = Field('name', _$name);
  static String? _$id(CatalogNeed v) => v.id;
  static const Field<CatalogNeed, String> _f$id = Field('id', _$id, opt: true);
  static String? _$via(CatalogNeed v) => v.via;
  static const Field<CatalogNeed, String> _f$via = Field(
    'via',
    _$via,
    opt: true,
  );

  @override
  final MappableFields<CatalogNeed> fields = const {
    #name: _f$name,
    #id: _f$id,
    #via: _f$via,
  };

  static CatalogNeed _instantiate(DecodingData data) {
    return CatalogNeed(
      name: data.dec(_f$name),
      id: data.dec(_f$id),
      via: data.dec(_f$via),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static CatalogNeed fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<CatalogNeed>(map);
  }

  static CatalogNeed fromJson(String json) {
    return ensureInitialized().decodeJson<CatalogNeed>(json);
  }
}

mixin CatalogNeedMappable {
  String toJson() {
    return CatalogNeedMapper.ensureInitialized().encodeJson<CatalogNeed>(
      this as CatalogNeed,
    );
  }

  Map<String, dynamic> toMap() {
    return CatalogNeedMapper.ensureInitialized().encodeMap<CatalogNeed>(
      this as CatalogNeed,
    );
  }

  CatalogNeedCopyWith<CatalogNeed, CatalogNeed, CatalogNeed> get copyWith =>
      _CatalogNeedCopyWithImpl<CatalogNeed, CatalogNeed>(
        this as CatalogNeed,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return CatalogNeedMapper.ensureInitialized().stringifyValue(
      this as CatalogNeed,
    );
  }

  @override
  bool operator ==(Object other) {
    return CatalogNeedMapper.ensureInitialized().equalsValue(
      this as CatalogNeed,
      other,
    );
  }

  @override
  int get hashCode {
    return CatalogNeedMapper.ensureInitialized().hashValue(this as CatalogNeed);
  }
}

extension CatalogNeedValueCopy<$R, $Out>
    on ObjectCopyWith<$R, CatalogNeed, $Out> {
  CatalogNeedCopyWith<$R, CatalogNeed, $Out> get $asCatalogNeed =>
      $base.as((v, t, t2) => _CatalogNeedCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class CatalogNeedCopyWith<$R, $In extends CatalogNeed, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({String? name, String? id, String? via});
  CatalogNeedCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _CatalogNeedCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, CatalogNeed, $Out>
    implements CatalogNeedCopyWith<$R, CatalogNeed, $Out> {
  _CatalogNeedCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<CatalogNeed> $mapper =
      CatalogNeedMapper.ensureInitialized();
  @override
  $R call({String? name, Object? id = $none, Object? via = $none}) => $apply(
    FieldCopyWithData({
      if (name != null) #name: name,
      if (id != $none) #id: id,
      if (via != $none) #via: via,
    }),
  );
  @override
  CatalogNeed $make(CopyWithData data) => CatalogNeed(
    name: data.get(#name, or: $value.name),
    id: data.get(#id, or: $value.id),
    via: data.get(#via, or: $value.via),
  );

  @override
  CatalogNeedCopyWith<$R2, CatalogNeed, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _CatalogNeedCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class CatalogExtrasMapper extends ClassMapperBase<CatalogExtras> {
  CatalogExtrasMapper._();

  static CatalogExtrasMapper? _instance;
  static CatalogExtrasMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = CatalogExtrasMapper._());
      CatalogReleaseMapper.ensureInitialized();
      CatalogRequirementsMapper.ensureInitialized();
      CatalogConflictMapper.ensureInitialized();
      CatalogSaveCompatMapper.ensureInitialized();
      CatalogAiUseMapper.ensureInitialized();
      CatalogSameNameModMapper.ensureInitialized();
      CatalogGalleryPictureMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'CatalogExtras';

  static String? _$displayName(CatalogExtras v) => v.displayName;
  static const Field<CatalogExtras, String> _f$displayName = Field(
    'displayName',
    _$displayName,
    opt: true,
  );
  static String? _$summary(CatalogExtras v) => v.summary;
  static const Field<CatalogExtras, String> _f$summary = Field(
    'summary',
    _$summary,
    opt: true,
  );
  static List<String> _$categories(CatalogExtras v) => v.categories;
  static const Field<CatalogExtras, List<String>> _f$categories = Field(
    'categories',
    _$categories,
    opt: true,
    def: const [],
  );
  static List<String> _$rawCategories(CatalogExtras v) => v.rawCategories;
  static const Field<CatalogExtras, List<String>> _f$rawCategories = Field(
    'rawCategories',
    _$rawCategories,
    opt: true,
    def: const [],
  );
  static Map<String, List<String>> _$otherAuthorNames(CatalogExtras v) =>
      v.otherAuthorNames;
  static const Field<CatalogExtras, Map<String, List<String>>>
  _f$otherAuthorNames = Field(
    'otherAuthorNames',
    _$otherAuthorNames,
    opt: true,
    def: const {},
  );
  static DateTime? _$addedOn(CatalogExtras v) => v.addedOn;
  static const Field<CatalogExtras, DateTime> _f$addedOn = Field(
    'addedOn',
    _$addedOn,
    opt: true,
  );
  static DateTime? _$editedOn(CatalogExtras v) => v.editedOn;
  static const Field<CatalogExtras, DateTime> _f$editedOn = Field(
    'editedOn',
    _$editedOn,
    opt: true,
  );
  static DateTime? _$lastReleaseDate(CatalogExtras v) => v.lastReleaseDate;
  static const Field<CatalogExtras, DateTime> _f$lastReleaseDate = Field(
    'lastReleaseDate',
    _$lastReleaseDate,
    opt: true,
  );
  static List<CatalogRelease> _$releases(CatalogExtras v) => v.releases;
  static const Field<CatalogExtras, List<CatalogRelease>> _f$releases = Field(
    'releases',
    _$releases,
    opt: true,
    def: const [],
  );
  static CatalogRequirements? _$requirements(CatalogExtras v) => v.requirements;
  static const Field<CatalogExtras, CatalogRequirements> _f$requirements =
      Field('requirements', _$requirements, opt: true);
  static List<CatalogConflict> _$conflicts(CatalogExtras v) => v.conflicts;
  static const Field<CatalogExtras, List<CatalogConflict>> _f$conflicts = Field(
    'conflicts',
    _$conflicts,
    opt: true,
    def: const [],
  );
  static List<String>? _$types(CatalogExtras v) => v.types;
  static const Field<CatalogExtras, List<String>> _f$types = Field(
    'types',
    _$types,
    opt: true,
  );
  static CatalogSaveCompat? _$saveCompat(CatalogExtras v) => v.saveCompat;
  static const Field<CatalogExtras, CatalogSaveCompat> _f$saveCompat = Field(
    'saveCompat',
    _$saveCompat,
    opt: true,
  );
  static CatalogAiUse? _$aiUse(CatalogExtras v) => v.aiUse;
  static const Field<CatalogExtras, CatalogAiUse> _f$aiUse = Field(
    'aiUse',
    _$aiUse,
    opt: true,
  );
  static List<CatalogSameNameMod> _$sameNameMods(CatalogExtras v) =>
      v.sameNameMods;
  static const Field<CatalogExtras, List<CatalogSameNameMod>> _f$sameNameMods =
      Field('sameNameMods', _$sameNameMods, opt: true, def: const []);
  static List<CatalogGalleryPicture> _$gallery(CatalogExtras v) => v.gallery;
  static const Field<CatalogExtras, List<CatalogGalleryPicture>> _f$gallery =
      Field('gallery', _$gallery, opt: true, def: const []);
  static String? _$discordPostHtml(CatalogExtras v) => v.discordPostHtml;
  static const Field<CatalogExtras, String> _f$discordPostHtml = Field(
    'discordPostHtml',
    _$discordPostHtml,
    opt: true,
  );

  @override
  final MappableFields<CatalogExtras> fields = const {
    #displayName: _f$displayName,
    #summary: _f$summary,
    #categories: _f$categories,
    #rawCategories: _f$rawCategories,
    #otherAuthorNames: _f$otherAuthorNames,
    #addedOn: _f$addedOn,
    #editedOn: _f$editedOn,
    #lastReleaseDate: _f$lastReleaseDate,
    #releases: _f$releases,
    #requirements: _f$requirements,
    #conflicts: _f$conflicts,
    #types: _f$types,
    #saveCompat: _f$saveCompat,
    #aiUse: _f$aiUse,
    #sameNameMods: _f$sameNameMods,
    #gallery: _f$gallery,
    #discordPostHtml: _f$discordPostHtml,
  };

  static CatalogExtras _instantiate(DecodingData data) {
    return CatalogExtras(
      displayName: data.dec(_f$displayName),
      summary: data.dec(_f$summary),
      categories: data.dec(_f$categories),
      rawCategories: data.dec(_f$rawCategories),
      otherAuthorNames: data.dec(_f$otherAuthorNames),
      addedOn: data.dec(_f$addedOn),
      editedOn: data.dec(_f$editedOn),
      lastReleaseDate: data.dec(_f$lastReleaseDate),
      releases: data.dec(_f$releases),
      requirements: data.dec(_f$requirements),
      conflicts: data.dec(_f$conflicts),
      types: data.dec(_f$types),
      saveCompat: data.dec(_f$saveCompat),
      aiUse: data.dec(_f$aiUse),
      sameNameMods: data.dec(_f$sameNameMods),
      gallery: data.dec(_f$gallery),
      discordPostHtml: data.dec(_f$discordPostHtml),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static CatalogExtras fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<CatalogExtras>(map);
  }

  static CatalogExtras fromJson(String json) {
    return ensureInitialized().decodeJson<CatalogExtras>(json);
  }
}

mixin CatalogExtrasMappable {
  String toJson() {
    return CatalogExtrasMapper.ensureInitialized().encodeJson<CatalogExtras>(
      this as CatalogExtras,
    );
  }

  Map<String, dynamic> toMap() {
    return CatalogExtrasMapper.ensureInitialized().encodeMap<CatalogExtras>(
      this as CatalogExtras,
    );
  }

  CatalogExtrasCopyWith<CatalogExtras, CatalogExtras, CatalogExtras>
  get copyWith => _CatalogExtrasCopyWithImpl<CatalogExtras, CatalogExtras>(
    this as CatalogExtras,
    $identity,
    $identity,
  );
  @override
  String toString() {
    return CatalogExtrasMapper.ensureInitialized().stringifyValue(
      this as CatalogExtras,
    );
  }

  @override
  bool operator ==(Object other) {
    return CatalogExtrasMapper.ensureInitialized().equalsValue(
      this as CatalogExtras,
      other,
    );
  }

  @override
  int get hashCode {
    return CatalogExtrasMapper.ensureInitialized().hashValue(
      this as CatalogExtras,
    );
  }
}

extension CatalogExtrasValueCopy<$R, $Out>
    on ObjectCopyWith<$R, CatalogExtras, $Out> {
  CatalogExtrasCopyWith<$R, CatalogExtras, $Out> get $asCatalogExtras =>
      $base.as((v, t, t2) => _CatalogExtrasCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class CatalogExtrasCopyWith<$R, $In extends CatalogExtras, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>> get categories;
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>>
  get rawCategories;
  MapCopyWith<
    $R,
    String,
    List<String>,
    ObjectCopyWith<$R, List<String>, List<String>>
  >
  get otherAuthorNames;
  ListCopyWith<
    $R,
    CatalogRelease,
    CatalogReleaseCopyWith<$R, CatalogRelease, CatalogRelease>
  >
  get releases;
  CatalogRequirementsCopyWith<$R, CatalogRequirements, CatalogRequirements>?
  get requirements;
  ListCopyWith<
    $R,
    CatalogConflict,
    CatalogConflictCopyWith<$R, CatalogConflict, CatalogConflict>
  >
  get conflicts;
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>>? get types;
  CatalogSaveCompatCopyWith<$R, CatalogSaveCompat, CatalogSaveCompat>?
  get saveCompat;
  CatalogAiUseCopyWith<$R, CatalogAiUse, CatalogAiUse>? get aiUse;
  ListCopyWith<
    $R,
    CatalogSameNameMod,
    CatalogSameNameModCopyWith<$R, CatalogSameNameMod, CatalogSameNameMod>
  >
  get sameNameMods;
  ListCopyWith<
    $R,
    CatalogGalleryPicture,
    CatalogGalleryPictureCopyWith<
      $R,
      CatalogGalleryPicture,
      CatalogGalleryPicture
    >
  >
  get gallery;
  $R call({
    String? displayName,
    String? summary,
    List<String>? categories,
    List<String>? rawCategories,
    Map<String, List<String>>? otherAuthorNames,
    DateTime? addedOn,
    DateTime? editedOn,
    DateTime? lastReleaseDate,
    List<CatalogRelease>? releases,
    CatalogRequirements? requirements,
    List<CatalogConflict>? conflicts,
    List<String>? types,
    CatalogSaveCompat? saveCompat,
    CatalogAiUse? aiUse,
    List<CatalogSameNameMod>? sameNameMods,
    List<CatalogGalleryPicture>? gallery,
    String? discordPostHtml,
  });
  CatalogExtrasCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _CatalogExtrasCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, CatalogExtras, $Out>
    implements CatalogExtrasCopyWith<$R, CatalogExtras, $Out> {
  _CatalogExtrasCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<CatalogExtras> $mapper =
      CatalogExtrasMapper.ensureInitialized();
  @override
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>> get categories =>
      ListCopyWith(
        $value.categories,
        (v, t) => ObjectCopyWith(v, $identity, t),
        (v) => call(categories: v),
      );
  @override
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>>
  get rawCategories => ListCopyWith(
    $value.rawCategories,
    (v, t) => ObjectCopyWith(v, $identity, t),
    (v) => call(rawCategories: v),
  );
  @override
  MapCopyWith<
    $R,
    String,
    List<String>,
    ObjectCopyWith<$R, List<String>, List<String>>
  >
  get otherAuthorNames => MapCopyWith(
    $value.otherAuthorNames,
    (v, t) => ObjectCopyWith(v, $identity, t),
    (v) => call(otherAuthorNames: v),
  );
  @override
  ListCopyWith<
    $R,
    CatalogRelease,
    CatalogReleaseCopyWith<$R, CatalogRelease, CatalogRelease>
  >
  get releases => ListCopyWith(
    $value.releases,
    (v, t) => v.copyWith.$chain(t),
    (v) => call(releases: v),
  );
  @override
  CatalogRequirementsCopyWith<$R, CatalogRequirements, CatalogRequirements>?
  get requirements =>
      $value.requirements?.copyWith.$chain((v) => call(requirements: v));
  @override
  ListCopyWith<
    $R,
    CatalogConflict,
    CatalogConflictCopyWith<$R, CatalogConflict, CatalogConflict>
  >
  get conflicts => ListCopyWith(
    $value.conflicts,
    (v, t) => v.copyWith.$chain(t),
    (v) => call(conflicts: v),
  );
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
  CatalogSaveCompatCopyWith<$R, CatalogSaveCompat, CatalogSaveCompat>?
  get saveCompat =>
      $value.saveCompat?.copyWith.$chain((v) => call(saveCompat: v));
  @override
  CatalogAiUseCopyWith<$R, CatalogAiUse, CatalogAiUse>? get aiUse =>
      $value.aiUse?.copyWith.$chain((v) => call(aiUse: v));
  @override
  ListCopyWith<
    $R,
    CatalogSameNameMod,
    CatalogSameNameModCopyWith<$R, CatalogSameNameMod, CatalogSameNameMod>
  >
  get sameNameMods => ListCopyWith(
    $value.sameNameMods,
    (v, t) => v.copyWith.$chain(t),
    (v) => call(sameNameMods: v),
  );
  @override
  ListCopyWith<
    $R,
    CatalogGalleryPicture,
    CatalogGalleryPictureCopyWith<
      $R,
      CatalogGalleryPicture,
      CatalogGalleryPicture
    >
  >
  get gallery => ListCopyWith(
    $value.gallery,
    (v, t) => v.copyWith.$chain(t),
    (v) => call(gallery: v),
  );
  @override
  $R call({
    Object? displayName = $none,
    Object? summary = $none,
    List<String>? categories,
    List<String>? rawCategories,
    Map<String, List<String>>? otherAuthorNames,
    Object? addedOn = $none,
    Object? editedOn = $none,
    Object? lastReleaseDate = $none,
    List<CatalogRelease>? releases,
    Object? requirements = $none,
    List<CatalogConflict>? conflicts,
    Object? types = $none,
    Object? saveCompat = $none,
    Object? aiUse = $none,
    List<CatalogSameNameMod>? sameNameMods,
    List<CatalogGalleryPicture>? gallery,
    Object? discordPostHtml = $none,
  }) => $apply(
    FieldCopyWithData({
      if (displayName != $none) #displayName: displayName,
      if (summary != $none) #summary: summary,
      if (categories != null) #categories: categories,
      if (rawCategories != null) #rawCategories: rawCategories,
      if (otherAuthorNames != null) #otherAuthorNames: otherAuthorNames,
      if (addedOn != $none) #addedOn: addedOn,
      if (editedOn != $none) #editedOn: editedOn,
      if (lastReleaseDate != $none) #lastReleaseDate: lastReleaseDate,
      if (releases != null) #releases: releases,
      if (requirements != $none) #requirements: requirements,
      if (conflicts != null) #conflicts: conflicts,
      if (types != $none) #types: types,
      if (saveCompat != $none) #saveCompat: saveCompat,
      if (aiUse != $none) #aiUse: aiUse,
      if (sameNameMods != null) #sameNameMods: sameNameMods,
      if (gallery != null) #gallery: gallery,
      if (discordPostHtml != $none) #discordPostHtml: discordPostHtml,
    }),
  );
  @override
  CatalogExtras $make(CopyWithData data) => CatalogExtras(
    displayName: data.get(#displayName, or: $value.displayName),
    summary: data.get(#summary, or: $value.summary),
    categories: data.get(#categories, or: $value.categories),
    rawCategories: data.get(#rawCategories, or: $value.rawCategories),
    otherAuthorNames: data.get(#otherAuthorNames, or: $value.otherAuthorNames),
    addedOn: data.get(#addedOn, or: $value.addedOn),
    editedOn: data.get(#editedOn, or: $value.editedOn),
    lastReleaseDate: data.get(#lastReleaseDate, or: $value.lastReleaseDate),
    releases: data.get(#releases, or: $value.releases),
    requirements: data.get(#requirements, or: $value.requirements),
    conflicts: data.get(#conflicts, or: $value.conflicts),
    types: data.get(#types, or: $value.types),
    saveCompat: data.get(#saveCompat, or: $value.saveCompat),
    aiUse: data.get(#aiUse, or: $value.aiUse),
    sameNameMods: data.get(#sameNameMods, or: $value.sameNameMods),
    gallery: data.get(#gallery, or: $value.gallery),
    discordPostHtml: data.get(#discordPostHtml, or: $value.discordPostHtml),
  );

  @override
  CatalogExtrasCopyWith<$R2, CatalogExtras, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _CatalogExtrasCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class CatalogReleaseMapper extends ClassMapperBase<CatalogRelease> {
  CatalogReleaseMapper._();

  static CatalogReleaseMapper? _instance;
  static CatalogReleaseMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = CatalogReleaseMapper._());
      CatalogSaveStatementMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'CatalogRelease';

  static DateTime _$seenOn(CatalogRelease v) => v.seenOn;
  static const Field<CatalogRelease, DateTime> _f$seenOn = Field(
    'seenOn',
    _$seenOn,
  );
  static String? _$oldVersion(CatalogRelease v) => v.oldVersion;
  static const Field<CatalogRelease, String> _f$oldVersion = Field(
    'oldVersion',
    _$oldVersion,
    opt: true,
  );
  static String _$newVersion(CatalogRelease v) => v.newVersion;
  static const Field<CatalogRelease, String> _f$newVersion = Field(
    'newVersion',
    _$newVersion,
  );
  static String? _$gameVersion(CatalogRelease v) => v.gameVersion;
  static const Field<CatalogRelease, String> _f$gameVersion = Field(
    'gameVersion',
    _$gameVersion,
    opt: true,
  );
  static String? _$changelogNotes(CatalogRelease v) => v.changelogNotes;
  static const Field<CatalogRelease, String> _f$changelogNotes = Field(
    'changelogNotes',
    _$changelogNotes,
    opt: true,
  );
  static CatalogSaveStatement? _$updateNote(CatalogRelease v) => v.updateNote;
  static const Field<CatalogRelease, CatalogSaveStatement> _f$updateNote =
      Field('updateNote', _$updateNote, opt: true);

  @override
  final MappableFields<CatalogRelease> fields = const {
    #seenOn: _f$seenOn,
    #oldVersion: _f$oldVersion,
    #newVersion: _f$newVersion,
    #gameVersion: _f$gameVersion,
    #changelogNotes: _f$changelogNotes,
    #updateNote: _f$updateNote,
  };

  static CatalogRelease _instantiate(DecodingData data) {
    return CatalogRelease(
      seenOn: data.dec(_f$seenOn),
      oldVersion: data.dec(_f$oldVersion),
      newVersion: data.dec(_f$newVersion),
      gameVersion: data.dec(_f$gameVersion),
      changelogNotes: data.dec(_f$changelogNotes),
      updateNote: data.dec(_f$updateNote),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static CatalogRelease fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<CatalogRelease>(map);
  }

  static CatalogRelease fromJson(String json) {
    return ensureInitialized().decodeJson<CatalogRelease>(json);
  }
}

mixin CatalogReleaseMappable {
  String toJson() {
    return CatalogReleaseMapper.ensureInitialized().encodeJson<CatalogRelease>(
      this as CatalogRelease,
    );
  }

  Map<String, dynamic> toMap() {
    return CatalogReleaseMapper.ensureInitialized().encodeMap<CatalogRelease>(
      this as CatalogRelease,
    );
  }

  CatalogReleaseCopyWith<CatalogRelease, CatalogRelease, CatalogRelease>
  get copyWith => _CatalogReleaseCopyWithImpl<CatalogRelease, CatalogRelease>(
    this as CatalogRelease,
    $identity,
    $identity,
  );
  @override
  String toString() {
    return CatalogReleaseMapper.ensureInitialized().stringifyValue(
      this as CatalogRelease,
    );
  }

  @override
  bool operator ==(Object other) {
    return CatalogReleaseMapper.ensureInitialized().equalsValue(
      this as CatalogRelease,
      other,
    );
  }

  @override
  int get hashCode {
    return CatalogReleaseMapper.ensureInitialized().hashValue(
      this as CatalogRelease,
    );
  }
}

extension CatalogReleaseValueCopy<$R, $Out>
    on ObjectCopyWith<$R, CatalogRelease, $Out> {
  CatalogReleaseCopyWith<$R, CatalogRelease, $Out> get $asCatalogRelease =>
      $base.as((v, t, t2) => _CatalogReleaseCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class CatalogReleaseCopyWith<$R, $In extends CatalogRelease, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  CatalogSaveStatementCopyWith<$R, CatalogSaveStatement, CatalogSaveStatement>?
  get updateNote;
  $R call({
    DateTime? seenOn,
    String? oldVersion,
    String? newVersion,
    String? gameVersion,
    String? changelogNotes,
    CatalogSaveStatement? updateNote,
  });
  CatalogReleaseCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _CatalogReleaseCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, CatalogRelease, $Out>
    implements CatalogReleaseCopyWith<$R, CatalogRelease, $Out> {
  _CatalogReleaseCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<CatalogRelease> $mapper =
      CatalogReleaseMapper.ensureInitialized();
  @override
  CatalogSaveStatementCopyWith<$R, CatalogSaveStatement, CatalogSaveStatement>?
  get updateNote =>
      $value.updateNote?.copyWith.$chain((v) => call(updateNote: v));
  @override
  $R call({
    DateTime? seenOn,
    Object? oldVersion = $none,
    String? newVersion,
    Object? gameVersion = $none,
    Object? changelogNotes = $none,
    Object? updateNote = $none,
  }) => $apply(
    FieldCopyWithData({
      if (seenOn != null) #seenOn: seenOn,
      if (oldVersion != $none) #oldVersion: oldVersion,
      if (newVersion != null) #newVersion: newVersion,
      if (gameVersion != $none) #gameVersion: gameVersion,
      if (changelogNotes != $none) #changelogNotes: changelogNotes,
      if (updateNote != $none) #updateNote: updateNote,
    }),
  );
  @override
  CatalogRelease $make(CopyWithData data) => CatalogRelease(
    seenOn: data.get(#seenOn, or: $value.seenOn),
    oldVersion: data.get(#oldVersion, or: $value.oldVersion),
    newVersion: data.get(#newVersion, or: $value.newVersion),
    gameVersion: data.get(#gameVersion, or: $value.gameVersion),
    changelogNotes: data.get(#changelogNotes, or: $value.changelogNotes),
    updateNote: data.get(#updateNote, or: $value.updateNote),
  );

  @override
  CatalogReleaseCopyWith<$R2, CatalogRelease, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _CatalogReleaseCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class CatalogConflictMapper extends ClassMapperBase<CatalogConflict> {
  CatalogConflictMapper._();

  static CatalogConflictMapper? _instance;
  static CatalogConflictMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = CatalogConflictMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'CatalogConflict';

  static String _$name(CatalogConflict v) => v.name;
  static const Field<CatalogConflict, String> _f$name = Field('name', _$name);
  static String? _$id(CatalogConflict v) => v.id;
  static const Field<CatalogConflict, String> _f$id = Field(
    'id',
    _$id,
    opt: true,
  );
  static String _$quote(CatalogConflict v) => v.quote;
  static const Field<CatalogConflict, String> _f$quote = Field(
    'quote',
    _$quote,
  );

  @override
  final MappableFields<CatalogConflict> fields = const {
    #name: _f$name,
    #id: _f$id,
    #quote: _f$quote,
  };

  static CatalogConflict _instantiate(DecodingData data) {
    return CatalogConflict(
      name: data.dec(_f$name),
      id: data.dec(_f$id),
      quote: data.dec(_f$quote),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static CatalogConflict fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<CatalogConflict>(map);
  }

  static CatalogConflict fromJson(String json) {
    return ensureInitialized().decodeJson<CatalogConflict>(json);
  }
}

mixin CatalogConflictMappable {
  String toJson() {
    return CatalogConflictMapper.ensureInitialized()
        .encodeJson<CatalogConflict>(this as CatalogConflict);
  }

  Map<String, dynamic> toMap() {
    return CatalogConflictMapper.ensureInitialized().encodeMap<CatalogConflict>(
      this as CatalogConflict,
    );
  }

  CatalogConflictCopyWith<CatalogConflict, CatalogConflict, CatalogConflict>
  get copyWith =>
      _CatalogConflictCopyWithImpl<CatalogConflict, CatalogConflict>(
        this as CatalogConflict,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return CatalogConflictMapper.ensureInitialized().stringifyValue(
      this as CatalogConflict,
    );
  }

  @override
  bool operator ==(Object other) {
    return CatalogConflictMapper.ensureInitialized().equalsValue(
      this as CatalogConflict,
      other,
    );
  }

  @override
  int get hashCode {
    return CatalogConflictMapper.ensureInitialized().hashValue(
      this as CatalogConflict,
    );
  }
}

extension CatalogConflictValueCopy<$R, $Out>
    on ObjectCopyWith<$R, CatalogConflict, $Out> {
  CatalogConflictCopyWith<$R, CatalogConflict, $Out> get $asCatalogConflict =>
      $base.as((v, t, t2) => _CatalogConflictCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class CatalogConflictCopyWith<$R, $In extends CatalogConflict, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({String? name, String? id, String? quote});
  CatalogConflictCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _CatalogConflictCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, CatalogConflict, $Out>
    implements CatalogConflictCopyWith<$R, CatalogConflict, $Out> {
  _CatalogConflictCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<CatalogConflict> $mapper =
      CatalogConflictMapper.ensureInitialized();
  @override
  $R call({String? name, Object? id = $none, String? quote}) => $apply(
    FieldCopyWithData({
      if (name != null) #name: name,
      if (id != $none) #id: id,
      if (quote != null) #quote: quote,
    }),
  );
  @override
  CatalogConflict $make(CopyWithData data) => CatalogConflict(
    name: data.get(#name, or: $value.name),
    id: data.get(#id, or: $value.id),
    quote: data.get(#quote, or: $value.quote),
  );

  @override
  CatalogConflictCopyWith<$R2, CatalogConflict, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _CatalogConflictCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class CatalogSameNameModMapper extends ClassMapperBase<CatalogSameNameMod> {
  CatalogSameNameModMapper._();

  static CatalogSameNameModMapper? _instance;
  static CatalogSameNameModMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = CatalogSameNameModMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'CatalogSameNameMod';

  static String _$title(CatalogSameNameMod v) => v.title;
  static const Field<CatalogSameNameMod, String> _f$title = Field(
    'title',
    _$title,
  );
  static String? _$url(CatalogSameNameMod v) => v.url;
  static const Field<CatalogSameNameMod, String> _f$url = Field(
    'url',
    _$url,
    opt: true,
  );
  static String? _$id(CatalogSameNameMod v) => v.id;
  static const Field<CatalogSameNameMod, String> _f$id = Field(
    'id',
    _$id,
    opt: true,
  );
  static List<String> _$authors(CatalogSameNameMod v) => v.authors;
  static const Field<CatalogSameNameMod, List<String>> _f$authors = Field(
    'authors',
    _$authors,
    opt: true,
    def: const [],
  );
  static String? _$gameVersion(CatalogSameNameMod v) => v.gameVersion;
  static const Field<CatalogSameNameMod, String> _f$gameVersion = Field(
    'gameVersion',
    _$gameVersion,
    opt: true,
  );
  static String? _$modVersion(CatalogSameNameMod v) => v.modVersion;
  static const Field<CatalogSameNameMod, String> _f$modVersion = Field(
    'modVersion',
    _$modVersion,
    opt: true,
  );
  static DateTime? _$threadLastPostOn(CatalogSameNameMod v) =>
      v.threadLastPostOn;
  static const Field<CatalogSameNameMod, DateTime> _f$threadLastPostOn = Field(
    'threadLastPostOn',
    _$threadLastPostOn,
    opt: true,
  );

  @override
  final MappableFields<CatalogSameNameMod> fields = const {
    #title: _f$title,
    #url: _f$url,
    #id: _f$id,
    #authors: _f$authors,
    #gameVersion: _f$gameVersion,
    #modVersion: _f$modVersion,
    #threadLastPostOn: _f$threadLastPostOn,
  };

  static CatalogSameNameMod _instantiate(DecodingData data) {
    return CatalogSameNameMod(
      title: data.dec(_f$title),
      url: data.dec(_f$url),
      id: data.dec(_f$id),
      authors: data.dec(_f$authors),
      gameVersion: data.dec(_f$gameVersion),
      modVersion: data.dec(_f$modVersion),
      threadLastPostOn: data.dec(_f$threadLastPostOn),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static CatalogSameNameMod fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<CatalogSameNameMod>(map);
  }

  static CatalogSameNameMod fromJson(String json) {
    return ensureInitialized().decodeJson<CatalogSameNameMod>(json);
  }
}

mixin CatalogSameNameModMappable {
  String toJson() {
    return CatalogSameNameModMapper.ensureInitialized()
        .encodeJson<CatalogSameNameMod>(this as CatalogSameNameMod);
  }

  Map<String, dynamic> toMap() {
    return CatalogSameNameModMapper.ensureInitialized()
        .encodeMap<CatalogSameNameMod>(this as CatalogSameNameMod);
  }

  CatalogSameNameModCopyWith<
    CatalogSameNameMod,
    CatalogSameNameMod,
    CatalogSameNameMod
  >
  get copyWith =>
      _CatalogSameNameModCopyWithImpl<CatalogSameNameMod, CatalogSameNameMod>(
        this as CatalogSameNameMod,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return CatalogSameNameModMapper.ensureInitialized().stringifyValue(
      this as CatalogSameNameMod,
    );
  }

  @override
  bool operator ==(Object other) {
    return CatalogSameNameModMapper.ensureInitialized().equalsValue(
      this as CatalogSameNameMod,
      other,
    );
  }

  @override
  int get hashCode {
    return CatalogSameNameModMapper.ensureInitialized().hashValue(
      this as CatalogSameNameMod,
    );
  }
}

extension CatalogSameNameModValueCopy<$R, $Out>
    on ObjectCopyWith<$R, CatalogSameNameMod, $Out> {
  CatalogSameNameModCopyWith<$R, CatalogSameNameMod, $Out>
  get $asCatalogSameNameMod => $base.as(
    (v, t, t2) => _CatalogSameNameModCopyWithImpl<$R, $Out>(v, t, t2),
  );
}

abstract class CatalogSameNameModCopyWith<
  $R,
  $In extends CatalogSameNameMod,
  $Out
>
    implements ClassCopyWith<$R, $In, $Out> {
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>> get authors;
  $R call({
    String? title,
    String? url,
    String? id,
    List<String>? authors,
    String? gameVersion,
    String? modVersion,
    DateTime? threadLastPostOn,
  });
  CatalogSameNameModCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _CatalogSameNameModCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, CatalogSameNameMod, $Out>
    implements CatalogSameNameModCopyWith<$R, CatalogSameNameMod, $Out> {
  _CatalogSameNameModCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<CatalogSameNameMod> $mapper =
      CatalogSameNameModMapper.ensureInitialized();
  @override
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>> get authors =>
      ListCopyWith(
        $value.authors,
        (v, t) => ObjectCopyWith(v, $identity, t),
        (v) => call(authors: v),
      );
  @override
  $R call({
    String? title,
    Object? url = $none,
    Object? id = $none,
    List<String>? authors,
    Object? gameVersion = $none,
    Object? modVersion = $none,
    Object? threadLastPostOn = $none,
  }) => $apply(
    FieldCopyWithData({
      if (title != null) #title: title,
      if (url != $none) #url: url,
      if (id != $none) #id: id,
      if (authors != null) #authors: authors,
      if (gameVersion != $none) #gameVersion: gameVersion,
      if (modVersion != $none) #modVersion: modVersion,
      if (threadLastPostOn != $none) #threadLastPostOn: threadLastPostOn,
    }),
  );
  @override
  CatalogSameNameMod $make(CopyWithData data) => CatalogSameNameMod(
    title: data.get(#title, or: $value.title),
    url: data.get(#url, or: $value.url),
    id: data.get(#id, or: $value.id),
    authors: data.get(#authors, or: $value.authors),
    gameVersion: data.get(#gameVersion, or: $value.gameVersion),
    modVersion: data.get(#modVersion, or: $value.modVersion),
    threadLastPostOn: data.get(#threadLastPostOn, or: $value.threadLastPostOn),
  );

  @override
  CatalogSameNameModCopyWith<$R2, CatalogSameNameMod, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _CatalogSameNameModCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class CatalogGalleryPictureMapper
    extends ClassMapperBase<CatalogGalleryPicture> {
  CatalogGalleryPictureMapper._();

  static CatalogGalleryPictureMapper? _instance;
  static CatalogGalleryPictureMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = CatalogGalleryPictureMapper._());
      CatalogPictureKindMapper.ensureInitialized();
      CatalogPictureFitMapper.ensureInitialized();
      CatalogPictureSourceMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'CatalogGalleryPicture';

  static String _$url(CatalogGalleryPicture v) => v.url;
  static const Field<CatalogGalleryPicture, String> _f$url = Field(
    'url',
    _$url,
  );
  static String? _$caption(CatalogGalleryPicture v) => v.caption;
  static const Field<CatalogGalleryPicture, String> _f$caption = Field(
    'caption',
    _$caption,
    opt: true,
  );
  static String? _$aiCaption(CatalogGalleryPicture v) => v.aiCaption;
  static const Field<CatalogGalleryPicture, String> _f$aiCaption = Field(
    'aiCaption',
    _$aiCaption,
    opt: true,
  );
  static CatalogPictureKind? _$aiKind(CatalogGalleryPicture v) => v.aiKind;
  static const Field<CatalogGalleryPicture, CatalogPictureKind> _f$aiKind =
      Field('aiKind', _$aiKind, opt: true);
  static CatalogPictureFit? _$aiFit(CatalogGalleryPicture v) => v.aiFit;
  static const Field<CatalogGalleryPicture, CatalogPictureFit> _f$aiFit = Field(
    'aiFit',
    _$aiFit,
    opt: true,
  );
  static bool _$aiUnreadable(CatalogGalleryPicture v) => v.aiUnreadable;
  static const Field<CatalogGalleryPicture, bool> _f$aiUnreadable = Field(
    'aiUnreadable',
    _$aiUnreadable,
    opt: true,
    def: false,
  );
  static bool _$small(CatalogGalleryPicture v) => v.small;
  static const Field<CatalogGalleryPicture, bool> _f$small = Field(
    'small',
    _$small,
    opt: true,
    def: false,
  );
  static CatalogPictureSource? _$source(CatalogGalleryPicture v) => v.source;
  static const Field<CatalogGalleryPicture, CatalogPictureSource> _f$source =
      Field('source', _$source, opt: true);

  @override
  final MappableFields<CatalogGalleryPicture> fields = const {
    #url: _f$url,
    #caption: _f$caption,
    #aiCaption: _f$aiCaption,
    #aiKind: _f$aiKind,
    #aiFit: _f$aiFit,
    #aiUnreadable: _f$aiUnreadable,
    #small: _f$small,
    #source: _f$source,
  };

  static CatalogGalleryPicture _instantiate(DecodingData data) {
    return CatalogGalleryPicture(
      url: data.dec(_f$url),
      caption: data.dec(_f$caption),
      aiCaption: data.dec(_f$aiCaption),
      aiKind: data.dec(_f$aiKind),
      aiFit: data.dec(_f$aiFit),
      aiUnreadable: data.dec(_f$aiUnreadable),
      small: data.dec(_f$small),
      source: data.dec(_f$source),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static CatalogGalleryPicture fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<CatalogGalleryPicture>(map);
  }

  static CatalogGalleryPicture fromJson(String json) {
    return ensureInitialized().decodeJson<CatalogGalleryPicture>(json);
  }
}

mixin CatalogGalleryPictureMappable {
  String toJson() {
    return CatalogGalleryPictureMapper.ensureInitialized()
        .encodeJson<CatalogGalleryPicture>(this as CatalogGalleryPicture);
  }

  Map<String, dynamic> toMap() {
    return CatalogGalleryPictureMapper.ensureInitialized()
        .encodeMap<CatalogGalleryPicture>(this as CatalogGalleryPicture);
  }

  CatalogGalleryPictureCopyWith<
    CatalogGalleryPicture,
    CatalogGalleryPicture,
    CatalogGalleryPicture
  >
  get copyWith =>
      _CatalogGalleryPictureCopyWithImpl<
        CatalogGalleryPicture,
        CatalogGalleryPicture
      >(this as CatalogGalleryPicture, $identity, $identity);
  @override
  String toString() {
    return CatalogGalleryPictureMapper.ensureInitialized().stringifyValue(
      this as CatalogGalleryPicture,
    );
  }

  @override
  bool operator ==(Object other) {
    return CatalogGalleryPictureMapper.ensureInitialized().equalsValue(
      this as CatalogGalleryPicture,
      other,
    );
  }

  @override
  int get hashCode {
    return CatalogGalleryPictureMapper.ensureInitialized().hashValue(
      this as CatalogGalleryPicture,
    );
  }
}

extension CatalogGalleryPictureValueCopy<$R, $Out>
    on ObjectCopyWith<$R, CatalogGalleryPicture, $Out> {
  CatalogGalleryPictureCopyWith<$R, CatalogGalleryPicture, $Out>
  get $asCatalogGalleryPicture => $base.as(
    (v, t, t2) => _CatalogGalleryPictureCopyWithImpl<$R, $Out>(v, t, t2),
  );
}

abstract class CatalogGalleryPictureCopyWith<
  $R,
  $In extends CatalogGalleryPicture,
  $Out
>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({
    String? url,
    String? caption,
    String? aiCaption,
    CatalogPictureKind? aiKind,
    CatalogPictureFit? aiFit,
    bool? aiUnreadable,
    bool? small,
    CatalogPictureSource? source,
  });
  CatalogGalleryPictureCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _CatalogGalleryPictureCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, CatalogGalleryPicture, $Out>
    implements CatalogGalleryPictureCopyWith<$R, CatalogGalleryPicture, $Out> {
  _CatalogGalleryPictureCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<CatalogGalleryPicture> $mapper =
      CatalogGalleryPictureMapper.ensureInitialized();
  @override
  $R call({
    String? url,
    Object? caption = $none,
    Object? aiCaption = $none,
    Object? aiKind = $none,
    Object? aiFit = $none,
    bool? aiUnreadable,
    bool? small,
    Object? source = $none,
  }) => $apply(
    FieldCopyWithData({
      if (url != null) #url: url,
      if (caption != $none) #caption: caption,
      if (aiCaption != $none) #aiCaption: aiCaption,
      if (aiKind != $none) #aiKind: aiKind,
      if (aiFit != $none) #aiFit: aiFit,
      if (aiUnreadable != null) #aiUnreadable: aiUnreadable,
      if (small != null) #small: small,
      if (source != $none) #source: source,
    }),
  );
  @override
  CatalogGalleryPicture $make(CopyWithData data) => CatalogGalleryPicture(
    url: data.get(#url, or: $value.url),
    caption: data.get(#caption, or: $value.caption),
    aiCaption: data.get(#aiCaption, or: $value.aiCaption),
    aiKind: data.get(#aiKind, or: $value.aiKind),
    aiFit: data.get(#aiFit, or: $value.aiFit),
    aiUnreadable: data.get(#aiUnreadable, or: $value.aiUnreadable),
    small: data.get(#small, or: $value.small),
    source: data.get(#source, or: $value.source),
  );

  @override
  CatalogGalleryPictureCopyWith<$R2, CatalogGalleryPicture, $Out2>
  $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _CatalogGalleryPictureCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

