import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/mod_variant.dart';
import '../utils/generic_settings_manager.dart';
import '../utils/generic_settings_notifier.dart';

part 'mod_metadata.mapper.dart';

/// Provides [ModMetadata]s, observable state.
final modsMetadataProvider =
    AsyncNotifierProvider<ModMetadataStore, ModsMetadata>(ModMetadataStore.new);

/// Stores [ModMetadata]s, provides methods to manage them, observable state.
class ModMetadataStore extends GenericSettingsAsyncNotifier<ModsMetadata> {
  @override
  GenericAsyncSettingsManager<ModsMetadata> createSettingsManager() =>
      _ModsMetadataManager();

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
        : baseMetadata;
  }

  /// Returns a mod variant metadata object containing user metadata first and, if not found, base metadata.
  ModVariantMetadata? getMergedModVariantMetadata(String modId, String smolId) {
    final userMetadata = this.userMetadata[modId]?.variantsMetadata[smolId];
    final baseMetadata = this.baseMetadata[modId]?.variantsMetadata[smolId];

    return userMetadata != null && baseMetadata != null
        ? userMetadata.backfillWith(baseMetadata)
        : baseMetadata;
  }
}

/// Stores [ModVariantMetadata]s.
@MappableClass()
class ModMetadata with ModMetadataMappable {
  final Map<SmolId, ModVariantMetadata> variantsMetadata;
  final int? firstSeen;
  final bool? isFavorited;

  ModMetadata({
    required this.variantsMetadata,
    required this.firstSeen,
    required this.isFavorited,
  });

  /// Returns a mod metadata object containing user metadata first and, if not found, base metadata.
  ModMetadata backfillWith(ModMetadata base) {
    return ModMetadata(
      variantsMetadata: variantsMetadata.map((key, value) {
        final baseModVariantMetadata = base.variantsMetadata[key];

        return baseModVariantMetadata != null
            ? MapEntry(key, value.backfillWith(baseModVariantMetadata))
            : MapEntry(key, value);
      }),
      firstSeen: firstSeen ?? base.firstSeen,
      isFavorited: isFavorited ?? base.isFavorited,
    );
  }
}

/// Stores metadata for a mod variant.
@MappableClass()
class ModVariantMetadata with ModVariantMetadataMappable {
  final int? firstSeen;

  ModVariantMetadata({
    required this.firstSeen,
  });

  /// Returns a mod variant metadata object containing user metadata first and, if not found, base metadata.
  ModVariantMetadata backfillWith(ModVariantMetadata base) {
    return ModVariantMetadata(
      firstSeen: firstSeen ?? base.firstSeen,
    );
  }
}
