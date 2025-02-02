import 'dart:ffi';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:trios/compression/archive.dart';
import 'package:trios/compression/libarchive/libarchive_bindings.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/logging.dart';
import 'package:trios/utils/util.dart';

class LibArchiveEntry implements ArchiveEntry {
  final String pathName;
  final int unpackedSize;
  final int modifiedTime;
  final int birthTime;
  final int cTime;
  final int accessedTime;
  final int fileType;
  final String? fflags;
  final String? gname;
  final String? sourcePath;
  final int sizeIsSet;
  final int isEncrypted;

  LibArchiveEntry(
      this.pathName,
      this.unpackedSize,
      this.modifiedTime,
      this.birthTime,
      this.cTime,
      this.accessedTime,
      this.fileType,
      this.fflags,
      this.gname,
      this.sourcePath,
      this.sizeIsSet,
      this.isEncrypted);

  @override
  String toString() {
    return "LibArchiveEntry{pathName: $pathName, unpackedSize: $unpackedSize, mTime: $modifiedTime, birthTime: $birthTime, cTime: $cTime, aTime: $accessedTime, type: $fileType, fflags: $fflags, gname: $gname, sourcePath: $sourcePath, sizeIsSet: $sizeIsSet, isEncrypted: $isEncrypted}";
  }

  late FileSystemEntity file = FileSystemEntity.isDirectorySync(pathName)
      ? Directory(pathName)
      : File(pathName);

  @override
  String get path => pathName;
  late bool isDirectory = fileType == AE_IFDIR;
}

class LibArchiveExtractedFile implements ArchiveExtractedFile<LibArchiveEntry> {
  @override
  final LibArchiveEntry archiveFile;
  @override
  final File extractedFile;

  LibArchiveExtractedFile(this.archiveFile, this.extractedFile);
}

class LibArchiveReadFile implements ArchiveReadFile<LibArchiveEntry> {
  @override
  final LibArchiveEntry archiveFile;
  @override
  final Uint8List extractedContent;

  LibArchiveReadFile(this.archiveFile, this.extractedContent);
}

/// Not thread-safe.
class LibArchive implements ArchiveInterface {
  static late final LibArchiveBinding binding;

  LibArchive() {
    binding = _getArchive();
  }

  LibArchive.fromPath(Directory libArchivePath) {
    binding = _getArchive(assetsPath: libArchivePath);
  }

  static LibArchiveBinding _getArchive({Directory? assetsPath}) {
    final currentAssetsPath = assetsPath?.path ?? getAssetsPath();

    final libArchivePathForPlatform = switch (Platform.operatingSystem) {
      "windows" =>
        File("$currentAssetsPath/windows/libarchive/bin/archive.dll"),
      "macos" =>
        File("$currentAssetsPath/macos/libarchive/lib/libarchive.dylib"),
      "linux" => File("$currentAssetsPath/linux/libarchive/lib/libarchive.so"),
      _ =>
        throw UnimplementedError('Libarchive not supported for this platform')
    }
        .absolute
        .normalize
        .toFile();

    if (!libArchivePathForPlatform.existsSync()) {
      throw Exception("Libarchive not found at $libArchivePathForPlatform");
    }

    final libraries = switch (currentPlatform) {
      TargetPlatform.windows => [
          "zstd.dll",
          "libcrypto-3-x64.dll",
          "lz4.dll",
          "zlib1.dll",
          "iconv-2.dll",
          "liblzma.dll",
          "bz2.dll",
          "libxml2.dll"
        ],
      TargetPlatform.macOS => [],
      _ => [],
    };

    for (String lib in libraries) {
      DynamicLibrary.open(libArchivePathForPlatform.parent.resolve(lib).path);
    }

    var dynamicLibrary = DynamicLibrary.open(libArchivePathForPlatform.path);

    return LibArchiveBinding(dynamicLibrary);
  }

