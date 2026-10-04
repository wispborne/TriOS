// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'archived_save.dart';

class ArchivedSaveMapper extends ClassMapperBase<ArchivedSave> {
  ArchivedSaveMapper._();

  static ArchivedSaveMapper? _instance;
  static ArchivedSaveMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ArchivedSaveMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'ArchivedSave';

  static String _$saveFolderName(ArchivedSave v) => v.saveFolderName;
  static const Field<ArchivedSave, String> _f$saveFolderName = Field(
    'saveFolderName',
    _$saveFolderName,
  );
  static String? _$characterName(ArchivedSave v) => v.characterName;
  static const Field<ArchivedSave, String> _f$characterName = Field(
    'characterName',
    _$characterName,
    opt: true,
  );
  static int? _$characterLevel(ArchivedSave v) => v.characterLevel;
  static const Field<ArchivedSave, int> _f$characterLevel = Field(
    'characterLevel',
    _$characterLevel,
    opt: true,
  );
  static String? _$portraitPath(ArchivedSave v) => v.portraitPath;
  static const Field<ArchivedSave, String> _f$portraitPath = Field(
    'portraitPath',
    _$portraitPath,
    opt: true,
  );
  static String? _$saveFileVersion(ArchivedSave v) => v.saveFileVersion;
  static const Field<ArchivedSave, String> _f$saveFileVersion = Field(
    'saveFileVersion',
    _$saveFileVersion,
    opt: true,
  );
  static DateTime? _$saveDate(ArchivedSave v) => v.saveDate;
  static const Field<ArchivedSave, DateTime> _f$saveDate = Field(
    'saveDate',
    _$saveDate,
    opt: true,
  );
  static int? _$gameTimestamp(ArchivedSave v) => v.gameTimestamp;
  static const Field<ArchivedSave, int> _f$gameTimestamp = Field(
    'gameTimestamp',
    _$gameTimestamp,
    opt: true,
  );
  static double? _$secondsPerDay(ArchivedSave v) => v.secondsPerDay;
  static const Field<ArchivedSave, double> _f$secondsPerDay = Field(
    'secondsPerDay',
    _$secondsPerDay,
    opt: true,
  );
  static String? _$difficulty(ArchivedSave v) => v.difficulty;
  static const Field<ArchivedSave, String> _f$difficulty = Field(
    'difficulty',
    _$difficulty,
    opt: true,
  );
  static bool? _$isIronMode(ArchivedSave v) => v.isIronMode;
  static const Field<ArchivedSave, bool> _f$isIronMode = Field(
    'isIronMode',
    _$isIronMode,
    opt: true,
  );
  static List<String> _$modNames(ArchivedSave v) => v.modNames;
  static const Field<ArchivedSave, List<String>> _f$modNames = Field(
    'modNames',
    _$modNames,
    opt: true,
    def: const [],
  );
  static int _$fileCount(ArchivedSave v) => v.fileCount;
  static const Field<ArchivedSave, int> _f$fileCount = Field(
    'fileCount',
    _$fileCount,
    opt: true,
    def: 0,
  );
  static int _$originalSizeInBytes(ArchivedSave v) => v.originalSizeInBytes;
  static const Field<ArchivedSave, int> _f$originalSizeInBytes = Field(
    'originalSizeInBytes',
    _$originalSizeInBytes,
    opt: true,
    def: 0,
  );
  static int _$archiveSizeInBytes(ArchivedSave v) => v.archiveSizeInBytes;
  static const Field<ArchivedSave, int> _f$archiveSizeInBytes = Field(
    'archiveSizeInBytes',
    _$archiveSizeInBytes,
    opt: true,
    def: 0,
  );
  static DateTime _$archivedDate(ArchivedSave v) => v.archivedDate;
  static const Field<ArchivedSave, DateTime> _f$archivedDate = Field(
    'archivedDate',
    _$archivedDate,
  );

  @override
  final MappableFields<ArchivedSave> fields = const {
    #saveFolderName: _f$saveFolderName,
    #characterName: _f$characterName,
    #characterLevel: _f$characterLevel,
    #portraitPath: _f$portraitPath,
    #saveFileVersion: _f$saveFileVersion,
    #saveDate: _f$saveDate,
    #gameTimestamp: _f$gameTimestamp,
    #secondsPerDay: _f$secondsPerDay,
    #difficulty: _f$difficulty,
    #isIronMode: _f$isIronMode,
    #modNames: _f$modNames,
    #fileCount: _f$fileCount,
    #originalSizeInBytes: _f$originalSizeInBytes,
    #archiveSizeInBytes: _f$archiveSizeInBytes,
    #archivedDate: _f$archivedDate,
  };

