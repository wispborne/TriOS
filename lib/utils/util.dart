import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:trios/models/mod_info_json.dart';
import 'package:trios/models/version.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/logging.dart';
import 'package:win32_registry/win32_registry.dart';

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

Directory defaultGamePath() {
  if (Platform.isWindows) {
    // todo read from registry
    try {
      const registryPath = r'Software\Fractal Softworks\Starsector';
      final key =
          Registry.openPath(RegistryHive.currentUser, path: registryPath);
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
  if (Platform.isWindows) {
    return Directory(p.join(gamePath.path, "starsector-core"));
  } else if (Platform.isMacOS) {
    return Directory(p.join(gamePath.path, "Contents/Resources/Java"));
  } else if (kIsWeb) {
    return null; // huh
  } else {
    return null;
  }
}

Directory? defaultGameCorePath() {
  return defaultGamePath() == null
      ? null
      : generateGameCorePath(defaultGamePath()!)?.normalize;
}

Directory? generateModFolderPath(Directory gamePath) {
  if (Platform.isWindows || Platform.isMacOS) {
    return Directory(p.join(gamePath.path, "mods")).normalize;
  } else if (kIsWeb) {
    return null; // huh
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
  /// https://stackoverflow.com/a/16348977/1622788
  Color stringToColor(String str) {
    var hash = 0;
    for (var i = 0; i < str.length; i++) {
      hash = str.codeUnitAt(i) + ((hash << 5) - hash);
    }

    var colour = '#';

    for (var i = 0; i < 3; i++) {
      var value = (hash >> (i * 8)) & 0xFF;
      colour += (value.toRadixString(16)).padLeft(2, '0');
    }

    return HexColor.fromHex(colour);
  }

  // New: Generate colors based on an existing color
  static Color generateFromColor(String text, Color baseColor,
      {bool complementary = false}) {
    final random = Random(text.hashCode);

    // 1. Manipulation Options
    if (complementary) {
      return ColorGenerator.complementary(baseColor);
    } else {
      // Apply adjustments from string's hash
      int lightnessOffset = random.nextInt(70) - 35; // Range: -35 to 35
      double newLightness =
          (baseColor.computeLuminance() + lightnessOffset / 100)
              .clamp(0.0, 1.0);

      return HSLColor.fromColor(baseColor)
          .withLightness(newLightness)
          .toColor();
    }
  }

  // Helper for finding complementary color
  static Color complementary(Color color) {
    return Color.fromRGBO(
      255 - color.red,
      255 - color.green,
      255 - color.blue,
      1.0,
    );
  }
}

typedef ProgressCallback = void Function(
    int bytesReceived, int contentLengthBytes);

Future<File> downloadFile(String url, Directory savePath, String? filename,
    {ProgressCallback? onProgress}) async {
  try {
    final request = http.Request('GET', Uri.parse(url));
    final streamedResponse = await http.Client().send(request);

    final contentLength = streamedResponse.contentLength ?? -1;
    int bytesReceived = 0;

    var desiredFilename = filename ??
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
      (element) => element.name.toLowerCase() == Platform.operatingSystem);
}

/// CAREFUL. Make sure to close the stream controller when you're done with it.
/// Does not return.
/// Starts async polling every [intervalMillis] for changes in the file's last modified date.
pollFileForModification(File file, StreamController<File?> streamController,
    {int intervalMillis = 1000}) async {
  var didExistLastCheck = file.existsSync();
  // If the file doesn't exist when we start, use the current time as the last modified date.
  var lastModified =
      didExistLastCheck ? file.lastModifiedSync() : DateTime.now();
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

class JsonConverterVersion implements JsonConverter<Version, dynamic> {
  const JsonConverterVersion();

  @override
  Version fromJson(dynamic json) {
    try {
      if (json is Map<String, dynamic>) {
        // Shouldn't have to sanitize the input if they used the major/minor/patch json format.
        return Version.parse(VersionObject.fromJson(json).toString(), sanitizeInput: false);
      }
      return Version.parse(json, sanitizeInput: true);
    } catch (e) {
      rethrow;
    }
  }

  @override
  String toJson(dynamic object) {
    if (object is VersionObject) {
      return "${object.major}.${object.minor}.${object.patch}";
    } else {
      return object.toString();
    }
  }
}

class JsonConverterVersionNullable implements JsonConverter<Version?, dynamic> {
  const JsonConverterVersionNullable();

  @override
  Version? fromJson(dynamic json) {
    try {
      return const JsonConverterVersion().fromJson(json);
    } catch (e) {
      return null;
    }
  }

  @override
  String toJson(dynamic object) {
    return const JsonConverterVersion().toJson(object);
  }
}

class JsonConverterToString implements JsonConverter<String, dynamic> {
  const JsonConverterToString();

  @override
  String fromJson(dynamic json) {
    return json.toString();
  }

  @override
  dynamic toJson(String object) {
    return object;
  }
}

class JsonConverterBool implements JsonConverter<bool, dynamic> {
  const JsonConverterBool();

  @override
  bool fromJson(dynamic json) {
    if (json == null) return false;
    if (json is bool) return json;
    if (json is String) {
      return bool.tryParse(json, caseSensitive: false) ?? false;
    }
    return false;
  }

  @override
  dynamic toJson(bool object) {
    return object.toString();
  }
}

String jsonEncodePrettily(dynamic json) {
  var spaces = ' ' * 2;
  var encoder = JsonEncoder.withIndent(spaces);
  return encoder.convert(json);
}
