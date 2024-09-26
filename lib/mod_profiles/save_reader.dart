import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:trios/models/version.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/logging.dart';
import 'package:xml/xml.dart';

// Save file provider using AsyncNotifier
final saveFileProvider =
    AsyncNotifierProvider<SaveFileNotifier, List<SaveFile>>(
  SaveFileNotifier.new,
);

// SaveFileNotifier class to manage saves asynchronously
class SaveFileNotifier extends AsyncNotifier<List<SaveFile>> {
  final String descriptorFileName = "descriptor.xml";
  final List<String> datePatterns = [
    "yyyy-MM-dd HH:mm:ss.SSS zzz",
    "yyyy-MM-dd HH:mm:ss.S zzz",
  ];

  @override
  Future<List<SaveFile>> build() async {
    return await readAllSaves();
  }

  Future<List<SaveFile>> readAllSaves({bool forceRefresh = false}) async {
    final gameFolder = ref.read(AppState.gameFolder).valueOrNull;
    if (gameFolder == null) {
      Fimber.e("Game folder not set");
      return [];
    }

    final saveDir = Directory("${gameFolder.path}/saves");

    if (!forceRefresh && state.valueOrNull?.isNotEmpty == true) {
      Fimber.i("Saves already loaded, not refreshing.");
      return state.value!;
    }

    if (!await saveDir.exists()) {
      Fimber.w("Save folder does not exist");
      return [];
    }

    final saveFolders = saveDir
        .listSync()
        .whereType<Directory>()
        .where((d) => d.path.startsWith("save"))
        .toList();

    final newSaves = await Future.wait(saveFolders.map((folder) async {
      try {
        return await readSave(folder);
      } catch (e) {
        Fimber.w("Failed to read save folder ${folder.path}: $e");
        return null;
      }
    }));

    return newSaves.whereNotNull().toList();
  }

  Future<SaveFile> readSave(Directory saveFolder) async {
    final descriptorFile = File("${saveFolder.path}/$descriptorFileName");
    if (!await descriptorFile.exists()) {
      throw Exception("Descriptor file not found in ${saveFolder.path}");
    } else {
      Fimber.i("Reading save from ${saveFolder.path}");
    }

    final document = XmlDocument.parse(await descriptorFile.readAsString());
    final characterName = document.getElement('characterName')?.text ?? '';
    final characterLevel =
        int.tryParse(document.getElement('characterLevel')?.text ?? '0') ?? 0;
    final portraitPath = document.getElement('portraitName')?.text;
    final saveFileVersion = document.getElement('saveFileVersion')?.text;
    final saveDateText = document.getElement('saveDate')?.text;

    final saveDate = _parseSaveDate(saveDateText);

    final modsElement = document.getElement('allModsEverEnabled');
    final Map<int, SaveFileMod> allMods =
        modsElement != null ? _parseMods(modsElement) : {};

    final enabledModsElement = document.getElement('enabledMods');
    final enabledMods = enabledModsElement != null
        ? _parseEnabledMods(enabledModsElement, allMods)
        : <SaveFileMod>[];

    return SaveFile(
      id: saveFolder.path.split('/').last,
      characterName: characterName,
      characterLevel: characterLevel,
      portraitPath: portraitPath,
      saveFileVersion: saveFileVersion,
      saveDate: saveDate,
      mods: enabledMods,
    );
  }

  Map<int, SaveFileMod> _parseMods(XmlElement modsElement) {
    return modsElement.findElements('mod').map((modElement) {
      final id = modElement.getElement('id')?.text ?? '';
      final name = modElement.getElement('name')?.text ?? '';
      final versionElement = modElement.getElement('version');
      final version = Version(
        raw: versionElement?.getElement('string')?.text ?? '',
        major: versionElement?.getElement('major')?.text ?? '',
        minor: versionElement?.getElement('minor')?.text ?? '',
        patch: versionElement?.getElement('patch')?.text ?? '',
      );
      final ref = int.tryParse(modElement.getElement('z')?.text ?? '0') ?? 0;
      return MapEntry(ref, SaveFileMod(id: id, name: name, version: version));
    }).toMap();
  }

  List<SaveFileMod> _parseEnabledMods(
    XmlElement enabledModsElement,
    Map<int, SaveFileMod> allMods,
  ) {
    return enabledModsElement
        .findElements('mod')
        .map((modElement) {
          final ref =
              int.tryParse(modElement.getElement('ref')?.text ?? '0') ?? 0;
          return allMods[ref];
        })
        .whereType<SaveFileMod>()
        .toList();
  }

  DateTime _parseSaveDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return DateTime.now();
    for (var pattern in datePatterns) {
      try {
        return DateFormat(pattern).parse(dateString);
      } catch (e) {
        Fimber.w("Failed to parse date with pattern $pattern: $e");
      }
    }
    return DateTime.now();
  }
}

class SaveFile {
  final String id;
  final String characterName;
  final int characterLevel;
  final String? portraitPath;
  final String? saveFileVersion;
  final DateTime saveDate;
  final List<SaveFileMod> mods;

  SaveFile({
    required this.id,
    required this.characterName,
    required this.characterLevel,
    this.portraitPath,
    this.saveFileVersion,
    required this.saveDate,
    required this.mods,
  });
}

class SaveFileMod {
  final String id;
  final String name;
  final Version version;

  SaveFileMod({
    required this.id,
    required this.name,
    required this.version,
  });
}
