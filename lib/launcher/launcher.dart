import 'dart:io';

import 'package:collection/collection.dart';
import 'package:dart_extensions_methods/dart_extension_methods.dart';
import 'package:fimber/fimber.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/trios/settings/settings.dart';
import 'package:trios/utils/extensions.dart';
import 'package:win32_registry/win32_registry.dart';

class Launcher extends ConsumerWidget {
  const Launcher({super.key});

  static StarsectorLaunchPreferences? getStarsectorLaunchPrefs() {
    if (Platform.isWindows) {
      return _getStarsectorLaunchPrefsWindows();
    } else {
      Fimber.w('Platform not yet supported');
      return null;
    }
  }

  static StarsectorLaunchPreferences _getStarsectorLaunchPrefsWindows() {
    const registryPath = r'Software\JavaSoft\Prefs\com\fs\starfarer';
    final key = Registry.openPath(RegistryHive.currentUser, path: registryPath);
    final prefs = StarsectorLaunchPreferences(
      isFullscreen: key.getValueAsString('fullscreen')?.equalsIgnoreCase("true") ?? false,
      resolution: key.getValueAsString('resolution') ?? '1920x1080',
      hasSound: key.getValueAsString('sound')?.equalsIgnoreCase("true") ?? true,
    );
    key.close();

    Fimber.i('Reading Starsector settings from Registry:\n${prefs.toString()}');
    return prefs;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
        onPressed: () => launchGame(ref),
        child: const Text('Launch', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)));
  }

  static launchGame(WidgetRef ref) {
    // Starsector folder
    var gamePath = ref.read(appSettings.select((value) => value.gameDir))?.toDirectory();
    final gameCorePath = ref.read(appSettings.select((value) => value.gameCoreDir))?.toDirectory();
    var javaExe = gamePath?.resolve('jre/bin/java.exe') as File?;
    var vmParams = gamePath?.resolve('vmparams') as File?;

    if (javaExe?.existsSync() != true) {
      Fimber.w('Java not found at $javaExe');
      return;
    } else if (vmParams?.existsSync() != true) {
      Fimber.w('vmparams not found at $vmParams.'); // TODO: mac and linux
      return;
    }

    var vmParamsContent = vmParams
        ?.readAsStringSync()
        .removePrefix("java.exe")
        .split(" ")
        .where((element) => element.isNotEmpty)
        .toList();
    Fimber.d('vmParamsContent: $vmParamsContent');

    if (vmParamsContent == null) {
      Fimber.w('vmparams is empty');
      return;
    }

    StarsectorLaunchPreferences? launchPreferences;

    if (Platform.isWindows) {
      launchPreferences = Launcher.getStarsectorLaunchPrefs()!;
      final overrideArgs = _generateVmparamOverrides(launchPreferences, gameCorePath, vmParamsContent);

      List<String> result = overrideArgs.entries.map((entry) => '${entry.key}=${entry.value}').toList() +
          vmParamsContent
              // Remove any vanilla params that we're overriding.
              .filter((vanillaParam) => overrideArgs.entries.none((entry) => vanillaParam.startsWith(entry.key)))
              .toList();

      Fimber.d('processArgs: $result');
      Process.start(javaExe!.absolute.path, result,
          workingDirectory: gameCorePath?.path, mode: ProcessStartMode.detached, includeParentEnvironment: true);
    } else {
      Fimber.w('Platform not yet supported');
      return;
    }
  }

  static Map<String, String?> _generateVmparamOverrides(
    StarsectorLaunchPreferences launchPrefs,
    Directory? starsectorCoreDir,
    List<String> vanillaVmparams,
  ) {
    final vmparamsKeysToAbsolutize = <String>[
      '-Djava.library.path',
      '-Dcom.fs.starfarer.settings.paths.saves',
      '-Dcom.fs.starfarer.settings.paths.screenshots',
      '-Dcom.fs.starfarer.settings.paths.mods',
      '-Dcom.fs.starfarer.settings.paths.logs',
    ];

    final overrideArgs = <String, String?>{
      '-DlaunchDirect': 'true',
      '-DstartFS': launchPrefs.isFullscreen.toString(),
      '-DstartSound': launchPrefs.hasSound.toString(),
      '-DstartRes': launchPrefs.resolution,
    };

    for (var key in vmparamsKeysToAbsolutize) {
      // Look through vmparams for the matching key, grab the value of it, and treat it as a relative path
      // to return an absolute one.
      final pair = vanillaVmparams.firstWhereOrNull((element) => element.startsWith('$key='));
      if (pair != null) {
        var value = pair.split('=').getOrNull(1);
        if (value != null) {
          overrideArgs[key] = starsectorCoreDir?.resolve(value).normalize().absolute.path;
        }
      }
    }

    return overrideArgs;
  }
}

class StarsectorLaunchPreferences {
  final bool isFullscreen;
  final String resolution;
  final bool hasSound;

  StarsectorLaunchPreferences({required this.isFullscreen, required this.resolution, required this.hasSound});

  @override
  String toString() {
    return 'isFullscreen: $isFullscreen\nresolution: $resolution\nhasSound: $hasSound';
  }
}
