import 'package:flutter_test/flutter_test.dart';
import 'package:trios/models/mod_info.dart';
import 'package:trios/models/version.dart';
import 'package:trios/trios/download_manager/download_manager.dart';
import 'package:trios/trios/download_manager/download_request.dart';
import 'package:trios/trios/download_manager/download_status.dart';
import 'package:trios/trios/download_manager/download_target.dart';
import 'package:trios/trios/download_manager/download_task.dart';

/// A download that isn't tied to a known mod id, the way a catalog install
/// looks before its archive is unpacked.
Download _download({
  String url = 'https://example.com/mod.zip',
  String displayName = 'Some Mod',
  String? catalogName,
  DownloadStatus status = DownloadStatus.downloading,
  bool installComplete = false,
}) {
  final task = DownloadTask(DownloadRequest(url, '', null));
  task.status.value = status;
  final download = Download(
    'id',
    displayName,
    task,
    sourceHint: catalogName == null
        ? null
        : DownloadSourceHint(catalogName: catalogName),
  );
  download.installComplete.value = installComplete;
  return download;
}

/// A download whose mod id is already known, the way a version-check update is.
ModDownload _modDownload({
  required String modId,
  String url = 'https://example.com/mod.zip',
  String displayName = 'Some Mod',
  String? catalogName,
  DownloadStatus status = DownloadStatus.downloading,
}) {
  final task = DownloadTask(DownloadRequest(url, '', null));
  task.status.value = status;
  return ModDownload(
    'id',
    displayName,
    task,
    ModInfo(id: modId, name: displayName, version: Version.parse('1.0.0')),
    sourceHint: catalogName == null
        ? null
        : DownloadSourceHint(catalogName: catalogName),
  );
}

void main() {
  group('DownloadTarget.matches', () {
    test('a target needs at least one clue', () {
      expect(() => DownloadTarget(), throwsA(isA<AssertionError>()));
    });

    test('matches on mod id', () {
      final target = DownloadTarget(modId: 'lazylib');
      expect(target.matches(_modDownload(modId: 'lazylib')), isTrue);
    });

    test('mod ids ignore case and surrounding spaces', () {
      final target = DownloadTarget(modId: '  LazyLib ');
      expect(target.matches(_modDownload(modId: 'lazylib')), isTrue);
    });

    test('two known-but-different mod ids never match, however alike '
        'everything else looks', () {
      final target = DownloadTarget(
        modId: 'lazylib',
        url: 'https://example.com/mod.zip',
        catalogName: 'LazyLib',
        displayName: 'LazyLib',
      );
      final other = _modDownload(
        modId: 'magiclib',
        url: 'https://example.com/mod.zip',
        catalogName: 'LazyLib',
        displayName: 'LazyLib',
      );

      expect(
        target.matches(other),
        isFalse,
        reason: 'a matching name must not override a mod id that disagrees',
      );
    });

    test('a download with no mod id yet still matches on its name', () {
      final target = DownloadTarget(modId: 'lazylib', displayName: 'LazyLib');
      expect(target.matches(_download(displayName: 'LazyLib')), isTrue);
    });

    test('matches on url', () {
      final target = DownloadTarget(url: 'https://example.com/mod.zip');
      expect(
        target.matches(
          _download(url: 'https://example.com/mod.zip', displayName: 'Other'),
        ),
        isTrue,
      );
    });

    test('urls are compared after the same tidy-up downloads get', () {
      const dl0 =
          'https://www.dropbox.com/s/abc123/mod.version?dl=0';
      const dl1 =
          'https://www.dropbox.com/s/abc123/mod.version?dl=1';

      expect(
        DownloadTarget(url: dl0).matches(_download(url: dl1, displayName: 'x')),
        isTrue,
        reason: 'the downloader rewrites dl=0 to dl=1, so both are one url',
      );
    });

    test('different urls alone are not a match', () {
      final target = DownloadTarget(url: 'https://example.com/a.zip');
      expect(
        target.matches(
          _download(url: 'https://example.com/b.zip', displayName: 'Other'),
        ),
        isFalse,
      );
    });

    test('a catalog entry name matches the download it started', () {
      final target = DownloadTarget(catalogName: 'Ashpad');
      expect(
        target.matches(
          _download(displayName: 'Other', catalogName: 'Ashpad'),
        ),
        isTrue,
      );
    });

    test('a catalog name matches a download only named on screen', () {
      final target = DownloadTarget(catalogName: 'Ashpad');
      expect(target.matches(_download(displayName: 'ashpad')), isTrue);
    });

    test('a display name matches the download catalog name', () {
      final target = DownloadTarget(displayName: 'Ashpad');
      expect(
        target.matches(
          _download(displayName: 'unrelated', catalogName: 'Ashpad'),
        ),
        isTrue,
      );
    });

    test('nothing in common is not a match', () {
      final target = DownloadTarget(
        catalogName: 'Ashpad',
        url: 'https://example.com/a.zip',
      );
      expect(
        target.matches(
          _download(url: 'https://example.com/b.zip', displayName: 'LazyLib'),
        ),
        isFalse,
      );
    });

    test('empty clues are ignored rather than matching each other', () {
      final target = DownloadTarget(displayName: 'Ashpad', catalogName: '');
      expect(
        target.matches(_download(displayName: '   ')),
        isFalse,
        reason: 'two blank names are not the same download',
      );
    });
  });

  group('findActiveDownload', () {
    test('finds the running download for a target', () {
      final mine = _modDownload(modId: 'lazylib');
      final theirs = _modDownload(modId: 'magiclib');

      expect(
        findActiveDownload([theirs, mine], DownloadTarget(modId: 'lazylib')),
        same(mine),
      );
    });

    test('a finished download is not active', () {
      final done = _modDownload(
        modId: 'lazylib',
        status: DownloadStatus.completed,
      )..installComplete.value = true;

      expect(
        findActiveDownload([done], DownloadTarget(modId: 'lazylib')),
        isNull,
      );
    });

    test('a downloaded-but-still-installing mod is still active', () {
      final installing = _modDownload(
        modId: 'lazylib',
        status: DownloadStatus.completed,
      );

      expect(
        findActiveDownload([installing], DownloadTarget(modId: 'lazylib')),
        same(installing),
        reason: 'the button should keep spinning while the archive unpacks',
      );
    });

    test('a failed download is not active', () {
      final failed = _modDownload(
        modId: 'lazylib',
        status: DownloadStatus.failed,
      );

      expect(
        findActiveDownload([failed], DownloadTarget(modId: 'lazylib')),
        isNull,
      );
    });

    test('no downloads means nothing to find', () {
      expect(
        findActiveDownload([], DownloadTarget(modId: 'lazylib')),
        isNull,
      );
    });
  });

  group('DownloadTarget as a set key', () {
    test('same clues are the same target', () {
      expect(
        DownloadTarget(modId: 'lazylib', url: 'https://example.com/a.zip'),
        DownloadTarget(modId: 'lazylib', url: 'https://example.com/a.zip'),
      );
    });

    test('a set keeps one entry per target', () {
      final set = {
        DownloadTarget(modId: 'lazylib'),
        DownloadTarget(modId: 'lazylib'),
        DownloadTarget(modId: 'magiclib'),
      };
      expect(set, hasLength(2));
    });

    test('different clues are different targets', () {
      expect(
        DownloadTarget(modId: 'lazylib'),
        isNot(DownloadTarget(modId: 'lazylib', displayName: 'LazyLib')),
      );
    });
  });
}
