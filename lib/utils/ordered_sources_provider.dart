import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/utils/game_data_merge.dart';

/// The last list handed out for each toggle value. See
/// [orderedSourcesProvider].
///
/// A provider rather than a plain top-level map so it belongs to the provider
/// container and is let go of when that container is thrown away.
final _lastSources = Provider<Map<bool, List<MergeSource>>>((ref) => {});

/// True when both lists name the same sources in the same order.
///
/// Compares what callers actually read off a source, not the objects
/// themselves: `AppState.mods` rebuilds its `Mod` objects every time, so an
/// object comparison would never match and the reuse below would never happen.
///
/// The folder path is checked too, because the key alone isn't enough. A
/// source's key is the variant's smolId, which covers the mod id and version
/// but not where it lives — so the same mod version reinstalled into a
/// differently named folder keeps its key while its files move.
bool _sameSources(List<MergeSource> a, List<MergeSource> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i].key != b[i].key) return false;
    if (a[i].name != b[i].name) return false;
    if (a[i].variant?.modFolder.path != b[i].variant?.modFolder.path) {
      return false;
    }
  }
  return true;
}

/// The sources to merge, in the game's load order, for the mods installed now.
///
/// **Watch this instead of `AppState.mods`** anywhere you only need the source
/// list. `AppState.mods` hands out a brand-new list whenever anything about any
/// mod changes — including enabling or disabling one — which is far more often
/// than the sources themselves change. This provider hands back the very same
/// list when the sources match last time's, so Riverpod sees an unchanged value
/// and doesn't re-run anything watching it.
///
/// That matters because the work behind these lists is slow: re-reading and
/// re-parsing a config file out of every mod folder, or merging every ship
/// again. Watching `AppState.mods` directly meant redoing all of it on every
/// toggle, for an answer that hadn't changed.
///
/// With [onlyEnabledMods] on, mods without an enabled variant are left out, so
/// a disabled mod can't override data it wouldn't override in the game.
final orderedSourcesProvider = Provider.family<List<MergeSource>, bool>((
  ref,
  onlyEnabledMods,
) {
  final mods = ref.watch(AppState.mods);
  final sources = orderedSources(
    mods
        .map((mod) => mod.findFirstEnabledOrHighestVersion)
        .nonNulls
        .where(
          (variant) =>
              !onlyEnabledMods || variant.mod(mods)?.hasEnabledVariant == true,
        ),
  );

  final lastSources = ref.watch(_lastSources);
  final last = lastSources[onlyEnabledMods];
  if (last != null && _sameSources(last, sources)) return last;
  lastSources[onlyEnabledMods] = sources;
  return sources;
});
