import 'dart:collection';

import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/mod_tag_manager/mod_tag.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/utils/generic_settings_manager.dart';
import 'package:trios/utils/generic_settings_notifier.dart';
import 'package:trios/utils/logging.dart';

part 'mod_tag_manager.mapper.dart';

/// Riverpod provider for the ModTagStore (async-loaded, then cached in memory).
final modTagManagerProvider =
    AsyncNotifierProvider<ModTagStoreNotifier, ModTagStore>(
      ModTagStoreNotifier.new,
    );

/// Persisted store model for tags and associations
@MappableClass()
class ModTagStore with ModTagStoreMappable {
  /// Master list of all tags known to the system
  final List<ModTag> masterTags;

  /// Mapping of modId -> set of tagIds
  final Map<String, Set<String>> tagsByModId;

  ModTagStore({required this.masterTags, required this.tagsByModId});
}

/// Settings manager to persist ModTagStore on disk
class _ModTagSettings extends GenericAsyncSettingsManager<ModTagStore> {
  @override
  FileFormat get fileFormat => FileFormat.json;

  @override
  String get fileName => 'mod_tags.json';

  @override
  ModTagStore Function(Map<String, dynamic> map) get fromMap =>
      ModTagStoreMapper.fromMap;

  @override
  Map<String, dynamic> Function(ModTagStore obj) get toMap =>
      (s) => s.toMap();
}

// ... existing code ...

/// Main store for mod tags, loaded once and then operated on in-memory.
/// Exposes synchronous methods that act on the cached state and schedule persistence.
class ModTagStoreNotifier extends GenericSettingsAsyncNotifier<ModTagStore> {
  @override
  GenericAsyncSettingsManager<ModTagStore> createSettingsManager() =>
      _ModTagSettings();

  @override
  Future<ModTagStore> build() async {
    final t0 = DateTime.now().millisecondsSinceEpoch;
    final loaded = await super.build();
    Fimber.d(
      "Loaded ModTagStore in ${DateTime.now().millisecondsSinceEpoch - t0}ms.",
    );
    return loaded;
  }

  @override
  ModTagStore createDefaultState() =>
      ModTagStore(masterTags: [], tagsByModId: {});

  // ------- Synchronous API over in-memory data -------

  /// Returns the master list of all known tags (unmodifiable).
  List<ModTag> getAllTags() {
    final s = _snapshot();
    return List.unmodifiable(s.masterTags);
  }

  /// Returns tags associated with a specific mod id (unmodifiable set).
  Set<ModTag> getTagsForMod(String modId) {
    final s = _snapshot();
    final tagIds = s.tagsByModId[modId] ?? const <String>{};
    final byId = _indexTagsById(s.masterTags);
    final result = tagIds.map((id) => byId[id]).whereType<ModTag>().toSet();
    return result;
  }

  /// Returns a map of modId -> set of ModTag (unmodifiable).
  Map<String, Set<ModTag>> getTagsByModId() {
    final s = _snapshot();
    final byId = _indexTagsById(s.masterTags);
    final result = <String, Set<ModTag>>{};
    for (final entry in s.tagsByModId.entries) {
      result[entry.key] = entry.value
          .map((id) => byId[id])
          .whereType<ModTag>()
          .toSet();
    }
    return UnmodifiableMapView(result);
  }

  /// Adds the provided tags to the given mod (by tag objects).
  /// - Ensures tags exist in the master list.
  /// - Deduplicates by tag id.
  void addTagsToMod(String modId, Iterable<ModTag> tags) {
    if (tags.isEmpty) return;

    _mutate((s) {
      return _cloneAndAddTagsToMod(s, tags, modId);
    });
  }

  /// Adds tags by name to the given mod.
  /// - Creates new ModTag for unknown names.
  /// - Re-uses existing tags by name.
  // void addTagNamesToMod(String modId, Iterable<String> tagNames) {
  //   final cleaned = tagNames
  //       .map((n) => n.trim())
  //       .where((n) => n.isNotEmpty)
  //       .toList();
  //   if (cleaned.isEmpty) return;
  //
  //   final s = _snapshot();
  //   final byName = _indexTagsByName(s.masterTags);
  //   final toAdd = <ModTag>[];
  //
  //   for (final name in cleaned) {
  //     final existing = byName[name.toLowerCase()];
  //     toAdd.add(existing ?? ModTag.create(name));
  //   }
  //
  //   addTagsToMod(modId, toAdd);
  // }

