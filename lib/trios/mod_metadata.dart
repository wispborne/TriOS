import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/models/mod.dart';
import 'package:trios/thirdparty/dartx/map.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/logging.dart';

import '../models/mod_variant.dart';
import '../utils/generic_settings_manager.dart';
import '../utils/generic_settings_notifier.dart';
import 'app_state.dart';

part 'mod_metadata.mapper.dart';

/// Stores [ModMetadata]s, provides methods to manage them, observable state.
class ModMetadataStore extends GenericSettingsAsyncNotifier<ModsMetadata> {
  @override
  GenericAsyncSettingsManager<ModsMetadata> createSettingsManager() =>
      _ModsMetadataManager();

  @override
  Future<ModsMetadata> build() async {
    int timestamp = DateTime.now().millisecondsSinceEpoch;
    final settings = await super.build();
    Fimber.d(
        "Read metadata in ${DateTime.now().millisecondsSinceEpoch - timestamp}ms.");
    timestamp = DateTime.now().millisecondsSinceEpoch;
    bool isDirty = false;

    // Can't call ref.watch here because it can cause build to get called multiple times
    // on startup, resulting in the metadata never loading properly.
    final allMods = ref.read(AppState.mods);
    _initializeMissingMetadata(allMods, settings, isDirty, timestamp);

    ref.listen(AppState.mods, (prev, newMods) {
      if (!listEquals(prev, newMods)) {
        _initializeMissingMetadata(newMods, settings, isDirty, timestamp);
      }
    });

    return settings;
  }

  // Create metadata for all mods and variants if they don't exist.
  // This sets the firstSeen timestamp to now.
  void _initializeMissingMetadata(
      List<Mod> allMods, ModsMetadata settings, bool isDirty, int timestamp) {
    for (final mod in allMods) {
      final baseMetadata = settings.baseMetadata[mod.id] ?? ModMetadata.empty();
      final baseVariantMetadata = mod.modVariants
          .map((variant) => MapEntry(
              variant.smolId,
              baseMetadata.variantsMetadata[variant.smolId] ??
                  ModVariantMetadata.empty()))
          .toMap();
      final newModMetadata =
          baseMetadata.copyWith(variantsMetadata: baseVariantMetadata);

      if (settings.baseMetadata[mod.id].hashCode != newModMetadata.hashCode) {
        settings.baseMetadata[mod.id] = newModMetadata;
        isDirty = true;
      }
    }

    Fimber.d(
        "Updated metadata in ${DateTime.now().millisecondsSinceEpoch - timestamp}ms.");

    if (isDirty) {
      settingsManager.writeSettingsToDisk(settings);
    }
  }

  /// Returns a mod metadata object containing user metadata first and, if not found, base metadata.
  /// Make sure not to write using this, as it combines user and base metadata.
  ModMetadata? getMergedModMetadata(String modId) {
    return state.valueOrNull?.getMergedModMetadata(modId);
  }

  /// Returns a mod variant metadata object containing user metadata first and, if not found, base metadata.
  /// Make sure not to write using this, as it combines user and base metadata.
  ModVariantMetadata? getMergedModVariantMetadata(String modId, String smolId) {
    return state.valueOrNull?.getMergedModVariantMetadata(modId, smolId);
  }

  void updateModUserMetadata(String modId,
      ModMetadata Function(ModMetadata oldMetadata) metadataUpdater) {
    final userMetadata = state.valueOrNull?.userMetadata.toMap() ?? {};
    userMetadata[modId] =
        metadataUpdater(userMetadata[modId] ?? ModMetadata.empty());
    update((s) => s.copyWith(userMetadata: userMetadata));
  }

  void updateModBaseMetadata(String modId,
      ModMetadata Function(ModMetadata oldMetadata) metadataUpdater) {
    final baseMetadata = state.valueOrNull?.baseMetadata.toMap() ?? {};
    baseMetadata[modId] =
        metadataUpdater(baseMetadata[modId] ?? ModMetadata.empty());
    update((s) => s.copyWith(baseMetadata: baseMetadata));
  }

  void updateModVariantUserMetadata(
      String modId,
      String smolId,
      ModVariantMetadata Function(ModVariantMetadata oldMetadata)
          metadataUpdater) {
    final userMetadata = state.valueOrNull?.userMetadata.toMap() ?? {};
    if (userMetadata[modId] == null) {
      userMetadata[modId] = ModMetadata.empty();
    }

    userMetadata[modId]!.variantsMetadata[smolId] = metadataUpdater(
        userMetadata[modId]!.variantsMetadata[smolId] ??
            ModVariantMetadata.empty());
    update((s) => s.copyWith(userMetadata: userMetadata));
  }

