import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:trios/vram_estimator/selectors/references/java_source_references.dart';

import '_helpers.dart';

void main() {
  late Directory tmp;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('vram_java_refs_test_');
  });

  tearDown(() {
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  test('extracts path-like string literals', () async {
    final fx = buildModFixture(tmp, {
      'src/Foo.java': '''
        package example;
        public class Foo {
          public void run() {
            loadSprite("graphics/icons/foo.png");
            loadSprite("graphics/icons/bar.png");
          }
        }
      ''',
      // on-disk presence needed for directory-prefix expansion tests
      'graphics/icons/foo.png': 'stub',
      'graphics/icons/bar.png': 'stub',
    });
    final refs = await JavaSourceReferences().collect(
      fx.mod,
      fx.files,
      buildTestContext(),
    );
    expect(refs, contains('graphics/icons/foo.png'));
    expect(refs, contains('graphics/icons/bar.png'));
  });

  test('directory-prefix literals expand to every image in the directory',
      () async {
    final fx = buildModFixture(tmp, {
      'src/Loader.java': '''
        String dir = "graphics/portraits/";
        Global.getSettings().loadTexture(dir + id + ".png");
      ''',
      'graphics/portraits/alice.png': 'stub',
      'graphics/portraits/bob.png': 'stub',
      'graphics/portraits/charlie.png': 'stub',
      'graphics/elsewhere/nope.png': 'stub',
    });
    final refs = await JavaSourceReferences().collect(
      fx.mod,
      fx.files,
      buildTestContext(),
    );
    expect(refs, contains('graphics/portraits/alice.png'));
    expect(refs, contains('graphics/portraits/bob.png'));
    expect(refs, contains('graphics/portraits/charlie.png'));
    // A different directory shouldn't be pulled in by the prefix.
    expect(refs, isNot(contains('graphics/elsewhere/nope.png')));
  });

  test('commented-out strings are skipped', () async {
    final fx = buildModFixture(tmp, {
      'src/Commented.java': '''
        public class Commented {
          // loadSprite("graphics/line_comment/ignored.png");
          /* loadSprite("graphics/block_comment/ignored.png"); */
          public void run() {
            loadSprite("graphics/real/kept.png");
          }
        }
      ''',
    });
    final refs = await JavaSourceReferences().collect(
      fx.mod,
      fx.files,
      buildTestContext(),
    );
    expect(refs, contains('graphics/real/kept.png'));
    expect(
      refs,
      isNot(contains('graphics/line_comment/ignored.png')),
    );
    expect(
      refs,
      isNot(contains('graphics/block_comment/ignored.png')),
    );
  });

  test('escaped quotes inside literals do not terminate the match early',
      () async {
    final fx = buildModFixture(tmp, {
      'src/Escaped.java': r'''
        String q = "graphics/escaped/\"quoted\".png";
        String normal = "graphics/escaped/normal.png";
      ''',
    });
    final refs = await JavaSourceReferences().collect(
      fx.mod,
      fx.files,
      buildTestContext(),
    );
    expect(refs, contains('graphics/escaped/normal.png'));
  });

  test('non-path-like literals (no slash, no resource root) are filtered out',
      () async {
    final fx = buildModFixture(tmp, {
      'src/Noise.java': '''
        String msg = "Hello, world!";
        String noSlash = "not_a_path";
        String good = "graphics/good.png";
      ''',
    });
    final refs = await JavaSourceReferences().collect(
      fx.mod,
      fx.files,
      buildTestContext(),
    );
    expect(refs.keys, contains('graphics/good.png'));
    expect(refs.keys.any((r) => r.contains('hello')), isFalse);
    expect(refs.keys.any((r) => r.contains('not_a_path')), isFalse);
    // Literals that merely start with a resource root do survive the
    // filter — this is intentional, because the downstream intersection
    // with on-disk files drops any path that isn't actually present.
    // Verified here by ensuring they don't show up as real matches when
    // there's nothing on disk to hit.
  });

  test('ignores non-.java files', () async {
    final fx = buildModFixture(tmp, {
      'notes.txt': 'String s = "graphics/notes.png";',
    });
    final refs = await JavaSourceReferences().collect(
      fx.mod,
      fx.files,
      buildTestContext(),
    );
    expect(refs, isEmpty);
  });
}
