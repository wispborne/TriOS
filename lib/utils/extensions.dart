import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_extensions_methods/dart_extension_methods.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:toml/toml.dart';
import 'package:trios/utils/logging.dart';
import 'package:yaml/yaml.dart';

extension DoubleExt on double {
  String bytesAsReadableMB() => "${(this / 1000000).toStringAsFixed(3)} MB";

  double coerceAtLeast(double minimumValue) {
    return this < minimumValue ? minimumValue : this;
  }

  double coerceAtMost(double maximumValue) {
    return this > maximumValue ? maximumValue : this;
  }

  double minus(double other) {
    return this - other;
  }

  double plus(double other) {
    return this + other;
  }

  double times(double other) {
    return this * other;
  }

  double div(double other) {
    return this / other;
  }
}
// Long.bytesAsReadableMB: String
// get() = "%.3f MB".format(this / 1000000f)

extension BoolExt on bool {
  Comparable toComparable() => this ? 0 : 1;
}

extension StringBufferExt on StringBuffer {
  appendAndPrint(String line, Function(String) traceOut) {
    traceOut(line);
    writeln(line);
  }
}

extension StringExt on String {
  String ifBlank(String str) {
    if (isEmpty) return str;
    return this;
  }

  Directory toDirectory() => Directory(this);

  File toFile() => File(this);

  String take(int n) => length < n ? this : substring(0, n);

  String takeLast(int n) => length < n ? this : substring(length - n);

  String takeWhile(bool Function(String) predicate) {
    var index = 0;
    while (index < length && predicate(this[index])) {
      index++;
    }
    return substring(0, index);
  }

  String skipLinesWhile(bool Function(String) predicate) {
    final lines = split('\n');

    for (var i = 0; i < lines.length; i++) {
      if (!predicate(lines[i])) {
        return lines.sublist(i).join('\n');
      }
    }

    return this;
  }

  String removePrefix(String prefix) {
    if (startsWith(prefix)) {
      return substring(prefix.length);
    }
    return this;
  }

  /// Warning: probably not fast.
  String fixJson() {
    // Replace \# with # because some mod did that and it broke things.
    var fixed = replaceAll(r"\#", "#");
    // Replace tabs with spaces because yaml is picky. Thank you VIC.
    fixed = fixed.replaceAll("\t", "  ");

    try {
      return json.encode(loadYaml(fixed));
    } catch (e) {
      Fimber.d("Unable to fix json: ${fixed.take(2000)}", ex: e);
      rethrow;
    }
  }

  Map<String, dynamic> fixJsonToMap() {
    return jsonDecode(fixJson());
  }

  /// Returns a string having leading characters from the chars array removed.
  String trimStart(String prefix) {
    var index = 0;
    while (index < length && prefix.contains(this[index])) {
      index++;
    }
    return substring(index);
  }

  String trimEnd(String suffix) {
    var index = length - 1;
    while (index >= 0 && suffix.contains(this[index])) {
      index--;
    }
    return substring(0, index + 1);
  }

  // Helper for comparing number-like strings
  int compareRecognizingNumbers(String str2) {
    final chunks1 = splitIntoAlphaAndNumeric();
    final chunks2 = str2.splitIntoAlphaAndNumeric();

    for (var i = 0; i < chunks1.length || i < chunks2.length; i++) {
      final chunk1 = _getSafeChunk(chunks1, i);
      final chunk2 = _getSafeChunk(chunks2, i);

      final result = _compareChunks(chunk1, chunk2);
      if (result != 0) return result;
    }

    return 0;
  }

  String filter(bool Function(String) predicate) =>
      characters.where(predicate).join();

  /// Breaks a string into chunks of letters and numbers.
  /// "55hhb3vv-5 s" -> ["55", "hhb", "3", "vv", "5", "s"]
  List<String> splitIntoAlphaAndNumeric() {
    final str = this;

    return ([0] +
            _letterDigitSplitterRegex
                .allMatches(str)
                .map((m) => m.start)
                .toList() +
            [str.length])
        .zipWithNext((l, r) => str
            .substring(l, r)
            .filter((it) => RegExp(r"[a-zA-Z0-9]").hasMatch(it)))
        .filter((p0) => p0.isNotEmpty)
        .toList();
  }

