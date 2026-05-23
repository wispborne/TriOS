// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'activity_entry.dart';

class ActivitySourceTypeMapper extends EnumMapper<ActivitySourceType> {
  ActivitySourceTypeMapper._();

  static ActivitySourceTypeMapper? _instance;
  static ActivitySourceTypeMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ActivitySourceTypeMapper._());
    }
    return _instance!;
  }

  static ActivitySourceType fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  ActivitySourceType decode(dynamic value) {
    switch (value) {
      case r'download':
        return ActivitySourceType.download;
      case r'archive':
        return ActivitySourceType.archive;
      default:
        throw MapperException.unknownEnumValue(value);
    }
  }

  @override
  dynamic encode(ActivitySourceType self) {
    switch (self) {
      case ActivitySourceType.download:
        return r'download';
      case ActivitySourceType.archive:
        return r'archive';
    }
  }
}

extension ActivitySourceTypeMapperExtension on ActivitySourceType {
  String toValue() {
    ActivitySourceTypeMapper.ensureInitialized();
    return MapperContainer.globals.toValue<ActivitySourceType>(this) as String;
  }
}

class ActivityStatusMapper extends EnumMapper<ActivityStatus> {
  ActivityStatusMapper._();

  static ActivityStatusMapper? _instance;
  static ActivityStatusMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ActivityStatusMapper._());
    }
    return _instance!;
  }

  static ActivityStatus fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  ActivityStatus decode(dynamic value) {
    switch (value) {
      case r'completed':
        return ActivityStatus.completed;
      case r'failed':
        return ActivityStatus.failed;
      case r'cancelled':
        return ActivityStatus.cancelled;
      default:
        throw MapperException.unknownEnumValue(value);
    }
  }

  @override
  dynamic encode(ActivityStatus self) {
    switch (self) {
      case ActivityStatus.completed:
        return r'completed';
      case ActivityStatus.failed:
        return r'failed';
      case ActivityStatus.cancelled:
        return r'cancelled';
    }
  }
}

extension ActivityStatusMapperExtension on ActivityStatus {
  String toValue() {
    ActivityStatusMapper.ensureInitialized();
    return MapperContainer.globals.toValue<ActivityStatus>(this) as String;
  }
}

class ActivityEntryMapper extends ClassMapperBase<ActivityEntry> {
  ActivityEntryMapper._();

  static ActivityEntryMapper? _instance;
  static ActivityEntryMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ActivityEntryMapper._());
      ActivitySourceTypeMapper.ensureInitialized();
      ActivityStatusMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'ActivityEntry';

  static String _$id(ActivityEntry v) => v.id;
  static const Field<ActivityEntry, String> _f$id = Field('id', _$id);
  static String _$modName(ActivityEntry v) => v.modName;
  static const Field<ActivityEntry, String> _f$modName = Field(
    'modName',
    _$modName,
  );
  static String? _$modId(ActivityEntry v) => v.modId;
  static const Field<ActivityEntry, String> _f$modId = Field(
    'modId',
    _$modId,
    opt: true,
  );
  static String? _$modVersion(ActivityEntry v) => v.modVersion;
  static const Field<ActivityEntry, String> _f$modVersion = Field(
    'modVersion',
    _$modVersion,
    opt: true,
  );
  static ActivitySourceType _$sourceType(ActivityEntry v) => v.sourceType;
  static const Field<ActivityEntry, ActivitySourceType> _f$sourceType = Field(
    'sourceType',
    _$sourceType,
  );
  static String? _$sourceDetail(ActivityEntry v) => v.sourceDetail;
  static const Field<ActivityEntry, String> _f$sourceDetail = Field(
    'sourceDetail',
    _$sourceDetail,
    opt: true,
  );
  static DateTime _$timestamp(ActivityEntry v) => v.timestamp;
  static const Field<ActivityEntry, DateTime> _f$timestamp = Field(
    'timestamp',
    _$timestamp,
  );
  static ActivityStatus _$status(ActivityEntry v) => v.status;
  static const Field<ActivityEntry, ActivityStatus> _f$status = Field(
    'status',
    _$status,
  );
  static String? _$errorMessage(ActivityEntry v) => v.errorMessage;
  static const Field<ActivityEntry, String> _f$errorMessage = Field(
    'errorMessage',
    _$errorMessage,
    opt: true,
  );
  static String? _$modIconPath(ActivityEntry v) => v.modIconPath;
  static const Field<ActivityEntry, String> _f$modIconPath = Field(
    'modIconPath',
    _$modIconPath,
    opt: true,
  );

  @override
  final MappableFields<ActivityEntry> fields = const {
    #id: _f$id,
    #modName: _f$modName,
    #modId: _f$modId,
    #modVersion: _f$modVersion,
    #sourceType: _f$sourceType,
    #sourceDetail: _f$sourceDetail,
    #timestamp: _f$timestamp,
    #status: _f$status,
    #errorMessage: _f$errorMessage,
    #modIconPath: _f$modIconPath,
  };

  static ActivityEntry _instantiate(DecodingData data) {
    return ActivityEntry(
      id: data.dec(_f$id),
      modName: data.dec(_f$modName),
      modId: data.dec(_f$modId),
      modVersion: data.dec(_f$modVersion),
      sourceType: data.dec(_f$sourceType),
      sourceDetail: data.dec(_f$sourceDetail),
      timestamp: data.dec(_f$timestamp),
      status: data.dec(_f$status),
      errorMessage: data.dec(_f$errorMessage),
      modIconPath: data.dec(_f$modIconPath),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static ActivityEntry fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<ActivityEntry>(map);
  }

  static ActivityEntry fromJson(String json) {
    return ensureInitialized().decodeJson<ActivityEntry>(json);
  }
}

