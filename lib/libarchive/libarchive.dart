import 'dart:ffi';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:trios/libarchive/libarchive_bindings.dart';
import 'package:trios/utils/extensions.dart';

LibArchive getArchive() {
  final currentPath = p.join(Directory.current.absolute.path, "assets");
  final libArchivePathForPlatform = switch (Platform.operatingSystem) {
    "windows" => Directory("$currentPath/libarchive/windows/bin").absolute.normalize.path,
    "linux" => Directory("$currentPath/libarchive/linux/archive.so").absolute.normalize.path,
    "macos" => Directory("$currentPath/libarchive/macos/archive.dylib").absolute.normalize.path,
    _ => throw UnimplementedError('Libarchive not supported for this platform')
  };

  // if (!File(libArchivePathForPlatform).existsSync()) {
  //   throw Exception("Libarchive not found at $libArchivePathForPlatform");
  // }

  // final libraryName = fullLibraryName("archive");
  // final lib = loadDynamicLibrary(libraryName: "archive", searchPath: libArchivePathForPlatform);
  // return LibArchive(lib);
  var libFile = File("assets/libarchive/windows/bin/archive.dll").absolute.normalize;
  if (libFile.existsSync()) {
    var dynamicLibrary = DynamicLibrary.open(libFile.path);
    return LibArchive(dynamicLibrary);
  } else {
    throw Exception("Libarchive not found at ${libFile.path}");
  }
}
