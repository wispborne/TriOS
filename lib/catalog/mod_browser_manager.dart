import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:trios/catalog/models/scraped_mod.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/utils/logging.dart';

final isLoadingCatalog = StateProvider<bool>((ref) => false);

final browseModsNotifierProvider = StreamProvider<ScrapedModsRepo>((
  ref,
) async* {
  final currentTime = DateTime.now();
  ref.watch(isLoadingCatalog.notifier).state = true;
  String modRepo;

  try {
    modRepo = await _fetchModRepoWithCache();
  } catch (ex, st) {
    Fimber.w('Failed to fetch mod repo', ex: ex, stacktrace: st);
    ref.watch(isLoadingCatalog.notifier).state = false;
    return;
  }

  try {
    final scrapedMods = ScrapedModsRepoMapper.fromJson(modRepo);

    ref.watch(isLoadingCatalog.notifier).state = false;
    Fimber.i(
      'Parsed ${scrapedMods.items.length} scraped mods in ${DateTime.now().difference(currentTime).inMilliseconds}ms',
    );

    yield scrapedMods;
  } catch (ex, st) {
    Fimber.w('Failed to parse mod repo', ex: ex, stacktrace: st);
    ref.watch(isLoadingCatalog.notifier).state = false;
    return;
  }
});

const _cacheMaxAge = Duration(hours: 1);

Future<String> _fetchModRepoWithCache() async {
  final cacheDir = Constants.cacheDirPath;
  final cacheFile = File(p.join(cacheDir.path, 'mod_repo.json'));
  final metaFile = File(p.join(cacheDir.path, 'mod_repo.meta'));

  // Try reading from cache.
  if (cacheFile.existsSync() && metaFile.existsSync()) {
    try {
      final meta = jsonDecode(metaFile.readAsStringSync());
      final cachedAt = DateTime.parse(meta['cachedAt'] as String);

      if (DateTime.now().difference(cachedAt) < _cacheMaxAge) {
        Fimber.i('Using cached mod repo (cached ${DateTime.now().difference(cachedAt).inMinutes}m ago)');
        return cacheFile.readAsStringSync();
      }
    } catch (e) {
      Fimber.w('Failed to read mod repo cache, will re-fetch', ex: e);
    }
  }

  // Fetch fresh data.
  final response = await http.get(Uri.parse(Constants.modRepoUrl));
  final body = response.body;

  // Write to cache.
  try {
    if (!cacheDir.existsSync()) {
      cacheDir.createSync(recursive: true);
    }
    cacheFile.writeAsStringSync(body);
    metaFile.writeAsStringSync(jsonEncode({'cachedAt': DateTime.now().toIso8601String()}));
  } catch (e) {
    Fimber.w('Failed to write mod repo cache', ex: e);
  }

  return body;
}
