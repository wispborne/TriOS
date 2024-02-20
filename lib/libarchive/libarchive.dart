import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:fimber/fimber.dart';
import 'package:path/path.dart' as p;
import 'package:trios/libarchive/libarchive_bindings.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/util.dart';

class LibArchive {
  late var binding = _getArchive();

  LibArchiveBinding _getArchive() {
    final currentLibarchivePath = p.join(Directory.current.absolute.path, "assets/libarchive");

    final libArchivePathForPlatform = switch (Platform.operatingSystem) {
      "windows" => Directory("$currentLibarchivePath/windows/bin/archive.dll").absolute.normalize.path,
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
    if (!File(archivePath).existsSync()) {
      throw Exception("File not found at $archivePath");
    }

    final Pointer<archive> archivePtr = binding.archive_read_new();
    var errCode = 0;

    try {
      errCode = binding.archive_read_support_filter_all(archivePtr);
      if (errCode != ARCHIVE_OK) {
        throw Exception("Failed to support all filters. Error code: ${errorCodeToString(errCode)}.");
      }

      errCode = binding.archive_read_support_format_all(archivePtr);
      if (errCode != ARCHIVE_OK) {
        throw Exception("Failed to support all formats. Error code: ${errorCodeToString(errCode)}.");
      }

      var pathPtr = archivePath.toNativeChar();
      var readPointer = binding.archive_read_open_filename(archivePtr, pathPtr, 10240);
      calloc.free(pathPtr);
      if (readPointer != ARCHIVE_OK) {
        throw Exception("Failed to open archive. Error code: ${errorCodeToString(readPointer)}.");
      }

      Pointer<archive_entry> entryPtr = binding.archive_entry_new();
      final paths = <String>[];
      while (true) {
        Pointer<Pointer<archive_entry>> entryPtrPtr = calloc();
        entryPtrPtr.value = Pointer.fromAddress(entryPtr.address);
        readPointer = binding.archive_read_next_header(archivePtr, entryPtrPtr);
        if (readPointer == ARCHIVE_EOF) {
          break;
        }

        if (readPointer < ARCHIVE_OK) {
          throw Exception("Failed to read next header. Error code: ${errorCodeToString(readPointer)}.");
        } else if (readPointer < ARCHIVE_WARN) {
          throw Exception("Warning while reading next header. Error code: ${errorCodeToString(readPointer)}.");
        } else {
          var pathNamePtr = binding.archive_entry_pathname_utf8(entryPtrPtr.value).cast<Utf8>();
          if (pathNamePtr == nullptr) {
            Fimber.d("Path name is null");
            continue;
          }
          var filePath = pathNamePtr.toDartString();
          paths.add(filePath);
        }
      }

      return paths;
    } catch (e, st) {
      throw NestedException("Failed to list paths in archive '$archivePath'.", e, st);
    } finally {
      binding.archive_read_free(archivePtr);
    }

    throw Exception("Failed to list paths in archive");
  }

  /// const int ARCHIVE_EOF = 1;
  /// const int ARCHIVE_OK = 0;
  /// const int ARCHIVE_RETRY = -10;
  /// const int ARCHIVE_WARN = -20;
  /// const int ARCHIVE_FAILED = -25;
  /// const int ARCHIVE_FATAL = -30;
  String errorCodeToString(int errorCode) {
    return switch (errorCode) {
      1 => "ARCHIVE_EOF",
      0 => "ARCHIVE_OK",
      -10 => "ARCHIVE_RETRY",
      -20 => "ARCHIVE_WARN",
      -25 => "ARCHIVE_FAILED",
      -30 => "ARCHIVE_FATAL",
      _ => "Unknown error code $errorCode"
    };
  }
}

extension NativeStringExt on String {
  /// Converts this [String] to a [Pointer<Utf8>].
  /// Make sure to call [calloc.free] on the result when you're done with it.
  Pointer<Char> toNativeChar({Allocator allocator = malloc}) {
    return toNativeUtf8(allocator: allocator).cast();
  }
}
