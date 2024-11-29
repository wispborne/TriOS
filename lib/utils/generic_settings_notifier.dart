import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/utils/generic_settings_manager.dart';

abstract class GenericSettingsAsyncNotifier<T> extends AsyncNotifier<T> {
  late final GenericAsyncSettingsManager<T> settingsManager;

  /// Subclasses must provide the settings manager instance.
  GenericAsyncSettingsManager<T> createSettingsManager();

  @override
  Future<T> build() async {
    settingsManager = createSettingsManager();
    final settings = await settingsManager.load();
    return settings;
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
  late final GenericSettingsManager<T> settingsManager;

  /// Subclasses must provide the settings manager instance.
  GenericSettingsManager<T> createSettingsManager();

  @override
  T build() {
    settingsManager = createSettingsManager();
    settingsManager.loadSync();
    return settingsManager.state;
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
