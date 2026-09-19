import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:trios/utils/http_archive_download.dart';

void main() {
  late HttpServer server;
  late HttpClient client;
  late Directory directory;
  late Uri base;
  setUp(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    client = HttpClient();
    directory = await Directory.systemTemp.createTemp('archive-stream-test');
    base = Uri.parse('http://127.0.0.1:${server.port}');
    server.listen((request) async {
      if (request.uri.path == '/redirect') {
        request.response.statusCode = 302;
        request.response.headers.set('location', '/archive');
      } else if (request.uri.path == '/loop') {
        request.response.statusCode = 302;
        request.response.headers.set('location', '/loop');
      } else if (request.uri.path == '/failure') {
        request.response.statusCode = 403;
      } else {
        request.response.add([0x50, 0x4b, 1, 2, 3, 4]);
      }
      await request.response.close();
    });
  });
  tearDown(() async {
    client.close(force: true);
    await server.close(force: true);
    await directory.delete(recursive: true);
  });
  test('streams the response and returns the final redirect address', () async {
    final file = File('${directory.path}/mod.zip');
    var received = 0;
    final finalUrl = await downloadHttpArchive(
      client,
      base.resolve('/redirect'),
      file,
      onProgress: (bytes, _) => received = bytes,
    );
    expect(finalUrl, base.resolve('/archive'));
    expect(await file.readAsBytes(), [0x50, 0x4b, 1, 2, 3, 4]);
    expect(received, 6);
  });
  test('rejects an oversized streamed response', () async {
    await expectLater(
      downloadHttpArchive(
        client,
        base.resolve('/archive'),
        File('${directory.path}/mod.zip'),
        maxBytes: 3,
        onProgress: (_, _) {},
      ),
      throwsFormatException,
    );
  });
  test('rejects failed responses and bounds redirect loops', () async {
    await expectLater(
      downloadHttpArchive(
        client,
        base.resolve('/failure'),
        File('${directory.path}/failed.zip'),
        onProgress: (_, _) {},
      ),
      throwsA(isA<HttpException>()),
    );
    await expectLater(
      downloadHttpArchive(
        client,
        base.resolve('/loop'),
        File('${directory.path}/loop.zip'),
        onProgress: (_, _) {},
      ),
      throwsFormatException,
    );
  });
}
