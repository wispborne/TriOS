// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'theme_manager.dart';

class ThemeStateMapper extends ClassMapperBase<ThemeState> {
  ThemeStateMapper._();

  static ThemeStateMapper? _instance;
  static ThemeStateMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ThemeStateMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'ThemeState';

  static ThemeData _$themeData(ThemeState v) => v.themeData;
  static const Field<ThemeState, ThemeData> _f$themeData = Field(
    'themeData',
    _$themeData,
  );
  static Map<String, TriOSTheme> _$availableThemes(ThemeState v) =>
      v.availableThemes;
  static const Field<ThemeState, Map<String, TriOSTheme>> _f$availableThemes =
      Field('availableThemes', _$availableThemes);
  static TriOSTheme _$currentTheme(ThemeState v) => v.currentTheme;
  static const Field<ThemeState, TriOSTheme> _f$currentTheme = Field(
    'currentTheme',
    _$currentTheme,
  );

  @override
  final MappableFields<ThemeState> fields = const {
    #themeData: _f$themeData,
    #availableThemes: _f$availableThemes,
    #currentTheme: _f$currentTheme,
  };

  static ThemeState _instantiate(DecodingData data) {
    return ThemeState(
      data.dec(_f$themeData),
      data.dec(_f$availableThemes),
      data.dec(_f$currentTheme),
    );
  }

  @override
  final Function instantiate = _instantiate;
}

mixin ThemeStateMappable {
  ThemeStateCopyWith<ThemeState, ThemeState, ThemeState> get copyWith =>
      _ThemeStateCopyWithImpl<ThemeState, ThemeState>(
        this as ThemeState,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return ThemeStateMapper.ensureInitialized().stringifyValue(
      this as ThemeState,
    );
  }

  @override
  bool operator ==(Object other) {
    return ThemeStateMapper.ensureInitialized().equalsValue(
      this as ThemeState,
      other,
    );
  }

  @override
  int get hashCode {
    return ThemeStateMapper.ensureInitialized().hashValue(this as ThemeState);
  }
}

extension ThemeStateValueCopy<$R, $Out>
    on ObjectCopyWith<$R, ThemeState, $Out> {
  ThemeStateCopyWith<$R, ThemeState, $Out> get $asThemeState =>
      $base.as((v, t, t2) => _ThemeStateCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class ThemeStateCopyWith<$R, $In extends ThemeState, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  MapCopyWith<
    $R,
    String,
    TriOSTheme,
    ObjectCopyWith<$R, TriOSTheme, TriOSTheme>
  >
  get availableThemes;
  $R call({
    ThemeData? themeData,
    Map<String, TriOSTheme>? availableThemes,
    TriOSTheme? currentTheme,
  });
  ThemeStateCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _ThemeStateCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, ThemeState, $Out>
    implements ThemeStateCopyWith<$R, ThemeState, $Out> {
  _ThemeStateCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<ThemeState> $mapper =
      ThemeStateMapper.ensureInitialized();
  @override
  MapCopyWith<
    $R,
    String,
    TriOSTheme,
    ObjectCopyWith<$R, TriOSTheme, TriOSTheme>
  >
  get availableThemes => MapCopyWith(
    $value.availableThemes,
    (v, t) => ObjectCopyWith(v, $identity, t),
    (v) => call(availableThemes: v),
  );
  @override
  $R call({
    ThemeData? themeData,
    Map<String, TriOSTheme>? availableThemes,
    TriOSTheme? currentTheme,
  }) => $apply(
    FieldCopyWithData({
      if (themeData != null) #themeData: themeData,
      if (availableThemes != null) #availableThemes: availableThemes,
      if (currentTheme != null) #currentTheme: currentTheme,
    }),
  );
  @override
  ThemeState $make(CopyWithData data) => ThemeState(
    data.get(#themeData, or: $value.themeData),
    data.get(#availableThemes, or: $value.availableThemes),
    data.get(#currentTheme, or: $value.currentTheme),
  );

  @override
  ThemeStateCopyWith<$R2, ThemeState, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _ThemeStateCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

