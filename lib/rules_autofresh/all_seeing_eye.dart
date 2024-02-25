import 'package:flutter/material.dart';

/// Thanks Gemini
class FadingEye extends StatefulWidget {
  final double size;

  const FadingEye({super.key, this.size = 24});

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
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true); // Repeat the animation

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
      // Use FadeTransition for the fading effect
      opacity: _animation,
      child: Icon(Icons.visibility, size: widget.size),
    );
  }
}
