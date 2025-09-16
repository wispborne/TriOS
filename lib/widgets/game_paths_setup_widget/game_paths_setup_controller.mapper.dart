// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'game_paths_setup_controller.dart';

class GamePathsSetupStateMapper extends ClassMapperBase<GamePathsSetupState> {
  GamePathsSetupStateMapper._();

  static GamePathsSetupStateMapper? _instance;
  static GamePathsSetupStateMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = GamePathsSetupStateMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'GamePathsSetupState';

  static String _$gamePathText(GamePathsSetupState v) => v.gamePathText;
  static const Field<GamePathsSetupState, String> _f$gamePathText =
      Field('gamePathText', _$gamePathText, opt: true, def: '');
  static bool _$gamePathExists(GamePathsSetupState v) => v.gamePathExists;
  static const Field<GamePathsSetupState, bool> _f$gamePathExists =
      Field('gamePathExists', _$gamePathExists, opt: true, def: false);
  static bool _$useCustomExecutable(GamePathsSetupState v) =>
      v.useCustomExecutable;
  static const Field<GamePathsSetupState, bool> _f$useCustomExecutable = Field(
      'useCustomExecutable', _$useCustomExecutable,
      opt: true, def: false);
  static String _$customExecutablePathText(GamePathsSetupState v) =>
      v.customExecutablePathText;
  static const Field<GamePathsSetupState, String> _f$customExecutablePathText =
      Field('customExecutablePathText', _$customExecutablePathText,
          opt: true, def: '');
  static bool _$customExecutablePathExists(GamePathsSetupState v) =>
      v.customExecutablePathExists;
  static const Field<GamePathsSetupState, bool> _f$customExecutablePathExists =
      Field('customExecutablePathExists', _$customExecutablePathExists,
          opt: true, def: false);
  static bool _$useCustomModsPath(GamePathsSetupState v) => v.useCustomModsPath;
  static const Field<GamePathsSetupState, bool> _f$useCustomModsPath =
      Field('useCustomModsPath', _$useCustomModsPath, opt: true, def: false);
  static String _$customModsPathText(GamePathsSetupState v) =>
      v.customModsPathText;
  static const Field<GamePathsSetupState, String> _f$customModsPathText =
      Field('customModsPathText', _$customModsPathText, opt: true, def: '');
  static bool _$customModsPathExists(GamePathsSetupState v) =>
      v.customModsPathExists;
  static const Field<GamePathsSetupState, bool> _f$customModsPathExists = Field(
      'customModsPathExists', _$customModsPathExists,
      opt: true, def: false);
  static bool _$useCustomSavesPath(GamePathsSetupState v) =>
      v.useCustomSavesPath;
  static const Field<GamePathsSetupState, bool> _f$useCustomSavesPath =
      Field('useCustomSavesPath', _$useCustomSavesPath, opt: true, def: false);
  static String _$customSavesPathText(GamePathsSetupState v) =>
      v.customSavesPathText;
  static const Field<GamePathsSetupState, String> _f$customSavesPathText =
      Field('customSavesPathText', _$customSavesPathText, opt: true, def: '');
  static bool _$customSavesPathExists(GamePathsSetupState v) =>
      v.customSavesPathExists;
  static const Field<GamePathsSetupState, bool> _f$customSavesPathExists =
      Field('customSavesPathExists', _$customSavesPathExists,
          opt: true, def: false);
  static bool _$useCustomCorePath(GamePathsSetupState v) => v.useCustomCorePath;
  static const Field<GamePathsSetupState, bool> _f$useCustomCorePath =
      Field('useCustomCorePath', _$useCustomCorePath, opt: true, def: false);
  static String _$customCorePathText(GamePathsSetupState v) =>
      v.customCorePathText;
  static const Field<GamePathsSetupState, String> _f$customCorePathText =
      Field('customCorePathText', _$customCorePathText, opt: true, def: '');
  static bool _$customCorePathExists(GamePathsSetupState v) =>
      v.customCorePathExists;
  static const Field<GamePathsSetupState, bool> _f$customCorePathExists = Field(
      'customCorePathExists', _$customCorePathExists,
      opt: true, def: false);

