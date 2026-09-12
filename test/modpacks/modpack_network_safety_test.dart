import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:trios/modpacks/models/modpack_definition.dart';
import 'package:trios/modpacks/sharing/modpack_source_validator.dart';
import 'package:trios/utils/http_client.dart';
import 'package:trios/utils/http_probe.dart';
import 'package:trios/utils/public_http_client.dart';

void main() {
  test(
    'guarded HTTPS keeps the hostname while connecting to a checked IP',
    () async {
      final context = SecurityContext()
        ..useCertificateChain('test/fixtures/https/localhost-cert.pem')
        ..usePrivateKey('test/fixtures/https/localhost-key.pem');
      final server = await HttpServer.bindSecure(
        InternetAddress.loopbackIPv4,
        0,
        context,
      );
      addTearDown(() => server.close(force: true));
      server.listen((request) async {
        expect(request.headers.host, 'source.test');
        request.response.add([80, 75, 3, 4]);
        await request.response.close();
      });
      final client = createPublicHttpClient(
        allowSelfSignedCertificates: true,
        lookup: (_) async => [InternetAddress('8.8.8.8')],
        connect: (address, port) {
          expect(address.address, '8.8.8.8');
          expect(port, 443);
          return Socket.startConnect(InternetAddress.loopbackIPv4, server.port);
        },
      );
      addTearDown(() => client.close(force: true));
      final result = await probeHttpUrl(
        Uri.parse('https://source.test/archive'),
        maxBytes: 512,
        prefixOnly: true,
        cancellation: HttpProbeCancellation(),
        client: client,
      );
      expect(result.bytes, [80, 75, 3, 4]);
      expect(result.url.host, 'source.test');
    },
  );

  test('a public client reuses one connection across probes', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    server.listen((request) async {
      request.response.add([80, 75, 3, 4]);
      await request.response.close();
    });
    var connects = 0;
    final client = createPublicHttpClient(
      lookup: (_) async => [InternetAddress('8.8.8.8')],
      connect: (address, port) {
        connects++;
        return Socket.startConnect(InternetAddress.loopbackIPv4, server.port);
      },
    );
    addTearDown(() => client.close(force: true));
    for (var i = 0; i < 8; i++) {
      final result = await probeHttpUrl(
        Uri.parse('http://source.test/archive'),
        maxBytes: 512,
        prefixOnly: false,
        cancellation: HttpProbeCancellation(),
        client: client,
      );
      expect(result.bytes, [80, 75, 3, 4]);
    }
    expect(connects, lessThan(3));
  });

  test('rejects local and private IPv4 and IPv6 destinations', () {
    for (final value in [
      '0.0.0.0',
      '10.1.2.3',
      '127.0.0.2',
      '100.64.0.1',
      '169.254.169.254',
      '172.16.0.1',
      '172.31.255.255',
      '192.168.1.2',
      '224.0.0.1',
      '255.255.255.255',
      '::',
      '::1',
      'fc00::1',
      'fd12::1',
      'fe80::1',
      'ff02::1',
      '::ffff:127.0.0.1',
      '::ffff:192.168.1.1',
      '64:ff9b::a00:1',
      '2002:7f00:1::',
      '2001:0::1',
    ]) {
      expect(isPublicHttpAddress(InternetAddress(value)), false, reason: value);
    }
    for (final value in [
      '8.8.8.8',
      '1.1.1.1',
      '172.32.0.1',
      '2606:4700:4700::1111',
      '::ffff:8.8.8.8',
    ]) {
      expect(isPublicHttpAddress(InternetAddress(value)), true, reason: value);
    }
  });

  test('mixed public and private DNS answers never open a socket', () async {
    var connected = false;
    final client = createPublicHttpClient(
      lookup: (_) async => [
        InternetAddress('8.8.8.8'),
        InternetAddress('10.0.0.1'),
      ],
      connect: (_, _) async {
        connected = true;
        throw StateError('Must not connect');
      },
    );
    addTearDown(() => client.close(force: true));
    await expectLater(
      client.getUrl(Uri.parse('http://source.test')),
      throwsFormatException,
    );
    expect(connected, false);
  });

  test(
    'connects to the checked IP and blocks a redirect to loopback',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      var requests = 0;
      server.listen((request) async {
        requests++;
        expect(request.headers.host, 'source.test');
        request.response.statusCode = 302;
        request.response.headers.set(
          'location',
          'http://127.0.0.1:${server.port}/private',
        );
        await request.response.close();
      });
      var lookups = 0;
      final connected = <String>[];
      final client = createPublicHttpClient(
        lookup: (_) async {
          lookups++;
          return [InternetAddress('8.8.8.8')];
        },
        connect: (address, port) {
          connected.add(address.address);
          // Route the approved address to a local fixture only in this test.
          return Socket.startConnect(InternetAddress.loopbackIPv4, server.port);
        },
      );
      addTearDown(() => client.close(force: true));
      await expectLater(
        probeHttpUrl(
          Uri.parse('http://source.test/archive'),
          maxBytes: 512,
          prefixOnly: true,
          cancellation: HttpProbeCancellation(),
          client: client,
        ),
        throwsFormatException,
      );
      expect(lookups, 1);
      expect(connected, ['8.8.8.8']);
      expect(requests, 1);
    },
  );

  test(
    'production validation blocks local version files and archives',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      var requests = 0;
      server.listen((request) {
        requests++;
        request.response.close();
      });
      final client = TriOSHttpClient(config: ApiClientConfig());
      addTearDown(() => client.close(force: true));
      for (final type in ModpackItemSourceType.values) {
        await expectLater(
          ModpackSourceValidator.forClient(client).validate(
            ModpackItem(
              modId: 'mod',
              url: 'http://127.0.0.1:${server.port}/source',
              sourceType: type,
            ),
            HttpProbeCancellation(),
          ),
          throwsFormatException,
        );
      }
      expect(requests, 0);
    },
  );

  test(
    'a stalled probe times out instead of holding the request open',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      server.listen((_) {});
      final client = HttpClient();
      addTearDown(() => client.close(force: true));
      await expectLater(
        probeHttpUrl(
          Uri.parse('http://127.0.0.1:${server.port}/stall'),
          maxBytes: 512,
          prefixOnly: false,
          cancellation: HttpProbeCancellation(),
          client: client,
          timeout: const Duration(milliseconds: 100),
        ),
        throwsA(isA<TimeoutException>()),
      );
    },
  );

  test('cancelling during the connect stops waiting on it', () async {
    // The lookup never answers, standing in for a slow DNS or TCP connect.
    final stuck = Completer<List<InternetAddress>>();
    final client = createPublicHttpClient(
      lookup: (_) => stuck.future,
      connect: (_, _) => fail('The connect should not be reached.'),
    );
    addTearDown(() {
      client.close(force: true);
      if (!stuck.isCompleted) stuck.complete([InternetAddress('8.8.8.8')]);
    });
    final cancellation = HttpProbeCancellation();
    final probe = probeHttpUrl(
      Uri.parse('https://source.test/archive'),
      maxBytes: 512,
      prefixOnly: true,
      cancellation: cancellation,
      client: client,
    );
    await Future<void>.delayed(Duration.zero);
    cancellation.cancel();

    // Without giving up on the connect, this would hold its slot in the
    // client's request queue until the probe's own 20 second timeout.
    await expectLater(
      probe.timeout(const Duration(seconds: 2)),
      throwsA(isA<HttpProbeCancelled>()),
    );
    expect(stuck.isCompleted, isFalse);
  });
}