  /// Removes the provided tags from the given mod (by tag objects).
  /// - Prunes unused tags from the master list if no mod references them anymore.
  void removeTagsFromMod(String modId, Iterable<ModTag> tags) {
    removeTagIdsFromMod(modId, tags.map((t) => t.id));
  }

  /// Removes tags by name from the given mod.
  void removeTagNamesFromMod(String modId, Iterable<String> tagNames) {
    final cleaned = tagNames
        .map((n) => n.trim().toLowerCase())
        .where((n) => n.isNotEmpty);
    if (cleaned.isEmpty) return;

    final s = _snapshot();
    final byName = _indexTagsByName(s.masterTags);
    final ids = cleaned.map((n) => byName[n]?.id).whereType<String>();
    removeTagIdsFromMod(modId, ids);
  }

  /// Removes tag ids from a mod and prunes unused tags from master list.
  void removeTagIdsFromMod(String modId, Iterable<String> tagIds) {
    final ids = tagIds.toSet();
    if (ids.isEmpty) return;

    _mutate((s) {
      // Remove from the target mod
      final tagsByModId = _cloneTagsByModId(s.tagsByModId);
      final set = tagsByModId[modId];
      if (set != null) {
        set.removeAll(ids);
        if (set.isEmpty) {
          tagsByModId.remove(modId);
        }
      }

      // Compute still-referenced ids
      final stillReferenced = <String>{};
      for (final entry in tagsByModId.values) {
        stillReferenced.addAll(entry);
      }

      // Prune master tags that are no longer referenced by any mod
      final prunedMaster = s.masterTags
          .where((t) => stillReferenced.contains(t.id))
          .toList();

      return ModTagStore(masterTags: prunedMaster, tagsByModId: tagsByModId);
    });
  }

  void addDefaultModTags(List<ModVariant> modVariants) {
    for (final variant in modVariants) {
      _mutate((store) {
        final newTags = <ModTag>[];
        if (variant.modInfo.isUtility) {
          newTags.add(ModTag.create(name: "Utility", isUserCreated: false));
        }
        if (variant.modInfo.isTotalConversion) {
          newTags.add(
            ModTag.create(name: "Total Conversion", isUserCreated: false),
          );
        }

        if (newTags.isNotEmpty) {
          return _cloneAndAddTagsToMod(store, newTags, variant.modInfo.id);
        } else {
          return store;
        }
      });
    }
  }

  ModTagStore _cloneAndAddTagsToMod(
    ModTagStore s,
    Iterable<ModTag> tags,
    String modId,
  ) {
    final master = [...s.masterTags];
    final byId = _indexTagsById(master);

    // Ensure master list contains all tags
    for (final t in tags) {
      if (!byId.containsKey(t.id)) {
        master.add(t);
        byId[t.id] = t;
      }
    }

    // Attach to mod
    final tagsByModId = _cloneTagsByModId(s.tagsByModId);
    final set = tagsByModId.putIfAbsent(modId, () => <String>{});
    for (final t in tags) {
      set.add(t.id);
    }

    return ModTagStore(masterTags: master, tagsByModId: tagsByModId);
  }

  // ------- Helpers -------

  ModTagStore _snapshot() {
    // Prefer live state; fall back to lastKnownValue if build hasn't completed yet.
    return state.valueOrNull ??
        (settingsManager.lastKnownValue ?? createDefaultState());
  }

  void _mutate(ModTagStore Function(ModTagStore current) updater) {
    final current = _snapshot();
    final next = updater(current);
    updateState((_) => next);
  }

  Map<String, ModTag> _indexTagsById(List<ModTag> tags) {
    final map = <String, ModTag>{};
    for (final t in tags) {
      map[t.id] = t;
    }
    return map;
  }

  Map<String, ModTag> _indexTagsByName(List<ModTag> tags) {
    final map = <String, ModTag>{};
    for (final t in tags) {
      map[t.name.toLowerCase()] = t;
    }
    return map;
  }

  Map<String, Set<String>> _cloneTagsByModId(Map<String, Set<String>> source) {
    final copy = <String, Set<String>>{};
    for (final e in source.entries) {
      copy[e.key] = {...e.value};
    }
    return copy;
  }
}
