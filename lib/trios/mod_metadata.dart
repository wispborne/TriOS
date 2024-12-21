import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/thirdparty/dartx/map.dart';
import 'package:trios/utils/extensions.dart';

import '../models/mod_variant.dart';
import '../utils/generic_settings_manager.dart';
import '../utils/generic_settings_notifier.dart';
import 'app_state.dart';

part 'mod_metadata.mapper.dart';

/// Provides [ModMetadata]s, observable state.
final modsMetadataProvider =
    AsyncNotifierProvider<ModMetadataStore, ModsMetadata>(ModMetadataStore.new);

/// Stores [ModMetadata]s, provides methods to manage them, observable state.
class ModMetadataStore extends GenericSettingsAsyncNotifier<ModsMetadata> {
  @override
  GenericAsyncSettingsManager<ModsMetadata> createSettingsManager() =>
      _ModsMetadataManager();

  @override
  Future<ModsMetadata> build() async {
    final settings = await super.build();
    bool isDirty = false;

    // Create metadata for all mods and variants if they don't exist.
    // This sets the firstSeen timestamp to now.
    final allMods = ref.watch(AppState.mods);
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

    if (isDirty) {
      settingsManager.writeSettingsToDisk(settings);
    }

    return settings;
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
      ModMetadata Function(ModMetadata oldMetadata) newUserMetadata) {
    final userMetadata = state.valueOrNull?.userMetadata.toMap() ?? {};
    userMetadata[modId] =
        newUserMetadata(userMetadata[modId] ?? ModMetadata.empty());
    update((s) => s.copyWith(userMetadata: userMetadata));
  }

  void updateModVariantUserMetadata(
      String modId,
      String smolId,
      ModVariantMetadata Function(ModVariantMetadata oldMetadata)
          newUserMetadata) {
    final userMetadata = state.valueOrNull?.userMetadata.toMap() ?? {};
    if (userMetadata[modId] == null) {
      userMetadata[modId] = ModMetadata.empty();
    }

    userMetadata[modId]!.variantsMetadata[smolId] = newUserMetadata(
        userMetadata[modId]!.variantsMetadata[smolId] ??
            ModVariantMetadata.empty());
    update((s) => s.copyWith(userMetadata: userMetadata));
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
  final bool? isFavorited;

  ModMetadata({
    this.variantsMetadata = const {},
    required this.firstSeen,
    this.isFavorited,
  });

  static ModMetadata empty() => ModMetadata(
      variantsMetadata: {}, firstSeen: DateTime.now().millisecondsSinceEpoch);

  /// Returns a mod metadata object containing user metadata first and, if not found, base metadata.
  ModMetadata backfillWith(ModMetadata base) {
    return ModMetadata(
      variantsMetadata: variantsMetadata.map((key, value) {
        final baseModVariantMetadata = base.variantsMetadata[key];

        return baseModVariantMetadata != null
            ? MapEntry(key, value.backfillWith(baseModVariantMetadata))
            : MapEntry(key, value);
      }),
      firstSeen: firstSeen,
      isFavorited: isFavorited ?? base.isFavorited,
    );
  }
}

/// Stores metadata for a mod variant.
@MappableClass()
class ModVariantMetadata with ModVariantMetadataMappable {
  final int firstSeen;

  ModVariantMetadata({
    required this.firstSeen,
  });

  static ModVariantMetadata empty() =>
      ModVariantMetadata(firstSeen: DateTime.now().millisecondsSinceEpoch);

  /// Returns a mod variant metadata object containing user metadata first and, if not found, base metadata.
  ModVariantMetadata backfillWith(ModVariantMetadata base) {
    return ModVariantMetadata(
      firstSeen: firstSeen ?? base.firstSeen,
    );
  }
}
