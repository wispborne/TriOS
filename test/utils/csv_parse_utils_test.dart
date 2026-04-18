// test/utils/csv_parse_utils_test.dart

import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trios/utils/csv_parse_utils.dart';
import 'package:trios/utils/extensions.dart';

void main() {
  group('removeCsvLineComments', () {
    test('plain line with no comment is unchanged', () {
      expect('a,b,c'.removeCsvLineComments(), 'a,b,c');
    });

    test('strips trailing # comment', () {
      expect('a,b,c # this is a comment'.removeCsvLineComments(), 'a,b,c');
    });

    test('ignores # inside quoted field', () {
      expect(
        'a,"has a # in it",c'.removeCsvLineComments(),
        'a,"has a # in it",c',
      );
    });

    test('row starting with # becomes empty', () {
      expect('#commented,row'.removeCsvLineComments(), '');
    });
  });

  group('stripCsvCommentsAndTrackLines', () {
    test('plain rows pass through with correct line map', () {
      const input = 'name,id\nFoo,foo\nBar,bar\n';
      final result = input.stripCsvCommentsAndTrackLines();
      expect(result.cleanContent, 'name,id\nFoo,foo\nBar,bar');
      expect(result.lineNumberMap, [1, 2, 3]);
    });

    test('blank lines are dropped and line map still points to source', () {
      const input = 'name,id\n\n\nFoo,foo\n\nBar,bar\n';
      final result = input.stripCsvCommentsAndTrackLines();
      expect(result.cleanContent, 'name,id\nFoo,foo\nBar,bar');
      expect(result.lineNumberMap, [1, 4, 6]);
    });

    test('whole-row # comments are removed', () {
      const input = 'name,id\n#Commented,row\nFoo,foo\n';
      final result = input.stripCsvCommentsAndTrackLines();
      expect(result.cleanContent, 'name,id\nFoo,foo');
      expect(result.lineNumberMap, [1, 3]);
    });

    test('# inside a quoted field is not a comment', () {
      const input = 'name,desc\nFoo,"contains # sign"\nBar,bar\n';
      final result = input.stripCsvCommentsAndTrackLines();
      expect(
        result.cleanContent,
        'name,desc\nFoo,"contains # sign"\nBar,bar',
      );
      expect(result.lineNumberMap, [1, 2, 3]);
    });

    test('escaped "" inside quoted field is preserved', () {
      const input = 'name,desc\nFoo,"he said ""hi"" to me"\n';
      final result = input.stripCsvCommentsAndTrackLines();
      expect(
        result.cleanContent,
        'name,desc\nFoo,"he said ""hi"" to me"',
      );
      expect(result.lineNumberMap, [1, 2]);
    });

    test('multi-line quoted field in a good row is preserved', () {
      const input =
          'name,desc\nFoo,"line one\nline two\nline three"\nBar,bar\n';
      final result = input.stripCsvCommentsAndTrackLines();
      expect(
        result.cleanContent,
        'name,desc\nFoo,"line one\nline two\nline three"\nBar,bar',
      );
      // Source lines: header=1, Foo starts at 2, Bar starts at 5.
      expect(result.lineNumberMap, [1, 2, 5]);
    });

    test(
      'commented row containing multi-line quoted field is dropped entirely',
      () {
        // Mirrors the HMI Point Defense Integration shape from hull_mods.csv.
        const input =
            'name,id,desc\n'
            'Integrated Point Defense AI,pointdefenseai,"ignores flares"\n'
            '#Point Defense Integration,pdintegration,"Reduces OP cost.\n'
            '\n'
            'In addition, all PD weapons deal more damage."\n'
            'Integrated Targeting Unit,targetingunit,"Extends range."\n';
        final result = input.stripCsvCommentsAndTrackLines();

        // The commented row and its embedded newlines must be fully gone.
        expect(
          result.cleanContent,
          'name,id,desc\n'
          'Integrated Point Defense AI,pointdefenseai,"ignores flares"\n'
          'Integrated Targeting Unit,targetingunit,"Extends range."',
        );
        // Source lines: header=1, first real row=2, last real row=6.
        expect(result.lineNumberMap, [1, 2, 6]);

        // And CsvToListConverter should parse it cleanly.
        final rows = const CsvToListConverter(
          eol: '\n',
          shouldParseNumbers: false,
        ).convert(result.cleanContent);
        expect(rows.length, 3);
        expect(rows[0], ['name', 'id', 'desc']);
        expect(rows[1][0], 'Integrated Point Defense AI');
        expect(rows[2][0], 'Integrated Targeting Unit');
      },
    );

    test('normalizes CRLF line endings', () {
      const input = 'name,id\r\nFoo,foo\r\nBar,bar\r\n';
      final result = input.stripCsvCommentsAndTrackLines();
      expect(result.cleanContent, 'name,id\nFoo,foo\nBar,bar');
      expect(result.lineNumberMap, [1, 2, 3]);
    });

    test('file without trailing newline still flushes the last row', () {
      const input = 'name,id\nFoo,foo';
      final result = input.stripCsvCommentsAndTrackLines();
      expect(result.cleanContent, 'name,id\nFoo,foo');
      expect(result.lineNumberMap, [1, 2]);
    });
  });

  group('readAsStringUtf8OrLatin1', () {
    test('reads valid UTF-8 normally', () async {
      final tmp = await File(
        '${Directory.systemTemp.path}/trios_csv_utf8_test.txt',
      ).create();
      try {
        await tmp.writeAsString('hello world');
        expect(await tmp.readAsStringUtf8OrLatin1(), 'hello world');
      } finally {
        if (await tmp.exists()) await tmp.delete();
      }
    });

    test('falls back to Latin-1 for Windows-1252 bytes', () async {
      final tmp = await File(
        '${Directory.systemTemp.path}/trios_csv_latin1_test.txt',
      ).create();
      try {
        // 0x96 is a Windows-1252 en-dash and is NOT a valid UTF-8 lead byte.
        // UTF-8 strict decoding would throw; Latin-1 accepts it as U+0096.
        await tmp.writeAsBytes([
          0x61, // a
          0x20, // space
          0x96, // en-dash (Windows-1252)
          0x20, // space
          0x62, // b
        ]);
        final result = await tmp.readAsStringUtf8OrLatin1();
        expect(result.length, 5);
        expect(result.codeUnitAt(0), 0x61);
        expect(result.codeUnitAt(2), 0x96);
        expect(result.codeUnitAt(4), 0x62);
      } finally {
        if (await tmp.exists()) await tmp.delete();
      }
    });
  });
}
