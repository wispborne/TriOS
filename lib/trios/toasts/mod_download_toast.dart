import 'dart:io';

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
import 'package:trios/widgets/text_trios.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../utils/logging.dart';
import '../download_manager/download_manager.dart';
import '../download_manager/download_status.dart';

class ModDownloadToast extends ConsumerStatefulWidget {
  /// toastDurationMillis Starts ticking after download is completed or failed.
  const ModDownloadToast(
    this.download,
    this.item,
    this.toastDurationMillis, {
    super.key,
  });

  final ToastificationItem item;
  final Download download;

  final int toastDurationMillis;

  @override
  ConsumerState<ModDownloadToast> createState() => _ModDownloadToastState();
}

class _ModDownloadToastState extends ConsumerState<ModDownloadToast> {
  PaletteGenerator? palette;
  bool _isHovering = false;
  ModVariant? _lastInstalledMod;
  int? _installedSizeBytes;

  Future<void> _computeInstalledSize(ModVariant mod) async {
    final dir = mod.modFolder;
    if (!dir.existsSync()) return;
    var total = 0;
    await for (final entity in dir.list(recursive: true)) {
      if (entity is File) {
        try {
          total += await entity.length();
        } catch (_) {}
      }
    }
    if (mounted) setState(() => _installedSizeBytes = total);
  }

