import 'dart:async';
import 'dart:io';

import 'package:dart_extensions_methods/dart_extension_methods.dart';
import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:trios/jre_manager/jre_manager_logic.dart';
import 'package:trios/models/download_progress.dart';
import 'package:trios/models/version.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/logging.dart';
import 'package:trios/utils/util.dart';

import '../libarchive/libarchive.dart';
import '../trios/settings/settings.dart';
import '../utils/dart_mappable_utils.dart';
import '../widgets/disable.dart';
import '../widgets/download_progress_indicator.dart';

part 'jre_23.mapper.dart';

final doesJre23ExistInGameFolderProvider = FutureProvider<bool>((ref) async {
  final gamePath =
      ref.read(appSettings.select((value) => value.gameDir))?.toDirectory();
  if (gamePath == null) {
    return false;
  }
  return doesJre23ExistInGameFolder(gamePath);
});

bool doesJre23ExistInGameFolder(Directory gameDir) {
  return gameDir.resolve("mikohime").toDirectory().existsSync() &&
      gameDir.resolve("Miko_Rouge.bat").toFile().existsSync();
}

// final jre23jdkTriOSDownloadProgress =
//     StateProvider<TriOSDownloadProgress?>((ref) => null);
// final jdk23ConfigTriOSDownloadProgress =
//     StateProvider<TriOSDownloadProgress?>((ref) => null);

// Define the state class
class Jre23State {
  final TriOSDownloadProgress? jre23jdkTriOSDownloadProgress;
  final TriOSDownloadProgress? jdk23ConfigTriOSDownloadProgress;
  final String? errorMessage;
  final bool isInstalling;

  Jre23State({
    this.jre23jdkTriOSDownloadProgress,
    this.jdk23ConfigTriOSDownloadProgress,
    this.errorMessage,
    this.isInstalling = false,
  });

  Jre23State copyWith({
    TriOSDownloadProgress? jre23jdkTriOSDownloadProgress,
    TriOSDownloadProgress? jdk23ConfigTriOSDownloadProgress,
    String? errorMessage,
    bool? isInstalling,
  }) {
    return Jre23State(
      jre23jdkTriOSDownloadProgress:
          jre23jdkTriOSDownloadProgress ?? this.jre23jdkTriOSDownloadProgress,
      jdk23ConfigTriOSDownloadProgress: jdk23ConfigTriOSDownloadProgress ??
          this.jdk23ConfigTriOSDownloadProgress,
      errorMessage: errorMessage ?? this.errorMessage,
      isInstalling: isInstalling ?? this.isInstalling,
    );
  }
}

class Jre23Notifier extends AsyncNotifier<Jre23State> {
  static const _gameFolderFilesFolderNamePart = "Files to put into starsector";
  static const _vmParamsFolderNamePart = "Pick VMParam";

  @override
  Future<Jre23State> build() async {
    // Initialize the state
    return Jre23State();
  }

  Future<void> installJre23() async {
    final gamePath =
        ref.read(appSettings.select((value) => value.gameDir))?.toDirectory();
    if (gamePath == null) {
      Fimber.e("Game path not set");
      state = AsyncValue.error("Game path not set", StackTrace.current);
      return;
    }

    var libArchive = LibArchive();
    var versionChecker = (await getVersionCheckerInfo())!;
    final savePath =
        Directory.systemTemp.createTempSync('trios_jre23-').absolute.normalize;

    state = AsyncValue.loading();

    try {
      final jdkZip =
          await downloadJre23JdkForPlatform(versionChecker, savePath);
      final configZip = await downloadJre23Config(versionChecker, savePath);
      await installJRE23Config(libArchive, gamePath, savePath, await configZip);
      await installJRE23Jdk(libArchive, gamePath, await jdkZip);

      state = AsyncValue.data(state.value!.copyWith(isInstalling: false));
    } catch (e, stackTrace) {
      Fimber.e("Error installing JRE 23", ex: e, stacktrace: stackTrace);
      state = AsyncValue.error(e, stackTrace);
    } finally {
      Fimber.i("Deleting temp folder $savePath");
      savePath.deleteSync(recursive: true);
    }
  }

  Future<File> downloadJre23JdkForPlatform(
      Jre23VersionChecker versionChecker, Directory savePath) async {
    final jdkUrl = switch (currentPlatform) {
      TargetPlatform.linux => versionChecker.linuxJDKDownload,
      TargetPlatform.windows => versionChecker.windowsJDKDownload,
      _ => throw UnsupportedError("$currentPlatform not supported for JRE 23"),
    };

    if (jdkUrl == null) {
      Fimber.e("No JRE 23 JDK download link for $currentPlatform");
      throw UnsupportedError(
          "No JRE 23 JDK download link for $currentPlatform");
    }

    final jdkZip = downloadFile(jdkUrl, savePath, null,
        onProgress: (bytesReceived, contentLength) {
      state = AsyncValue.data(state.value!.copyWith(
        jre23jdkTriOSDownloadProgress:
            TriOSDownloadProgress(bytesReceived, contentLength),
      ));
    });

    return jdkZip;
  }

  Future<File> downloadJre23Config(
      Jre23VersionChecker versionChecker, Directory savePath) async {
    final himiUrl = switch (currentPlatform) {
      TargetPlatform.linux => versionChecker.linuxConfigDownload,
      TargetPlatform.windows => versionChecker.windowsConfigDownload,
      _ => throw UnsupportedError("$currentPlatform not supported for JRE 23"),
    };

    if (himiUrl == null) {
      Fimber.e("No JRE 23 Himi/config download link for $currentPlatform");
      throw UnsupportedError(
          "No JRE 23 Hime/config download link for $currentPlatform");
    }

    final configZip = downloadFile(himiUrl, savePath, null,
        onProgress: (bytesReceived, contentLength) {
      state = AsyncValue.data(state.value!.copyWith(
        jdk23ConfigTriOSDownloadProgress:
            TriOSDownloadProgress(bytesReceived, contentLength),
      ));
    });

    return configZip;
  }

