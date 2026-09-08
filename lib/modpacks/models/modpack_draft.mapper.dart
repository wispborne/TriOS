// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'modpack_draft.dart';

class ModpackDraftProblemMapper extends EnumMapper<ModpackDraftProblem> {
  ModpackDraftProblemMapper._();

  static ModpackDraftProblemMapper? _instance;
  static ModpackDraftProblemMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ModpackDraftProblemMapper._());
    }
    return _instance!;
  }

  static ModpackDraftProblem fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  ModpackDraftProblem decode(dynamic value) {
    switch (value) {
      case r'packNameMissing':
        return ModpackDraftProblem.packNameMissing;
      case r'packNameTooLong':
        return ModpackDraftProblem.packNameTooLong;
      case r'homepageUrlInvalid':
        return ModpackDraftProblem.homepageUrlInvalid;
      case r'updateUrlInvalid':
        return ModpackDraftProblem.updateUrlInvalid;
      case r'noItems':
        return ModpackDraftProblem.noItems;
      case r'tooManyItems':
        return ModpackDraftProblem.tooManyItems;
      case r'itemModIdMissing':
        return ModpackDraftProblem.itemModIdMissing;
      case r'itemUrlMissing':
        return ModpackDraftProblem.itemUrlMissing;
      case r'itemUrlInvalid':
        return ModpackDraftProblem.itemUrlInvalid;
      case r'itemSourceTypeMissing':
        return ModpackDraftProblem.itemSourceTypeMissing;
      case r'itemLabelInvalid':
        return ModpackDraftProblem.itemLabelInvalid;
      case r'itemNoteTooLong':
        return ModpackDraftProblem.itemNoteTooLong;
      case r'duplicateModId':
        return ModpackDraftProblem.duplicateModId;
      default:
        throw MapperException.unknownEnumValue(value);
    }
  }

  @override
  dynamic encode(ModpackDraftProblem self) {
    switch (self) {
      case ModpackDraftProblem.packNameMissing:
        return r'packNameMissing';
      case ModpackDraftProblem.packNameTooLong:
        return r'packNameTooLong';
      case ModpackDraftProblem.homepageUrlInvalid:
        return r'homepageUrlInvalid';
      case ModpackDraftProblem.updateUrlInvalid:
        return r'updateUrlInvalid';
      case ModpackDraftProblem.noItems:
        return r'noItems';
      case ModpackDraftProblem.tooManyItems:
        return r'tooManyItems';
      case ModpackDraftProblem.itemModIdMissing:
        return r'itemModIdMissing';
      case ModpackDraftProblem.itemUrlMissing:
        return r'itemUrlMissing';
      case ModpackDraftProblem.itemUrlInvalid:
        return r'itemUrlInvalid';
      case ModpackDraftProblem.itemSourceTypeMissing:
        return r'itemSourceTypeMissing';
      case ModpackDraftProblem.itemLabelInvalid:
        return r'itemLabelInvalid';
      case ModpackDraftProblem.itemNoteTooLong:
        return r'itemNoteTooLong';
      case ModpackDraftProblem.duplicateModId:
        return r'duplicateModId';
    }
  }
}

extension ModpackDraftProblemMapperExtension on ModpackDraftProblem {
  String toValue() {
    ModpackDraftProblemMapper.ensureInitialized();
    return MapperContainer.globals.toValue<ModpackDraftProblem>(this) as String;
  }
}

class ModpackDraftIssueMapper extends ClassMapperBase<ModpackDraftIssue> {
  ModpackDraftIssueMapper._();

