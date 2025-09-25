// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
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
      CustomPathFieldStateMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'GamePathsSetupState';

  static String _$gamePathText(GamePathsSetupState v) => v.gamePathText;
  static const Field<GamePathsSetupState, String> _f$gamePathText = Field(
    'gamePathText',
    _$gamePathText,
    opt: true,
    def: '',
  );
  static bool _$gamePathExists(GamePathsSetupState v) => v.gamePathExists;
  static const Field<GamePathsSetupState, bool> _f$gamePathExists = Field(
    'gamePathExists',
    _$gamePathExists,
    opt: true,
    def: false,
  );
  static CustomPathFieldState _$customExecutablePathState(
    GamePathsSetupState v,
  ) => v.customExecutablePathState;
  static const Field<GamePathsSetupState, CustomPathFieldState>
  _f$customExecutablePathState = Field(
    'customExecutablePathState',
    _$customExecutablePathState,
    opt: true,
    def: const CustomPathFieldState(),
  );
  static CustomPathFieldState _$customModsPathState(GamePathsSetupState v) =>
      v.customModsPathState;
  static const Field<GamePathsSetupState, CustomPathFieldState>
  _f$customModsPathState = Field(
    'customModsPathState',
    _$customModsPathState,
    opt: true,
    def: const CustomPathFieldState(),
  );
  static CustomPathFieldState _$customSavesPathState(GamePathsSetupState v) =>
      v.customSavesPathState;
  static const Field<GamePathsSetupState, CustomPathFieldState>
  _f$customSavesPathState = Field(
    'customSavesPathState',
    _$customSavesPathState,
    opt: true,
    def: const CustomPathFieldState(),
  );
  static CustomPathFieldState _$customCorePathState(GamePathsSetupState v) =>
      v.customCorePathState;
  static const Field<GamePathsSetupState, CustomPathFieldState>
  _f$customCorePathState = Field(
    'customCorePathState',
    _$customCorePathState,
    opt: true,
    def: const CustomPathFieldState(),
  );

  @override
  final MappableFields<GamePathsSetupState> fields = const {
    #gamePathText: _f$gamePathText,
    #gamePathExists: _f$gamePathExists,
    #customExecutablePathState: _f$customExecutablePathState,
    #customModsPathState: _f$customModsPathState,
    #customSavesPathState: _f$customSavesPathState,
    #customCorePathState: _f$customCorePathState,
  };

  static GamePathsSetupState _instantiate(DecodingData data) {
    return GamePathsSetupState(
      gamePathText: data.dec(_f$gamePathText),
      gamePathExists: data.dec(_f$gamePathExists),
      customExecutablePathState: data.dec(_f$customExecutablePathState),
      customModsPathState: data.dec(_f$customModsPathState),
      customSavesPathState: data.dec(_f$customSavesPathState),
      customCorePathState: data.dec(_f$customCorePathState),
    );
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

  GamePathsSetupStateCopyWith<
    GamePathsSetupState,
    GamePathsSetupState,
    GamePathsSetupState
  >
  get copyWith =>
      _GamePathsSetupStateCopyWithImpl<
        GamePathsSetupState,
        GamePathsSetupState
      >(this as GamePathsSetupState, $identity, $identity);
  @override
  String toString() {
    return GamePathsSetupStateMapper.ensureInitialized().stringifyValue(
      this as GamePathsSetupState,
    );
  }

  @override
  bool operator ==(Object other) {
    return GamePathsSetupStateMapper.ensureInitialized().equalsValue(
      this as GamePathsSetupState,
      other,
    );
  }

  @override
  int get hashCode {
    return GamePathsSetupStateMapper.ensureInitialized().hashValue(
      this as GamePathsSetupState,
    );
  }
}

extension GamePathsSetupStateValueCopy<$R, $Out>
    on ObjectCopyWith<$R, GamePathsSetupState, $Out> {
  GamePathsSetupStateCopyWith<$R, GamePathsSetupState, $Out>
  get $asGamePathsSetupState => $base.as(
    (v, t, t2) => _GamePathsSetupStateCopyWithImpl<$R, $Out>(v, t, t2),
  );
}

abstract class GamePathsSetupStateCopyWith<
  $R,
  $In extends GamePathsSetupState,
  $Out
