// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'jre_entry.dart';

class JreVersionMapper extends ClassMapperBase<JreVersion> {
  JreVersionMapper._();

  static JreVersionMapper? _instance;
  static JreVersionMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = JreVersionMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'JreVersion';

  static String _$versionString(JreVersion v) => v.versionString;
  static const Field<JreVersion, String> _f$versionString =
      Field('versionString', _$versionString);

  @override
  final MappableFields<JreVersion> fields = const {
    #versionString: _f$versionString,
  };

  static JreVersion _instantiate(DecodingData data) {
    return JreVersion(data.dec(_f$versionString));
  }

  @override
  final Function instantiate = _instantiate;

  static JreVersion fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<JreVersion>(map);
  }

  static JreVersion fromJson(String json) {
    return ensureInitialized().decodeJson<JreVersion>(json);
  }
}

mixin JreVersionMappable {
  String toJson() {
    return JreVersionMapper.ensureInitialized()
        .encodeJson<JreVersion>(this as JreVersion);
  }

  Map<String, dynamic> toMap() {
    return JreVersionMapper.ensureInitialized()
        .encodeMap<JreVersion>(this as JreVersion);
  }

  JreVersionCopyWith<JreVersion, JreVersion, JreVersion> get copyWith =>
      _JreVersionCopyWithImpl(this as JreVersion, $identity, $identity);
  @override
  String toString() {
    return JreVersionMapper.ensureInitialized()
        .stringifyValue(this as JreVersion);
  }

  @override
  bool operator ==(Object other) {
    return JreVersionMapper.ensureInitialized()
        .equalsValue(this as JreVersion, other);
  }

  @override
  int get hashCode {
    return JreVersionMapper.ensureInitialized().hashValue(this as JreVersion);
  }
}

extension JreVersionValueCopy<$R, $Out>
    on ObjectCopyWith<$R, JreVersion, $Out> {
  JreVersionCopyWith<$R, JreVersion, $Out> get $asJreVersion =>
      $base.as((v, t, t2) => _JreVersionCopyWithImpl(v, t, t2));
}

