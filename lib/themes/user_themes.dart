import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart' as p;
import 'package:trios/themes/theme.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/logging.dart';

/// What one read of the user themes file produced: the themes that loaded, and
/// a plain-English line for each one that didn't.
typedef UserThemesReadResult = ({
  List<TriOSTheme> themes,
  List<String> problems,
});

/// Themes people write themselves.
///
/// These live in the config folder rather than the asset bundle, because the
/// bundle sits in the install folder and every update replaces it. TriOS writes
/// this file once, when it isn't there yet, and never again — so comments and
/// formatting the user adds stay put. Adding a theme is done by pasting, not by
/// TriOS rewriting the file.
class UserThemes {
  static const fileName = 'trios_themes-v1.json';

  /// Goes in front of the user's own key when the theme is saved, so their key
  /// can never collide with a built-in theme's name.
  static const idPrefix = 'user:';

  /// Without these two a theme can't be built at all, so they're checked before
  /// anything reaches the theme picker.
  static const _requiredFields = ['primary', 'surfaceContainer'];

  static File get file =>
      File(p.join(Constants.configDataFolderPath.path, fileName));

  /// Reads every theme in the file. A theme with a mistake in it is skipped and
  /// described in `problems`; the rest still load.
  static Future<UserThemesReadResult> read() async {
    final themeFile = file;
    final themes = <TriOSTheme>[];
    final problems = <String>[];

    if (!await themeFile.exists()) {
      await _writeStarterFile(themeFile);
      return (themes: themes, problems: problems);
    }

    Map<String, dynamic> json;
    try {
      json = await (await themeFile.readAsString()).parseJsonToMapAsync();
    } catch (e, st) {
      Fimber.w("Couldn't read $fileName.", ex: e, stacktrace: st);
      problems.add("Couldn't read $fileName. It isn't valid JSON.");
      return (themes: themes, problems: problems);
    }

    final entries = json['themes'];
    if (entries is! Map) {
      problems.add("$fileName has no \"themes\" section.");
      return (themes: themes, problems: problems);
    }

    for (final entry in entries.entries) {
      final key = entry.key.toString();
      try {
        final data = entry.value as Map<String, dynamic>;

        final missing = _requiredFields
            .where((field) => data[field] == null)
            .toList();
        if (missing.isNotEmpty) {
          problems.add(
            'Couldn\'t load "$key": ${missing.join(" and ")} '
            '${missing.length == 1 ? "is" : "are"} missing.',
          );
          continue;
        }

        themes.add(
          TriOSTheme.fromHexCodes(
            id: "$idPrefix$key",
            displayName: data['displayName'] as String? ?? key,
            isDark: data['isDark'] ?? true,
            primary: data['primary'],
            secondary: data['secondary'],
            surface: data['surface'],
            surfaceContainer: data['surfaceContainer'],
            onPrimary: data['onPrimary'],
            onSecondary: data['onSecondary'],
            onSurface: data['onSurface'],
            fontFamily: data['fontFamily'],
            rainbowAccent: data['rainbowAccent'] ?? false,
            appNameOverride: data['appNameOverride'],
            isUserTheme: true,
            successSeed: data['successSeed'],
            warningSeed: data['warningSeed'],
            infoSeed: data['infoSeed'],
            neutralSeed: data['neutralSeed'],
          ),
        );
      } catch (e, st) {
        Fimber.w("Couldn't load user theme '$key'.", ex: e, stacktrace: st);
        problems.add('Couldn\'t load "$key": $e');
      }
    }

    Fimber.i("Loaded ${themes.length} user themes from $fileName.");
    return (themes: themes, problems: problems);
  }

  /// One theme written out ready to paste into the "themes" section of the
  /// user's file. Only the fields [theme] actually sets are included — filling
  /// in the rest would change how it looks, because TriOS works some colors out
  /// differently depending on whether a neighbouring one was given.
  static String asPasteableEntry(TriOSTheme theme) {
    final lines = <String>[
      '"displayName": "${theme.displayName} (copy)"',
      '"isDark": ${theme.isDark}',
      '"primary": "${_hex(theme.primary)}"',
      if (theme.secondary != null) '"secondary": "${_hex(theme.secondary!)}"',
      if (theme.surface != null) '"surface": "${_hex(theme.surface!)}"',
      if (theme.surfaceContainer != null)
        '"surfaceContainer": "${_hex(theme.surfaceContainer!)}"',
      if (theme.onPrimary != null) '"onPrimary": "${_hex(theme.onPrimary!)}"',
      if (theme.onSecondary != null)
        '"onSecondary": "${_hex(theme.onSecondary!)}"',
      if (theme.onSurface != null) '"onSurface": "${_hex(theme.onSurface!)}"',
      if (theme.successSeed != null)
        '"successSeed": "${_hex(theme.successSeed!)}"',
      if (theme.warningSeed != null)
        '"warningSeed": "${_hex(theme.warningSeed!)}"',
      if (theme.infoSeed != null) '"infoSeed": "${_hex(theme.infoSeed!)}"',
      if (theme.fontFamily != null) '"fontFamily": "${theme.fontFamily}"',
      if (theme.rainbowAccent) '"rainbowAccent": true',
      if (theme.appNameOverride != null)
        '"appNameOverride": "${theme.appNameOverride}"',
    ];

    final body = lines.map((line) => '      $line').join(',\n');
    return '    "${_slugify(theme.displayName)}-copy": {\n$body\n    },';
  }

  static String _hex(Color color) =>
      "#${color.toHex(leadingHashSign: false).substring(2).toUpperCase()}";

  static String _slugify(String name) => name
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');

  static Future<void> _writeStarterFile(File themeFile) async {
    try {
      await themeFile.parent.create(recursive: true);
      await themeFile.writeAsString(_starterFileContents);
      Fimber.i("Created $fileName at ${themeFile.path}.");
    } catch (e, st) {
      Fimber.w("Couldn't create $fileName.", ex: e, stacktrace: st);
    }
  }

  static const _starterFileContents = '''
// Your own TriOS themes. Add entries under "themes" below.
//
// Colours are hex, with or without the leading #.
//
//   primary           Required. The main accent: buttons, links, the app icon.
//   surfaceContainer  Required. Behind cards, panels, and the window itself.
//   displayName       What the theme is called in the picker.
//   isDark            true for a dark theme, false for a light one.
//   secondary         A second accent, used for a few highlights.
//   surface           Behind scrolling content.
//   onPrimary         Text and icons drawn on top of primary.
//   onSecondary       Text and icons drawn on top of secondary.
//   onSurface         Text and icons drawn on top of surface.
//   successSeed       Base colour for "good" badges.
//   warningSeed       Base colour for "needs attention" badges.
//   infoSeed          Base colour for informational badges.
//   fontFamily        A font installed on your system, e.g. "Comic Sans MS".
//   rainbowAccent     true to draw the rainbow accent bar.
//   appNameOverride   Renames the app while this theme is active.
//
// Leave anything else out and TriOS works it out from primary.
// Press "Reload themes" in Settings after editing.

{
  "themes": {
    // "my-theme": {
    //   "displayName": "My Theme",
    //   "isDark": true,
    //   "primary": "#1080D6",
    //   "secondary": "#2BE394",
    //   "surface": "#042138",
    //   "surfaceContainer": "#282C34"
    // }
  }
}
''';
}