  bool containsAny(Iterable<String> elements) {
    return elements.any(contains);
  }

  bool containsAnyIgnoreCase(Iterable<String> elements) {
    return elements.any(containsIgnoreCase);
  }

  bool equalsAnyIgnoreCase(Iterable<String> elements) {
    return elements.any(equalsIgnoreCase);
  }

  String fixFilenameForFileSystem() {
    // This pattern matches any character that is not allowed in filenames on Windows, macOS, and Linux.
    // < > : " / \ | ? * are disallowed characters.
    // \x00-\x1F matches non-printable control characters.
    String fixed = replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), '_').trim();

    // Ensure the length is within valid range before calling substring
    if (fixed.length > 255) {
      return fixed.substring(0, 255);
    }

    return fixed;
  }

  String toTitleCase() {
    if (isEmpty) return this;

    return split(' ').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  void openAsUriInBrowser() {
    OpenFilex.open(this);
  }
}

extension StringMapExt on Map<String, dynamic> {
  String toJsonString() {
    return jsonEncode(this);
  }

  /// Recursively removes entries with `null` values, using an iterative approach.
  Map<String, dynamic> removeNullValues() {
    final map = this;
    final stack = <Map<String, dynamic>>[map]; // Stack of maps to process

    while (stack.isNotEmpty) {
      final currentMap = stack.removeLast();

      currentMap.removeWhere((key, value) {
        if (value is Map<String, dynamic>) {
          stack.add(value); // Add nested map to stack
          return false; // Keep the key for now
        } else if (value is List) {
          // Process each element in the list
          currentMap[key] = value
              .where((item) =>
                  item is! Map<String, dynamic> ||
                  item.removeNullValues().isNotEmpty)
              .toList();
          return (currentMap[key] as List).isEmpty; // Remove if list is empty
        }
        return value == null; // Remove key if value is null
      });

      // Remove keys with empty maps
      currentMap.removeWhere((key, value) => value is Map && value.isEmpty);
    }

    return map;
  }

  String prettyPrintJson() {
    return JsonEncoder.withIndent('  ').convert(this);
  }

  String prettyPrintToml() {
    return TomlDocument.fromMap(
            Map<String, dynamic>.from(this).removeNullValues())
        .toString();
  }
}

final _letterDigitSplitterRegex = RegExp(r"(?<=\D)(?=\d)|(?<=\d)(?=\D)");

String _getSafeChunk(List<String> chunks, int index) =>
    index < chunks.length ? chunks[index] : "0";

int _compareChunks(String chunk1, String chunk2) {
  final int1 = int.tryParse(chunk1);
  final int2 = int.tryParse(chunk2);

  if (int1 != null && int2 != null) {
    return int1.compareTo(int2);
  } else {
    return chunk1.compareTo(chunk2);
  }
}

extension FileSystemEntityExt on FileSystemEntity {
  FileSystemEntity resolve(String path) {
    return File(p.join(absolute.path, path));
  }

  FileSystemEntity normalize() {
    return File(p.normalize(absolute.path));
  }

  Future<void> moveTo(Directory destDir, {bool overwrite = false}) async {
    if (this is Directory) {
      await (this as Directory).moveDirectory(destDir, overwrite: overwrite);
    } else if (this is File) {
      await (this as File).moveTo(destDir, overwrite: overwrite);
    }
  }

  bool isFile() => statSync().type == FileSystemEntityType.file;

  bool isDirectory() => statSync().type == FileSystemEntityType.directory;

  File toFile() => File(absolute.path);

  Directory toDirectory() => Directory(absolute.path);

  bool existsSync() =>
      FileSystemEntity.typeSync(path) != FileSystemEntityType.notFound;
}

extension FileExt on File {
  String relativePath(Directory baseFolder) =>
      p.normalize(p.relative(absolute.path, from: baseFolder.absolute.path));

  String relativeTo(Directory baseFolder) => relativePath(baseFolder);

  String get nameWithoutExtension => p.basenameWithoutExtension(path);

  String get nameWithExtension => p.basename(path);

