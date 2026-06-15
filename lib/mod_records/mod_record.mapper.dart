// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'mod_record.dart';

class ModRecordMapper extends ClassMapperBase<ModRecord> {
  ModRecordMapper._();

  static ModRecordMapper? _instance;
  static ModRecordMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ModRecordMapper._());
      ModRecordSourceMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'ModRecord';

  static String _$recordKey(ModRecord v) => v.recordKey;
  static const Field<ModRecord, String> _f$recordKey = Field(
    'recordKey',
    _$recordKey,
  );
  static String? _$modId(ModRecord v) => v.modId;
  static const Field<ModRecord, String> _f$modId = Field(
    'modId',
    _$modId,
    opt: true,
  );
  static DateTime? _$firstSeen(ModRecord v) => v.firstSeen;
  static const Field<ModRecord, DateTime> _f$firstSeen = Field(
    'firstSeen',
    _$firstSeen,
    opt: true,
  );
  static Map<String, ModRecordSource> _$sources(ModRecord v) => v.sources;
  static const Field<ModRecord, Map<String, ModRecordSource>> _f$sources =
      Field('sources', _$sources, opt: true, def: const {});
  static Map<String, ModRecordSource> _$userOverrides(ModRecord v) =>
      v.userOverrides;
  static const Field<ModRecord, Map<String, ModRecordSource>> _f$userOverrides =
      Field('userOverrides', _$userOverrides, opt: true, def: const {});
  static Map<String, ModRecordSource> _$resolvedSources(ModRecord v) =>
      v.resolvedSources;
  static const Field<ModRecord, Map<String, ModRecordSource>>
  _f$resolvedSources = Field(
    'resolvedSources',
    _$resolvedSources,
    mode: FieldMode.member,
  );
  static InstalledSource? _$installed(ModRecord v) => v.installed;
  static const Field<ModRecord, InstalledSource> _f$installed = Field(
    'installed',
    _$installed,
    mode: FieldMode.member,
  );
  static CatalogSource? _$catalog(ModRecord v) => v.catalog;
  static const Field<ModRecord, CatalogSource> _f$catalog = Field(
    'catalog',
    _$catalog,
    mode: FieldMode.member,
  );
  static VersionCheckerSource? _$versionChecker(ModRecord v) =>
      v.versionChecker;
  static const Field<ModRecord, VersionCheckerSource> _f$versionChecker = Field(
    'versionChecker',
    _$versionChecker,
    mode: FieldMode.member,
  );
  static DownloadHistorySource? _$downloadHistory(ModRecord v) =>
      v.downloadHistory;
  static const Field<ModRecord, DownloadHistorySource> _f$downloadHistory =
      Field('downloadHistory', _$downloadHistory, mode: FieldMode.member);
  static ForumDataSource? _$forumData(ModRecord v) => v.forumData;
  static const Field<ModRecord, ForumDataSource> _f$forumData = Field(
    'forumData',
    _$forumData,
    mode: FieldMode.member,
  );
  static Set<String> _$allNames(ModRecord v) => v.allNames;
  static const Field<ModRecord, Set<String>> _f$allNames = Field(
    'allNames',
    _$allNames,
    mode: FieldMode.member,
  );
  static Set<String> _$allAuthors(ModRecord v) => v.allAuthors;
  static const Field<ModRecord, Set<String>> _f$allAuthors = Field(
    'allAuthors',
    _$allAuthors,
    mode: FieldMode.member,
  );
  static String? _$forumThreadId(ModRecord v) => v.forumThreadId;
  static const Field<ModRecord, String> _f$forumThreadId = Field(
    'forumThreadId',
    _$forumThreadId,
    mode: FieldMode.member,
  );
  static String? _$nexusModsId(ModRecord v) => v.nexusModsId;
  static const Field<ModRecord, String> _f$nexusModsId = Field(
    'nexusModsId',
    _$nexusModsId,
    mode: FieldMode.member,
  );

  @override
  final MappableFields<ModRecord> fields = const {
    #recordKey: _f$recordKey,
    #modId: _f$modId,
    #firstSeen: _f$firstSeen,
    #sources: _f$sources,
    #userOverrides: _f$userOverrides,
    #resolvedSources: _f$resolvedSources,
    #installed: _f$installed,
    #catalog: _f$catalog,
    #versionChecker: _f$versionChecker,
    #downloadHistory: _f$downloadHistory,
    #forumData: _f$forumData,
    #allNames: _f$allNames,
    #allAuthors: _f$allAuthors,
    #forumThreadId: _f$forumThreadId,
    #nexusModsId: _f$nexusModsId,
  };

  static ModRecord _instantiate(DecodingData data) {
    return ModRecord(
      recordKey: data.dec(_f$recordKey),
      modId: data.dec(_f$modId),
      firstSeen: data.dec(_f$firstSeen),
      sources: data.dec(_f$sources),
      userOverrides: data.dec(_f$userOverrides),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static ModRecord fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<ModRecord>(map);
  }

  static ModRecord fromJson(String json) {
    return ensureInitialized().decodeJson<ModRecord>(json);
  }
}

