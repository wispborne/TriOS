import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/utils/generic_settings_manager.dart';
import 'package:trios/utils/logging.dart';

abstract class GenericSettingsAsyncNotifier<T> extends AsyncNotifier<T> {
  late final GenericAsyncSettingsManager<T> settingsManager;
  bool _isInitialized = false;

  /// Subclasses must provide the settings manager instance.
  GenericAsyncSettingsManager<T> createSettingsManager();

  /// Subclasses must provide the default state.
  T createDefaultState();

  GenericSettingsAsyncNotifier() {
    settingsManager = createSettingsManager();
  }

  @override
  Future<T> build() async {
    if (!_isInitialized) {
      state = AsyncValue.loading();
      Fimber.i("Building settings notifier: $runtimeType");
      try {
        final loadedState =
            await settingsManager.readSettingsFromDisk(createDefaultState());
        state = AsyncData(loadedState);
        _isInitialized = true;
        return loadedState;
      } catch (e, stackTrace) {
        state = AsyncError(e, stackTrace);
        Fimber.w("Error building settings notifier",
            ex: e, stacktrace: stackTrace);
        rethrow;
      }
    } else {
      return state.requireValue;
    }
  }

  Future<T> updateState(
    FutureOr<T> Function(T currentState) mutator, {
    FutureOr<T> Function(Object, StackTrace)? onError,
  }) async {
    final oldValue = state.valueOrNull ?? createDefaultState();
    try {
      final newValue = await mutator(oldValue);
      if (newValue.hashCode != oldValue.hashCode) {
        state = AsyncData(newValue);
        settingsManager.scheduleWriteSettingsToDisk(newValue);
      } else {
        Fimber.d("No settings change detected.");
      }
      return newValue;
    } catch (e, stackTrace) {
      if (onError != null) {
        return await onError(e, stackTrace);
      } else {
        Fimber.e("Error during settings update: $e",
            ex: e, stacktrace: stackTrace);
        rethrow;
      }
    }
  }
}
