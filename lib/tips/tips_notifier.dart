import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/models/mod.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/tips/tip.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/generic_settings_manager.dart';
import 'package:trios/utils/logging.dart';

import '../thirdparty/dartx/map.dart';

class TipsNotifier extends AsyncNotifier<List<ModTip>> {
  final deletedTipsStorageManager = _TipsStorageManager();

  @override
  Future<List<ModTip>> build() async {
    state =
        const AsyncValue.loading(); // Set loading state before async operation

    final mods = ref.watch(AppState.mods);
    if (mods.isEmpty) {
      return [];
    }

    ref.listen(AppState.mods, (prev, newMods) async {
      if (prev.hashCode == newMods.hashCode) return;
      _removePreviouslyDeletedTips(newMods);
    });
    _removePreviouslyDeletedTips(mods);

    return await loadTips(mods);
  }

  /// Searches to see if tips that a user has previously deleted are present.
  /// This usually happens if they update or reinstall a mod, and the new version re-adds the tip.
  Future<void> _removePreviouslyDeletedTips(List<Mod> newMods) async {
    final previouslyDeletedTips =
        await _checkForModsWithPreviouslyDeletedTips(newMods);
    Fimber.d("Found ${previouslyDeletedTips.length} previously deleted tips");
    if (previouslyDeletedTips.isNotEmpty) {
      deleteTips(previouslyDeletedTips.map((pair) => pair.second));
    }
  }

  /// Load tips from each [Mod] in [mods] and return the list.
  /// This ensures that `build()` properly awaits the result.
  Future<List<ModTip>> loadTips(List<Mod> mods) async {
    Fimber.i('Loading tips...');

    final unfilteredTips = <ModTip>[];

    for (final mod in mods) {
      final tipsMap = <Tip, List<({ModVariant variant, File tipsFile})>>{};

      for (final variant in mod.modVariants) {
        try {
          final tips = await _loadTipsFromFile(variant);

          if (tips != null) {
            for (final tip in tips.tips.tips.orEmpty()) {
              tipsMap.putIfAbsent(tip, () => []).add(
                (variant: variant, tipsFile: tips.file),
              );
            }
          }
        } catch (e, st) {
          Fimber.e('Error loading tips for $variant', ex: e, stacktrace: st);
        }
      }

      final modTips = tipsMap.entries
          .map((entry) => ModTip(
              tipObj: entry.key,
              variants: entry.value.map((m) => m.variant).toList(),
              tipFile: entry.value.first.tipsFile))
          .toList();

      unfilteredTips.addAll(modTips);
    }

    Fimber.i('Loaded tips: ${unfilteredTips.length}');
    return unfilteredTips;
  }

  File getTipsFile(ModVariant variant) {
    return variant.modFolder.resolve(Constants.tipsFileRelativePath).toFile();
  }

  Future<({Tips tips, File file})?> _loadTipsFromFile(
      ModVariant variant) async {
    final tipsFile = getTipsFile(variant);
    if (tipsFile.existsSync()) {
      return (
        tips: TipsMapper.fromMap(
            (await tipsFile.toFile().readAsString()).fixJsonToMap()),
        file: tipsFile
      );
    }
    return null;
  }

  ({File file, Tips tips})? _loadTipsFromFileSync(ModVariant variant) {
    final tipsFile = getTipsFile(variant);
    if (tipsFile.existsSync()) {
      return (
        tips: TipsMapper.fromMap(
            tipsFile.toFile().readAsStringSync().fixJsonToMap()),
        file: tipsFile
      );
    }
    return null;
  }

