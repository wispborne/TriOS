import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trios/trios/MyTheme.dart';

// part 'generated/app_state.g.dart';

class AppState {
  static MyTheme theme = MyTheme();
}

final selfUpdateDownloadProgress = StateProvider<double?>((ref) => null);

/// Initialized in main.dart
late SharedPreferences sharedPrefs;

// @riverpod
// class SelfUpdateState extends _$SelfUpdateState {
//   @override
//   Future<double?> build() => null
//
// }
