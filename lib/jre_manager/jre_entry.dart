import 'dart:io';

import 'package:dart_extensions_methods/dart_extension_methods.dart';
import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:trios/compression/archive.dart';
import 'package:trios/compression/libarchive/libarchive.dart';
import 'package:trios/models/download_progress.dart';
import 'package:trios/models/version.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/utils/dart_mappable_utils.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/logging.dart';
import 'package:trios/utils/util.dart';

import 'jre_manager_logic.dart';

part 'jre_entry.mapper.dart';

abstract class JreEntry implements Comparable<JreEntry> {
  /// e.g. C:\Program Files (x86)\Starsector
  final Directory gamePath;
  JreVersion version;

  JreEntry(this.gamePath, this.version);

  int get versionInt => version.version;

  String get versionString => version.versionString;

  /// e.g. vmparams, Miko_R3.txt, Miko_R4.txt
  String get vmParamsFileRelativePath;

  @override
  int compareTo(JreEntry other) => version.compareTo(other.version);

  @override
  int get hashCode => version.hashCode;

  @override
  bool operator ==(Object other) =>
      other is JreEntry && version == other.version;

  bool get isSupportedByTriOS =>
      JreManager.supportedJreVersions.contains(version.version);
}

abstract class JreEntryInstalled extends JreEntry {
  String? ramAmountInMb;
  final Directory jreRelativePath;

  JreEntryInstalled(super.gamePath, this.jreRelativePath, super.version) {
    try {
      ramAmountInMb = getRamAmountFromVmparamsInMb(readVmParamsFile());
    } catch (e) {
      Fimber.w("Error reading vmparams file: $vmParamsFileAbsolutePath", ex: e);
    }
  }

  bool get isCustomJre;

  bool get isStandardJre;

  Future<void> setRamAmountInMb(double ramAmountInMb) async {
    final newRamStr = "${ramAmountInMb.toStringAsFixed(0)}m";
    final newVmparams = vmParamsFileAbsolutePath
        .readAsStringSync()
        .replaceAll(maxRamInVmparamsRegex, newRamStr)
        .replaceAll(minRamInVmparamsRegex, newRamStr);
    await vmParamsFileAbsolutePath.writeAsString(newVmparams);
  }

  String readVmParamsFile() =>
      vmParamsFileAbsolutePath.toFile().readAsStringSync();

  Directory get jreAbsolutePath =>
      gamePath.resolve(jreRelativePath.path).normalize().toDirectory();

  File get vmParamsFileAbsolutePath =>
      gamePath.resolve(vmParamsFileRelativePath).normalize().toFile();

  bool isActive({required List<JreEntryInstalled> activeJres}) =>
      activeJres.any((it) => it == this);

  Future<bool> canWriteToVmParamsFile() async =>
      vmParamsFileAbsolutePath.existsSync() &&
      await vmParamsFileAbsolutePath.isWritable();

  /// True if we can currently launch the game with this JRE.
  /// So, if it is a standard JRE, it needs to be in the `jre` folder.
  /// If it is a custom JRE, it needs to have all files present.
  bool hasAllFilesReadyToLaunch();

  /// If not empty, then entry is "broken" and cannot be used. Lists what's missing.
  List<String> missingFiles();

  /// Parses the amount of RAM from the vmparams file
  String? getRamAmountFromVmparamsInMb(String vmparams) {
    var ramMatch = maxRamInVmparamsRegex.stringMatch(vmparams);
    if (ramMatch == null) {
      return null;
    }
    // eg 2048m
    var amountWithLowercaseChar = ramMatch.toLowerCase();
    // remove all non-numeric characters
    final replace = RegExp(r"[^\d]");
    final valueAsDouble = double.tryParse(
      amountWithLowercaseChar.replaceAll(replace, ""),
    );
    if (valueAsDouble == null) return null;

    final amountInMb =
        amountWithLowercaseChar.endsWith("g")
            // Convert from GB to MB
            ? (valueAsDouble * mbPerGb).toStringAsFixed(0)
            : valueAsDouble.toStringAsFixed(0);
    return amountInMb;
  }
}

