import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:trios/utils/http_client.dart';

/// These run against a real socket on this machine, because the problems they
/// cover only exist at the level of connections and response streams.
void main() {
  late TriOSHttpClient client;
  late ServerSocket server;
  final accepted = <Socket>[];

  setUp(() async {
    client = TriOSHttpClient(config: ApiClientConfig());
    server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    accepted.clear();
  });

  tearDown(() async {
    client.close(force: true);
    for (final socket in accepted) {
      socket.destroy();
    }
    await server.close();
  });

  String url() => 'http://127.0.0.1:${server.port}/file';

  /// Fails with a clear message instead of leaving the test hanging.
  Future<Object?> errorFrom(Future<Object?> request) => request
      .then<Object?>((_) => null, onError: (Object e) => e)
      .timeout(
        const Duration(seconds: 3),
        onTimeout: () => fail('The request never finished.'),
      );

  test('gives up when a server accepts the connection but never replies', () async {
    server.listen((socket) {
      accepted.add(socket);
      socket.listen((_) {});
    });

    final error = await errorFrom(
      client.get(url(), timeout: const Duration(milliseconds: 200), tries: 1),
    );

    expect(error, isNotNull);
  });

  test('closes the connection when a download stalls partway through', () async {
    final closedByClient = Completer<void>();
    server.listen((socket) {
      accepted.add(socket);
      socket.listen(
        (_) {
          socket.write(
            'HTTP/1.1 200 OK\r\n'
            'Content-Type: application/zip\r\n'
            'Content-Length: 1000\r\n\r\n'
            'partial',
          );
        },
        onDone: () {
          if (!closedByClient.isCompleted) closedByClient.complete();
        },
      );
    });

    final error = await errorFrom(
      client.get(url(), timeout: const Duration(milliseconds: 200), tries: 1),
    );
    expect(error, isNotNull);

    await closedByClient.future.timeout(
      const Duration(seconds: 2),
      onTimeout: () => fail('The stalled connection was left open.'),
    );
  });

  group('skipFileBody', () {
    /// Answers every request with [response] and leaves the connection open.
    /// Completes [closedByClient] when the client hangs up.
    Completer<void> serve(List<int> response) {
      final closedByClient = Completer<void>();
      server.listen((socket) {
        accepted.add(socket);
        socket.listen(
          (_) => socket.add(response),
          onDone: () {
            if (!closedByClient.isCompleted) closedByClient.complete();
          },
        );
      });
      return closedByClient;
    }

    List<int> headers(String lines) => '$lines\r\n\r\n'.codeUnits;

    Future<TriOSHttpResponse<dynamic>> lookup() => client
        .get(url(), skipFileBody: true)
        .timeout(
          const Duration(seconds: 3),
          onTimeout: () => fail('The lookup never finished.'),
        );

    test('handles an empty file', () async {
      serve(
        headers(
          'HTTP/1.1 200 OK\r\n'
          'Content-Type: application/zip\r\n'
          'Content-Length: 0',
        ),
      );

      final response = await lookup();

      expect(response.statusCode, 200);
      expect(response.data, isEmpty);
    });

    test('hangs up on a compressed file', () async {
      final closedByClient = serve([
        ...headers(
          'HTTP/1.1 200 OK\r\n'
          'Content-Type: application/zip\r\n'
          'Content-Encoding: gzip\r\n'
          'Content-Length: 1000',
        ),
        ...gzip.encode([1, 2, 3]).take(5),
      ]);

      final response = await lookup();
      expect(response.data, isEmpty);

      await closedByClient.future.timeout(
        const Duration(seconds: 2),
        onTimeout: () => fail('The connection was left open.'),
      );
    });

    test('still reads text', () async {
      serve([
        ...headers(
          'HTTP/1.1 200 OK\r\n'
          'Content-Type: text/html\r\n'
          'Content-Length: 5',
        ),
        ...'hello'.codeUnits,
      ]);

      expect((await lookup()).data, 'hello');
    });

    test('keeps the status of an error response', () async {
      serve(
        headers(
          'HTTP/1.1 404 Not Found\r\n'
          'Content-Type: application/zip\r\n'
          'Content-Length: 1000',
        ),
      );

      expect((await lookup()).statusCode, 404);
    });

    test('hang-ups do not use up the connections to a host', () async {
      serve(
        headers(
          'HTTP/1.1 200 OK\r\n'
          'Content-Type: application/zip\r\n'
          'Content-Length: 1000',
        ),
      );

      // More lookups than the 10 connections allowed per host.
      for (var i = 0; i < 25; i++) {
        await lookup();
      }
    });
  });
}
