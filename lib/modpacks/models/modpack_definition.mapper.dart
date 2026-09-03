// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'modpack_definition.dart';

class ModpackItemSourceTypeMapper extends EnumMapper<ModpackItemSourceType> {
  ModpackItemSourceTypeMapper._();

  static ModpackItemSourceTypeMapper? _instance;
  static ModpackItemSourceTypeMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ModpackItemSourceTypeMapper._());
    }
    return _instance!;
  }

  static ModpackItemSourceType fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  ModpackItemSourceType decode(dynamic value) {
    switch (value) {
      case r'versionFile':
        return ModpackItemSourceType.versionFile;
      case r'directDownload':
        return ModpackItemSourceType.directDownload;
      default:
        throw MapperException.unknownEnumValue(value);
    }
  }

  @override
  dynamic encode(ModpackItemSourceType self) {
    switch (self) {
      case ModpackItemSourceType.versionFile:
        return r'versionFile';
      case ModpackItemSourceType.directDownload:
        return r'directDownload';
    }
  }
}

extension ModpackItemSourceTypeMapperExtension on ModpackItemSourceType {
  String toValue() {
    ModpackItemSourceTypeMapper.ensureInitialized();
    return MapperContainer.globals.toValue<ModpackItemSourceType>(this)
        as String;
  }
}

class ModpackCatalogCluesMapper extends ClassMapperBase<ModpackCatalogClues> {
  ModpackCatalogCluesMapper._();

  static ModpackCatalogCluesMapper? _instance;
  static ModpackCatalogCluesMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ModpackCatalogCluesMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'ModpackCatalogClues';

  static String? _$name(ModpackCatalogClues v) => v.name;
  static const Field<ModpackCatalogClues, String> _f$name = Field(
    'name',
    _$name,
    opt: true,
  );
  static String? _$forumTopicId(ModpackCatalogClues v) => v.forumTopicId;
  static const Field<ModpackCatalogClues, String> _f$forumTopicId = Field(
    'forumTopicId',
    _$forumTopicId,
    opt: true,
  );
  static String? _$nexusModsId(ModpackCatalogClues v) => v.nexusModsId;
  static const Field<ModpackCatalogClues, String> _f$nexusModsId = Field(
    'nexusModsId',
    _$nexusModsId,
    opt: true,
  );
  static Map<String, dynamic> _$unknownFields(ModpackCatalogClues v) =>
      v.unknownFields;
  static const Field<ModpackCatalogClues, Map<String, dynamic>>
  _f$unknownFields = Field(
    'unknownFields',
    _$unknownFields,
    opt: true,
    def: const {},
  );

  @override
  final MappableFields<ModpackCatalogClues> fields = const {
    #name: _f$name,
    #forumTopicId: _f$forumTopicId,
    #nexusModsId: _f$nexusModsId,
    #unknownFields: _f$unknownFields,
  };