/// Represents a JRE version.
/// e.g. 1.8.0_291, 1.8.0_291-b10, 1.8.0_291-b10-jre
@MappableClass()
class JreVersion with JreVersionMappable implements Comparable<JreVersion> {
  final String versionString;

  JreVersion(this.versionString);

  int get version {
    try {
      return versionString.startsWith("1.")
          ? int.parse(versionString.substring(2, 3))
          : int.parse(
            versionString.takeWhile(
              (char) => char != '.' && char != '-' && char != '+',
            ),
          );
    } catch (e, st) {
      Fimber.d(e.toString(), ex: e, stacktrace: st);
      return 0;
    }
  }

  @override
  int compareTo(JreVersion other) =>
      versionString.compareTo(other.versionString);
}

class StandardInstalledJreEntry extends JreEntryInstalled {
  StandardInstalledJreEntry(
    super.gamePath,
    super.jreRelativePath,
    super.version,
  );

  @override
  bool get isCustomJre => false;

  @override
  bool get isStandardJre => true;

  @override
  String get vmParamsFileRelativePath => switch (currentPlatform) {
    TargetPlatform.windows => "vmparams",
    TargetPlatform.linux => "starsector.sh",
    TargetPlatform.macOS => "starsector_mac.sh",
    _ => throw UnsupportedError("Platform not supported: $currentPlatform"),
  };

  @override
  bool hasAllFilesReadyToLaunch() =>
      vmParamsFileAbsolutePath.existsSync() &&
      jreRelativePath.name == Constants.gameJreFolderName &&
      jreAbsolutePath.existsSync();

  @override
  List<String> missingFiles() {
    final missingFiles = <String>[];
    if (!vmParamsFileAbsolutePath.existsSync()) {
      missingFiles.add(vmParamsFileRelativePath);
    }

    return missingFiles;
  }
}

abstract class CustomInstalledJreEntry extends JreEntryInstalled {
  CustomInstalledJreEntry(super.gamePath, super.jreRelativePath, super.version);

  @override
  bool get isCustomJre => true;

  @override
  bool get isStandardJre => false;

  String launchFileName(bool silent);
}

abstract class MikohimeCustomJreEntry extends CustomInstalledJreEntry {
  MikohimeCustomJreEntry(super.gamePath, super.jreRelativePath, super.version);

  Directory get mikohimeFolder =>
      gamePath.resolve("mikohime").normalize().toDirectory();

  @override
  bool hasAllFilesReadyToLaunch() =>
      vmParamsFileAbsolutePath.existsSync() &&
      jreAbsolutePath.existsSync() &&
      mikohimeFolder.existsSync();
  // Ideally would check that the mikohime folder is for this specific JRE.
  // But idk how.

  @override
  List<String> missingFiles() {
    final missingFiles = <String>[];
    if (!vmParamsFileAbsolutePath.existsSync()) {
      missingFiles.add(vmParamsFileRelativePath);
    }
    if (!jreAbsolutePath.existsSync()) {
      missingFiles.add(jreRelativePath.path);
    }
    if (!mikohimeFolder.existsSync()) {
      missingFiles.add(mikohimeFolder.name);
    }

    return missingFiles;
  }
}

class Jre23InstalledJreEntry extends MikohimeCustomJreEntry {
  Jre23InstalledJreEntry(super.gamePath, super.jreRelativePath, super.version);

  @override
  String get vmParamsFileRelativePath => "Miko_R3.txt";

  @override
  String launchFileName(bool silent) =>
      silent ? "Miko_Silent.bat" : "Miko_Rouge.bat";
}

class Jre24InstalledJreEntry extends MikohimeCustomJreEntry {
  Jre24InstalledJreEntry(super.gamePath, super.jreRelativePath, super.version);

  @override
  String get vmParamsFileRelativePath => "Miko_R4.txt";

  @override
  String launchFileName(bool silent) =>
      silent ? "Miko_Silent.bat" : "Miko_Rouge.bat";
}

abstract class JreToDownload extends JreEntry {
  CustomJreNotifier _createDownloadProvider();

