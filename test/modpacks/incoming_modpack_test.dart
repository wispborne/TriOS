import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trios/modpacks/incoming/incoming_modpack.dart';
import 'package:trios/modpacks/models/modpack_definition.dart';
import 'package:trios/modpacks/models/modpack_draft.dart';
import 'package:trios/modpacks/models/modpack_library_entry.dart';
import 'package:trios/modpacks/modpack_format.dart';
import 'package:trios/modpacks/modpack_link_codec.dart';
import 'package:trios/modpacks/modpack_store.dart';
import 'package:trios/trios/deep_link/single_instance_manager.dart';

const incomingPack = ModpackDefinition(
  id: 'N3qGd6c8R2mVx1ZaYkW0_A',
  name: 'Incoming pack',
  version: 3,
  updateUrl: 'https://example.com/pack.trios-modpack',
  items: [
    ModpackItem(
      modId: 'alpha',
      name: 'Alpha',
      label: 'Core',
      url: 'https://example.com/alpha.zip',
      sourceType: ModpackItemSourceType.directDownload,
    ),
  ],
  unknownFields: {
    'future': {'value': 5},
  },
);

void main() {
  test(
    'readable files accept Hjson without changing strings or unknown data',
    () {
      final pack = decodeModpackFileBytes(
        utf8.encode("""
      # Hjson allows omitted root braces and newline separators.
      formatVersion: 1
      id: N3qGd6c8R2mVx1ZaYkW0_A
      name: My pack, with commas # literal text
      version: 3 # comment on a number
      description:
        '''
        First line.
        Second line.
        '''
      items: [
        {
          id: alpha
          url: https://example.com/file.zip
          sourceType: directDownload
          label: Core
        }
      ]
      future: {enabled: true, values: [1, 2, 3]}
      """),
      );
      expect(pack.name, 'My pack, with commas # literal text');
      expect(pack.description, 'First line.\nSecond line.');
      expect(pack.items.single.url, 'https://example.com/file.zip');
      expect(pack.unknownFields['future'], {
        'enabled': true,
        'values': [1, 2, 3],
      });
      expect(
        modpackDefinitionsAreIdentical(
          pack,
          decodeModpackFileBytes(
            utf8.encode(encodeModpackDefinitionFileJson(pack)),
          ),
        ),
        true,
      );
    },
  );

  test(
    'links and bounded files decode through the same definition format',
    () async {
      final folder = await Directory.systemTemp.createTemp('incoming-modpack');
      addTearDown(() => folder.delete(recursive: true));
      final file = File('${folder.path}/space in name.trios-modpack');
      await file.writeAsString(encodeModpackDefinitionFileJson(incomingPack));
      for (final input in [
        file.path,
        file.uri.toString(),
        buildModpackShareLink(incomingPack),
        buildModpackDeepLinkUri(encodeModpackPayload(incomingPack))
            .replaceFirst('install?', 'install/?'),
      ]) {
        expect(isIncomingModpack(input), true);
        expect(
          modpackDefinitionsAreIdentical(
            await readIncomingModpack(input),
            incomingPack,
          ),
          true,
        );
      }
      expect(
        SingleInstanceManager.extractDeepLinkFromArgs([file.path]),
        file.uri.toString(),
      );
      await file.writeAsBytes(
        List.filled(ModpackLimits.maxExpandedBytes + 1, 32),
      );
      await expectLater(readIncomingModpack(file.path), throwsFormatException);
    },
  );

  test(
    'malformed, mixed, oversized and unknown formats cannot become downloads',
    () async {
      final link = buildModpackDeepLinkUri(encodeModpackPayload(incomingPack));
      for (final value in [
        '$link&mod=https://example.com/a.zip',
        '$link&dep=x',
        '$link&modpack=1.other',
        '$link&name=${'x' * 30000}',
        'starsector-mod://install?modpack=9.x',
        'starsector-mod://install?modpack=',
      ]) {
        expect(isIncomingModpack(value), true);
        await expectLater(
          readIncomingModpack(value),
          throwsA(isA<ModpackFormatException>()),
        );
      }
      expect(
        isIncomingModpack(
          'starsector-mod://install?mod=https://example.com/a.zip',
        ),
        false,
      );
      await expectLater(
        readIncomingModpack('not a link'),
        throwsA(isA<ModpackFormatException>()),
      );
    },
  );

  test('drafts take priority over saved duplicate detection', () {
    final entry = ModpackLibraryEntry(definition: incomingPack);
    final saved = ModpacksData(packs: {incomingPack.id: entry});
    expect(
      matchIncomingModpack(incomingPack, const ModpacksData()),
      IncomingModpackMatch.newPack,
    );
    expect(
      matchIncomingModpack(incomingPack, saved),
      IncomingModpackMatch.saved,
    );
    expect(
      matchIncomingModpack(incomingPack.copyWith(version: 4), saved),
      IncomingModpackMatch.savedConflict,
    );
    expect(
      matchIncomingModpack(
        incomingPack.copyWith(unknownFields: {'future': 6}),
        saved,
      ),
      IncomingModpackMatch.savedConflict,
    );
    final draft = ModpackDraft.fromDefinition(incomingPack);
    expect(
      matchIncomingModpack(
        incomingPack,
        saved.copyWith(drafts: {draft.id: draft}),
      ),
      IncomingModpackMatch.draft,
    );
    expect(
      matchIncomingModpack(
        incomingPack,
        saved.copyWith(drafts: {draft.id: draft.copyWith(name: 'My work')}),
      ),
      IncomingModpackMatch.draftConflict,
    );
  });

  test(
    'receipt does not fetch; checks offer a definition without selecting it',
    () async {
      var calls = 0;
      final online = incomingPack.copyWith(version: 4);
      final session = IncomingModpackSession(
        incomingPack,
        fetch: (_, _) async {
          calls++;
          return online;
        },
      );
      addTearDown(session.dispose);
      expect(calls, 0);
      await session.checkForUpdate();
      expect(calls, 1);
      expect(session.selected, incomingPack);
      expect(session.online, online);
      session.selectOnline();
      expect(session.selected, online);
    },
  );

  test(
    'an add freezes its definition and ignores a delayed online result',
    () async {
      final result = Completer<ModpackDefinition>();
      final session = IncomingModpackSession(
        incomingPack,
        fetch: (_, _) => result.future,
      );
      addTearDown(session.dispose);
      final check = session.checkForUpdate();
      final chosen = session.beginAction();
      result.complete(incomingPack.copyWith(version: 8));
      await check;
      expect(chosen, incomingPack);
      expect(session.selected, incomingPack);
      expect(session.online, isNull);
      expect(session.checking, false);
    },
  );

  test(
    'failed, older, and different-ID checks leave the embedded pack usable',
    () async {
      for (final result in [
        incomingPack.copyWith(version: 2),
        incomingPack.copyWith(id: 'different_pack_00000000'),
      ]) {
        final session = IncomingModpackSession(
          incomingPack,
          fetch: (_, _) async => result,
        );
        await session.checkForUpdate();
        expect(session.online, isNull);
        expect(session.selected, incomingPack);
        expect(session.message, isNotNull);
        session.dispose();
      }
      final session = IncomingModpackSession(
        incomingPack,
        fetch: (_, _) async => throw const FormatException('Unavailable'),
      );
      await session.checkForUpdate();
      expect(session.selected, incomingPack);
      expect(session.message, contains('Unavailable'));
      session.dispose();
    },
  );

  test(
    'reviewed replacement is atomic and refuses changed draft work',
    () async {
      final folder = await Directory.systemTemp.createTemp('incoming-store');
      final store = ModpackStore(storageFolder: folder);
      final container = ProviderContainer(
        overrides: [modpackStoreProvider.overrideWith(() => store)],
      );
      addTearDown(() async {
        container.dispose();
        await folder.delete(recursive: true);
      });
      await container.read(modpackStoreProvider.future);
      final saved = await store.acceptIncomingDefinition(
        incomingPack,
        expectedEntry: null,
        expectedDraft: null,
      );
      final draft = await store.openDraft(incomingPack.id);
      final newer = incomingPack.copyWith(version: 4);
      await expectLater(
        store.acceptIncomingDefinition(
          newer,
          expectedEntry: saved,
          expectedDraft: draft,
        ),
        throwsStateError,
      );
      await store.saveDraft(draft!.copyWith(name: 'Still editing'));
      await expectLater(
        store.acceptIncomingDefinition(
          newer,
          expectedEntry: saved,
          expectedDraft: draft,
          discardDraft: true,
        ),
        throwsStateError,
      );
      final data = container.read(modpackStoreProvider).requireValue;
      final copy = await store.saveIncomingDefinitionAsCopy(newer);
      expect(copy.definition.id, isNot(incomingPack.id));
      expect(copy.definition.version, 1);
      expect(
        container
            .read(modpackStoreProvider)
            .requireValue
            .drafts[incomingPack.id]
            ?.name,
        'Still editing',
      );
      await store.acceptIncomingDefinition(
        newer,
        expectedEntry: data.packs[incomingPack.id],
        expectedDraft: data.drafts[incomingPack.id],
        discardDraft: true,
      );
      expect(
        container
            .read(modpackStoreProvider)
            .requireValue
            .packs[incomingPack.id]
            ?.definition,
        newer,
      );
      expect(container.read(modpackStoreProvider).requireValue.drafts, isEmpty);
    },
  );
}