  List<T> readArchiveAndDoOnEach<T>(
      String archivePath,
      T Function(Pointer<archive> archivePtr,
              Pointer<Pointer<archive_entry>> entryPtrPtr)
          action) {
    if (!File(archivePath).existsSync()) {
      throw Exception("File not found at $archivePath");
    }

    final Pointer<archive> archivePtr = binding.archive_read_new();
    var errCode = 0;

    try {
      errCode = binding.archive_read_support_filter_all(archivePtr);
      if (errCode != ARCHIVE_OK) {
        throw Exception(
            "Failed to support all filters. Error code: ${_errorCodeToString(errCode)}. "
            "Message: ${binding.archive_error_string(archivePtr).toDartStringSafe()}. ");
      }

      errCode = binding.archive_read_support_format_all(archivePtr);
      if (errCode != ARCHIVE_OK) {
        throw Exception(
            "Failed to support all formats. Error code: ${_errorCodeToString(errCode)}. "
            "Message: ${binding.archive_error_string(archivePtr).toDartStringSafe()}. ");
      }

      final fileBytes = File(archivePath).readAsBytesSync();
      final Pointer<Uint8> buffer = malloc.allocate<Uint8>(fileBytes.length);
      buffer.asTypedList(fileBytes.length).setAll(0, fileBytes);

      var readPointer = binding.archive_read_open_memory(
          archivePtr, buffer as Pointer<Void>, fileBytes.length);

      if (readPointer != ARCHIVE_OK) {
        throw Exception(
            "Failed to open archive. Error code: ${_errorCodeToString(readPointer)}. "
            "Message: ${binding.archive_error_string(archivePtr).toDartStringSafe()}. ");
      }

      Pointer<archive_entry> entryPtr = binding.archive_entry_new();
      final paths = <T>[];
      while (true) {
        Pointer<Pointer<archive_entry>> entryPtrPtr = calloc();
        entryPtrPtr.value = Pointer.fromAddress(entryPtr.address);
        readPointer = binding.archive_read_next_header(archivePtr, entryPtrPtr);
        if (readPointer == ARCHIVE_EOF) {
          break;
        }

        if (readPointer < ARCHIVE_OK) {
          // ARCHIVE_WARN. Message: Pathname cannot be converted from UTF-8 to current locale.
          // [C](势力)趋光议会ApproLight 1.2.0.zip'
          throw Exception(
              "Failed to read next header. Error code: ${_errorCodeToString(readPointer)}. "
              "Message: ${binding.archive_error_string(archivePtr).toDartStringSafe()}. ");
        } else if (readPointer < ARCHIVE_WARN) {
          throw Exception(
              "Warning while reading next header. Error code: ${_errorCodeToString(readPointer)}. "
              "Message: ${binding.archive_error_string(archivePtr).toDartStringSafe()}. ");
        } else {
          // Combat-Activators-v1.1.3/src/activators/examples/ToggledDriveActivator.java
          final pathName = getEntryPathnamePlatformAware(entryPtrPtr);
          if (pathName == null) {
            Fimber.d("Path name is null");
            continue;
          }

          var value = action(archivePtr, entryPtrPtr);
          if (value != null) {
            paths.add(value);
          }
        }
      }

      return paths;
    } catch (e, st) {
      throw NestedException("Failed in archive '$archivePath'.", e, st);
    } finally {
      binding.archive_read_free(archivePtr);
    }
  }

  List<LibArchiveEntry> listEntriesInArchive(File archivePath) {
    return readArchiveAndDoOnEach(archivePath.path,
        (archivePtr, entryPtrPtr) => _getEntryInArchive(entryPtrPtr));
  }

  final _ignorableErrors = [
    // Thrown by .rar for all folders.
    "Can't decompress an entry marked as a directory",
  ];