  @override
  final MappableFields<GamePathsSetupState> fields = const {
    #gamePathText: _f$gamePathText,
    #gamePathExists: _f$gamePathExists,
    #useCustomExecutable: _f$useCustomExecutable,
    #customExecutablePathText: _f$customExecutablePathText,
    #customExecutablePathExists: _f$customExecutablePathExists,
    #useCustomModsPath: _f$useCustomModsPath,
    #customModsPathText: _f$customModsPathText,
    #customModsPathExists: _f$customModsPathExists,
    #useCustomSavesPath: _f$useCustomSavesPath,
    #customSavesPathText: _f$customSavesPathText,
    #customSavesPathExists: _f$customSavesPathExists,
    #useCustomCorePath: _f$useCustomCorePath,
    #customCorePathText: _f$customCorePathText,
    #customCorePathExists: _f$customCorePathExists,
  };

  static GamePathsSetupState _instantiate(DecodingData data) {
    return GamePathsSetupState(
        gamePathText: data.dec(_f$gamePathText),
        gamePathExists: data.dec(_f$gamePathExists),
        useCustomExecutable: data.dec(_f$useCustomExecutable),
        customExecutablePathText: data.dec(_f$customExecutablePathText),
        customExecutablePathExists: data.dec(_f$customExecutablePathExists),
        useCustomModsPath: data.dec(_f$useCustomModsPath),
        customModsPathText: data.dec(_f$customModsPathText),
        customModsPathExists: data.dec(_f$customModsPathExists),
        useCustomSavesPath: data.dec(_f$useCustomSavesPath),
        customSavesPathText: data.dec(_f$customSavesPathText),
        customSavesPathExists: data.dec(_f$customSavesPathExists),
        useCustomCorePath: data.dec(_f$useCustomCorePath),
        customCorePathText: data.dec(_f$customCorePathText),
        customCorePathExists: data.dec(_f$customCorePathExists));
  }

  @override
  final Function instantiate = _instantiate;

  static GamePathsSetupState fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<GamePathsSetupState>(map);
  }

  static GamePathsSetupState fromJson(String json) {
    return ensureInitialized().decodeJson<GamePathsSetupState>(json);
  }
}

mixin GamePathsSetupStateMappable {
  String toJson() {
    return GamePathsSetupStateMapper.ensureInitialized()
        .encodeJson<GamePathsSetupState>(this as GamePathsSetupState);
  }

  Map<String, dynamic> toMap() {
    return GamePathsSetupStateMapper.ensureInitialized()
        .encodeMap<GamePathsSetupState>(this as GamePathsSetupState);
  }

  GamePathsSetupStateCopyWith<GamePathsSetupState, GamePathsSetupState,
      GamePathsSetupState> get copyWith => _GamePathsSetupStateCopyWithImpl<
          GamePathsSetupState, GamePathsSetupState>(
      this as GamePathsSetupState, $identity, $identity);
  @override
  String toString() {
    return GamePathsSetupStateMapper.ensureInitialized()
        .stringifyValue(this as GamePathsSetupState);
  }

  @override
  bool operator ==(Object other) {
    return GamePathsSetupStateMapper.ensureInitialized()
        .equalsValue(this as GamePathsSetupState, other);
  }

  @override
  int get hashCode {
    return GamePathsSetupStateMapper.ensureInitialized()
        .hashValue(this as GamePathsSetupState);
  }
}

