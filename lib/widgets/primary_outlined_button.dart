import 'package:material_ui/material_ui.dart';
import 'package:trios/themes/theme.dart';

/// An outlined button whose outline uses the theme's primary color.
///
/// Use it for the button that starts the main action on a page, or that fixes
/// a problem the user is being shown. A plain [OutlinedButton] has a soft gray
/// outline and is the right choice everywhere else.
class PrimaryOutlinedButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final Widget? icon;

  /// Extra styling, e.g. padding or a different shape. Anything it sets wins
  /// over the primary outline.
  final ButtonStyle? style;

  const PrimaryOutlinedButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.style,
  }) : icon = null;

  const PrimaryOutlinedButton.icon({
    super.key,
    required this.onPressed,
    required this.icon,
    required Widget label,
    this.style,
  }) : child = label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final outlineColor =
        theme.extension<TriOSThemeExtension>()?.primaryOutline ??
        theme.colorScheme.primary;
    final primaryStyle = OutlinedButton.styleFrom(
      side: BorderSide(color: outlineColor),
    );
    final buttonStyle = style?.merge(primaryStyle) ?? primaryStyle;

    return icon == null
        ? OutlinedButton(
            onPressed: onPressed,
            style: buttonStyle,
            child: child,
          )
        : OutlinedButton.icon(
            onPressed: onPressed,
            style: buttonStyle,
            icon: icon,
            label: child,
          );
  }
}
