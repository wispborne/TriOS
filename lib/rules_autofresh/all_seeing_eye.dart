import 'package:flutter/material.dart';

class FadingEye extends StatefulWidget {
  final double size;
  final bool shouldAnimate;
  final int durationMillis;
  final Color color;

  const FadingEye({
    super.key,
    this.size = 24,
    this.shouldAnimate = true,
    this.durationMillis = 1200,
    required this.color,
  });

  @override
  FadingEyeState createState() => FadingEyeState();
}

class FadingEyeState extends State<FadingEye>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    if (widget.shouldAnimate) {
      _initAnimation();
    }
  }

  @override
  void didUpdateWidget(FadingEye oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shouldAnimate && _controller == null) {
      _initAnimation();
    } else if (!widget.shouldAnimate && _controller != null) {
      _disposeAnimation();
    }
  }

  void _initAnimation() {
    _controller = AnimationController(
      duration: Duration(milliseconds: widget.durationMillis),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween(begin: 1.0, end: 0.2).animate(_controller!);
  }

  void _disposeAnimation() {
    _controller?.dispose();
    _controller = null;
  }

  @override
  void dispose() {
    _disposeAnimation();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.shouldAnimate && _controller != null
        ? FadeTransition(
            opacity: _animation,
            child: Icon(
              Icons.visibility,
              size: widget.size,
              color: widget.color,
            ),
          )
        : Icon(
            Icons.visibility,
            size: widget.size,
            // set color to null if we're doing animations
            color: widget.color,
          );
  }
}