  void updateModVariantBaseMetadata(
      String modId,
      String smolId,
      ModVariantMetadata Function(ModVariantMetadata oldMetadata)
          metadataUpdater) {
    final baseMetadata = state.valueOrNull?.baseMetadata.toMap() ?? {};
    if (baseMetadata[modId] == null) {
      baseMetadata[modId] = ModMetadata.empty();
    }

    baseMetadata[modId]!.variantsMetadata[smolId] = metadataUpdater(
        baseMetadata[modId]!.variantsMetadata[smolId] ??
            ModVariantMetadata.empty());
    update((s) => s.copyWith(baseMetadata: baseMetadata));
  }
}

/// Manager for [ModMetadataStore].
class _ModsMetadataManager extends GenericAsyncSettingsManager<ModsMetadata> {
  @override
  ModsMetadata Function() get createDefaultState =>
      () => const ModsMetadata(baseMetadata: {}, userMetadata: {});

  @override
  FileFormat get fileFormat => FileFormat.json;

  @override
  String get fileName => "trios_mod_metadata-v1.${fileFormat.name}";

  @override
  ModsMetadata Function(Map<String, dynamic> map) get fromMap =>
      (json) => ModsMetadataMapper.fromMap(json);

  @override
  Map<String, dynamic> Function(ModsMetadata) get toMap =>
      (state) => state.toMap();
}

/// Stores [ModMetadata]s and [ModVariantMetadata]s.
@MappableClass()
class ModsMetadata with ModsMetadataMappable {
  /// Filled by TriOS
  final Map<SmolId, ModMetadata> baseMetadata;

  /// Filled by user, overrides base metadata
  final Map<SmolId, ModMetadata> userMetadata;

  const ModsMetadata({
    required this.baseMetadata,
    required this.userMetadata,
  });

  /// Returns a mod metadata object containing user metadata first and, if not found, base metadata.
  ModMetadata? getMergedModMetadata(String modId) {
    final userMetadata = this.userMetadata[modId];
    final baseMetadata = this.baseMetadata[modId];

    return userMetadata != null && baseMetadata != null
        ? userMetadata.backfillWith(baseMetadata)
        : userMetadata ?? baseMetadata;
  }

  /// Returns a mod variant metadata object containing user metadata first and, if not found, base metadata.
  ModVariantMetadata? getMergedModVariantMetadata(String modId, String smolId) {
    final userMetadata = this.userMetadata[modId]?.variantsMetadata[smolId];
    final baseMetadata = this.baseMetadata[modId]?.variantsMetadata[smolId];

    return userMetadata != null && baseMetadata != null
        ? userMetadata.backfillWith(baseMetadata)
        : userMetadata ?? baseMetadata;
  }
}

/// Stores [ModVariantMetadata]s.
@MappableClass()
class ModMetadata with ModMetadataMappable {
  final Map<SmolId, ModVariantMetadata> variantsMetadata;
  final int firstSeen;
  final bool isFavorited;

  /// Timestamp of when the mod variant was last enabled by TriOS.
  final int? lastEnabled;

  ModMetadata({
    this.variantsMetadata = const {},
    required this.firstSeen,
    this.isFavorited = false,
    this.lastEnabled,
  });

  static ModMetadata empty() => ModMetadata(
      variantsMetadata: {}, firstSeen: DateTime.now().millisecondsSinceEpoch);

  /// Merges all fields from this (user) and [base], with user data overriding what it explicitly sets.
  ModMetadata backfillWith(ModMetadata base) {
    final mergedVariants = {
      ...base.variantsMetadata,
      ...variantsMetadata,
    }.map((key, userVariant) {
      final baseVariant = base.variantsMetadata[key];
      if (baseVariant != null) {
        return MapEntry(key, userVariant.backfillWith(baseVariant));
      }
      return MapEntry(key, userVariant);
    });

    return ModMetadata(
      variantsMetadata: mergedVariants,
      firstSeen: firstSeen,
      isFavorited: isFavorited,
      lastEnabled: lastEnabled ?? base.lastEnabled,
    );
  }
}

/// Stores metadata for a mod variant.
@MappableClass()
class ModVariantMetadata with ModVariantMetadataMappable {
  /// Timestamp of when the mod variant was first seen by TriOS.
  final int firstSeen;

  ModVariantMetadata({
    required this.firstSeen,
  });

  static ModVariantMetadata empty() =>
      ModVariantMetadata(firstSeen: DateTime.now().millisecondsSinceEpoch);

  /// Merges all fields from this (user) and [base], with user data overriding what it explicitly sets.
  ModVariantMetadata backfillWith(ModVariantMetadata base) {
    return ModVariantMetadata(
      firstSeen: firstSeen,
    );
  }
}
