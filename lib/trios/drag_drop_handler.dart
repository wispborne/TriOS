import 'dart:async';
import 'dart:io';

import 'package:dart_extensions_methods/dart_extension_methods.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:super_clipboard/src/reader.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';
import 'package:trios/chipper/chipper_state.dart';
import 'package:trios/mod_manager/batch_installation/batch_installation_notifier.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/modpacks/incoming/incoming_modpack.dart';
import 'package:trios/modpacks/incoming/incoming_modpack_handler.dart';
import 'package:trios/trios/download_manager/download_manager.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/logging.dart';
import 'package:trios/widgets/file_card.dart';
import 'package:trios/widgets/rainbow/themed_progress_indicator.dart';

import '../chipper/views/chipper_home.dart';
import 'constants.dart';

class DragDropHandler extends ConsumerStatefulWidget {
  final Widget child;
  final void Function(String)? onDroppedLog;

  const DragDropHandler({super.key, required this.child, this.onDroppedLog});

  @override
  ConsumerState createState() => _DragDropHandlerState();
}

class _DragDropHandlerState extends ConsumerState<DragDropHandler> {
  bool _dragging = false;
  bool _inProgress = false;
  List<DropItem>? hoveredEvents;
  Future<DroppedContents>? _hoveredContents;
  DropSession? _modpackCheckSession;
  Future<bool> _modpackCheck = Future.value(false);

  // Offset? _offset;
  static int _lastDropTimestamp = 0;
  static const _minDropInterval = 400;