  static ModpackCatalogClues _instantiate(DecodingData data) {
    return ModpackCatalogClues(
      name: data.dec(_f$name),
      forumTopicId: data.dec(_f$forumTopicId),
      nexusModsId: data.dec(_f$nexusModsId),
      unknownFields: data.dec(_f$unknownFields),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static ModpackCatalogClues fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<ModpackCatalogClues>(map);
  }

  static ModpackCatalogClues fromJson(String json) {
    return ensureInitialized().decodeJson<ModpackCatalogClues>(json);
  }
}

mixin ModpackCatalogCluesMappable {
  String toJson() {
    return ModpackCatalogCluesMapper.ensureInitialized()
        .encodeJson<ModpackCatalogClues>(this as ModpackCatalogClues);
  }

  Map<String, dynamic> toMap() {
    return ModpackCatalogCluesMapper.ensureInitialized()
        .encodeMap<ModpackCatalogClues>(this as ModpackCatalogClues);
  }

  ModpackCatalogCluesCopyWith<
    ModpackCatalogClues,
    ModpackCatalogClues,
    ModpackCatalogClues
  >
  get copyWith =>
      _ModpackCatalogCluesCopyWithImpl<
        ModpackCatalogClues,
        ModpackCatalogClues
      >(this as ModpackCatalogClues, $identity, $identity);
  @override
  String toString() {
    return ModpackCatalogCluesMapper.ensureInitialized().stringifyValue(
      this as ModpackCatalogClues,
    );
  }

  @override
  bool operator ==(Object other) {
    return ModpackCatalogCluesMapper.ensureInitialized().equalsValue(
      this as ModpackCatalogClues,
      other,
    );
  }

  @override
  int get hashCode {
    return ModpackCatalogCluesMapper.ensureInitialized().hashValue(
      this as ModpackCatalogClues,
    );
  }
}

extension ModpackCatalogCluesValueCopy<$R, $Out>
    on ObjectCopyWith<$R, ModpackCatalogClues, $Out> {
  ModpackCatalogCluesCopyWith<$R, ModpackCatalogClues, $Out>
  get $asModpackCatalogClues => $base.as(
    (v, t, t2) => _ModpackCatalogCluesCopyWithImpl<$R, $Out>(v, t, t2),
  );
}

abstract class ModpackCatalogCluesCopyWith<
  $R,
  $In extends ModpackCatalogClues,
  $Out
>
    implements ClassCopyWith<$R, $In, $Out> {
  MapCopyWith<$R, String, dynamic, ObjectCopyWith<$R, dynamic, dynamic>?>
  get unknownFields;
  $R call({
    String? name,
    String? forumTopicId,
    String? nexusModsId,
    Map<String, dynamic>? unknownFields,
  });
  ModpackCatalogCluesCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _ModpackCatalogCluesCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, ModpackCatalogClues, $Out>
    implements ModpackCatalogCluesCopyWith<$R, ModpackCatalogClues, $Out> {
  _ModpackCatalogCluesCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<ModpackCatalogClues> $mapper =
      ModpackCatalogCluesMapper.ensureInitialized();
  @override
  MapCopyWith<$R, String, dynamic, ObjectCopyWith<$R, dynamic, dynamic>?>
  get unknownFields => MapCopyWith(
    $value.unknownFields,
    (v, t) => ObjectCopyWith(v, $identity, t),
    (v) => call(unknownFields: v),
  );
  @override
  $R call({
    Object? name = $none,
    Object? forumTopicId = $none,
    Object? nexusModsId = $none,
    Map<String, dynamic>? unknownFields,
  }) => $apply(
    FieldCopyWithData({
      if (name != $none) #name: name,
      if (forumTopicId != $none) #forumTopicId: forumTopicId,
      if (nexusModsId != $none) #nexusModsId: nexusModsId,
      if (unknownFields != null) #unknownFields: unknownFields,
    }),
  );
  @override
  ModpackCatalogClues $make(CopyWithData data) => ModpackCatalogClues(
    name: data.get(#name, or: $value.name),
    forumTopicId: data.get(#forumTopicId, or: $value.forumTopicId),
    nexusModsId: data.get(#nexusModsId, or: $value.nexusModsId),
    unknownFields: data.get(#unknownFields, or: $value.unknownFields),
  );

  @override
  ModpackCatalogCluesCopyWith<$R2, ModpackCatalogClues, $Out2>
  $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _ModpackCatalogCluesCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class ModpackItemMapper extends ClassMapperBase<ModpackItem> {
  ModpackItemMapper._();

  static ModpackItemMapper? _instance;
  static ModpackItemMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ModpackItemMapper._());
      ModpackItemSourceTypeMapper.ensureInitialized();
      ModpackCatalogCluesMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'ModpackItem';

  static String _$modId(ModpackItem v) => v.modId;
  static const Field<ModpackItem, String> _f$modId = Field(
    'modId',
    _$modId,
    key: r'id',
  );
  static String _$url(ModpackItem v) => v.url;
  static const Field<ModpackItem, String> _f$url = Field('url', _$url);
  static ModpackItemSourceType _$sourceType(ModpackItem v) => v.sourceType;
  static const Field<ModpackItem, ModpackItemSourceType> _f$sourceType = Field(
    'sourceType',
    _$sourceType,
  );
  static String? _$name(ModpackItem v) => v.name;
  static const Field<ModpackItem, String> _f$name = Field(
    'name',
    _$name,
    opt: true,
  );
  static String? _$version(ModpackItem v) => v.version;
  static const Field<ModpackItem, String> _f$version = Field(
    'version',
    _$version,
    opt: true,
  );
  static String? _$status(ModpackItem v) => v.status;
  static const Field<ModpackItem, String> _f$status = Field(
    'status',
    _$status,
    opt: true,
  );
  static String? _$note(ModpackItem v) => v.note;
  static const Field<ModpackItem, String> _f$note = Field(
    'note',
    _$note,
    opt: true,
  );
  static ModpackCatalogClues? _$catalog(ModpackItem v) => v.catalog;
  static const Field<ModpackItem, ModpackCatalogClues> _f$catalog = Field(
    'catalog',
    _$catalog,
    opt: true,
  );
  static Map<String, dynamic> _$unknownFields(ModpackItem v) => v.unknownFields;
  static const Field<ModpackItem, Map<String, dynamic>> _f$unknownFields =
      Field('unknownFields', _$unknownFields, opt: true, def: const {});

  @override
  final MappableFields<ModpackItem> fields = const {
    #modId: _f$modId,
    #url: _f$url,
    #sourceType: _f$sourceType,
    #name: _f$name,
    #version: _f$version,
    #status: _f$status,
    #note: _f$note,
    #catalog: _f$catalog,
    #unknownFields: _f$unknownFields,
  };

  static ModpackItem _instantiate(DecodingData data) {
    return ModpackItem(
      modId: data.dec(_f$modId),
      url: data.dec(_f$url),
      sourceType: data.dec(_f$sourceType),
      name: data.dec(_f$name),
      version: data.dec(_f$version),
      status: data.dec(_f$status),
      note: data.dec(_f$note),
      catalog: data.dec(_f$catalog),
      unknownFields: data.dec(_f$unknownFields),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static ModpackItem fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<ModpackItem>(map);
  }

  static ModpackItem fromJson(String json) {
    return ensureInitialized().decodeJson<ModpackItem>(json);
  }
}

mixin ModpackItemMappable {
  String toJson() {
    return ModpackItemMapper.ensureInitialized().encodeJson<ModpackItem>(
      this as ModpackItem,
    );
  }

  Map<String, dynamic> toMap() {
    return ModpackItemMapper.ensureInitialized().encodeMap<ModpackItem>(
      this as ModpackItem,
    );
  }

  ModpackItemCopyWith<ModpackItem, ModpackItem, ModpackItem> get copyWith =>
      _ModpackItemCopyWithImpl<ModpackItem, ModpackItem>(
        this as ModpackItem,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return ModpackItemMapper.ensureInitialized().stringifyValue(
      this as ModpackItem,
    );
  }

  @override
  bool operator ==(Object other) {
    return ModpackItemMapper.ensureInitialized().equalsValue(
      this as ModpackItem,
      other,
    );
  }

  @override
  int get hashCode {
    return ModpackItemMapper.ensureInitialized().hashValue(this as ModpackItem);
  }
}

extension ModpackItemValueCopy<$R, $Out>
    on ObjectCopyWith<$R, ModpackItem, $Out> {
  ModpackItemCopyWith<$R, ModpackItem, $Out> get $asModpackItem =>
      $base.as((v, t, t2) => _ModpackItemCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class ModpackItemCopyWith<$R, $In extends ModpackItem, $Out>
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
    String? status,
    String? note,
    ModpackCatalogClues? catalog,
    Map<String, dynamic>? unknownFields,
  });
  ModpackItemCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _ModpackItemCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, ModpackItem, $Out>
    implements ModpackItemCopyWith<$R, ModpackItem, $Out> {
  _ModpackItemCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<ModpackItem> $mapper =
      ModpackItemMapper.ensureInitialized();
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
    String? modId,
    String? url,
    ModpackItemSourceType? sourceType,
    Object? name = $none,
    Object? version = $none,
    Object? status = $none,
    Object? note = $none,
    Object? catalog = $none,
    Map<String, dynamic>? unknownFields,
  }) => $apply(
    FieldCopyWithData({
      if (modId != null) #modId: modId,
      if (url != null) #url: url,
      if (sourceType != null) #sourceType: sourceType,
      if (name != $none) #name: name,
      if (version != $none) #version: version,
      if (status != $none) #status: status,
      if (note != $none) #note: note,
      if (catalog != $none) #catalog: catalog,
      if (unknownFields != null) #unknownFields: unknownFields,
    }),
  );
  @override
  ModpackItem $make(CopyWithData data) => ModpackItem(
    modId: data.get(#modId, or: $value.modId),
    url: data.get(#url, or: $value.url),
    sourceType: data.get(#sourceType, or: $value.sourceType),
    name: data.get(#name, or: $value.name),
    version: data.get(#version, or: $value.version),
    status: data.get(#status, or: $value.status),
    note: data.get(#note, or: $value.note),
    catalog: data.get(#catalog, or: $value.catalog),
    unknownFields: data.get(#unknownFields, or: $value.unknownFields),
  );

  @override
  ModpackItemCopyWith<$R2, ModpackItem, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _ModpackItemCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class ModpackDefinitionMapper extends ClassMapperBase<ModpackDefinition> {
  ModpackDefinitionMapper._();

  static ModpackDefinitionMapper? _instance;
  static ModpackDefinitionMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ModpackDefinitionMapper._());
      ModpackItemMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'ModpackDefinition';

  static int _$formatVersion(ModpackDefinition v) => v.formatVersion;
  static const Field<ModpackDefinition, int> _f$formatVersion = Field(
    'formatVersion',
    _$formatVersion,
    opt: true,
    def: ModpackDefinition.currentFormatVersion,
  );
  static String _$id(ModpackDefinition v) => v.id;
  static const Field<ModpackDefinition, String> _f$id = Field('id', _$id);
  static String _$name(ModpackDefinition v) => v.name;
  static const Field<ModpackDefinition, String> _f$name = Field('name', _$name);
  static int _$version(ModpackDefinition v) => v.version;
  static const Field<ModpackDefinition, int> _f$version = Field(
    'version',
    _$version,
  );
  static String? _$author(ModpackDefinition v) => v.author;
  static const Field<ModpackDefinition, String> _f$author = Field(
    'author',
    _$author,
    opt: true,
  );
  static String? _$description(ModpackDefinition v) => v.description;
  static const Field<ModpackDefinition, String> _f$description = Field(
    'description',
    _$description,
    opt: true,
  );
  static String? _$gameVersion(ModpackDefinition v) => v.gameVersion;
  static const Field<ModpackDefinition, String> _f$gameVersion = Field(
    'gameVersion',
    _$gameVersion,
    opt: true,
  );
  static String? _$homepageUrl(ModpackDefinition v) => v.homepageUrl;
  static const Field<ModpackDefinition, String> _f$homepageUrl = Field(
    'homepageUrl',
    _$homepageUrl,
    opt: true,
  );
  static String? _$updateUrl(ModpackDefinition v) => v.updateUrl;
  static const Field<ModpackDefinition, String> _f$updateUrl = Field(
    'updateUrl',
    _$updateUrl,
    opt: true,
  );
  static List<ModpackItem> _$items(ModpackDefinition v) => v.items;
  static const Field<ModpackDefinition, List<ModpackItem>> _f$items = Field(
    'items',
    _$items,
    opt: true,
    def: const [],
  );
  static Map<String, dynamic> _$unknownFields(ModpackDefinition v) =>
      v.unknownFields;
  static const Field<ModpackDefinition, Map<String, dynamic>> _f$unknownFields =
      Field('unknownFields', _$unknownFields, opt: true, def: const {});

  @override
  final MappableFields<ModpackDefinition> fields = const {
    #formatVersion: _f$formatVersion,
    #id: _f$id,
    #name: _f$name,
    #version: _f$version,
    #author: _f$author,
    #description: _f$description,
    #gameVersion: _f$gameVersion,
    #homepageUrl: _f$homepageUrl,
    #updateUrl: _f$updateUrl,
    #items: _f$items,
    #unknownFields: _f$unknownFields,
  };

  static ModpackDefinition _instantiate(DecodingData data) {
    return ModpackDefinition(
      formatVersion: data.dec(_f$formatVersion),
      id: data.dec(_f$id),
      name: data.dec(_f$name),
      version: data.dec(_f$version),
      author: data.dec(_f$author),
      description: data.dec(_f$description),
      gameVersion: data.dec(_f$gameVersion),
      homepageUrl: data.dec(_f$homepageUrl),
      updateUrl: data.dec(_f$updateUrl),
      items: data.dec(_f$items),
      unknownFields: data.dec(_f$unknownFields),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static ModpackDefinition fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<ModpackDefinition>(map);
  }

  static ModpackDefinition fromJson(String json) {
    return ensureInitialized().decodeJson<ModpackDefinition>(json);
  }
}

mixin ModpackDefinitionMappable {
  String toJson() {
    return ModpackDefinitionMapper.ensureInitialized()
        .encodeJson<ModpackDefinition>(this as ModpackDefinition);
  }

  Map<String, dynamic> toMap() {
    return ModpackDefinitionMapper.ensureInitialized()
        .encodeMap<ModpackDefinition>(this as ModpackDefinition);
  }

  ModpackDefinitionCopyWith<
    ModpackDefinition,
    ModpackDefinition,
    ModpackDefinition
  >
  get copyWith =>
      _ModpackDefinitionCopyWithImpl<ModpackDefinition, ModpackDefinition>(
        this as ModpackDefinition,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return ModpackDefinitionMapper.ensureInitialized().stringifyValue(
      this as ModpackDefinition,
    );
  }

  @override
  bool operator ==(Object other) {
    return ModpackDefinitionMapper.ensureInitialized().equalsValue(
      this as ModpackDefinition,
      other,
    );
  }

  @override
  int get hashCode {
    return ModpackDefinitionMapper.ensureInitialized().hashValue(
      this as ModpackDefinition,
    );
  }
}

extension ModpackDefinitionValueCopy<$R, $Out>
    on ObjectCopyWith<$R, ModpackDefinition, $Out> {
  ModpackDefinitionCopyWith<$R, ModpackDefinition, $Out>
  get $asModpackDefinition => $base.as(
    (v, t, t2) => _ModpackDefinitionCopyWithImpl<$R, $Out>(v, t, t2),
  );
}

abstract class ModpackDefinitionCopyWith<
  $R,
  $In extends ModpackDefinition,
  $Out
>
    implements ClassCopyWith<$R, $In, $Out> {
  ListCopyWith<
    $R,
    ModpackItem,
    ModpackItemCopyWith<$R, ModpackItem, ModpackItem>
  >
  get items;
  MapCopyWith<$R, String, dynamic, ObjectCopyWith<$R, dynamic, dynamic>?>
  get unknownFields;
  $R call({
    int? formatVersion,
    String? id,
    String? name,
    int? version,
    String? author,
    String? description,
    String? gameVersion,
    String? homepageUrl,
    String? updateUrl,
    List<ModpackItem>? items,
    Map<String, dynamic>? unknownFields,
  });
  ModpackDefinitionCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _ModpackDefinitionCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, ModpackDefinition, $Out>
    implements ModpackDefinitionCopyWith<$R, ModpackDefinition, $Out> {
  _ModpackDefinitionCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<ModpackDefinition> $mapper =
      ModpackDefinitionMapper.ensureInitialized();
  @override
  ListCopyWith<
    $R,
    ModpackItem,
    ModpackItemCopyWith<$R, ModpackItem, ModpackItem>
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
    int? formatVersion,
    String? id,
    String? name,
    int? version,
    Object? author = $none,
    Object? description = $none,
    Object? gameVersion = $none,
    Object? homepageUrl = $none,
    Object? updateUrl = $none,
    List<ModpackItem>? items,
    Map<String, dynamic>? unknownFields,
  }) => $apply(
    FieldCopyWithData({
      if (formatVersion != null) #formatVersion: formatVersion,
      if (id != null) #id: id,
      if (name != null) #name: name,
      if (version != null) #version: version,
      if (author != $none) #author: author,
      if (description != $none) #description: description,
      if (gameVersion != $none) #gameVersion: gameVersion,
      if (homepageUrl != $none) #homepageUrl: homepageUrl,
      if (updateUrl != $none) #updateUrl: updateUrl,
      if (items != null) #items: items,
      if (unknownFields != null) #unknownFields: unknownFields,
    }),
  );
  @override
  ModpackDefinition $make(CopyWithData data) => ModpackDefinition(
    formatVersion: data.get(#formatVersion, or: $value.formatVersion),
    id: data.get(#id, or: $value.id),
    name: data.get(#name, or: $value.name),
    version: data.get(#version, or: $value.version),
    author: data.get(#author, or: $value.author),
    description: data.get(#description, or: $value.description),
    gameVersion: data.get(#gameVersion, or: $value.gameVersion),
    homepageUrl: data.get(#homepageUrl, or: $value.homepageUrl),
    updateUrl: data.get(#updateUrl, or: $value.updateUrl),
    items: data.get(#items, or: $value.items),
    unknownFields: data.get(#unknownFields, or: $value.unknownFields),
  );

  @override
  ModpackDefinitionCopyWith<$R2, ModpackDefinition, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _ModpackDefinitionCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