  static ModpackDraftIssueMapper? _instance;
  static ModpackDraftIssueMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ModpackDraftIssueMapper._());
      ModpackDraftProblemMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'ModpackDraftIssue';

  static ModpackDraftProblem _$problem(ModpackDraftIssue v) => v.problem;
  static const Field<ModpackDraftIssue, ModpackDraftProblem> _f$problem = Field(
    'problem',
    _$problem,
  );
  static int? _$itemIndex(ModpackDraftIssue v) => v.itemIndex;
  static const Field<ModpackDraftIssue, int> _f$itemIndex = Field(
    'itemIndex',
    _$itemIndex,
    opt: true,
  );

  @override
  final MappableFields<ModpackDraftIssue> fields = const {
    #problem: _f$problem,
    #itemIndex: _f$itemIndex,
  };

  static ModpackDraftIssue _instantiate(DecodingData data) {
    return ModpackDraftIssue(
      data.dec(_f$problem),
      itemIndex: data.dec(_f$itemIndex),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static ModpackDraftIssue fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<ModpackDraftIssue>(map);
  }

  static ModpackDraftIssue fromJson(String json) {
    return ensureInitialized().decodeJson<ModpackDraftIssue>(json);
  }
}

mixin ModpackDraftIssueMappable {
  String toJson() {
    return ModpackDraftIssueMapper.ensureInitialized()
        .encodeJson<ModpackDraftIssue>(this as ModpackDraftIssue);
  }

  Map<String, dynamic> toMap() {
    return ModpackDraftIssueMapper.ensureInitialized()
        .encodeMap<ModpackDraftIssue>(this as ModpackDraftIssue);
  }

  ModpackDraftIssueCopyWith<
    ModpackDraftIssue,
    ModpackDraftIssue,
    ModpackDraftIssue
  >
  get copyWith =>
      _ModpackDraftIssueCopyWithImpl<ModpackDraftIssue, ModpackDraftIssue>(
        this as ModpackDraftIssue,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return ModpackDraftIssueMapper.ensureInitialized().stringifyValue(
      this as ModpackDraftIssue,
    );
  }

  @override
  bool operator ==(Object other) {
    return ModpackDraftIssueMapper.ensureInitialized().equalsValue(
      this as ModpackDraftIssue,
      other,
    );
  }

  @override
  int get hashCode {
    return ModpackDraftIssueMapper.ensureInitialized().hashValue(
      this as ModpackDraftIssue,
    );
  }
}

extension ModpackDraftIssueValueCopy<$R, $Out>
    on ObjectCopyWith<$R, ModpackDraftIssue, $Out> {
  ModpackDraftIssueCopyWith<$R, ModpackDraftIssue, $Out>
  get $asModpackDraftIssue => $base.as(
    (v, t, t2) => _ModpackDraftIssueCopyWithImpl<$R, $Out>(v, t, t2),
  );
}

abstract class ModpackDraftIssueCopyWith<
  $R,
  $In extends ModpackDraftIssue,
  $Out
