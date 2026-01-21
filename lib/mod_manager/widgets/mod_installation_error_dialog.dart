import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:trios/mod_manager/mod_manager_logic.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/utils/dialogs.dart';

/// Dialog for displaying mod installation errors.
///
/// Shows a list of failed mod installations with:
/// - Error message for each failed mod
/// - Buttons to open the mod file location
/// - Button to open the Starsector mods folder
/// - Instructions to check logs for more details
class ModInstallationErrorDialog extends StatelessWidget {
  final List<InstallModResult> errors;

  const ModInstallationErrorDialog({
    super.key,
    required this.errors,
  });

  /// Shows the error dialog with a list of failed installations.
  static Future<void> show(
    BuildContext context,
    List<InstallModResult> errors,
  ) {
    return showAlertDialog(
      context,
      title: "Error",
      widget: ModInstallationErrorDialog(errors: errors),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: errors.length == 1
                    ? "There was an error while installing.\nPlease install the mod manually."
                    : "There were errors while installing.\nPlease install the mods manually.\n",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              TextSpan(
                text:
                    "Check the ${Constants.appName} logs for more information.\n\n",
              ),
            ],
          ),
        ),
        ...errors.map((failedMod) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline),
                  const SizedBox(width: 8),
                  Text(
                    "${failedMod.modInfo.name} ${failedMod.modInfo.version}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    OutlinedButton(
                      onPressed: () {
                        OpenFilex.open(
                          failedMod.sourceFileEntity.parent.path,
                        );
                      },
                      child: const Text("Show mod file"),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () {
                        OpenFilex.open(
                          failedMod.destinationFolder.path,
                        );
                      },
                      child: const Text("Open Starsector mods folder"),
                    ),
                  ],
                ),
              ),
              SelectableText(
                "${failedMod.err}\n",
                style: theme.textTheme.bodySmall,
              ),
            ],
          );
        }),
      ],
    );
  }
}