  /// Extracts all entries in the archive to the destination path.
  /// - `archivePath` is the path to the archive file.
  /// - `destinationPath` is the path to the directory where the archive will be extracted.
  /// - `fileFilter` is a function that filters the files to be extracted. If it returns `false`, the file will not be extracted.
  /// - `pathTransform` is a function that transforms the path of the extracted file. If it is not provided, the path will be the same as the path in the archive.
  /// - `onError` is a function that is called when an error occurs. If it returns `true`, the error will be ignored and the extraction will continue. If it returns `false`, the error will be thrown.
  Future<List<LibArchiveExtractedFile?>> extractEntriesInArchive(
    File archivePath,
    String destinationPath, {
    bool Function(LibArchiveEntry entry)? fileFilter,
    String Function(LibArchiveEntry entry)? pathTransform,
    bool Function(Object ex, StackTrace st)? onError,
  }) async {
    final writePtr = binding.archive_write_disk_new();
    try {
      const writeFlags = ARCHIVE_EXTRACT_TIME |
          ARCHIVE_EXTRACT_PERM |
          ARCHIVE_EXTRACT_ACL |
          ARCHIVE_EXTRACT_FFLAGS;
      binding.archive_write_disk_set_options(writePtr, writeFlags);
      binding.archive_write_disk_set_standard_lookup(writePtr);
      var errCode = 0;

      // Iterate through the archive and extract each entry
      return readArchiveAndDoOnEach(archivePath.absolute.path,
          (archivePtr, entryPtrPtr) {
        final entry = _getEntryInArchive(entryPtrPtr);
        if (fileFilter != null && !fileFilter(entry)) {
          return null;
        } else {
          try {
            return _extractSingleEntryInArchive(entryPtrPtr, destinationPath,
                errCode, writePtr, archivePtr, entry,
                pathTransform: pathTransform);
          } catch (e, st) {
            if (_ignorableErrors.contains(e.toString()) ||
                _ignorableErrors.any((error) => e.toString().contains(error))) {
              return null;
            }

            // If onError exists and handles the error, continue with the next entry
            if (onError != null && onError(e, st)) {
              return null;
            } else {
              rethrow;
            }
          }
        }
      }).nonNulls.toList();
    } finally {
      binding.archive_write_free(writePtr);
    }
  }

  LibArchiveExtractedFile _extractSingleEntryInArchive(
    Pointer<Pointer<archive_entry>> entryPtrPtr,
    String destinationPath,
    int errCode,
    Pointer<archive> writePtr,
    Pointer<archive> archivePtr,
    LibArchiveEntry entry, {
    String Function(LibArchiveEntry entry)? pathTransform,
  }) {
    // Add the destination path to the entry
    final outputPath = p.join(destinationPath,
        pathTransform != null ? pathTransform(entry) : entry.pathName);
    binding.archive_entry_set_pathname_utf8(
        entryPtrPtr.value, outputPath.toNativeChar());

    // Create the file header (creates the file?)
    errCode = binding.archive_write_header(
        writePtr,
        entryPtrPtr
            .value); // not sure about using entryPtrPtr instead of entryPtr
    if (errCode < ARCHIVE_OK) {
      throw Exception(
          "Failed to write header. Error code: ${_errorCodeToString(errCode)}. $outputPath");
    }

    // Copy the data from the archive to the file
    errCode = _copyData(archivePtr, writePtr);
    if (errCode < ARCHIVE_OK) {
      throw Exception(
          "Failed to copy data. Error code: ${_errorCodeToString(errCode)}. "
          "Message: ${binding.archive_error_string(archivePtr).toDartStringSafe()}. "
          "$outputPath");
    }
    if (errCode < ARCHIVE_WARN) {
      throw Exception(
          "Warning while copying data. Error code: ${_errorCodeToString(errCode)}. "
          "Message: ${binding.archive_error_string(archivePtr).toDartStringSafe()}. "
          "$outputPath");
    }

    return LibArchiveExtractedFile(entry, File(outputPath));
  }

  LibArchiveEntry _getEntryInArchive(
      Pointer<Pointer<archive_entry>> entryPtrPtr) {
    final pathName = getEntryPathnamePlatformAware(entryPtrPtr)!;
    final unpackedSize = binding.archive_entry_size(entryPtrPtr.value);
    final mTime = binding.archive_entry_mtime(entryPtrPtr.value);
    final birthTime = binding.archive_entry_birthtime(entryPtrPtr.value);
    final cTime = binding.archive_entry_ctime(entryPtrPtr.value);
    final aTime = binding.archive_entry_atime(entryPtrPtr.value);
    final type = binding.archive_entry_filetype(entryPtrPtr.value);
    final fflags =
        binding.archive_entry_fflags_text(entryPtrPtr.value).toDartStringSafe();
    final gname =
        binding.archive_entry_gname(entryPtrPtr.value).toDartStringSafe();
    final sourcePath =
        binding.archive_entry_sourcepath(entryPtrPtr.value).toDartStringSafe();
    final sizeIsSet = binding.archive_entry_size_is_set(entryPtrPtr.value);
    final isEncrypted = binding.archive_entry_is_encrypted(entryPtrPtr.value);

    return LibArchiveEntry(pathName, unpackedSize, mTime, birthTime, cTime,
        aTime, type, fflags, gname, sourcePath, sizeIsSet, isEncrypted);
  }

