// pretty_share_codec_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:trios/mod_profiles/models/shared_mod_list.dart';
import 'package:trios/models/version.dart';

void main() {
  group('SharedModListCodec.encode', () {
    test('encodes header + all mod line variants', () {
      final list = SharedModList(
        id: '4f2a1',
        name: 'Starter pack',
        dateCreated: DateTime.now(),
        dateModified: DateTime.now(),
        description: '',
        mods: <SharedModVariant>[
          SharedModVariant.create(
            modId: 'com.foo.alpha',
            modName: 'Alpha',
            versionName: Version.parse('1.2.0'),
          ),
          SharedModVariant.create(modId: 'com.bar.beta', modName: 'Beta'),
          SharedModVariant.create(
            modId: 'com.baz.gamma',
            versionName: Version.parse('2.0'),
          ),
          SharedModVariant.create(modId: 'com.qux.delta'),
        ],
      );

      final share = list.toShareString();

      const expected = '''
Starter pack (=4f2a1)
===
Alpha - 1.2.0 (com.foo.alpha)
Beta (com.bar.beta)
com.baz.gamma - 2.0
com.qux.delta''';

      expect(_normalize(share), _normalize(expected));
    });

    test('escapes parentheses and backslashes in name, id, and version', () {
      final list = SharedModList(
        id: r'id\(x\)\tail\',
        name: r'My Pack (X)\',
        dateCreated: DateTime.now(),
        dateModified: DateTime.now(),
        description: '',
        mods: <SharedModVariant>[
          SharedModVariant.create(
            modId: r'com.acme\)mod(id)',
            modName: r'Name (feat. \(X\)) \',
            versionName: Version.parse(r'v1.0(+) \'),
          ),
        ],
      );

      final share = list.toShareString();

      // Header must escape the trailing '\' and parentheses.
      expect(
        _normalize(share).split('\n').first,
        r'My Pack \(X\)\\ (=id\(x\)\\tail\\)',
      );

      // Mod line: "<name> - <version> (<id>)" with escapes applied.
      final modLine = _normalize(share).split('\n').last;
      expect(
        modLine,
        r'Name \(feat. \(X\)\) \\ - v1.0\(+\) \\ (com.acme\)mod\(id\))',
      );
    });

    test('omits separator when includeSeparator=false', () {
      final list = SharedModList(
        id: 'abc',
        name: 'NoSep',
        dateCreated: DateTime.now(),
        dateModified: DateTime.now(),
        description: '',
        mods: <SharedModVariant>[SharedModVariant.create(modId: 'x.y')],
      );
      final share = list.toShareString(includeSeparator: false);
      final lines = _normalize(share).split('\n');
      expect(lines.length, 2);
      expect(lines[0], 'NoSep (=abc)');
      expect(lines[1], 'x.y');
    });
  });

  group('SharedModListCodec.decode', () {
    test('parses all mod line variants', () {
      const input = '''
Starter pack (=4f2a1)
===
Alpha - 1.2.0 (com.foo.alpha)
Beta (com.bar.beta)
com.baz.gamma - 2.0
com.qux.delta
====''';

      final parsed = SharedModListCodec.fromShareString(
        input,
        fallbackId: 'fallback',
        fallbackName: 'Untitled',
      );

      expect(parsed.id, '4f2a1');
      expect(parsed.name, 'Starter pack');
      expect(parsed.mods.length, 4);

      final m0 = parsed.mods[0];
      expect(m0.modId, 'com.foo.alpha');
      expect(m0.modName, 'Alpha');
      expect(m0.versionName?.toString(), '1.2.0');

      final m1 = parsed.mods[1];
      expect(m1.modId, 'com.bar.beta');
      expect(m1.modName, 'Beta');
      expect(m1.versionName, isNull);

      final m2 = parsed.mods[2];
      expect(m2.modId, 'com.baz.gamma');
      expect(m2.modName, isNull);
      expect(m2.versionName?.toString(), '2.0');

      final m3 = parsed.mods[3];
      expect(m3.modId, 'com.qux.delta');
      expect(m3.modName, isNull);
      expect(m3.versionName, isNull);
    });

    test(
      'handles missing header via fallbacks and keeps first line as mod',
      () {
        const input = '''
Alpha - 1.2.0 (com.foo.alpha)
com.bar.beta''';

        final parsed = SharedModListCodec.fromShareString(
          input,
          fallbackId: 'x',
          fallbackName: 'Untitled',
        );

        expect(parsed.id, 'x');
        expect(parsed.name, 'Untitled');
        expect(parsed.mods.length, 2);
        expect(parsed.mods[0].modId, 'com.foo.alpha');
        expect(parsed.mods[1].modId, 'com.bar.beta');
      },
    );

    test('accepts empty name when id is provided in parens', () {
      const input = '''
Pack (=p1)
()
(com.id)
(another.id)''';

      final parsed = SharedModListCodec.fromShareString(
        input,
        fallbackId: 'x',
        fallbackName: 'Untitled',
      );

      // "()" is ignored as empty id; "(com.id)" and "(another.id)" are valid.
      expect(parsed.mods.map((m) => m.modId).toList(), [
        'com.id',
        'another.id',
      ]);
      expect(parsed.mods.every((m) => m.modName == null), isTrue);
    });

    test(
      'respects escaped trailing ")" inside names and still finds id parens',
      () {
        const input = r'''
Pack (=p1)
Name with \) char (com.id)''';

        final parsed = SharedModListCodec.fromShareString(
          input,
          fallbackId: 'x',
          fallbackName: 'Untitled',
        );

        expect(parsed.mods.length, 1);
        expect(parsed.mods.first.modId, 'com.id');
        expect(parsed.mods.first.modName, r'Name with ) char');
      },
    );

    test('keeps literal trailing backslash', () {
      const input = r'''
Pack (=p1)
EndsWithSlash\\ (com.id)''';

      final parsed = SharedModListCodec.fromShareString(
        input,
        fallbackId: 'x',
        fallbackName: 'Untitled',
      );

      expect(parsed.mods.first.modName, r'EndsWithSlash\');
    });

    test('ignores stray "===" lines anywhere', () {
      const input = '''
Pack (=p1)
===
com.a
===
com.b
==''';

      final parsed = SharedModListCodec.fromShareString(
        input,
        fallbackId: 'x',
        fallbackName: 'Untitled',
      );

      expect(parsed.mods.map((m) => m.modId).toList(), ['com.a', 'com.b']);
    });
  });

  group('SharedModListCodec.round-trip', () {
    test('decode(encode(x)) ≡ x (field-wise)', () {
      final src = SharedModList(
        id: 'ID-42',
        name: r'My Pack (v2)\',
        dateCreated: DateTime.now(),
        dateModified: DateTime.now(),
        description: '',
        mods: <SharedModVariant>[
          SharedModVariant.create(
            modId: r'com.acme\id',
            modName: 'Cool (Mod)',
            versionName: Version.parse('3.1.4'),
          ),
          SharedModVariant.create(
            modId: 'com.no.name',
            versionName: Version.parse('0.9.0'),
          ),
          SharedModVariant.create(modId: 'com.plain'),
        ],
      );

      final encoded = src.toShareString();

      final dst = SharedModListCodec.fromShareString(
        encoded,
        fallbackId: 'fallback',
        fallbackName: 'fallback',
      );

      // Header
      expect(dst.id, src.id);
      expect(dst.name, src.name);

      // Mods equality
      expect(dst.mods.length, src.mods.length);
      for (var i = 0; i < src.mods.length; i++) {
        final a = src.mods[i];
        final b = dst.mods[i];
        expect(b.modId, a.modId);
        expect(b.modName, a.modName);
        expect(b.versionName?.toString(), a.versionName?.toString());
      }

      // Stability: encode after decode should match original encoding.
      final reEncoded = dst.toShareString();
      expect(_normalize(reEncoded), _normalize(encoded));
    });

    test(
      'encode(decode(x)) ≡ normalized(x) for inputs with varied spacing',
      () {
        const noisy = '''
   Pack Name (=ID)
 ===============
  Alpha   -   1.0.0   (com.alpha)
  Beta(com.beta)
com.gamma   -   2.0
  com.delta
''';

        final parsed = SharedModListCodec.fromShareString(
          noisy,
          fallbackId: 'x',
          fallbackName: 'y',
        );

        final clean = parsed.toShareString();

        const expected = '''
Pack Name (=ID)
===
Alpha - 1.0.0 (com.alpha)
Beta (com.beta)
com.gamma - 2.0
com.delta''';

        expect(_normalize(clean), _normalize(expected));
      },
    );
  });
}

// ---------- helpers ----------

String _normalize(String s) => s.replaceAll('\r\n', '\n');
