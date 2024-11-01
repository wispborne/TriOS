import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

import 'logging.dart'; // Assuming you're using Fimber for logging

extension PlatformFileEntityExt on FileSystemEntity {
  void moveToTrash({bool deleteIfFailed = false}) {
    if (Platform.isWindows) {
      _moveToRecycleBinWindows(path, deleteIfFailed);
    } else if (Platform.isMacOS) {
      _moveToTrashMacOS(path, deleteIfFailed);
    } else if (Platform.isLinux) {
      _moveToTrashLinux(path, deleteIfFailed);
    } else {
      throw UnsupportedError(
          'This platform is not supported for trash operation.');
    }
  }
}

base class TOKEN_ELEVATION extends Struct {
  @Uint32()
  external int elevation;
}

/// Check if the current process has admin privileges (Windows-specific)
bool windowsIsAdmin() {
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
    if (GetTokenInformation(tokenHandle.value, TokenElevation, elevation,
            sizeOf<TOKEN_ELEVATION>(), returnLength) ==
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
  final filePath = TEXT(path);

  final fileOpStruct = calloc<SHFILEOPSTRUCT>()
    ..ref.wFunc = FO_DELETE
    ..ref.pFrom = filePath.cast()
    ..ref.fFlags = FILEOPERATION_FLAGS.FOF_ALLOWUNDO |
        FILEOPERATION_FLAGS.FOF_NOCONFIRMATION |
        FILEOPERATION_FLAGS.FOF_SILENT;

  final result = SHFileOperation(fileOpStruct);

  calloc.free(filePath);
  calloc.free(fileOpStruct);

  if (result != 0) {
    Fimber.w("Failed to move file to Recycle Bin. Reason: $result");

    if (deleteIfFailed) {
      File(path).deleteSync();
      Fimber.i("Deleted file: $path");
    }
  }
}

// macOS's underlying API
typedef MoveToTrashNative = Int32 Function(
    Pointer<Utf8> path, Pointer<Pointer<Utf8>> errorMessage);
typedef MoveToTrashDart = int Function(
    Pointer<Utf8> path, Pointer<Pointer<Utf8>> errorMessage);

void _moveToTrashMacOS(String path, bool deleteIfFailed) {
  final library = DynamicLibrary.open(
      '/System/Library/Frameworks/CoreServices.framework/Versions/A/CoreServices');
  final MoveToTrashDart moveToTrash = library
      .lookup<NativeFunction<MoveToTrashNative>>('FSPathMoveObjectToTrashSync')
      .asFunction();

  final pathPtr = path.toNativeUtf8();
  final errorPtr = calloc<Pointer<Utf8>>();

  final result = moveToTrash(pathPtr, errorPtr);

  if (result != 0) {
    Fimber.w(
        "Failed to move file to Trash: ${errorPtr.value.toDartString()}. Reason: $result");

    if (deleteIfFailed) {
      File(path).deleteSync();
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
      File(path).deleteSync();
      Fimber.i("Deleted file: $path");
    }
  }
}
