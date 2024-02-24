import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:trios/models/file_download.dart';

// part 'generated/app_state.g.dart';

final selfUpdateDownloadProgress = StateProvider<double?>((ref) => null);

// @riverpod
// class SelfUpdateState extends _$SelfUpdateState {
//   @override
//   Future<double?> build() => null
//
// }
