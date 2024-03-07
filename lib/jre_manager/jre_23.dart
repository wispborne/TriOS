import 'dart:io';

import 'package:dart_extensions_methods/dart_extension_methods.dart';
import 'package:fimber/fimber.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:http/http.dart' as http;
import 'package:trios/jre_manager/jre_manager_logic.dart';
import 'package:trios/models/download_progress.dart';
import 'package:trios/models/mod_info_json.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/util.dart';

import '../libarchive/libarchive.dart';
import '../trios/settings/settings.dart';

part '../generated/jre_manager/jre_23.freezed.dart';
part '../generated/jre_manager/jre_23.g.dart';

final jre23jdkDownloadProgress = StateProvider<DownloadProgress?>((ref) => null);
final jdk23ConfigDownloadProgress = StateProvider<DownloadProgress?>((ref) => null);

class Jre23 {
  static const _gameFolderFilesFolderNamePart = "Files to put into starsector";
  static const _vmParamsFolderNamePart = "Pick VMParam";

  static Future<void> installJre23(WidgetRef ref) async {
    await downloadJre23JdkForPlatform(ref, (await getVersionCheckerInfo())!);
  }

  static Future<void> downloadJre23JdkForPlatform(WidgetRef ref, Jre23VersionChecker versionChecker) async {
    final gamePath = ref.read(appSettings.select((value) => value.gameDir))?.toDirectory();
    if (gamePath == null) {
      Fimber.e("Game path not set");
      return;
    }

    final savePath = Directory.systemTemp.createTempSync('trios_jre23-').absolute.normalize;
    var libArchive = LibArchive();

    installJRE23Jdk(ref, versionChecker, libArchive, gamePath, savePath);
    installJRE23Config(ref, versionChecker, libArchive, gamePath, savePath);
  }

  static Future<void> installJRE23Config(WidgetRef ref, Jre23VersionChecker versionChecker, LibArchive libArchive,
      Directory gamePath, Directory savePath) async {
    final himiUrl = switch (currentPlatform) {
      TargetPlatform.linux => versionChecker.linuxConfigDownload,
      TargetPlatform.windows => versionChecker.windowsConfigDownload,
      _ => throw UnsupportedError("$currentPlatform not supported for JRE 23"),
    };

    if (himiUrl == null) {
      Fimber.e("No JRE 23 Himi/config download link for $currentPlatform");
      return;
    }
    // Download config zip
    final configZip = downloadFile(himiUrl, savePath, null, onProgress: (bytesReceived, contentLength) {
      ref.read(jdk23ConfigDownloadProgress.notifier).state = DownloadProgress(bytesReceived, contentLength);
    });

    // Extract config zip
    final filesInConfigZip = (await libArchive.extractEntriesInArchive(await configZip, savePath.absolute.path))
        .map((e) => e?.extractedFile.normalize)
        .whereType<File>()
        .toList();

    final gameFolderFilesFolder = filesInConfigZip
        .filter((file) => file.path.containsIgnoreCase(_gameFolderFilesFolderNamePart))
        .rootFolder()!
        .path
        .toDirectory();

    // Move to game folder
    Fimber.i('Moving "$gameFolderFilesFolder" to "$gamePath"');
    gameFolderFilesFolder.moveDirectory(gamePath, overwrite: true);

    // Find VMParams
    final vmParamsFile = filesInConfigZip
        .filter((file) => file.path.containsIgnoreCase(_vmParamsFolderNamePart))
        .rootFolder()! // \1. Pick VMParam Size Here\
        .listSync()
        .first // \1. Pick VMParam Size Here\10GB\
        .toDirectory()
        .listSync()
        .first
        .toFile(); // \1. Pick VMParam Size Here\10GB\Miko_R3.txt

    if (!vmParamsFile.existsSync()) {
      Fimber.e("VMParams file not found in '$savePath'");
      return;
    }

    final vmParams = vmParamsFile.readAsStringSync();
    Fimber.i("VMParams: $vmParams");
    // Save the filename of the VMParams file, in case it changes later from "Miko_R3.txt".
    ref.read(appSettings.notifier).update((it) => it.copyWith(jre23VmparamsFilename: vmParamsFile.nameWithExtension));

    // Set ram to player's vanilla amount
    final vanillaRam = ref.read(currentRamAmountInMb).value;
    final newVmparams = vmParams
        .replaceAll(maxRamInVmparamsRegex, "-Xmx${vanillaRam}m")
        .replaceAll(minRamInVmparamsRegex, "-Xms${vanillaRam}m");

    // Move VMParams to game folder
    Fimber.i('Moving "$vmParamsFile" to "$gamePath"');
    gamePath.resolve(vmParamsFile.nameWithExtension).toFile().writeAsStringSync(newVmparams);
  }

