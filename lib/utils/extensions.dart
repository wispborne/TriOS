import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../pages/vram_estimator/models/mod_result.dart';

extension DoubleExt on double {
  String bytesAsReadableMB() => "${(this / 1000000).toStringAsFixed(3)} MB";
}
// Long.bytesAsReadableMB: String
// get() = "%.3f MB".format(this / 1000000f)

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
}

extension FileExt on File {
  String relativePath(Directory modFolder) =>
      p.normalize(p.relative(absolute.path, from: modFolder.absolute.path));

  String relativeTo(Directory modFolder) => relativePath(modFolder);

  String get nameWithoutExtension => p.basenameWithoutExtension(path);

  String get name => p.basename(path);
}

extension FileSystemEntityExt on FileSystemEntity {
  FileSystemEntity resolve(String path) {
    return File(p.join(absolute.path, path));
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

  Iterable<T> sortedByDescending<R extends Comparable<R>>(
      R Function(T) selector) {
    return toList()..sort((a, b) => selector(b).compareTo(selector(a)));
  }

  bool containsAll(Iterable<T> elements) {
    return elements.every(contains);
  }
}

extension ListExt<T> on List<T> {
  void removeAll(Iterable<T> elements) {
    removeWhere((element) => elements.contains(element));
  }
}

extension IntExt on int {
  static const int MIN_VALUE = 0x80000000;

  int highestOneBit() {
    return this & (MIN_VALUE >>> numberOfLeadingZeros());
  }

  String bytesAsReadableMB() => "${(this / 1000000).toStringAsFixed(2)} MB";

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
}

// List<Mod>.getBytesUsedByDedupedImages(): Long = this
// .flatMap { mod -> mod.images.map { img -> mod.info.modFolder to img } }
// .distinctBy { (modFolder: Path, image: ModImage) -> image.file.relativeTo(modFolder).pathString + image.file.name }
//     .sumOf { it.second.bytesUsed }

extension ModListExt on Iterable<Mod> {
  int getBytesUsedByDedupedImages() {
    return expand(
            (mod) => mod.images.map((img) => Tuple2(mod.info.modFolder, img)))
        .toSet()
        .map((pair) => pair.item2.bytesUsed)
        .sum;
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

class Tuple2<T1, T2> {
  final T1 item1;
  final T2 item2;

  Tuple2(this.item1, this.item2);
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
