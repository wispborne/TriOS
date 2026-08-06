import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override, ProviderListenable;

/// Builds a container set up the way the app's `ProviderScope` is, and disposes
/// it when the test ends.
///
/// Riverpod 3 retries a failing provider on its own, backing off up to 6.4
/// seconds between tries. `main.dart` turns that off, but a container built in a
/// test does not inherit the app's setting, so a test that expects an error
/// state would keep retrying and hang.
ProviderContainer createTestContainer({List<Override> overrides = const []}) =>
    ProviderContainer.test(
      overrides: overrides,
      retry: (retryCount, error) => null,
    );

/// Waits for [provider]'s first value and returns it.
///
/// Riverpod 3 pauses a provider's stream whenever nothing is listening to it, so
/// `container.read(someStreamProvider.future)` on its own never finishes in a
/// test. This holds a listener open, which is what lets the stream run. The
/// listener stays open until the container is disposed, so the provider does not
/// pause again partway through the test.
Future<T> awaitFirstValue<T>(
  ProviderContainer container,
  ProviderListenable<AsyncValue<T>> provider,
) {
  final completer = Completer<T>();

  container.listen(provider, fireImmediately: true, (previous, next) {
    if (completer.isCompleted) return;
    switch (next) {
      case AsyncData(:final value):
        completer.complete(value);
      case AsyncError(:final error, :final stackTrace):
        completer.completeError(error, stackTrace);
      case _:
        break;
    }
  });

  return completer.future;
}
