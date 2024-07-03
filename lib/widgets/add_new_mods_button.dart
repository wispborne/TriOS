import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/mod_manager/mod_manager_logic.dart';
import 'package:trios/widgets/disable_if_cannot_write_mods.dart';

class AddNewModsButton extends ConsumerWidget {
  final double iconSize;

  const AddNewModsButton({
    super.key,
    this.iconSize = 20,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Tooltip(
      message: "Add new mod(s)\nTip: drag'n'drop to install mods!",
      textAlign: TextAlign.center,
      child: DisableIfCannotWriteMods(
        child: IconButton(
            icon: const Icon(Icons.add),
            iconSize: iconSize,
            constraints: const BoxConstraints(),
            onPressed: () {
              FilePicker.platform.pickFiles(allowMultiple: true).then((value) {
                if (value == null) return;

                final file = File(value.files.single.path!);
                installModFromArchiveWithDefaultUI(file, ref, context);
              });
            }),
      ),
    );
  }
}
