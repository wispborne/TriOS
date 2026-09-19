import 'package:trios/compression/archive.dart';
import 'package:trios/mod_manager/batch_installation/batch_pre_scanner.dart';
import 'package:trios/mod_manager/batch_installation/batch_installation.dart';
import 'package:trios/models/mod_info.dart';

import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trios/trios/download_manager/downloader.dart';
import 'package:trios/trios/download_manager/download_request.dart';
import 'package:trios/trios/download_manager/download_task.dart';
import 'package:trios/trios/download_manager/download_status.dart';
import 'package:trios/utils/http_client.dart';
import 'package:trios/utils/http_probe.dart';

class FakeClient extends TriOSHttpClient {
  final finish = Completer<void>();
  int transfers = 0;
  final transferUrls = <Uri>[];
  FakeClient() : super(config: ApiClientConfig());
  @override
  Future<HttpProbeResult> probe(
    Uri url, {
    required int maxBytes,
    required bool prefixOnly,
    required HttpProbeCancellation cancellation,
    bool? allowSelfSignedCertificates,
  }) async => HttpProbeResult(Uri.parse('https://example.org/archive.zip'), [
    0x50,
    0x4b,
  ], 'application/zip');
  @override
  Future<Uri> downloadArchive(
    Uri url,
    File file, {
    required void Function(int, int) onProgress,
  }) async {
    transfers++;
    transferUrls.add(url);
    onProgress(2, 4);
    await finish.future;
    await file.writeAsBytes([0x50, 0x4b, 0, 0]);
    onProgress(4, 4);
    // A real transfer follows redirects and reports where it ended.
    return Uri.parse('https://example.org/archive.zip');
  }
}

class _UnusedArchive implements ArchiveInterface {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Scanner extends BatchPreScanner {
  int scans = 0;
  _Scanner() : super(archive: _UnusedArchive(), existingVariants: []);
  @override
  Future<void> scanArchive(BatchEntry entry) async {
    scans++;
    entry.scanResult = ScannedArchive(
      modInfo: ModInfo(id: 'wanted'),
      fileCount: 1,
    );
    entry.status = BatchEntryStatus.scanned;
  }
}

void main() {
  test('different URLs share the final-address transfer until every caller releases it', () async {
    final client = FakeClient();
    final container = ProviderContainer(
      overrides: [triOSHttpClient.overrideWithValue(client)],
    );
    addTearDown(() {
      container.dispose();
      client.close();
    });
    final manager = container.read(downloadManagerInstance);
    final a = await manager.acquireShared('https://example.org/a');
    final b = await manager.acquireShared('https://example.org/b');
    expect(identical(a, b), isTrue);
    expect(client.transfers, 1);
    // The transfer follows redirects itself instead of reusing the probe's
    // end address, which may be a signed link that has since expired.
    expect(client.transferUrls, [Uri.parse('https://example.org/a')]);
    expect(a.task.downloaded.value.bytesReceived, 2);
    client.finish.complete();
    final file = await a.completed;
    expect(await b.completed, file);
    expect(a.finalUrl, 'https://example.org/archive.zip');
    final scanner = _Scanner();
    final scans = await Future.wait([a.inspect(scanner), b.inspect(scanner)]);
    expect(identical(scans.first, scans.last), isTrue);
    expect(scanner.scans, 1);
    final later = await manager.acquireShared('https://example.org/later');
    expect(identical(later, a), isTrue);
    await later.completed;
    expect(client.transfers, 1);
    await later.release();
    await a.release();
    expect(await file.exists(), isTrue);
    await b.release();
    expect(await file.exists(), isFalse);
    expect(manager.runningTasks, 0);
  });

  test(
    'awaiting completion on a completed task leaves no listener behind',
    () async {
      final task = DownloadTask(
        DownloadRequest('https://example.org/a', '', null),
      );
      task.status.value = DownloadStatus.completed;
      expect(await task.whenDownloadComplete(), DownloadStatus.completed);
      // ignore: invalid_use_of_protected_member
      expect(task.status.hasListeners, isFalse);
    },
  );

  test('completion timeout removes the listener', () async {
    final task = DownloadTask(
      DownloadRequest('https://example.org/a', '', null),
    );
    await expectLater(
      task.whenDownloadComplete(timeout: Duration.zero),
      throwsA(isA<TimeoutException>()),
    );
    // ignore: invalid_use_of_protected_member
    expect(task.status.hasListeners, isFalse);
  });
}
