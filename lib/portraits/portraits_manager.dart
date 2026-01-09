import 'package:dart_extensions_methods/dart_extension_methods.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/portraits/portrait_model.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/utils/logging.dart';

import '../models/mod_variant.dart';
import 'portrait_scanner.dart';

class PortraitsNotifier
    extends AsyncNotifier<Map<ModVariant?, List<Portrait>>> {
  /// Whether portraits are still being loaded.
  /// [PortraitsNotifier] streams its results, meaning that even at 1% loaded, it's considered to be loaded since it has a value.
  /// This is a separate state tracker.
  var isLoadingPortraits = false;

  var _lastState = <ModVariant?, List<Portrait>>{};
  var _lastGameFolder = "";
  var _fullRescanRequested = false;

  @override
  Future<Map<ModVariant?, List<Portrait>>> build() async {
    // Rebuild when these change (mods added/removed, game folder change)
    ref.watch(AppState.variantSmolIds);
    final gameCoreFolder = ref.watch(AppState.gameCoreFolder).value;

    // Mark loading
    isLoadingPortraits = true;

    try {
      if (gameCoreFolder == null) {
        // No game folder set: return empty but not error
        isLoadingPortraits = false;
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
        Fimber.i("Scanning all portraits for the first time.");
        _fullRescanRequested = true;
      }

      if (gameCoreFolder.path != _lastGameFolder) {
        Fimber.i("Game folder changed, invalidating portraits.");
        _fullRescanRequested = true;
      }

      final scanner = PortraitScanner();

      if (!_fullRescanRequested) {
        // Fast path: remove deleted variants, keep existing ones, then stream-in new ones.
        final removedVariants = _lastState.keys.subtract(variants).toList();
        final result = Map<ModVariant?, List<Portrait>>.from(_lastState);
        for (final variant in removedVariants) {
          result.remove(variant);
          Fimber.i(
            "Removed variant ${variant?.smolId} from portrait scanning.",
          );
        }

        final existingSmolIds = _lastState.keys
            .whereType<ModVariant>()
            .map((v) => v.smolId)
            .toSet();

        final newVariants = variants
            .where((v) => !existingSmolIds.contains(v?.smolId))
            .toList();

        Fimber.i(
          "Differential scan: removed ${removedVariants.length} variants, added ${newVariants.length} variants.",
        );

        // 1) Immediately publish current known state
        state = AsyncValue.data(result);
        _lastState = result;

        // 2) Stream updates for newly added variants, merging as we go
        if (newVariants.isNotEmpty) {
          await for (final partial in scanner.scanVariantsStream(
            newVariants,
            gameCoreFolder,
          )) {
            Fimber.i(
              "Added variant ${partial.keys.first?.smolId} to portrait scanning.",
            );
            final merged = <ModVariant?, List<Portrait>>{...result, ...partial};
            state = AsyncValue.data(merged);
            _lastState = merged;
          }
        }
      } else {
        // Full rescan path
        await for (final result in scanner.scanVariantsStream(
          variants,
          gameCoreFolder,
        )) {
          state = AsyncValue.data(result);
          _lastState = result;
        }
      }

      _lastGameFolder = gameCoreFolder.path;
      _fullRescanRequested = false;
      return _lastState;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    } finally {
      isLoadingPortraits = false;
    }
  }

  Future<void> rescan() async {
    _fullRescanRequested = true;
    await build();
  }
}
