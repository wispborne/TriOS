import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/mod_manager/mod_install_source.dart';
import 'package:trios/mod_manager/mod_manager_logic.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/widgets/disable.dart';
import 'package:trios/widgets/disable_if_cannot_write_mods.dart';
import 'package:trios/widgets/moving_tooltip.dart';

class AddNewModsButton extends ConsumerWidget {
  final double iconSize;
  final Widget? labelWidget;
  final EdgeInsetsGeometry padding;

  const AddNewModsButton({
    super.key,
    this.iconSize = 20,
    this.padding = const EdgeInsets.all(4),
    this.labelWidget,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isGameRunning = ref.watch(AppState.isGameRunning).value == true;

    var isIconOnly = labelWidget != null;
    return MovingTooltipWidget.text(
      message: isGameRunning
          ? "Game is running"
          : isIconOnly
              ? "Tip: drag'n'drop to install mods!"
              : "Add new mod(s)\n\nTip: drag'n'drop to install mods!",
      child: Disable(
        isEnabled: !isGameRunning,
        child: DisableIfCannotWriteMods(
          child: isIconOnly
              ? Padding(
                  padding: padding,
                  child: OutlinedButton.icon(
                    onPressed: () => _pickAndInstallMods(ref),
                    label: labelWidget!,
                    icon: Icon(
                      Icons.add,
                      size: iconSize,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                )
              : IconButton(
                  onPressed: () => _pickAndInstallMods(ref),
                  constraints: const BoxConstraints(),
                  iconSize: iconSize,
                  padding: padding,
                  icon: Icon(
                    Icons.add,
                    size: iconSize,
                  ),
                ),
        ),
      ),
    );
  }

  void _pickAndInstallMods(WidgetRef ref) {
    FilePicker.platform.pickFiles(allowMultiple: true).then((value) async {
      if (value == null) return;

      for (final file in value.files) {
        if (Constants.modInfoFileNames.contains(file.name)) {
          await ref.read(modManager.notifier).installModFromSourceWithDefaultUI(
              DirectoryModInstallSource(
                  Directory(File(file.path!).parent.path)));
        } else {
          await ref.read(modManager.notifier).installModFromSourceWithDefaultUI(
              ArchiveModInstallSource(File(file.path!)));
        }
      }
    });
  }
}
