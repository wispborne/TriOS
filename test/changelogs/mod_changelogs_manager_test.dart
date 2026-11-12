import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trios/mod_manager/version_checker.dart';
import 'package:trios/models/mod.dart';
import 'package:trios/models/mod_info.dart';
import 'package:trios/models/mod_info_json.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/models/version.dart';
import 'package:trios/models/version_checker_info.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/utils/http_client.dart';

import '../riverpod_test_helpers.dart';

/// Stands in for the real version checker, which publishes a new state each
/// time one mod's check finishes.
class _FakeVersionChecks extends VersionCheckerAsyncProvider {
  @override
  Future<VersionCheckerState> build() async => VersionCheckerState({});

  void publish(Map<String, RemoteVersionCheckResult> results) {
    state = AsyncData(VersionCheckerState(Map.of(results)));
  }
}

Mod _mod(String id, String changelogUrl) {
  final info = VersionCheckerInfo(
    masterVersionFile: 'https://example.com/$id.version',
    modVersion: VersionObject('1', '0', '0'),
    changelogURL: changelogUrl,
  );
  final variant = ModVariant(
    modInfo: ModInfo(id: id, name: id, version: Version.parse('1.0.0')),
    versionCheckerInfo: info,
    modFolder: Directory('mods/$id'),
    hasNonBrickedModInfo: true,
    gameCoreFolder: Directory('core'),
  );
  return Mod(id: id, isEnabledInGame: true, modVariants: [variant]);
}

void main() {
  late HttpServer server;
  late TriOSHttpClient client;
  final requestCounts = <String, int>{};
  var responseDelay = Duration.zero;

  setUp(() async {
    requestCounts.clear();
    responseDelay = Duration.zero;
    client = TriOSHttpClient(config: ApiClientConfig());
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      final path = request.uri.path;
      requestCounts[path] = (requestCounts[path] ?? 0) + 1;
      if (path == '/hangs') return; // Never answers.
      await Future.delayed(responseDelay);
      request.response.headers.contentType = ContentType.text;
      request.response.write('Version 1.0.0\n- Changes for $path');
      await request.response.close();
    });
  });

  tearDown(() async {
    client.close(force: true);
    await server.close(force: true);
  });

  ProviderContainer containerFor(List<Mod> mods) => createTestContainer(
    overrides: [
      triOSHttpClient.overrideWithValue(client),
      AppState.mods.overrideWithValue(mods),
      AppState.versionCheckResults.overrideWith(_FakeVersionChecks.new),
    ],
  );

  String urlFor(String path) => 'http://127.0.0.1:${server.port}/$path';

  Future<void> waitForChangelogs(
    ProviderContainer container,
    Iterable<String> modIds,
  ) async {
    final deadline = DateTime.now().add(const Duration(seconds: 5));
    while (DateTime.now().isBefore(deadline)) {
      final loaded = container.read(AppState.changelogsProvider).value ?? {};
      if (modIds.every(loaded.containsKey)) return;
      await Future.delayed(const Duration(milliseconds: 10));
    }
    final loaded = container.read(AppState.changelogsProvider).value ?? {};
    fail('Only these changelogs loaded: ${loaded.keys.toList()}');
  }

  test('each changelog is requested once while version checks come in', () async {
    responseDelay = const Duration(milliseconds: 100);
    final mods = [for (var i = 0; i < 5; i++) _mod('mod$i', urlFor('mod$i'))];
    final container = containerFor(mods);
    container.listen(AppState.changelogsProvider, (_, _) {});
    await container.read(AppState.versionCheckResults.future);

    final checker =
        container.read(AppState.versionCheckResults.notifier)
            as _FakeVersionChecks;
    final results = <String, RemoteVersionCheckResult>{};
    for (final mod in mods) {
      final variant = mod.modVariants.first;
      results[variant.smolId] = RemoteVersionCheckResult(
        variant.versionCheckerInfo,
        variant.versionCheckerInfo,
        'https://example.com/${mod.id}.version',
      );
      checker.publish(results);
      await Future.delayed(const Duration(milliseconds: 20));
    }

    await waitForChangelogs(container, mods.map((m) => m.id));
    // Leave time for any leftover duplicate requests to arrive.
    await Future.delayed(const Duration(milliseconds: 500));

    expect(requestCounts, {for (final m in mods) '/${m.id}': 1});
  });

  test('a server that never answers does not hold up other changelogs', () async {
    final mods = [
      _mod('hangs', urlFor('hangs')),
      _mod('working1', urlFor('working1')),
      _mod('working2', urlFor('working2')),
    ];
    final container = containerFor(mods);
    container.listen(AppState.changelogsProvider, (_, _) {});
    await container.read(AppState.versionCheckResults.future);

    final checker =
        container.read(AppState.versionCheckResults.notifier)
            as _FakeVersionChecks;
    checker.publish({
      for (final mod in mods)
        mod.modVariants.first.smolId: RemoteVersionCheckResult(
          mod.modVariants.first.versionCheckerInfo,
          mod.modVariants.first.versionCheckerInfo,
          'https://example.com/${mod.id}.version',
        ),
    });

    await waitForChangelogs(container, ['working1', 'working2']);
  });
}
