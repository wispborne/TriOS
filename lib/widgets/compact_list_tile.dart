import 'package:flutter/material.dart';

class CompactListTile extends StatelessWidget {
  final Widget? leading;
  final Widget? title;
  final Widget? subtitle;
  final Widget? trailing;
  final GestureTapCallback? onTap;

  const CompactListTile({
    super.key,
    this.leading,
    this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    // Smaller text sizes for compact layout
    final TextStyle titleStyle = theme.textTheme.bodyMedium!.copyWith(
      fontSize: 13, // Smaller title font size
    );
    final TextStyle? subtitleStyle = theme.textTheme.bodyMedium?.copyWith(
      fontSize: 11, // Smaller subtitle font size
    );

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 2.0,
          horizontal: 8.0,
        ), // Very minimal padding
        child: Row(
          children: [
            if (leading != null)
              Padding(
                padding: const EdgeInsets.only(
                  right: 6.0,
                ), // Tighter space between leading and title
                child: SizedBox(
                  width: 28, // Smaller leading icon size
                  height: 28, // Smaller leading icon size
                  child: leading,
                ),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DefaultTextStyle(
                    style: titleStyle,
                    child: title ?? const SizedBox.shrink(),
                  ),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(
                        top: 1.0,
                      ), // Minimal spacing between title and subtitle
                      child: DefaultTextStyle(
                        style: subtitleStyle!,
                        child: subtitle!,
                      ),
                    ),
                ],
              ),
            ),
            if (trailing != null)
              Padding(
                padding: const EdgeInsets.only(
                  left: 6.0,
                ), // Tighter space between title and trailing
                child: SizedBox(
                  width: 28, // Smaller trailing icon size
                  height: 28, // Smaller trailing icon size
                  child: trailing,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
