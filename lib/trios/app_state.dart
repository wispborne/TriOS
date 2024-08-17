import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:dart_extensions_methods/dart_extension_methods.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trios/jre_manager/jre_entry.dart';
import 'package:trios/mod_manager/mod_manager_extensions.dart';
import 'package:trios/mod_manager/mod_manager_logic.dart';
import 'package:trios/models/download_progress.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/themes/theme_manager.dart';
import 'package:trios/trios/self_updater/self_updater.dart';
import 'package:trios/trios/settings/settings.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/logging.dart';
import 'package:trios/utils/platform_paths.dart';
import 'package:trios/utils/util.dart';

import '../jre_manager/jre_manager_logic.dart';
import '../mod_manager/audit_page.dart';
import '../mod_manager/version_checker.dart';
import '../models/enabled_mods.dart';
import '../models/mod.dart';
import 'data_cache/enabled_mods.dart';
import 'mod_variants.dart';

class AppState {
  static ThemeManager theme = ThemeManager();
  static final isWindowFocused = StateProvider<bool>((ref) => true);
  static final selfUpdate =
      AsyncNotifierProvider<SelfUpdater, DownloadProgress?>(SelfUpdater.new);

  /// Master list of all mod variants found in the mods folder.
  static final modVariants =
      AsyncNotifierProvider<ModVariantsNotifier, List<ModVariant>>(
          ModVariantsNotifier.new);

  /// String is the smolId
  static final versionCheckResults = AsyncNotifierProvider<
      VersionCheckerNotifier,
      Map<String, RemoteVersionCheckResult>>(VersionCheckerNotifier.new);

  static var skipCacheOnNextVersionCheck = false;

  static List<Mod> getModsFromVariants(
      List<ModVariant> modVariants, List<String> enabledMods) {
    return modVariants
        .groupBy((ModVariant variant) => variant.modInfo.id)
        .entries
        .map((entry) {
      return Mod(
        id: entry.key,
        isEnabledInGame: enabledMods.contains(entry.key),
        modVariants: entry.value.toList(),
      );
    }).toList();
  }

  /// Projection of [modVariants], grouping them by mod id.
  static final mods = Provider<List<Mod>>((ref) {
    // Fimber.d("Recalculating mods from variants.");
    final modVariants = ref.watch(AppState.modVariants).value ?? [];
    final enabledMods =
        ref.watch(AppState.enabledModIds).value.orEmpty().toList();
    return getModsFromVariants(modVariants, enabledMods);
  });

  static final enabledModVariants = Provider<List<ModVariant>>((ref) {
    final mods = ref.watch(AppState.mods);
    return mods.map((mod) => mod.findFirstEnabled).whereNotNull().toList();
  });

  static final modAudit =
      StateNotifierProvider<ModAuditNotifier, List<AuditEntry>>(
          (ref) => ModAuditNotifier());

  static final modCompatibility = Provider<Map<SmolId, DependencyCheck>>((ref) {
    final modVariants = ref.watch(AppState.modVariants).valueOrNull ?? [];
    final gameVersion = ref.watch(AppState.starsectorVersion).valueOrNull;
    final enabledMods = ref.watch(AppState.enabledModsFile).valueOrNull;
    if (enabledMods == null) return {};
    return modVariants.map((variant) {
      final compatibility =
          compareGameVersions(variant.modInfo.gameVersion, gameVersion);
      final dependencyCheckResult = variant.checkDependencies(
          modVariants, enabledMods.enabledMods.toList(), gameVersion);
      return MapEntry(variant.smolId,
          DependencyCheck(compatibility, dependencyCheckResult));
    }).toMap();
  });

  static final enabledModsFile =
      AsyncNotifierProvider<EnabledModsNotifier, EnabledMods>(
          EnabledModsNotifier.new);
  static final enabledModIds = FutureProvider<List<String>>((ref) async =>
      ref.watch(enabledModsFile).value?.enabledMods.toList() ?? []);
  static final modsState = Provider<Map<String, ModState>>((ref) => {});
  static final starsectorVersion = FutureProvider<String?>((ref) async {
    final gamePath =
        ref.watch(appSettings.select((value) => value.gameDir))?.toDirectory();
    if (gamePath == null) return null;
    try {
      final versionInLog = await readStarsectorVersionFromLog(gamePath);
      if (versionInLog != null) {
        ref
            .read(appSettings.notifier)
            .update((s) => s.copyWith(lastStarsectorVersion: versionInLog));
        return versionInLog;
      } else {
        return ref
            .read(appSettings.select((value) => value.lastStarsectorVersion));
      }
    } catch (e, stack) {
      Fimber.w("Failed to read starsector version from log",
          ex: e, stacktrace: stack);
      return ref
          .read(appSettings.select((value) => value.lastStarsectorVersion));
    }
  });