  Future<void> installJRE23Jdk(
      LibArchive libArchive, Directory gamePath, File jdkZip) async {
    final filesInJdkZip = libArchive.listEntriesInArchive(jdkZip);

    if (filesInJdkZip.isEmpty) {
      Fimber.e("No files in JRE 23 JDK zip");
      return;
    }

    final topLevelFolder = filesInJdkZip
        .minByOrNull<num>((element) => element.pathName.length)!
        .pathName;
    if (gamePath.resolve(topLevelFolder).path.toDirectory().existsSync()) {
      Fimber.i("JRE 23 JDK already exists in game folder. Aborting.");
      return;
    }

    final extractedJdkFiles = await libArchive.extractEntriesInArchive(
        jdkZip, gamePath.absolute.path);
    Fimber.i(
        "Extracted JRE 23 JDK files: ${extractedJdkFiles.joinToString(separator: ', ', transform: (it) => it?.extractedFile.path ?? "")}");
  }

  Future<void> installJRE23Config(LibArchive libArchive, Directory gamePath,
      Directory savePath, File configZip) async {
    final filesInConfigZip = (await libArchive.extractEntriesInArchive(
            configZip, savePath.absolute.path))
        .map((e) => e?.extractedFile.normalize)
        .whereType<File>()
        .toList();
    Fimber.i(
        "Extracted JRE 23 Himemi files: ${filesInConfigZip.joinToString(separator: ', ', transform: (it) => it.path)}");

    final gameFolderFilesFolder = filesInConfigZip
        .filter((file) =>
            file.path.containsIgnoreCase(_gameFolderFilesFolderNamePart))
        .rootFolder()!
        .path
        .toDirectory();

    Fimber.i('Moving "$gameFolderFilesFolder" to "$gamePath"');
    await gameFolderFilesFolder.moveDirectory(gamePath, overwrite: true);
    Fimber.i('Moved "$gameFolderFilesFolder" to "$gamePath"');

    Fimber.i("Looking for VMParams file");
    final vmParamsFile = filesInConfigZip
        .filter((file) => file.path.containsIgnoreCase(_vmParamsFolderNamePart))
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

    ref.read(appSettings.notifier).update((it) =>
        it.copyWith(jre23VmparamsFilename: vmParamsFile.nameWithExtension));

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

  Future<Jre23VersionChecker?> getVersionCheckerInfo() async {
    const versionCheckerUrl =
        "https://raw.githubusercontent.com/Yumeris/Mikohime_Repo/main/Java23.version";

    final response = await http.get(Uri.parse(versionCheckerUrl));

    if (response.statusCode == 200) {
      final parsableJson = response.body.fixJson();
      final versionChecker = Jre23VersionCheckerMapper.fromJson(parsableJson);
      Fimber.i("Jre23VersionChecker: $versionChecker");
      return versionChecker;
    }

    return null;
  }
}

// Create a provider for the Jre23Notifier
final jre23NotifierProvider =
    AsyncNotifierProvider<Jre23Notifier, Jre23State>(() => Jre23Notifier());

@MappableClass()
class Jre23VersionChecker with Jre23VersionCheckerMappable {
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

  Jre23VersionChecker({
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

class InstallJre23Card extends ConsumerStatefulWidget {
  const InstallJre23Card({super.key});

  @override
  ConsumerState createState() => _InstallJre23CardState();
}

class _InstallJre23CardState extends ConsumerState<InstallJre23Card> {
  bool? installingJre23State;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child:
                  Text("JRE 23", style: Theme.of(context).textTheme.titleLarge),
            ),
            Disable(
              isEnabled: installingJre23State != true,
              child: ElevatedButton(
                  onPressed: () async {
                    setState(() {
                      installingJre23State = true;
                    });
                    await ref
                        .watch(jre23NotifierProvider.notifier)
                        .installJre23();
                    setState(() {
                      installingJre23State = false;
                    });
                  },
                  child: const Text("Install")),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: SizedBox(
                  width: 200,
                  child: Column(
                    children: [
                      const Text("Starsector Himemi Config"),
                      TriOSDownloadProgressIndicator(
                          value: ref
                                  .watch(jre23NotifierProvider)
                                  .value
                                  ?.jdk23ConfigTriOSDownloadProgress ??
                              const TriOSDownloadProgress(0, 0,
                                  isIndeterminate: true)),
                    ],
                  )),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: SizedBox(
                  width: 200,
                  child: Column(
                    children: [
                      const Text("JDK 23"),
                      TriOSDownloadProgressIndicator(
                          value: ref
                                  .watch(jre23NotifierProvider)
                                  .value
                                  ?.jre23jdkTriOSDownloadProgress ??
                              const TriOSDownloadProgress(0, 0,
                                  isIndeterminate: true)),
                    ],
                  )),
            ),
            Text(switch (installingJre23State) {
              true => "Installing JRE 23...",
              false => "JRE 23 installed!",
              _ => ""
            }),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                  "This will overwrite any existing JRE23 install.\nJRE23 is provided by Himemi.",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall),
            ),
          ],
        ),
      ),
    );
  }
}
