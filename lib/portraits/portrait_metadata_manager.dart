import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/portraits/faction_portrait_parser.dart';
import 'package:trios/portraits/portrait_metadata.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/utils/logging.dart';

/// Manages portrait metadata extracted from faction files.
///
/// This notifier scans all faction files from enabled mods and vanilla
/// to build a lookup table of portrait paths to their metadata (gender, factions).
class PortraitMetadataNotifier
    extends AsyncNotifier<Map<String, PortraitMetadata>> {
  var isLoading = false;

  var _lastState = <String, PortraitMetadata>{};
  var _lastGameFolder = "";
  var _fullRescanRequested = false;

  @override
  Future<Map<String, PortraitMetadata>> build() async {
    // Rebuild when these change (mods added/removed, game folder change)
    ref.watch(AppState.variantSmolIds);
    final gameCoreFolder = ref.watch(AppState.gameCoreFolder).value;

    isLoading = true;

    try {
      if (gameCoreFolder == null) {
        isLoading = false;
        return _lastState;
      }

      final mods = ref.read(AppState.mods);
      final variants = mods
          .map((mod) => mod.findFirstEnabledOrHighestVersion)
          .toList();

      // Always include null (Vanilla) in the variants list
      if (!variants.contains(null)) {
        variants.add(null);
      }

      if (_lastState.isEmpty) {
        Fimber.i("Scanning all faction files for portrait metadata.");
        _fullRescanRequested = true;
      }

      if (gameCoreFolder.path != _lastGameFolder) {
        Fimber.i("Game folder changed, invalidating portrait metadata.");
        _fullRescanRequested = true;
      }

      Map<String, PortraitMetadata> allMetadata = {};

      if (!_fullRescanRequested) {
        // Start with existing metadata
        allMetadata = Map.from(_lastState);

        // Remove metadata from removed variants
        // Note: This is imprecise since we don't track which metadata came from which variant.
        // For simplicity, we'll do a full rescan when variants change significantly.
        // TODO: Track source variant for more precise updates
        _fullRescanRequested = true;
      }

      if (_fullRescanRequested) {
        allMetadata = {};

        for (final variant in variants) {
          final variantMetadata = await FactionPortraitParser.parseModFactions(
            variant,
            gameCoreFolder,
          );

          // Merge metadata
          for (final entry in variantMetadata.entries) {
            if (allMetadata.containsKey(entry.key)) {
              allMetadata[entry.key] =
                  allMetadata[entry.key]!.mergeWith(entry.value);
            } else {
              allMetadata[entry.key] = entry.value;
            }
          }

          // Update state progressively
          state = AsyncValue.data(Map.from(allMetadata));
          _lastState = Map.from(allMetadata);
        }
      }

      _lastGameFolder = gameCoreFolder.path;
      _fullRescanRequested = false;

      Fimber.i(
        "Portrait metadata scan complete. Found metadata for ${allMetadata.length} portraits.",
      );

      return _lastState;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    } finally {
      isLoading = false;
    }
  }

  Future<void> rescan() async {
    _fullRescanRequested = true;
    await build();
  }
}

/// Extension to look up metadata for a portrait by its relative path.
extension PortraitMetadataLookup on Map<String, PortraitMetadata> {
  /// Gets metadata for a portrait, returning unknown metadata if not found.
  PortraitMetadata getMetadataFor(String relativePath) {
    // Normalize the path for lookup
    final normalized = _normalizePath(relativePath);
    return this[normalized] ?? PortraitMetadata.unknown(relativePath);
  }

  String _normalizePath(String path) {
    var normalized = path.replaceAll('\\', '/');
    if (normalized.startsWith('/')) {
      normalized = normalized.substring(1);
    }
    return normalized;
  }
}
