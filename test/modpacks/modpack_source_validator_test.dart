import 'package:trios/models/version_checker_info.dart';

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trios/modpacks/models/modpack_definition.dart';
import 'package:trios/modpacks/sharing/modpack_share_controller.dart';
import 'package:trios/modpacks/sharing/modpack_source_validator.dart';
import 'package:trios/utils/http_probe.dart';

const item = ModpackItem(
  modId: 'test',
  url: 'https://example.com/mod.zip',
  sourceType: ModpackItemSourceType.directDownload,
);
HttpProbeResult archive(Uri url) =>
    HttpProbeResult(url, [0x50, 0x4b, 3, 4], 'application/zip');

ModpackSourceValidator _validator(
  HttpProbe probe, {
  DateTime Function()? now,
  Future<VersionCheckerInfo> Function(String, HttpProbeCancellation)?
  fetchVersionInfo,
}) => ModpackSourceValidator(
  probe,
  now: now,
  fetchVersionInfo:
      fetchVersionInfo ??
      (url, _) async =>
          throw StateError('Unexpected Version Checker fetch: $url'),
);

void main() {
  test(
    'successful checks cache exact source and type for only 60 minutes',
    () async {
      var time = DateTime(2026);
      final calls = <Uri>[];
      final validator = _validator(
        (
          url, {
          required maxBytes,
          required prefixOnly,
          required cancellation,
        }) async {
          calls.add(url);
          return prefixOnly
              ? archive(url)
              : HttpProbeResult(
                  url,
                  utf8.encode(
                    '{"DirectDownloadUrl":" https://example.com/archive.zip "}',
                  ),
                  'text/plain',
                );
        },
        now: () => time,
        fetchVersionInfo: (url, _) async {
          calls.add(Uri.parse(url));
          return VersionCheckerInfo(
            directDownloadURL: ' https://example.com/archive.zip ',
          );
        },
      );
      final token = HttpProbeCancellation();
      expect(await validator.validate(item, token), false);
      expect(await validator.validate(item, token), true);
      expect(calls.length, 1);
      await validator.validate(
        item.copyWith(url: '${item.url}?changed'),
        token,
      );
      await validator.validate(
        item.copyWith(sourceType: ModpackItemSourceType.versionFile),
        token,
      );
      expect(calls.length, 4);
      time = time.add(const Duration(minutes: 60));
      expect(await validator.validate(item, token), false);
      expect(calls.length, 5);
    },
  );

  test(
    'failed responses retry and version files must resolve to archives',
    () async {
      var valid = false;
      var calls = 0;
      final validator = _validator((
        url, {
        required maxBytes,
        required prefixOnly,
        required cancellation,
      }) async {
        calls++;
        return valid
            ? archive(url)
            : HttpProbeResult(
                url,
                utf8.encode('<html>Sign in</html>'),
                'application/octet-stream',
              );
      }, fetchVersionInfo: (_, _) async => VersionCheckerInfo());
      final token = HttpProbeCancellation();
      await expectLater(validator.validate(item, token), throwsFormatException);
      valid = true;
      expect(await validator.validate(item, token), false);
      expect(calls, 2);
      await expectLater(
        validator.validate(
          item.copyWith(sourceType: ModpackItemSourceType.versionFile),
          token,
        ),
        throwsA(isA<Exception>()),
      );
    },
  );

  test(
    'controller checks all items, retries failures and never checks update URL',
    () async {
      final calls = <Uri>[];
      var fail = true;
      final validator = _validator((
        url, {
        required maxBytes,
        required prefixOnly,
        required cancellation,
      }) async {
        calls.add(url);
        if (fail && url.path == '/bad.zip') {
          throw const FormatException('Unavailable');
        }
        return archive(url);
      });
      final container = ProviderContainer(
        overrides: [
          modpackSourceValidatorProvider.overrideWithValue(validator),
        ],
      );
      addTearDown(container.dispose);
      final provider = modpackShareControllerProvider('pack');
      final sub = container.listen(provider, (_, _) {});
      addTearDown(sub.close);
      final pack = ModpackDefinition(
        id: '0123456789abcdefghijkl',
        name: 'Pack',
        version: 1,
        updateUrl: 'https://unreachable.invalid/update',
        items: [
          item,
          item.copyWith(modId: 'bad', url: 'https://example.com/bad.zip'),
        ],
      );
      final controller = container.read(provider.notifier);
      expect(await controller.validate(pack), false);
      expect(container.read(provider).checks.map((c) => c.status), [
        ModpackSourceCheckStatus.passed,
        ModpackSourceCheckStatus.failed,
      ]);
      fail = false;
      expect(await controller.validate(pack), true);
      expect(calls.map((u) => u.path), ['/mod.zip', '/bad.zip', '/bad.zip']);
    },
  );

  test('cancelling validation prevents completion and caching', () async {
    final pending = Completer<HttpProbeResult>();
    final validator = _validator(
      (url, {required maxBytes, required prefixOnly, required cancellation}) =>
          pending.future,
    );
    final token = HttpProbeCancellation();
    final check = validator.validate(item, token);
    token.cancel();
    pending.complete(archive(Uri.parse(item.url)));
    await expectLater(check, throwsA(isA<HttpProbeCancelled>()));
  });

  test('HTTP probes stop after an archive prefix and bound metadata', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    server.listen((request) async {
      if (request.uri.path == '/redirect') {
        request.response.statusCode = 302;
        request.response.headers.set('location', '/archive');
        await request.response.close();
      } else {
        request.response.add(List.filled(4096, 80));
        await request.response.close();
      }
    });
    final client = HttpClient();
    addTearDown(() => client.close(force: true));
    final url = Uri.parse('http://127.0.0.1:${server.port}/redirect');
    final result = await probeHttpUrl(
      url,
      maxBytes: 512,
      prefixOnly: true,
      cancellation: HttpProbeCancellation(),
      client: client,
    );
    expect(result.bytes.length, lessThanOrEqualTo(512));
    expect(result.url.path, '/archive');
    await expectLater(
      probeHttpUrl(
        url,
        maxBytes: 512,
        prefixOnly: false,
        cancellation: HttpProbeCancellation(),
        client: client,
      ),
      throwsFormatException,
    );
  });
}
