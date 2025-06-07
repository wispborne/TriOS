import 'package:flutter/material.dart';

enum DenseButtonStyle { compact, extraCompact }

class DenseButton extends StatelessWidget {
  final Widget child;
  final DenseButtonStyle density;

  const DenseButton({
    super.key,
    required this.child,
    this.density = DenseButtonStyle.compact,
  });

  @override
  Widget build(BuildContext context) {
    final EdgeInsetsGeometry padding = density == DenseButtonStyle.extraCompact
        ? const EdgeInsets.symmetric(horizontal: 6, vertical: 2)
        : const EdgeInsets.symmetric(horizontal: 10, vertical: 6);

    final Size minimumSize = density == DenseButtonStyle.extraCompact
        ? const Size(0, 24)
        : const Size(0, 30);

    return Theme(
      data: Theme.of(context).copyWith(
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            padding: padding,
            minimumSize: minimumSize,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            padding: padding,
            minimumSize: minimumSize,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: padding,
            minimumSize: minimumSize,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ),
      child: child,
    );
  }
}
