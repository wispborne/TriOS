import 'package:flutter/material.dart';
import 'package:trios/widgets/moving_tooltip.dart';

class SpinningRefreshButton extends StatefulWidget {
  final VoidCallback onPressed;
  final bool isScanning;
  final String? tooltip;

  const SpinningRefreshButton({
    super.key,
    required this.onPressed,
    required this.isScanning,
    this.tooltip,
  });

  @override
  SpinningRefreshButtonState createState() => SpinningRefreshButtonState();
}

class SpinningRefreshButtonState extends State<SpinningRefreshButton>
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
  void didUpdateWidget(SpinningRefreshButton oldWidget) {
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
    return MovingTooltipWidget.text(
      message: widget.tooltip,
      child: InkWell(
        onTap: widget.onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
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
        ),
      ),
    );
  }
}