  String get extension => p.extension(path);

  File get normalize => File(p.normalize(absolute.path));

  Future<File> moveTo(Directory destDir, {bool overwrite = false}) async {
    var destFile = destDir.resolve(nameWithExtension);
    if (await destFile.exists()) {
      if (overwrite) {
        await destFile.delete();
      } else {
        Fimber.i(
            "Skipping file move (file already exists): $this to $destFile");
        return this;
      }
    }
    return (await rename(destFile.path)).normalize;
  }

  String readAsStringSyncAllowingMalformed() {
    return utf8.decode(readAsBytesSync(), allowMalformed: true);
  }

  /// From https://stackoverflow.com/a/64569532/1622788
  Future<bool> isWritable() async {
    try {
      if (!existsSync()) {
        return false;
      }

      final tmp = openWrite(mode: FileMode.append);
      await tmp.flush();
      await tmp.close(); // errors from opening will be thrown at this point
      return true;
    } catch (e) {
      Fimber.d("File $path is not writable: $e");
      return false;
    }
  }

  Future<bool> isNotWritable() async {
    return !(await isWritable());
  }
}

extension DirectoryExt on Directory {
  Directory get normalize => Directory(p.normalize(absolute.path));

  String get name => p.basename(path);

  Future<void> moveDirectory(Directory destDir,
      {bool overwrite = false}) async {
    try {
      renameSync(destDir.absolute.path);
    } catch (e) {
      // Simple rename didn't work. Time to get real.
      await copyDirectory(destDir, overwrite: overwrite);
      deleteSync(recursive: true);
    }
  }

  /// Copied from FileUtils.java::doCopyDirectory in Apache Commons IO.
  Future<void> copyDirectory(Directory destDir,
      {bool overwrite = false}) async {
    final source = normalize;
    final srcFiles =
        source.listSync(recursive: false).map((e) => e.path.toFile());
    destDir.createSync(recursive: true); // mkdirs

    for (var srcFile in srcFiles) {
      final destFile = destDir.resolve(srcFile.nameWithExtension);
      if (srcFile.isDirectory()) {
        await srcFile
            .toDirectory()
            .copyDirectory(destFile.toDirectory(), overwrite: overwrite);
      } else if (srcFile.isFile()) {
        if (destFile.existsSync() && !overwrite) {
          Fimber.d(
              "Skipping file copy (file already exists): $srcFile to $destFile");
          continue;
        } else {
          await srcFile.copy(destFile.path);
        }
      }
    }
  }

  void openInExplorer() {
    OpenFilex.open(path);
  }
}

extension IterableExt<T> on Iterable<T> {
  String joinToString(
      {String separator = ", ",
      required String Function(T element) transform}) {
    return map(transform).join(separator);
  }

  Iterable<T> filter(bool Function(T) predicate) {
    return where(predicate);
  }

  Iterable<R> flatMap<R>(Iterable<R> Function(T) transform) {
    return map(transform).expand((element) => element);
  }

  Iterable<R> mapNotNull<R>(R? Function(T) transform) {
    return map(transform).where((element) => element != null).map((e) => e!);
  }

  T? maxByOrNull<R extends Comparable<R>>(R Function(T) selector) {
    if (isEmpty) return null;
    var maxElement = first;
    var maxValue = selector(maxElement);
    for (var element in skip(1)) {
      var value = selector(element);
      if (value.compareTo(maxValue) > 0) {
        maxElement = element;
        maxValue = value;
      }
    }
    return maxElement;
  }

  /// Sorts the list by the given [selector] function, which is passed to each element in the list.
  ///
  /// If the [selector] function returns null for an element, that element is considered to be smaller than any element for which the [selector] function does not return null.
  ///
  /// If [nullsLast] is true, all elements for which the [selector] function returns null are placed at the end of the list. Otherwise, they are placed at the beginning.
  ///
  /// This is like [List.sort] but with a more intuitive way of handling nulls.
  List<T> sortedByButBetter<R extends Comparable>(
    R? Function(T item) selector, {
    bool isAscending = true,
    bool nullsLast = false,
  }) {
    if (isEmpty) return toList();
    return (toList()
          ..sort((a, b) {
            final aValue = selector(a);
            final bValue = selector(b);
            if (aValue == null) {
              return nullsLast ? 1 : -1;
            } else if (bValue == null) {
              return nullsLast ? -1 : 1;
            }
            return aValue.compareTo(bValue);
          }))
        .let((sorted) => isAscending ? sorted : sorted.reversed)
        .toList();
  }

