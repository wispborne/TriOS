import 'dart:io';
import 'package:trios/trios/constants_theme.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/themes/theme_manager.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/platform_specific.dart';
import 'package:trios/widgets/moving_tooltip.dart';
import 'package:trios/widgets/svg_image_icon.dart';

import '../vmparams/vmparams_manager.dart';

/// Shows a warning when vmparams files are not writable.
class FilePermissionShield extends ConsumerStatefulWidget {
  const FilePermissionShield({super.key});

  @override
  ConsumerState<FilePermissionShield> createState() =>
      _FilePermissionShieldState();
}

class _FilePermissionShieldState extends ConsumerState<FilePermissionShield> {
  bool _areAllVmparamsWritable = true;
  List<String> _vmParamsFilesThatCannotBeWritten = [];
  bool _initialized = false;

  @override
  Widget build(BuildContext context) {
    ref.listen(vmparamsManagerProvider, (prev, next) async {
      final newState = next.value;
      if (newState != null && prev?.value != newState) {
        await _refreshWritability(newState.selectedVmparamsFiles);
      }
    });

    if (!_initialized) {
      return const SizedBox();
    }

    final paths = [
      for (final filePath in _vmParamsFilesThatCannotBeWritten)
        (description: 'vmparams file', isWritable: false, path: filePath),
    ];

    if (_areAllVmparamsWritable) {
      return const SizedBox();
    }

    final isAlreadyAdmin = windowsIsAdmin();

    return MovingTooltipWidget.framed(
      tooltipWidget: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: isAlreadyAdmin
                  ? "Unable to find or modify file(s)."
                  : "Right-click TriOS.exe and select 'Run as Administrator'.",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(
              text: isAlreadyAdmin
                  ? "\nEnsure that they exist and are not read-only.\n"
                  : "\nTriOS may not be able to modify game files, otherwise.\n",
            ),
            TextSpan(
              text:
                  "\n${paths.joinToString(separator: "\n", transform: (path) => "❌ Unable to edit ${path.description}."
                      "\n    (${path.path ?? 'unknown path'}).")}",
            ),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SvgImageIcon(
            "assets/images/icon-admin-shield.svg",
            color: TriOSThemeConstants.vanillaWarningColor,
          ),
          Text(
            isAlreadyAdmin ? "Warning" : "Must Run as Admin",
            style: TextStyle(
              color: TriOSThemeConstants.vanillaWarningColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshWritability(List<File> selectedFiles) async {
    _vmParamsFilesThatCannotBeWritten = [];
    _areAllVmparamsWritable = true;
    for (final file in selectedFiles) {
      if (file.existsSync() && await file.isNotWritable()) {
        _areAllVmparamsWritable = false;
        _vmParamsFilesThatCannotBeWritten.add(file.path);
      }
    }
    setState(() {
      _initialized = true;
    });
  }
}

/// Shows a warning when the app is running as Windows administrator.
class AdminPermissionShield extends StatelessWidget {
  const AdminPermissionShield({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Platform.isWindows || !windowsIsAdmin()) {
      return const SizedBox();
    }

    return MovingTooltipWidget.text(
      message:
          "Running as Administrator.\nDrag'n'drop will not work due to Windows security limits.",
      child: SvgImageIcon(
        "assets/images/icon-admin-shield-half.svg",
        color: Theme.of(context).iconTheme.color,
      ),
    );
  }
}

/// Donate dialog content.
class DonateView extends StatelessWidget {
  const DonateView({super.key});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 650),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SelectableText(
            "TriOS, like SMOL before it, is a hobby that I do because I enjoy it, and because I enjoy giving to Starsector."
            "\nThey're the result of many hundreds of hours of coding, and I hope they have been useful (and even enjoyable) for you."
            "\n"
            "\nIf you feel like donating, thank you. If you can't donate but wish you were rich enough to just give money away, thank you anyway :)"
            "\nTake care of yourself,"
            "\n- Wisp",
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontSize: 16),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 300,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 4,
              children: [
                ListTile(
                  title: const Text("Ko-Fi"),
                  leading: Icon(Icons.coffee, size: 20),
                  tileColor: Theme.of(context).colorScheme.surfaceContainer,
                  onTap: () {
                    Constants.kofiUrl.openAsUriInBrowser();
                    Navigator.of(context).pop();
                  },
                ),
                ListTile(
                  title: const Text("Patreon"),
                  leading: SvgImageIcon(
                    "assets/images/icon-patreon.svg",
                    height: 20,
                  ),
                  tileColor: Theme.of(context).colorScheme.surfaceContainer,
                  onTap: () {
                    Constants.patreonUrl.openAsUriInBrowser();
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
