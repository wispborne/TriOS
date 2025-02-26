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

import 'package:trios/thirdparty/dartx/map.dart';

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
      hideTips(previouslyDeletedTips.map((pair) => pair.second));
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

  List<ModTip> getHidden(List<ModTip> tips) {
    final hiddenTipHashes = deletedTipsStorageManager.lastKnownValue ?? {};

    return tips
        .where((tip) =>
            tip.tipObj.freq == "0" &&
            hiddenTipHashes.contains(_createTipHashcode(
                tip.variants.firstOrNull?.modInfo.id, tip.tipObj)))
        .toList();
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

  /// Hides tips from the current state.
  Future<void> hideTips(Iterable<ModTip> tipsToRemove,
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
          "Removing from variant ${variant.smolId} tips: ${variantTipsToRemove.map((t) => "'${t.tip?.truncate(40)}'").toList()}");

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
            // This line removes the tip
            // ?.where((t) => !variantTipsToRemove.contains(t))
            // Switched to hiding the tip (freq 0) instead of removing it
            ?.map((t) => variantTipsToRemove.contains(t)
                ? t.copyWith(freq: "0", originalFreq: t.freq)
                : t)
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
    final allRemovedHashes =
        (currentDeletedTips + removedTipHashcodes.toList()).toSet();
    deletedTipsStorageManager.scheduleWriteSettingsToDisk(allRemovedHashes);

    if (reloadTipsAfter) {
      final updatedList = [...?state.valueOrNull];

      for (final hiddenTip in tipsToRemove) {
        final index = updatedList.indexOf(hiddenTip);
        if (index != -1) {
          final oldTipObj = updatedList[index].tipObj;
          final newTipObj =
              oldTipObj.copyWith(freq: '0', originalFreq: oldTipObj.freq);
          updatedList[index] = updatedList[index].copyWith(tipObj: newTipObj);
        }
      }

      state = AsyncValue.data(updatedList);
    }
  }

  bool isHidden(ModTip tip) {
    final hiddenTips = getHidden(state.valueOrNull.orEmpty().toList());
    return hiddenTips.contains(tip);
  }

  Future<void> unhideTips(Iterable<ModTip> tipsToUnhide,
      {bool reloadTipsAfter = true}) async {
    final current = state.valueOrNull;
    if (current == null || tipsToUnhide.isEmpty) return;

    // We'll group them by variant so we can open each tips.json only once:
    final tipsToUnhideByVariant = <ModVariant, List<Tip>>{};
    for (var tip in tipsToUnhide) {
      for (var variant in tip.variants) {
        tipsToUnhideByVariant.putIfAbsent(variant, () => []).add(tip.tipObj);
      }
    }

    // Write back to each tips.json on disk
    for (var entry in tipsToUnhideByVariant.entries) {
      final variant = entry.key;
      final variantTips = entry.value;

      try {
        final tipData = await _loadTipsFromFile(variant);
        if (tipData == null) continue; // no file found, skip

        final allVariantTips = tipData.tips.tips;
        if (allVariantTips == null) continue;

        final updatedTips = allVariantTips.map((original) {
          if (variantTips.contains(original)) {
            // This tip is being unhidden:
            final restoredFreq = original.originalFreq?.isNotEmpty == true
                ? original.originalFreq
                : '1'; // fallback to "1"
            return original.copyWith(
              freq: restoredFreq,
              originalFreq: null, // clear originalFreq after unhide
            );
          } else {
            return original;
          }
        }).toList();

        final updatedJson = Tips(tips: updatedTips).toMap().prettyPrintJson();
        final file = getTipsFile(variant);
        await file.writeAsString(updatedJson);
      } catch (e, stacktrace) {
        Fimber.e("Error un-hiding tips", ex: e, stacktrace: stacktrace);
      }
    }

    // Remove their hash codes from the 'deleted tips' tracking file:
    final unhiddenTipHashes = tipsToUnhide
        .map((tip) => _createTipHashcode(
            tip.variants.firstOrNull?.modInfo.id, tip.tipObj))
        .toSet();

    var currentDeletedTips = <String>[];
    try {
      currentDeletedTips =
          (await deletedTipsStorageManager.readSettingsFromDisk({}))
              .orEmpty()
              .toList();
    } catch (e, stacktrace) {
      Fimber.e("Error reading deleted tips from disk",
          ex: e, stacktrace: stacktrace);
    }

    // Filter out the ones we just unhid:
    final newDeletedSet = currentDeletedTips
        .where((hash) => !unhiddenTipHashes.contains(hash))
        .toSet();
    deletedTipsStorageManager.scheduleWriteSettingsToDisk(newDeletedSet);

    // Finally, update in-memory state so UI immediately reflects the changes:
    if (reloadTipsAfter) {
      final updatedList = [...current];

      for (final unhiddenTip in tipsToUnhide) {
        final idx = updatedList.indexOf(unhiddenTip);
        if (idx != -1) {
          final oldTip = updatedList[idx];
          final oldTipObj = oldTip.tipObj;
          final restoredFreq = oldTipObj.originalFreq?.isNotEmpty == true
              ? oldTipObj.originalFreq
              : '1';

          // Rebuild the tip with freq restored:
          final newTipObj = oldTipObj.copyWith(
            freq: restoredFreq,
            originalFreq: null,
          );
          updatedList[idx] = oldTip.copyWith(tipObj: newTipObj);
        }
      }

      state = AsyncValue.data(updatedList);
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
