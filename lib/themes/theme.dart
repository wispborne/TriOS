import 'dart:ui';

/// /**
/// <a href="https://material.io/design/color/the-color-system.html" class="external" target="_blank">Material Design color system</a>.
///
/// The Material Design color system can help you create a color theme that reflects your brand or
/// style.
///
/// ![Color image](https://developer.android.com/images/reference/androidx/compose/material/color.png)
///
/// @property primary The primary color is the color displayed most frequently across your app’s
/// screens and components.
/// @property primaryVariant The primary variant color is used to distinguish two elements of the
/// app using the primary color, such as the top app bar and the system bar.
/// @property secondary The secondary color provides more ways to accent and distinguish your
/// product. Secondary colors are best for:
/// - Floating action buttons
/// - Selection controls, like checkboxes and radio buttons
/// - Highlighting selected text
/// - Links and headlines
/// @property secondaryVariant The secondary variant color is used to distinguish two elements of the
/// app using the secondary color.
/// @property background The background color appears behind scrollable content.
/// @property surface The surface color is used on surfaces of components, such as cards, sheets and
/// menus.
/// @property error The error color is used to indicate error within components, such as text fields.
/// @property onPrimary Color used for text and icons displayed on top of the primary color.
/// @property onSecondary Color used for text and icons displayed on top of the secondary color.
/// @property onBackground Color used for text and icons displayed on top of the background color.
/// @property onSurface Color used for text and icons displayed on top of the surface color.
/// @property onError Color used for text and icons displayed on top of the error color.
/// @property isDark Whether this Colors is considered as a 'light' or 'dark' set of colors. This
/// affects default behavior for some components: for example, in a light theme a [TopAppBar] will
/// use [primary] by default for its background color, when in a dark theme it will use [surface].
class TriOSTheme {
  final bool isDark;
  final Color primary;
  final Color? primaryVariant;
  final Color? secondary;
  final Color? secondaryVariant;
  final Color? background;
  final Color? surface;
  final Color? error;
  final Color? onPrimary;
  final Color? onSecondary;
  final Color? onBackground;
  final Color? onSurface;
  final Color? onError;
  final Color? hyperlink;

  TriOSTheme({
    this.isDark = true,
    required this.primary,
    this.primaryVariant,
    this.secondary,
    this.secondaryVariant,
    this.background,
    this.surface,
    this.error,
    this.onPrimary,
    this.onSecondary,
    this.onBackground,
    this.onSurface,
    this.onError,
    this.hyperlink,
  });

  // Constructor Handling Hexadecimal Strings
  TriOSTheme.fromHexCodes({
    required this.isDark,
    required String primary,
    String? primaryVariant,
    String? secondary,
    String? secondaryVariant,
    String? background,
    String? surface,
    String? error,
    String? onPrimary,
    String? onSecondary,
    String? onBackground,
    String? onSurface,
    String? onError,
    String? hyperlink,
  })  : primary = _parseColor(primary)!,
        primaryVariant = _parseColor(primaryVariant),
        secondary = _parseColor(secondary),
        secondaryVariant = _parseColor(secondaryVariant),
        background = _parseColor(background),
        surface = _parseColor(surface),
        error = _parseColor(error),
        onPrimary = _parseColor(onPrimary),
        onSecondary = _parseColor(onSecondary),
        onBackground = _parseColor(onBackground),
        onSurface = _parseColor(onSurface),
        onError = _parseColor(onError),
        hyperlink = _parseColor(hyperlink);

  static Color? _parseColor(String? hexCode) {
    if (hexCode == null) return null;
    hexCode = hexCode.replaceAll("#", "").trim();
    return Color(int.parse(hexCode, radix: 16) ^ 0xFF000000); // Add opacity
  }

  @override
  String toString() {
    return 'TriOSTheme{isDark: $isDark, primary: $primary, primaryVariant: $primaryVariant, secondary: $secondary, secondaryVariant: $secondaryVariant, background: $background, surface: $surface, error: $error, onPrimary: $onPrimary, onSecondary: $onSecondary, onBackground: $onBackground, onSurface: $onSurface, onError: $onError, hyperlink: $hyperlink}';
  }

  TriOSTheme copyWith({
    bool? isDark,
    Color? primary,
    Color? primaryVariant,
    Color? secondary,
    Color? secondaryVariant,
    Color? background,
    Color? surface,
    Color? error,
    Color? onPrimary,
    Color? onSecondary,
    Color? onBackground,
    Color? onSurface,
    Color? onError,
    Color? hyperlink,
  }) {
    return TriOSTheme(
      isDark: isDark ?? this.isDark,
      primary: primary ?? this.primary,
      primaryVariant: primaryVariant ?? this.primaryVariant,
      secondary: secondary ?? this.secondary,
      secondaryVariant: secondaryVariant ?? this.secondaryVariant,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      error: error ?? this.error,
      onPrimary: onPrimary ?? this.onPrimary,
      onSecondary: onSecondary ?? this.onSecondary,
      onBackground: onBackground ?? this.onBackground,
      onSurface: onSurface ?? this.onSurface,
      onError: onError ?? this.onError,
      hyperlink: hyperlink ?? this.hyperlink,
    );
  }
}
