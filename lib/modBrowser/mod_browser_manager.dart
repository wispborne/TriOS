import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/modBrowser/models/scraped_mod.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/trios/providers.dart';
import 'package:trios/utils/logging.dart';

final isLoadingBrowseModsList = StateProvider<bool>((ref) => false);

final browseModsNotifierProvider = StreamProvider<ScrapedModsRepo>((ref) async* {
  final currentTime = DateTime.now();
  ref.watch(isLoadingBrowseModsList.notifier).state = true;
  final httpClient = ref.read(triOSHttpClient);
  // todo add caching

  final modRepo = httpClient.get(Constants.modRepoUrl);

  final scrapedMods = ScrapedModsRepoMapper.fromJson((await modRepo).data.toString());

  ref.watch(isLoadingBrowseModsList.notifier).state = false;
  Fimber.i(
      'Parsed ${scrapedMods.items.length} scraped mods in ${DateTime.now().difference(currentTime).inMilliseconds}ms');

  yield scrapedMods;
});
