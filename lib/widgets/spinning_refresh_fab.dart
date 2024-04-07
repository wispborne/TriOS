import 'package:flutter/material.dart';

class SpinningRefreshFAB extends StatefulWidget {
  final VoidCallback onPressed;
  final bool isScanning;
  final String? tooltip;

  const SpinningRefreshFAB({
    super.key,
    required this.onPressed,
    required this.isScanning,
    this.tooltip,
  });

  @override
  SpinningRefreshFABState createState() => SpinningRefreshFABState();
}

class SpinningRefreshFABState extends State<SpinningRefreshFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
  }

  @override
  void didUpdateWidget(SpinningRefreshFAB oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isScanning) {
      _animationController.repeat();
    } else {
      _animationController.stop();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: widget.onPressed,
      tooltip: widget.tooltip,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (_, child) {
          return Transform.rotate(
            angle: _animationController.value * 2.0 * 3.141592, // 2 * pi
            child: child,
          );
        },
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
