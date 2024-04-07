import 'package:desktop_drop/desktop_drop.dart';
import 'package:fimber/fimber.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/chipper/chipper_state.dart';

import 'chipper_home.dart';

class ChipperDropper extends ConsumerStatefulWidget {
  final Widget child;
  final void Function(String)? onDropped;

  const ChipperDropper({super.key, required this.child, this.onDropped});

  @override
  ConsumerState createState() => _ChipperDropperState();
}

class _ChipperDropperState extends ConsumerState<ChipperDropper> {
  bool _dragging = false;
  Offset? _offset;

  @override
  Widget build(BuildContext context) {
    return DropTarget(
      onDragDone: (detail) {
        Fimber.i('onDragDone:');

        var file = detail.files.first;
        final filePath = file.path;
        handleDroppedFile(filePath).then((content) {
          if (content == null) return;// TODO ref.read(ChipperState.logRawContents).valueOrNull;
          return ref.read(ChipperState.logRawContents.notifier).parseLog(LogFile(file.path, content));
        });
        widget.onDropped?.call(filePath);
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
      child: Container(
        color: _dragging ? Colors.blue.withOpacity(0.4) : Colors.transparent,
        child: widget.child,
      ),
    );
  }
}
