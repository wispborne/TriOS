import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/chipper/chipper_state.dart';
import 'package:trios/mod_manager/mod_manager_logic.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/logging.dart';

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
  Offset? _offset;
  static int _lastDropTimestamp = 0;
  static const _minDropInterval = 400;

  @override
  Widget build(BuildContext context) {
    return DropTarget(
      onDragDone: (detail) async {
        // The onDragDone callback is called twice for the same drop event, add a timer to avoid it.
        if (DateTime.now().millisecondsSinceEpoch - _lastDropTimestamp <
            _minDropInterval) {
          return;
        } else {
          _lastDropTimestamp = DateTime.now().millisecondsSinceEpoch;
        }

        Fimber.i('onDragDone:');
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

        final files = detail.files.map((e) => e.path.toFile()).toList();

        if (files.any((file) => file.extension
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
                  await installModFromArchiveWithDefaultUI(
                      filePath.toFile(), ref, context);
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
      onDragUpdated: (details) {
        setState(() {
          _offset = details.localPosition;
        });
      },
      onDragEntered: (detail) {
        setState(() {
          _dragging = true;
          _offset = detail.localPosition;
        });
      },
      onDragExited: (detail) {
        setState(() {
          _dragging = false;
          _offset = null;
        });
      },
      child: Stack(
        children: [
          widget.child,
          IgnorePointer(
            child: Container(
              color:
                  _dragging ? Colors.blue.withOpacity(0.4) : Colors.transparent,
              child: _inProgress
                  ? const Center(child: CircularProgressIndicator())
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
