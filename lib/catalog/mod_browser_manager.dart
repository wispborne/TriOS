import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/catalog/models/scraped_mod.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/utils/cached_json_fetcher.dart';
import 'package:trios/utils/logging.dart';

final isLoadingCatalog = StateProvider<bool>((ref) => false);

/// Shared fetcher for Wisp's mod repo. Exposed so the data-sources dialog
/// can introspect and clear its cache without duplicating file-name wiring.
final modRepoFetcher = CachedJsonFetcher(
  cacheFileName: 'mod_repo.json',
  metaFileName: 'mod_repo.meta',
  url: Constants.modRepoUrl,
  maxAge: Duration(hours: 6),
  logTag: 'mod repo',
);

final browseModsNotifierProvider = StreamProvider<ScrapedModsRepo>((
  ref,
) async* {
  final currentTime = DateTime.now();
  ref.watch(isLoadingCatalog.notifier).state = true;
  String modRepo;

  try {
    modRepo = await modRepoFetcher.fetch();
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
