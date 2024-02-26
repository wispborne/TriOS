import 'package:flutter/material.dart';

/// Thanks Gemini
class FadingEye extends StatefulWidget {
  final double size;
  final bool shouldAnimate;
  final int durationMillis;

  const FadingEye({super.key, this.size = 24, this.shouldAnimate = true, this.durationMillis = 1200});

  @override
  FadingEyeState createState() => FadingEyeState();
}

class FadingEyeState extends State<FadingEye> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: widget.durationMillis),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween(begin: 1.0, end: 0.2).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: widget.shouldAnimate ? _animation : const AlwaysStoppedAnimation(1),
      child: Icon(Icons.visibility, size: widget.size, color: widget.shouldAnimate ? Theme.of(context).colorScheme.primary : null),
    );
  }
}
