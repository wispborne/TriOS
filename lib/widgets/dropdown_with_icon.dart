import 'package:flutter/material.dart';

class AnimatedPopupMenuButton<T> extends StatefulWidget {
  final Widget icon;
  final List<PopupMenuItem<T>> menuItems;
  final ValueChanged<T> onSelected;
  final bool showArrow;
  final Color? arrowColor;
  final Duration animationDuration;

  const AnimatedPopupMenuButton({
    super.key,
    required this.icon, // Icon to display (e.g., toolbox icon)
    required this.menuItems, // List of menu items to display
    required this.onSelected, // Callback when a menu item is selected
    this.showArrow = true,
    this.arrowColor, // Arrow color
    this.animationDuration =
        const Duration(milliseconds: 200), // Arrow animation duration
  });

  @override
  State<AnimatedPopupMenuButton> createState() =>
      _AnimatedPopupMenuButtonState<T>();
}

class _AnimatedPopupMenuButtonState<T> extends State<AnimatedPopupMenuButton<T>>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _arrowAnimation;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );
    _arrowAnimation = Tween<double>(begin: 0.0, end: 0.5).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onMenuOpened(bool isOpened) {
    setState(() {
      _isOpen = isOpened;
      if (isOpened) {
        _controller.forward(); // Rotate the arrow when the menu opens
      } else {
        _controller.reverse(); // Rotate back when the menu closes
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(24),
            color: _isOpen
                ? Theme.of(context).colorScheme.surface
                : Colors.transparent,
          ),
          child: Theme(
            data: Theme.of(context).copyWith(
              splashFactory: NoSplash.splashFactory,
            ),
            child: PopupMenuButton<T>(
              icon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  widget.icon, // User-specified icon
                  if (widget.showArrow)
                    const SizedBox(width: 4), // Space between icon and arrow
                  if (widget.showArrow)
                    RotationTransition(
                      turns: _arrowAnimation,
                      // Apply rotation animation to arrow
                      child: Icon(
                        Icons.arrow_drop_down, // The arrow icon
                        color: widget.arrowColor ??
                            Theme.of(context).iconTheme.color, // Arrow color
                      ),
                    ),
                ],
              ),
              tooltip: "",
              offset: const Offset(0, 48),
              // Menu will appear below the button
              onSelected: (T value) {
                widget.onSelected(value);
                _onMenuOpened(false); // Close the menu and reset the arrow
              },
              // Rotate arrow back on cancel
              onCanceled: () => _onMenuOpened(false),
              // Rotate arrow when menu is opened
              onOpened: () => _onMenuOpened(true),
              itemBuilder: (BuildContext context) {
                return widget.menuItems; // Use the generic list of menu items
              },
            ),
          ),
        )
      ],
    );
  }
}