  List<T> sortedByDescending<R extends Comparable>(R? Function(T item) selector,
      {bool nullsLast = true}) {
    if (isEmpty) return toList();
    return toList()
      ..sort((a, b) {
        final aValue = selector(a);
        final bValue = selector(b);
        if (aValue == null) {
          return nullsLast ? 1 : -1;
        } else if (bValue == null) {
          return nullsLast ? -1 : 1;
        }
        return bValue.compareTo(aValue);
      });
  }

  /// Returns a new list with all elements sorted according to descending
  /// natural sort order.
  List<T> sortedDescending() {
    final list = toList();
    list.sort((a, b) => -(a as Comparable).compareTo(b));
    return list;
  }

  bool containsAll(Iterable<T> elements) {
    return elements.every(contains);
  }

  T random() {
    return elementAt(DateTime.now().microsecond % length);
  }

  T? getOrNull(int index) {
    if (index < 0 || index >= length) return null;
    return elementAt(index);
  }

  T? minByOrNull<R extends Comparable<R>>(R Function(T) selector) {
    if (isEmpty) return null;
    var minElement = first;
    var minValue = selector(minElement);
    for (var element in skip(1)) {
      var value = selector(element);
      if (value.compareTo(minValue) < 0) {
        minElement = element;
        minValue = value;
      }
    }
    return minElement;
  }

  /// Combines the current element with the next element in the iterable using the provided [transform] function.
  /// From Gemini.
  ///
  /// Example:
  /// ```dart
  /// final numbers = [1, 4, 9, 16];
  /// final differences = numbers.zipWithNext((a, b) => b - a);
  /// print(differences); // Output: [3, 5, 7]
  /// ```
  List<R> zipWithNext<R>(R Function(T a, T b) transform) {
    final iterator = this.iterator;
    if (!iterator.moveNext()) return <R>[];

    final result = <R>[];
    var current = iterator.current;

    while (iterator.moveNext()) {
      final next = iterator.current;
      result.add(transform(current, next));
      current = next;
    }

    return result;
  }

  Iterable<T> dropUntil(bool Function(T) predicate) {
    var found = false;
    return where((element) {
      if (found) return true;
      if (predicate(element)) {
        found = true;
        return true;
      }
      return false;
    });
  }

  Future<Iterable<T>> whereAsync(
      FutureOr<bool> Function(T element) test) async {
    var result = <T>[];
    for (final element in this) {
      if (await test(element)) {
        result.add(element);
      }
    }
    return result;
  }

  Iterable<T>? nullIfEmpty() => isEmpty ? null : this;

  Iterable<T> ifEmpty(Iterable<T> Function() block) => isEmpty ? block() : this;

  /// Filters the iterable based on the given predicate.
  /// If the filtered result is empty, returns the original iterable.
  Iterable<T> prefer(bool Function(T) predicate) {
    var filtered = where(predicate);
    return filtered.isEmpty ? this : filtered;
  }
}

extension NullableIterableExt<T> on Iterable<T>? {
  Iterable<T> orEmpty() => this ?? [];
}

extension IterableFileExt on Iterable<File> {
  Directory? rootFolder() {
    final result = minByOrNull<num>((File file) => file.path.length);
    return result?.isDirectory() != true ? null : result?.toDirectory();
  }
}

extension ListExt<T> on List<T> {
  void removeAll(Iterable<T> elements) {
    final elementsSet = elements.toSet(); // Faster lookup?
    removeWhere((element) => elementsSet.contains(element));
  }
}

extension IntExt on int {
  static const int MIN_VALUE = 0x80000000;

  int highestOneBit() {
    return this & (MIN_VALUE >>> numberOfLeadingZeros());
  }

  String bytesAsReadableMB() => "${(this / 1000000).toStringAsFixed(2)} MB";

