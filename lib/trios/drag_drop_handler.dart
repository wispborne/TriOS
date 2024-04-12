import 'package:desktop_drop/desktop_drop.dart';
import 'package:trios/utils/logging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/chipper/chipper_state.dart';
import 'package:trios/mod_manager/mod_manager_logic.dart';
import 'package:trios/utils/extensions.dart';

import '../chipper/utils.dart';
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

  @override
  Widget build(BuildContext context) {
    return DropTarget(
      onDragDone: (detail) async {
        Fimber.i('onDragDone:');

        var file = detail.files.first;
        final filePath = file.path;

        if (filePath
            .toFile()
            .extension
            .equalsAnyIgnoreCase(Constants.supportedArchiveExtensions)) {
          {
            setState(() {
              _inProgress = true;
            });
            try {
              installModFromArchiveWithDefaultUI(
                  filePath.toFile(), ref, context);
            } finally {
              setState(() {
                _inProgress = false;
              });
            }
          }
        } else {
          handleDroppedLogFile(filePath).then((content) {
            if (content == null) {
              return; // TODO ref.read(ChipperState.logRawContents).valueOrNull;
            }
            return ref
                .read(ChipperState.logRawContents.notifier)
                .parseLog(LogFile(file.path, content));
          });
          widget.onDroppedLog?.call(filePath);
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
