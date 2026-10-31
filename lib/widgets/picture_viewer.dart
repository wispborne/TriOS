import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/widgets/moving_tooltip.dart';
import 'package:trios/widgets/rainbow/themed_progress_indicator.dart';

/// One picture for [showPictureViewer].
class ViewerPicture {
  final String url;

  /// The picture's own caption or alt text.
  final String? caption;

  /// An AI-written description. Only shown while AI features are on.
  final String? aiCaption;

  const ViewerPicture({required this.url, this.caption, this.aiCaption});
}

/// Opens [pictures] full screen, starting at [startIndex].
///
/// The viewer is its own route above whatever opened it, so its arrow keys
/// never reach a dialog behind it.
///
/// - The mouse wheel zooms and dragging pans.
/// - Left and right arrows move between pictures.
/// - `+` and `-` zoom, `0` resets the zoom, and Escape closes the viewer.
Future<void> showPictureViewer(
  BuildContext context, {
  required List<ViewerPicture> pictures,
  int startIndex = 0,
}) {
  if (pictures.isEmpty) return Future.value();
  return showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.9),
    pageBuilder: (context, _, _) =>
        PictureViewer(pictures: pictures, startIndex: startIndex),
  );
}

/// The full-screen picture viewer. Open it with [showPictureViewer].
class PictureViewer extends ConsumerStatefulWidget {
  final List<ViewerPicture> pictures;
  final int startIndex;

  const PictureViewer({super.key, required this.pictures, this.startIndex = 0});

  @override
  ConsumerState<PictureViewer> createState() => _PictureViewerState();
}

class _PictureViewerState extends ConsumerState<PictureViewer> {
  static const _minScale = 0.5;
  static const _maxScale = 8.0;
  static const _zoomStep = 1.25;

  late int _index = widget.startIndex.clamp(0, widget.pictures.length - 1);
  final _transform = TransformationController();
  Size _viewportSize = Size.zero;

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  void _step(int delta) {
    final next = _index + delta;
    if (next < 0 || next >= widget.pictures.length) return;
    setState(() {
      _index = next;
      _transform.value = Matrix4.identity();
    });
  }

  /// Zooms by [factor] around the middle of the screen.
  void _zoomBy(double factor) {
    final current = _transform.value.getMaxScaleOnAxis();
    final target = (current * factor).clamp(_minScale, _maxScale);
    final change = target / current;
    final cx = _viewportSize.width / 2;
    final cy = _viewportSize.height / 2;
    _transform.value =
        Matrix4.translationValues(cx, cy, 0) *
        Matrix4.diagonal3Values(change, change, 1) *
        Matrix4.translationValues(-cx, -cy, 0) *
        _transform.value;
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowLeft) {
      _step(-1);
    } else if (key == LogicalKeyboardKey.arrowRight) {
      _step(1);
    } else if (key == LogicalKeyboardKey.equal ||
        key == LogicalKeyboardKey.add ||
        key == LogicalKeyboardKey.numpadAdd) {
      _zoomBy(_zoomStep);
    } else if (key == LogicalKeyboardKey.minus ||
        key == LogicalKeyboardKey.numpadSubtract) {
      _zoomBy(1 / _zoomStep);
    } else if (key == LogicalKeyboardKey.digit0 ||
        key == LogicalKeyboardKey.numpad0) {
      _transform.value = Matrix4.identity();
    } else if (key == LogicalKeyboardKey.escape) {
      Navigator.of(context).pop();
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final picture = widget.pictures[_index];
    final showAi = ref.watch(appSettings.select((s) => s.enableAiFeatures));
    final caption = picture.caption?.trim();
    final aiCaption = showAi ? picture.aiCaption?.trim() : null;
    final count = widget.pictures.length;
    const iconColor = Colors.white;
    final textStyle = theme.textTheme.bodyMedium?.copyWith(color: Colors.white);
    final mutedStyle = theme.textTheme.labelMedium?.copyWith(
      color: Colors.white70,
    );

    return Focus(
      autofocus: true,
      onKeyEvent: _onKeyEvent,
      child: Material(
        color: Colors.transparent,
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        _viewportSize = constraints.biggest;
                        return InteractiveViewer(
                          key: ValueKey(_index),
                          transformationController: _transform,
                          minScale: _minScale,
                          maxScale: _maxScale,
                          child: Center(child: _PictureImage(url: picture.url)),
                        );
                      },
                    ),
                  ),
                  if (count > 1) ...[
                    Positioned(
                      left: 8,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: MovingTooltipWidget.text(
                          message: 'Previous (Left arrow)',
                          child: IconButton(
                            iconSize: 40,
                            color: iconColor,
                            icon: const Icon(Icons.chevron_left),
                            onPressed: _index > 0 ? () => _step(-1) : null,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 8,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: MovingTooltipWidget.text(
                          message: 'Next (Right arrow)',
                          child: IconButton(
                            iconSize: 40,
                            color: iconColor,
                            icon: const Icon(Icons.chevron_right),
                            onPressed: _index < count - 1
                                ? () => _step(1)
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ],
                  Positioned(
                    top: 8,
                    right: 8,
                    child: MovingTooltipWidget.text(
                      message: 'Close (Escape)',
                      child: IconButton(
                        color: iconColor,
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const .all(16),
              child: Column(
                mainAxisSize: .min,
                spacing: 8,
                children: [
                  if (caption != null && caption.isNotEmpty)
                    Text(caption, style: textStyle, textAlign: .center),
                  if (aiCaption != null && aiCaption.isNotEmpty)
                    Text(
                      'AI description: $aiCaption',
                      style: mutedStyle?.copyWith(fontStyle: .italic),
                      textAlign: .center,
                    ),
                  Row(
                    mainAxisAlignment: .center,
                    spacing: 16,
                    children: [
                      if (count > 1)
                        Text('${_index + 1} of $count', style: mutedStyle),
                      MovingTooltipWidget.text(
                        message: picture.url,
                        child: TextButton.icon(
                          onPressed: () => picture.url.openAsUriInBrowser(),
                          icon: const Icon(Icons.open_in_new, size: 16),
                          label: const Text('Open original'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PictureImage extends StatelessWidget {
  final String url;

  const _PictureImage({required this.url});

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => const Icon(
        Icons.broken_image_outlined,
        size: 64,
        color: Colors.white54,
      ),
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return const SizedBox(
          width: 32,
          height: 32,
          child: ThemedCircularProgressIndicator(strokeWidth: 3),
        );
      },
    );
  }
}
