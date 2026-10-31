import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:trios/widgets/moving_tooltip.dart';

/// A screenshot taken for a bug report, before any boxes or drawings are added.
class BugReportScreenshot {
  final Uint8List bytes;
  final int width;
  final int height;

  const BugReportScreenshot(this.bytes, this.width, this.height);

  static Future<BugReportScreenshot> fromBytes(Uint8List bytes) async {
    final image = await decodeImageFromList(bytes);
    final screenshot = BugReportScreenshot(bytes, image.width, image.height);
    image.dispose();
    return screenshot;
  }
}

/// Something the user added on top of the screenshot.
/// Positions are in screenshot pixels, so they don't depend on how big the
/// screenshot is shown.
sealed class ScreenshotMark {
  const ScreenshotMark();
}

/// A solid black box that hides part of the screenshot.
class HideBox extends ScreenshotMark {
  final Rect rect;

  const HideBox(this.rect);
}

/// A freehand red line.
class DrawStroke extends ScreenshotMark {
  final List<Offset> points;

  const DrawStroke(this.points);
}

const _strokeColor = Color(0xFFFF2020);
const _strokeWidth = 6.0;

/// Paints [marks] onto [canvas]. [scale] is shown size / screenshot size.
void _paintMarks(Canvas canvas, Iterable<ScreenshotMark> marks, double scale) {
  final hidePaint = Paint()..color = const Color(0xFF000000);
  final strokePaint = Paint()
    ..color = _strokeColor
    ..style = PaintingStyle.stroke
    ..strokeWidth = _strokeWidth * scale
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  for (final mark in marks) {
    switch (mark) {
      case HideBox(:final rect):
        canvas.drawRect(
          Rect.fromLTRB(
            rect.left * scale,
            rect.top * scale,
            rect.right * scale,
            rect.bottom * scale,
          ),
          hidePaint,
        );
      case DrawStroke(:final points):
        if (points.isEmpty) continue;
        final path = Path()
          ..moveTo(points.first.dx * scale, points.first.dy * scale);
        for (final point in points.skip(1)) {
          path.lineTo(point.dx * scale, point.dy * scale);
        }
        canvas.drawPath(path, strokePaint);
    }
  }
}

class _MarksPainter extends CustomPainter {
  final List<ScreenshotMark> marks;
  final double scale;

  _MarksPainter(this.marks, this.scale);

  @override
  void paint(Canvas canvas, Size size) => _paintMarks(canvas, marks, scale);

  // The editor changes the mark list in place, so always repaint.
  @override
  bool shouldRepaint(_MarksPainter oldDelegate) => true;
}

/// Returns the screenshot as a PNG with [marks] drawn into it.
/// The hidden areas are painted over, so they can't be recovered from the file.
Future<Uint8List> flattenScreenshot(
  BugReportScreenshot screenshot,
  List<ScreenshotMark> marks,
) async {
  if (marks.isEmpty) return screenshot.bytes;

  final image = await decodeImageFromList(screenshot.bytes);
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawImage(image, Offset.zero, Paint());
  _paintMarks(canvas, marks, 1);
  final picture = recorder.endRecording();
  final result = await picture.toImage(image.width, image.height);
  final data = await result.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  picture.dispose();
  result.dispose();
  return data!.buffer.asUint8List();
}

/// Shows the screenshot with its marks, scaled down to fit the space given.
class ScreenshotWithMarks extends StatelessWidget {
  final BugReportScreenshot screenshot;
  final List<ScreenshotMark> marks;

  /// Builds a layer on top of the screenshot, given the scale it's shown at.
  final Widget Function(double scale)? overlayBuilder;

  const ScreenshotWithMarks({
    super.key,
    required this.screenshot,
    required this.marks,
    this.overlayBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = screenshot.width.toDouble();
        final height = screenshot.height.toDouble();
        var scale = 1.0;
        if (constraints.hasBoundedWidth) {
          scale = constraints.maxWidth / width;
        }
        if (constraints.hasBoundedHeight) {
          scale = scale.clamp(0, constraints.maxHeight / height);
        }
        if (scale > 1) scale = 1;

        return SizedBox(
          width: width * scale,
          height: height * scale,
          child: Stack(
            fit: .expand,
            children: [
              Image.memory(screenshot.bytes, fit: .fill),
              CustomPaint(painter: _MarksPainter(marks, scale)),
              if (overlayBuilder != null) overlayBuilder!(scale),
            ],
          ),
        );
      },
    );
  }
}

enum _EditorTool { hide, draw }

