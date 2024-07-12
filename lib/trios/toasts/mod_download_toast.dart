import 'package:collection/collection.dart';
import 'package:dart_extensions_methods/dart_extension_methods.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:toastification/toastification.dart';
import 'package:trios/mod_manager/mod_manager_logic.dart';
import 'package:trios/models/download_progress.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/themes/theme_manager.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/widgets/download_progress_indicator.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../utils/logging.dart';
import '../download_manager/download_manager.dart';
import '../download_manager/download_status.dart';

class ModDownloadToast extends ConsumerStatefulWidget {
  const ModDownloadToast(this.download, this.item, {super.key});

  final ToastificationItem item;
  final Download download;

  @override
  ConsumerState<ModDownloadToast> createState() => _ModDownloadToastState();
}

class _ModDownloadToastState extends ConsumerState<ModDownloadToast> {
  PaletteGenerator? palette;

  Future<void> _generatePalette(ModVariant variant) async {
    if (variant.iconFilePath.isNotNullOrEmpty()) {
      final icon = Image.file((variant.iconFilePath ?? "").toFile());
      palette = await PaletteGenerator.fromImageProvider(icon.image);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final download = widget.download;
    final item = widget.item;
    final modString = download.displayName;
    final downloadTask = download.task;
    var installedMod = download is ModDownload
        ? ref.watch(AppState.modVariants).value.orEmpty().firstWhereOrNull(
            (ModVariant element) => element.smolId == (download).modInfo.smolId)
        : null;
    if (palette == null && installedMod != null) {
      _generatePalette(installedMod);
    }

    return Padding(
      padding: const EdgeInsets.only(top: 4, right: 32),
      child: Theme(
        data: createPaletteTheme(context, palette),
        child: Builder(builder: (context) {
          final theme = Theme.of(context);
          return Card(
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
              child: ValueListenableBuilder(
                valueListenable: downloadTask.status,
                builder: (context, status, child) {
                  return Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: Tooltip(
                          message: download.id,
                          child: Icon(
                            size: 40,
                            switch (status) {
                              DownloadStatus.queued => Icons.schedule,
                              DownloadStatus.downloading => Icons.downloading,
                              DownloadStatus.completed => Icons.check_circle,
                              DownloadStatus.failed => Icons.error,
                              DownloadStatus.canceled => Icons.circle,
                              _ => Icons.downloading
                            },
                            color: switch (status) {
                              DownloadStatus.queued => null,
                              DownloadStatus.downloading => null,
                              DownloadStatus.completed =>
                                theme.colorScheme.primary,
                              DownloadStatus.failed => vanillaErrorColor,
                              DownloadStatus.canceled => vanillaErrorColor,
                              _ => null
                            },
                          ),
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
                                style: theme.textTheme.bodyMedium,
                              ),
                              Opacity(
                                opacity: 0.9,
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    downloadTask.request.url,
                                    style: theme.textTheme.labelMedium,
                                  ),
                                ),
                              ),
                              if (status == DownloadStatus.failed &&
                                  downloadTask.error != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    downloadTask.error.toString(),
                                    style: theme.textTheme.labelMedium
                                        ?.copyWith(color: vanillaErrorColor),
                                  ),
                                ),
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: ValueListenableBuilder(
                                  valueListenable: downloadTask.downloaded,
                                  builder: (context, downloaded, child) =>
                                      DownloadProgressIndicator(
                                    color: status == DownloadStatus.failed
                                        ? vanillaErrorColor
                                        : null,
                                    value: DownloadProgress(
                                        downloaded.bytesReceived,
                                        downloaded.totalBytes),
                                  ),
                                ),
                              ),
                              if (installedMod != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    "Currently enabled: ${installedMod.modInfo.version}",
                                    style: theme.textTheme.labelMedium,
                                  ),
                                ),
                              if (installedMod != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      ElevatedButton.icon(
                                          onPressed: () {
                                            // open folder in file explorer
                                            launchUrlString(
                                                installedMod.modsFolder.path);
                                          },
                                          icon: Icon(Icons.folder_open,
                                              color:
                                                  theme.colorScheme.onSurface),
                                          label: Text("Open",
                                              style: theme.textTheme.bodyMedium
                                                  ?.copyWith(
                                                      color: theme.colorScheme
                                                          .onSurface))),
                                      const SizedBox(width: 8),
                                      Builder(builder: (context) {
                                        final mods = ref.read(AppState.mods);
                                        final mod = installedMod.mod(mods);
                                        final currentVariant =
                                            mod?.findFirstEnabled;

                                        return ElevatedButton.icon(
                                          onPressed: () async {
                                            if (mod == null) {
                                              Fimber.w(
                                                  "Cannot enable, mod not found for variant ${installedMod.smolId}");
                                              return;
                                            }
                                            await changeActiveModVariant(
                                                mod, installedMod, ref);
                                            toastification.dismiss(item);
                                          },
                                          icon: const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child:
                                                Icon(Icons.power_settings_new),
                                          ),
                                          label: const Text("Enable"),
                                        );
                                      }),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      IconButton(
                          onPressed: () => toastification.dismiss(item),
                          icon: const Icon(Icons.close))
                    ],
                  );
                },
              ),
            ),
          );
        }),
      ),
    );
  }
}
