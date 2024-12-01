import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/utils/generic_settings_manager.dart';
import 'package:trios/utils/logging.dart';

abstract class GenericSettingsAsyncNotifier<T> extends AsyncNotifier<T> {
  late GenericAsyncSettingsManager<T> settingsManager;

  /// Subclasses must provide the settings manager instance.
  GenericAsyncSettingsManager<T> createSettingsManager();

  GenericSettingsAsyncNotifier() {
    settingsManager = createSettingsManager();
  }

  @override
  Future<T> build() async {
    try {
      final settings = await settingsManager.readSettingsFromDisk();
      return settings;
    } catch (e, stackTrace) {
      state = AsyncError(e, stackTrace);
      Fimber.w("Error building settings notifier",
          ex: e, stacktrace: stackTrace);
      rethrow;
    }
  }

  /// Updates the current state using the provided mutator function and persists the updated state to disk.
  @override
  Future<T> update(
    FutureOr<T> Function(T currentState) mutator, {
    FutureOr<T> Function(Object, StackTrace)? onError,
  }) async {
    final newState = await settingsManager.update(mutator, onError: onError);

    state = AsyncData(newState);

    return newState;
  }

  /// Provides access to the current settings state.
  T get currentState => settingsManager.state;
}

abstract class GenericSettingsNotifier<T> extends Notifier<T> {
  late GenericSettingsManager<T> settingsManager;

  /// Subclasses must provide the settings manager instance.
  GenericSettingsManager<T> createSettingsManager();

  GenericSettingsNotifier() {
    settingsManager = createSettingsManager();
  }

  @override
  T build() {
    try {
      settingsManager.loadSync();
      return settingsManager.state;
    } catch (e, stackTrace) {
      Fimber.w("Error building settings notifier",
          ex: e, stacktrace: stackTrace);
      rethrow;
    }
  }

  /// Updates the current state using the provided mutator function and persists the updated state to disk.
  T update(
    T Function(T currentState) mutator, {
    T Function(Object, StackTrace)? onError,
  }) {
    try {
      final newState = settingsManager.updateSync(mutator, onError: onError);

      state = newState; // Notify listeners
      return newState;
    } catch (e, stackTrace) {
      if (onError != null) {
        return onError(e, stackTrace);
      }
      rethrow;
    }
  }

  /// Provides access to the current settings state.
  T get currentState => settingsManager.state;
}
