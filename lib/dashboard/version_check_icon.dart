import 'package:flutter/material.dart';
import 'package:trios/models/version_checker_info.dart';
import 'package:trios/themes/theme_manager.dart';
import 'package:trios/widgets/blur.dart';
import 'package:trios/widgets/conditional_wrap.dart';
import 'package:trios/widgets/svg_image_icon.dart';

import '../mod_manager/version_checker.dart';

class VersionCheckIcon extends StatelessWidget {
  const VersionCheckIcon({
    super.key,
    required this.localVersionCheck,
    required this.remoteVersionCheck,
    required this.versionCheckComparison,
    required this.theme,
  });

  final VersionCheckerInfo? localVersionCheck;
  final VersionCheckResult? remoteVersionCheck;
  final int? versionCheckComparison;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    const updateIconSize = 20.0;
    var hasDirectDownload = remoteVersionCheck?.remoteVersion?.directDownloadURL != null;
    final iconColor = switch (versionCheckComparison) {
      -1 => theme.colorScheme.secondary,
      _ => theme.disabledColor.withOpacity(0.5),
    };

    return Row(children: [
      if (localVersionCheck?.modVersion != null && remoteVersionCheck?.remoteVersion?.modVersion != null)
        Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ConditionalWrap(
                condition: versionCheckComparison == -1,
                wrapper: (child) => Blur(blurX: 0, blurY: 0, blurOpacity: 0.7, child: child),
                child: Builder(builder: (context) {
                  if (versionCheckComparison == -1 && hasDirectDownload) {
                    return Icon(Icons.download, size: updateIconSize, color: iconColor);
                  } else if (versionCheckComparison == -1 && !hasDirectDownload) {
                    return SvgImageIcon("assets/images/icon-update-badge.svg",
                        width: updateIconSize, height: updateIconSize, color: iconColor);
                  } else {
                    return Icon(Icons.check, size: updateIconSize, color: iconColor);
                  }
                }))),
      if (localVersionCheck?.modVersion != null && remoteVersionCheck?.error != null)
        Padding(
          padding: const EdgeInsets.only(right: 6),
          child:
              Icon(Icons.error_outline, size: updateIconSize, color: vanillaWarningColor.withOpacity(0.5)),
        ),
      if (localVersionCheck?.modVersion == null)
        Padding(
            padding: const EdgeInsets.only(right: 6),
            child: SizedBox(
              width: updateIconSize,
              child: Center(
                child: ColorFiltered(
                    colorFilter: greyscale,
                    child: SvgImageIcon("assets/images/icon-help.svg",
                        width: updateIconSize, height: updateIconSize, color: theme.disabledColor.withOpacity(0.35))),
              ),
            )),
      if (localVersionCheck != null && remoteVersionCheck == null)
        Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ColorFiltered(
              colorFilter: greyscale,
              child:
                  Text("…", style: theme.textTheme.labelLarge?.copyWith(color: theme.disabledColor.withOpacity(0.35))),
            )),
    ]);
  }
}
