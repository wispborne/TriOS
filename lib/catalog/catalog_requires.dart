import 'package:trios/catalog/catalog_links.dart';
import 'package:trios/catalog/models/catalog_extras.dart';
import 'package:trios/catalog/models/catalog_mod.dart';
import 'package:trios/utils/extensions.dart';

/// The Dependencies chip for mods that need no other mods. Starts with an
/// underscore, so it can't match a catalog id or a name key.
const String kRequiresStandalone = '_standalone';

/// The Dependencies chip key for a required mod written as [name], when it has
/// no catalog id. Uses the catalog's own name key, so "LazyLib", "Lazy Lib"
/// and "LazyLib v2.8" share a chip. A name with no English letters or numbers
/// falls back to the name itself, lowercased.
String requiresNameKey(String name) {
  final key = catalogNameMatchKey(name);
  return key.isNotEmpty ? key : catalogEntryKey(name);
}

/// The chip key for one required mod: its catalog id, or the id of the one
/// catalog mod with that name (from [idsByNameKey]), or [requiresNameKey] of
/// its name. Empty when none of those gives anything.
String _keyFor(CatalogNeed need, Map<String, String> idsByNameKey) {
  final id = need.id?.trim();
  if (id != null && id.isNotEmpty) return id;
  final nameKey = requiresNameKey(need.name);
  return idsByNameKey[nameKey] ?? nameKey;
}

/// The Dependencies chip values for [mod]:
/// - one key per required mod, from [_keyFor]
/// - [kRequiresStandalone] when the mod has an AI answer or an extras record,
///   and requires nothing
/// - nothing when there's no answer either way
///
/// [idsByNameKey] maps a [requiresNameKey] to a catalog id. See
/// [catalogIdsByNameKey].
List<String> requiresChipKeys(
  CatalogMod mod, {
  Map<String, String> idsByNameKey = const {},
}) {
  final needs = mod.requiredMods;
  if (needs.isEmpty) {
    final hasAnswer = mod.llmMod != null || mod.extras != null;
    return hasAnswer ? const [kRequiresStandalone] : const [];
  }
  return {
    for (final need in needs)
      if (_keyFor(need, idsByNameKey) case final key when key.isNotEmpty) key,
  }.toList();
}

/// [requiresNameKey] of each catalog mod's name, to its catalog id. A name
/// that more than one catalog mod uses is left out, since there's no telling
/// which one is meant.
Map<String, String> catalogIdsByNameKey(List<CatalogMod> mods) {
  final ids = <String, String>{};
  final shared = <String>{};
  for (final mod in mods) {
    final id = mod.entry.id;
    if (id == null || id.isEmpty) continue;
    final key = requiresNameKey(mod.entry.name);
    if (key.isEmpty || shared.contains(key)) continue;
    if (ids.containsKey(key)) {
      ids.remove(key);
      shared.add(key);
    } else {
      ids[key] = id;
    }
  }
  return ids;
}

/// Each mod's Dependencies chip values, plus each chip's label and count,
/// worked out once from every mod.
class RequiresChipInfo {
  final Map<CatalogMod, List<String>> _keysByMod;

  /// Chip key to the name shown on the chip.
  final Map<String, String> labels;

  /// Chip key to how many mods have that value.
  final Map<String, int> counts;

  /// Chip key to its label, lowercased, for sorting.
  final Map<String, String> _sortLabels;

  const RequiresChipInfo()
    : _keysByMod = const {},
      labels = const {},
      counts = const {},
      _sortLabels = const {};

  RequiresChipInfo._(this._keysByMod, this.labels, this.counts)
    : _sortLabels = {
        for (final e in labels.entries) e.key: e.value.toLowerCase(),
      };

  /// [mod]'s chip values. Empty for a mod that wasn't in the list.
  List<String> keysFor(CatalogMod mod) => _keysByMod[mod] ?? const [];

  /// Labels a chip key. Unknown keys show as-is.
  String labelFor(String key) => labels[key] ?? key;

  /// Standalone first, then the most needed, then by label.
  int compare(String a, String b) {
    if (a == b) return 0;
    if (a == kRequiresStandalone) return -1;
    if (b == kRequiresStandalone) return 1;
    final byCount = (counts[b] ?? 0).compareTo(counts[a] ?? 0);
    if (byCount != 0) return byCount;
    return (_sortLabels[a] ?? a).compareTo(_sortLabels[b] ?? b);
  }

  /// Builds the chip values, labels and counts from [mods].
  ///
  /// A chip for a catalog id is labelled with that catalog mod's name. Any
  /// other chip uses the spelling most mods wrote.
  factory RequiresChipInfo.from(List<CatalogMod> mods) {
    final idsByNameKey = catalogIdsByNameKey(mods);
    final namesById = {for (final mod in mods) mod.entry.id: mod.title};
    final keysByMod = <CatalogMod, List<String>>{};
    final counts = <String, int>{};
    final spellings = <String, Map<String, int>>{};

    for (final mod in mods) {
      final keys = requiresChipKeys(mod, idsByNameKey: idsByNameKey);
      keysByMod[mod] = keys;
      for (final key in keys) {
        counts[key] = (counts[key] ?? 0) + 1;
      }
      for (final need in mod.requiredMods) {
        final key = _keyFor(need, idsByNameKey);
        final name = need.name.trim();
        if (key.isEmpty || name.isEmpty) continue;
        final forKey = spellings.putIfAbsent(key, () => {});
        forKey[name] = (forKey[name] ?? 0) + 1;
      }
    }

    final labels = <String, String>{kRequiresStandalone: 'Standalone'};
    for (final key in counts.keys) {
      if (key == kRequiresStandalone) continue;
      final catalogName = namesById[key];
      if (catalogName != null && catalogName.isNotEmpty) {
        labels[key] = catalogName;
      } else if (spellings[key]?.entries.maxByOrNull((e) => e.value)
          case final mostCommon?) {
        labels[key] = mostCommon.key;
      }
    }
    return RequiresChipInfo._(keysByMod, labels, counts);
  }
}
