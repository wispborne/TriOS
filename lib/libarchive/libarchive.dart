import 'dart:ffi';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:trios/libarchive/libarchive_bindings.dart';
import 'package:trios/utils/extensions.dart';

class LibArchive {
  late var binding = getArchive();

  LibArchiveBinding getArchive() {
    final currentLibarchivePath = p.join(Directory.current.absolute.path, "assets/libarchive");

    final libArchivePathForPlatform = switch (Platform.operatingSystem) {
      "windows" => Directory("$currentLibarchivePath/windows/bin").absolute.normalize.path,
      "linux" => Directory("$currentLibarchivePath/linux/archive.so").absolute.normalize.path,
      "macos" => Directory("$currentLibarchivePath/macos/archive.dylib").absolute.normalize.path,
      _ => throw UnimplementedError('Libarchive not supported for this platform')
    };

    if (!File(libArchivePathForPlatform).existsSync()) {
      throw Exception("Libarchive not found at $libArchivePathForPlatform");
    }

    var dynamicLibrary = DynamicLibrary.open(libArchivePathForPlatform);
    return LibArchiveBinding(dynamicLibrary);
  }

  List<String> listPathsInArchive(String archivePath) {
    final archive = binding.archive_read_new();
    var  result = binding.archive_read_support_filter_all(archive);
    if (result != 0) {
      throw Exception("Failed to support all filters");
    }

    result = binding.archive_read_support_format_all(archive);
    if (result != 0) {
      throw Exception("Failed to support all formats");
    }

    result = binding.archive_read_open_filename(archive, archivePath, 10240);
    if (result != 0) {
      throw Exception("Failed to open archive");
    }

    final paths = <String>[];
    while (true) {
      final entry = binding.archive_entry_new();
      result = binding.archive_read_next_header(archive, entry);
      if (result == 1) {
        break;
      }

      if (result == 0) {
        paths.add(binding.archive_entry_pathname_utf8(entry));
      } else {
        throw Exception("Failed to read next header");
      }
    }

    binding.archive_read_free(archive);
    return paths;
  }
}
