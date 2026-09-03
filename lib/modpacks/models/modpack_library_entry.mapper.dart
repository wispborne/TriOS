// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'modpack_library_entry.dart';

class ModpackItemFailureMapper extends ClassMapperBase<ModpackItemFailure> {
  ModpackItemFailureMapper._();

  static ModpackItemFailureMapper? _instance;
  static ModpackItemFailureMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ModpackItemFailureMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'ModpackItemFailure';

  static String _$modId(ModpackItemFailure v) => v.modId;
  static const Field<ModpackItemFailure, String> _f$modId = Field(
    'modId',
    _$modId,
  );
  static String _$sourceFingerprint(ModpackItemFailure v) =>
      v.sourceFingerprint;
  static const Field<ModpackItemFailure, String> _f$sourceFingerprint = Field(
    'sourceFingerprint',
    _$sourceFingerprint,
  );
  static String _$message(ModpackItemFailure v) => v.message;
  static const Field<ModpackItemFailure, String> _f$message = Field(
    'message',
    _$message,
  );
  static DateTime _$failedAt(ModpackItemFailure v) => v.failedAt;
  static const Field<ModpackItemFailure, DateTime> _f$failedAt = Field(
    'failedAt',
    _$failedAt,
  );

  @override
  final MappableFields<ModpackItemFailure> fields = const {
    #modId: _f$modId,
    #sourceFingerprint: _f$sourceFingerprint,
    #message: _f$message,
    #failedAt: _f$failedAt,
  };