  String bytesAsReadableKB() => "${(this / 1000).toStringAsFixed(2)} KB";

  /// From Java
  int numberOfLeadingZeros() {
    // HD, Count leading 0's
    var i = this;
    if (i <= 0) {
      return i == 0 ? 32 : 0;
    }
    int n = 31;
    if (i >= 1 << 16) {
      n -= 16;
      i >>>= 16;
    }
    if (i >= 1 << 8) {
      n -= 8;
      i >>>= 8;
    }
    if (i >= 1 << 4) {
      n -= 4;
      i >>>= 4;
    }
    if (i >= 1 << 2) {
      n -= 2;
      i >>>= 2;
    }
    return n - (i >>> 1);
  }

  int coerceAtLeast(int minimumValue) {
    return this < minimumValue ? minimumValue : this;
  }

  int coerceAtMost(int maximumValue) {
    return this > maximumValue ? maximumValue : this;
  }
}

// List<Mod>.getBytesUsedByDedupedImages(): Long = this
// .flatMap { mod -> mod.images.map { img -> mod.info.modFolder to img } }
// .distinctBy { (modFolder: Path, image: ModImage) -> image.file.relativeTo(modFolder).pathString + image.file.name }
//     .sumOf { it.second.bytesUsed }

extension IntListExt on List<int> {
  int sum() {
    return fold(0, (previousValue, element) => previousValue + element);
  }
}

extension NumListExt on List<num> {
  num sum() {
    return fold(0, (previousValue, element) => previousValue + element);
  }

  // From Gemini
  num findClosest(num targetValue) {
    num? closestValue;
    num? minDistance;

    for (final value in this) {
      final distance =
          (targetValue - value).abs(); // Calculate absolute distance

      if (minDistance == null || distance < minDistance) {
        closestValue = value;
        minDistance = distance;
      }
    }

    return closestValue!; // Assuming the list 'values' will not be empty
  }
}

extension ObjectExt<T> on T {
  also(Function(T) block) {
    block(this);
    return this;
  }

  R let<R>(R Function(T) block) {
    return block(this);
  }

  T run(T Function() block) {
    return block();
  }
}

extension HexColor on Color {
  /// String is in the format "aabbcc" or "ffaabbcc" with an optional leading "#".
  static Color fromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  /// Prefixes a hash sign if [leadingHashSign] is set to `true` (default is `true`).
  String toHex({bool leadingHashSign = true}) => '${leadingHashSign ? '#' : ''}'
      '${alpha.toRadixString(16).padLeft(2, '0')}'
      '${red.toRadixString(16).padLeft(2, '0')}'
      '${green.toRadixString(16).padLeft(2, '0')}'
      '${blue.toRadixString(16).padLeft(2, '0')}';

  MaterialColor createMaterialColor() {
    final color = this;
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
}

extension ToMapExt<T, V> on Iterable<MapEntry<T, V>> {
  Map<T, V> toMap() {
    return Map.fromEntries(this);
  }
}

extension FutureListExt<T> on List<Future<T>> {
  Future<List<T>> awaitAll() async {
    return await Future.wait(this);
  }

  Future<List> awaitPooled(int poolSize) async {
    final List<Future<T>> activeFutures = [];
    final List<T> results = [];

    for (var future in this) {
      if (activeFutures.length >= poolSize) {
        final completedFuture = await Future.any(activeFutures);
        results.add(completedFuture);
        activeFutures.removeWhere((f) => f == completedFuture);
      }

      activeFutures.add(future);
    }

    // Wait for the remaining futures to complete
    results.addAll(await activeFutures.awaitAll());
    return results;
  }
}

extension EnumFromStringCaseInsensitive on Iterable {
  /// Converts a string to an enum value of the provided enum type,
  /// ignoring case sensitivity. Returns `null` if no match is found.
  /// Use `enum.values.enumFromStringCaseInsensitive<String>("string")` to get the enum value.
  T? enumFromStringCaseInsensitive<T>(String value) {
    return firstWhere(
      (e) => e.toString().split('.').last.toLowerCase() == value.toLowerCase(),
      orElse: () => null,
    ) as T?;
  }
}
