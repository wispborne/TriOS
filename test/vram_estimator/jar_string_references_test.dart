import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trios/vram_estimator/selectors/references/jar_string_references.dart';

import '_helpers.dart';

/// Build a minimal valid .class file whose constant pool contains the
/// given Utf8 strings. Only CONSTANT_Utf8 entries are emitted — this is
/// enough for `JarStringReferences` because its parser scans the
/// constant pool for `CONSTANT_Utf8` and stops on unknown tags.
Uint8List buildClassFileWithUtf8Strings(List<String> strings) {
  final body = BytesBuilder();
  // Magic: 0xCAFEBABE
  body.addByte(0xCA);
  body.addByte(0xFE);
  body.addByte(0xBA);
  body.addByte(0xBE);
  // Minor + major version (Java 17 = 61)
  body.addByte(0x00);
  body.addByte(0x00);
  body.addByte(0x00);
  body.addByte(0x3D);
  // constant_pool_count is the number of entries + 1 (indices are 1-based).
  final cpCount = strings.length + 1;
  body.addByte((cpCount >> 8) & 0xFF);
  body.addByte(cpCount & 0xFF);
  // Each entry: tag 1 (CONSTANT_Utf8), 2-byte length, then UTF-8 bytes.
  for (final s in strings) {
    body.addByte(0x01);
    final utf = utf8.encode(s);
    body.addByte((utf.length >> 8) & 0xFF);
    body.addByte(utf.length & 0xFF);
    body.add(utf);
  }
  // After the constant pool, the parser will hit an unknown tag and bail
  // cleanly — that's fine.
  return body.toBytes();
}

/// Wrap one or more .class byte blobs into a .jar (zip) at `jarPath`.
void writeJar(String jarPath, Map<String, Uint8List> classFiles) {
  final archive = Archive();
  classFiles.forEach((name, bytes) {
    archive.addFile(ArchiveFile.bytes(name, bytes));
  });
  final encoded = ZipEncoder().encodeBytes(archive);
  File(jarPath)
    ..createSync(recursive: true)
    ..writeAsBytesSync(encoded);
}

void main() {
  late Directory tmp;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('vram_jar_refs_test_');
  });

  tearDown(() {
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  test('extracts image-path literals from a jar at any location', () async {
    final classBytes = buildClassFileWithUtf8Strings([
      'graphics/portraits/explicit.png',
      'SomeClass', // should be filtered (no slash, no resource root)
      'Ljava/lang/String;', // should be filtered (not an asset-path shape)
    ]);
    // Place the jar outside jars/ to verify location-agnostic scanning.
    writeJar('${tmp.path}/bin/plugin.jar', {'Foo.class': classBytes});

    final fx = buildModFixture(tmp, {
      'graphics/portraits/explicit.png': 'stub',
    });
    final refs = await JarStringReferences().collect(
      fx.mod,
      fx.files,
      buildTestContext(),
    );
    expect(refs.keys, contains('graphics/portraits/explicit.png'));
    // Filter rejections shouldn't leak.
    expect(refs.keys.any((r) => r.contains('someclass')), isFalse);
  });

  test('directory-prefix literal expands to on-disk images in that dir',
      () async {
    final classBytes = buildClassFileWithUtf8Strings([
      'graphics/portraits/',
    ]);
    writeJar('${tmp.path}/jars/loader.jar', {'Loader.class': classBytes});

    final fx = buildModFixture(tmp, {
      'graphics/portraits/alice.png': 'stub',
      'graphics/portraits/bob.png': 'stub',
      'graphics/elsewhere/nope.png': 'stub',
    });
    final refs = await JarStringReferences().collect(
      fx.mod,
      fx.files,
      buildTestContext(),
    );
    expect(refs, contains('graphics/portraits/alice.png'));
    expect(refs, contains('graphics/portraits/bob.png'));
    expect(refs, isNot(contains('graphics/elsewhere/nope.png')));
  });

  test('malformed jar does not crash the parser', () async {
    File('${tmp.path}/broken.jar')
      ..createSync(recursive: true)
      ..writeAsBytesSync(Uint8List.fromList([1, 2, 3, 4, 5]));

    final fx = buildModFixture(tmp, {});
    final logs = <String>[];
    final refs = await JarStringReferences().collect(
      fx.mod,
      fx.files,
      buildTestContext(logLines: logs),
    );
    expect(refs, isEmpty);
  });

  test('a jar containing non-.class entries is ignored gracefully', () async {
    writeJar('${tmp.path}/resources.jar', {
      'META-INF/MANIFEST.MF':
          Uint8List.fromList(utf8.encode('Manifest-Version: 1.0')),
      'data/settings.txt':
          Uint8List.fromList(utf8.encode('graphics/settings/foo.png')),
    });
    final fx = buildModFixture(tmp, {});
    final refs = await JarStringReferences().collect(
      fx.mod,
      fx.files,
      buildTestContext(),
    );
    // Non-.class files are skipped — the literal in settings.txt is not
    // a Utf8 constant pool entry.
    expect(refs, isEmpty);
  });
}