  /// Deletes tips from the current state.
  Future<void> deleteTips(Iterable<ModTip> tipsToRemove,
      {bool dryRun = false, bool reloadTipsAfter = true}) async {
    final current = state.valueOrNull;
    if (current == null || tipsToRemove.isEmpty) return;

    final tipsToRemoveByVariant = <ModVariant, List<Tip>>{};

    for (var tip in tipsToRemove) {
      for (var variant in tip.variants) {
        tipsToRemoveByVariant.putIfAbsent(variant, () => []).add(tip.tipObj);
      }
    }

    for (var entry in tipsToRemoveByVariant.entries) {
      final variant = entry.key;
      final variantTipsToRemove = entry.value;

      Fimber.i(
          "Removing from variant ${variant.smolId} tips: ${variantTipsToRemove.map((t) => "'${t.tip?.substring(0, 40)}'").toList()}");

      try {
        final tipData = await _loadTipsFromFile(variant);
        if (tipData == null) return;

        final path = getTipsFile(variant).path;
        final allVariantTips = tipData;

        final backupPath = "$path.bak";
        final backupFile = File(backupPath);

        if (!await backupFile.exists()) {
          await File(path).copy(backupPath);
          Fimber.i("Created backup of '$path' at '$backupPath'");
        }

        final updatedTips = allVariantTips.tips.tips
            ?.where((t) => !variantTipsToRemove.contains(t))
            .toList();

        final filteredTipsJson =
            Tips(tips: updatedTips).toMap().prettyPrintJson();

        if (!dryRun) {
          await File(path).writeAsString(filteredTipsJson);
        }

        Fimber.i(
            "Removed ${variantTipsToRemove.length} tips from ${variant.smolId} tips at path '$path'.");
      } catch (e, stacktrace) {
        Fimber.e("Error deleting tips", ex: e, stacktrace: stacktrace);
      }
    }

    // add the tip hashcodes to storage
    final removedTipHashcodes = tipsToRemove
        .map((tip) => _createTipHashcode(
            tip.variants.firstOrNull?.modInfo.id, tip.tipObj))
        .toSet();
    final loadedTips = state.valueOrNull
            ?.map((tip) => _createTipHashcode(
                tip.variants.firstOrNull?.modInfo.id, tip.tipObj))
            .toList() ??
        [];
    var currentDeletedTips = <String>[];
    try {
      currentDeletedTips =
          (await deletedTipsStorageManager.readSettingsFromDisk({}))
              .orEmpty()
              .toList();
    } catch (e, stacktrace) {
      Fimber.e("Error reading deleted tips from disk. Wiping.",
          ex: e, stacktrace: stacktrace);
    }
    deletedTipsStorageManager.scheduleWriteSettingsToDisk(
        (currentDeletedTips + removedTipHashcodes.toList()).toSet());

    if (reloadTipsAfter) {
      state = const AsyncValue.loading();
      state = await AsyncValue.guard(() => loadTips(ref.watch(AppState.mods)));
    }
  }

  Future<List<Pair<String, ModTip>>> _checkForModsWithPreviouslyDeletedTips(
      List<Mod> modsToCheck) async {
    final removedTipHashes = await deletedTipsStorageManager
        .readSettingsFromDisk({}, useCachedValue: true);
    if (removedTipHashes.isEmpty) {
      return [];
    }
    final allModTipHashes =
        modsToCheck.flatMap((it) => it.modVariants).flatMap((variant) {
      ({File file, Tips tips})? tipsFromFileSync;

      try {
        tipsFromFileSync = _loadTipsFromFileSync(variant);
      } catch (ex, st) {
        Fimber.w("Unable to load tips from ${variant.smolId}.",
            ex: ex, stacktrace: st);
      }
      return (tipsFromFileSync?.tips.tips.orEmpty() ?? [])
          .map<Pair<String, ModTip>>((it) => Pair(
                _createTipHashcode(variant.modInfo.id, it),
                ModTip(
                    tipObj: it,
                    variants: [variant],
                    tipFile: tipsFromFileSync!.file),
              ));
    });

    return allModTipHashes
        .where((it) => removedTipHashes.contains(it.first))
        .toList();
  }

  String _createTipHashcode(String? modId, Tip tip) => "$modId-${tip.hashCode}";
}

class _TipsStorageManager extends GenericAsyncSettingsManager<Set<String>> {
  @override
  FileFormat get fileFormat => FileFormat.json;

  @override
  String get fileName => "trios_removed_tip_hashcodes-v1.${fileFormat.name}";

  @override
  Set<String> Function(Map<String, dynamic> map) get fromMap =>
      (map) => map.keys.toSet();

  @override
  Map<String, dynamic> Function(Set<String> obj) get toMap =>
      (obj) => {for (var e in obj) e: true};
}