  /// [archive_entry_pathname_utf8] is needed on Windows to extract non-ASCII filenames, otherwise the file is skipped.
  /// However, [archive_entry_pathname_utf8] causes filenames to be empty on MacOS.
  /// MacOS works correctly using [archive_entry_pathname].
  String? getEntryPathnamePlatformAware(
          Pointer<Pointer<archive_entry>> entryPtrPtr) =>
      Platform.isWindows
          ? binding
              .archive_entry_pathname_utf8(entryPtrPtr.value)
              .toDartStringSafe()
          : binding
              .archive_entry_pathname(entryPtrPtr.value)
              .toDartStringSafe();

  int _copyData(Pointer<archive> ar, Pointer<archive> aw) {
    final buffer = malloc<Uint8>(10240); // Allocate a temporary buffer
    try {
      int errCode = 0;
      final size = calloc<Size>();
      final offset = calloc<LongLong>();

      final bufferPtr = malloc<Pointer<Void>>();
      bufferPtr.value = Pointer.fromAddress(buffer.address);
      final sizePtr = malloc<Pointer<Size>>();
      sizePtr.value = Pointer.fromAddress(size.address);
      final offsetPtr = malloc<Pointer<LongLong>>();
      offsetPtr.value = Pointer.fromAddress(offset.address);

      while (true) {
        errCode = binding.archive_read_data_block(
            ar, bufferPtr, sizePtr.value, offsetPtr.value);
        if (errCode == ARCHIVE_EOF) {
          return ARCHIVE_OK;
        }

        if (errCode < ARCHIVE_OK) {
          return errCode;
        }

        errCode = binding.archive_write_data_block(
            aw, bufferPtr.value, size.value, offset.value);
        if (errCode < ARCHIVE_OK) {
          return errCode;
        }
      }
    } finally {
      calloc.free(buffer); //  Deallocate the temporary buffer
    }
  }

  Future<List<LibArchiveReadFile?>> readEntriesInArchive(
    File archivePath, {
    bool Function(LibArchiveEntry entry)? fileFilter,
    String Function(LibArchiveEntry entry)? pathTransform,
    bool Function(Object ex, StackTrace st)? onError,
  }) async {
    final archivePtr = binding.archive_read_new();
    final entryPtrPtr = calloc<Pointer<archive_entry>>();

    try {
      // Enable all filters and formats
      binding.archive_read_support_filter_all(archivePtr);
      binding.archive_read_support_format_all(archivePtr);

      // Open the archive file
      final openResult = binding.archive_read_open_filename(archivePtr,
          archivePath.absolute.path.toNativeUtf8().cast<Char>(), 10240);
      if (openResult != ARCHIVE_OK) {
        throw Exception(
            'Failed to open archive: ${binding.archive_error_string(archivePtr).toDartStringSafe()}');
      }

      final extractedFiles = <LibArchiveReadFile>[];

      while (binding.archive_read_next_header(archivePtr, entryPtrPtr) ==
          ARCHIVE_OK) {
        try {
          final entry = _getEntryInArchive(entryPtrPtr);

          // Apply file filter if provided
          if (fileFilter != null && !fileFilter(entry)) {
            // Skip this entry
            binding.archive_read_data_skip(archivePtr);
            continue;
          }

          // Transform path if pathTransform is provided
          if (pathTransform != null) {
            final transformedPath = pathTransform(entry);
            binding.archive_entry_set_pathname_utf8(
                entryPtrPtr.value, transformedPath.toNativeUtf8().cast<Char>());
          }

          // Read data into memory
          final extractedContent = _readData(archivePtr);

          extractedFiles.add(LibArchiveReadFile(
            entry,
            extractedContent,
          ));
        } catch (e, st) {
          // Handle errors
          if (onError != null && onError(e, st)) {
            // Skip to the next entry
            continue;
          } else {
            rethrow;
          }
        }
      }

      return extractedFiles;
    } finally {
      // Clean up
      binding.archive_read_close(archivePtr);
      binding.archive_read_free(archivePtr);
      calloc.free(entryPtrPtr);
    }
  }

