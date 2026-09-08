import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:trios/mod_manager/version_checker.dart';
import 'package:trios/modpacks/models/modpack_definition.dart';
import 'package:trios/modpacks/sharing/modpack_source_validator.dart';
import 'package:trios/utils/http_client.dart';
import 'package:trios/utils/http_probe.dart';

void main() {
  test('source checks use the regular Version Checker over HTTPS', () async {
    final context = SecurityContext()
      ..useCertificateChain('test/fixtures/https/localhost-cert.pem')
      ..usePrivateKey('test/fixtures/https/localhost-key.pem');
    final server = await HttpServer.bindSecure(
      InternetAddress.loopbackIPv4,
      0,
      context,
    );
    addTearDown(() => server.close(force: true));
    final origin = 'https://127.0.0.1:${server.port}';
    final client = TriOSHttpClient(
      config: ApiClientConfig(),
      allowInsecureConnectionsByDefault: true,
    );
    addTearDown(() => client.close(force: true));
    final paths = <String>[];
    server.listen((request) async {
      paths.add(request.uri.path);
      expect(request.headers.contentType, isNull);
      if (request.uri.path == '/mod.version') {
        request.response.headers.contentType = ContentType.text;
        request.response.write('''{
          // The same JSON-ish syntax supported by the regular checker.
          "modName": "Test mod",
          "directDownloadURL": "$origin/download",
          "modVersion": {"major": 1, "minor": 0, "patch": 0},
        }''');
      } else if (request.uri.path == '/download') {
        request.response.statusCode = 302;
        request.response.headers.set('location', '/archive');
      } else {
        expect(request.headers.value('range'), 'bytes=0-511');
        request.response.headers.contentType = ContentType(
          'application',
          'zip',
        );
        request.response.add([80, 75, 3, 4, ...List.filled(4096, 0)]);
      }
      await request.response.close();
    });
    final regular = await fetchRemoteVersionCheckerInfo(
      '$origin/mod.version',
      client,
    );
    expect(regular.directDownloadURL, '$origin/download');
    final validator = ModpackSourceValidator.forClient(client);
    expect(
      await validator.validate(
        ModpackItem(
          modId: 'test',
          url: '$origin/mod.version',
          sourceType: ModpackItemSourceType.versionFile,
        ),
        HttpProbeCancellation(),
      ),
      false,
    );
    expect(paths, ['/mod.version', '/mod.version', '/download', '/archive']);
  });

  test(
    'reported public sources resolve through the production sharing path',
    () async {
      final client = TriOSHttpClient(config: ApiClientConfig());
      addTearDown(() => client.close(force: true));
      final validator = ModpackSourceValidator.forClient(client);
      final urls = [
        'https://raw.githubusercontent.com/LazyWizard/lazylib/master/mod/lazylib.version',
        'https://raw.githubusercontent.com/MagicLibStarsector/MagicLib/master/magiclib.version',
        'https://raw.githubusercontent.com/Lukas22041/LunaLib/main/LunaLib.version',
        'https://bitbucket.org/DarkRevenant/graphicslib/downloads/graphicsLib.version',
        'https://raw.githubusercontent.com/Dal-041/Knights_of_Ludd/master/kol.version',
      ];
      for (var i = 0; i < urls.length; i++) {
        expect(
          await validator.validate(
            ModpackItem(
              modId: 'mod-$i',
              url: urls[i],
              sourceType: ModpackItemSourceType.versionFile,
            ),
            HttpProbeCancellation(),
          ),
          false,
          reason: urls[i],
        );
      }
    },
    skip: !const bool.fromEnvironment('LIVE_SOURCE_CHECKS'),
  );
}