/// Opens the screenshot editor. Returns the new list of marks, or null if the
/// user cancelled.
Future<List<ScreenshotMark>?> showScreenshotEditor(
  BuildContext context, {
  required BugReportScreenshot screenshot,
  required List<ScreenshotMark> marks,
}) {
  return showDialog<List<ScreenshotMark>>(
    context: context,
    barrierDismissible: false,
    builder: (context) =>
        _ScreenshotEditorDialog(screenshot: screenshot, marks: marks),
  );
}

class _ScreenshotEditorDialog extends StatefulWidget {
  final BugReportScreenshot screenshot;
  final List<ScreenshotMark> marks;

  const _ScreenshotEditorDialog({
    required this.screenshot,
    required this.marks,
  });

  @override
  State<_ScreenshotEditorDialog> createState() =>
      _ScreenshotEditorDialogState();
}

class _ScreenshotEditorDialogState extends State<_ScreenshotEditorDialog> {
  late final List<ScreenshotMark> _marks = [...widget.marks];
  var _tool = _EditorTool.hide;

  /// Where the current drag started, in screenshot pixels. Only used for boxes.
  Offset? _dragStart;

  Offset _toScreenshot(Offset local, double scale) => Offset(
    (local.dx / scale).clamp(0, widget.screenshot.width.toDouble()),
    (local.dy / scale).clamp(0, widget.screenshot.height.toDouble()),
  );

  void _onPanStart(Offset local, double scale) {
    final point = _toScreenshot(local, scale);
    setState(() {
      switch (_tool) {
        case _EditorTool.hide:
          _dragStart = point;
          _marks.add(HideBox(Rect.fromPoints(point, point)));
        case _EditorTool.draw:
          _marks.add(DrawStroke([point]));
      }
    });
  }

  void _onPanUpdate(Offset local, double scale) {
    final point = _toScreenshot(local, scale);
    final current = _marks.lastOrNull;
    setState(() {
      switch (current) {
        case HideBox():
          final start = _dragStart;
          if (start != null) {
            _marks[_marks.length - 1] = HideBox(Rect.fromPoints(start, point));
          }
        case DrawStroke(:final points):
          points.add(point);
        case null:
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      insetPadding: const .all(32),
      child: Padding(
        padding: const .all(16),
        child: Column(
          crossAxisAlignment: .start,
          spacing: 16,
          children: [
            Text("Edit Screenshot", style: theme.textTheme.titleLarge),
            Row(
              spacing: 8,
              children: [
                SegmentedButton<_EditorTool>(
                  segments: [
                    ButtonSegment(
                      value: _EditorTool.hide,
                      icon: const Icon(Icons.rectangle),
                      label: MovingTooltipWidget.text(
                        message:
                            "Drag to cover part of the screenshot with a black box.",
                        child: const Text("Hide"),
                      ),
                    ),
                    ButtonSegment(
                      value: _EditorTool.draw,
                      icon: const Icon(Icons.brush),
                      label: MovingTooltipWidget.text(
                        message: "Draw to show the bug or issue.",
                        child: const Text("Draw"),
                      ),
                    ),
                  ],
                  selected: {_tool},
                  onSelectionChanged: (selected) =>
                      setState(() => _tool = selected.first),
                ),
                MovingTooltipWidget.text(
                  message: "Undo",
                  child: TextButton.icon(
                    icon: const Icon(Icons.undo),
                    label: const Text("Undo"),
                    onPressed: _marks.isEmpty
                        ? null
                        : () => setState(() => _marks.removeLast()),
                  ),
                ),
                MovingTooltipWidget.text(
                  message: "Remove all boxes and drawings.",
                  child: TextButton.icon(
                    icon: const Icon(Icons.delete_sweep),
                    label: const Text("Clear"),
                    onPressed: _marks.isEmpty
                        ? null
                        : () => setState(() => _marks.clear()),
                  ),
                ),
              ],
            ),
            Expanded(
              child: Center(
                child: ScreenshotWithMarks(
                  screenshot: widget.screenshot,
                  marks: _marks,
                  overlayBuilder: (scale) => MouseRegion(
                    cursor: SystemMouseCursors.precise,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onPanStart: (details) =>
                          _onPanStart(details.localPosition, scale),
                      onPanUpdate: (details) =>
                          _onPanUpdate(details.localPosition, scale),
                      onPanEnd: (_) => _dragStart = null,
                    ),
                  ),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: .end,
              spacing: 8,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(_marks),
                  child: const Text("Done"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
