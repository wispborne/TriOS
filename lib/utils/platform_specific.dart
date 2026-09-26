import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:win32/win32.dart';

import 'logging.dart';

extension PlatformFileEntityExt on FileSystemEntity {
  /// Throws an exception if deleting fails.
  void moveToTrash({bool deleteIfFailed = false}) {
    if (Platform.isWindows) {
      _moveToRecycleBinWindows(path, deleteIfFailed);
    } else if (Platform.isMacOS) {
      _moveToTrashMacOS(path, deleteIfFailed);
    } else if (Platform.isLinux) {
      _moveToTrashLinux(path, deleteIfFailed);
    } else {
      throw UnsupportedError(
        'This platform is not supported for trash operation.',
      );
    }
  }
}

base class TOKEN_ELEVATION extends Struct {
  @Uint32()
  external int elevation;
}

/// Check if the current process has admin privileges (Windows-specific)
bool windowsIsAdmin() {
  if (!Platform.isWindows) {
    return false;
  }
  const int TokenElevation = 20; // TokenElevation value
  final tokenHandle = calloc<HANDLE>();
  final elevation =
      calloc<TOKEN_ELEVATION>(); // Allocate memory for TOKEN_ELEVATION struct
  final returnLength = calloc<DWORD>();

  try {
    final processHandle = GetCurrentProcess();

    // Open the process token with TOKEN_QUERY access
    if (OpenProcessToken(processHandle, TOKEN_QUERY, tokenHandle) == 0) {
      return false; // Failed to open token
    }

    // Get token elevation information
    if (GetTokenInformation(
          tokenHandle.value,
          TokenElevation,
          elevation,
          sizeOf<TOKEN_ELEVATION>(),
          returnLength,
        ) ==
        0) {
      return false; // Failed to get token information
    }

    // Check if the token is elevated
    return elevation.ref.elevation !=
        0; // Returns true if the token has admin privileges
  } finally {
    // Free allocated memory
    free(tokenHandle);
    free(elevation);
    free(returnLength);
  }
}

void _moveToRecycleBinWindows(String path, bool deleteIfFailed) {
  final filePath = TEXT('$path\0'); // Ensure double null-termination

  final fileOpStruct = calloc<SHFILEOPSTRUCT>()
    ..ref.wFunc = FO_DELETE
    ..ref.pFrom = filePath.cast()
    ..ref.fFlags = FOF_ALLOWUNDO | FOF_NOCONFIRMATION | FOF_SILENT;

  final result = SHFileOperation(fileOpStruct);

  calloc.free(filePath);
  calloc.free(fileOpStruct);

  if (result != 0) {
    Fimber.w("SHFileOperation failed with error code: $result");

    if (deleteIfFailed) {
      try {
        File(path).deleteSync(recursive: true);
        Fimber.i("Deleted file directly: $path");
      } catch (e) {
        Fimber.w(
          "Failed to delete file directly: $path. Error: $e. "
          "Retrying with Windows recursive deletion.",
        );
        try {
          deleteRecursivelyWindows(path);
          Fimber.i("Deleted file directly: $path");
        } catch (e) {
          Fimber.e("Failed to delete file directly: $path. Error: $e");
          rethrow;
        }
      }
    }
  } else {
    Fimber.i("Moved to Recycle Bin: $path");
  }
}

/// The reparse tag that cloud sync apps (OneDrive, Dropbox, Google Drive) put
/// on the files and folders they manage. Windows has 16 versions of it
/// (IO_REPARSE_TAG_CLOUD to IO_REPARSE_TAG_CLOUD_F), which differ only in the
/// bits covered by [_ioReparseTagCloudMask].
const _ioReparseTagCloud = 0x9000001A;
const _ioReparseTagCloudMask = 0x0000F000;

/// Whether [reparseTag] marks a folder managed by a cloud sync app.
/// Such a folder is a real folder with its files inside, not a link.
@visibleForTesting
bool isCloudReparseTagWindows(int reparseTag) =>
    (reparseTag & ~_ioReparseTagCloudMask) == _ioReparseTagCloud;

class _WindowsEntry {
  final String name;
  final int attributes;
  final int reparseTag;

  _WindowsEntry(this.name, this.attributes, this.reparseTag);

  bool get isDirectory => attributes & FILE_ATTRIBUTE_DIRECTORY != 0;

  bool get isReadOnly => attributes & FILE_ATTRIBUTE_READONLY != 0;

  /// True for normal folders and cloud-synced folders, which have their files
  /// inside. False for symbolic links and junctions, which point elsewhere.
  bool get hasContentsInside =>
      isDirectory &&
      (attributes & FILE_ATTRIBUTE_REPARSE_POINT == 0 ||
          isCloudReparseTagWindows(reparseTag));
}

