import 'package:flutter/material.dart';
import 'package:trios/themes/theme.dart';
import 'package:trios/trios/constants_theme.dart';

enum SnackBarType { info, warn, error }

void showSnackBar({
  required BuildContext context,
  required Widget content,
  bool? clearPreviousSnackBars = true,
  SnackBarType? type,
  Color? backgroundColor,
  double? elevation,
  EdgeInsetsGeometry? margin,
  EdgeInsetsGeometry? padding,
  double? width,
  ShapeBorder? shape,
  HitTestBehavior? hitTestBehavior,
  SnackBarBehavior? behavior,
  SnackBarAction? action,
  double? actionOverflowThreshold,
  bool? showCloseIcon,
  Color? closeIconColor,
  Duration duration = const Duration(milliseconds: 4000),
  Animation<double>? animation,
  void Function()? onVisible,
  DismissDirection? dismissDirection,
  Clip clipBehavior = Clip.hardEdge,
}) {
  if (clearPreviousSnackBars == true) {
    ScaffoldMessenger.of(context).clearSnackBars();
  }

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: type != null
          ? DefaultTextStyle.merge(
              child: content,
              style: TextStyle(
                color:
                    switch (type) {
                      SnackBarType.info => Theme.of(
                        context,
                      ).extension<TriOSThemeExtension>()?.onInfo,
                      SnackBarType.warn => Theme.of(
                        context,
                      ).extension<TriOSThemeExtension>()?.onWarning,
                      SnackBarType.error => Colors.white,
                    } ??
                    Colors.white,
                fontWeight: FontWeight.bold,
              ),
            )
          : content,
      backgroundColor: switch (type) {
        SnackBarType.info =>
          Theme.of(context).extension<TriOSThemeExtension>()?.info ??
              Colors.blue,
        SnackBarType.warn =>
          Theme.of(context).extension<TriOSThemeExtension>()?.warning ??
              TriOSThemeConstants.vanillaWarningColor,
        SnackBarType.error => TriOSThemeConstants.vanillaErrorColor,
        null => Theme.of(context).snackBarTheme.backgroundColor,
      },
      elevation: elevation,
      margin: margin,
      padding: padding,
      width: width,
      shape: shape,
      hitTestBehavior: hitTestBehavior,
      behavior: behavior,
      action: action,
      actionOverflowThreshold: actionOverflowThreshold,
      showCloseIcon: showCloseIcon,
      closeIconColor: closeIconColor,
      duration: duration,
      animation: animation,
      onVisible: onVisible,
      dismissDirection: dismissDirection,
      clipBehavior: clipBehavior,
    ),
  );
}
