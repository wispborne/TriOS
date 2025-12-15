import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:trios/about/about_page.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/thirdparty/faded_scrollable/faded_scrollable.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/utils/platform_specific.dart';
import 'package:trios/widgets/disable.dart';
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

  Row _buildVariantToDeleteRow(
    ModVariant variant,
    bool isEnabled,
    ThemeData theme, {
    required bool checked,
    required ValueChanged<bool?> onChanged,
  }) {
    return Row(
      children: [
        Checkbox(value: checked, onChanged: onChanged),
        InkWell(
          onTap: () => onChanged(!checked),
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
          child: Padding(
            padding: const .only(left: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      "${variant.modInfo.nameOrId} v${variant.modInfo.version}",
                      style: theme.textTheme.labelLarge,
                    ),
                    if (isEnabled)
                      Text(
                        " (enabled)",
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
                Text(
                  "${variant.modFolder.path}",
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.textTheme.bodyMedium?.color?.withAlpha(200),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  if (variantsToDelete.isEmpty) {
    return;
  }

  runZonedGuarded(
    () async {
      // Build enabled/disabled maps and selection state
      final allMods = ref.read(AppState.mods);
      final isEnabledBySmolId = <String, bool>{
        for (final v in variantsToDelete) v.smolId: v.isEnabled(allMods),
      };
      final enabledSmolIds = isEnabledBySmolId.entries
          .where((e) => e.value)
          .map((e) => e.key)
          .toSet();
      final disabledSmolIds = isEnabledBySmolId.entries
          .where((e) => !e.value)
          .map((e) => e.key)
          .toSet();
      final selectedSmolIds = <String>{};
      bool initializedSelection = false;

      final shouldDelete = await showDialog<bool>(
        context: context,
        builder: (context) {
          final theme = Theme.of(context);

          return StatefulBuilder(
            builder: (context, setState) {
              // Initialize the default selection once per dialog open
              if (!initializedSelection) {
                final hasBoth =
                    enabledSmolIds.isNotEmpty && disabledSmolIds.isNotEmpty;
                if (hasBoth) {
                  selectedSmolIds
                    ..clear()
                    ..addAll(disabledSmolIds);
                } else {
                  selectedSmolIds
                    ..clear()
                    ..addAll(isEnabledBySmolId.keys);
                }
                initializedSelection = true;
              }

              final hasBothEnabledAndDisabled =
                  enabledSmolIds.isNotEmpty && disabledSmolIds.isNotEmpty;
              final selectedCount = selectedSmolIds.length;
              final s = selectedCount == 1 ? "" : "s";

              return AlertDialog(
                title: Text('Delete Mod$s'),
                content: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 8,
                    children: [
                      const Text('Select the mod folders to delete:'),
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
                                    for (final variant in variantsToDelete)
                                      _buildVariantToDeleteRow(
                                        variant,
                                        variant.isEnabled(allMods),
                                        theme,
                                        checked: selectedSmolIds.contains(
                                          variant.smolId,
                                        ),
                                        onChanged: (newValue) {
                                          setState(() {
                                            if (newValue == true) {
                                              selectedSmolIds.add(
                                                variant.smolId,
                                              );
                                            } else {
                                              selectedSmolIds.remove(
                                                variant.smolId,
                                              );
                                            }
                                          });
                                        },
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (variantsToDelete.length > 5)
                        Row(
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton.icon(
                                onPressed: () {
                                  setState(() {
                                    selectedSmolIds.addAll(
                                      variantsToDelete.map((v) => v.smolId),
                                    );
                                  });
                                },
                                icon: const Icon(Icons.select_all),
                                label: const Text('Select all'),
                              ),
                            ),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton.icon(
                                onPressed: () {
                                  setState(() {
                                    selectedSmolIds.clear();
                                  });
                                },
                                icon: const Icon(Icons.deselect),
                                label: const Text('Deselect all'),
                              ),
                            ),
                          ],
                        ),
                      Padding(
                        padding: const .only(top: 16),
                        child: Text(
                          "This will delete the mod folder$s on disk. This action cannot be undone.",
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
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
                  Disable(
                    isEnabled: selectedCount > 0,
                    child: TextButton.icon(
                      onPressed: () => Navigator.of(context).pop(true),
                      label: Text('Delete $selectedCount Mod$s'),
                      icon: const Icon(Icons.delete),
                    ),
                  ),
                ],
              );
            },
          );
        },
      );

      if (shouldDelete == true) {
        final toDelete = variantsToDelete
            .where((v) => selectedSmolIds.contains(v.smolId))
            .toList();
        for (var variant in toDelete) {
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