/// Deletes [path] and everything inside it.
///
/// Dart's own recursive delete treats every folder with a reparse point as a
/// link. It removes only the folder entry and doesn't go inside. OneDrive puts
/// a reparse point on every folder it syncs, so Dart can't delete those
/// folders while they have files in them.
///
/// This goes inside folders marked by a cloud sync app. Symbolic links and
/// junctions are still removed as links only, so the folder they point to is
/// left alone.
///
/// Throws a [FileSystemException] if something can't be deleted.
/// Does nothing if [path] doesn't exist.
@visibleForTesting
void deleteRecursivelyWindows(String path) {
  // Checked here because Dart can reset Windows' error code before we read it,
  // so FindFirstFile can't reliably tell us the path is missing.
  if (FileSystemEntity.typeSync(path, followLinks: false) ==
      FileSystemEntityType.notFound) {
    return;
  }
  final fullPath = _toLongPathWindows(path);
  _deleteEntryWindows(fullPath, _findEntriesWindows(fullPath).single);
}

void _deleteEntryWindows(String path, _WindowsEntry entry) {
  if (entry.hasContentsInside) {
    for (final child in _findEntriesWindows('$path\\*')) {
      if (child.name == '.' || child.name == '..') continue;
      _deleteEntryWindows('$path\\${child.name}', child);
    }
  }

  using((arena) {
    final nativePath = path.toNativeUtf16(allocator: arena);
    if (entry.isDirectory) {
      if (RemoveDirectory(nativePath) == 0) _throwDeleteFailed(path);
    } else {
      if (entry.isReadOnly) {
        SetFileAttributes(
          nativePath,
          entry.attributes & ~FILE_ATTRIBUTE_READONLY,
        );
      }
      if (DeleteFile(nativePath) == 0) _throwDeleteFailed(path);
    }
  });
}

/// Lists entries matching [pattern], or throws if the search fails.
List<_WindowsEntry> _findEntriesWindows(String pattern) {
  return using((arena) {
    final findData = arena<WIN32_FIND_DATA>();
    final handle = FindFirstFile(
      pattern.toNativeUtf16(allocator: arena),
      findData,
    );
    if (handle == INVALID_HANDLE_VALUE) {
      throw FileSystemException(
        'Listing failed',
        _fromLongPathWindows(pattern),
        OSError('', GetLastError()),
      );
    }

    final entries = <_WindowsEntry>[];
    try {
      do {
        entries.add(
          _WindowsEntry(
            findData.ref.cFileName,
            findData.ref.dwFileAttributes,
            findData.ref.dwReserved0,
          ),
        );
      } while (FindNextFile(handle, findData) != 0);
    } finally {
      FindClose(handle);
    }
    return entries;
  });
}

Never _throwDeleteFailed(String path) {
  throw FileSystemException(
    'Deletion failed',
    _fromLongPathWindows(path),
    OSError('', GetLastError()),
  );
}

/// Adds the `\\?\` prefix so Windows accepts paths longer than 260 characters.
/// Network paths (starting with `\\`) are left as they are.
String _toLongPathWindows(String path) {
  var fullPath = File(path).absolute.path.replaceAll('/', r'\');
  while (fullPath.endsWith(r'\')) {
    fullPath = fullPath.substring(0, fullPath.length - 1);
  }
  return fullPath.startsWith(r'\\') ? fullPath : '\\\\?\\$fullPath';
}

String _fromLongPathWindows(String path) =>
    path.startsWith(r'\\?\') ? path.substring(4) : path;

// macOS's underlying API
typedef MoveToTrashNative = Int32 Function(
  Pointer<Utf8> path,
  Pointer<Pointer<Utf8>> errorMessage,
);
typedef MoveToTrashDart = int Function(
  Pointer<Utf8> path,
  Pointer<Pointer<Utf8>> errorMessage,
);

void _moveToTrashMacOS(String path, bool deleteIfFailed) {
  final library = DynamicLibrary.open(
    '/System/Library/Frameworks/CoreServices.framework/Versions/A/CoreServices',
  );
  final MoveToTrashDart moveToTrash = library
      .lookup<NativeFunction<MoveToTrashNative>>('FSPathMoveObjectToTrashSync')
      .asFunction();

  final pathPtr = path.toNativeUtf8();
  final errorPtr = calloc<Pointer<Utf8>>();

  final result = moveToTrash(pathPtr, errorPtr);

  if (result != 0) {
    Fimber.w(
      "Failed to move file to Trash: ${errorPtr.value}. Reason: $result",
    );

    if (deleteIfFailed) {
      // recursive: true so this also works when the path is a folder.
      File(path).deleteSync(recursive: true);
      Fimber.i("Deleted file: $path");
    }
  }

  calloc.free(pathPtr);
  if (errorPtr.value != nullptr) {
    calloc.free(errorPtr.value);
  }
  calloc.free(errorPtr);
}

void _moveToTrashLinux(String path, bool deleteIfFailed) {
  final result = Process.runSync('gio', ['trash', path]);

  if (result.exitCode != 0) {
    Fimber.w('Failed to move file to Trash: ${result.stderr}');

    if (deleteIfFailed) {
      // recursive: true so this also works when the path is a folder.
      File(path).deleteSync(recursive: true);
      Fimber.i("Deleted file: $path");
    }
  }
}