mixin ActivityEntryMappable {
  String toJson() {
    return ActivityEntryMapper.ensureInitialized().encodeJson<ActivityEntry>(
      this as ActivityEntry,
    );
  }

  Map<String, dynamic> toMap() {
    return ActivityEntryMapper.ensureInitialized().encodeMap<ActivityEntry>(
      this as ActivityEntry,
    );
  }

  ActivityEntryCopyWith<ActivityEntry, ActivityEntry, ActivityEntry>
  get copyWith => _ActivityEntryCopyWithImpl<ActivityEntry, ActivityEntry>(
    this as ActivityEntry,
    $identity,
    $identity,
  );
  @override
  String toString() {
    return ActivityEntryMapper.ensureInitialized().stringifyValue(
      this as ActivityEntry,
    );
  }

  @override
  bool operator ==(Object other) {
    return ActivityEntryMapper.ensureInitialized().equalsValue(
      this as ActivityEntry,
      other,
    );
  }

  @override
  int get hashCode {
    return ActivityEntryMapper.ensureInitialized().hashValue(
      this as ActivityEntry,
    );
  }
}

extension ActivityEntryValueCopy<$R, $Out>
    on ObjectCopyWith<$R, ActivityEntry, $Out> {
  ActivityEntryCopyWith<$R, ActivityEntry, $Out> get $asActivityEntry =>
      $base.as((v, t, t2) => _ActivityEntryCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class ActivityEntryCopyWith<$R, $In extends ActivityEntry, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({
    String? id,
    String? modName,
    String? modId,
    String? modVersion,
    ActivitySourceType? sourceType,
    String? sourceDetail,
    DateTime? timestamp,
    ActivityStatus? status,
    String? errorMessage,
    String? modIconPath,
  });
  ActivityEntryCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _ActivityEntryCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, ActivityEntry, $Out>
    implements ActivityEntryCopyWith<$R, ActivityEntry, $Out> {
  _ActivityEntryCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<ActivityEntry> $mapper =
      ActivityEntryMapper.ensureInitialized();
  @override
  $R call({
    String? id,
    String? modName,
    Object? modId = $none,
    Object? modVersion = $none,
    ActivitySourceType? sourceType,
    Object? sourceDetail = $none,
    DateTime? timestamp,
    ActivityStatus? status,
    Object? errorMessage = $none,
    Object? modIconPath = $none,
  }) => $apply(
    FieldCopyWithData({
      if (id != null) #id: id,
      if (modName != null) #modName: modName,
      if (modId != $none) #modId: modId,
      if (modVersion != $none) #modVersion: modVersion,
      if (sourceType != null) #sourceType: sourceType,
      if (sourceDetail != $none) #sourceDetail: sourceDetail,
      if (timestamp != null) #timestamp: timestamp,
      if (status != null) #status: status,
      if (errorMessage != $none) #errorMessage: errorMessage,
      if (modIconPath != $none) #modIconPath: modIconPath,
    }),
  );
  @override
  ActivityEntry $make(CopyWithData data) => ActivityEntry(
    id: data.get(#id, or: $value.id),
    modName: data.get(#modName, or: $value.modName),
    modId: data.get(#modId, or: $value.modId),
    modVersion: data.get(#modVersion, or: $value.modVersion),
    sourceType: data.get(#sourceType, or: $value.sourceType),
    sourceDetail: data.get(#sourceDetail, or: $value.sourceDetail),
    timestamp: data.get(#timestamp, or: $value.timestamp),
    status: data.get(#status, or: $value.status),
    errorMessage: data.get(#errorMessage, or: $value.errorMessage),
    modIconPath: data.get(#modIconPath, or: $value.modIconPath),
  );

  @override
  ActivityEntryCopyWith<$R2, ActivityEntry, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _ActivityEntryCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class ActivityHistoryMapper extends ClassMapperBase<ActivityHistory> {
  ActivityHistoryMapper._();

  static ActivityHistoryMapper? _instance;
  static ActivityHistoryMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ActivityHistoryMapper._());
      ActivityEntryMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'ActivityHistory';

  static List<ActivityEntry> _$entries(ActivityHistory v) => v.entries;
  static const Field<ActivityHistory, List<ActivityEntry>> _f$entries = Field(
    'entries',
    _$entries,
    opt: true,
    def: const [],
  );

  @override
  final MappableFields<ActivityHistory> fields = const {#entries: _f$entries};

  static ActivityHistory _instantiate(DecodingData data) {
    return ActivityHistory(entries: data.dec(_f$entries));
  }

  @override
  final Function instantiate = _instantiate;

  static ActivityHistory fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<ActivityHistory>(map);
  }

  static ActivityHistory fromJson(String json) {
    return ensureInitialized().decodeJson<ActivityHistory>(json);
  }
}

mixin ActivityHistoryMappable {
  String toJson() {
    return ActivityHistoryMapper.ensureInitialized()
        .encodeJson<ActivityHistory>(this as ActivityHistory);
  }

  Map<String, dynamic> toMap() {
    return ActivityHistoryMapper.ensureInitialized().encodeMap<ActivityHistory>(
      this as ActivityHistory,
    );
  }

  ActivityHistoryCopyWith<ActivityHistory, ActivityHistory, ActivityHistory>
  get copyWith =>
      _ActivityHistoryCopyWithImpl<ActivityHistory, ActivityHistory>(
        this as ActivityHistory,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return ActivityHistoryMapper.ensureInitialized().stringifyValue(
      this as ActivityHistory,
    );
  }

  @override
  bool operator ==(Object other) {
    return ActivityHistoryMapper.ensureInitialized().equalsValue(
      this as ActivityHistory,
      other,
    );
  }

  @override
  int get hashCode {
    return ActivityHistoryMapper.ensureInitialized().hashValue(
      this as ActivityHistory,
    );
  }
}

extension ActivityHistoryValueCopy<$R, $Out>
    on ObjectCopyWith<$R, ActivityHistory, $Out> {
  ActivityHistoryCopyWith<$R, ActivityHistory, $Out> get $asActivityHistory =>
      $base.as((v, t, t2) => _ActivityHistoryCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class ActivityHistoryCopyWith<$R, $In extends ActivityHistory, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  ListCopyWith<
    $R,
    ActivityEntry,
    ActivityEntryCopyWith<$R, ActivityEntry, ActivityEntry>
  >
  get entries;
  $R call({List<ActivityEntry>? entries});
  ActivityHistoryCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _ActivityHistoryCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, ActivityHistory, $Out>
    implements ActivityHistoryCopyWith<$R, ActivityHistory, $Out> {
  _ActivityHistoryCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<ActivityHistory> $mapper =
      ActivityHistoryMapper.ensureInitialized();
  @override
  ListCopyWith<
    $R,
    ActivityEntry,
    ActivityEntryCopyWith<$R, ActivityEntry, ActivityEntry>
  >
  get entries => ListCopyWith(
    $value.entries,
    (v, t) => v.copyWith.$chain(t),
    (v) => call(entries: v),
  );
  @override
  $R call({List<ActivityEntry>? entries}) =>
      $apply(FieldCopyWithData({if (entries != null) #entries: entries}));
  @override
  ActivityHistory $make(CopyWithData data) =>
      ActivityHistory(entries: data.get(#entries, or: $value.entries));

  @override
  ActivityHistoryCopyWith<$R2, ActivityHistory, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _ActivityHistoryCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

