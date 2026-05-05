import 'dart:ui';

import 'package:flutter/material.dart';

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
/// @property rainbowAccent Whether to show a rainbow gradient accent bar.
class TriOSTheme {
  final String id;
  final String displayName;
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
  final String? fontFamily;
  final bool rainbowAccent;
  final String? iconAsset;
  final String? appNameOverride;

  // Semantic status color seeds (optional overrides).
  final Color? successSeed;
  final Color? warningSeed;
  final Color? infoSeed;
  final Color? neutralSeed;

  TriOSTheme({
    required this.id,
    required this.displayName,
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
    this.fontFamily,
    this.rainbowAccent = false,
    this.iconAsset,
    this.appNameOverride,
    this.successSeed,
    this.warningSeed,
    this.infoSeed,
    this.neutralSeed,
  });

  /// Constructor that accepts hex color strings (e.g. "#FF0000").
  TriOSTheme.fromHexCodes({
    required this.id,
    required this.displayName,
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
    this.fontFamily,
    this.rainbowAccent = false,
    this.iconAsset,
    this.appNameOverride,
    String? successSeed,
    String? warningSeed,
    String? infoSeed,
    String? neutralSeed,
  }) : primary = _parseColor(primary)!,
       secondary = _parseColor(secondary),
       surface = _parseColor(surface),
       surfaceContainer = _parseColor(surfaceContainer),
       error = _parseColor(error),
       onPrimary = _parseColor(onPrimary),
       onSecondary = _parseColor(onSecondary),
       onSurface = _parseColor(onSurface),
       onError = _parseColor(onError),
       successSeed = _parseColor(successSeed),
       warningSeed = _parseColor(warningSeed),
       infoSeed = _parseColor(infoSeed),
       neutralSeed = _parseColor(neutralSeed);

  static Color? _parseColor(String? hexCode) {
    if (hexCode == null) return null;
    hexCode = hexCode.replaceAll("#", "").trim();
    return Color(int.parse(hexCode, radix: 16) | 0xFF000000); // Ensure full opacity
  }

  @override
  String toString() {
    return 'TriOSTheme{id: $id, displayName: $displayName, isDark: $isDark, primary: $primary, secondary: $secondary, surface: $surface, surfaceContainer: $surfaceContainer, error: $error, onPrimary: $onPrimary, onSecondary: $onSecondary, onSurface: $onSurface, onError: $onError, fontFamily: $fontFamily, rainbowAccent: $rainbowAccent, successSeed: $successSeed, warningSeed: $warningSeed, infoSeed: $infoSeed, neutralSeed: $neutralSeed}';
  }

  TriOSTheme copyWith({
    String? id,
    String? displayName,
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
    String? fontFamily,
    bool? rainbowAccent,
    String? iconAsset,
    String? appNameOverride,
    Color? successSeed,
    Color? warningSeed,
    Color? infoSeed,
    Color? neutralSeed,
  }) {
    return TriOSTheme(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
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
      fontFamily: fontFamily ?? this.fontFamily,
      rainbowAccent: rainbowAccent ?? this.rainbowAccent,
      iconAsset: iconAsset ?? this.iconAsset,
      appNameOverride: appNameOverride ?? this.appNameOverride,
      successSeed: successSeed ?? this.successSeed,
      warningSeed: warningSeed ?? this.warningSeed,
      infoSeed: infoSeed ?? this.infoSeed,
      neutralSeed: neutralSeed ?? this.neutralSeed,
    );
  }
}

/// Theme extension to expose custom TriOS theme properties via [Theme.of].
class TriOSThemeExtension extends ThemeExtension<TriOSThemeExtension> {
  final bool rainbowAccent;
  final String? iconAsset;
  final String? appNameOverride;

  // Success
  final Color success;
  final Color onSuccess;
  final Color successContainer;
  final Color onSuccessContainer;

  // Warning
  final Color warning;
  final Color onWarning;
  final Color warningContainer;
  final Color onWarningContainer;

  // Info
  final Color info;
  final Color onInfo;
  final Color infoContainer;
  final Color onInfoContainer;

  // Neutral
  final Color neutral;
  final Color onNeutral;
  final Color neutralContainer;
  final Color onNeutralContainer;