  JreToDownload(super.gamePath, super.version) {
    downloadProvider =
        AsyncNotifierProvider<CustomJreNotifier, CustomJreDownloadState>(
          () => _createDownloadProvider(),
        );
  }

  late AsyncNotifierProvider<CustomJreNotifier, CustomJreDownloadState>
  downloadProvider;
}

abstract class CustomJreToDownload extends JreToDownload {
  CustomJreToDownload(super.gamePath, super.version);

  String get versionCheckerUrl;
}

class Jre23JreToDownload extends CustomJreToDownload {
  Jre23JreToDownload(super.gamePath, super.version);

  @override
  CustomJreNotifier _createDownloadProvider() =>
      CustomJreNotifier(versionString, versionCheckerUrl);

  @override
  String get versionCheckerUrl =>
      "https://raw.githubusercontent.com/Yumeris/Mikohime_Repo/main/Java23.version";

  @override
  String get vmParamsFileRelativePath => "Miko_R3.txt";
}

class Jre24JreToDownload extends CustomJreToDownload {
  Jre24JreToDownload(super.gamePath, super.version);

  @override
  CustomJreNotifier _createDownloadProvider() =>
      CustomJreNotifier(versionString, versionCheckerUrl);

  @override
  String get versionCheckerUrl =>
      "https://gist.githubusercontent.com/wispborne/bbf0b9f68fe7eb9954e399fd1d6979d6/raw/Mikohime_Java_24.version";

  @override
  String get vmParamsFileRelativePath => "Miko_R4.txt";
}

class CustomJreNotifier extends AsyncNotifier<CustomJreDownloadState> {
  static const _gameFolderFilesFolderNamePart = "Files to put into starsector";
  static const _vmParamsFolderNamePart = "Pick VMParam";

  final String _jreVersion;
  final String _versionCheckerUrl;
  CustomJreDownloadState _mikohimeDownloadState = CustomJreDownloadState();
  CustomJreDownloadState _jdkDownloadState = CustomJreDownloadState();

  CustomJreNotifier(this._jreVersion, this._versionCheckerUrl);

  @override
  Future<CustomJreDownloadState> build() async {
    // Initialize the state
    return CustomJreDownloadState();
  }

  void _updateDownloadState() {
    state = AsyncValue.data(
      CustomJreDownloadState.aggregate({
        "jdk": _jdkDownloadState,
        "mikohime": _mikohimeDownloadState,
      }),
    );
  }

  Future<void> installCustomJre() async {
    _mikohimeDownloadState = CustomJreDownloadState();
    _jdkDownloadState = CustomJreDownloadState();

    final gamePath =
        ref.read(appSettings.select((value) => value.gameDir))?.toDirectory();
    if (gamePath == null) {
      Fimber.e("Game path not set");
      state = AsyncValue.error("Game path not set", StackTrace.current);
      return;
    }

    final customJreInfo = await _getVersionCheckerInfo();

    if (customJreInfo == null) {
      Fimber.e(
        "Custom JRE version checker file not found at $_versionCheckerUrl",
      );
      state = AsyncValue.error(
        "Custom JRE version checker file not found.",
        StackTrace.current,
      );
      return;
    }

    final archive = ref.read(archiveProvider).requireValue;
    var versionChecker = customJreInfo;
    final savePath =
        Directory.systemTemp
            .createTempSync('trios_jre$_jreVersion-')
            .absolute
            .normalize;

    state = AsyncValue.loading();

    try {
      final jdkZip = _downloadCustomJreJdkForPlatform(versionChecker, savePath);
      final configZip = _downloadCustomJreConfig(versionChecker, savePath);
      await _installCustomJREConfig(
        archive,
        gamePath,
        savePath,
        await configZip,
      );
      await _installCustomJREJdk(archive, gamePath, await jdkZip);

      state = AsyncValue.data(state.value!.copyWith(isInstalling: false));
    } catch (e, stackTrace) {
      Fimber.e(
        "Error installing JRE $_jreVersion",
        ex: e,
        stacktrace: stackTrace,
      );
      state = AsyncValue.error(e, stackTrace);
    } finally {
      Fimber.i("Deleting temp folder $savePath");
      savePath.deleteSync(recursive: true);
    }
  }

