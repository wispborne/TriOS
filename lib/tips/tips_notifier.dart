import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/tips/tip.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/logging.dart';

class TipsNotifier extends StateNotifier<AsyncValue<List<ModTip>>> {
  // In a real app, inject references such as triOSHttpClient, userManager, etc.
  TipsNotifier() : super(const AsyncValue.data([]));

  Future<void> loadTips(List<ModVariant> variants) async {
    // Mark as loading.
    state = const AsyncValue.loading();
    Fimber.i('Loading tips...');

    final newTips = <ModTip>[];
    for (final v in variants) {
      try {
        final tipsFile = v.modFolder.resolve(Constants.tipsFileRelativePath);
        if (tipsFile.existsSync()) {
          final tipsJson = tipsFile.toFile().readAsString();
          final loaded = TipsMapper.fromJson(await tipsJson);
          if (loaded.tips != null) {
            for (final t in loaded.tips!) {
              newTips.add(ModTip(tipObj: t, variants: [v]));
            }
          }
        }
      } catch (e, st) {
        Fimber.e('Error loading tips', ex: e, stacktrace: st);
      }
    }

    state = AsyncValue.data(newTips);
    Fimber.i('Loaded tips: ${newTips.length}');
  }

  void deleteTips(Iterable<ModTip> toRemove) {
    final current = state.valueOrNull;
    if (current == null || toRemove.isEmpty) return;

    Fimber.i('Deleting tips...');
    final updated = current.whereNot((tip) => toRemove.contains(tip)).toList();
    state = AsyncValue.data(updated);

    // Optionally: if you want to persist these deletions, do so here.
  }
}