>
    implements ClassCopyWith<$R, $In, $Out> {
  CustomPathFieldStateCopyWith<$R, CustomPathFieldState, CustomPathFieldState>
  get customExecutablePathState;
  CustomPathFieldStateCopyWith<$R, CustomPathFieldState, CustomPathFieldState>
  get customModsPathState;
  CustomPathFieldStateCopyWith<$R, CustomPathFieldState, CustomPathFieldState>
  get customSavesPathState;
  CustomPathFieldStateCopyWith<$R, CustomPathFieldState, CustomPathFieldState>
  get customCorePathState;
  $R call({
    String? gamePathText,
    bool? gamePathExists,
    CustomPathFieldState? customExecutablePathState,
    CustomPathFieldState? customModsPathState,
    CustomPathFieldState? customSavesPathState,
    CustomPathFieldState? customCorePathState,
  });
  GamePathsSetupStateCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _GamePathsSetupStateCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, GamePathsSetupState, $Out>
    implements GamePathsSetupStateCopyWith<$R, GamePathsSetupState, $Out> {
  _GamePathsSetupStateCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<GamePathsSetupState> $mapper =
      GamePathsSetupStateMapper.ensureInitialized();
  @override
  CustomPathFieldStateCopyWith<$R, CustomPathFieldState, CustomPathFieldState>
  get customExecutablePathState => $value.customExecutablePathState.copyWith
      .$chain((v) => call(customExecutablePathState: v));
  @override
  CustomPathFieldStateCopyWith<$R, CustomPathFieldState, CustomPathFieldState>
  get customModsPathState => $value.customModsPathState.copyWith.$chain(
    (v) => call(customModsPathState: v),
  );
  @override
  CustomPathFieldStateCopyWith<$R, CustomPathFieldState, CustomPathFieldState>
  get customSavesPathState => $value.customSavesPathState.copyWith.$chain(
    (v) => call(customSavesPathState: v),
  );
  @override
  CustomPathFieldStateCopyWith<$R, CustomPathFieldState, CustomPathFieldState>
  get customCorePathState => $value.customCorePathState.copyWith.$chain(
    (v) => call(customCorePathState: v),
  );
  @override
  $R call({
    String? gamePathText,
    bool? gamePathExists,
    CustomPathFieldState? customExecutablePathState,
    CustomPathFieldState? customModsPathState,
    CustomPathFieldState? customSavesPathState,
    CustomPathFieldState? customCorePathState,
  }) => $apply(
    FieldCopyWithData({
      if (gamePathText != null) #gamePathText: gamePathText,
      if (gamePathExists != null) #gamePathExists: gamePathExists,
      if (customExecutablePathState != null)
        #customExecutablePathState: customExecutablePathState,
      if (customModsPathState != null)
        #customModsPathState: customModsPathState,
      if (customSavesPathState != null)
        #customSavesPathState: customSavesPathState,
      if (customCorePathState != null)
        #customCorePathState: customCorePathState,
    }),
  );
  @override
  GamePathsSetupState $make(CopyWithData data) => GamePathsSetupState(
    gamePathText: data.get(#gamePathText, or: $value.gamePathText),
    gamePathExists: data.get(#gamePathExists, or: $value.gamePathExists),
    customExecutablePathState: data.get(
      #customExecutablePathState,
      or: $value.customExecutablePathState,
    ),
    customModsPathState: data.get(
      #customModsPathState,
      or: $value.customModsPathState,
    ),
    customSavesPathState: data.get(
      #customSavesPathState,
      or: $value.customSavesPathState,
    ),
    customCorePathState: data.get(
      #customCorePathState,
      or: $value.customCorePathState,
    ),
  );

  @override
  GamePathsSetupStateCopyWith<$R2, GamePathsSetupState, $Out2>
  $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _GamePathsSetupStateCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class CustomPathFieldStateMapper extends ClassMapperBase<CustomPathFieldState> {
  CustomPathFieldStateMapper._();

  static CustomPathFieldStateMapper? _instance;
  static CustomPathFieldStateMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = CustomPathFieldStateMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'CustomPathFieldState';

  static bool _$useCustomPath(CustomPathFieldState v) => v.useCustomPath;
  static const Field<CustomPathFieldState, bool> _f$useCustomPath = Field(
    'useCustomPath',
    _$useCustomPath,
    opt: true,
    def: false,
  );
  static String _$pathText(CustomPathFieldState v) => v.pathText;
  static const Field<CustomPathFieldState, String> _f$pathText = Field(
    'pathText',
    _$pathText,
    opt: true,
    def: '',
  );
  static bool _$pathExists(CustomPathFieldState v) => v.pathExists;
  static const Field<CustomPathFieldState, bool> _f$pathExists = Field(
    'pathExists',
    _$pathExists,
    opt: true,
    def: false,
  );

  @override
  final MappableFields<CustomPathFieldState> fields = const {
    #useCustomPath: _f$useCustomPath,
    #pathText: _f$pathText,
    #pathExists: _f$pathExists,
  };

  static CustomPathFieldState _instantiate(DecodingData data) {
    return CustomPathFieldState(
      useCustomPath: data.dec(_f$useCustomPath),
      pathText: data.dec(_f$pathText),
      pathExists: data.dec(_f$pathExists),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static CustomPathFieldState fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<CustomPathFieldState>(map);
  }

  static CustomPathFieldState fromJson(String json) {
    return ensureInitialized().decodeJson<CustomPathFieldState>(json);
  }
}

mixin CustomPathFieldStateMappable {
  String toJson() {
    return CustomPathFieldStateMapper.ensureInitialized()
        .encodeJson<CustomPathFieldState>(this as CustomPathFieldState);
  }

  Map<String, dynamic> toMap() {
    return CustomPathFieldStateMapper.ensureInitialized()
        .encodeMap<CustomPathFieldState>(this as CustomPathFieldState);
  }

  CustomPathFieldStateCopyWith<
    CustomPathFieldState,
    CustomPathFieldState,
    CustomPathFieldState
  >
  get copyWith =>
      _CustomPathFieldStateCopyWithImpl<
        CustomPathFieldState,
        CustomPathFieldState
      >(this as CustomPathFieldState, $identity, $identity);
  @override
  String toString() {
    return CustomPathFieldStateMapper.ensureInitialized().stringifyValue(
      this as CustomPathFieldState,
    );
  }

  @override
  bool operator ==(Object other) {
    return CustomPathFieldStateMapper.ensureInitialized().equalsValue(
      this as CustomPathFieldState,
      other,
    );
  }

  @override
  int get hashCode {
    return CustomPathFieldStateMapper.ensureInitialized().hashValue(
      this as CustomPathFieldState,
    );
  }
}

extension CustomPathFieldStateValueCopy<$R, $Out>
    on ObjectCopyWith<$R, CustomPathFieldState, $Out> {
  CustomPathFieldStateCopyWith<$R, CustomPathFieldState, $Out>
  get $asCustomPathFieldState => $base.as(
    (v, t, t2) => _CustomPathFieldStateCopyWithImpl<$R, $Out>(v, t, t2),
  );
}

abstract class CustomPathFieldStateCopyWith<
  $R,
  $In extends CustomPathFieldState,
  $Out
>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({bool? useCustomPath, String? pathText, bool? pathExists});
  CustomPathFieldStateCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _CustomPathFieldStateCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, CustomPathFieldState, $Out>
    implements CustomPathFieldStateCopyWith<$R, CustomPathFieldState, $Out> {
  _CustomPathFieldStateCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<CustomPathFieldState> $mapper =
      CustomPathFieldStateMapper.ensureInitialized();
  @override
  $R call({bool? useCustomPath, String? pathText, bool? pathExists}) => $apply(
    FieldCopyWithData({
      if (useCustomPath != null) #useCustomPath: useCustomPath,
      if (pathText != null) #pathText: pathText,
      if (pathExists != null) #pathExists: pathExists,
    }),
  );
  @override
  CustomPathFieldState $make(CopyWithData data) => CustomPathFieldState(
    useCustomPath: data.get(#useCustomPath, or: $value.useCustomPath),
    pathText: data.get(#pathText, or: $value.pathText),
    pathExists: data.get(#pathExists, or: $value.pathExists),
  );

  @override
  CustomPathFieldStateCopyWith<$R2, CustomPathFieldState, $Out2>
  $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _CustomPathFieldStateCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

