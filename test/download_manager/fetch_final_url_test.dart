import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:trios/trios/download_manager/downloader.dart';
import 'package:trios/utils/http_client.dart';

/// Finding out what's at a link must not download the file. The body of a big
/// mod is sent over and over otherwise, before the real download even starts.
void main() {
  late HttpServer server;
  late TriOSHttpClient client;

  setUp(() async {
    client = TriOSHttpClient(config: ApiClientConfig());
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    // Starts sending a file and never finishes, so anything that waits for the
    // whole file doesn't return. It also ignores Range headers, like some mod
    // hosts do.
    server.listen((request) async {
      if (request.uri.path == '/redirect') {
        await request.response.redirect(
          Uri.parse('http://127.0.0.1:${server.port}/mod.zip'),
        );
        return;
      }
      if (request.uri.path == '/folder/relative-redirect') {
        await request.response.redirect(Uri.parse('second-redirect'));
        return;
      }
      if (request.uri.path == '/folder/second-redirect') {
        await request.response.redirect(Uri.parse('/mod.zip'));
        return;
      }
      if (request.uri.path == '/meta-refresh') {
        request.response.headers.contentType = ContentType.html;
        request.response.write(
          '<html><head>'
          '<meta http-equiv="refresh" content="0; url=/mod.zip">'
          '</head></html>',
        );
        await request.response.close();
        return;
      }
      if (request.uri.path == '/complete.zip') {
        request.response.headers.contentType = ContentType(
          'application',
          'zip',
        );
        request.response.add(List.filled(_completeFileSize, 7));
        await request.response.close();
        return;
      }
      request.response.headers.contentType = ContentType('application', 'zip');
      request.response.headers.set(
        'content-disposition',
        'attachment; filename="mod.zip"',
      );
      request.response.add(List.filled(1024, 0));
      request.response.flush();
    });
  });

  tearDown(() async {
    client.close(force: true);
    await server.close(force: true);
  });

  test('looking up a file link does not download the file', () async {
    final result =
        await DownloadManager.fetchFinalUrlAndHeaders(
          'http://127.0.0.1:${server.port}/mod.zip',
          client,
        ).timeout(
          const Duration(seconds: 3),
          onTimeout: () => fail('The lookup waited for the whole file.'),
        );

    expect(result.headersMap['content-type'], 'application/zip');
    expect(result.headersMap['content-disposition'], contains('mod.zip'));
  });

  test('follows a redirect to the file', () async {
    final result = await DownloadManager.fetchFinalUrlAndHeaders(
      'http://127.0.0.1:${server.port}/redirect',
      client,
    ).timeout(const Duration(seconds: 3));

    expect(Uri.parse(result.url).path, '/mod.zip');
    expect(result.headersMap['content-disposition'], contains('mod.zip'));
  });

  test('follows redirects that give a relative address', () async {
    final result = await DownloadManager.fetchFinalUrlAndHeaders(
      'http://127.0.0.1:${server.port}/folder/relative-redirect',
      client,
    ).timeout(const Duration(seconds: 3));

    expect(result.url, 'http://127.0.0.1:${server.port}/mod.zip');
  });

  test('still reads web pages, so it can follow a meta refresh', () async {
    final result = await DownloadManager.fetchFinalUrlAndHeaders(
      'http://127.0.0.1:${server.port}/meta-refresh',
      client,
    ).timeout(const Duration(seconds: 3));

    expect(Uri.parse(result.url).path, '/mod.zip');
    expect(result.headersMap['content-type'], 'application/zip');
  });

  test('the real download still gets the whole file after a lookup', () async {
    final url = 'http://127.0.0.1:${server.port}/complete.zip';

    await DownloadManager.fetchFinalUrlAndHeaders(url, client);
    final response = await client.get(url);

    expect(response.data, hasLength(_completeFileSize));
  });
}

const _completeFileSize = 2 * 1024 * 1024;
