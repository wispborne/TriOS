import 'dart:async';
import 'dart:io';

import 'package:trios/mod_manager/batch_installation/batch_installation.dart';
import 'package:trios/mod_manager/batch_installation/batch_pre_scanner.dart';

import 'download_task.dart';
import 'download_status.dart';

/// An archive transfer shared by its final normalized address. Callers retain
/// it until extraction finishes; the last release removes temporary files.
class SharedDownload {
  final DownloadTask task;
  final Directory directory;
  final void Function() onReleased;
  int _users = 0;
  Future<BatchEntry>? _scan;

  SharedDownload(this.task, this.directory, this.onReleased);

  String get finalUrl => task.finalUrl ?? task.request.url;
  void retain() => _users++;

  Future<File> get completed async {
    final status = await task.whenDownloadComplete();
    if (status != DownloadStatus.completed || task.file.value == null) {
      throw task.error ?? StateError('Download did not complete.');
    }
    return task.file.value!;
  }

  Future<BatchEntry> inspect(BatchPreScanner scanner) => _scan ??= () async {
    final entry = BatchEntry(id: finalUrl, source: await completed);
    await scanner.scanArchive(entry);
    if (entry.status == BatchEntryStatus.failed) {
      throw entry.error ??
          StateError(entry.errorDetail ?? 'Cannot read archive.');
    }
    return entry;
  }();

  Future<void> release() async {
    if (--_users != 0) return;
    onReleased();
    await task.whenDownloadComplete();
    if (await directory.exists()) await directory.delete(recursive: true);
  }
}
