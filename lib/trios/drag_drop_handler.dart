import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:super_clipboard/src/reader.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';
import 'package:trios/chipper/chipper_state.dart';
import 'package:trios/mod_manager/mod_manager_logic.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/download_manager/download_manager.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/logging.dart';
import 'package:trios/widgets/file_card.dart';

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

  // Offset? _offset;
  static int _lastDropTimestamp = 0;
  static const _minDropInterval = 400;

  @override
  Widget build(BuildContext context) {
    final isGameRunning = ref.watch(AppState.isGameRunning).value == true;

    return DropRegion(
      formats: Formats.standardFormats,
      onPerformDrop: (detail) async {
        final ignoringDrop = ref.read(AppState.ignoringDrop) == true;
        if (isGameRunning || ignoringDrop) {
          return;
        }

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
              });
          return;
        }

        final files = (await Future.wait(droppedItems.map((e) async {
          final reader = e.dataReader;
          if (reader == null) return null;

          // File
          if (reader.canProvide(Formats.fileUri)) {
            Fimber.i("Dropped file: ${await reader.getSuggestedName()}");
            return await getFileFromReader(reader);
          } else if (reader.canProvide(Formats.uri)) {
            Fimber.i("Dropped uri: ${await reader.getSuggestedName()}");
            final uri = await getUriFromReader(reader);
            if (uri == null) return null;

            ref.read(downloadManager.notifier).downloadAndInstallMod(
                  "Web link download",
                  uri.uri.toString(),
                  activateVariantOnComplete: false,
                );
            return null;
          }

          return null;
        })))
            .whereNotNull()
            .toList();

        if (files.isEmpty) {
          Fimber.i("No files dropped.");
          return;
        }

        if (files.any((file) =>
            file is File &&
            file.extension
                .equalsAnyIgnoreCase(Constants.supportedArchiveExtensions))) {
          {
            setState(() {
              _inProgress = true;
            });
            try {
              // Install each dropped archive in turn.
              // Log any errors and continue with the next archive.
              for (var filePath in files) {
                try {
                  // TODO: this works fine in _pickAndInstallMods with `await`, see what the difference is.
                  ref
                      .read(modManager.notifier)
                      .installModFromArchiveWithDefaultUI(filePath.toFile());
                } catch (e, st) {
                  Fimber.e("Failed to install mod from archive",
                      ex: e, stacktrace: st);
                }
              }
            } finally {
              setState(() {
                _inProgress = false;
              });
            }
          }
        } else {
          final firstFile = files.first;
          handleDroppedLogFile(firstFile.path).then((content) {
            if (content == null) {
              return; // TODO ref.read(ChipperState.logRawContents).valueOrNull;
            }
            return ref
                .read(ChipperState.logRawContents.notifier)
                .parseLog(LogFile(firstFile.path, content));
          });
          widget.onDroppedLog?.call(firstFile.path);
        }
      },
      onDropOver: (detail) async {
        final ignoringDrop = ref.read(AppState.ignoringDrop) == true;
        if (detail.session.items.isEmpty || ignoringDrop) {
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
        //     .whereNotNull()
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
        });
      },
      child: Builder(builder: (context) {
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
                        ? const Center(child: CircularProgressIndicator())
                        : hoveredEvents != null
                            ? SizedBox(
                                width: double.infinity,
                                height: double.infinity,
                                child: Center(
                                  child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: isGameRunning
                                          ? const Text(
                                              "Game is running. Close to install mods.")
                                          : FutureBuilder(
                                              future: Future.wait(hoveredEvents!
                                                  .map((event) async {
                                                if (event.dataReader == null) {
                                                  return null;
                                                } else if (event.dataReader!
                                                    .canProvide(
                                                        Formats.fileUri)) {
                                                  return await getFileFromReader(
                                                      event.dataReader!);
                                                } else if (event.dataReader!
                                                    .canProvide(Formats.uri)) {
                                                  return (await getUriFromReader(
                                                          event.dataReader!))
                                                      ?.uri;
                                                }
                                              })),
                                              builder: (context, future) {
                                                return IntrinsicHeight(
                                                  child: IntrinsicWidth(
                                                    child: ConstrainedBox(
                                                      constraints:
                                                          const BoxConstraints(
                                                              minWidth: 400),
                                                      child: FileCard(
                                                        entities: future.data
                                                            .orEmpty()
                                                            .whereNotNull()
                                                            .whereType<File>()
                                                            .toList(),
                                                        urls: future.data
                                                            .orEmpty()
                                                            .whereNotNull()
                                                            .whereType<Uri>()
                                                            .toList(),
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              })),
                                ),
                              )
                            : null),
              ),
          ],
        );
      }),
    );
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
        if ((await getFileFromReader(reader))?.isFile() == true) {
          supportedItems.add(item);
        }
      } else if (reader.canProvide(Formats.uri)) {
        supportedItems.add(item);
      }
    }

    return supportedItems;
  }
}

class IgnoreDropMouseRegion extends ConsumerStatefulWidget {
  final Widget child;

  const IgnoreDropMouseRegion({super.key, required this.child});

  @override
  ConsumerState<IgnoreDropMouseRegion> createState() =>
      _IgnoreDropMouseRegionState();
}

class _IgnoreDropMouseRegionState
    extends ConsumerState<IgnoreDropMouseRegion> {
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
