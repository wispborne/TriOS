import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:trios/modpacks/models/modpack_definition.dart';
import 'package:trios/modpacks/modpack_format.dart';
import 'package:trios/modpacks/modpack_link_codec.dart';

ModpackDefinition _goldenFull() => decodeModpackDefinition(
  jsonDecode(File('test/modpacks/golden/modpack_full.json').readAsStringSync()),
);

ModpackDefinition _packWithItems(int count) => ModpackDefinition(
  id: 'N3qGd6c8R2mVx1ZaYkW0_A',
  name: 'Big pack',
  version: 1,
  items: [
    for (var index = 0; index < count; index++)
      ModpackItem(
        modId: 'mod_id_number_$index',
        name: 'Mod Number $index',
        version: '1.$index.0',
        url: 'https://example.com/downloads/mod_number_$index/Mod.version',
        sourceType: ModpackItemSourceType.versionFile,
      ),
  ],
);

Matcher _throwsFormatError(ModpackFormatError error) => throwsA(
  isA<ModpackFormatException>().having((e) => e.error, 'error', error),
);

void main() {
  group('payloads', () {
    test('round trip a definition', () {
      final original = _goldenFull();
      final payload = encodeModpackPayload(original);

      expect(payload, startsWith('1.'));
      expect(
        encodeModpackDefinitionJson(decodeModpackPayload(payload)),
        encodeModpackDefinitionJson(original),
      );
    });

    test('use unpadded base64url', () {
      final payload = encodeModpackPayload(_goldenFull());
      final body = payload.substring(2);
      expect(body, isNot(contains('=')));
      expect(body, isNot(contains('+')));
      expect(body, isNot(contains('/')));
    });

    test('are the same for the same data', () {
      expect(
        encodeModpackPayload(_goldenFull()),
        encodeModpackPayload(_goldenFull()),
      );
    });

    test('compress well enough for a large pack', () {
      // A link should hold well over a thousand mods.
      final link = buildModpackShareLink(_packWithItems(1000));
      expect(link.length, lessThan(ModpackLimits.maxLinkCharacters));
    });

    test('ask for a newer TriOS for an unknown transport number', () {
      final payload = encodeModpackPayload(_goldenFull());
      final future = '2.${payload.substring(2)}';

      expect(
        () => decodeModpackPayload(future),
        _throwsFormatError(ModpackFormatError.unsupportedTransportFormat),
      );
    });

    test('refuse malformed payloads', () {
      expect(
        () => decodeModpackPayload(''),
        _throwsFormatError(ModpackFormatError.missingPayload),
      );
      expect(
        () => decodeModpackPayload('no-separator'),
        _throwsFormatError(ModpackFormatError.malformedPayload),
      );
      expect(
        () => decodeModpackPayload('1.'),
        _throwsFormatError(ModpackFormatError.malformedPayload),
      );
      expect(
        () => decodeModpackPayload('1.not!base64url'),
        _throwsFormatError(ModpackFormatError.malformedPayload),
      );
    });

    test('refuse data that will not decompress', () {
      expect(
        () => decodeModpackPayload(
          '1.${base64Url.encode(utf8.encode('plain text')).replaceAll('=', '')}',
        ),
        _throwsFormatError(ModpackFormatError.decompressionFailed),
      );
    });

    test('refuse a payload longer than a link may be', () {
      final tooLong = '1.${'A' * ModpackLimits.maxLinkCharacters}';
      expect(
        () => decodeModpackPayload(tooLong),
        _throwsFormatError(ModpackFormatError.payloadTooLarge),
      );
    });

    test('refuse a payload that expands past the limit', () {
      // Small compressed data that inflates to a lot of JSON.
      final bomb = ZLibCodec(level: 9).encode(
        utf8.encode(
          '{"padding":"${'a' * (ModpackLimits.maxExpandedBytes + 1024)}"}',
        ),
      );
      final payload = '1.${base64Url.encode(bomb).replaceAll('=', '')}';

      expect(
        () => decodeModpackPayload(payload),
        _throwsFormatError(ModpackFormatError.payloadTooLarge),
      );
    });

    test('refuse a payload holding a bad definition', () {
      final deflated = ZLibCodec(level: 9).encode(
        utf8.encode(
          '{"formatVersion":1,"id":"short","name":"x","version":1,"items":[]}',
        ),
      );
      expect(
        () => decodeModpackPayload(
          '1.${base64Url.encode(deflated).replaceAll('=', '')}',
        ),
        _throwsFormatError(ModpackFormatError.invalidId),
      );
    });
  });

  group('share links', () {
    test('put the pack in the fragment with readable decoration', () {
      final definition = _goldenFull();
      final link = buildModpackShareLink(definition);

      expect(link, startsWith('$trilinkOpenPageUrl#'));
      final fragment = Uri.parse(link).fragment;
      final fields = Uri.splitQueryString(fragment);

      expect(fields['name'], 'Wisps-QoL-Pack');
      expect(fields['version'], '3');
      expect(fields['modpack'], startsWith('1.'));

      // Everything TriOS trusts comes from the payload, not the decoration.
      expect(decodeModpackPayload(fields['modpack']!).name, "Wisp's QoL Pack");
    });

    test('never contain a query string, so the pack stays off the server', () {
      expect(Uri.parse(buildModpackShareLink(_goldenFull())).query, isEmpty);
    });

    test('refuse to build a link that is too long', () {
      // Long item notes are what usually pushes a pack past the limit.
      final wordy = ModpackDefinition(
        id: 'N3qGd6c8R2mVx1ZaYkW0_A',
        name: 'Wordy pack',
        version: 1,
        items: [
          for (var index = 0; index < 400; index++)
            ModpackItem(
              modId: 'mod_$index',
              url: 'https://example.com/mod_$index/Mod.version',
              sourceType: ModpackItemSourceType.versionFile,
              note: List.generate(
                60,
                (word) => 'unrepeatable-note-$index-$word',
              ).join(' '),
            ),
        ],
      );

      expect(
        () => buildModpackShareLink(wordy),
        _throwsFormatError(ModpackFormatError.linkTooLarge),
      );
    });

    test('build the scheme address TriLink hands to TriOS', () {
      final payload = encodeModpackPayload(_goldenFull());
      final deepLink = buildModpackDeepLinkUri(payload);

      expect(deepLink, 'starsector-mod://install?modpack=$payload');
      expect(
        decodeModpackPayload(Uri.parse(deepLink).queryParameters['modpack']!)
            .id,
        'N3qGd6c8R2mVx1ZaYkW0_A',
      );
    });

    test('give a nameless pack a usable decoration', () {
      final link = buildModpackShareLink(
        ModpackDefinition(
          id: 'N3qGd6c8R2mVx1ZaYkW0_A',
          name: '???',
          version: 2,
          items: _goldenFull().items,
        ),
      );
      expect(Uri.splitQueryString(Uri.parse(link).fragment)['name'], 'Modpack');
    });
  });
}