  Future<CustomJreVersionCheckerFile?> _getVersionCheckerInfo() async {
    final response = await http.get(Uri.parse(_versionCheckerUrl));

    if (response.statusCode == 200) {
      final parsableJson = response.body.fixJson();
      final versionChecker = CustomJreVersionCheckerFileMapper.fromJson(
        parsableJson,
      );
      // Fimber.i("Jre23VersionChecker: $versionChecker");
      return versionChecker;
    }

    return null;
  }

  Future<File> _downloadCustomJreJdkForPlatform(
    CustomJreVersionCheckerFile versionChecker,
    Directory savePath,
  ) async {
    final jdkUrl = switch (currentPlatform) {
      TargetPlatform.linux => versionChecker.linuxJDKDownload,
      TargetPlatform.windows => versionChecker.windowsJDKDownload,
      _ =>
        throw UnsupportedError(
          "$currentPlatform not supported for JRE $_jreVersion",
        ),
    };

    if (jdkUrl == null) {
      Fimber.e("No JRE $_jreVersion JDK download link for $currentPlatform");
      throw UnsupportedError(
        "No JRE $_jreVersion JDK download link for $currentPlatform",
      );
    }

    final jdkZip = downloadFile(
      jdkUrl,
      savePath,
      null,
      onProgress: (bytesReceived, contentLength) {
        _jdkDownloadState = _jdkDownloadState.copyWith(
          downloadProgress: TriOSDownloadProgress(bytesReceived, contentLength),
        );
        _updateDownloadState();
      },
    );

    return jdkZip;
  }

  Future<File> _downloadCustomJreConfig(
    CustomJreVersionCheckerFile versionChecker,
    Directory savePath,
  ) async {
    final himiUrl = switch (currentPlatform) {
      TargetPlatform.linux => versionChecker.linuxConfigDownload,
      TargetPlatform.windows => versionChecker.windowsConfigDownload,
      _ =>
        throw UnsupportedError(
          "$currentPlatform not supported for JRE $_jreVersion",
        ),
    };

    if (himiUrl == null) {
      Fimber.e(
        "No JRE $_jreVersion Himi/config download link for $currentPlatform",
      );
      throw UnsupportedError(
        "No JRE $_jreVersion Hime/config download link for $currentPlatform",
      );
    }

    final configZip = downloadFile(
      himiUrl,
      savePath,
      null,
      onProgress: (bytesReceived, contentLength) {
        _mikohimeDownloadState = _mikohimeDownloadState.copyWith(
          downloadProgress: TriOSDownloadProgress(bytesReceived, contentLength),
        );
        _updateDownloadState();
      },
    );

    return configZip;
  }

  Future<void> _installCustomJREJdk(
    ArchiveInterface archive,
    Directory gamePath,
    File jdkZip,
  ) async {
    final filesInJdkZip = await archive.listFiles(jdkZip);

    if (filesInJdkZip.isEmpty) {
      Fimber.e("No files in JRE $_jreVersion JDK zip");
      return;
    }

    final topLevelFolder =
        filesInJdkZip.minByOrNull<num>((element) => element.path.length)!.path;
    if (gamePath.resolve(topLevelFolder).path.toDirectory().existsSync()) {
      Fimber.i("JRE $_jreVersion JDK already exists in game folder. Aborting.");
      return;
    }

    final extractedJdkFiles = await archive.extractEntriesInArchive(
      jdkZip,
      gamePath.absolute.path,
    );
    Fimber.i(
      "Extracted JRE $_jreVersion JDK files: ${extractedJdkFiles.joinToString(separator: ', ', transform: (it) => it?.extractedFile.path ?? "")}",
    );
  }

