import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:trios/compression/archive.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/logging.dart';
import 'package:trios/utils/platform_paths.dart';
import 'package:win32_registry/win32_registry.dart';

import '../trios/constants.dart';

MaterialColor createMaterialColor(Color color) {
  List strengths = <double>[.05];
  Map<int, Color> swatch = {};
  final int r = color.red, g = color.green, b = color.blue;

  for (int i = 1; i < 10; i++) {
    strengths.add(0.1 * i);
  }
  for (var strength in strengths) {
    final double ds = 0.5 - strength;
    swatch[(strength * 1000).round()] = Color.fromRGBO(
      r + ((ds < 0 ? r : (255 - r)) * ds).round(),
      g + ((ds < 0 ? g : (255 - g)) * ds).round(),
      b + ((ds < 0 ? b : (255 - b)) * ds).round(),
      1,
    );
  }

  return MaterialColor(color.value, swatch);
}

/// Windows: Reads the registry for the game path.
/// Mac: /Applications/Starsector.app
Directory defaultGamePath() {
  if (Platform.isWindows) {
    try {
      const registryPath = r'Software\Fractal Softworks\Starsector';
      final key = Registry.openPath(
        RegistryHive.currentUser,
        path: registryPath,
      );
      final registryGamePath = key.getValueAsString("")?.toDirectory();
      if (registryGamePath != null && registryGamePath.existsSync()) {
        return registryGamePath;
      }
    } catch (e) {
      Fimber.w("Error reading registry: $e");
    }

    return Directory("C:/Program Files (x86)/Fractal Softworks/Starsector");
  } else if (Platform.isMacOS) {
    return Directory("/Applications/Starsector.app");
  } else if (kIsWeb) {
    return Directory(""); // huh
  } else {
    return Directory("");
  }
}

Directory? generateGameCorePath(Directory gamePath) {
  switch (currentPlatform) {
    case TargetPlatform.windows:
      return Directory(p.join(gamePath.path, "starsector-core"));
    case TargetPlatform.macOS:
      return Directory(p.join(gamePath.path, "Contents/Resources/Java"));
    case TargetPlatform.linux:
      return gamePath;
    case _:
      return null;
  }
}

Directory? generateModsFolderPath(Directory gamePath) {
  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    return Directory(p.join(gamePath.path, "mods")).normalize;
  } else {
    return null;
  }
}

Directory? generateJresFolderPath(Directory gamePath) {
  if (Platform.isWindows) {
    return gamePath;
  } else if (Platform.isMacOS) {
    return Directory(p.join(gamePath.path, "Contents")).normalize;
  } else if (Platform.isLinux) {
    return gamePath;
  } else {
    return null;
  }
}

File? getRulesCsvInModFolder(Directory modFolder) {
  var file = File(p.join(modFolder.path, "data/campaign/rules.csv"));
  if (file.existsSync()) {
    return file;
  } else {
    return null;
  }
}

final allRulesCsvsInModsFolder = StateProvider<File?>((ref) => null);

List<File> getAllRulesCsvsInModsFolder(Directory modsFolder) {
  return modsFolder
      .listSync()
      .whereType<Directory>()
      .map((entity) => getRulesCsvInModFolder(entity))
      .where((entity) => entity != null)
      .map((entity) => entity!)
      .toList();
}

File getVanillaRulesCsvInGameFiles(Directory gameFiles) {
  return File(getRulesCsvInModFolder(gameFiles)!.absolute.path);
}

Future<String?> getStarsectorVersionFromObf(
  Directory gameCorePath,
  ArchiveInterface archive,
) async {
  final starsectorObfJar = "starfarer_obf.jar";
  final obfPath = p.join(gameCorePath.path, starsectorObfJar).toFile();
  if (!obfPath.existsSync()) {
    throw Exception("${obfPath.path} not found.");
  }

  final extractedVersionFile = (await archive.readEntriesInArchive(
    obfPath,
    fileFilter: (entry) => entry.path.contains("Version.class"),
  )).firstOrNull;
  if (extractedVersionFile == null) {
    return null;
  }

  final bytes = extractedVersionFile.extractedContent;
  const versionMarkers = ['versionOnly', 'versionString'];

  // Decode bytes as UTF-8 and search for markers to find the version string.
  final utf8String = utf8.decode(bytes, allowMalformed: true);

  for (var marker in versionMarkers) {
    final markerIndex = utf8String.indexOf(marker);
    if (markerIndex != -1) {
      // Assuming version string appears immediately after the marker (as observed in the file).
      final versionStart = utf8String.indexOf(RegExp(r'[\d.]'), markerIndex);
      if (versionStart != -1) {
        final versionEnd = utf8String.indexOf(
          RegExp(r'[^a-zA-Z0-9.-]'),
          versionStart,
        );
        final gameVersion = utf8String
            .substring(versionStart, versionEnd)
            .trim();
        Fimber.i("Found game version in obs: $gameVersion");
        return gameVersion;
      }
    }
  }
  return null;
}

