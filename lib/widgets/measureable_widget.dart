import 'dart:async';

import 'package:flutter/material.dart';

/// From https://blog.gskinner.com/archives/2021/01/flutter-how-to-measure-widgets.html
class MeasurableWidget extends StatefulWidget {
  final Widget child;
  final void Function(Size size) onSized;
  final void Function(Size size) onResized;

  const MeasurableWidget({
    super.key,
    required this.child,
    required this.onSized,
    required this.onResized,
  });

  @override
  State createState() => _MeasurableWidgetState();
}

class _MeasurableWidgetState extends State<MeasurableWidget> {
  bool _hasMeasured = false;
  Size? _previousSize;

  @override
  Widget build(BuildContext context) {
    Size size = (context.findRenderObject() as RenderBox?)?.size ?? Size.zero;
    if (size != Size.zero) {
      widget.onSized.call(size);

      if (_previousSize != size) {
        _previousSize = size;
      }
    } else if (!_hasMeasured) {
      // Need to build twice in order to get size
      scheduleMicrotask(() => setState(() => _hasMeasured = true));
    }
    return widget.child;
  }
}