  static ModpackItemFailure _instantiate(DecodingData data) {
    return ModpackItemFailure(
      modId: data.dec(_f$modId),
      sourceFingerprint: data.dec(_f$sourceFingerprint),
      message: data.dec(_f$message),
      failedAt: data.dec(_f$failedAt),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static ModpackItemFailure fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<ModpackItemFailure>(map);
  }

  static ModpackItemFailure fromJson(String json) {
    return ensureInitialized().decodeJson<ModpackItemFailure>(json);
  }
}

mixin ModpackItemFailureMappable {
  String toJson() {
    return ModpackItemFailureMapper.ensureInitialized()
        .encodeJson<ModpackItemFailure>(this as ModpackItemFailure);
  }

  Map<String, dynamic> toMap() {
    return ModpackItemFailureMapper.ensureInitialized()
        .encodeMap<ModpackItemFailure>(this as ModpackItemFailure);
  }

  ModpackItemFailureCopyWith<
    ModpackItemFailure,
    ModpackItemFailure,
    ModpackItemFailure
  >
  get copyWith =>
      _ModpackItemFailureCopyWithImpl<ModpackItemFailure, ModpackItemFailure>(
        this as ModpackItemFailure,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return ModpackItemFailureMapper.ensureInitialized().stringifyValue(
      this as ModpackItemFailure,
    );
  }

  @override
  bool operator ==(Object other) {
    return ModpackItemFailureMapper.ensureInitialized().equalsValue(
      this as ModpackItemFailure,
      other,
    );
  }

  @override
  int get hashCode {
    return ModpackItemFailureMapper.ensureInitialized().hashValue(
      this as ModpackItemFailure,
    );
  }
}

extension ModpackItemFailureValueCopy<$R, $Out>
    on ObjectCopyWith<$R, ModpackItemFailure, $Out> {
  ModpackItemFailureCopyWith<$R, ModpackItemFailure, $Out>
  get $asModpackItemFailure => $base.as(
    (v, t, t2) => _ModpackItemFailureCopyWithImpl<$R, $Out>(v, t, t2),
  );
}

abstract class ModpackItemFailureCopyWith<
  $R,
  $In extends ModpackItemFailure,
  $Out
>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({
    String? modId,
    String? sourceFingerprint,
    String? message,
    DateTime? failedAt,
  });
  ModpackItemFailureCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _ModpackItemFailureCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, ModpackItemFailure, $Out>
    implements ModpackItemFailureCopyWith<$R, ModpackItemFailure, $Out> {
  _ModpackItemFailureCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<ModpackItemFailure> $mapper =
      ModpackItemFailureMapper.ensureInitialized();
  @override
  $R call({
    String? modId,
    String? sourceFingerprint,
    String? message,
    DateTime? failedAt,
  }) => $apply(
    FieldCopyWithData({
      if (modId != null) #modId: modId,
      if (sourceFingerprint != null) #sourceFingerprint: sourceFingerprint,
      if (message != null) #message: message,
      if (failedAt != null) #failedAt: failedAt,
    }),
  );
  @override
  ModpackItemFailure $make(CopyWithData data) => ModpackItemFailure(
    modId: data.get(#modId, or: $value.modId),
    sourceFingerprint: data.get(
      #sourceFingerprint,
      or: $value.sourceFingerprint,
    ),
    message: data.get(#message, or: $value.message),
    failedAt: data.get(#failedAt, or: $value.failedAt),
  );

  @override
  ModpackItemFailureCopyWith<$R2, ModpackItemFailure, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _ModpackItemFailureCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class ModpackUpdateCheckMapper extends ClassMapperBase<ModpackUpdateCheck> {
  ModpackUpdateCheckMapper._();

  static ModpackUpdateCheckMapper? _instance;
  static ModpackUpdateCheckMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ModpackUpdateCheckMapper._());
      ModpackDefinitionMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'ModpackUpdateCheck';

  static ModpackDefinition? _$onlineDefinition(ModpackUpdateCheck v) =>
      v.onlineDefinition;
  static const Field<ModpackUpdateCheck, ModpackDefinition>
  _f$onlineDefinition = Field(
    'onlineDefinition',
    _$onlineDefinition,
    opt: true,
  );
  static DateTime? _$succeededAt(ModpackUpdateCheck v) => v.succeededAt;
  static const Field<ModpackUpdateCheck, DateTime> _f$succeededAt = Field(
    'succeededAt',
    _$succeededAt,
    opt: true,
  );
  static String? _$error(ModpackUpdateCheck v) => v.error;
  static const Field<ModpackUpdateCheck, String> _f$error = Field(
    'error',
    _$error,
    opt: true,
  );
  static DateTime? _$failedAt(ModpackUpdateCheck v) => v.failedAt;
  static const Field<ModpackUpdateCheck, DateTime> _f$failedAt = Field(
    'failedAt',
    _$failedAt,
    opt: true,
  );

  @override
  final MappableFields<ModpackUpdateCheck> fields = const {
    #onlineDefinition: _f$onlineDefinition,
    #succeededAt: _f$succeededAt,
    #error: _f$error,
    #failedAt: _f$failedAt,
  };

  static ModpackUpdateCheck _instantiate(DecodingData data) {
    return ModpackUpdateCheck(
      onlineDefinition: data.dec(_f$onlineDefinition),
      succeededAt: data.dec(_f$succeededAt),
      error: data.dec(_f$error),
      failedAt: data.dec(_f$failedAt),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static ModpackUpdateCheck fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<ModpackUpdateCheck>(map);
  }

  static ModpackUpdateCheck fromJson(String json) {
    return ensureInitialized().decodeJson<ModpackUpdateCheck>(json);
  }
}

mixin ModpackUpdateCheckMappable {
  String toJson() {
    return ModpackUpdateCheckMapper.ensureInitialized()
        .encodeJson<ModpackUpdateCheck>(this as ModpackUpdateCheck);
  }

  Map<String, dynamic> toMap() {
    return ModpackUpdateCheckMapper.ensureInitialized()
        .encodeMap<ModpackUpdateCheck>(this as ModpackUpdateCheck);
  }

  ModpackUpdateCheckCopyWith<
    ModpackUpdateCheck,
    ModpackUpdateCheck,
    ModpackUpdateCheck
  >
  get copyWith =>
      _ModpackUpdateCheckCopyWithImpl<ModpackUpdateCheck, ModpackUpdateCheck>(
        this as ModpackUpdateCheck,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return ModpackUpdateCheckMapper.ensureInitialized().stringifyValue(
      this as ModpackUpdateCheck,
    );
  }

  @override
  bool operator ==(Object other) {
    return ModpackUpdateCheckMapper.ensureInitialized().equalsValue(
      this as ModpackUpdateCheck,
      other,
    );
  }

  @override
  int get hashCode {
    return ModpackUpdateCheckMapper.ensureInitialized().hashValue(
      this as ModpackUpdateCheck,
    );
  }
}

extension ModpackUpdateCheckValueCopy<$R, $Out>
    on ObjectCopyWith<$R, ModpackUpdateCheck, $Out> {
  ModpackUpdateCheckCopyWith<$R, ModpackUpdateCheck, $Out>
  get $asModpackUpdateCheck => $base.as(
    (v, t, t2) => _ModpackUpdateCheckCopyWithImpl<$R, $Out>(v, t, t2),
  );
}

abstract class ModpackUpdateCheckCopyWith<
  $R,
  $In extends ModpackUpdateCheck,
  $Out
>
    implements ClassCopyWith<$R, $In, $Out> {
  ModpackDefinitionCopyWith<$R, ModpackDefinition, ModpackDefinition>?
  get onlineDefinition;
  $R call({
    ModpackDefinition? onlineDefinition,
    DateTime? succeededAt,
    String? error,
    DateTime? failedAt,
  });
  ModpackUpdateCheckCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _ModpackUpdateCheckCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, ModpackUpdateCheck, $Out>
    implements ModpackUpdateCheckCopyWith<$R, ModpackUpdateCheck, $Out> {
  _ModpackUpdateCheckCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<ModpackUpdateCheck> $mapper =
      ModpackUpdateCheckMapper.ensureInitialized();
  @override
  ModpackDefinitionCopyWith<$R, ModpackDefinition, ModpackDefinition>?
  get onlineDefinition => $value.onlineDefinition?.copyWith.$chain(
    (v) => call(onlineDefinition: v),
  );
  @override
  $R call({
    Object? onlineDefinition = $none,
    Object? succeededAt = $none,
    Object? error = $none,
    Object? failedAt = $none,
  }) => $apply(
    FieldCopyWithData({
      if (onlineDefinition != $none) #onlineDefinition: onlineDefinition,
      if (succeededAt != $none) #succeededAt: succeededAt,
      if (error != $none) #error: error,
      if (failedAt != $none) #failedAt: failedAt,
    }),
  );
  @override
  ModpackUpdateCheck $make(CopyWithData data) => ModpackUpdateCheck(
    onlineDefinition: data.get(#onlineDefinition, or: $value.onlineDefinition),
    succeededAt: data.get(#succeededAt, or: $value.succeededAt),
    error: data.get(#error, or: $value.error),
    failedAt: data.get(#failedAt, or: $value.failedAt),
  );

  @override
  ModpackUpdateCheckCopyWith<$R2, ModpackUpdateCheck, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _ModpackUpdateCheckCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class ModpackLibraryEntryMapper extends ClassMapperBase<ModpackLibraryEntry> {
  ModpackLibraryEntryMapper._();

  static ModpackLibraryEntryMapper? _instance;
  static ModpackLibraryEntryMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ModpackLibraryEntryMapper._());
      ModpackDefinitionMapper.ensureInitialized();
      ModpackUpdateCheckMapper.ensureInitialized();
      ModpackItemFailureMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'ModpackLibraryEntry';

  static ModpackDefinition _$definition(ModpackLibraryEntry v) => v.definition;
  static const Field<ModpackLibraryEntry, ModpackDefinition> _f$definition =
      Field('definition', _$definition);
  static DateTime? _$savedAt(ModpackLibraryEntry v) => v.savedAt;
  static const Field<ModpackLibraryEntry, DateTime> _f$savedAt = Field(
    'savedAt',
    _$savedAt,
    opt: true,
  );
  static ModpackUpdateCheck? _$updateCheck(ModpackLibraryEntry v) =>
      v.updateCheck;
  static const Field<ModpackLibraryEntry, ModpackUpdateCheck> _f$updateCheck =
      Field('updateCheck', _$updateCheck, opt: true);
  static String? _$lastExportPath(ModpackLibraryEntry v) => v.lastExportPath;
  static const Field<ModpackLibraryEntry, String> _f$lastExportPath = Field(
    'lastExportPath',
    _$lastExportPath,
    opt: true,
  );
  static Map<String, ModpackItemFailure> _$itemFailures(
    ModpackLibraryEntry v,
  ) => v.itemFailures;
  static const Field<ModpackLibraryEntry, Map<String, ModpackItemFailure>>
  _f$itemFailures = Field(
    'itemFailures',
    _$itemFailures,
    opt: true,
    def: const {},
  );

  @override
  final MappableFields<ModpackLibraryEntry> fields = const {
    #definition: _f$definition,
    #savedAt: _f$savedAt,
    #updateCheck: _f$updateCheck,
    #lastExportPath: _f$lastExportPath,
    #itemFailures: _f$itemFailures,
  };

  static ModpackLibraryEntry _instantiate(DecodingData data) {
    return ModpackLibraryEntry(
      definition: data.dec(_f$definition),
      savedAt: data.dec(_f$savedAt),
      updateCheck: data.dec(_f$updateCheck),
      lastExportPath: data.dec(_f$lastExportPath),
      itemFailures: data.dec(_f$itemFailures),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static ModpackLibraryEntry fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<ModpackLibraryEntry>(map);
  }

  static ModpackLibraryEntry fromJson(String json) {
    return ensureInitialized().decodeJson<ModpackLibraryEntry>(json);
  }
}

mixin ModpackLibraryEntryMappable {
  String toJson() {
    return ModpackLibraryEntryMapper.ensureInitialized()
        .encodeJson<ModpackLibraryEntry>(this as ModpackLibraryEntry);
  }

  Map<String, dynamic> toMap() {
    return ModpackLibraryEntryMapper.ensureInitialized()
        .encodeMap<ModpackLibraryEntry>(this as ModpackLibraryEntry);
  }

  ModpackLibraryEntryCopyWith<
    ModpackLibraryEntry,
    ModpackLibraryEntry,
    ModpackLibraryEntry
  >
  get copyWith =>
      _ModpackLibraryEntryCopyWithImpl<
        ModpackLibraryEntry,
        ModpackLibraryEntry
      >(this as ModpackLibraryEntry, $identity, $identity);
  @override
  String toString() {
    return ModpackLibraryEntryMapper.ensureInitialized().stringifyValue(
      this as ModpackLibraryEntry,
    );
  }

  @override
  bool operator ==(Object other) {
    return ModpackLibraryEntryMapper.ensureInitialized().equalsValue(
      this as ModpackLibraryEntry,
      other,
    );
  }

  @override
  int get hashCode {
    return ModpackLibraryEntryMapper.ensureInitialized().hashValue(
      this as ModpackLibraryEntry,
    );
  }
}

extension ModpackLibraryEntryValueCopy<$R, $Out>
    on ObjectCopyWith<$R, ModpackLibraryEntry, $Out> {
  ModpackLibraryEntryCopyWith<$R, ModpackLibraryEntry, $Out>
  get $asModpackLibraryEntry => $base.as(
    (v, t, t2) => _ModpackLibraryEntryCopyWithImpl<$R, $Out>(v, t, t2),
  );
}

abstract class ModpackLibraryEntryCopyWith<
  $R,
  $In extends ModpackLibraryEntry,
  $Out
>
    implements ClassCopyWith<$R, $In, $Out> {
  ModpackDefinitionCopyWith<$R, ModpackDefinition, ModpackDefinition>
  get definition;
  ModpackUpdateCheckCopyWith<$R, ModpackUpdateCheck, ModpackUpdateCheck>?
  get updateCheck;
  MapCopyWith<
    $R,
    String,
    ModpackItemFailure,
    ModpackItemFailureCopyWith<$R, ModpackItemFailure, ModpackItemFailure>
  >
  get itemFailures;
  $R call({
    ModpackDefinition? definition,
    DateTime? savedAt,
    ModpackUpdateCheck? updateCheck,
    String? lastExportPath,
    Map<String, ModpackItemFailure>? itemFailures,
  });
  ModpackLibraryEntryCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _ModpackLibraryEntryCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, ModpackLibraryEntry, $Out>
    implements ModpackLibraryEntryCopyWith<$R, ModpackLibraryEntry, $Out> {
  _ModpackLibraryEntryCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<ModpackLibraryEntry> $mapper =
      ModpackLibraryEntryMapper.ensureInitialized();
  @override
  ModpackDefinitionCopyWith<$R, ModpackDefinition, ModpackDefinition>
  get definition =>
      $value.definition.copyWith.$chain((v) => call(definition: v));
  @override
  ModpackUpdateCheckCopyWith<$R, ModpackUpdateCheck, ModpackUpdateCheck>?
  get updateCheck =>
      $value.updateCheck?.copyWith.$chain((v) => call(updateCheck: v));
  @override
  MapCopyWith<
    $R,
    String,
    ModpackItemFailure,
    ModpackItemFailureCopyWith<$R, ModpackItemFailure, ModpackItemFailure>
  >
  get itemFailures => MapCopyWith(
    $value.itemFailures,
    (v, t) => v.copyWith.$chain(t),
    (v) => call(itemFailures: v),
  );
  @override
  $R call({
    ModpackDefinition? definition,
    Object? savedAt = $none,
    Object? updateCheck = $none,
    Object? lastExportPath = $none,
    Map<String, ModpackItemFailure>? itemFailures,
  }) => $apply(
    FieldCopyWithData({
      if (definition != null) #definition: definition,
      if (savedAt != $none) #savedAt: savedAt,
      if (updateCheck != $none) #updateCheck: updateCheck,
      if (lastExportPath != $none) #lastExportPath: lastExportPath,
      if (itemFailures != null) #itemFailures: itemFailures,
    }),
  );
  @override
  ModpackLibraryEntry $make(CopyWithData data) => ModpackLibraryEntry(
    definition: data.get(#definition, or: $value.definition),
    savedAt: data.get(#savedAt, or: $value.savedAt),
    updateCheck: data.get(#updateCheck, or: $value.updateCheck),
    lastExportPath: data.get(#lastExportPath, or: $value.lastExportPath),
    itemFailures: data.get(#itemFailures, or: $value.itemFailures),
  );

  @override
  ModpackLibraryEntryCopyWith<$R2, ModpackLibraryEntry, $Out2>
  $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _ModpackLibraryEntryCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class ModpacksDataMapper extends ClassMapperBase<ModpacksData> {
  ModpacksDataMapper._();

  static ModpacksDataMapper? _instance;
  static ModpacksDataMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ModpacksDataMapper._());
      ModpackLibraryEntryMapper.ensureInitialized();
      ModpackDraftMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'ModpacksData';

  static Map<String, ModpackLibraryEntry> _$packs(ModpacksData v) => v.packs;
  static const Field<ModpacksData, Map<String, ModpackLibraryEntry>> _f$packs =
      Field('packs', _$packs, opt: true, def: const {});
  static Map<String, ModpackDraft> _$drafts(ModpacksData v) => v.drafts;
  static const Field<ModpacksData, Map<String, ModpackDraft>> _f$drafts = Field(
    'drafts',
    _$drafts,
    opt: true,
    def: const {},
  );

  @override
  final MappableFields<ModpacksData> fields = const {
    #packs: _f$packs,
    #drafts: _f$drafts,
  };

  static ModpacksData _instantiate(DecodingData data) {
    return ModpacksData(packs: data.dec(_f$packs), drafts: data.dec(_f$drafts));
  }

  @override
  final Function instantiate = _instantiate;

  static ModpacksData fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<ModpacksData>(map);
  }

  static ModpacksData fromJson(String json) {
    return ensureInitialized().decodeJson<ModpacksData>(json);
  }
}

mixin ModpacksDataMappable {
  String toJson() {
    return ModpacksDataMapper.ensureInitialized().encodeJson<ModpacksData>(
      this as ModpacksData,
    );
  }

  Map<String, dynamic> toMap() {
    return ModpacksDataMapper.ensureInitialized().encodeMap<ModpacksData>(
      this as ModpacksData,
    );
  }

  ModpacksDataCopyWith<ModpacksData, ModpacksData, ModpacksData> get copyWith =>
      _ModpacksDataCopyWithImpl<ModpacksData, ModpacksData>(
        this as ModpacksData,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return ModpacksDataMapper.ensureInitialized().stringifyValue(
      this as ModpacksData,
    );
  }

  @override
  bool operator ==(Object other) {
    return ModpacksDataMapper.ensureInitialized().equalsValue(
      this as ModpacksData,
      other,
    );
  }

  @override
  int get hashCode {
    return ModpacksDataMapper.ensureInitialized().hashValue(
      this as ModpacksData,
    );
  }
}

extension ModpacksDataValueCopy<$R, $Out>
    on ObjectCopyWith<$R, ModpacksData, $Out> {
  ModpacksDataCopyWith<$R, ModpacksData, $Out> get $asModpacksData =>
      $base.as((v, t, t2) => _ModpacksDataCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class ModpacksDataCopyWith<$R, $In extends ModpacksData, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  MapCopyWith<
    $R,
    String,
    ModpackLibraryEntry,
    ModpackLibraryEntryCopyWith<$R, ModpackLibraryEntry, ModpackLibraryEntry>
  >
  get packs;
  MapCopyWith<
    $R,
    String,
    ModpackDraft,
    ModpackDraftCopyWith<$R, ModpackDraft, ModpackDraft>
  >
  get drafts;
  $R call({
    Map<String, ModpackLibraryEntry>? packs,
    Map<String, ModpackDraft>? drafts,
  });
  ModpacksDataCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _ModpacksDataCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, ModpacksData, $Out>
    implements ModpacksDataCopyWith<$R, ModpacksData, $Out> {
  _ModpacksDataCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<ModpacksData> $mapper =
      ModpacksDataMapper.ensureInitialized();
  @override
  MapCopyWith<
    $R,
    String,
    ModpackLibraryEntry,
    ModpackLibraryEntryCopyWith<$R, ModpackLibraryEntry, ModpackLibraryEntry>
  >
  get packs => MapCopyWith(
    $value.packs,
    (v, t) => v.copyWith.$chain(t),
    (v) => call(packs: v),
  );
  @override
  MapCopyWith<
    $R,
    String,
    ModpackDraft,
    ModpackDraftCopyWith<$R, ModpackDraft, ModpackDraft>
  >
  get drafts => MapCopyWith(
    $value.drafts,
    (v, t) => v.copyWith.$chain(t),
    (v) => call(drafts: v),
  );
  @override
  $R call({
    Map<String, ModpackLibraryEntry>? packs,
    Map<String, ModpackDraft>? drafts,
  }) => $apply(
    FieldCopyWithData({
      if (packs != null) #packs: packs,
      if (drafts != null) #drafts: drafts,
    }),
  );
  @override
  ModpacksData $make(CopyWithData data) => ModpacksData(
    packs: data.get(#packs, or: $value.packs),
    drafts: data.get(#drafts, or: $value.drafts),
  );

  @override
  ModpacksDataCopyWith<$R2, ModpacksData, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _ModpacksDataCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

