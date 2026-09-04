import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:trios/modpacks/models/modpack_definition.dart';
import 'package:trios/modpacks/modpack_format.dart';
import 'package:trios/modpacks/modpack_id.dart';

/// The shared definitions TriOS and TriLink must both agree on. TriLink keeps
/// copies of these files in its own tests.
const _goldenFolder = 'test/modpacks/golden';

Map<String, Object?> _golden(String name) =>
    jsonDecode(File('$_goldenFolder/$name').readAsStringSync())
        as Map<String, Object?>;

ModpackDefinition _definition({
  String id = 'N3qGd6c8R2mVx1ZaYkW0_A',
  String name = 'Test pack',
  int version = 1,
  List<ModpackItem>? items,
  Map<String, dynamic> unknownFields = const {},
}) => ModpackDefinition(
  id: id,
  name: name,
  version: version,
  items:
      items ??
      const [
        ModpackItem(
          modId: 'example_mod',
          url: 'https://example.com/Example.version',
          sourceType: ModpackItemSourceType.versionFile,
        ),
      ],
  unknownFields: unknownFields,
);

void main() {
  group('pack IDs', () {
    test('are 22 unpadded base64url characters', () {
      for (var attempt = 0; attempt < 50; attempt++) {
        final id = generateModpackId();
        expect(id.length, 22);
        expect(isValidModpackId(id), isTrue, reason: id);
        expect(id, isNot(contains('=')));
      }
    });

    test('differ from each other', () {
      final ids = {for (var i = 0; i < 100; i++) generateModpackId()};
      expect(ids.length, 100);
    });

    test('reject wrong lengths and characters', () {
      expect(isValidModpackId('too-short'), isFalse);
      expect(isValidModpackId('N3qGd6c8R2mVx1ZaYkW0_AA'), isFalse);
      expect(isValidModpackId('N3qGd6c8R2mVx1ZaYkW0+A'), isFalse);
      expect(isValidModpackId(''), isFalse);
    });

    test('are case-sensitive', () {
      const id = 'N3qGd6c8R2mVx1ZaYkW0_A';
      expect(
        modpackDefinitionsAreIdentical(
          _definition(id: id),
          _definition(id: id.toLowerCase()),
        ),
        isFalse,
      );
    });
  });

  group('decoding golden examples', () {
    test('reads a full definition', () {
      final definition = decodeModpackDefinition(_golden('modpack_full.json'));

      expect(definition.formatVersion, 1);
      expect(definition.id, 'N3qGd6c8R2mVx1ZaYkW0_A');
      expect(definition.name, "Wisp's QoL Pack");
      expect(definition.version, 3);
      expect(definition.author, 'Wisp');
      expect(definition.gameVersion, '0.98a-RC8');
      expect(definition.items.length, 3);

      final lazyLib = definition.items.first;
      expect(lazyLib.modId, 'lw_lazylib');
      expect(lazyLib.sourceType, ModpackItemSourceType.versionFile);
      expect(lazyLib.status, ModpackItemStatuses.required);
      expect(lazyLib.catalog?.forumTopicId, '5444');

      final magicLib = definition.items[1];
      expect(magicLib.sourceType, ModpackItemSourceType.directDownload);
      expect(magicLib.note, contains('LunaLib'));

      // A custom status keeps its own wording.
      expect(definition.items[2].status, 'Not for first-timers');
    });

    test('reads a minimal definition', () {
      final definition = decodeModpackDefinition(
        _golden('modpack_minimal.json'),
      );
      expect(definition.items.single.modId, 'example_mod');
      expect(definition.author, isNull);
      expect(definition.items.single.status, isNull);
      expect(definition.items.single.catalog, isNull);
    });

    test('round trips every golden example unchanged', () {
      for (final name in [
        'modpack_full.json',
        'modpack_minimal.json',
        'modpack_unknown_fields.json',
      ]) {
        final original = _golden(name);
        final decoded = decodeModpackDefinition(original);
        final reEncoded = jsonDecode(encodeModpackDefinitionJson(decoded));
        expect(reEncoded, original, reason: name);
      }
    });
  });

  group('unknown fields', () {
    test('survive decoding and encoding', () {
      final definition = decodeModpackDefinition(
        _golden('modpack_unknown_fields.json'),
      );

      expect(definition.unknownFields['futurePackField'], 'kept as-is');
      expect(definition.unknownFields['futurePackList'], [1, 2, 3]);
      expect(definition.items.single.unknownFields['futureItemFlag'], isTrue);
      expect(
        definition.items.single.catalog?.unknownFields['futureCatalogClue'],
        'kept',
      );
    });

    test('are counted when comparing definitions', () {
      final withField = _definition(unknownFields: {'futureField': 1});
      final without = _definition();

      expect(modpackDefinitionsAreIdentical(withField, without), isFalse);
      expect(modpackSharedContentMatches(withField, without), isFalse);
    });

    test('are written with their keys sorted', () {
      final definition = _definition(
        unknownFields: {'zebra': 1, 'alpha': 2, 'middle': 3},
      );
      final json = encodeModpackDefinitionJson(definition);
      expect(json.indexOf('"alpha"'), lessThan(json.indexOf('"middle"')));
      expect(json.indexOf('"middle"'), lessThan(json.indexOf('"zebra"')));
    });

    test('are rejected when nested too deeply', () {
      Object? nested = 'bottom';
      for (var depth = 0; depth < 12; depth++) {
        nested = {'down': nested};
      }
      expect(
        () => decodeModpackDefinition({
          ..._golden('modpack_minimal.json'),
          'futureField': nested,
        }),
        throwsA(
          isA<ModpackFormatException>().having(
            (e) => e.error,
            'error',
            ModpackFormatError.invalidUnknownField,
          ),
        ),
      );
    });
  });

  group('canonical encoding', () {
    test('gives the same output for the same data', () {
      final first = decodeModpackDefinition(_golden('modpack_full.json'));
      final second = decodeModpackDefinition(_golden('modpack_full.json'));
      expect(
        encodeModpackDefinitionJson(first),
        encodeModpackDefinitionJson(second),
      );
    });

    test('writes known fields in a fixed order', () {
      final json = encodeModpackDefinitionJson(
        decodeModpackDefinition(_golden('modpack_full.json')),
      );
      final order = [
        '"formatVersion"',
        '"id"',
        '"name"',
        '"version"',
        '"author"',
        '"description"',
        '"gameVersion"',
        '"homepageUrl"',
        '"updateUrl"',
        '"items"',
      ];
      var previous = -1;
      for (final field in order) {
        final position = json.indexOf(field);
        expect(position, greaterThan(previous), reason: field);
        previous = position;
      }
    });

    test('keeps the creator\'s item order', () {
      final definition = decodeModpackDefinition(_golden('modpack_full.json'));
      final reordered = definition.copyWith(
        items: definition.items.reversed.toList(),
      );

      expect(
        decodeModpackDefinition(
          jsonDecode(encodeModpackDefinitionJson(reordered)),
        ).modIds,
        ['prv', 'MagicLib', 'lw_lazylib'],
      );
      // Order is part of the shared content, so this is a real change.
      expect(modpackSharedContentMatches(reordered, definition), isFalse);
    });

    test('leaves out optional fields that are not set', () {
      final json = encodeModpackDefinitionJson(_definition());
      expect(json, isNot(contains('author')));
      expect(json, isNot(contains('status')));
      expect(json, isNot(contains('catalog')));
    });

    test('writes a readable file version of the same data', () {
      final definition = decodeModpackDefinition(_golden('modpack_full.json'));
      final pretty = encodeModpackDefinitionFileJson(definition);
      expect(pretty, contains('\n'));
      expect(
        jsonDecode(pretty),
        jsonDecode(encodeModpackDefinitionJson(definition)),
      );
    });
  });

  group('comparison', () {
    test('ignores ID and version for shared content', () {
      final saved = _definition(version: 4);
      final sameContent = _definition(id: 'aaaaaaaaaaaaaaaaaaaaaa', version: 9);

      expect(modpackSharedContentMatches(sameContent, saved), isTrue);
      expect(modpackDefinitionsAreIdentical(sameContent, saved), isFalse);
    });

    test('sees a changed note, status, or source as a change', () {
      final saved = _definition();
      final item = saved.items.single;

      expect(
        modpackSharedContentMatches(
          saved.copyWith(items: [item.copyWith(note: 'new note')]),
          saved,
        ),
        isFalse,
      );
      expect(
        modpackSharedContentMatches(
          saved.copyWith(items: [item.copyWith(status: 'Required')]),
          saved,
        ),
        isFalse,
      );
      expect(
        modpackSharedContentMatches(
          saved.copyWith(
            items: [
              item.copyWith(
                url: 'https://example.com/Other.zip',
                sourceType: ModpackItemSourceType.directDownload,
              ),
            ],
          ),
          saved,
        ),
        isFalse,
      );
    });
  });

  group('refusing bad definitions', () {
    void expectError(Object? raw, ModpackFormatError error) {
      expect(
        () => decodeModpackDefinition(raw),
        throwsA(
          isA<ModpackFormatException>().having((e) => e.error, 'error', error),
        ),
        reason: '$raw',
      );
    }

    test('rejects a definition that is not an object', () {
      expectError('not a pack', ModpackFormatError.invalidDefinition);
      expectError([], ModpackFormatError.invalidDefinition);
    });

    test('asks for a newer TriOS when the format is unknown', () {
      final exception = () {
        try {
          decodeModpackDefinition({
            ..._golden('modpack_minimal.json'),
            'formatVersion': 2,
          });
        } on ModpackFormatException catch (e) {
          return e;
        }
        return null;
      }();

      expect(exception, isNotNull);
      expect(exception!.error, ModpackFormatError.unsupportedDefinitionFormat);
      expect(exception.needsNewerTriOS, isTrue);
      expect(exception.message, contains('Update TriOS'));
    });

    test('rejects bad identity, name, and version', () {
      final base = _golden('modpack_minimal.json');
      expectError({...base, 'id': 'short'}, ModpackFormatError.invalidId);
      expectError({...base, 'name': '  '}, ModpackFormatError.invalidName);
      expectError({...base, 'version': 0}, ModpackFormatError.invalidVersion);
      expectError({...base, 'version': -3}, ModpackFormatError.invalidVersion);
      expectError({...base, 'version': 1.5}, ModpackFormatError.invalidVersion);
      expectError({...base, 'version': '3'}, ModpackFormatError.invalidVersion);
      expectError({
        ...base,
        'version': ModpackLimits.maxSafeInteger + 1,
      }, ModpackFormatError.invalidVersion);
    });

    test('rejects unsafe addresses', () {
      final base = _golden('modpack_minimal.json');
      for (final url in [
        'ftp://example.com/Mod.zip',
        'file:///C:/mods/Mod.zip',
        'javascript:alert(1)',
        'https://user:pass@example.com/Mod.zip',
        'https://',
        'not a url',
      ]) {
        expectError({
          ...base,
          'items': [
            {'id': 'example_mod', 'url': url, 'sourceType': 'versionFile'},
          ],
        }, ModpackFormatError.unsafeUrl);
      }

      expectError({
        ...base,
        'updateUrl': 'ftp://example.com/pack',
      }, ModpackFormatError.unsafeUrl);
    });

    test('rejects a missing or unknown item source type', () {
      final base = _golden('modpack_minimal.json');
      for (final sourceType in [null, 'torrent', 'VersionFile', 1]) {
        expectError({
          ...base,
          'items': [
            {
              'id': 'example_mod',
              'url': 'https://example.com/Example.version',
              'sourceType': sourceType,
            },
          ],
        }, ModpackFormatError.invalidSourceType);
      }
    });

    test('rejects duplicate mod IDs but allows different capitalization', () {
      final base = _golden('modpack_minimal.json');
      const item = {
        'id': 'example_mod',
        'url': 'https://example.com/Example.version',
        'sourceType': 'versionFile',
      };

      expectError({
        ...base,
        'items': [item, item],
      }, ModpackFormatError.duplicateItem);

      final mixedCase = decodeModpackDefinition({
        ...base,
        'items': [
          item,
          {...item, 'id': 'Example_Mod'},
        ],
      });
      expect(mixedCase.items.length, 2);
    });

    test('rejects items with no mod ID', () {
      final base = _golden('modpack_minimal.json');
      expectError({
        ...base,
        'items': [
          {
            'url': 'https://example.com/Example.version',
            'sourceType': 'versionFile',
          },
        ],
      }, ModpackFormatError.invalidItem);
      expectError({...base, 'items': 'nope'}, ModpackFormatError.invalidItems);
    });

    test('rejects over-long text and too many items', () {
      final base = _golden('modpack_minimal.json');
      expectError({
        ...base,
        'name': 'x' * (ModpackLimits.maxNameLength + 1),
      }, ModpackFormatError.fieldTooLong);
      expectError({
        ...base,
        'items': [
          {
            'id': 'example_mod',
            'url': 'https://example.com/Example.version',
            'sourceType': 'versionFile',
            'note': 'x' * (ModpackLimits.maxNoteLength + 1),
          },
        ],
      }, ModpackFormatError.invalidNote);
      expectError({
        ...base,
        'items': [
          {
            'id': 'example_mod',
            'url': 'https://example.com/Example.version',
            'sourceType': 'versionFile',
            'status': 'x' * (ModpackLimits.maxStatusLength + 1),
          },
        ],
      }, ModpackFormatError.invalidStatus);
      expectError({
        ...base,
        'items': [
          for (var index = 0; index < ModpackLimits.maxItems + 1; index++)
            {
              'id': 'mod_$index',
              'url': 'https://example.com/Mod$index.version',
              'sourceType': 'versionFile',
            },
        ],
      }, ModpackFormatError.tooManyItems);
    });

    test('rejects control characters in notes and statuses', () {
      final base = _golden('modpack_minimal.json');
      expectError({
        ...base,
        'items': [
          {
            'id': 'example_mod',
            'url': 'https://example.com/Example.version',
            'sourceType': 'versionFile',
            'note': 'line\u0000break',
          },
        ],
      }, ModpackFormatError.invalidNote);
      expectError({
        ...base,
        'items': [
          {
            'id': 'example_mod',
            'url': 'https://example.com/Example.version',
            'sourceType': 'versionFile',
            'status': 'two\nlines',
          },
        ],
      }, ModpackFormatError.invalidStatus);
    });

    test('keeps line breaks in a note', () {
      final definition = decodeModpackDefinition({
        ..._golden('modpack_minimal.json'),
        'items': [
          {
            'id': 'example_mod',
            'url': 'https://example.com/Example.version',
            'sourceType': 'versionFile',
            'note': 'First line.\nSecond line.',
          },
        ],
      });
      expect(definition.items.single.note, 'First line.\nSecond line.');
    });
  });

  group('item statuses', () {
    test('recognise standard labels whatever the capitalization', () {
      expect(ModpackItemStatuses.normalize('required'), 'Required');
      expect(ModpackItemStatuses.normalize('  RECOMMENDED '), 'Recommended');
      expect(ModpackItemStatuses.normalize('optional'), 'Optional');
      expect(ModpackItemStatuses.isStandard('OPTIONAL'), isTrue);
    });

    test('keep a custom label as it was typed', () {
      expect(
        ModpackItemStatuses.normalize('  Vanilla-friendly  '),
        'Vanilla-friendly',
      );
      expect(ModpackItemStatuses.isStandard('Vanilla-friendly'), isFalse);
    });

    test('treat blank as no status', () {
      expect(ModpackItemStatuses.normalize(null), isNull);
      expect(ModpackItemStatuses.normalize('   '), isNull);
    });

    test('are normalised when a definition is read', () {
      final definition = decodeModpackDefinition({
        ..._golden('modpack_minimal.json'),
        'items': [
          {
            'id': 'example_mod',
            'url': 'https://example.com/Example.version',
            'sourceType': 'versionFile',
            'status': 'recommended',
          },
        ],
      });
      expect(definition.items.single.status, 'Recommended');
    });
  });
}
