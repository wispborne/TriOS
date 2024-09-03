import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

import 'logging.dart'; // Assuming you're using Fimber for logging

extension PlatformFileEntityExt on FileSystemEntity {
  void moveToTrash() {
    if (Platform.isWindows) {
      _moveToRecycleBinWindows(path);
    } else if (Platform.isMacOS) {
      _moveToTrashMacOS(path);
    } else if (Platform.isLinux) {
      _moveToTrashLinux(path);
    } else {
      throw UnsupportedError(
          'This platform is not supported for trash operation.');
    }
  }
}

void _moveToRecycleBinWindows(String path) {
  final filePath = TEXT(path);

  final fileOpStruct = calloc<SHFILEOPSTRUCT>()
    ..ref.wFunc = FO_DELETE
    ..ref.pFrom = filePath.cast()
    ..ref.fFlags = FILEOPERATION_FLAGS.FOF_ALLOWUNDO |
        FILEOPERATION_FLAGS.FOF_NOCONFIRMATION |
        FILEOPERATION_FLAGS.FOF_SILENT;

  final result = SHFileOperation(fileOpStruct);

  if (result != 0) {
    Fimber.w("Failed to move file to Recycle Bin.");
  }

  calloc.free(filePath);
  calloc.free(fileOpStruct);
}

// macOS's underlying API
typedef MoveToTrashNative = Int32 Function(
    Pointer<Utf8> path, Pointer<Pointer<Utf8>> errorMessage);
typedef MoveToTrashDart = int Function(
    Pointer<Utf8> path, Pointer<Pointer<Utf8>> errorMessage);

void _moveToTrashMacOS(String path) {
  final library = DynamicLibrary.open(
      '/System/Library/Frameworks/CoreServices.framework/Versions/A/CoreServices');
  final MoveToTrashDart moveToTrash = library
      .lookup<NativeFunction<MoveToTrashNative>>('FSPathMoveObjectToTrashSync')
      .asFunction();

  final pathPtr = path.toNativeUtf8();
  final errorPtr = calloc<Pointer<Utf8>>();

  final result = moveToTrash(pathPtr, errorPtr);

  if (result != 0) {
    Fimber.w("Failed to move file to Trash: ${errorPtr.value.toDartString()}");
  }

  calloc.free(pathPtr);
  if (errorPtr.value != nullptr) {
    calloc.free(errorPtr.value);
  }
  calloc.free(errorPtr);
}

void _moveToTrashLinux(String path) {
  final result = Process.runSync('gio', ['trash', path]);

  if (result.exitCode != 0) {
    Fimber.w('Failed to move file to Trash: ${result.stderr}');
  }
}
