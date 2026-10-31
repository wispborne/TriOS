import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart' show StateProvider;
import 'package:trios/catalog/models/catalog_extras.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/utils/app_worker.dart';
import 'package:trios/utils/cached_json_fetcher.dart';
import 'package:trios/utils/logging.dart';

final isLoadingCatalogExtras = StateProvider<bool>((ref) => false);

/// Shared fetcher for `mod-catalog-extras.json`. Exposed so the data-sources
/// dialog can show and clear its cache.
final catalogExtrasFetcher = CachedJsonFetcher(
  cacheFileName: 'mod_catalog_extras.json',
  metaFileName: 'mod_catalog_extras.meta',
  url: Constants.modCatalogExtrasUrl,
  maxAge: Duration(hours: 6),
  logTag: 'mod catalog extras',
);

/// Decodes and reads the extras file. Runs on the background worker, since
/// the file is several megabytes and would stall the UI.
CatalogExtrasFile _decodeCatalogExtras(String rawJson) =>
    parseCatalogExtrasFile(jsonDecode(rawJson) as Map<String, dynamic>);

/// The extras file. Emits nothing when it can't be downloaded or read, so the
/// catalog keeps working without it.
final catalogExtrasProvider = StreamProvider<CatalogExtrasFile>((ref) async* {
  final currentTime = DateTime.now();
  ref.watch(isLoadingCatalogExtras.notifier).state = true;
  String rawJson;

  try {
    rawJson = await catalogExtrasFetcher.fetch();
  } catch (ex, st) {
    Fimber.w('Failed to fetch mod catalog extras', ex: ex, stacktrace: st);
    ref.watch(isLoadingCatalogExtras.notifier).state = false;
    return;
  }

  try {
    final file = await ref
        .read(appWorkerProvider)
        .run(_decodeCatalogExtras, rawJson);

    ref.watch(isLoadingCatalogExtras.notifier).state = false;
    Fimber.i(
      'Parsed ${file.mods.length} mod catalog extras in '
      '${DateTime.now().difference(currentTime).inMilliseconds}ms',
    );

    yield file;
  } catch (ex, st) {
    Fimber.w('Failed to parse mod catalog extras', ex: ex, stacktrace: st);
    ref.watch(isLoadingCatalogExtras.notifier).state = false;
    return;
  }
});

/// Each catalog mod's extras record, keyed by catalog id. Empty when the file
/// isn't available.
final catalogExtrasByIdProvider = Provider<Map<String, CatalogExtras>>((ref) {
  return ref.watch(catalogExtrasProvider).value?.mods ?? const {};
});

/// True when the extras file loaded, TriOS knows its schema version, and it
/// holds at least one record.
final catalogExtrasAvailableProvider = Provider<bool>((ref) {
  return ref.watch(catalogExtrasByIdProvider).isNotEmpty;
});
