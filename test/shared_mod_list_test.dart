import 'package:flutter_test/flutter_test.dart';
import 'package:trios/mod_profiles/models/shared_mod_list.dart';
import 'package:trios/models/version.dart';

void main() {
  group('SharedModListCodec.encode', () {
    test('encodes header + mod lines in new format', () {
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
          SharedModVariant.create(
            modId: 'com.bar.beta',
            modName: 'Beta',
            versionName: Version.parse('1.0.0'),
          ),
          SharedModVariant.create(
            modId: 'com.qux.delta',
            modName: 'Delta',
            versionName: Version.parse('0.0.1'),
          ),
        ],
      );

      final share = list.toShareString();

      const expected = '''
Starter pack (4f2a1)
---
Alpha v1.2.0 (com.foo.alpha)
Beta v1.0.0 (com.bar.beta)
Delta v0.0.1 (com.qux.delta)''';

      expect(_normalize(share), _normalize(expected));
    });

    test(
      'escapes parentheses, backslashes, and keeps " v" escaped in version',
      () {
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
              // Version string starts with 'v' per new format
              versionName: Version.parse(r'v1.0(+) \'),
            ),
          ],
        );

        final share = list.toShareString();

        // Header must escape the trailing '\' and parentheses, and omit '=' in id block.
        expect(
          _normalize(share).split('\n').first,
          r'My Pack \(X\)\\ (id\(x\)\\tail\\)',
        );

        // Mod line: "<name> v<version> (<id>)" with escapes applied.
        final modLine = _normalize(share).split('\n').last;
        expect(
          modLine,
          r'Name \(feat. \(X\)\) \\ vv1.0\(+\) \\ (com.acme\)mod\(id\))',
        );
      },
    );
  });

  group('SharedModListCodec.decode', () {
    test('parses mod lines in new format', () {
      const input = '''
Starter pack (4f2a1)
---
Alpha v1.2.0 (com.foo.alpha)
Beta vv1.0.0 (com.bar.beta)
Delta v0.0.1 (com.qux.delta)
----''';

      final parsed = SharedModListCodec.fromShareString(
        input,
        fallbackProfileId: 'fallback',
        fallbackProfileName: 'Untitled',
      );

      expect(parsed.id, '4f2a1');
      expect(parsed.name, 'Starter pack');
      expect(parsed.mods.length, 3);

      final m0 = parsed.mods[0];
      expect(m0.modId, 'com.foo.alpha');
      expect(m0.modName, 'Alpha');
      expect(m0.versionName?.toString(), '1.2.0');

      final m1 = parsed.mods[1];
      expect(m1.modId, 'com.bar.beta');
      expect(m1.modName, 'Beta');
      expect(m1.versionName?.toString(), 'v1.0.0');

      final m2 = parsed.mods[2];
      expect(m2.modId, 'com.qux.delta');
      expect(m2.modName, 'Delta');
      expect(m2.versionName?.toString(), '0.0.1');
    });

    test('handles missing header via fallbacks; still parses mod lines', () {
      const input = '''
Alpha v1.2.0 (com.foo.alpha)
Beta v1.0.0 (com.bar.beta)''';

      final parsed = SharedModListCodec.fromShareString(
        input,
        fallbackProfileId: 'x',
        fallbackProfileName: 'Untitled',
      );

      expect(parsed.id, 'x');
      expect(parsed.name, 'Untitled');
      expect(parsed.mods.length, 2);
      expect(parsed.mods[0].modId, 'com.foo.alpha');
      expect(parsed.mods[0].versionName?.toString(), '1.2.0');
      expect(parsed.mods[1].modId, 'com.bar.beta');
      expect(parsed.mods[1].versionName?.toString(), '1.0.0');
    });

    test('version required', () {
      const input = '''
Pack (p1)''';

      try {
        SharedModListCodec.fromShareString(
          input,
          fallbackProfileId: 'x',
          fallbackProfileName: 'Untitled',
        );
        expect(true, false);
      } catch (e) {
        expect(e, isA<FormatException>());
        return;
      }
    });

    test(
      'respects escaped trailing ")" inside names and still finds id parens',
      () {
        const input = r'''
Name with \) char v1 (com.id)''';

        final parsed = SharedModListCodec.fromShareString(
          input,
          fallbackProfileId: 'x',
          fallbackProfileName: 'Untitled',
        );

        expect(parsed.mods.length, 1);
        expect(parsed.mods.first.modId, 'com.id');
        expect(parsed.mods.first.modName, r'Name with ) char');
        expect(parsed.mods.first.versionName?.toString(), '1');
      },
    );

    test('keeps literal trailing backslash', () {
      const input = r'''
EndsWithSlash\\ v1 (com.id)'''; // FAILS because the mod name is escaping the " v`. Not sure how to reconcile this.

      final parsed = SharedModListCodec.fromShareString(
        input,
        fallbackProfileId: 'x',
        fallbackProfileName: 'Untitled',
      );

      expect(parsed.mods.first.modName, r'EndsWithSlash\');
      expect(parsed.mods.first.versionName?.toString(), '1');
    });

    test('ignores stray hyphen separators anywhere', () {
      const input = '''
Pack (p1)
---
com.a v1 (com.a)
------
com.b v2 (com.b)
--''';

      final parsed = SharedModListCodec.fromShareString(
        input,
        fallbackProfileId: 'x',
        fallbackProfileName: 'Untitled',
      );

      expect(parsed.mods.map((m) => m.modId).toList(), ['com.a', 'com.b']);
      expect(parsed.mods.map((m) => m.versionName?.toString()).toList(), [
        '1',
        '2',
      ]);
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
            modName: null,
            versionName: Version.parse('0.9.0'),
          ),
          SharedModVariant.create(
            modId: 'com.plain',
            modName: 'Plain',
            versionName: Version.parse('1'),
          ),
        ],
      );

      final encoded = src.toShareString();

      final dst = SharedModListCodec.fromShareString(
        encoded,
        fallbackProfileId: 'fallback',
        fallbackProfileName: 'fallback',
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
        expect(b.modName, a.modName ?? a.modId);
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
   Pack Name (ID)
 -------------
  Alpha   v   1.0.0   (com.alpha)
  Beta v1.0.0 (com.beta)
com.gamma   v   2.0.0   (com.gamma)
  com.delta v0.1 (com.delta)
''';

        final parsed = SharedModListCodec.fromShareString(
          noisy,
          fallbackProfileId: 'x',
          fallbackProfileName: 'y',
        );

        final clean = parsed.toShareString();

        const expected = '''
Pack Name (ID)
---
Alpha v   1.0.0 (com.alpha)
Beta v1.0.0 (com.beta)
com.gamma v   2.0.0 (com.gamma)
com.delta v0.1 (com.delta)''';

        expect(_normalize(clean), _normalize(expected));
      },
    );
  });
}

// ---------- helpers ----------

String _normalize(String s) => s.replaceAll('\r\n', '\n');