  Future<void> _generatePalette(ModVariant variant) async {
    if (variant.iconFilePath.isNotNullOrEmpty()) {
      final icon = Image.file((variant.iconFilePath ?? "").toFile());
      palette = await PaletteGenerator.fromImageProvider(icon.image);
      if (!mounted) return;
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    widget.item.pause();
    // loop to update the time remaining every 5ms
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 5));
      if (mounted) {
        setState(() {});
      }
      return mounted;
    });

    // Listen for installComplete to trigger auto-dismiss for install-only entries.
    widget.download.installComplete.addListener(_onInstallComplete);
    widget.download.installProgress.addListener(_onInstallProgressChanged);
    widget.download.installedVariant.addListener(_onInstalledVariantChanged);
  }

  void _onInstallComplete() {
    if (mounted) setState(() {});
  }

  void _onInstallProgressChanged() {
    if (mounted) setState(() {});
  }

  void _onInstalledVariantChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.download.installComplete.removeListener(_onInstallComplete);
    widget.download.installProgress.removeListener(_onInstallProgressChanged);
    widget.download.installedVariant.removeListener(_onInstalledVariantChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final download = widget.download;
    final item = widget.item;
    final downloadTask = download.task;
    var installedMod = download is ModDownload
        ? ref
              .watch(AppState.modVariants)
              .value
              .orEmpty()
              .firstWhereOrNull(
                (ModVariant element) =>
                    element.smolId == download.modInfo.smolId,
              )
        : download.installedVariant.value;
    final modString = installedMod?.modInfo.name ?? download.displayName;
    if (palette == null && installedMod != null) {
      _generatePalette(installedMod);
    }
    if (installedMod != null && installedMod != _lastInstalledMod) {
      _lastInstalledMod = installedMod;
      _computeInstalledSize(installedMod);
    }
    final currentlyEnabled = installedMod
        ?.mod(ref.read(AppState.mods))
        ?.findFirstEnabled;
    final timeElapsed = (widget.item.elapsedDuration?.inMilliseconds ?? 0);
    final timeTotal = (widget.item.originalDuration?.inMilliseconds ?? 1000);

    return Padding(
      padding: const EdgeInsets.only(top: 4, right: 32),
      child: Container(
        decoration: const BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4.0,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Theme(
          data: palette.createPaletteTheme(context),
          child: Builder(
            builder: (context) {
              final theme = Theme.of(context);
              return MouseRegion(
                onEnter: (_) {
                  setState(() => _isHovering = true);
                  widget.item.pause();
                },
                onExit: (_) {
                  setState(() => _isHovering = false);
                  final isReadyToAutoDismiss =
                      !download.hasInstallError &&
                      (installedMod != null || download.installComplete.value);
                  if (downloadTask.status.value.isCompleted &&
                      isReadyToAutoDismiss) {
                    widget.item.start();
                  }
                },
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  child: Container(
                    padding: const EdgeInsets.only(top: 16),
                    color: theme.colorScheme.surface,
                    child: ValueListenableBuilder(
                      valueListenable: downloadTask.status,
                      builder: (context, status, child) {
                        final isStopped = (!item.isRunning || !item.isStarted);
                        // Don't auto-dismiss while installing. Wait for the
                        // mod variant to appear (ModDownload) or
                        // installComplete (install-only Download).
                        // Never auto-dismiss if installation failed.
                        final isReadyToAutoDismiss =
                            !download.hasInstallError &&
                            (installedMod != null ||
                                download.installComplete.value);
                        if (isStopped && isReadyToAutoDismiss && !_isHovering) {
                          item.start();
                        }

                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 16,
                                right: 16,
                                bottom: 16,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(right: 16),
                                    child:
                                        status.isCompleted &&
                                            installedMod != null
                                        ? SizedBox(
                                            width: 40,
                                            height: 40,
                                            child:
                                                installedMod.iconFilePath
                                                    .isNotNullOrEmpty()
                                                ? Image.file(
                                                    (installedMod
                                                                .iconFilePath ??
                                                            "")
                                                        .toFile(),
                                                  )
                                                : const Icon(
                                                    Icons.extension,
                                                    size: 40,
                                                  ),
                                          )
                                        : Tooltip(
                                            message:
                                                status ==
                                                        DownloadStatus
                                                            .completed &&
                                                    installedMod == null
                                                ? download.hasInstallError
                                                      ? "Installation failed"
                                                      : "Installing..."
                                                : status.displayString,
                                            child: Icon(
                                              size: 40,
                                              status ==
                                                          DownloadStatus
                                                              .completed &&
                                                      installedMod == null
                                                  ? download.hasInstallError
                                                        ? Icons.error
                                                        : Icons.install_desktop
                                                  : switch (status) {
                                                      DownloadStatus.queued =>
                                                        Icons.schedule,
                                                      DownloadStatus
                                                          .retrievingFileInfo =>
                                                        Icons.downloading,
                                                      DownloadStatus
                                                          .downloading =>
                                                        Icons.downloading,
                                                      DownloadStatus
                                                          .completed =>
                                                        Icons.check_circle,
                                                      DownloadStatus.failed =>
                                                        Icons.error,
                                                      DownloadStatus.canceled =>
                                                        Icons.circle,
                                                      _ => Icons.downloading,
                                                    },
                                              color:
                                                  status ==
                                                          DownloadStatus
                                                              .completed &&
                                                      download.hasInstallError
                                                  ? ThemeManager
                                                        .vanillaErrorColor
                                                  : switch (status) {
                                                      DownloadStatus.queued =>
                                                        theme.iconTheme.color,
                                                      DownloadStatus
                                                          .retrievingFileInfo =>
                                                        theme.iconTheme.color,
                                                      DownloadStatus
                                                          .downloading =>
                                                        theme.iconTheme.color,
                                                      DownloadStatus
                                                          .completed =>
                                                        theme
                                                            .colorScheme
                                                            .secondary,
                                                      DownloadStatus.failed =>
                                                        ThemeManager
                                                            .vanillaErrorColor,
                                                      DownloadStatus.canceled =>
                                                        ThemeManager
                                                            .vanillaErrorColor,
                                                      _ =>
                                                        theme.iconTheme.color,
                                                    },
                                            ),
                                          ),
                                  ),
                                  Expanded(
                                    child: SelectionArea(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            modString,
                                            style: theme.textTheme.bodyMedium,
                                          ),
                                          if (status.isCompleted &&
                                              installedMod != null) ...[
                                            // --- Installed state ---
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                top: 2,
                                              ),
                                              child: Text(
                                                installedMod.modInfo.version
                                                    .toString(),
                                                style:
                                                    theme.textTheme.labelMedium,
                                              ),
                                            ),
                                            if (currentlyEnabled != null &&
                                                currentlyEnabled.smolId !=
                                                    installedMod.smolId)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  top: 2,
                                                ),
                                                child: Text(
                                                  "Previously enabled: ${currentlyEnabled.modInfo.version}",
                                                  style: theme
                                                      .textTheme
                                                      .labelMedium,
                                                ),
                                              ),
                                            ValueListenableBuilder(
                                              valueListenable:
                                                  downloadTask.downloaded,
                                              builder: (context, dl, _) {
                                                final dlBytes = dl.totalBytes;
                                                return Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        top: 4,
                                                      ),
                                                  child: Opacity(
                                                    opacity: 0.6,
                                                    child: Row(
                                                      spacing: 8,
                                                      children: [
                                                        if (dlBytes > 0)
                                                          Tooltip(
                                                            message:
                                                                "Downloaded archive size",
                                                            child: Row(
                                                              spacing: 4,
                                                              children: [
                                                                const Icon(
                                                                  Icons
                                                                      .file_download_outlined,
                                                                  size: 12,
                                                                ),
                                                                Text(
                                                                  dlBytes
                                                                      .bytesAsReadableMB(),
                                                                  style: theme
                                                                      .textTheme
                                                                      .labelSmall,
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        if (dlBytes > 0 &&
                                                            _installedSizeBytes !=
                                                                null)
                                                          const Icon(
                                                            Icons.arrow_forward,
                                                            size: 10,
                                                          ),
                                                        if (_installedSizeBytes !=
                                                            null)
                                                          Tooltip(
                                                            message:
                                                                "Installed size on disk",
                                                            child: Row(
                                                              spacing: 4,
                                                              children: [
                                                                const Icon(
                                                                  Icons
                                                                      .folder_outlined,
                                                                  size: 12,
                                                                ),
                                                                Text(
                                                                  _installedSizeBytes!
                                                                      .bytesAsReadableMB(),
                                                                  style: theme
                                                                      .textTheme
                                                                      .labelSmall,
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                            if (downloadTask
                                                .request
                                                .url
                                                .isNotEmpty)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  top: 4,
                                                ),
                                                child: Opacity(
                                                  opacity: 0.6,
                                                  child: Row(
                                                    spacing: 4,
                                                    crossAxisAlignment: .end,
                                                    children: [
                                                      const Icon(
                                                        Icons.download_done,
                                                        size: 12,
                                                      ),
                                                      Expanded(
                                                        child: TextTriOS(
                                                          downloadTask
                                                              .request
                                                              .url,
                                                          style: theme
                                                              .textTheme
                                                              .labelSmall,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          maxLines: 1,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                top: 8,
                                              ),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.end,
                                                children: [
                                                  ElevatedButton.icon(
                                                    onPressed: () {
                                                      launchUrlString(
                                                        installedMod
                                                            .modFolder
                                                            .path,
                                                      );
                                                    },
                                                    icon: Icon(
                                                      Icons.folder_open,
                                                      color: theme
                                                          .colorScheme
                                                          .onSurface,
                                                    ),
                                                    label: Text(
                                                      "Open",
                                                      style: theme
                                                          .textTheme
                                                          .bodyMedium
                                                          ?.copyWith(
                                                            color: theme
                                                                .colorScheme
                                                                .onSurface,
                                                          ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Builder(
                                                    builder: (context) {
                                                      final mod = installedMod
                                                          .mod(
                                                            ref.read(
                                                              AppState.mods,
                                                            ),
                                                          );
                                                      return ElevatedButton.icon(
                                                        onPressed: () async {
                                                          if (mod == null) {
                                                            Fimber.w(
                                                              "Cannot enable, mod not found for variant ${installedMod.smolId}",
                                                            );
                                                            return;
                                                          }
                                                          await ref
                                                              .read(
                                                                modManager
                                                                    .notifier,
                                                              )
                                                              .changeActiveModVariantWithForceModGameVersionDialogIfNeeded(
                                                                mod,
                                                                installedMod,
                                                              );
                                                          toastification
                                                              .dismiss(item);
                                                        },
                                                        icon: const SizedBox(
                                                          width: 24,
                                                          height: 24,
                                                          child: Icon(
                                                            Icons
                                                                .power_settings_new,
                                                          ),
                                                        ),
                                                        label: const Text(
                                                          "Enable",
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ] else if (status ==
                                                  DownloadStatus.completed &&
                                              download.hasInstallError) ...[
                                            // --- Installation failed state ---
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                top: 8,
                                              ),
                                              child: TextTriOS(
                                                downloadTask.error.toString(),
                                                maxLines: 5,
                                                overflow: .fade,
                                                warningLevel: .error,
                                                style: theme
                                                    .textTheme
                                                    .labelMedium
                                                    ?.copyWith(
                                                      color: ThemeManager
                                                          .vanillaErrorColor,
                                                    ),
                                              ),
                                            ),
                                          ] else if (status ==
                                              DownloadStatus.completed) ...[
                                            // --- Installing state ---
                                            Opacity(
                                              opacity: 0.9,
                                              child: Padding(
                                                padding: const EdgeInsets.only(
                                                  top: 4,
                                                ),
                                                child: Text(
                                                  "Installing...",
                                                  style: theme
                                                      .textTheme
                                                      .labelMedium,
                                                ),
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                top: 8,
                                              ),
                                              child: Builder(
                                                builder: (context) {
                                                  final progress = download
                                                      .installProgress
                                                      .value;
                                                  return TriOSDownloadProgressIndicator(
                                                    value:
                                                        progress ??
                                                        TriOSDownloadProgress(
                                                          0,
                                                          0,
                                                          isIndeterminate: true,
                                                        ),
                                                  );
                                                },
                                              ),
                                            ),
                                          ] else ...[
                                            // --- Downloading / failed state ---
                                            Opacity(
                                              opacity: 0.9,
                                              child: Padding(
                                                padding: const EdgeInsets.only(
                                                  top: 4,
                                                ),
                                                child: TextTriOS(
                                                  downloadTask.request.url,
                                                  style: theme
                                                      .textTheme
                                                      .labelMedium,
                                                  maxLines: 1,
                                                ),
                                              ),
                                            ),
                                            if (status ==
                                                    DownloadStatus.failed &&
                                                downloadTask.error != null)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  top: 8,
                                                ),
                                                child: Text(
                                                  downloadTask.error.toString(),
                                                  style: theme
                                                      .textTheme
                                                      .labelMedium
                                                      ?.copyWith(
                                                        color: ThemeManager
                                                            .vanillaErrorColor,
                                                      ),
                                                ),
                                              ),
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                top: 8,
                                              ),
                                              child: ValueListenableBuilder(
                                                valueListenable:
                                                    downloadTask.downloaded,
                                                builder: (context, downloaded, child) {
                                                  final isIndeterminate =
                                                      status ==
                                                          DownloadStatus
                                                              .queued ||
                                                      status ==
                                                          DownloadStatus
                                                              .retrievingFileInfo;
                                                  return TriOSDownloadProgressIndicator(
                                                    color:
                                                        status ==
                                                            DownloadStatus
                                                                .failed
                                                        ? ThemeManager
                                                              .vanillaErrorColor
                                                        : null,
                                                    value:
                                                        TriOSDownloadProgress(
                                                          downloaded
                                                              .bytesReceived,
                                                          downloaded.totalBytes,
                                                          isIndeterminate:
                                                              isIndeterminate,
                                                        ),
                                                  );
                                                },
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () =>
                                        toastification.dismiss(widget.item),
                                    icon: const Icon(Icons.close),
                                  ),
                                ],
                              ),
                            ),
                            LinearProgressIndicator(
                              value: ((timeTotal - timeElapsed) / timeTotal)
                                  .clamp(0.0, 1.0),
                              minHeight: 3,
                              backgroundColor: Colors.transparent,
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
