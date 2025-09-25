// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'version_checker.dart';

class RemoteVersionCheckResultMapper
    extends ClassMapperBase<RemoteVersionCheckResult> {
  RemoteVersionCheckResultMapper._();

  static RemoteVersionCheckResultMapper? _instance;
  static RemoteVersionCheckResultMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(
        _instance = RemoteVersionCheckResultMapper._(),
      );
      VersionCheckerInfoMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'RemoteVersionCheckResult';

  static VersionCheckerInfo? _$remoteVersion(RemoteVersionCheckResult v) =>
      v.remoteVersion;
  static const Field<RemoteVersionCheckResult, VersionCheckerInfo>
  _f$remoteVersion = Field('remoteVersion', _$remoteVersion);
  static String? _$uri(RemoteVersionCheckResult v) => v.uri;
  static const Field<RemoteVersionCheckResult, String> _f$uri = Field(
    'uri',
    _$uri,
  );
  static DateTime _$timestamp(RemoteVersionCheckResult v) => v.timestamp;
  static const Field<RemoteVersionCheckResult, DateTime> _f$timestamp = Field(
    'timestamp',
    _$timestamp,
    opt: true,
  );
  static String? _$smolId(RemoteVersionCheckResult v) => v.smolId;
  static const Field<RemoteVersionCheckResult, String> _f$smolId = Field(
    'smolId',
    _$smolId,
    mode: FieldMode.member,
  );
  static Object? _$error(RemoteVersionCheckResult v) => v.error;
  static const Field<RemoteVersionCheckResult, Object> _f$error = Field(
    'error',
    _$error,
    mode: FieldMode.member,
  );

  @override
  final MappableFields<RemoteVersionCheckResult> fields = const {
    #remoteVersion: _f$remoteVersion,
    #uri: _f$uri,
    #timestamp: _f$timestamp,
    #smolId: _f$smolId,
    #error: _f$error,
  };

  static RemoteVersionCheckResult _instantiate(DecodingData data) {
    return RemoteVersionCheckResult(
      data.dec(_f$remoteVersion),
      data.dec(_f$uri),
      timestamp: data.dec(_f$timestamp),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static RemoteVersionCheckResult fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<RemoteVersionCheckResult>(map);
  }

  static RemoteVersionCheckResult fromJson(String json) {
    return ensureInitialized().decodeJson<RemoteVersionCheckResult>(json);
  }
}

mixin RemoteVersionCheckResultMappable {
  String toJson() {
    return RemoteVersionCheckResultMapper.ensureInitialized()
        .encodeJson<RemoteVersionCheckResult>(this as RemoteVersionCheckResult);
  }

  Map<String, dynamic> toMap() {
    return RemoteVersionCheckResultMapper.ensureInitialized()
        .encodeMap<RemoteVersionCheckResult>(this as RemoteVersionCheckResult);
  }

  RemoteVersionCheckResultCopyWith<
    RemoteVersionCheckResult,
    RemoteVersionCheckResult,
    RemoteVersionCheckResult
  >
  get copyWith =>
      _RemoteVersionCheckResultCopyWithImpl<
        RemoteVersionCheckResult,
        RemoteVersionCheckResult
      >(this as RemoteVersionCheckResult, $identity, $identity);
  @override
  String toString() {
    return RemoteVersionCheckResultMapper.ensureInitialized().stringifyValue(
      this as RemoteVersionCheckResult,
    );
  }

  @override
  bool operator ==(Object other) {
    return RemoteVersionCheckResultMapper.ensureInitialized().equalsValue(
      this as RemoteVersionCheckResult,
      other,
    );
  }

  @override
  int get hashCode {
    return RemoteVersionCheckResultMapper.ensureInitialized().hashValue(
      this as RemoteVersionCheckResult,
    );
  }
}

extension RemoteVersionCheckResultValueCopy<$R, $Out>
    on ObjectCopyWith<$R, RemoteVersionCheckResult, $Out> {
  RemoteVersionCheckResultCopyWith<$R, RemoteVersionCheckResult, $Out>
  get $asRemoteVersionCheckResult => $base.as(
    (v, t, t2) => _RemoteVersionCheckResultCopyWithImpl<$R, $Out>(v, t, t2),
  );
}

abstract class RemoteVersionCheckResultCopyWith<
  $R,
  $In extends RemoteVersionCheckResult,
  $Out
>
    implements ClassCopyWith<$R, $In, $Out> {
  VersionCheckerInfoCopyWith<$R, VersionCheckerInfo, VersionCheckerInfo>?
  get remoteVersion;
  $R call({
    VersionCheckerInfo? remoteVersion,
    String? uri,
    DateTime? timestamp,
  });
  RemoteVersionCheckResultCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _RemoteVersionCheckResultCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, RemoteVersionCheckResult, $Out>
    implements
        RemoteVersionCheckResultCopyWith<$R, RemoteVersionCheckResult, $Out> {
  _RemoteVersionCheckResultCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<RemoteVersionCheckResult> $mapper =
      RemoteVersionCheckResultMapper.ensureInitialized();
  @override
  VersionCheckerInfoCopyWith<$R, VersionCheckerInfo, VersionCheckerInfo>?
  get remoteVersion =>
      $value.remoteVersion?.copyWith.$chain((v) => call(remoteVersion: v));
  @override
  $R call({
    Object? remoteVersion = $none,
    Object? uri = $none,
    Object? timestamp = $none,
  }) => $apply(
    FieldCopyWithData({
      if (remoteVersion != $none) #remoteVersion: remoteVersion,
      if (uri != $none) #uri: uri,
      if (timestamp != $none) #timestamp: timestamp,
    }),
  );
  @override
  RemoteVersionCheckResult $make(CopyWithData data) => RemoteVersionCheckResult(
    data.get(#remoteVersion, or: $value.remoteVersion),
    data.get(#uri, or: $value.uri),
    timestamp: data.get(#timestamp, or: $value.timestamp),
  );

  @override
  RemoteVersionCheckResultCopyWith<$R2, RemoteVersionCheckResult, $Out2>
  $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _RemoteVersionCheckResultCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class VersionCheckerStateMapper extends ClassMapperBase<VersionCheckerState> {
  VersionCheckerStateMapper._();

  static VersionCheckerStateMapper? _instance;
  static VersionCheckerStateMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = VersionCheckerStateMapper._());
      RemoteVersionCheckResultMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'VersionCheckerState';

  static Map<String, RemoteVersionCheckResult> _$versionCheckResultsBySmolId(
    VersionCheckerState v,
  ) => v.versionCheckResultsBySmolId;
  static const Field<VersionCheckerState, Map<String, RemoteVersionCheckResult>>
  _f$versionCheckResultsBySmolId = Field(
    'versionCheckResultsBySmolId',
    _$versionCheckResultsBySmolId,
  );

  @override
  final MappableFields<VersionCheckerState> fields = const {
    #versionCheckResultsBySmolId: _f$versionCheckResultsBySmolId,
  };

  static VersionCheckerState _instantiate(DecodingData data) {
    return VersionCheckerState(data.dec(_f$versionCheckResultsBySmolId));
  }

  @override
  final Function instantiate = _instantiate;

  static VersionCheckerState fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<VersionCheckerState>(map);
  }

  static VersionCheckerState fromJson(String json) {
    return ensureInitialized().decodeJson<VersionCheckerState>(json);
  }
}

mixin VersionCheckerStateMappable {
  String toJson() {
    return VersionCheckerStateMapper.ensureInitialized()
        .encodeJson<VersionCheckerState>(this as VersionCheckerState);
  }

  Map<String, dynamic> toMap() {
    return VersionCheckerStateMapper.ensureInitialized()
        .encodeMap<VersionCheckerState>(this as VersionCheckerState);
  }

  VersionCheckerStateCopyWith<
    VersionCheckerState,
    VersionCheckerState,
    VersionCheckerState
  >
  get copyWith =>
      _VersionCheckerStateCopyWithImpl<
        VersionCheckerState,
        VersionCheckerState
      >(this as VersionCheckerState, $identity, $identity);
  @override
  String toString() {
    return VersionCheckerStateMapper.ensureInitialized().stringifyValue(
      this as VersionCheckerState,
    );
  }

  @override
  bool operator ==(Object other) {
    return VersionCheckerStateMapper.ensureInitialized().equalsValue(
      this as VersionCheckerState,
      other,
    );
  }

  @override
  int get hashCode {
    return VersionCheckerStateMapper.ensureInitialized().hashValue(
      this as VersionCheckerState,
    );
  }
}

extension VersionCheckerStateValueCopy<$R, $Out>
    on ObjectCopyWith<$R, VersionCheckerState, $Out> {
  VersionCheckerStateCopyWith<$R, VersionCheckerState, $Out>
  get $asVersionCheckerState => $base.as(
    (v, t, t2) => _VersionCheckerStateCopyWithImpl<$R, $Out>(v, t, t2),
  );
}

abstract class VersionCheckerStateCopyWith<
  $R,
  $In extends VersionCheckerState,
  $Out
>
    implements ClassCopyWith<$R, $In, $Out> {
  MapCopyWith<
    $R,
    String,
    RemoteVersionCheckResult,
    RemoteVersionCheckResultCopyWith<
      $R,
      RemoteVersionCheckResult,
      RemoteVersionCheckResult
    >
  >
  get versionCheckResultsBySmolId;
  $R call({Map<String, RemoteVersionCheckResult>? versionCheckResultsBySmolId});
  VersionCheckerStateCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _VersionCheckerStateCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, VersionCheckerState, $Out>
    implements VersionCheckerStateCopyWith<$R, VersionCheckerState, $Out> {
  _VersionCheckerStateCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<VersionCheckerState> $mapper =
      VersionCheckerStateMapper.ensureInitialized();
  @override
  MapCopyWith<
    $R,
    String,
    RemoteVersionCheckResult,
    RemoteVersionCheckResultCopyWith<
      $R,
      RemoteVersionCheckResult,
      RemoteVersionCheckResult
    >
  >
  get versionCheckResultsBySmolId => MapCopyWith(
    $value.versionCheckResultsBySmolId,
    (v, t) => v.copyWith.$chain(t),
    (v) => call(versionCheckResultsBySmolId: v),
  );
  @override
  $R call({
    Map<String, RemoteVersionCheckResult>? versionCheckResultsBySmolId,
  }) => $apply(
    FieldCopyWithData({
      if (versionCheckResultsBySmolId != null)
        #versionCheckResultsBySmolId: versionCheckResultsBySmolId,
    }),
  );
  @override
  VersionCheckerState $make(CopyWithData data) => VersionCheckerState(
    data.get(
      #versionCheckResultsBySmolId,
      or: $value.versionCheckResultsBySmolId,
    ),
  );

  @override
  VersionCheckerStateCopyWith<$R2, VersionCheckerState, $Out2>
  $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _VersionCheckerStateCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

