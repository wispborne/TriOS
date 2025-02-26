import 'package:flutter/material.dart';

class TabButton extends StatelessWidget {
  final String text;
  final bool isSelected;
  final VoidCallback onPressed;
  final Widget icon;
  final double iconSize;
  final double iconSpacing;

  const TabButton({
    super.key,
    required this.text,
    required this.isSelected,
    required this.onPressed,
    required this.icon,
    this.iconSize = 24,
    this.iconSpacing = 2,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final foregroundColor =
        isSelected ? colors.primary : colors.onSurface.withOpacity(0.8);

    return Padding(
      padding: const EdgeInsets.all(0),
      child: TextButton(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          backgroundColor: isSelected ? Colors.transparent : Colors.transparent,
          foregroundColor: foregroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(0.0),
          ),
        ),
        onPressed: onPressed,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconTheme(
              data: IconThemeData(color: foregroundColor),
              child: SizedBox(height: iconSize, child: icon),
            ),
            SizedBox(height: iconSpacing),
            Text(
              text,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
