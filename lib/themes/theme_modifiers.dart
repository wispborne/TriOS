import 'package:dart_mappable/dart_mappable.dart';
import 'package:trios/utils/dart_mappable_utils.dart';

part 'theme_modifiers.mapper.dart';

@MappableEnum(defaultValue: AppIconOverride.defaultIcon)
enum AppIconOverride { defaultIcon, pride, hegemony }

@MappableEnum(defaultValue: AppNameOverride.defaultName)
enum AppNameOverride { defaultName, hegOS }

@MappableEnum(defaultValue: LaunchButtonOverride.defaultStyle)
enum LaunchButtonOverride { defaultStyle, pride }

@MappableEnum(defaultValue: GlitterLocation.sidebar)
enum GlitterLocation {
  sidebar,
  toolbar,
  tooltip;

  String get label => switch (this) {
    GlitterLocation.sidebar => 'Sidebar',
    GlitterLocation.toolbar => 'Toolbar',
    GlitterLocation.tooltip => 'Tooltips',
  };
}

@MappableClass()
class ThemeModifiers with ThemeModifiersMappable {
  final AppIconOverride appIconOverride;
  final AppNameOverride appNameOverride;
  final LaunchButtonOverride launchButtonOverride;

  /// Whether the motes background is enabled. Null = follow the theme default
  /// (on for Pride, off otherwise); an explicit value overrides that.
  final bool? enableGlitter;
  @MappableField(hook: SafeDecodeHook())
  final List<GlitterLocation> glitterLocations;

  /// Theme id whose colors the glitter uses. Null = the active theme.
  final String? glitterThemeKey;

  const ThemeModifiers({
    this.appIconOverride = AppIconOverride.defaultIcon,
    this.appNameOverride = AppNameOverride.defaultName,
    this.launchButtonOverride = LaunchButtonOverride.defaultStyle,
    this.enableGlitter,
    this.glitterLocations = GlitterLocation.values,
    this.glitterThemeKey,
  });

  /// Whether motes should render given the [activeThemeId]. Honors an explicit
  /// [enableGlitter], otherwise defaults on for the Pride theme.
  bool motesEnabled(String? activeThemeId) =>
      enableGlitter ?? (activeThemeId == 'Pride');
}
