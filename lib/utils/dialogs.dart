import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:trios/about/about_page.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/thirdparty/dartx/iterable.dart';
import 'package:trios/thirdparty/faded_scrollable/faded_scrollable.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/utils/platform_specific.dart';
import 'package:trios/widgets/checkbox_with_label.dart';
import 'package:trios/widgets/trios_app_icon.dart';

import 'logging.dart';

Future<void> showMyDialog(
  BuildContext context, {
  Widget? title,
  List<Widget>? body,
}) async {
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: title,
        content: SingleChildScrollView(
          child: SelectionArea(child: ListBody(children: body ?? [])),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Close'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}

Future<void> showAlertDialog(
  BuildContext context, {
  String? title,
  String? content,
  Widget? widget,
  List<Widget>? actions,
}) async {
  assert(content != null || widget != null);
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: title != null ? Text(title) : null,
        content: SingleChildScrollView(
          child: SelectionArea(
            child: ListBody(
              children: [
                widget ??
                    Linkify(
                      text: content ?? "",
                      onOpen: (link) {
                        OpenFilex.open(link.url);
                      },
                    ),
              ],
            ),
          ),
        ),
        actions:
            actions ??
            <Widget>[
              TextButton(
                child: const Text('Close'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
      );
    },
  );
}

Future<void> showTriOSAboutDialog(BuildContext context) async {
  return showAboutDialog(
    context: context,
    applicationIcon: const TriOSAppIcon(),
    applicationName: Constants.appTitle,
    applicationVersion: "A Starsector toolkit\nby Wisp",
    children: [
      ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700),
        child: const AboutPage(),
      ),
    ],
  );
}

Future<void> showDeleteModFoldersConfirmationDialog(
  List<ModVariant> variantsToDelete,
  BuildContext context,
  WidgetRef ref, {
  bool? allowDeletingEnabledModsDefaultState = false,
  bool dryRun = false,
}) async {
  Future<void> deleteFolder(String folderPath) async {
    final directory = Directory(folderPath);
    final modsDir = ref.read(AppState.modsFolder).value!.path;

    if (p.equals(folderPath, modsDir)) {
      Fimber.e("Refusing to delete the mods root folder");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Did you just try to delete your mods folder? No! Bad!",
          ),
        ),
      );
      return;
    }

    if (await directory.exists() && !dryRun) {
      directory.moveToTrash(deleteIfFailed: true);
    }
    ref.read(AppState.modVariants.notifier).reloadModVariants();
  }

  if (variantsToDelete.isEmpty) {
    return;
  }

  runZonedGuarded(
    () async {
      bool allowDeletingEnabledMods =
          allowDeletingEnabledModsDefaultState ?? false;
      List<ModVariant> filteredVariantsToDelete = variantsToDelete;
      List<ModVariant> enabledVariantsThatWillNotBeDeleted = [];

      final shouldDelete = await showDialog<bool>(
        context: context,
        builder: (context) {
          final theme = Theme.of(context);

          return StatefulBuilder(
            builder: (context, setState) {
              final allMods = ref.read(AppState.mods);

              final isOnlyEnabledMods = variantsToDelete.all(
                (variant) => variant.isEnabled(allMods),
              );

              enabledVariantsThatWillNotBeDeleted =
                  (isOnlyEnabledMods || allowDeletingEnabledMods)
                  ? []
                  : variantsToDelete
                        .where((variant) => !variant.isEnabled(allMods))
                        .toList();

              filteredVariantsToDelete =
                  variantsToDelete - enabledVariantsThatWillNotBeDeleted;

              final enabledVariants = variantsToDelete
                  .where((variant) => variant.isEnabled(allMods))
                  .toList();

              final s = filteredVariantsToDelete.length == 1 ? "s" : "";

              return AlertDialog(
                title: Text('Delete Mod$s'),
                content: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 8,
                    children: [
                      if (filteredVariantsToDelete.isNotEmpty ||
                          isOnlyEnabledMods)
                        const Text('Are you sure you want to delete:'),
                      Flexible(
                        child: FadedScrollable(
                          child: Scrollbar(
                            thumbVisibility: true,
                            child: SingleChildScrollView(
                              primary: true,
                              child: Padding(
                                padding: const EdgeInsets.only(right: 16),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  spacing: 4,
                                  children: [
                                    for (final variant
                                        in filteredVariantsToDelete)
                                      _buildVariantToDeleteRow(variant, theme),
                                    if (enabledVariantsThatWillNotBeDeleted
                                        .isNotEmpty)
                                      Padding(
                                        padding: const .only(top: 16),
                                        child: Text.rich(
                                          TextSpan(
                                            style: theme.textTheme.bodyLarge
                                                ?.copyWith(fontSize: 20),
                                            children: [
                                              TextSpan(
                                                text:
                                                    "The following mods will ",
                                              ),
                                              TextSpan(
                                                text: "not",
                                                style: theme
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.copyWith(
                                                      fontSize: 20,
                                                      fontWeight: .bold,
                                                    ),
                                              ),
                                              TextSpan(
                                                text:
                                                    " be deleted because they are enabled:",
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    for (final variant
                                        in enabledVariantsThatWillNotBeDeleted)
                                      _buildVariantToDeleteRow(variant, theme),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (!isOnlyEnabledMods && enabledVariants.isNotEmpty)
                        CheckboxWithLabel(
                          label: "Allow deleting of currently-enabled mods",
                          value: allowDeletingEnabledMods,
                          onChanged: (newValue) {
                            setState(() {
                              allowDeletingEnabledMods =
                                  newValue ??
                                  allowDeletingEnabledModsDefaultState ??
                                  false;
                            });
                          },
                        ),
                      Text(
                        "This will delete the mod folder$s on disk. This action cannot be undone.",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  TextButton.icon(
                    onPressed: () => Navigator.of(context).pop(true),
                    label: Text(
                      'Delete ${filteredVariantsToDelete.length} Mod$s',
                    ),
                    icon: const Icon(Icons.delete),
                  ),
                ],
              );
            },
          );
        },
      );

      if (shouldDelete == true) {
        for (var variant in filteredVariantsToDelete) {
          deleteFolder(variant.modFolder.absolute.path);
        }
      }
    },
    (e, s) {
      Fimber.w("Error deleting mod folder", ex: e, stacktrace: s);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("An error occurred while deleting the mod folder(s)."),
        ),
      );
    },
  );
}

Row _buildVariantToDeleteRow(ModVariant variant, ThemeData theme) {
  return Row(
    children: [
      Checkbox(value: true, onChanged: (newValue) {}),
      Padding(
        padding: const .only(left: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "${variant.modInfo.nameOrId} v${variant.modInfo.version}",
              style: theme.textTheme.labelLarge,
            ),
            Text(
              variant.modFolder.path,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withAlpha(200),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