  static Future<void> installJRE23Jdk(WidgetRef ref, Jre23VersionChecker versionChecker, LibArchive libArchive,
      Directory gamePath, Directory savePath) async {
    final jdkUrl = switch (currentPlatform) {
      TargetPlatform.linux => versionChecker.linuxJDKDownload,
      TargetPlatform.windows => versionChecker.windowsJDKDownload,
      _ => throw UnsupportedError("$currentPlatform not supported for JRE 23"),
    };

    if (jdkUrl == null) {
      Fimber.e("No JRE 23 JDK download link for $currentPlatform");
      return;
    }
    final jdkZip = downloadFile(jdkUrl, savePath, null, onProgress: (bytesReceived, contentLength) {
      ref.read(jre23jdkDownloadProgress.notifier).state = DownloadProgress(bytesReceived, contentLength);
    });

    final filesInJdkZip = libArchive.listEntriesInArchive(await jdkZip);

    if (filesInJdkZip.isEmpty) {
      Fimber.e("No files in JRE 23 JDK zip");
      return;
    }

    final topLevelFolder = filesInJdkZip.minByOrNull<num>((element) => element.pathName.length)!.pathName;
    if (gamePath.resolve(topLevelFolder).path.toDirectory().existsSync()) {
      Fimber.i("JRE 23 JDK already exists in game folder. Aborting.");
      return;
    }

    final extractedJdkFiles = await libArchive.extractEntriesInArchive(await jdkZip, gamePath.absolute.path);
    Fimber.i("Extracted JRE 23 JDK files: $extractedJdkFiles");
  }

  static Future<Jre23VersionChecker?> getVersionCheckerInfo() async {
    const versionCheckerUrl = "https://raw.githubusercontent.com/Yumeris/Mikohime_Repo/main/Java23.version";

    final response = await http.get(Uri.parse(versionCheckerUrl));

    if (response.statusCode == 200) {
      final parsableJson = response.body.fixJsonToMap();
      final versionChecker = Jre23VersionChecker.fromJson(parsableJson);
      Fimber.i("Jre23VersionChecker: $versionChecker");
      return versionChecker;
    }

    return null;
  }
}

// @jsonSerializable
// class Jre23VersionChecker {
//   String masterVersionFile;
//   String modName;
//   // @JsonProperty(converter: ToNullableStringJsonConverter())
//   int? modThreadId;
//   Version_095a modVersion;
//   String starsectorVersion;
//
//   String? windowsJDKDownload;
//   String? windowsConfigDownload;
//
//   String? linuxJDKDownload;
//   String? linuxConfigDownload;
//
//   Jre23VersionChecker(this.masterVersionFile, this.modName, this.modThreadId, this.modVersion, this.starsectorVersion,
//       this.windowsJDKDownload, this.windowsConfigDownload, this.linuxJDKDownload, this.linuxConfigDownload);
// }

@freezed
class Jre23VersionChecker with _$Jre23VersionChecker {
  factory Jre23VersionChecker({
    required final String masterVersionFile,
    required final String modName,
    final int? modThreadId,
    required final Version_095a modVersion,
    required final String starsectorVersion,
    final String? windowsJDKDownload,
    final String? windowsConfigDownload,
    final String? linuxJDKDownload,
    final String? linuxConfigDownload,
  }) = _Jre23VersionChecker;

  factory Jre23VersionChecker.fromJson(Map<String, dynamic> json) => _$Jre23VersionCheckerFromJson(json);
}
