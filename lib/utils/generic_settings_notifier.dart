import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mutex/mutex.dart';
import 'package:trios/utils/generic_settings_manager.dart';
import 'package:trios/utils/logging.dart';

abstract class GenericSettingsAsyncNotifier<T> extends AsyncNotifier<T> {
  late final GenericAsyncSettingsManager<T> settingsManager;
  bool _isInitialized = false;

  /// Serializes [updateState] calls so concurrent callers with async mutators
  /// can't interleave across awaits and drop each other's changes.
  final _updateMutex = Mutex();

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
        final loadedState = await settingsManager.read(
          createDefaultState(),
        );
        state = AsyncData(loadedState);
        _isInitialized = true;
        // Create a backup on initial load (max of once every 30 mins), just in case something catastrophic happens during runtime and wipes the main one.
        try {
          if (!settingsManager.getBackupFile().existsSync() ||
              DateTime.now().difference(
                    settingsManager.getBackupFile().lastModifiedSync(),
                  ) >
                  Duration(minutes: 30)) {
            settingsManager.createBackup();
          }
        } catch (e, stackTrace) {
          Fimber.w("Error creating backup", ex: e, stacktrace: stackTrace);
        }
        return loadedState;
      } catch (e, stackTrace) {
        state = AsyncError(e, stackTrace);
        Fimber.w(
          "Error building settings notifier",
          ex: e,
          stacktrace: stackTrace,
        );
        rethrow;
      }
    } else {
      return state.requireValue;
    }
  }

  /// Apply [mutator] to the current state and schedule a write.
  ///
  /// By default, a `hashCode` equality check skips the write (and listener
  /// notification) when the mutator returns a structurally identical
  /// value. For small models that check is free, but for large
  /// dart_mappable states (e.g. the VRAM cache with its full image table)
  /// the structural hash walks the whole graph and can dominate CPU. Pass
  /// [skipChangeCheck] = true on hot paths where the caller already knows
  /// the state changed.
  Future<T> updateState(
    FutureOr<T> Function(T currentState) mutator, {
    FutureOr<T> Function(Object, StackTrace)? onError,
    bool skipChangeCheck = false,
  }) async {
    return _updateMutex.protect(() async {
      final oldValue = state.value ?? createDefaultState();
      try {
        final newValue = await mutator(oldValue);
        if (skipChangeCheck || newValue.hashCode != oldValue.hashCode) {
          state = AsyncData(newValue);
          settingsManager.scheduleWrite(newValue);
        } else {
          Fimber.v(() => "No settings change detected.");
        }
        return newValue;
      } catch (e, stackTrace) {
        if (onError != null) {
          return await onError(e, stackTrace);
        } else {
          Fimber.e(
            "Error during settings update: $e",
            ex: e,
            stacktrace: stackTrace,
          );
          rethrow;
        }
      }
    });
  }
}
