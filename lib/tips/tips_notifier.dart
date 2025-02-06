import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/models/mod.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/tips/tip.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/logging.dart';

class TipsNotifier extends AsyncNotifier<List<ModTip>> {
  @override
  Future<List<ModTip>> build() async {
    state =
        const AsyncValue.loading(); // Set loading state before async operation

    final mods = ref.watch(AppState.mods);
    if (mods.isEmpty) {
      return [];
    }
    return await loadTips(mods);
  }

  /// Load tips from each [Mod] in [mods] and return the list.
  /// This ensures that `build()` properly awaits the result.
  Future<List<ModTip>> loadTips(List<Mod> mods) async {
    Fimber.i('Loading tips...');

    final unfilteredTips = <ModTip>[];

    for (final mod in mods) {
      final tipsMap = <Tip, List<ModVariant>>{};

      for (final variant in mod.modVariants) {
        try {
          final tipsFile =
              variant.modFolder.resolve(Constants.tipsFileRelativePath);
          if (tipsFile.existsSync()) {
            final tipsJson = await tipsFile.toFile().readAsString();
            final loaded = TipsMapper.fromJson(tipsJson.fixJson()).tips ?? [];

            for (final tip in loaded) {
              tipsMap.putIfAbsent(tip, () => []).add(variant);
            }
          }
        } catch (e, st) {
          Fimber.e('Error loading tips for $variant', ex: e, stacktrace: st);
        }
      }

      final modTips = tipsMap.entries
          .map((entry) => ModTip(tipObj: entry.key, variants: entry.value))
          .toList();

      unfilteredTips.addAll(modTips);
    }

    Fimber.i('Loaded tips: ${unfilteredTips.length}');
    return unfilteredTips;
  }

  /// Deletes tips from the current state.
  void deleteTips(Iterable<ModTip> toRemove) {
    final current = state.valueOrNull;
    if (current == null || toRemove.isEmpty) return;

    Fimber.i('Deleting tips...');
    final updated = current.where((tip) => !toRemove.contains(tip)).toList();
    state = AsyncValue.data(updated);
  }
}