  Uint8List _readData(Pointer<archive> ar) {
    // Create a BytesBuilder to accumulate the data
    final data = BytesBuilder();

    // Allocate pointers for the output parameters
    final bufferPtrPtr = calloc<Pointer<Void>>();
    final sizePtr = calloc<Size>();
    final offsetPtr = calloc<LongLong>();

    try {
      int errCode = 0;

      while (true) {
        errCode = binding.archive_read_data_block(
            ar, bufferPtrPtr, sizePtr, offsetPtr);

        if (errCode == ARCHIVE_EOF) {
          // End of file
          break;
        }

        if (errCode < ARCHIVE_OK) {
          // Handle error
          throw Exception('Error reading data block: $errCode');
        }

        // Access the data block
        final bufferPtr = bufferPtrPtr.value.cast<Uint8>();
        final int size = sizePtr.value;

        // Read the data into a Uint8List
        final chunk = bufferPtr.asTypedList(size);

        // Add the chunk to the BytesBuilder
        data.add(chunk);
      }

      // Return the accumulated data
      return data.takeBytes();
    } finally {
      // Free allocated pointers
      calloc.free(bufferPtrPtr);
      calloc.free(sizePtr);
      calloc.free(offsetPtr);
    }
  }

  /// - `ARCHIVE_EOF` is returned only from `archive_read_data()` functions when you reach the end of the data in an entry or from `archive_read_next_header()` when you reach the end of the archive.
  /// - `ARCHIVE_OK` if the operation completed successfully
  /// - `ARCHIVE_WARN` if the operation completed with some surprises. You may want to report the issue to your user. `archive_error_string` will return a suitable text message, `archive_errno` returns an associated system errno value. (Since not all errors are caused by failing system calls, `archive_errno` does not always return a meaningful value.)
  /// - `ARCHIVE_FAILED` if this operation failed. In particular, this means that further operations on this entry are impossible. This is returned, for example, if you try to write an entry type that's not supported by this archive format. Recovery usually consists of simply going on to the next entry.
  /// - `ARCHIVE_FATAL` if the archive object itself is no longer usable, typically because of an I/O failure or memory allocation failure. Generally, your only recovery in this case is to invoke `archive_write_finish` to release the archive object.
  String _errorCodeToString(int errorCode) {
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

  @override
  Future<void> extractAll(File archiveFile, Directory destination) {
    return extractEntriesInArchive(archiveFile, destination.path);
  }

  @override
  Future<void> extractSome(
      File archiveFile, Directory destination, List<String> inArchivePaths) {
    return extractEntriesInArchive(archiveFile, destination.path,
        fileFilter: (entry) => inArchivePaths.contains(entry.path));
  }

  @override
  Future<List<LibArchiveEntry>> listFiles(File archiveFile) {
    return readEntriesInArchive(archiveFile).then((entries) => entries
        .map((e) => e?.archiveFile)
        .whereType<LibArchiveEntry>()
        .toList());
  }
}

extension NativeStringExt on String {
  /// Converts this [String] to a [Pointer<Utf8>].
  /// Make sure to call [calloc.free] on the result when you're done with it.
  Pointer<Char> toNativeChar({Allocator allocator = malloc}) {
    return toNativeUtf8(allocator: allocator).cast();
  }
}

extension CharPtrExt on Pointer<Char> {
  /// Converts this [Pointer<Char>] to a [String].
  String? toDartStringSafe() {
    final ptr = cast<Utf8>();
    return ptr == nullptr ? null : ptr.toDartString();
  }
}
