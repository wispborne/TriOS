// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'jre_23.dart';

class Jre23VersionCheckerMapper extends ClassMapperBase<Jre23VersionChecker> {
  Jre23VersionCheckerMapper._();

  static Jre23VersionCheckerMapper? _instance;
  static Jre23VersionCheckerMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = Jre23VersionCheckerMapper._());
      VersionMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'Jre23VersionChecker';

  static String _$masterVersionFile(Jre23VersionChecker v) =>
      v.masterVersionFile;
  static const Field<Jre23VersionChecker, String> _f$masterVersionFile =
      Field('masterVersionFile', _$masterVersionFile);
  static String _$modName(Jre23VersionChecker v) => v.modName;
  static const Field<Jre23VersionChecker, String> _f$modName =
      Field('modName', _$modName);
  static int? _$modThreadId(Jre23VersionChecker v) => v.modThreadId;
  static const Field<Jre23VersionChecker, int> _f$modThreadId =
      Field('modThreadId', _$modThreadId, opt: true);
  static Version _$modVersion(Jre23VersionChecker v) => v.modVersion;
  static const Field<Jre23VersionChecker, Version> _f$modVersion =
      Field('modVersion', _$modVersion, hook: VersionHook());
  static String _$starsectorVersion(Jre23VersionChecker v) =>
      v.starsectorVersion;
  static const Field<Jre23VersionChecker, String> _f$starsectorVersion =
      Field('starsectorVersion', _$starsectorVersion);
  static String? _$windowsJDKDownload(Jre23VersionChecker v) =>
      v.windowsJDKDownload;
  static const Field<Jre23VersionChecker, String> _f$windowsJDKDownload =
      Field('windowsJDKDownload', _$windowsJDKDownload, opt: true);
  static String? _$windowsConfigDownload(Jre23VersionChecker v) =>
      v.windowsConfigDownload;
  static const Field<Jre23VersionChecker, String> _f$windowsConfigDownload =
      Field('windowsConfigDownload', _$windowsConfigDownload, opt: true);
  static String? _$linuxJDKDownload(Jre23VersionChecker v) =>
      v.linuxJDKDownload;
  static const Field<Jre23VersionChecker, String> _f$linuxJDKDownload =
      Field('linuxJDKDownload', _$linuxJDKDownload, opt: true);
  static String? _$linuxConfigDownload(Jre23VersionChecker v) =>
      v.linuxConfigDownload;
  static const Field<Jre23VersionChecker, String> _f$linuxConfigDownload =
      Field('linuxConfigDownload', _$linuxConfigDownload, opt: true);

  @override
  final MappableFields<Jre23VersionChecker> fields = const {
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

  static Jre23VersionChecker _instantiate(DecodingData data) {
    return Jre23VersionChecker(
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

  static Jre23VersionChecker fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<Jre23VersionChecker>(map);
  }

  static Jre23VersionChecker fromJson(String json) {
    return ensureInitialized().decodeJson<Jre23VersionChecker>(json);
  }
}

mixin Jre23VersionCheckerMappable {
  String toJson() {
    return Jre23VersionCheckerMapper.ensureInitialized()
        .encodeJson<Jre23VersionChecker>(this as Jre23VersionChecker);
  }

  Map<String, dynamic> toMap() {
    return Jre23VersionCheckerMapper.ensureInitialized()
        .encodeMap<Jre23VersionChecker>(this as Jre23VersionChecker);
  }

  Jre23VersionCheckerCopyWith<Jre23VersionChecker, Jre23VersionChecker,
          Jre23VersionChecker>
      get copyWith => _Jre23VersionCheckerCopyWithImpl(
          this as Jre23VersionChecker, $identity, $identity);
  @override
  String toString() {
    return Jre23VersionCheckerMapper.ensureInitialized()
        .stringifyValue(this as Jre23VersionChecker);
  }

  @override
  bool operator ==(Object other) {
    return Jre23VersionCheckerMapper.ensureInitialized()
        .equalsValue(this as Jre23VersionChecker, other);
  }

  @override
  int get hashCode {
    return Jre23VersionCheckerMapper.ensureInitialized()
        .hashValue(this as Jre23VersionChecker);
  }
}

extension Jre23VersionCheckerValueCopy<$R, $Out>
    on ObjectCopyWith<$R, Jre23VersionChecker, $Out> {
  Jre23VersionCheckerCopyWith<$R, Jre23VersionChecker, $Out>
      get $asJre23VersionChecker =>
          $base.as((v, t, t2) => _Jre23VersionCheckerCopyWithImpl(v, t, t2));
}

abstract class Jre23VersionCheckerCopyWith<$R, $In extends Jre23VersionChecker,
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
  Jre23VersionCheckerCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
      Then<$Out2, $R2> t);
}

class _Jre23VersionCheckerCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, Jre23VersionChecker, $Out>
    implements Jre23VersionCheckerCopyWith<$R, Jre23VersionChecker, $Out> {
  _Jre23VersionCheckerCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<Jre23VersionChecker> $mapper =
      Jre23VersionCheckerMapper.ensureInitialized();
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
  Jre23VersionChecker $make(CopyWithData data) => Jre23VersionChecker(
      masterVersionFile:
          data.get(#masterVersionFile, or: $value.masterVersionFile),
      modName: data.get(#modName, or: $value.modName),
      modThreadId: data.get(#modThreadId, or: $value.modThreadId),
      modVersion: data.get(#modVersion, or: $value.modVersion),
      starsectorVersion:
          data.get(#starsectorVersion, or: $value.starsectorVersion),
      windowsJDKDownload:
          data.get(#windowsJDKDownload, or: $value.windowsJDKDownload),
      windowsConfigDownload:
          data.get(#windowsConfigDownload, or: $value.windowsConfigDownload),
      linuxJDKDownload:
          data.get(#linuxJDKDownload, or: $value.linuxJDKDownload),
      linuxConfigDownload:
          data.get(#linuxConfigDownload, or: $value.linuxConfigDownload));

  @override
  Jre23VersionCheckerCopyWith<$R2, Jre23VersionChecker, $Out2>
      $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
          _Jre23VersionCheckerCopyWithImpl($value, $cast, t);
}