abstract class JreVersionCopyWith<$R, $In extends JreVersion, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({String? versionString});
  JreVersionCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _JreVersionCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, JreVersion, $Out>
    implements JreVersionCopyWith<$R, JreVersion, $Out> {
  _JreVersionCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<JreVersion> $mapper =
      JreVersionMapper.ensureInitialized();
  @override
  $R call({String? versionString}) => $apply(FieldCopyWithData(
      {if (versionString != null) #versionString: versionString}));
  @override
  JreVersion $make(CopyWithData data) =>
      JreVersion(data.get(#versionString, or: $value.versionString));

  @override
  JreVersionCopyWith<$R2, JreVersion, $Out2> $chain<$R2, $Out2>(
          Then<$Out2, $R2> t) =>
      _JreVersionCopyWithImpl($value, $cast, t);
}

class CustomJreDownloadStateMapper
    extends ClassMapperBase<CustomJreDownloadState> {
  CustomJreDownloadStateMapper._();

  static CustomJreDownloadStateMapper? _instance;
  static CustomJreDownloadStateMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = CustomJreDownloadStateMapper._());
      TriOSDownloadProgressMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'CustomJreDownloadState';

  static TriOSDownloadProgress? _$downloadProgress(CustomJreDownloadState v) =>
      v.downloadProgress;
  static const Field<CustomJreDownloadState, TriOSDownloadProgress>
      _f$downloadProgress =
      Field('downloadProgress', _$downloadProgress, opt: true);
  static String? _$errorMessage(CustomJreDownloadState v) => v.errorMessage;
  static const Field<CustomJreDownloadState, String> _f$errorMessage =
      Field('errorMessage', _$errorMessage, opt: true);
  static bool _$isInstalling(CustomJreDownloadState v) => v.isInstalling;
  static const Field<CustomJreDownloadState, bool> _f$isInstalling =
      Field('isInstalling', _$isInstalling, opt: true, def: false);

  @override
  final MappableFields<CustomJreDownloadState> fields = const {
    #downloadProgress: _f$downloadProgress,
    #errorMessage: _f$errorMessage,
    #isInstalling: _f$isInstalling,
  };

  static CustomJreDownloadState _instantiate(DecodingData data) {
    return CustomJreDownloadState(
        downloadProgress: data.dec(_f$downloadProgress),
        errorMessage: data.dec(_f$errorMessage),
        isInstalling: data.dec(_f$isInstalling));
  }

  @override
  final Function instantiate = _instantiate;

  static CustomJreDownloadState fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<CustomJreDownloadState>(map);
  }

  static CustomJreDownloadState fromJson(String json) {
    return ensureInitialized().decodeJson<CustomJreDownloadState>(json);
  }
}

mixin CustomJreDownloadStateMappable {
  String toJson() {
    return CustomJreDownloadStateMapper.ensureInitialized()
        .encodeJson<CustomJreDownloadState>(this as CustomJreDownloadState);
  }

  Map<String, dynamic> toMap() {
    return CustomJreDownloadStateMapper.ensureInitialized()
        .encodeMap<CustomJreDownloadState>(this as CustomJreDownloadState);
  }

  CustomJreDownloadStateCopyWith<CustomJreDownloadState, CustomJreDownloadState,
          CustomJreDownloadState>
      get copyWith => _CustomJreDownloadStateCopyWithImpl(
          this as CustomJreDownloadState, $identity, $identity);
  @override
  String toString() {
    return CustomJreDownloadStateMapper.ensureInitialized()
        .stringifyValue(this as CustomJreDownloadState);
  }

  @override
  bool operator ==(Object other) {
    return CustomJreDownloadStateMapper.ensureInitialized()
        .equalsValue(this as CustomJreDownloadState, other);
  }

  @override
  int get hashCode {
    return CustomJreDownloadStateMapper.ensureInitialized()
        .hashValue(this as CustomJreDownloadState);
  }
}

extension CustomJreDownloadStateValueCopy<$R, $Out>
    on ObjectCopyWith<$R, CustomJreDownloadState, $Out> {
  CustomJreDownloadStateCopyWith<$R, CustomJreDownloadState, $Out>
      get $asCustomJreDownloadState =>
          $base.as((v, t, t2) => _CustomJreDownloadStateCopyWithImpl(v, t, t2));
}

abstract class CustomJreDownloadStateCopyWith<
    $R,
    $In extends CustomJreDownloadState,
    $Out> implements ClassCopyWith<$R, $In, $Out> {
  TriOSDownloadProgressCopyWith<$R, TriOSDownloadProgress,
      TriOSDownloadProgress>? get downloadProgress;
  $R call(
      {TriOSDownloadProgress? downloadProgress,
      String? errorMessage,
      bool? isInstalling});
  CustomJreDownloadStateCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
      Then<$Out2, $R2> t);
}

class _CustomJreDownloadStateCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, CustomJreDownloadState, $Out>
    implements
        CustomJreDownloadStateCopyWith<$R, CustomJreDownloadState, $Out> {
  _CustomJreDownloadStateCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<CustomJreDownloadState> $mapper =
      CustomJreDownloadStateMapper.ensureInitialized();
  @override
  TriOSDownloadProgressCopyWith<$R, TriOSDownloadProgress,
          TriOSDownloadProgress>?
      get downloadProgress => $value.downloadProgress?.copyWith
          .$chain((v) => call(downloadProgress: v));
  @override
  $R call(
          {Object? downloadProgress = $none,
          Object? errorMessage = $none,
          bool? isInstalling}) =>
      $apply(FieldCopyWithData({
        if (downloadProgress != $none) #downloadProgress: downloadProgress,
        if (errorMessage != $none) #errorMessage: errorMessage,
        if (isInstalling != null) #isInstalling: isInstalling
      }));
  @override
  CustomJreDownloadState $make(CopyWithData data) => CustomJreDownloadState(
      downloadProgress:
          data.get(#downloadProgress, or: $value.downloadProgress),
      errorMessage: data.get(#errorMessage, or: $value.errorMessage),
      isInstalling: data.get(#isInstalling, or: $value.isInstalling));

  @override
  CustomJreDownloadStateCopyWith<$R2, CustomJreDownloadState, $Out2>
      $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
          _CustomJreDownloadStateCopyWithImpl($value, $cast, t);
}

class CustomJreVersionCheckerFileMapper
    extends ClassMapperBase<CustomJreVersionCheckerFile> {
  CustomJreVersionCheckerFileMapper._();

  static CustomJreVersionCheckerFileMapper? _instance;
  static CustomJreVersionCheckerFileMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals
          .use(_instance = CustomJreVersionCheckerFileMapper._());
      VersionMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'CustomJreVersionCheckerFile';

  static String _$masterVersionFile(CustomJreVersionCheckerFile v) =>
      v.masterVersionFile;
  static const Field<CustomJreVersionCheckerFile, String> _f$masterVersionFile =
      Field('masterVersionFile', _$masterVersionFile);
  static String _$modName(CustomJreVersionCheckerFile v) => v.modName;
  static const Field<CustomJreVersionCheckerFile, String> _f$modName =
      Field('modName', _$modName);
  static int? _$modThreadId(CustomJreVersionCheckerFile v) => v.modThreadId;
  static const Field<CustomJreVersionCheckerFile, int> _f$modThreadId =
      Field('modThreadId', _$modThreadId, opt: true);
  static Version _$modVersion(CustomJreVersionCheckerFile v) => v.modVersion;
  static const Field<CustomJreVersionCheckerFile, Version> _f$modVersion =
      Field('modVersion', _$modVersion, hook: VersionHook());
  static String _$starsectorVersion(CustomJreVersionCheckerFile v) =>
      v.starsectorVersion;
  static const Field<CustomJreVersionCheckerFile, String> _f$starsectorVersion =
      Field('starsectorVersion', _$starsectorVersion);
  static String? _$windowsJDKDownload(CustomJreVersionCheckerFile v) =>
      v.windowsJDKDownload;
  static const Field<CustomJreVersionCheckerFile, String>
      _f$windowsJDKDownload =
      Field('windowsJDKDownload', _$windowsJDKDownload, opt: true);
  static String? _$windowsConfigDownload(CustomJreVersionCheckerFile v) =>
      v.windowsConfigDownload;
  static const Field<CustomJreVersionCheckerFile, String>
      _f$windowsConfigDownload =
      Field('windowsConfigDownload', _$windowsConfigDownload, opt: true);
  static String? _$linuxJDKDownload(CustomJreVersionCheckerFile v) =>
      v.linuxJDKDownload;
  static const Field<CustomJreVersionCheckerFile, String> _f$linuxJDKDownload =
      Field('linuxJDKDownload', _$linuxJDKDownload, opt: true);
  static String? _$linuxConfigDownload(CustomJreVersionCheckerFile v) =>
      v.linuxConfigDownload;
  static const Field<CustomJreVersionCheckerFile, String>
      _f$linuxConfigDownload =
      Field('linuxConfigDownload', _$linuxConfigDownload, opt: true);

  @override
  final MappableFields<CustomJreVersionCheckerFile> fields = const {
    #masterVersionFile: _f$masterVersionFile,
    #modName: _f$modName,
    #modThreadId: _f$modThreadId,
    #modVersion: _f$modVersion,
    #starsectorVersion: _f$starsectorVersion,
    #windowsJDKDownload: _f$windowsJDKDownload,
    #windowsConfigDownload: _f$windowsConfigDownload,
    #linuxJDKDownload: _f$linuxJDKDownload,
    #linuxConfigDownload: _f$linuxConfigDownload,
  };

  static CustomJreVersionCheckerFile _instantiate(DecodingData data) {
    return CustomJreVersionCheckerFile(
        masterVersionFile: data.dec(_f$masterVersionFile),
        modName: data.dec(_f$modName),
        modThreadId: data.dec(_f$modThreadId),
        modVersion: data.dec(_f$modVersion),
        starsectorVersion: data.dec(_f$starsectorVersion),
        windowsJDKDownload: data.dec(_f$windowsJDKDownload),
        windowsConfigDownload: data.dec(_f$windowsConfigDownload),
        linuxJDKDownload: data.dec(_f$linuxJDKDownload),
        linuxConfigDownload: data.dec(_f$linuxConfigDownload));
  }

  @override
  final Function instantiate = _instantiate;

  static CustomJreVersionCheckerFile fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<CustomJreVersionCheckerFile>(map);
  }

  static CustomJreVersionCheckerFile fromJson(String json) {
    return ensureInitialized().decodeJson<CustomJreVersionCheckerFile>(json);
  }
}

mixin CustomJreVersionCheckerFileMappable {
  String toJson() {
    return CustomJreVersionCheckerFileMapper.ensureInitialized()
        .encodeJson<CustomJreVersionCheckerFile>(
            this as CustomJreVersionCheckerFile);
  }

  Map<String, dynamic> toMap() {
    return CustomJreVersionCheckerFileMapper.ensureInitialized()
        .encodeMap<CustomJreVersionCheckerFile>(
            this as CustomJreVersionCheckerFile);
  }

  CustomJreVersionCheckerFileCopyWith<CustomJreVersionCheckerFile,
          CustomJreVersionCheckerFile, CustomJreVersionCheckerFile>
      get copyWith => _CustomJreVersionCheckerFileCopyWithImpl(
          this as CustomJreVersionCheckerFile, $identity, $identity);
  @override
  String toString() {
    return CustomJreVersionCheckerFileMapper.ensureInitialized()
        .stringifyValue(this as CustomJreVersionCheckerFile);
  }

  @override
  bool operator ==(Object other) {
    return CustomJreVersionCheckerFileMapper.ensureInitialized()
        .equalsValue(this as CustomJreVersionCheckerFile, other);
  }

  @override
  int get hashCode {
    return CustomJreVersionCheckerFileMapper.ensureInitialized()
        .hashValue(this as CustomJreVersionCheckerFile);
  }
}

extension CustomJreVersionCheckerFileValueCopy<$R, $Out>
    on ObjectCopyWith<$R, CustomJreVersionCheckerFile, $Out> {
  CustomJreVersionCheckerFileCopyWith<$R, CustomJreVersionCheckerFile, $Out>
      get $asCustomJreVersionCheckerFile => $base
          .as((v, t, t2) => _CustomJreVersionCheckerFileCopyWithImpl(v, t, t2));
}

abstract class CustomJreVersionCheckerFileCopyWith<
    $R,
    $In extends CustomJreVersionCheckerFile,
    $Out> implements ClassCopyWith<$R, $In, $Out> {
  VersionCopyWith<$R, Version, Version> get modVersion;
  $R call(
      {String? masterVersionFile,
      String? modName,
      int? modThreadId,
      Version? modVersion,
      String? starsectorVersion,
      String? windowsJDKDownload,
      String? windowsConfigDownload,
      String? linuxJDKDownload,
      String? linuxConfigDownload});
  CustomJreVersionCheckerFileCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
      Then<$Out2, $R2> t);
}

class _CustomJreVersionCheckerFileCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, CustomJreVersionCheckerFile, $Out>
    implements
        CustomJreVersionCheckerFileCopyWith<$R, CustomJreVersionCheckerFile,
            $Out> {
  _CustomJreVersionCheckerFileCopyWithImpl(
      super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<CustomJreVersionCheckerFile> $mapper =
      CustomJreVersionCheckerFileMapper.ensureInitialized();
  @override
  VersionCopyWith<$R, Version, Version> get modVersion =>
      $value.modVersion.copyWith.$chain((v) => call(modVersion: v));
  @override
  $R call(
          {String? masterVersionFile,
          String? modName,
          Object? modThreadId = $none,
          Version? modVersion,
          String? starsectorVersion,
          Object? windowsJDKDownload = $none,
          Object? windowsConfigDownload = $none,
          Object? linuxJDKDownload = $none,
          Object? linuxConfigDownload = $none}) =>
      $apply(FieldCopyWithData({
        if (masterVersionFile != null) #masterVersionFile: masterVersionFile,
        if (modName != null) #modName: modName,
        if (modThreadId != $none) #modThreadId: modThreadId,
        if (modVersion != null) #modVersion: modVersion,
        if (starsectorVersion != null) #starsectorVersion: starsectorVersion,
        if (windowsJDKDownload != $none)
          #windowsJDKDownload: windowsJDKDownload,
        if (windowsConfigDownload != $none)
          #windowsConfigDownload: windowsConfigDownload,
        if (linuxJDKDownload != $none) #linuxJDKDownload: linuxJDKDownload,
        if (linuxConfigDownload != $none)
          #linuxConfigDownload: linuxConfigDownload
      }));
  @override
  CustomJreVersionCheckerFile $make(CopyWithData data) =>
      CustomJreVersionCheckerFile(
          masterVersionFile:
              data.get(#masterVersionFile, or: $value.masterVersionFile),
          modName: data.get(#modName, or: $value.modName),
          modThreadId: data.get(#modThreadId, or: $value.modThreadId),
          modVersion: data.get(#modVersion, or: $value.modVersion),
          starsectorVersion:
              data.get(#starsectorVersion, or: $value.starsectorVersion),
          windowsJDKDownload:
              data.get(#windowsJDKDownload, or: $value.windowsJDKDownload),
          windowsConfigDownload: data.get(#windowsConfigDownload,
              or: $value.windowsConfigDownload),
          linuxJDKDownload:
              data.get(#linuxJDKDownload, or: $value.linuxJDKDownload),
          linuxConfigDownload:
              data.get(#linuxConfigDownload, or: $value.linuxConfigDownload));

  @override
  CustomJreVersionCheckerFileCopyWith<$R2, CustomJreVersionCheckerFile, $Out2>
      $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
          _CustomJreVersionCheckerFileCopyWithImpl($value, $cast, t);
}
