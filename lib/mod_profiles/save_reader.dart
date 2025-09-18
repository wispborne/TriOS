import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:trios/mod_profiles/models/mod_profile.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/models/version.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/logging.dart';
import 'package:xml/xml.dart';

final saveFileProvider =
    AsyncNotifierProvider<SaveFileNotifier, List<SaveFile>>(
      SaveFileNotifier.new,
    );

class SaveFileNotifier extends AsyncNotifier<List<SaveFile>> {
  final String _descriptorFileName = "descriptor.xml";

  @override
  Future<List<SaveFile>> build() async {
    readAllSaves().then((saves) => state = AsyncData(saves));
    return [];
  }

  Future<List<SaveFile>> readAllSaves() async {
    final gameFolder = ref.watch(AppState.gameFolder).valueOrNull;
    if (gameFolder == null) {
      Fimber.w("Game folder not set");
      return [];
    }

    final saveDir = ref.watch(AppState.savesFolder).value!.toDirectory();

    // if (state.valueOrNull?.isNotEmpty == true) {
    //   Fimber.i("Saves already loaded, not refreshing.");
    //   return state.value!;
    // }

    if (!await saveDir.exists()) {
      Fimber.w("Save folder does not exist");
      return [];
    }

    final saveFolders = saveDir
        .listSync()
        .whereType<Directory>()
        .where((d) => d.name.startsWith("save"))
        .toList();

    final newSaves = await Future.wait(
      saveFolders.map((folder) async {
        try {
          return await readSave(folder);
        } catch (e) {
          Fimber.w("Failed to read save folder ${folder.path}: $e");
          return null;
        }
      }),
    );

    return newSaves.nonNulls.toList();
  }

  Future<SaveFile> readSave(Directory folderOfSave) async {
    final file = folderOfSave.resolve(_descriptorFileName).toFile();
    final contents = await file.readAsString();
    final document = XmlDocument.parse(contents);
    var rootElement = document.getElement('SaveGameData');

    final portraitPath =
        rootElement?.getElement('portraitName')?.innerText ?? "";
    final characterName =
        rootElement?.getElement('characterName')?.innerText ?? "";
    final characterLevel =
        int.tryParse(
          rootElement?.getElement('characterLevel')?.innerText ?? '0',
        ) ??
        0;
    final saveFileVersion =
        rootElement?.getElement('saveFileVersion')?.innerText ?? "";
    final saveDateString = rootElement?.getElement('saveDate')?.innerText ?? "";

    DateTime saveDate = DateTime.now();
    try {
      saveDate = DateFormat("yyyy-MM-dd HH:mm:ss.SS")
          // Save file dates are always in UTC
          .parse(saveDateString.replaceAll(' UTC', ''), true);
    } catch (e) {
      Fimber.e('Error parsing save date: $e');
    }

    final compressed =
        rootElement?.getElement('compressed')?.innerText == 'true';
    final isIronMode =
        rootElement?.getElement('isIronMode')?.innerText == 'true';
    final difficulty =
        rootElement?.getElement('difficulty')?.innerText ?? "normal";

    final gameDateElement = rootElement?.getElement('gameDate');
    final secondsPerDay =
        double.tryParse(
          gameDateElement?.getElement('secondsPerDay')?.innerText ?? '10.0',
        ) ??
        10.0;
    final timestamp =
        int.tryParse(
          gameDateElement?.getElement('timestamp')?.innerText ?? '0',
        ) ??
        0;

    // Reading mods
    final modsElement = rootElement?.getElement('allModsEverEnabled');
    Map<int, SaveFileMod> modsMap = {};

    if (modsElement != null) {
      modsElement.findElements('EnabledModData').forEach((modData) {
        final spec = modData.getElement('spec');
        if (spec != null) {
          final id = spec.getElement('id')?.innerText ?? "";
          final name = spec.getElement('name')?.innerText ?? "";
          final versionInfo = spec.getElement('versionInfo');
          final version = Version(
            raw: versionInfo?.getElement('string')?.innerText,
            major: versionInfo?.getElement('major')?.innerText ?? "",
            minor: versionInfo?.getElement('minor')?.innerText ?? "",
            patch: versionInfo?.getElement('patch')?.innerText ?? "",
          );

          final zAttribute = int.tryParse(spec.getAttribute('z') ?? '');
          if (zAttribute != null) {
            modsMap[zAttribute] = SaveFileMod(
              id: id,
              name: name,
              version: version,
            );
          }
        }
      });
    }

    final enabledModsElement = rootElement?.getElement('enabledMods');
    List<SaveFileMod> enabledMods = [];

    if (enabledModsElement != null) {
      enabledModsElement.findElements('EnabledModData').forEach((modData) {
        final specRef = modData.getElement('spec')?.getAttribute('ref');
        if (specRef != null) {
          final modRef = int.tryParse(specRef);
          if (modRef != null && modsMap.containsKey(modRef)) {
            enabledMods.add(modsMap[modRef]!);
          }
        }
      });
    }

    return SaveFile(
      id: folderOfSave.name,
      folder: folderOfSave,
      characterName: characterName,
      characterLevel: characterLevel,
      portraitPath: portraitPath,
      saveFileVersion: saveFileVersion,
      saveDate: saveDate,
      mods: enabledMods,
      compressed: compressed,
      isIronMode: isIronMode,
      difficulty: difficulty,
      gameTimestamp: timestamp,
      secondsPerDay: secondsPerDay,
    );
  }
}

class SaveFile {
  final String id;
  final Directory folder;
  final String characterName;
  final int characterLevel;
  final String? portraitPath;
  final String? saveFileVersion;
  final DateTime? saveDate;
  final List<SaveFileMod> mods;
  final bool? compressed;
  final bool? isIronMode;
  final String? difficulty;
  final int? gameTimestamp;
  final double? secondsPerDay;

  SaveFile({
    required this.id,
    required this.folder,
    required this.characterName,
    required this.characterLevel,
    this.portraitPath,
    this.saveFileVersion,
    required this.saveDate,
    required this.mods,
    required this.compressed,
    required this.isIronMode,
    required this.difficulty,
    required this.gameTimestamp,
    required this.secondsPerDay,
  });
}

class SaveFileMod {
  final String id;
  final String name;
  final Version version;

  SaveFileMod({required this.id, required this.name, required this.version});

  ShallowModVariant toShallowModVariant() {
    return ShallowModVariant(
      modId: id,
      modName: name,
      version: version,
      smolVariantId: createSmolId(id, version),
    );
  }
}