  Future<void> _installCustomJREConfig(
    ArchiveInterface archive,
    Directory gamePath,
    Directory savePath,
    File configZip,
  ) async {
    final filesInConfigZip =
        (await archive.extractEntriesInArchive(
          configZip,
          savePath.absolute.path,
        )).map((e) => e?.extractedFile.normalize).whereType<File>().toList();
    Fimber.i(
      "Extracted JRE $_jreVersion Himemi files: ${filesInConfigZip.joinToString(separator: ', ', transform: (it) => it.path)}",
    );

    final gameFolderFilesFolder =
        filesInConfigZip
            .filter(
              (file) =>
                  file.path.containsIgnoreCase(_gameFolderFilesFolderNamePart),
            )
            .rootFolder()!
            .path
            .toDirectory();

    Fimber.i('Moving "$gameFolderFilesFolder" to "$gamePath"');
    await gameFolderFilesFolder.moveDirectory(gamePath, overwrite: true);
    Fimber.i('Moved "$gameFolderFilesFolder" to "$gamePath"');

    Fimber.i("Looking for VMParams file");
    final vmParamsFile =
        filesInConfigZip
            .filter(
              (file) => file.path.containsIgnoreCase(_vmParamsFolderNamePart),
            )
            .rootFolder()!
            .listSync()
            .first
            .toDirectory()
            .listSync()
            .first
            .toFile();

    if (!vmParamsFile.existsSync()) {
      Fimber.e("VMParams file not found in '$savePath'");
      return;
    } else {
      Fimber.i("Found VMParams file: $vmParamsFile");
    }

    final vmParams = vmParamsFile.readAsStringSync();
    Fimber.d("VMParams: $vmParams");

    // ref.read(appSettings.notifier).update((it) =>
    //     it.copyWith(jre23VmparamsFilename: vmParamsFile.nameWithExtension));

    final vanillaRam = ref.read(currentRamAmountInMb).value;
    final newVmparams = vmParams
        .replaceAll(maxRamInVmparamsRegex, "${vanillaRam}m")
        .replaceAll(minRamInVmparamsRegex, "${vanillaRam}m");

    Fimber.i('Writing "$vmParamsFile" to "$gamePath"');
    gamePath
        .resolve(vmParamsFile.nameWithExtension)
        .toFile()
        .writeAsStringSync(newVmparams);
  }
}

@MappableClass()
class CustomJreDownloadState with CustomJreDownloadStateMappable {
  final TriOSDownloadProgress? downloadProgress;
  final String? errorMessage;
  final bool isInstalling;

  CustomJreDownloadState({
    this.downloadProgress,
    this.errorMessage,
    this.isInstalling = false,
  });

  /// Aggregates a map of [CustomJreDownloadState] objects into one.
  ///
  /// - Sums the download progress fields across all states via [TriOSDownloadProgress.aggregate].
  /// - Chooses the first non-null [errorMessage] from any state.
  /// - Marks [isInstalling] as true if any state is installing.
  static CustomJreDownloadState aggregate(
    Map<String, CustomJreDownloadState> states,
  ) {
    if (states.isEmpty) {
      return CustomJreDownloadState();
    }

    final progressList =
        states.values
            .map((s) => s.downloadProgress)
            .whereType<TriOSDownloadProgress>()
            .toList();

    final aggregatedProgress =
        progressList.isEmpty
            ? null
            : TriOSDownloadProgress.aggregate(progressList);

    final firstError = states.values
        .map((s) => s.errorMessage)
        .firstWhere((err) => err != null, orElse: () => null);

    final anyInstalling = states.values.any((s) => s.isInstalling);

    return CustomJreDownloadState(
      downloadProgress: aggregatedProgress,
      errorMessage: firstError,
      isInstalling: anyInstalling,
    );
  }
}

@MappableClass()
class CustomJreVersionCheckerFile with CustomJreVersionCheckerFileMappable {
  final String masterVersionFile;
  final String modName;
  final int? modThreadId;

  @MappableField(hook: VersionHook())
  final Version modVersion;

  final String starsectorVersion;
  final String? windowsJDKDownload;
  final String? windowsConfigDownload;
  final String? linuxJDKDownload;
  final String? linuxConfigDownload;

  CustomJreVersionCheckerFile({
    required this.masterVersionFile,
    required this.modName,
    this.modThreadId,
    required this.modVersion,
    required this.starsectorVersion,
    this.windowsJDKDownload,
    this.windowsConfigDownload,
    this.linuxJDKDownload,
    this.linuxConfigDownload,
  });
}