  @override
  Widget build(BuildContext context) {
    final isGameRunning = ref.watch(AppState.isGameRunning).value == true;

    return DropRegion(
      formats: Formats.standardFormats,
      onPerformDrop: (detail) async {
        // The onDragDone callback is called twice for the same drop event, add a timer to avoid it.
        if (DateTime.now().millisecondsSinceEpoch - _lastDropTimestamp <
            _minDropInterval) {
          return;
        } else {
          _lastDropTimestamp = DateTime.now().millisecondsSinceEpoch;
        }

        final droppedItems = detail.session.items;

        Fimber.i("Dropped ${droppedItems.length} files.");
        // Fimber.i("Dropped ${detail.files.length} files at $_offset");

        if (droppedItems.isEmpty) {
          return;
        }

        final contents = await readDroppedContents(droppedItems);
        final files = contents.files;
        final urls = contents.urls;
        for (final incoming in contents.modpackInputs) {
          if (!context.mounted) return;
          setState(() {
            _dragging = false;
            hoveredEvents = null;
            _hoveredContents = null;
          });
          await ref
              .read(incomingModpackHandlerProvider)
              .receive(incoming, context: context);
        }
        if (!context.mounted || (files.isEmpty && urls.isEmpty)) return;
        if (ref.read(AppState.isGameRunning).value == true ||
            ref.read(AppState.ignoringDrop) == true) {
          return;
        }
        if (ref.read(AppState.canWriteToModsFolder).value == false) {
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text("Cannot modify mods folder"),
                content: const Text("Try running TriOS as administrator."),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text("OK"),
                  ),
                ],
              );
            },
          );
          return;
        }

        for (final uri in urls) {
          ref
              .read(downloadManager.notifier)
              .downloadAndInstallMod(
                'Web link download',
                uri.toString(),
                activateVariantOnComplete: false,
                sourceHint: null,
              );
        }
        if (files.isEmpty) {
          Fimber.i("No files dropped.");
          return;
        }

        if (files.any(
          (file) =>
              (file is File &&
                  file.extension.equalsAnyIgnoreCase(
                    Constants.supportedArchiveExtensions,
                  )) ||
              file.isDirectory(),
        )) {
          {
            setState(() {
              _inProgress = true;
            });
            try {
              _handleDroppedModFilesAndFolders(files);
            } finally {
              setState(() {
                _inProgress = false;
              });
            }
          }
        } else {
          final firstFile = files.first;
          handleDroppedLogFile(firstFile.path).then((logFile) {
            if (logFile == null) {
              return; // TODO ref.read(ChipperState.logRawContents).value;
            }
            return ref
                .read(ChipperState.logRawContents.notifier)
                .parseLogAndSetState(logFile);
          });
          widget.onDroppedLog?.call(firstFile.path);
        }
      },
      onDropOver: (detail) async {
        final ignoringDrop = ref.read(AppState.ignoringDrop) == true;
        if (detail.session.items.isEmpty ||
            (ignoringDrop && !await _containsModpack(detail.session))) {
          return DropOperation.none;
        } else if (detail.session.items.hashCode == hoveredEvents.hashCode) {
          return DropOperation.copy;
        }

        // final files = (await Future.wait(detail.session.items.map((e) async {
        //   final reader = e.dataReader;
        //   if (reader == null) return null;
        //
        //   // File
        //   var name = await reader.getSuggestedName();
        //   if (reader.canProvide(Formats.fileUri)) {
        //     Fimber.i("Dropped file: $name");
        //     return name;
        //   } else if (reader.canProvide(Formats.uri)) {
        //     Fimber.i("Dropped uri: $name");
        //     return name;
        //   }
        //
        //   return null;
        // })))
        //     .nonNulls
        //     .toList()

        final files = (await filterToSupportedTypes(detail.session.items))
            .orEmpty()
            .toList();
        if (files.isEmpty) {
          return DropOperation.none;
        }

        setState(() {
          _dragging = true;
          hoveredEvents = files;
          _hoveredContents = readDroppedContents(files);
          // _offset = detail.localPosition;
        });
        return DropOperation.copy;
      },
      onDropEnter: (detail) {
        final ignoringDrop = ref.read(AppState.ignoringDrop) == true;
        if (detail.session.items.isEmpty || ignoringDrop) {
          return;
        }
        setState(() {
          _dragging = true;
          // _offset = detail.session.localPosition;
        });
      },
      onDropLeave: (detail) {
        final ignoringDrop = ref.read(AppState.ignoringDrop) == true;
        if (detail.session.items.isEmpty || ignoringDrop) {
          return;
        }
        setState(() {
          _dragging = false;
          // _offset = null;
          hoveredEvents = null;
          _hoveredContents = null;
        });
      },
      child: Builder(
        builder: (context) {
          final ignoringDrop = ref.watch(AppState.ignoringDrop) == true;

          return Stack(
            children: [
              widget.child,
              if (!ignoringDrop)
                IgnorePointer(
                  child: Container(
                    color: _dragging
                        ? Colors.blue.withOpacity(0.4)
                        : Colors.transparent,
                    child: _inProgress
                        ? Center(child: ThemedCircularProgressIndicator())
                        : hoveredEvents != null
                        ? SizedBox(
                            width: double.infinity,
                            height: double.infinity,
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: FutureBuilder(
                                  future: _hoveredContents,
                                  builder: (context, snapshot) {
                                    final contents = snapshot.data;
                                    if (contents == null) {
                                      return const SizedBox.shrink();
                                    }
                                    if (contents.modpackInputs.isNotEmpty) {
                                      return const Text('Open modpack preview');
                                    }
                                    if (isGameRunning) {
                                      return const Text(
                                        'Game is running. Close to install mods.',
                                      );
                                    }
                                    return IntrinsicHeight(
                                      child: IntrinsicWidth(
                                        child: ConstrainedBox(
                                          constraints: const BoxConstraints(
                                            minWidth: 400,
                                          ),
                                          child: DragDropInstallModOverlay(
                                            entities: contents.files,
                                            urls: contents.urls,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          )
                        : null,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  /// Handles dropped files and folders.
  void _handleDroppedModFilesAndFolders(List<FileSystemEntity> files) {
    // Separate archives from directory drops.
    final archiveFiles = <File>[];
    final directoryDrops = <FileSystemEntity>[];

    for (final file in files) {
      if (file.isFile()) {
        archiveFiles.add(file.toFile());
      } else {
        directoryDrops.add(file);
      }
    }

    // Archives go through the batch system.
    if (archiveFiles.isNotEmpty) {
      ref.read(batchInstallationProvider.notifier).create(archiveFiles);
    }

    // Directories also go through the batch system.
    for (final dir in directoryDrops) {
      try {
        final download = ref
            .read(downloadManager.notifier)
            .addInstallation(dir.toFile().nameWithExtension, dir.path);
        ref.read(batchInstallationProvider.notifier).create([
          Directory(dir.path),
        ], download: download);
      } catch (e, st) {
        Fimber.e("Failed to install mod from directory", ex: e, stacktrace: st);
      }
    }
  }

  Future<FileSystemEntity?> getFileFromReader(DataReader reader) async {
    final completer = Completer<String?>();
    reader.getValue(Formats.fileUri, (fileUri) {
      final filePath = fileUri?.toFilePath(windows: Platform.isWindows);
      Fimber.v(() => "Got dropped file uri: $filePath");
      completer.complete(filePath);
    });
    return (await completer.future)?.let((path) => File(path));
  }

  Future<NamedUri?> getUriFromReader(DataReader reader) async {
    final completer = Completer<NamedUri?>();
    reader.getValue(Formats.uri, (uri) {
      Fimber.v(() => "Got dropped uri: ${uri?.uri}");
      completer.complete(uri);
    });
    return await completer.future;
  }

  Future<List<DropItem>?> filterToSupportedTypes(List<DropItem> items) async {
    List<DropItem> supportedItems = [];

    for (var item in items) {
      final reader = item.dataReader;
      if (reader == null) continue;

      if (reader.canProvide(Formats.fileUri)) {
        // if ((await getFileFromReader(reader))?.isFile() == true) {
        supportedItems.add(item);
        // }
      } else if (reader.canProvide(Formats.uri)) {
        supportedItems.add(item);
      }
    }

    return supportedItems;
  }

  /// Reads one dropped item. Returns a [FileSystemEntity], a [Uri], or null.
  Future<Object?> _readDropItem(DropItem item) async {
    final reader = item.dataReader;
    if (reader == null) return null;
    if (reader.canProvide(Formats.fileUri)) return getFileFromReader(reader);
    if (reader.canProvide(Formats.uri)) {
      return (await getUriFromReader(reader))?.uri;
    }
    return null;
  }

  /// Reads every dropped item at once, then sorts them. Each read is a
  /// platform round trip, so they must not be awaited one at a time.
  Future<DroppedContents> readDroppedContents(List<DropItem> items) async {
    final resolved = await Future.wait(items.map(_readDropItem));
    final files = <FileSystemEntity>[];
    final urls = <Uri>[];
    final modpackInputs = <String>[];
    for (final entry in resolved) {
      if (entry is FileSystemEntity) {
        if (isModpackFile(entry.path)) {
          modpackInputs.add(entry.uri.toString());
        } else {
          files.add(entry);
        }
      } else if (entry is Uri) {
        if (isIncomingModpack(entry.toString())) {
          modpackInputs.add(entry.toString());
        } else {
          urls.add(entry);
        }
      }
    }
    return DroppedContents(files, urls, modpackInputs);
  }

  /// onDropOver fires on every pointer move, so the reads are cached for as
  /// long as the pointer stays with the same drag session.
  Future<bool> _containsModpack(DropSession session) async {
    if (!identical(session, _modpackCheckSession)) {
      _modpackCheckSession = session;
      _modpackCheck = readDroppedContents(
        session.items,
      ).then((contents) => contents.modpackInputs.isNotEmpty);
    }
    return _modpackCheck;
  }
}

/// What a drag-and-drop session is offering, once every item has been read.
class DroppedContents {
  final List<FileSystemEntity> files;
  final List<Uri> urls;

  /// Inputs for [IncomingModpackHandler.receive]: file URIs or link text.
  final List<String> modpackInputs;

  const DroppedContents(this.files, this.urls, this.modpackInputs);

  bool get isEmpty => files.isEmpty && urls.isEmpty && modpackInputs.isEmpty;
}

class IgnoreDropMouseRegion extends ConsumerStatefulWidget {
  final Widget child;

  const IgnoreDropMouseRegion({super.key, required this.child});

  @override
  ConsumerState<IgnoreDropMouseRegion> createState() =>
      _IgnoreDropMouseRegionState();
}

class _IgnoreDropMouseRegionState extends ConsumerState<IgnoreDropMouseRegion> {
  bool _isDragging = false;

  void _updateIgnoringDrop(bool state) {
    ref.read(AppState.ignoringDrop.notifier).state = state;
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _updateIgnoringDrop(true),
      onExit: (PointerEvent event) async {
        if (_isDragging) return; // Prevent resetting during drag
        await Future.delayed(const Duration(milliseconds: 500));
        if (!mounted) return; // Widget may have been disposed during the delay
        _updateIgnoringDrop(false);
      },
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) {
          _isDragging = true;
          _updateIgnoringDrop(true);
        },
        onPointerMove: (_) {
          if (_isDragging) _updateIgnoringDrop(true);
        },
        onPointerUp: (_) {
          _isDragging = false;
          _updateIgnoringDrop(true);
        },
        child: widget.child,
      ),
    );
  }
}
