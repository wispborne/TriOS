import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/models/mod_variant.dart';
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
///
/// So is whether the mod is enabled, since that decides where the source sits
/// in the merge order. Skipping it would hand back the old list after a toggle
/// and leave every merge showing the previous mod's data.
bool _sameSources(List<MergeSource> a, List<MergeSource> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i].key != b[i].key) return false;
    if (a[i].name != b[i].name) return false;
    if (a[i].isEnabled != b[i].isEnabled) return false;
    if (a[i].variant?.modFolder.path != b[i].variant?.modFolder.path) {
      return false;
    }
  }
  return true;
}

/// The last list handed out by [scanSourcesProvider], in a single-slot list so
/// it can be replaced. A provider for the same reason as [_lastSources].
final _lastScanSources = Provider<List<List<MergeSource>>>((ref) => []);

/// Every installed mod in load order, held still when a mod is only enabled or
/// disabled.
///
/// **Watch this instead of [orderedSourcesProvider] for anything that reads
/// files off disk.** Enabling or disabling a mod writes nothing to the mods
/// folder, so a scan started by a toggle would re-read every mod and find
/// exactly what it found last time. [orderedSourcesProvider] can't be used
/// there because a toggle does move a source within it — that's the whole
/// point of it — which would set off that pointless re-read.
///
/// Anything that *merges* has to watch [orderedSourcesProvider] instead, since
/// a toggle changes which source wins.
final scanSourcesProvider = Provider<List<MergeSource>>((ref) {
  final mods = ref.watch(AppState.mods);
  final sources = orderedSources(
    mods.map((mod) => mod.findFirstEnabledOrHighestVersion).nonNulls,
  );

  final holder = ref.watch(_lastScanSources);
  final last = holder.isEmpty ? null : holder.first;
  if (last != null && _sameSources(last, sources)) return last;
  holder
    ..clear()
    ..add(sources);
  return sources;
});

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
/// With [onlyEnabledMods] on, mods without an enabled variant are left out
/// entirely, so nothing they ship shows up in the lists at all.
///
/// With it off they stay in, because browsing what's installed but switched off
/// is the point of that mode — but they are marked as not enabled, which sorts
/// them behind the game core. A disabled mod then only supplies ids and files
/// no loaded source has, and can't rename a vanilla ship system or restyle
/// another mod's ship. See [MergeSource.isEnabled].
final orderedSourcesProvider = Provider.family<List<MergeSource>, bool>((
  ref,
  onlyEnabledMods,
) {
  final mods = ref.watch(AppState.mods);
  bool isEnabled(ModVariant variant) =>
      variant.mod(mods)?.hasEnabledVariant == true;

  final sources = orderedSources(
    mods
        .map((mod) => mod.findFirstEnabledOrHighestVersion)
        .nonNulls
        .where((variant) => !onlyEnabledMods || isEnabled(variant)),
    isEnabled: isEnabled,
  );

  final lastSources = ref.watch(_lastSources);
  final last = lastSources[onlyEnabledMods];
  if (last != null && _sameSources(last, sources)) return last;
  lastSources[onlyEnabledMods] = sources;
  return sources;
});
