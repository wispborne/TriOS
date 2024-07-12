import 'package:collection/collection.dart';
import 'package:dart_extensions_methods/dart_extension_methods.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toastification/toastification.dart';
import 'package:trios/mod_manager/mod_manager_logic.dart';
import 'package:trios/models/download_progress.dart';
import 'package:trios/models/mod.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/themes/theme_manager.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/widgets/download_progress_indicator.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../utils/logging.dart';
import '../download_manager/download_manager.dart';
import '../download_manager/download_status.dart';

class ModAddedToast extends ConsumerWidget {
  const ModAddedToast(this.modVariant, this.item, {super.key});

  final ToastificationItem item;
  final ModVariant modVariant;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modString = modVariant.modInfo.nameOrId;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: 4, right: 32),
      child: Card(
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(ThemeManager.cornerRadius),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 4.0,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Tooltip(
                  message: modVariant.modInfo.nameOrId,
                  child: Icon(Icons.add),
                ),
              ),
              Expanded(
                child: SelectionArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Text(
                      //   switch (status) {
                      //     DownloadStatus.queued => "Queued",
                      //     DownloadStatus.downloading => "Downloading",
                      //     DownloadStatus.completed => "Downloaded",
                      //     DownloadStatus.failed => "Download failed",
                      //     _ => "Download\n${status.name}"
                      //   },
                      //   style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 18),
                      // ),
                      Text(
                        modString ?? "",
                        style:
                            theme.textTheme.bodyMedium?.copyWith(fontSize: 18),
                      ),
                      Opacity(
                        opacity: 0.9,
                        child: Text(
                          modVariant.modInfo.version.toString(),
                          style: theme.textTheme.labelSmall,
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(0.0),
                            child: ElevatedButton.icon(
                                onPressed: () {
                                  // open folder in file explorer
                                  launchUrlString(modVariant.modsFolder.path);
                                },
                                icon: Icon(Icons.folder_open,
                                    color: theme.colorScheme.onSurface),
                                label: Text("Open",
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                        color: theme.colorScheme.onSurface))),
                          ),
                          SizedBox(width: 8),
                          Builder(builder: (context) {
                            final mods = ref.read(AppState.mods);
                            final mod = modVariant.mod(mods);
                            final currentVariant = mod?.findFirstEnabled;

                            return ElevatedButton.icon(
                                onPressed: () async {
                                  if (mod == null) {
                                    Fimber.w(
                                        "Cannot enable, mod not found for variant ${modVariant.smolId}");
                                    return;
                                  }
                                  await changeActiveModVariant(
                                      mod, modVariant, ref);
                                  toastification.dismiss(item);
                                },
                                icon: modVariant.iconFilePath.isNotNullOrEmpty()
                                    ? Image.file(
                                        (modVariant.iconFilePath ?? "")
                                            .toFile(),
                                        width: 20,
                                      )
                                    : const Icon(Icons.rocket_launch),
                                label: Text(
                                    "Enable${currentVariant != null ? " ${modVariant.bestVersion} (now ${currentVariant.bestVersion})" : ""}"));
                          }),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                  onPressed: () => toastification.dismiss(item),
                  icon: const Icon(Icons.close))
            ],
          ),
        ),
      ),
    );
  }
}