extension GamePathsSetupStateValueCopy<$R, $Out>
    on ObjectCopyWith<$R, GamePathsSetupState, $Out> {
  GamePathsSetupStateCopyWith<$R, GamePathsSetupState, $Out>
      get $asGamePathsSetupState => $base.as(
          (v, t, t2) => _GamePathsSetupStateCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class GamePathsSetupStateCopyWith<$R, $In extends GamePathsSetupState,
    $Out> implements ClassCopyWith<$R, $In, $Out> {
  $R call(
      {String? gamePathText,
      bool? gamePathExists,
      bool? useCustomExecutable,
      String? customExecutablePathText,
      bool? customExecutablePathExists,
      bool? useCustomModsPath,
      String? customModsPathText,
      bool? customModsPathExists,
      bool? useCustomSavesPath,
      String? customSavesPathText,
      bool? customSavesPathExists,
      bool? useCustomCorePath,
      String? customCorePathText,
      bool? customCorePathExists});
  GamePathsSetupStateCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
      Then<$Out2, $R2> t);
}

class _GamePathsSetupStateCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, GamePathsSetupState, $Out>
    implements GamePathsSetupStateCopyWith<$R, GamePathsSetupState, $Out> {
  _GamePathsSetupStateCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<GamePathsSetupState> $mapper =
      GamePathsSetupStateMapper.ensureInitialized();
  @override
  $R call(
          {String? gamePathText,
          bool? gamePathExists,
          bool? useCustomExecutable,
          String? customExecutablePathText,
          bool? customExecutablePathExists,
          bool? useCustomModsPath,
          String? customModsPathText,
          bool? customModsPathExists,
          bool? useCustomSavesPath,
          String? customSavesPathText,
          bool? customSavesPathExists,
          bool? useCustomCorePath,
          String? customCorePathText,
          bool? customCorePathExists}) =>
      $apply(FieldCopyWithData({
        if (gamePathText != null) #gamePathText: gamePathText,
        if (gamePathExists != null) #gamePathExists: gamePathExists,
        if (useCustomExecutable != null)
          #useCustomExecutable: useCustomExecutable,
        if (customExecutablePathText != null)
          #customExecutablePathText: customExecutablePathText,
        if (customExecutablePathExists != null)
          #customExecutablePathExists: customExecutablePathExists,
        if (useCustomModsPath != null) #useCustomModsPath: useCustomModsPath,
        if (customModsPathText != null) #customModsPathText: customModsPathText,
        if (customModsPathExists != null)
          #customModsPathExists: customModsPathExists,
        if (useCustomSavesPath != null) #useCustomSavesPath: useCustomSavesPath,
        if (customSavesPathText != null)
          #customSavesPathText: customSavesPathText,
        if (customSavesPathExists != null)
          #customSavesPathExists: customSavesPathExists,
        if (useCustomCorePath != null) #useCustomCorePath: useCustomCorePath,
        if (customCorePathText != null) #customCorePathText: customCorePathText,
        if (customCorePathExists != null)
          #customCorePathExists: customCorePathExists
      }));
  @override
  GamePathsSetupState $make(CopyWithData data) => GamePathsSetupState(
      gamePathText: data.get(#gamePathText, or: $value.gamePathText),
      gamePathExists: data.get(#gamePathExists, or: $value.gamePathExists),
      useCustomExecutable:
          data.get(#useCustomExecutable, or: $value.useCustomExecutable),
      customExecutablePathText: data.get(#customExecutablePathText,
          or: $value.customExecutablePathText),
      customExecutablePathExists: data.get(#customExecutablePathExists,
          or: $value.customExecutablePathExists),
      useCustomModsPath:
          data.get(#useCustomModsPath, or: $value.useCustomModsPath),
      customModsPathText:
          data.get(#customModsPathText, or: $value.customModsPathText),
      customModsPathExists:
          data.get(#customModsPathExists, or: $value.customModsPathExists),
      useCustomSavesPath:
          data.get(#useCustomSavesPath, or: $value.useCustomSavesPath),
      customSavesPathText:
          data.get(#customSavesPathText, or: $value.customSavesPathText),
      customSavesPathExists:
          data.get(#customSavesPathExists, or: $value.customSavesPathExists),
      useCustomCorePath:
          data.get(#useCustomCorePath, or: $value.useCustomCorePath),
      customCorePathText:
          data.get(#customCorePathText, or: $value.customCorePathText),
      customCorePathExists:
          data.get(#customCorePathExists, or: $value.customCorePathExists));

  @override
  GamePathsSetupStateCopyWith<$R2, GamePathsSetupState, $Out2>
      $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
          _GamePathsSetupStateCopyWithImpl<$R2, $Out2>($value, $cast, t);
}
