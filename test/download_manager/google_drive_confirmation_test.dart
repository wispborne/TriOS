import 'package:flutter_test/flutter_test.dart';
import 'package:trios/trios/download_manager/downloader.dart';

/// Regression test for large Google Drive downloads failing as
/// "Not a supported archive format".
///
/// Files too large for Google to virus-scan aren't served directly; Google
/// returns an HTML "Virus scan warning" page with a hidden form. That form
/// carries a `uuid` token that the plain `…&confirm=t` link is missing, so
/// without following the form we saved the warning page as the "archive".
void main() {
  // Trimmed copy of the real warning page for the sample file.
  const warningPageHtml = '''
<!DOCTYPE html><html><head><title>Google Drive - Virus scan warning</title></head>
<body><div class="uc-main"><div id="uc-text">
<p class="uc-warning-caption">Google Drive can't scan this file for viruses.</p>
<p class="uc-warning-subcaption"><span class="uc-name-size">
<a href="/open?id=ABC123">crabshack.zip</a> (37M)</span> is too large for Google to scan for viruses. Would you still like to download this file?</p>
<form id="download-form" action="https://drive.usercontent.google.com/download" method="get">
<input type="submit" id="uc-download-link" value="Download anyway"/>
<input type="hidden" name="id" value="ABC123">
<input type="hidden" name="export" value="download">
<input type="hidden" name="authuser" value="0">
<input type="hidden" name="confirm" value="t">
<input type="hidden" name="uuid" value="the-uuid-token">
</form></div></div></body></html>''';

  test('follows the virus-scan form to the real download URL', () {
    final result = DownloadManager.resolveGoogleDriveConfirmation(
      warningPageHtml,
      'https://drive.usercontent.google.com/download?id=ABC123&export=download&authuser=0',
    );

    expect(result, isNotNull);
    final uri = Uri.parse(result!.url);
    // The whole point: the `uuid` token the plain confirm link lacked is now present.
    expect(uri.queryParameters['uuid'], 'the-uuid-token');
    expect(uri.queryParameters['confirm'], 't');
    expect(uri.queryParameters['id'], 'ABC123');
    expect(uri.host, 'drive.usercontent.google.com');
  });

  test('keeps the file name (and archive extension) from the page', () {
    final result = DownloadManager.resolveGoogleDriveConfirmation(
      warningPageHtml,
      'https://drive.usercontent.google.com/download?id=ABC123',
    );

    expect(
      result!.headersMap['content-disposition'],
      contains('crabshack.zip'),
      reason: 'The saved file must keep its .zip extension so the installer '
          'does not reject it as "Not a supported archive format".',
    );
  });

  test('returns null for a page that is not the virus-scan form', () {
    final result = DownloadManager.resolveGoogleDriveConfirmation(
      '<html><body>Just a normal page.</body></html>',
      'https://drive.usercontent.google.com/',
    );

    expect(result, isNull);
  });
}
