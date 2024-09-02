import 'package:flutter/material.dart';

/// A widget that lazily builds its children as they are needed.
///
/// The `LazyIndexedStack` widget is similar to an `IndexedStack`, but it only
/// builds the child widgets when they are first displayed. This can improve
/// performance by deferring the construction of widgets until they are needed.
class LazyIndexedStack extends StatefulWidget {
  /// The index of the child to display.
  final int index;

  /// The list of child widgets.
  final List<Widget> children;

  /// An optional `PageController` to control the page view.
  final PageController? controller;

  /// Creates a `LazyIndexedStack` widget.
  ///
  /// The [index] and [children] parameters are required.
  const LazyIndexedStack({
    super.key,
    required this.index,
    required this.children,
    this.controller,
  });

  @override
  State<LazyIndexedStack> createState() => _LazyIndexedStackState();
}

class _LazyIndexedStackState extends State<LazyIndexedStack> {
  /// The `PageController` used to control the page view.
  late PageController _pageController;

  /// A list of booleans indicating whether each child has been built.
  late List<bool> _isBuilt;

  @override
  void initState() {
    super.initState();
    _pageController =
        widget.controller ?? PageController(initialPage: widget.index);
    _isBuilt = List<bool>.filled(widget.children.length, false);
    _isBuilt[widget.index] = true;
  }

  @override
  void didUpdateWidget(LazyIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.index != oldWidget.index) {
      _pageController.jumpToPage(widget.index);
      if (!_isBuilt[widget.index]) {
        setState(() {
          _isBuilt[widget.index] = true;
        });
      }
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _pageController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _pageController,
      physics: const NeverScrollableScrollPhysics(),
      // Prevent swipe gesture navigation
      itemCount: widget.children.length,
      itemBuilder: (context, index) {
        if (_isBuilt[index]) {
          return widget.children[index];
        } else {
          return const SizedBox.shrink();
        }
      },
    );
  }
}
