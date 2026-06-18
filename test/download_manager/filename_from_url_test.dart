import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/trios/download_manager/downloader.dart';

/// Regression test for the "Not a supported archive format" download bug.
///
/// The download filename is taken from the `Content-Disposition` header; the
/// header map is built with lowercase keys (HttpHeaders normalizes names), so a
/// capitalized lookup silently missed it and fell back to the URL path. For
/// download URLs that have no extension in their path (Dropbox/Drive/forum
/// links), that fallback produced a name with no archive extension, which the
/// batch installer rejects as "Not a supported archive format".
void main() {
  late DownloadManager downloadManager;

  setUp(() {
    // The real provider; fetchFileNameFromUrl does no network/ref work.
    downloadManager = ProviderContainer().read(downloadManagerInstance);
  });

  bool isSupportedArchive(String name) => Constants.supportedArchiveExtensions
      .any((ext) => name.toLowerCase().endsWith(ext));

  test(
    'uses Content-Disposition filename when the URL path has no extension',
    () async {
      // Dropbox-style URL: no filename/extension in the path at all.
      const url = 'https://www.dropbox.com/scl/fi/abc123/?rlkey=xyz&dl=1';
      final name = await downloadManager.fetchFileNameFromUrl(url, {
        'content-disposition': 'attachment; filename="NSP.zip"',
      });

      expect(name, 'NSP.zip');
      expect(
        isSupportedArchive(name),
        isTrue,
        reason: 'Filename must end in a supported archive extension so the '
            'installer does not reject it as "Not a supported archive format".',
      );
    },
  );

  test('parses the RFC 5987 filename* form', () async {
    const url = 'https://drive.google.com/uc?export=download&id=ABC';
    final name = await downloadManager.fetchFileNameFromUrl(url, {
      'content-disposition':
          "attachment; filename*=UTF-8''NSP%20Pack%203.0.5.8.zip",
    });

    expect(name, 'NSP Pack 3.0.5.8.zip');
    expect(isSupportedArchive(name), isTrue);
  });

  test(
    'falls back to the URL filename when there is no Content-Disposition',
    () async {
      const url =
          'https://github.com/NEONN1111/NSP2/releases/download/3.0.5.8/NSP.zip';
      final name = await downloadManager.fetchFileNameFromUrl(url, {});

      expect(name, 'NSP.zip');
      expect(isSupportedArchive(name), isTrue);
    },
  );
}
