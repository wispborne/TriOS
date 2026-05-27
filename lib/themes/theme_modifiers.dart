import 'package:dart_mappable/dart_mappable.dart';

part 'theme_modifiers.mapper.dart';

@MappableEnum(defaultValue: AppIconOverride.defaultIcon)
enum AppIconOverride { defaultIcon, pride, hegemony }

@MappableEnum(defaultValue: AppNameOverride.defaultName)
enum AppNameOverride { defaultName, hegOS }

@MappableClass()
class ThemeModifiers with ThemeModifiersMappable {
  final AppIconOverride appIconOverride;
  final AppNameOverride appNameOverride;
  final bool rainbowLaunchIcon;

  const ThemeModifiers({
    this.appIconOverride = AppIconOverride.defaultIcon,
    this.appNameOverride = AppNameOverride.defaultName,
    this.rainbowLaunchIcon = false,
  });
}