  const TriOSThemeExtension({
    this.rainbowAccent = false,
    this.iconAsset,
    this.appNameOverride,
    this.success = const Color(0xFF4CAF50),
    this.onSuccess = const Color(0xFFFFFFFF),
    this.successContainer = const Color(0xFF4CAF50),
    this.onSuccessContainer = const Color(0xFF000000),
    this.warning = const Color(0xFFFDD818),
    this.onWarning = const Color(0xFF000000),
    this.warningContainer = const Color(0xFFFDD818),
    this.onWarningContainer = const Color(0xFF000000),
    this.info = const Color(0xFF2196F3),
    this.onInfo = const Color(0xFFFFFFFF),
    this.infoContainer = const Color(0xFF2196F3),
    this.onInfoContainer = const Color(0xFF000000),
    this.neutral = const Color(0xFF9E9E9E),
    this.onNeutral = const Color(0xFFFFFFFF),
    this.neutralContainer = const Color(0xFF9E9E9E),
    this.onNeutralContainer = const Color(0xFF000000),
  });

  @override
  TriOSThemeExtension copyWith({
    bool? rainbowAccent,
    String? iconAsset,
    String? appNameOverride,
    Color? success,
    Color? onSuccess,
    Color? successContainer,
    Color? onSuccessContainer,
    Color? warning,
    Color? onWarning,
    Color? warningContainer,
    Color? onWarningContainer,
    Color? info,
    Color? onInfo,
    Color? infoContainer,
    Color? onInfoContainer,
    Color? neutral,
    Color? onNeutral,
    Color? neutralContainer,
    Color? onNeutralContainer,
  }) {
    return TriOSThemeExtension(
      rainbowAccent: rainbowAccent ?? this.rainbowAccent,
      iconAsset: iconAsset ?? this.iconAsset,
      appNameOverride: appNameOverride ?? this.appNameOverride,
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      successContainer: successContainer ?? this.successContainer,
      onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
      warning: warning ?? this.warning,
      onWarning: onWarning ?? this.onWarning,
      warningContainer: warningContainer ?? this.warningContainer,
      onWarningContainer: onWarningContainer ?? this.onWarningContainer,
      info: info ?? this.info,
      onInfo: onInfo ?? this.onInfo,
      infoContainer: infoContainer ?? this.infoContainer,
      onInfoContainer: onInfoContainer ?? this.onInfoContainer,
      neutral: neutral ?? this.neutral,
      onNeutral: onNeutral ?? this.onNeutral,
      neutralContainer: neutralContainer ?? this.neutralContainer,
      onNeutralContainer: onNeutralContainer ?? this.onNeutralContainer,
    );
  }

  @override
  TriOSThemeExtension lerp(TriOSThemeExtension? other, double t) {
    if (other == null) return this;
    return TriOSThemeExtension(
      rainbowAccent: t < 0.5 ? rainbowAccent : other.rainbowAccent,
      iconAsset: t < 0.5 ? iconAsset : other.iconAsset,
      appNameOverride: t < 0.5 ? appNameOverride : other.appNameOverride,
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      successContainer: Color.lerp(successContainer, other.successContainer, t)!,
      onSuccessContainer: Color.lerp(onSuccessContainer, other.onSuccessContainer, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
      warningContainer: Color.lerp(warningContainer, other.warningContainer, t)!,
      onWarningContainer: Color.lerp(onWarningContainer, other.onWarningContainer, t)!,
      info: Color.lerp(info, other.info, t)!,
      onInfo: Color.lerp(onInfo, other.onInfo, t)!,
      infoContainer: Color.lerp(infoContainer, other.infoContainer, t)!,
      onInfoContainer: Color.lerp(onInfoContainer, other.onInfoContainer, t)!,
      neutral: Color.lerp(neutral, other.neutral, t)!,
      onNeutral: Color.lerp(onNeutral, other.onNeutral, t)!,
      neutralContainer: Color.lerp(neutralContainer, other.neutralContainer, t)!,
      onNeutralContainer: Color.lerp(onNeutralContainer, other.onNeutralContainer, t)!,
    );
  }
}