Future<String?> readStarsectorVersionFromLog(Directory gamePath) async {
  Fimber.i("Looking through log file for game version.");
  const versionContains = r"Starting Starsector";
  final versionRegex = RegExp(r"Starting Starsector (.*) launcher");
  final logfile = utf8.decode(
    getLogPath(gamePath).readAsBytesSync().toList(),
    allowMalformed: true,
  );
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

class HexColor extends Color {
  static int _getColorFromHex(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    return int.parse(hexColor, radix: 16);
  }

  HexColor.fromHex(String hexColor) : super(_getColorFromHex(hexColor));
}

class ColorGenerator {
  /// Generates a color based on [baseColor], varying hue/saturation/lightness
  /// using the hash of [text].
  /// If [complementary] is true, it returns the direct complementary color.
  static Color generateFromColor(
    String text,
    Color baseColor, {
    bool complementary = false,
  }) {
    final random = Random(text.hashCode);

    if (complementary) {
      return complementaryColor(baseColor);
    } else {
      final hslBase = HSLColor.fromColor(baseColor);

      // Random hue offset (±30°):
      final hueOffset = (random.nextDouble() * 60) - 30;
      final newHue = (hslBase.hue + hueOffset) % 360.0;

      // Random saturation offset (±0.15), clamped to [0..1]:
      final satOffset = (random.nextDouble() * 0.3) - 0.15;
      final newSaturation = (hslBase.saturation + satOffset).clamp(0.0, 1.0);

      // Random lightness offset (±0.2), clamped to [0..1]:
      final lightnessOffset = (random.nextDouble() * 0.4) - 0.2;
      final newLightness = (hslBase.lightness + lightnessOffset).clamp(
        0.0,
        1.0,
      );

      final generated = HSLColor.fromAHSL(
        1.0,
        newHue,
        newSaturation,
        newLightness,
      );
      return generated.toColor();
    }
  }

  /// Returns the direct complementary color of the given [color].
  static Color complementaryColor(Color color) {
    return Color.fromRGBO(
      (255 - color.r).toInt(),
      (255 - color.g).toInt(),
      (255 - color.b).toInt(),
      1.0,
    );
  }
}

String getAssetsPath() {
  // edit: Switching from Directory.current to Platform.resolvedExecutable.toFile().parent removed the need for a "is debug mode" check.
  final assetsPath = switch (currentPlatform) {
    TargetPlatform.windows => "data/flutter_assets/assets",
    TargetPlatform.macOS =>
      "../../Contents/Frameworks/App.framework/Resources/flutter_assets/assets/",
    TargetPlatform.linux => "data/flutter_assets/assets",
    _ => "data/flutter_assets/assets",
  };
  final currentAssetsPath = p.join(currentDirectory.absolute.path, assetsPath);
  return currentAssetsPath;
}

typedef ProgressCallback =
    void Function(int bytesReceived, int contentLengthBytes);

Future<File> downloadFile(
  String url,
  Directory savePath,
  String? filename, {
  ProgressCallback? onProgress,
}) async {
  try {
    final request = http.Request('GET', Uri.parse(url));
    final streamedResponse = await http.Client().send(request);

    final contentLength = streamedResponse.contentLength ?? -1;
    int bytesReceived = 0;

    var desiredFilename =
        filename ??
        request.headers['content-disposition']?.split('=')[1] ??
        url.split('/').last;
    final file = File(p.join(savePath.path, desiredFilename));

    if (file.existsSync()) {
      file.deleteSync();
    }

    final sink = file.openWrite();
    await streamedResponse.stream.listen((chunk) {
      bytesReceived += chunk.length;
      sink.add(chunk);
      if (onProgress != null) {
        onProgress(bytesReceived, contentLength);
      }
    }).asFuture();
    await sink.close();

    Fimber.d('File downloaded successfully: ${file.path} from $url.');
    return file;
  } catch (error) {
    Fimber.d('Error downloading file: $error from $url');
    rethrow;
  }
}

class Tuple2<T1, T2> {
  final T1 item1;
  final T2 item2;

  Tuple2(this.item1, this.item2);
}

class NestedException implements Exception {
  final String cause;
  final exception;
  final stacktrace;

  NestedException(this.cause, [this.exception, this.stacktrace]);

  @override
  String toString() =>
      '$cause\n\tCaused by: $exception${stacktrace != null ? "\n$stacktrace" : ""}';
}

TargetPlatform? get currentPlatform {
  return TargetPlatform.values.firstWhereOrNull(
    (element) => element.name.toLowerCase() == Platform.operatingSystem,
  );
}

/// CAREFUL. Make sure to close the stream controller when you're done with it.
/// Does not return.
/// Starts async polling every [intervalMillis] for changes in the file's last modified date.
pollFileForModification(
  File file,
  StreamController<File?> streamController, {
  int intervalMillis = 1000,
}) async {
  var didExistLastCheck = file.existsSync();
  // If the file doesn't exist when we start, use the current time as the last modified date.
  var lastModified = didExistLastCheck
      ? file.lastModifiedSync()
      : DateTime.now();
  final fileChangesInstance = streamController;

  while (!fileChangesInstance.isClosed) {
    await Future.delayed(Duration(milliseconds: intervalMillis));
    // If the file doesn't exist, we don't need to check the last modified date.
    // We do want to notify the listener that the file is gone, once.
    if (!file.existsSync()) {
      if (didExistLastCheck) {
        didExistLastCheck = false;
        streamController.add(null);
      }
      continue;
    }

    // Update listener if file is modified OR if it suddenly exists after not existing.
    final newModified = file.lastModifiedSync();
    if (!didExistLastCheck || newModified.isAfter(lastModified)) {
      lastModified = newModified;
      streamController.add(file);
    }
    didExistLastCheck = true;
  }
}

String jsonEncodePrettily(dynamic json) {
  var spaces = ' ' * 2;
  var encoder = JsonEncoder.withIndent(spaces);
  return encoder.convert(json);
}

T time<T>(T Function() function, {bool ignoreZero = true}) {
  final stopwatch = Stopwatch()..start();
  final result = function();
  stopwatch.stop();
  if (!ignoreZero || stopwatch.elapsedMilliseconds > 0) {
    Fimber.d('Time taken: ${stopwatch.elapsedMilliseconds}ms');
  }
  return result;
}

/// Checks a list of [files] to see if they are accessible (not locked).
///
/// It repeatedly tries to open each file in append mode and immediately close it.
/// If any file fails this check (throws a FileSystemException, likely due to locking),
/// it waits for [checkInterval] and retries, until [timeout] is reached.
///
/// Args:
///   files: The list of files to check.
///   timeout: The maximum duration to wait for all files to become accessible.
///   checkInterval: The duration to wait between checks.
///
/// Returns:
///   `Future<bool>`: `true` if all files become accessible within the [timeout],
///   `false` otherwise.
Future<bool> waitForFilesToBeAccessible(
  List<File> files, {
  Duration timeout = const Duration(seconds: 5),
  Duration checkInterval = const Duration(milliseconds: 250),
}) async {
  if (files.isEmpty) {
    return true;
  }

  final stopwatch = Stopwatch()..start();
  File? lockedFile; // Keep track of which file failed

  while (stopwatch.elapsed < timeout) {
    bool allFilesFree = true;

    for (final file in files) {
      try {
        if (await file.exists()) {
          // Try to open the file for appending. This often requires exclusive access
          // or at least checks if another process has a conflicting lock.
          RandomAccessFile raf = await file.open(mode: FileMode.append);
          await raf.close(); // Immediately close it if successful
        }
      } on FileSystemException catch (e) {
        Fimber.v(
          () =>
              "File accessibility check failed for ${file.path} (elapsed: ${stopwatch.elapsed}): ${e.message}",
        );
        allFilesFree = false;
        lockedFile = file;
        break;
      } catch (e, s) {
        Fimber.e(
          "Unexpected error checking file accessibility for ${file.path}",
          ex: e,
          stacktrace: s,
        );
        allFilesFree = false;
        lockedFile = file; // Treat unexpected errors as inaccessible too
        break;
      }
    }

    if (allFilesFree) {
      Fimber.i(
        "All ${files.length} files became accessible within ${stopwatch.elapsed}.",
      );
      stopwatch.stop();
      return true;
    }

    // If not all files were free, wait before the next check, unless timeout is near
    if (stopwatch.elapsed + checkInterval < timeout) {
      await Future.delayed(checkInterval);
    } else {
      // Don't delay if the next check would exceed the timeout anyway
      // Let the loop condition handle the exit.
    }
  }

  // Loop finished without success
  stopwatch.stop();
  Fimber.w(
    "Timeout ($timeout) reached while waiting for files to become accessible. Last locked file detected: ${lockedFile?.path ?? 'N/A'}",
  );
  return false;
}

const int intMaxValue = -1 >>> 1;