  static ArchivedSave _instantiate(DecodingData data) {
    return ArchivedSave(
      saveFolderName: data.dec(_f$saveFolderName),
      characterName: data.dec(_f$characterName),
      characterLevel: data.dec(_f$characterLevel),
      portraitPath: data.dec(_f$portraitPath),
      saveFileVersion: data.dec(_f$saveFileVersion),
      saveDate: data.dec(_f$saveDate),
      gameTimestamp: data.dec(_f$gameTimestamp),
      secondsPerDay: data.dec(_f$secondsPerDay),
      difficulty: data.dec(_f$difficulty),
      isIronMode: data.dec(_f$isIronMode),
      modNames: data.dec(_f$modNames),
      fileCount: data.dec(_f$fileCount),
      originalSizeInBytes: data.dec(_f$originalSizeInBytes),
      archiveSizeInBytes: data.dec(_f$archiveSizeInBytes),
      archivedDate: data.dec(_f$archivedDate),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static ArchivedSave fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<ArchivedSave>(map);
  }

  static ArchivedSave fromJson(String json) {
    return ensureInitialized().decodeJson<ArchivedSave>(json);
  }
}

mixin ArchivedSaveMappable {
  String toJson() {
    return ArchivedSaveMapper.ensureInitialized().encodeJson<ArchivedSave>(
      this as ArchivedSave,
    );
  }

  Map<String, dynamic> toMap() {
    return ArchivedSaveMapper.ensureInitialized().encodeMap<ArchivedSave>(
      this as ArchivedSave,
    );
  }

  ArchivedSaveCopyWith<ArchivedSave, ArchivedSave, ArchivedSave> get copyWith =>
      _ArchivedSaveCopyWithImpl<ArchivedSave, ArchivedSave>(
        this as ArchivedSave,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return ArchivedSaveMapper.ensureInitialized().stringifyValue(
      this as ArchivedSave,
    );
  }

  @override
  bool operator ==(Object other) {
    return ArchivedSaveMapper.ensureInitialized().equalsValue(
      this as ArchivedSave,
      other,
    );
  }

  @override
  int get hashCode {
    return ArchivedSaveMapper.ensureInitialized().hashValue(
      this as ArchivedSave,
    );
  }
}

extension ArchivedSaveValueCopy<$R, $Out>
    on ObjectCopyWith<$R, ArchivedSave, $Out> {
  ArchivedSaveCopyWith<$R, ArchivedSave, $Out> get $asArchivedSave =>
      $base.as((v, t, t2) => _ArchivedSaveCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class ArchivedSaveCopyWith<$R, $In extends ArchivedSave, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>> get modNames;
  $R call({
    String? saveFolderName,
    String? characterName,
    int? characterLevel,
    String? portraitPath,
    String? saveFileVersion,
    DateTime? saveDate,
    int? gameTimestamp,
    double? secondsPerDay,
    String? difficulty,
    bool? isIronMode,
    List<String>? modNames,
    int? fileCount,
    int? originalSizeInBytes,
    int? archiveSizeInBytes,
    DateTime? archivedDate,
  });
  ArchivedSaveCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _ArchivedSaveCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, ArchivedSave, $Out>
    implements ArchivedSaveCopyWith<$R, ArchivedSave, $Out> {
  _ArchivedSaveCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<ArchivedSave> $mapper =
      ArchivedSaveMapper.ensureInitialized();
  @override
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>> get modNames =>
      ListCopyWith(
        $value.modNames,
        (v, t) => ObjectCopyWith(v, $identity, t),
        (v) => call(modNames: v),
      );
  @override
  $R call({
    String? saveFolderName,
    Object? characterName = $none,
    Object? characterLevel = $none,
    Object? portraitPath = $none,
    Object? saveFileVersion = $none,
    Object? saveDate = $none,
    Object? gameTimestamp = $none,
    Object? secondsPerDay = $none,
    Object? difficulty = $none,
    Object? isIronMode = $none,
    List<String>? modNames,
    int? fileCount,
    int? originalSizeInBytes,
    int? archiveSizeInBytes,
    DateTime? archivedDate,
  }) => $apply(
    FieldCopyWithData({
      if (saveFolderName != null) #saveFolderName: saveFolderName,
      if (characterName != $none) #characterName: characterName,
      if (characterLevel != $none) #characterLevel: characterLevel,
      if (portraitPath != $none) #portraitPath: portraitPath,
      if (saveFileVersion != $none) #saveFileVersion: saveFileVersion,
      if (saveDate != $none) #saveDate: saveDate,
      if (gameTimestamp != $none) #gameTimestamp: gameTimestamp,
      if (secondsPerDay != $none) #secondsPerDay: secondsPerDay,
      if (difficulty != $none) #difficulty: difficulty,
      if (isIronMode != $none) #isIronMode: isIronMode,
      if (modNames != null) #modNames: modNames,
      if (fileCount != null) #fileCount: fileCount,
      if (originalSizeInBytes != null)
        #originalSizeInBytes: originalSizeInBytes,
      if (archiveSizeInBytes != null) #archiveSizeInBytes: archiveSizeInBytes,
      if (archivedDate != null) #archivedDate: archivedDate,
    }),
  );
  @override
  ArchivedSave $make(CopyWithData data) => ArchivedSave(
    saveFolderName: data.get(#saveFolderName, or: $value.saveFolderName),
    characterName: data.get(#characterName, or: $value.characterName),
    characterLevel: data.get(#characterLevel, or: $value.characterLevel),
    portraitPath: data.get(#portraitPath, or: $value.portraitPath),
    saveFileVersion: data.get(#saveFileVersion, or: $value.saveFileVersion),
    saveDate: data.get(#saveDate, or: $value.saveDate),
    gameTimestamp: data.get(#gameTimestamp, or: $value.gameTimestamp),
    secondsPerDay: data.get(#secondsPerDay, or: $value.secondsPerDay),
    difficulty: data.get(#difficulty, or: $value.difficulty),
    isIronMode: data.get(#isIronMode, or: $value.isIronMode),
    modNames: data.get(#modNames, or: $value.modNames),
    fileCount: data.get(#fileCount, or: $value.fileCount),
    originalSizeInBytes: data.get(
      #originalSizeInBytes,
      or: $value.originalSizeInBytes,
    ),
    archiveSizeInBytes: data.get(
      #archiveSizeInBytes,
      or: $value.archiveSizeInBytes,
    ),
    archivedDate: data.get(#archivedDate, or: $value.archivedDate),
  );

  @override
  ArchivedSaveCopyWith<$R2, ArchivedSave, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _ArchivedSaveCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

