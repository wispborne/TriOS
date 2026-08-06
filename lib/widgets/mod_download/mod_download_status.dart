import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/trios/download_manager/download_manager.dart';
import 'package:trios/trios/download_manager/download_status.dart';
import 'package:trios/trios/download_manager/download_target.dart';

/// What's happening to the mod a download button is about.
enum ModDownloadPhase {
  /// Nothing is running.
  idle,

  /// The button was clicked but no download has registered yet.
  starting,

  /// The file is coming down.
  downloading,

  /// The file is here and is being unpacked.
  installing,
}

@immutable
class ModDownloadStatus {
  final ModDownloadPhase phase;

  /// How far along, from 0 to 1. Null means "we don't know" — show a spinner
  /// that just turns.
  final double? progress;

  const ModDownloadStatus(this.phase, {this.progress});

  static const idle = ModDownloadStatus(ModDownloadPhase.idle);

  bool get isBusy => phase != ModDownloadPhase.idle;

  /// What to tell the user while this is running, or null when idle.
  String? get message => switch (phase) {
    ModDownloadPhase.idle => null,
    ModDownloadPhase.starting => 'Starting…',
    ModDownloadPhase.downloading => 'Downloading…',
    ModDownloadPhase.installing => 'Installing…',
  };
}

/// Watches the download (if any) for [target] and rebuilds [builder] as it
/// moves along.
///
/// Byte-level progress lives on the download's own listeners rather than in
/// Riverpod, so only this builder redraws as the numbers change — not the row,
/// card or dialog around it.
class ModDownloadStatusBuilder extends ConsumerWidget {
  final DownloadTarget target;
  final Widget Function(BuildContext context, ModDownloadStatus status) builder;

  const ModDownloadStatusBuilder({
    super.key,
    required this.target,
    required this.builder,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloads = ref.watch(downloadManager).value ?? const <Download>[];
    final download = findActiveDownload(downloads, target);

    if (download == null) {
      final isPending = ref.watch(pendingDownloadClicks).contains(target);
      return builder(
        context,
        isPending
            ? const ModDownloadStatus(ModDownloadPhase.starting)
            : ModDownloadStatus.idle,
      );
    }

    return ListenableBuilder(
      listenable: Listenable.merge([
        download.task.status,
        download.task.downloaded,
        download.installProgress,
        download.installComplete,
      ]),
      builder: (context, _) => builder(context, _statusOf(download)),
    );
  }

  static ModDownloadStatus _statusOf(Download download) {
    final status = download.task.status.value;
    if (status == DownloadStatus.completed && !download.installComplete.value) {
      return const ModDownloadStatus(ModDownloadPhase.installing);
    }
    final downloaded = download.task.downloaded.value;
    return ModDownloadStatus(
      ModDownloadPhase.downloading,
      progress:
          status == DownloadStatus.downloading && downloaded.totalBytes > 0
          ? downloaded.progressRatio
          : null,
    );
  }
}
