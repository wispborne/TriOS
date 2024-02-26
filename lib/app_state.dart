import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trios/trios/trios_theme.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/util.dart';

// part 'generated/app_state.g.dart';

class AppState {
  static TriOSTheme theme = TriOSTheme();
}

final selfUpdateDownloadProgress = StateProvider<double?>((ref) => null);

final gameFolderPath = StateProvider<Directory?>((ref) => defaultGamePath());

final modFolderPath =
    StateProvider<Directory?>((ref) => ref.read(gameFolderPath)?.let((value) => generateModFolderPath(value)));

/// Initialized in main.dart
late SharedPreferences sharedPrefs;

// @riverpod
// class SelfUpdateState extends _$SelfUpdateState {
//   @override
//   Future<double?> build() => null
//
// }
