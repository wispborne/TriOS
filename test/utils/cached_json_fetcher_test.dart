import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/utils/cached_json_fetcher.dart';

void main() {
  setUpAll(() {
    Constants.configDataFolderPath = Directory.systemTemp.createTempSync(
      'trios_cached_json_fetcher_test',
    );
  });

  CachedJsonFetcher makeFetcher(MockClient client) => CachedJsonFetcher(
    cacheFileName: 'fetcher_test.json',
    metaFileName: 'fetcher_test.meta',
    url: 'https://example.com/file.json',
    maxAge: Duration(hours: 6),
    logTag: 'fetcher test',
    client: client,
  );

  final notFound = MockClient(
    (_) async => http.Response('404: Not Found', 404),
  );

  setUp(() => makeFetcher(notFound).clearCache());

  test('a 404 reply is not saved, and the saved copy is returned', () async {
    final ok = makeFetcher(MockClient((_) async => http.Response('{"a":1}', 200)));
    await ok.fetch();

    final failing = makeFetcher(notFound);
    final body = await failing.fetch(bypassCache: true);

    expect(body, '{"a":1}');
    expect(File(failing.cacheFilePath).readAsStringSync(), '{"a":1}');
  });

  test('a 404 reply with no saved copy throws and saves nothing', () async {
    final failing = makeFetcher(notFound);

    await expectLater(failing.fetch(), throwsA(isA<HttpException>()));
    expect(File(failing.cacheFilePath).existsSync(), isFalse);
    expect(failing.getCacheTimestamp(), isNull);
  });
}
