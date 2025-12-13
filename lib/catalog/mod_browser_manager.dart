// import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:flutter_riverpod/legacy.dart' show StateProvider;
import 'package:http/http.dart' as http;
import 'package:trios/catalog/models/scraped_mod.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/utils/logging.dart';

final isLoadingCatalog = StateProvider<bool>((ref) => false);

final browseModsNotifierProvider = StreamProvider<ScrapedModsRepo>((
  ref,
) async* {
  final currentTime = DateTime.now();
  ref.watch(isLoadingCatalog.notifier).state = true;
  // final cache = CacheManager(Config("trios_modrepo_cache"));
  String modRepo;

  try {
    // final cache = CacheManager(Config("trios_modrepo_cache"));
    modRepo = (await http.get(Uri.parse(Constants.modRepoUrl))).body;
    // (await cache.getSingleFile(Constants.modRepoUrl)).readAsStringSync();
  } catch (ex, st) {
    Fimber.w('Failed to fetch mod repo', ex: ex, stacktrace: st);
    ref.watch(isLoadingCatalog.notifier).state = false;
    // cache.emptyCache();
    return;
  }

  try {
    final scrapedMods = ScrapedModsRepoMapper.fromJson((modRepo).toString());

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
