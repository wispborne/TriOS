// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'theme_modifiers.dart';

class AppIconOverrideMapper extends EnumMapper<AppIconOverride> {
  AppIconOverrideMapper._();

  static AppIconOverrideMapper? _instance;
  static AppIconOverrideMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = AppIconOverrideMapper._());
    }
    return _instance!;
  }

  static AppIconOverride fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  AppIconOverride decode(dynamic value) {
    switch (value) {
      case r'defaultIcon':
        return AppIconOverride.defaultIcon;
      case r'pride':
        return AppIconOverride.pride;
      case r'hegemony':
        return AppIconOverride.hegemony;
      default:
        return AppIconOverride.values[0];
    }
  }

  @override
  dynamic encode(AppIconOverride self) {
    switch (self) {
      case AppIconOverride.defaultIcon:
        return r'defaultIcon';
      case AppIconOverride.pride:
        return r'pride';
      case AppIconOverride.hegemony:
        return r'hegemony';
    }
  }
}

extension AppIconOverrideMapperExtension on AppIconOverride {
  String toValue() {
    AppIconOverrideMapper.ensureInitialized();
    return MapperContainer.globals.toValue<AppIconOverride>(this) as String;
  }
}

class AppNameOverrideMapper extends EnumMapper<AppNameOverride> {
  AppNameOverrideMapper._();

  static AppNameOverrideMapper? _instance;
  static AppNameOverrideMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = AppNameOverrideMapper._());
    }
    return _instance!;
  }

  static AppNameOverride fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  AppNameOverride decode(dynamic value) {
    switch (value) {
      case r'defaultName':
        return AppNameOverride.defaultName;
      case r'hegOS':
        return AppNameOverride.hegOS;
      default:
        return AppNameOverride.values[0];
    }
  }

  @override
  dynamic encode(AppNameOverride self) {
    switch (self) {
      case AppNameOverride.defaultName:
        return r'defaultName';
      case AppNameOverride.hegOS:
        return r'hegOS';
    }
  }
}

extension AppNameOverrideMapperExtension on AppNameOverride {
  String toValue() {
    AppNameOverrideMapper.ensureInitialized();
    return MapperContainer.globals.toValue<AppNameOverride>(this) as String;
  }
}

class ThemeModifiersMapper extends ClassMapperBase<ThemeModifiers> {
  ThemeModifiersMapper._();

  static ThemeModifiersMapper? _instance;
  static ThemeModifiersMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ThemeModifiersMapper._());
      AppIconOverrideMapper.ensureInitialized();
      AppNameOverrideMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'ThemeModifiers';

  static AppIconOverride _$appIconOverride(ThemeModifiers v) =>
      v.appIconOverride;
  static const Field<ThemeModifiers, AppIconOverride> _f$appIconOverride =
      Field(
        'appIconOverride',
        _$appIconOverride,
        opt: true,
        def: AppIconOverride.defaultIcon,
      );
  static AppNameOverride _$appNameOverride(ThemeModifiers v) =>
      v.appNameOverride;
  static const Field<ThemeModifiers, AppNameOverride> _f$appNameOverride =
      Field(
        'appNameOverride',
        _$appNameOverride,
        opt: true,
        def: AppNameOverride.defaultName,
      );
  static bool _$rainbowLaunchIcon(ThemeModifiers v) => v.rainbowLaunchIcon;
  static const Field<ThemeModifiers, bool> _f$rainbowLaunchIcon = Field(
    'rainbowLaunchIcon',
    _$rainbowLaunchIcon,
    opt: true,
    def: false,
  );

  @override
  final MappableFields<ThemeModifiers> fields = const {
    #appIconOverride: _f$appIconOverride,
    #appNameOverride: _f$appNameOverride,
    #rainbowLaunchIcon: _f$rainbowLaunchIcon,
  };

  static ThemeModifiers _instantiate(DecodingData data) {
    return ThemeModifiers(
      appIconOverride: data.dec(_f$appIconOverride),
      appNameOverride: data.dec(_f$appNameOverride),
      rainbowLaunchIcon: data.dec(_f$rainbowLaunchIcon),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static ThemeModifiers fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<ThemeModifiers>(map);
  }

  static ThemeModifiers fromJson(String json) {
    return ensureInitialized().decodeJson<ThemeModifiers>(json);
  }
}

mixin ThemeModifiersMappable {
  String toJson() {
    return ThemeModifiersMapper.ensureInitialized().encodeJson<ThemeModifiers>(
      this as ThemeModifiers,
    );
  }

  Map<String, dynamic> toMap() {
    return ThemeModifiersMapper.ensureInitialized().encodeMap<ThemeModifiers>(
      this as ThemeModifiers,
    );
  }

  ThemeModifiersCopyWith<ThemeModifiers, ThemeModifiers, ThemeModifiers>
  get copyWith => _ThemeModifiersCopyWithImpl<ThemeModifiers, ThemeModifiers>(
    this as ThemeModifiers,
    $identity,
    $identity,
  );
  @override
  String toString() {
    return ThemeModifiersMapper.ensureInitialized().stringifyValue(
      this as ThemeModifiers,
    );
  }

  @override
  bool operator ==(Object other) {
    return ThemeModifiersMapper.ensureInitialized().equalsValue(
      this as ThemeModifiers,
      other,
    );
  }

  @override
  int get hashCode {
    return ThemeModifiersMapper.ensureInitialized().hashValue(
      this as ThemeModifiers,
    );
  }
}

extension ThemeModifiersValueCopy<$R, $Out>
    on ObjectCopyWith<$R, ThemeModifiers, $Out> {
  ThemeModifiersCopyWith<$R, ThemeModifiers, $Out> get $asThemeModifiers =>
      $base.as((v, t, t2) => _ThemeModifiersCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class ThemeModifiersCopyWith<$R, $In extends ThemeModifiers, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({
    AppIconOverride? appIconOverride,
    AppNameOverride? appNameOverride,
    bool? rainbowLaunchIcon,
  });
  ThemeModifiersCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _ThemeModifiersCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, ThemeModifiers, $Out>
    implements ThemeModifiersCopyWith<$R, ThemeModifiers, $Out> {
  _ThemeModifiersCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<ThemeModifiers> $mapper =
      ThemeModifiersMapper.ensureInitialized();
  @override
  $R call({
    AppIconOverride? appIconOverride,
    AppNameOverride? appNameOverride,
    bool? rainbowLaunchIcon,
  }) => $apply(
    FieldCopyWithData({
      if (appIconOverride != null) #appIconOverride: appIconOverride,
      if (appNameOverride != null) #appNameOverride: appNameOverride,
      if (rainbowLaunchIcon != null) #rainbowLaunchIcon: rainbowLaunchIcon,
    }),
  );
  @override
  ThemeModifiers $make(CopyWithData data) => ThemeModifiers(
    appIconOverride: data.get(#appIconOverride, or: $value.appIconOverride),
    appNameOverride: data.get(#appNameOverride, or: $value.appNameOverride),
    rainbowLaunchIcon: data.get(
      #rainbowLaunchIcon,
      or: $value.rainbowLaunchIcon,
    ),
  );

  @override
  ThemeModifiersCopyWith<$R2, ThemeModifiers, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _ThemeModifiersCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

