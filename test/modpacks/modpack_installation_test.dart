import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trios/modpacks/full_page/modpack_item_row_data.dart';
import 'package:trios/modpacks/installation/modpack_installation.dart';
import 'package:trios/modpacks/models/modpack_definition.dart';
import 'package:trios/modpacks/models/modpack_library_entry.dart';
import 'package:trios/modpacks/modpack_error_text.dart';
import 'package:trios/utils/fair_work_queue.dart';

ModpackInstallPlan plan(String id, List<String> mods) {
  final items = [
    for (final mod in mods)
      ModpackItem(
        modId: mod,
        url: 'https://example.org/$mod.zip',
        sourceType: ModpackItemSourceType.directDownload,
        label: 'Core',
      ),
  ];
  final entry = ModpackLibraryEntry(
    definition: ModpackDefinition(id: id, name: id, version: 1, items: items),
  );
  return ModpackInstallPlan(entry, [
    for (final item in items)
      ModpackInstallChoice(
        ModpackItemRowData(
          item: item,
          packOrder: items.indexOf(item),
          installedMod: null,
        ),
        downloadUrl: item.url,
      ),
  ]);
}

class TestInstaller extends ModpackInstallationManager {
  final gate = FairWorkQueue(() => 2);
  final active = <String, Completer<void>>{};
  final failures = <String>[];
  final successes = <String>[];
  final enabled = <String>[];
  final started = <String>[];
  bool storageFails = false;
  @override
  void checkCanInstall() {}
  @override
  void checkSaved(ModpackLibraryEntry entry) {}
  @override
  Future<void> recordFailure(
    String packId,
    ModpackItem item,
    String error,
  ) async {
    failures.add(item.modId);
  }

  @override
  Future<void> clearFailure(String packId, String id) async {
    if (storageFails) throw StateError("Cannot write library");
    successes.add(id);
  }

  @override
  Future<void> enableInstalled(ModpackDefinition definition) async {
    enabled.add(definition.id);
  }

  @override
  Future<ModpackItemInstallResult> installItem(
    ModpackInstallRun run,
    ModpackInstallChoice choice,
    void Function(ModpackItemInstallResult) report,
  ) => gate.run(run.packId, () async {
    if (run.stopping) return const ModpackItemInstallResult(.skipped);
    final id = choice.row.key;
    started.add(id);
    final done = active[id] = Completer<void>();
    report(const ModpackItemInstallResult(.downloading));
    await done.future;
    if (id == 'broken') throw StateError('Wrong mod ID');
    if (id == 'blocked') {
      throw const ModpackInstallBlocked('Close Starsector first.');
    }
    return const ModpackItemInstallResult(.installed);
  });
}

void main() {
  late ProviderContainer container;
  late TestInstaller installer;
  setUp(() {
    installer = TestInstaller();
    container = ProviderContainer(
      overrides: [modpackInstallationProvider.overrideWith(() => installer)],
    );
    container.read(modpackInstallationProvider);
  });
  tearDown(() => container.dispose());

  test(
    'every Core item can be unchecked and selection remains in pack order',
    () async {
      final prepared = plan('pack', ['first', 'second']);
      expect(prepared.defaultSelection, {'first', 'second'});
      final run = installer.start(prepared, {'second'});
      expect(installer.started, ['second']);
      installer.active['second']!.complete();
      await run.settled;
      expect(installer.successes, ['second']);
      expect(installer.enabled, isEmpty);
    },
  );

  test(
    'same pack reuses its run while other packs can run concurrently',
    () async {
      final first = installer.start(plan('one', ['a']), {'a'});
      expect(
        identical(first, installer.start(plan('one', ['b']), {'b'})),
        isTrue,
      );
      final second = installer.start(plan('two', ['b']), {'b'});
      expect(installer.started, ['a', 'b']);
      for (final c in installer.active.values) {
        c.complete();
      }
      await Future.wait([first.settled, second.settled]);
    },
  );

  test('stop finishes active work, skips waiting items, does not enable and forgets attempt', () async {
    final prepared = plan('pack', ['a', 'b', 'c']);
    final run = installer.start(prepared, {
      'a',
      'b',
      'c',
    }, enableAfterInstallation: true);
    installer.stop('pack');
    expect(run.complete, isFalse);
    for (final c in installer.active.values) {
      c.complete();
    }
    await run.settled;
    expect(installer.started, ['a', 'b']);
    expect(run.results['c']!.status, ModpackItemInstallStatus.skipped);
    expect(installer.successes, containsAll(['a', 'b']));
    expect(installer.failures, isEmpty);
    expect(installer.enabled, isEmpty);
    expect(container.read(modpackInstallationProvider), isEmpty);
    final next = installer.start(prepared, {'c'});
    expect(identical(next, run), isFalse);
    installer.active['c']!.complete();
    await next.settled;
  });

  test(
    'partial failure retains successes and runs requested normal enabling',
    () async {
      final run = installer.start(plan('pack', ['a', 'broken']), {
        'a',
        'broken',
      }, enableAfterInstallation: true);
      for (final c in installer.active.values) {
        c.complete();
      }
      await run.settled;
      expect(installer.successes, ['a']);
      expect(installer.failures, ['broken']);
      expect(installer.enabled, ['pack']);
      expect(run.results['broken']!.status, ModpackItemInstallStatus.failed);
    },
  );

  test(
    'an item blocked by the game being open is skipped, not failed',
    () async {
      final run = installer.start(plan('pack', ['blocked']), {'blocked'});
      installer.active['blocked']!.complete();
      await run.settled;
      expect(run.results['blocked']!.status, ModpackItemInstallStatus.skipped);
      expect(run.results['blocked']!.text, 'Close Starsector first.');
      expect(installer.failures, isEmpty);
    },
  );

  test('failure text has no Dart type name in front', () async {
    final run = installer.start(plan('pack', ['broken']), {'broken'});
    installer.active['broken']!.complete();
    await run.settled;
    expect(run.results['broken']!.text, 'Wrong mod ID');
  });

  test('a failure to persist results does not turn an installed item into a failed install', () async {
    installer.storageFails = true;
    final run = installer.start(plan('pack', ['a']), {'a'});
    installer.active['a']!.complete();
    await run.settled;
    expect(run.results['a']!.status, ModpackItemInstallStatus.installed);
    expect(run.error, contains('Could not save installation result'));
    expect(installer.failures, isEmpty);
  });

  test('unknown selection is rejected before any work starts', () {
    expect(
      () => installer.start(plan('pack', ['a']), {'other'}),
      throwsArgumentError,
    );
    expect(installer.started, isEmpty);
  });
}