>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({ModpackDraftProblem? problem, int? itemIndex});
  ModpackDraftIssueCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _ModpackDraftIssueCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, ModpackDraftIssue, $Out>
    implements ModpackDraftIssueCopyWith<$R, ModpackDraftIssue, $Out> {
  _ModpackDraftIssueCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<ModpackDraftIssue> $mapper =
      ModpackDraftIssueMapper.ensureInitialized();
  @override
  $R call({ModpackDraftProblem? problem, Object? itemIndex = $none}) => $apply(
    FieldCopyWithData({
      if (problem != null) #problem: problem,
      if (itemIndex != $none) #itemIndex: itemIndex,
    }),
  );
  @override
  ModpackDraftIssue $make(CopyWithData data) => ModpackDraftIssue(
    data.get(#problem, or: $value.problem),
    itemIndex: data.get(#itemIndex, or: $value.itemIndex),
  );

  @override
  ModpackDraftIssueCopyWith<$R2, ModpackDraftIssue, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _ModpackDraftIssueCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class ModpackDraftItemMapper extends ClassMapperBase<ModpackDraftItem> {
  ModpackDraftItemMapper._();

  static ModpackDraftItemMapper? _instance;
  static ModpackDraftItemMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ModpackDraftItemMapper._());
      ModpackItemSourceTypeMapper.ensureInitialized();
      ModpackCatalogCluesMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'ModpackDraftItem';

  static String? _$modId(ModpackDraftItem v) => v.modId;
  static const Field<ModpackDraftItem, String> _f$modId = Field(
    'modId',
    _$modId,
    opt: true,
  );
  static String? _$url(ModpackDraftItem v) => v.url;
  static const Field<ModpackDraftItem, String> _f$url = Field(
    'url',
    _$url,
    opt: true,
  );
  static ModpackItemSourceType? _$sourceType(ModpackDraftItem v) =>
      v.sourceType;
  static const Field<ModpackDraftItem, ModpackItemSourceType> _f$sourceType =
      Field('sourceType', _$sourceType, opt: true);
  static String? _$name(ModpackDraftItem v) => v.name;
  static const Field<ModpackDraftItem, String> _f$name = Field(
    'name',
    _$name,
    opt: true,
  );
  static String? _$version(ModpackDraftItem v) => v.version;
  static const Field<ModpackDraftItem, String> _f$version = Field(
    'version',
    _$version,
    opt: true,
  );
  static String? _$label(ModpackDraftItem v) => v.label;
  static const Field<ModpackDraftItem, String> _f$label = Field(
    'label',
    _$label,
    opt: true,
  );
  static String? _$note(ModpackDraftItem v) => v.note;
  static const Field<ModpackDraftItem, String> _f$note = Field(
    'note',
    _$note,
    opt: true,
  );
  static ModpackCatalogClues? _$catalog(ModpackDraftItem v) => v.catalog;
  static const Field<ModpackDraftItem, ModpackCatalogClues> _f$catalog = Field(
    'catalog',
    _$catalog,
    opt: true,
  );
  static Map<String, dynamic> _$unknownFields(ModpackDraftItem v) =>
      v.unknownFields;
  static const Field<ModpackDraftItem, Map<String, dynamic>> _f$unknownFields =
      Field('unknownFields', _$unknownFields, opt: true, def: const {});

  @override
  final MappableFields<ModpackDraftItem> fields = const {
    #modId: _f$modId,
    #url: _f$url,
    #sourceType: _f$sourceType,
    #name: _f$name,
    #version: _f$version,
    #label: _f$label,
    #note: _f$note,
    #catalog: _f$catalog,
    #unknownFields: _f$unknownFields,
  };

  static ModpackDraftItem _instantiate(DecodingData data) {
    return ModpackDraftItem(
      modId: data.dec(_f$modId),
      url: data.dec(_f$url),
      sourceType: data.dec(_f$sourceType),
      name: data.dec(_f$name),
      version: data.dec(_f$version),
      label: data.dec(_f$label),
      note: data.dec(_f$note),
      catalog: data.dec(_f$catalog),
      unknownFields: data.dec(_f$unknownFields),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static ModpackDraftItem fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<ModpackDraftItem>(map);
  }

  static ModpackDraftItem fromJson(String json) {
    return ensureInitialized().decodeJson<ModpackDraftItem>(json);
  }
}

mixin ModpackDraftItemMappable {
  String toJson() {
    return ModpackDraftItemMapper.ensureInitialized()
        .encodeJson<ModpackDraftItem>(this as ModpackDraftItem);
  }

  Map<String, dynamic> toMap() {
    return ModpackDraftItemMapper.ensureInitialized()
        .encodeMap<ModpackDraftItem>(this as ModpackDraftItem);
  }

  ModpackDraftItemCopyWith<ModpackDraftItem, ModpackDraftItem, ModpackDraftItem>
  get copyWith =>
      _ModpackDraftItemCopyWithImpl<ModpackDraftItem, ModpackDraftItem>(
        this as ModpackDraftItem,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return ModpackDraftItemMapper.ensureInitialized().stringifyValue(
      this as ModpackDraftItem,
    );
  }

  @override
  bool operator ==(Object other) {
    return ModpackDraftItemMapper.ensureInitialized().equalsValue(
      this as ModpackDraftItem,
      other,
    );
  }

  @override
  int get hashCode {
    return ModpackDraftItemMapper.ensureInitialized().hashValue(
      this as ModpackDraftItem,
    );
  }
}

extension ModpackDraftItemValueCopy<$R, $Out>
    on ObjectCopyWith<$R, ModpackDraftItem, $Out> {
  ModpackDraftItemCopyWith<$R, ModpackDraftItem, $Out>
  get $asModpackDraftItem =>
      $base.as((v, t, t2) => _ModpackDraftItemCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class ModpackDraftItemCopyWith<$R, $In extends ModpackDraftItem, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  ModpackCatalogCluesCopyWith<$R, ModpackCatalogClues, ModpackCatalogClues>?
  get catalog;
  MapCopyWith<$R, String, dynamic, ObjectCopyWith<$R, dynamic, dynamic>?>
  get unknownFields;
  $R call({
    String? modId,
    String? url,
    ModpackItemSourceType? sourceType,
    String? name,
    String? version,
    String? label,
    String? note,
    ModpackCatalogClues? catalog,
    Map<String, dynamic>? unknownFields,
  });
  ModpackDraftItemCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _ModpackDraftItemCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, ModpackDraftItem, $Out>
    implements ModpackDraftItemCopyWith<$R, ModpackDraftItem, $Out> {
  _ModpackDraftItemCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<ModpackDraftItem> $mapper =
      ModpackDraftItemMapper.ensureInitialized();
  @override
  ModpackCatalogCluesCopyWith<$R, ModpackCatalogClues, ModpackCatalogClues>?
  get catalog => $value.catalog?.copyWith.$chain((v) => call(catalog: v));
  @override
  MapCopyWith<$R, String, dynamic, ObjectCopyWith<$R, dynamic, dynamic>?>
  get unknownFields => MapCopyWith(
    $value.unknownFields,
    (v, t) => ObjectCopyWith(v, $identity, t),
    (v) => call(unknownFields: v),
  );
  @override
  $R call({
    Object? modId = $none,
    Object? url = $none,
    Object? sourceType = $none,
    Object? name = $none,
    Object? version = $none,
    Object? label = $none,
    Object? note = $none,
    Object? catalog = $none,
    Map<String, dynamic>? unknownFields,
  }) => $apply(
    FieldCopyWithData({
      if (modId != $none) #modId: modId,
      if (url != $none) #url: url,
      if (sourceType != $none) #sourceType: sourceType,
      if (name != $none) #name: name,
      if (version != $none) #version: version,
      if (label != $none) #label: label,
      if (note != $none) #note: note,
      if (catalog != $none) #catalog: catalog,
      if (unknownFields != null) #unknownFields: unknownFields,
    }),
  );
  @override
  ModpackDraftItem $make(CopyWithData data) => ModpackDraftItem(
    modId: data.get(#modId, or: $value.modId),
    url: data.get(#url, or: $value.url),
    sourceType: data.get(#sourceType, or: $value.sourceType),
    name: data.get(#name, or: $value.name),
    version: data.get(#version, or: $value.version),
    label: data.get(#label, or: $value.label),
    note: data.get(#note, or: $value.note),
    catalog: data.get(#catalog, or: $value.catalog),
    unknownFields: data.get(#unknownFields, or: $value.unknownFields),
  );

  @override
  ModpackDraftItemCopyWith<$R2, ModpackDraftItem, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _ModpackDraftItemCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class ModpackDraftMapper extends ClassMapperBase<ModpackDraft> {
  ModpackDraftMapper._();

  static ModpackDraftMapper? _instance;
  static ModpackDraftMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ModpackDraftMapper._());
      ModpackDraftItemMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'ModpackDraft';

  static String _$id(ModpackDraft v) => v.id;
  static const Field<ModpackDraft, String> _f$id = Field('id', _$id);
  static String _$name(ModpackDraft v) => v.name;
  static const Field<ModpackDraft, String> _f$name = Field(
    'name',
    _$name,
    opt: true,
    def: '',
  );
  static String? _$author(ModpackDraft v) => v.author;
  static const Field<ModpackDraft, String> _f$author = Field(
    'author',
    _$author,
    opt: true,
  );
  static String? _$description(ModpackDraft v) => v.description;
  static const Field<ModpackDraft, String> _f$description = Field(
    'description',
    _$description,
    opt: true,
  );
  static String? _$gameVersion(ModpackDraft v) => v.gameVersion;
  static const Field<ModpackDraft, String> _f$gameVersion = Field(
    'gameVersion',
    _$gameVersion,
    opt: true,
  );
  static String? _$homepageUrl(ModpackDraft v) => v.homepageUrl;
  static const Field<ModpackDraft, String> _f$homepageUrl = Field(
    'homepageUrl',
    _$homepageUrl,
    opt: true,
  );
  static String? _$updateUrl(ModpackDraft v) => v.updateUrl;
  static const Field<ModpackDraft, String> _f$updateUrl = Field(
    'updateUrl',
    _$updateUrl,
    opt: true,
  );
  static List<ModpackDraftItem> _$items(ModpackDraft v) => v.items;
  static const Field<ModpackDraft, List<ModpackDraftItem>> _f$items = Field(
    'items',
    _$items,
    opt: true,
    def: const [],
  );
  static Map<String, dynamic> _$unknownFields(ModpackDraft v) =>
      v.unknownFields;
  static const Field<ModpackDraft, Map<String, dynamic>> _f$unknownFields =
      Field('unknownFields', _$unknownFields, opt: true, def: const {});
  static DateTime? _$updatedAt(ModpackDraft v) => v.updatedAt;
  static const Field<ModpackDraft, DateTime> _f$updatedAt = Field(
    'updatedAt',
    _$updatedAt,
    opt: true,
  );

  @override
  final MappableFields<ModpackDraft> fields = const {
    #id: _f$id,
    #name: _f$name,
    #author: _f$author,
    #description: _f$description,
    #gameVersion: _f$gameVersion,
    #homepageUrl: _f$homepageUrl,
    #updateUrl: _f$updateUrl,
    #items: _f$items,
    #unknownFields: _f$unknownFields,
    #updatedAt: _f$updatedAt,
  };

  static ModpackDraft _instantiate(DecodingData data) {
    return ModpackDraft(
      id: data.dec(_f$id),
      name: data.dec(_f$name),
      author: data.dec(_f$author),
      description: data.dec(_f$description),
      gameVersion: data.dec(_f$gameVersion),
      homepageUrl: data.dec(_f$homepageUrl),
      updateUrl: data.dec(_f$updateUrl),
      items: data.dec(_f$items),
      unknownFields: data.dec(_f$unknownFields),
      updatedAt: data.dec(_f$updatedAt),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static ModpackDraft fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<ModpackDraft>(map);
  }

  static ModpackDraft fromJson(String json) {
    return ensureInitialized().decodeJson<ModpackDraft>(json);
  }
}

mixin ModpackDraftMappable {
  String toJson() {
    return ModpackDraftMapper.ensureInitialized().encodeJson<ModpackDraft>(
      this as ModpackDraft,
    );
  }

  Map<String, dynamic> toMap() {
    return ModpackDraftMapper.ensureInitialized().encodeMap<ModpackDraft>(
      this as ModpackDraft,
    );
  }

  ModpackDraftCopyWith<ModpackDraft, ModpackDraft, ModpackDraft> get copyWith =>
      _ModpackDraftCopyWithImpl<ModpackDraft, ModpackDraft>(
        this as ModpackDraft,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return ModpackDraftMapper.ensureInitialized().stringifyValue(
      this as ModpackDraft,
    );
  }

  @override
  bool operator ==(Object other) {
    return ModpackDraftMapper.ensureInitialized().equalsValue(
      this as ModpackDraft,
      other,
    );
  }

  @override
  int get hashCode {
    return ModpackDraftMapper.ensureInitialized().hashValue(
      this as ModpackDraft,
    );
  }
}

extension ModpackDraftValueCopy<$R, $Out>
    on ObjectCopyWith<$R, ModpackDraft, $Out> {
  ModpackDraftCopyWith<$R, ModpackDraft, $Out> get $asModpackDraft =>
      $base.as((v, t, t2) => _ModpackDraftCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class ModpackDraftCopyWith<$R, $In extends ModpackDraft, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  ListCopyWith<
    $R,
    ModpackDraftItem,
    ModpackDraftItemCopyWith<$R, ModpackDraftItem, ModpackDraftItem>
  >
  get items;
  MapCopyWith<$R, String, dynamic, ObjectCopyWith<$R, dynamic, dynamic>?>
  get unknownFields;
  $R call({
    String? id,
    String? name,
    String? author,
    String? description,
    String? gameVersion,
    String? homepageUrl,
    String? updateUrl,
    List<ModpackDraftItem>? items,
    Map<String, dynamic>? unknownFields,
    DateTime? updatedAt,
  });
  ModpackDraftCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _ModpackDraftCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, ModpackDraft, $Out>
    implements ModpackDraftCopyWith<$R, ModpackDraft, $Out> {
  _ModpackDraftCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<ModpackDraft> $mapper =
      ModpackDraftMapper.ensureInitialized();
  @override
  ListCopyWith<
    $R,
    ModpackDraftItem,
    ModpackDraftItemCopyWith<$R, ModpackDraftItem, ModpackDraftItem>
  >
  get items => ListCopyWith(
    $value.items,
    (v, t) => v.copyWith.$chain(t),
    (v) => call(items: v),
  );
  @override
  MapCopyWith<$R, String, dynamic, ObjectCopyWith<$R, dynamic, dynamic>?>
  get unknownFields => MapCopyWith(
    $value.unknownFields,
    (v, t) => ObjectCopyWith(v, $identity, t),
    (v) => call(unknownFields: v),
  );
  @override
  $R call({
    String? id,
    String? name,
    Object? author = $none,
    Object? description = $none,
    Object? gameVersion = $none,
    Object? homepageUrl = $none,
    Object? updateUrl = $none,
    List<ModpackDraftItem>? items,
    Map<String, dynamic>? unknownFields,
    Object? updatedAt = $none,
  }) => $apply(
    FieldCopyWithData({
      if (id != null) #id: id,
      if (name != null) #name: name,
      if (author != $none) #author: author,
      if (description != $none) #description: description,
      if (gameVersion != $none) #gameVersion: gameVersion,
      if (homepageUrl != $none) #homepageUrl: homepageUrl,
      if (updateUrl != $none) #updateUrl: updateUrl,
      if (items != null) #items: items,
      if (unknownFields != null) #unknownFields: unknownFields,
      if (updatedAt != $none) #updatedAt: updatedAt,
    }),
  );
  @override
  ModpackDraft $make(CopyWithData data) => ModpackDraft(
    id: data.get(#id, or: $value.id),
    name: data.get(#name, or: $value.name),
    author: data.get(#author, or: $value.author),
    description: data.get(#description, or: $value.description),
    gameVersion: data.get(#gameVersion, or: $value.gameVersion),
    homepageUrl: data.get(#homepageUrl, or: $value.homepageUrl),
    updateUrl: data.get(#updateUrl, or: $value.updateUrl),
    items: data.get(#items, or: $value.items),
    unknownFields: data.get(#unknownFields, or: $value.unknownFields),
    updatedAt: data.get(#updatedAt, or: $value.updatedAt),
  );

  @override
  ModpackDraftCopyWith<$R2, ModpackDraft, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _ModpackDraftCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