  static final canWriteToModsFolder = FutureProvider<bool>((ref) async {
    final gamePath =
        ref.watch(appSettings.select((value) => value.gameDir))?.toDirectory();
    if (gamePath == null) return false;
    var modsFolder = generateModFolderPath(gamePath)?.toDirectory();
    final filesAndFolders = [ref.read(enabledModsFile).valueOrNull?.enabledMods.toList()].whereNotNull();
    for (final file in filesAndFolders) {
      if (filesAndFolders.isEmpty) {
        Fimber.d("Cannot find or write to: $file");
        return false;
      }
    }
    return true;
  });

  static final canWriteToStarsectorFolder = FutureProvider<bool>((ref) async {
    final gamePath =
        ref.watch(appSettings.select((value) => value.gameDir))?.toDirectory();
    if (gamePath == null) return false;
    final filesAndFolders = [getVmparamsFile(gamePath)].whereNotNull();
    for (var file in filesAndFolders) {
      if (!file.existsSync() || await file.isNotWritable()) {
        Fimber.d("Cannot find or write to: $file");
        return false;
      }
    }
    return true;
  });

  static final vmParamsFile = FutureProvider<File?>((ref) async {
    final gamePath =
        ref.watch(appSettings.select((value) => value.gameDir))?.toDirectory();
    if (gamePath == null) return null;
    return getVmparamsFile(gamePath);
  });

  static final gameFolder = FutureProvider<Directory?>((ref) async =>
      ref.watch(appSettings.select((value) => value.gameDir))?.toDirectory());
  static final modsFolder = FutureProvider<Directory?>((ref) async {
    final gamePath = ref.watch(gameFolder).valueOrNull;
    if (gamePath == null) return null;
    return generateModFolderPath(gamePath)?.toDirectory();
  });

  static final isVmParamsFileWritable = FutureProvider<bool>(
      (ref) async => ref.watch(vmParamsFile).value?.isWritable() ?? false);
  static final jre23VmparamsFile = FutureProvider<File?>((ref) async {
    final gamePath = ref.watch(gameFolder).valueOrNull;
    if (gamePath == null) return null;
    return getJre23VmparamsFile(gamePath);
  });

  static final isJre23VmparamsFileWritable = FutureProvider<bool>(
      (ref) async => ref.watch(jre23VmparamsFile).value?.isWritable() ?? false);

  static final isEnabledModsFileWritable = FutureProvider<bool>((ref) async {
    final modsPath = ref.watch(modsFolder).valueOrNull;
    if (modsPath == null) return false;
    return ref.read(AppState.enabledModsFile.notifier).isWritable();
  });

  static final activeJre = FutureProvider<JreEntryInstalled?>((ref) async {
    final jres = await findJREs(ref.watch(gameFolder).valueOrNull?.path);
    final isUsingJre23 =
        ref.watch(appSettings.select((value) => value.useJre23));
    var activeJre = jres
        .orEmpty()
        .firstWhereOrNull((jre) => jre.isActive(isUsingJre23, jres));
    return activeJre;
  });
}

Future<String?> readStarsectorVersionFromLog(Directory gamePath) async {
  const versionContains = r"Starting Starsector";
  final versionRegex = RegExp(r"Starting Starsector (.*) launcher");
  final logfile = utf8.decode(getLogPath(gamePath).readAsBytesSync().toList(),
      allowMalformed: true);
  for (var line in logfile.split("\n")) {
    if (line.contains(versionContains)) {
      try {
        final version = versionRegex.firstMatch(line)!.group(1);
        if (version == null) continue;
        return version;
      } catch (_) {
        continue;
      }
    }
  }
  return null;
}

/// Initialized in main.dart
late SharedPreferences sharedPrefs;

var currentFileHandles = 0;
var maxFileHandles = 2000;

Future<T> withFileHandleLimit<T>(Future<T> Function() function) async {
  while (currentFileHandles + 1 > maxFileHandles) {
    Fimber.v(
        "Waiting for file handles to free up. Current file handles: $currentFileHandles");
    await Future.delayed(const Duration(milliseconds: 100));
  }
  currentFileHandles++;
  try {
    return await function();
  } finally {
    currentFileHandles--;
  }
}

enum ModState {
  disablingVariants,
  deletingVariants,
  enablingVariant,
  backingUpVariant,
}

extension ModDependencies on List<DependencyCheck?> {
  bool get isCompatibleWithGameVersion =>
      any((d) => d?.gameCompatibility != GameCompatibility.incompatible) ??
      false;

  GameCompatibility get leastSevereCompatibility =>
      reduce((a, b) {
        if (a == null) return b!;
        if (b == null) return a;
        return a.gameCompatibility.index < b.gameCompatibility.index ? a : b;
      })?.gameCompatibility ??
      GameCompatibility.incompatible;
}
