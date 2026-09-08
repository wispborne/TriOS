import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:trios/mod_manager/version_checker.dart';
import 'package:trios/utils/http_client.dart';
import 'package:trios/utils/http_probe.dart';
import 'package:trios/utils/public_http_client.dart';

/// Replace only DNS and TCP routing; use the real checked transport and parser.
class _FixtureClient extends TriOSHttpClient {
  final int port;
  _FixtureClient(this.port) : super(config: ApiClientConfig());
  @override
  Future<HttpProbeResult> probe(
    Uri url, {
    required int maxBytes,
    required bool prefixOnly,
    required HttpProbeCancellation cancellation,
    bool? allowSelfSignedCertificates,
  }) async {
    final client = createPublicHttpClient(
      lookup: (_) async => [InternetAddress('8.8.8.8')],
      connect: (address, _) =>
          Socket.startConnect(InternetAddress.loopbackIPv4, port),
    );
    try {
      return await probeHttpUrl(
        url,
        maxBytes: maxBytes,
        prefixOnly: prefixOnly,
        cancellation: cancellation,
        client: client,
      );
    } finally {
      client.close(force: true);
    }
  }
}

void main() {
  test('regular checks reject local addresses before connecting', () async {
    final client = TriOSHttpClient(config: ApiClientConfig());
    addTearDown(() => client.close(force: true));
    for (final url in [
      'http://127.0.0.1/a.version',
      'http://192.168.1.1/a.version',
      'http://[::1]/a.version',
      'http://169.254.169.254/a.version',
    ]) {
      await expectLater(
        fetchRemoteVersionCheckerInfo(url, client),
        throwsFormatException,
      );
    }
  });

  test(
    'regular checks parse JSON-ish files, bound size, and recheck redirects',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      final paths = <String>[];
      server.listen((request) async {
        paths.add(request.uri.path);
        expect(request.headers.contentType, isNull);
        if (request.uri.path == '/redirect.version') {
          request.response.statusCode = 302;
          request.response.headers.set(
            'location',
            'http://127.0.0.1:${server.port}/private',
          );
        } else if (request.uri.path == '/large.version') {
          request.response.write(' ' * (1024 * 1024 + 1));
        } else {
          request.response.headers.contentType = ContentType.json;
          request.response.write(
            '{"modName":"Test", /* allowed comment */ "modVersion":{"major":1,"minor":2,"patch":0},"directDownloadURL":"https://example.com/mod.zip",}',
          );
        }
        try {
          await request.response.close();
        } catch (_) {}
      });
      final client = _FixtureClient(server.port);
      addTearDown(() => client.close(force: true));
      final info = await fetchRemoteVersionCheckerInfo(
        'http://public.test/mod.version',
        client,
      );
      expect(info.directDownloadURL, 'https://example.com/mod.zip');
      await expectLater(
        fetchRemoteVersionCheckerInfo(
          'http://public.test/large.version',
          client,
        ),
        throwsFormatException,
      );
      await expectLater(
        fetchRemoteVersionCheckerInfo(
          'http://public.test/redirect.version',
          client,
        ),
        throwsFormatException,
      );
      expect(paths, ['/mod.version', '/large.version', '/redirect.version']);
      final cancellation = HttpProbeCancellation()..cancel();
      await expectLater(
        fetchRemoteVersionCheckerInfo(
          'http://public.test/mod.version',
          client,
          cancellation: cancellation,
        ),
        throwsA(isA<HttpProbeCancelled>()),
      );
      expect(paths.length, 3);
    },
  );
}
