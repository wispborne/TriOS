import 'package:trios/mod_manager/batch_installation/batch_installation.dart';
import 'package:trios/trios/download_manager/download_manager.dart';
import 'package:trios/trios/download_manager/download_status.dart';

/// Which installs and downloads count as "still going".
///
/// The Activity Panel and the toolbar's activity button both show the same
/// list, so they ask these two questions rather than each deciding for itself.

/// Batch entries still in flight, in their original order.
///
/// Finished, failed and skipped entries move to the "Recent" history instead.
/// Entries that came from a download are left out — they already have a
/// download tile of their own, and listing both shows the same install twice.
List<BatchEntry> activeBatchEntries(BatchInstallation? batch) =>
    batch?.entries
        .where(
          (e) =>
              e.download == null &&
              (e.status == BatchEntryStatus.queued ||
                  e.status == BatchEntryStatus.scanning ||
                  e.status == BatchEntryStatus.scanned ||
                  e.status == BatchEntryStatus.extracting),
        )
        .toList() ??
    const [];

/// Downloads still working: still coming down, or downloaded but not yet
/// finished installing. A download that failed or was cancelled is done, since
/// its install never starts.
List<Download> inProgressDownloads(Iterable<Download> downloads) =>
    downloads.where((d) {
      final status = d.task.status.value;
      if (status == DownloadStatus.failed ||
          status == DownloadStatus.canceled) {
        return false;
      }
      final installDone = d.installComplete.value || d.installCancelled.value;
      return !status.isCompleted || !installDone;
    }).toList();
