import 'dart:ui';

/// Material Design 3 color scheme for TriOS themes.
///
/// @property primary The primary color displayed most frequently across the app.
/// @property secondary Accent color for distinguishing elements (FABs, selection controls, links).
/// @property surface The base surface color (behind scrollable content).
/// @property surfaceContainer Background color for components like cards, sheets, and menus.
/// @property error Color indicating errors within components.
/// @property onPrimary Color for text/icons on top of primary.
/// @property onSecondary Color for text/icons on top of secondary.
/// @property onSurface Color for text/icons on top of surface.
/// @property onError Color for text/icons on top of error.
/// @property isDark Whether this is a dark or light theme.
class TriOSTheme {
  final bool isDark;
  final Color primary;
  final Color? secondary;
  final Color? surface;
  final Color? surfaceContainer;
  final Color? error;
  final Color? onPrimary;
  final Color? onSecondary;
  final Color? onSurface;
  final Color? onError;

  TriOSTheme({
    this.isDark = true,
    required this.primary,
    this.secondary,
    this.surface,
    this.surfaceContainer,
    this.error,
    this.onPrimary,
    this.onSecondary,
    this.onSurface,
    this.onError,
  });

  /// Constructor that accepts hex color strings (e.g. "#FF0000").
  TriOSTheme.fromHexCodes({
    required this.isDark,
    required String primary,
    String? secondary,
    String? surface,
    String? surfaceContainer,
    String? error,
    String? onPrimary,
    String? onSecondary,
    String? onSurface,
    String? onError,
  }) : primary = _parseColor(primary)!,
       secondary = _parseColor(secondary),
       surface = _parseColor(surface),
       surfaceContainer = _parseColor(surfaceContainer),
       error = _parseColor(error),
       onPrimary = _parseColor(onPrimary),
       onSecondary = _parseColor(onSecondary),
       onSurface = _parseColor(onSurface),
       onError = _parseColor(onError);

  static Color? _parseColor(String? hexCode) {
    if (hexCode == null) return null;
    hexCode = hexCode.replaceAll("#", "").trim();
    return Color(int.parse(hexCode, radix: 16) ^ 0xFF000000); // Add opacity
  }

  @override
  String toString() {
    return 'TriOSTheme{isDark: $isDark, primary: $primary, secondary: $secondary, surface: $surface, surfaceContainer: $surfaceContainer, error: $error, onPrimary: $onPrimary, onSecondary: $onSecondary, onSurface: $onSurface, onError: $onError}';
  }

  TriOSTheme copyWith({
    bool? isDark,
    Color? primary,
    Color? secondary,
    Color? surface,
    Color? surfaceContainer,
    Color? error,
    Color? onPrimary,
    Color? onSecondary,
    Color? onSurface,
    Color? onError,
  }) {
    return TriOSTheme(
      isDark: isDark ?? this.isDark,
      primary: primary ?? this.primary,
      secondary: secondary ?? this.secondary,
      surface: surface ?? this.surface,
      surfaceContainer: surfaceContainer ?? this.surfaceContainer,
      error: error ?? this.error,
      onPrimary: onPrimary ?? this.onPrimary,
      onSecondary: onSecondary ?? this.onSecondary,
      onSurface: onSurface ?? this.onSurface,
      onError: onError ?? this.onError,
    );
  }
}