mixin ModRecordMappable {
  String toJson() {
    return ModRecordMapper.ensureInitialized().encodeJson<ModRecord>(
      this as ModRecord,
    );
  }

  Map<String, dynamic> toMap() {
    return ModRecordMapper.ensureInitialized().encodeMap<ModRecord>(
      this as ModRecord,
    );
  }

  ModRecordCopyWith<ModRecord, ModRecord, ModRecord> get copyWith =>
      _ModRecordCopyWithImpl<ModRecord, ModRecord>(
        this as ModRecord,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return ModRecordMapper.ensureInitialized().stringifyValue(
      this as ModRecord,
    );
  }

  @override
  bool operator ==(Object other) {
    return ModRecordMapper.ensureInitialized().equalsValue(
      this as ModRecord,
      other,
    );
  }

  @override
  int get hashCode {
    return ModRecordMapper.ensureInitialized().hashValue(this as ModRecord);
  }
}

extension ModRecordValueCopy<$R, $Out> on ObjectCopyWith<$R, ModRecord, $Out> {
  ModRecordCopyWith<$R, ModRecord, $Out> get $asModRecord =>
      $base.as((v, t, t2) => _ModRecordCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class ModRecordCopyWith<$R, $In extends ModRecord, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  MapCopyWith<
    $R,
    String,
    ModRecordSource,
    ModRecordSourceCopyWith<$R, ModRecordSource, ModRecordSource>
  >
  get sources;
  MapCopyWith<
    $R,
    String,
    ModRecordSource,
    ModRecordSourceCopyWith<$R, ModRecordSource, ModRecordSource>
  >
  get userOverrides;
  $R call({
    String? recordKey,
    String? modId,
    DateTime? firstSeen,
    Map<String, ModRecordSource>? sources,
    Map<String, ModRecordSource>? userOverrides,
  });
  ModRecordCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _ModRecordCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, ModRecord, $Out>
    implements ModRecordCopyWith<$R, ModRecord, $Out> {
  _ModRecordCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<ModRecord> $mapper =
      ModRecordMapper.ensureInitialized();
  @override
  MapCopyWith<
    $R,
    String,
    ModRecordSource,
    ModRecordSourceCopyWith<$R, ModRecordSource, ModRecordSource>
  >
  get sources => MapCopyWith(
    $value.sources,
    (v, t) => v.copyWith.$chain(t),
    (v) => call(sources: v),
  );
  @override
  MapCopyWith<
    $R,
    String,
    ModRecordSource,
    ModRecordSourceCopyWith<$R, ModRecordSource, ModRecordSource>
  >
  get userOverrides => MapCopyWith(
    $value.userOverrides,
    (v, t) => v.copyWith.$chain(t),
    (v) => call(userOverrides: v),
  );
  @override
  $R call({
    String? recordKey,
    Object? modId = $none,
    Object? firstSeen = $none,
    Map<String, ModRecordSource>? sources,
    Map<String, ModRecordSource>? userOverrides,
  }) => $apply(
    FieldCopyWithData({
      if (recordKey != null) #recordKey: recordKey,
      if (modId != $none) #modId: modId,
      if (firstSeen != $none) #firstSeen: firstSeen,
      if (sources != null) #sources: sources,
      if (userOverrides != null) #userOverrides: userOverrides,
    }),
  );
  @override
  ModRecord $make(CopyWithData data) => ModRecord(
    recordKey: data.get(#recordKey, or: $value.recordKey),
    modId: data.get(#modId, or: $value.modId),
    firstSeen: data.get(#firstSeen, or: $value.firstSeen),
    sources: data.get(#sources, or: $value.sources),
    userOverrides: data.get(#userOverrides, or: $value.userOverrides),
  );

  @override
  ModRecordCopyWith<$R2, ModRecord, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _ModRecordCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class ModRecordsMapper extends ClassMapperBase<ModRecords> {
  ModRecordsMapper._();

  static ModRecordsMapper? _instance;
  static ModRecordsMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ModRecordsMapper._());
      ModRecordMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'ModRecords';

  static Map<String, ModRecord> _$records(ModRecords v) => v.records;
  static const Field<ModRecords, Map<String, ModRecord>> _f$records = Field(
    'records',
    _$records,
    opt: true,
    def: const {},
  );

  @override
  final MappableFields<ModRecords> fields = const {#records: _f$records};

  static ModRecords _instantiate(DecodingData data) {
    return ModRecords(records: data.dec(_f$records));
  }

  @override
  final Function instantiate = _instantiate;

  static ModRecords fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<ModRecords>(map);
  }

  static ModRecords fromJson(String json) {
    return ensureInitialized().decodeJson<ModRecords>(json);
  }
}

mixin ModRecordsMappable {
  String toJson() {
    return ModRecordsMapper.ensureInitialized().encodeJson<ModRecords>(
      this as ModRecords,
    );
  }

  Map<String, dynamic> toMap() {
    return ModRecordsMapper.ensureInitialized().encodeMap<ModRecords>(
      this as ModRecords,
    );
  }

  ModRecordsCopyWith<ModRecords, ModRecords, ModRecords> get copyWith =>
      _ModRecordsCopyWithImpl<ModRecords, ModRecords>(
        this as ModRecords,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return ModRecordsMapper.ensureInitialized().stringifyValue(
      this as ModRecords,
    );
  }

  @override
  bool operator ==(Object other) {
    return ModRecordsMapper.ensureInitialized().equalsValue(
      this as ModRecords,
      other,
    );
  }

  @override
  int get hashCode {
    return ModRecordsMapper.ensureInitialized().hashValue(this as ModRecords);
  }
}

extension ModRecordsValueCopy<$R, $Out>
    on ObjectCopyWith<$R, ModRecords, $Out> {
  ModRecordsCopyWith<$R, ModRecords, $Out> get $asModRecords =>
      $base.as((v, t, t2) => _ModRecordsCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class ModRecordsCopyWith<$R, $In extends ModRecords, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  MapCopyWith<
    $R,
    String,
    ModRecord,
    ModRecordCopyWith<$R, ModRecord, ModRecord>
  >
  get records;
  $R call({Map<String, ModRecord>? records});
  ModRecordsCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _ModRecordsCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, ModRecords, $Out>
    implements ModRecordsCopyWith<$R, ModRecords, $Out> {
  _ModRecordsCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<ModRecords> $mapper =
      ModRecordsMapper.ensureInitialized();
  @override
  MapCopyWith<
    $R,
    String,
    ModRecord,
    ModRecordCopyWith<$R, ModRecord, ModRecord>
  >
  get records => MapCopyWith(
    $value.records,
    (v, t) => v.copyWith.$chain(t),
    (v) => call(records: v),
  );
  @override
  $R call({Map<String, ModRecord>? records}) =>
      $apply(FieldCopyWithData({if (records != null) #records: records}));
  @override
  ModRecords $make(CopyWithData data) =>
      ModRecords(records: data.get(#records, or: $value.records));

  @override
  ModRecordsCopyWith<$R2, ModRecords, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _ModRecordsCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

