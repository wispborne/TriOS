// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'logging.dart';

class LoggingSettingsMapper extends ClassMapperBase<LoggingSettings> {
  LoggingSettingsMapper._();

  static LoggingSettingsMapper? _instance;
  static LoggingSettingsMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = LoggingSettingsMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'LoggingSettings';

  static bool _$printPlatformInfo(LoggingSettings v) => v.printPlatformInfo;
  static const Field<LoggingSettings, bool> _f$printPlatformInfo = Field(
    'printPlatformInfo',
    _$printPlatformInfo,
    opt: true,
    def: false,
  );
  static bool _$allowSentryReporting(LoggingSettings v) =>
      v.allowSentryReporting;
  static const Field<LoggingSettings, bool> _f$allowSentryReporting = Field(
    'allowSentryReporting',
    _$allowSentryReporting,
    opt: true,
    def: false,
  );
  static bool _$consoleOnly(LoggingSettings v) => v.consoleOnly;
  static const Field<LoggingSettings, bool> _f$consoleOnly = Field(
    'consoleOnly',
    _$consoleOnly,
    opt: true,
    def: false,
  );
  static bool _$shouldDebugRiverpod(LoggingSettings v) => v.shouldDebugRiverpod;
  static const Field<LoggingSettings, bool> _f$shouldDebugRiverpod = Field(
    'shouldDebugRiverpod',
    _$shouldDebugRiverpod,
    opt: true,
    def: false,
  );
  static Level _$consoleLoggingLevel(LoggingSettings v) =>
      v.consoleLoggingLevel;
  static const Field<LoggingSettings, Level> _f$consoleLoggingLevel = Field(
    'consoleLoggingLevel',
    _$consoleLoggingLevel,
    opt: true,
    def: kDebugMode ? Level.debug : Level.error,
  );
  static Level _$fileLoggingLevel(LoggingSettings v) => v.fileLoggingLevel;
  static const Field<LoggingSettings, Level> _f$fileLoggingLevel = Field(
    'fileLoggingLevel',
    _$fileLoggingLevel,
    opt: true,
    def: Level.info,
  );

  @override
  final MappableFields<LoggingSettings> fields = const {
    #printPlatformInfo: _f$printPlatformInfo,
    #allowSentryReporting: _f$allowSentryReporting,
    #consoleOnly: _f$consoleOnly,
    #shouldDebugRiverpod: _f$shouldDebugRiverpod,
    #consoleLoggingLevel: _f$consoleLoggingLevel,
    #fileLoggingLevel: _f$fileLoggingLevel,
  };

  static LoggingSettings _instantiate(DecodingData data) {
    return LoggingSettings(
      printPlatformInfo: data.dec(_f$printPlatformInfo),
      allowSentryReporting: data.dec(_f$allowSentryReporting),
      consoleOnly: data.dec(_f$consoleOnly),
      shouldDebugRiverpod: data.dec(_f$shouldDebugRiverpod),
      consoleLoggingLevel: data.dec(_f$consoleLoggingLevel),
      fileLoggingLevel: data.dec(_f$fileLoggingLevel),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static LoggingSettings fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<LoggingSettings>(map);
  }

  static LoggingSettings fromJson(String json) {
    return ensureInitialized().decodeJson<LoggingSettings>(json);
  }
}

mixin LoggingSettingsMappable {
  String toJson() {
    return LoggingSettingsMapper.ensureInitialized()
        .encodeJson<LoggingSettings>(this as LoggingSettings);
  }

  Map<String, dynamic> toMap() {
    return LoggingSettingsMapper.ensureInitialized().encodeMap<LoggingSettings>(
      this as LoggingSettings,
    );
  }

  LoggingSettingsCopyWith<LoggingSettings, LoggingSettings, LoggingSettings>
  get copyWith =>
      _LoggingSettingsCopyWithImpl<LoggingSettings, LoggingSettings>(
        this as LoggingSettings,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return LoggingSettingsMapper.ensureInitialized().stringifyValue(
      this as LoggingSettings,
    );
  }

  @override
  bool operator ==(Object other) {
    return LoggingSettingsMapper.ensureInitialized().equalsValue(
      this as LoggingSettings,
      other,
    );
  }

  @override
  int get hashCode {
    return LoggingSettingsMapper.ensureInitialized().hashValue(
      this as LoggingSettings,
    );
  }
}

extension LoggingSettingsValueCopy<$R, $Out>
    on ObjectCopyWith<$R, LoggingSettings, $Out> {
  LoggingSettingsCopyWith<$R, LoggingSettings, $Out> get $asLoggingSettings =>
      $base.as((v, t, t2) => _LoggingSettingsCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class LoggingSettingsCopyWith<$R, $In extends LoggingSettings, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({
    bool? printPlatformInfo,
    bool? allowSentryReporting,
    bool? consoleOnly,
    bool? shouldDebugRiverpod,
    Level? consoleLoggingLevel,
    Level? fileLoggingLevel,
  });
  LoggingSettingsCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _LoggingSettingsCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, LoggingSettings, $Out>
    implements LoggingSettingsCopyWith<$R, LoggingSettings, $Out> {
  _LoggingSettingsCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<LoggingSettings> $mapper =
      LoggingSettingsMapper.ensureInitialized();
  @override
  $R call({
    bool? printPlatformInfo,
    bool? allowSentryReporting,
    bool? consoleOnly,
    bool? shouldDebugRiverpod,
    Level? consoleLoggingLevel,
    Level? fileLoggingLevel,
  }) => $apply(
    FieldCopyWithData({
      if (printPlatformInfo != null) #printPlatformInfo: printPlatformInfo,
      if (allowSentryReporting != null)
        #allowSentryReporting: allowSentryReporting,
      if (consoleOnly != null) #consoleOnly: consoleOnly,
      if (shouldDebugRiverpod != null)
        #shouldDebugRiverpod: shouldDebugRiverpod,
      if (consoleLoggingLevel != null)
        #consoleLoggingLevel: consoleLoggingLevel,
      if (fileLoggingLevel != null) #fileLoggingLevel: fileLoggingLevel,
    }),
  );
  @override
  LoggingSettings $make(CopyWithData data) => LoggingSettings(
    printPlatformInfo: data.get(
      #printPlatformInfo,
      or: $value.printPlatformInfo,
    ),
    allowSentryReporting: data.get(
      #allowSentryReporting,
      or: $value.allowSentryReporting,
    ),
    consoleOnly: data.get(#consoleOnly, or: $value.consoleOnly),
    shouldDebugRiverpod: data.get(
      #shouldDebugRiverpod,
      or: $value.shouldDebugRiverpod,
    ),
    consoleLoggingLevel: data.get(
      #consoleLoggingLevel,
      or: $value.consoleLoggingLevel,
    ),
    fileLoggingLevel: data.get(#fileLoggingLevel, or: $value.fileLoggingLevel),
  );

  @override
  LoggingSettingsCopyWith<$R2, LoggingSettings, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _LoggingSettingsCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

