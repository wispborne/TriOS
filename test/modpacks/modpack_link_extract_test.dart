import 'package:flutter_test/flutter_test.dart';
import 'package:trios/modpacks/modpack_format.dart';
import 'package:trios/modpacks/modpack_link_codec.dart';
import 'package:trios/modpacks/models/modpack_definition.dart';

const _definition = ModpackDefinition(
  id: 'N3qGd6c8R2mVx1ZaYkW0_A',
  name: 'Wisp\'s pack',
  version: 2,
  items: [
    ModpackItem(
      modId: 'lw_lazylib',
      url: 'https://example.com/LazyLib.version',
      sourceType: ModpackItemSourceType.versionFile,
    ),
  ],
);

void main() {
  final payload = encodeModpackPayload(_definition);

  group('extracting a payload from pasted text', () {
    test('a TriLink share link', () {
      final link = buildModpackShareLink(_definition);
      expect(extractModpackLinkPayload(link), payload);
    });

    test('the registered-scheme address, with or without the slash', () {
      expect(
        extractModpackLinkPayload(buildModpackDeepLinkUri(payload)),
        payload,
      );
      expect(
        extractModpackLinkPayload('starsector-mod://install/?modpack=$payload'),
        payload,
      );
    });

    test('a bare payload, with whitespace around it', () {
      expect(extractModpackLinkPayload('  $payload\n'), payload);
    });

    test('text that is not a link gives null', () {
      expect(extractModpackLinkPayload(''), isNull);
      expect(extractModpackLinkPayload('hello there'), isNull);
      expect(extractModpackLinkPayload('https://example.com/#name=x'), isNull);
      expect(
        extractModpackLinkPayload('starsector-mod://install?mod=abc'),
        isNull,
      );
    });
  });

  group('decoding pasted text', () {
    test('a share link decodes to the same definition', () {
      final decoded = decodeModpackLink(buildModpackShareLink(_definition));
      expect(modpackDefinitionsAreIdentical(decoded, _definition), isTrue);
    });

    test('text without a link is refused', () {
      expect(
        () => decodeModpackLink('not a link'),
        throwsA(
          isA<ModpackFormatException>().having(
            (e) => e.error,
            'error',
            ModpackFormatError.missingPayload,
          ),
        ),
      );
    });

    test('a link with a broken payload is refused', () {
      expect(
        () => decodeModpackLink('starsector-mod://install?modpack=1.!!!'),
        throwsA(isA<ModpackFormatException>()),
      );
    });
  });
}
