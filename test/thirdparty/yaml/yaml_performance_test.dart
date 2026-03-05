import 'package:flutter_test/flutter_test.dart';
import 'package:trios/thirdparty/yaml/yaml.dart';

/// Scale factor applied to every iteration count. Increase to run longer.
const int kIterationMultiplier = 30;

void _benchmark(String label, int iterations, void Function() fn) {
  iterations = (iterations * kIterationMultiplier).round();
  final sw = Stopwatch()..start();
  for (var i = 0; i < iterations; i++) {
    fn();
  }
  sw.stop();
  final ms = sw.elapsedMilliseconds;
  final rate =
      ms > 0 ? (iterations * 1000 / ms).toStringAsFixed(0) : 'inf';
  print('$label: $iterations iterations in ${ms}ms ($rate docs/sec)');
}

void main() {
  group('loadYaml performance', () {
    test('small flat map (10 entries)', () {
      const yaml = '''
key1: value1
key2: value2
key3: value3
key4: value4
key5: value5
key6: value6
key7: value7
key8: value8
key9: value9
key10: value10
''';
      const iterations = 1000;
      dynamic result;
      _benchmark('small flat map', iterations, () {
        result = loadYaml(yaml);
      });

      expect(result, isA<YamlMap>());
      expect((result as YamlMap).length, 10);
    });

    test('large flat map (100 entries)', () {
      final buf = StringBuffer();
      for (var i = 1; i <= 100; i++) {
        buf.writeln('key$i: value$i');
      }
      final yaml = buf.toString();

      const iterations = 500;
      dynamic result;
      _benchmark('large flat map', iterations, () {
        result = loadYaml(yaml);
      });

      expect(result, isA<YamlMap>());
      expect((result as YamlMap).length, 100);
    });

    test('deeply nested map (10 levels)', () {
      // level1:\n  level2:\n    ...        level10: deep_value
      final buf = StringBuffer();
      for (var i = 1; i <= 9; i++) {
        buf.write('  ' * (i - 1));
        buf.writeln('level$i:');
      }
      buf.write('  ' * 9);
      buf.write('level10: deep_value');
      final yaml = buf.toString();

      const iterations = 500;
      dynamic result;
      _benchmark('deeply nested map', iterations, () {
        result = loadYaml(yaml);
      });

      expect(result, isA<YamlMap>());
      // Walk to the deepest level to verify structure
      var node = result as YamlMap;
      for (var i = 1; i < 10; i++) {
        node = node['level$i'] as YamlMap;
      }
      expect(node['level10'], 'deep_value');
    });

    test('large list (500 scalars)', () {
      final buf = StringBuffer();
      for (var i = 1; i <= 500; i++) {
        buf.writeln('- item$i');
      }
      final yaml = buf.toString();

      const iterations = 200;
      dynamic result;
      _benchmark('large list', iterations, () {
        result = loadYaml(yaml);
      });

      expect(result, isA<YamlList>());
      expect((result as YamlList).length, 500);
    });

    test('anchors and aliases (20 anchors x 5 references each)', () {
      final buf = StringBuffer();
      for (var i = 1; i <= 20; i++) {
        buf.writeln('anchor$i: &anchor$i {name: item$i, value: $i}');
        for (var j = 1; j <= 5; j++) {
          buf.writeln('ref${i}_$j: *anchor$i');
        }
      }
      final yaml = buf.toString();

      const iterations = 500;
      dynamic result;
      _benchmark('anchors and aliases', iterations, () {
        result = loadYaml(yaml);
      });

      expect(result, isA<YamlMap>());
      // 20 anchor definitions + 20 * 5 alias references = 120 keys
      expect((result as YamlMap).length, 120);
    });

    test('multi-line block scalars (literal and folded)', () {
      const yaml = '''
literal_block: |
  Line one of a literal block scalar.
  Line two with some extra content here.
  Line three continues on and on.
  Line four wraps up the literal block.
  Line five ends the section.

folded_block: >
  This folded block scalar joins
  adjacent lines together with
  a single space between them
  until a blank line is found.

  This starts a new paragraph in
  the folded block scalar output.
''';
      const iterations = 500;
      dynamic result;
      _benchmark('block scalars', iterations, () {
        result = loadYaml(yaml);
      });

      expect(result, isA<YamlMap>());
      expect((result as YamlMap).containsKey('literal_block'), isTrue);
      expect((result).containsKey('folded_block'), isTrue);
    });

    test('flow style (inline maps and lists)', () {
      const yaml = '''
point: {x: 1.5, y: 2.7, z: -0.3}
colors: [red, green, blue, alpha]
matrix: [[1, 0, 0], [0, 1, 0], [0, 0, 1]]
config: {debug: false, retries: 3, tags: [a, b, c]}
nested: {a: {b: {c: {d: end}}}}
''';
      const iterations = 500;
      dynamic result;
      _benchmark('flow style', iterations, () {
        result = loadYaml(yaml);
      });

      expect(result, isA<YamlMap>());
      expect((result as YamlMap)['colors'], isA<YamlList>());
      expect((result)['colors'].length, 4);
    });

    test('special characters and quoted strings', () {
      // ignore: unnecessary_raw_strings
      const yaml = r'''
unicode_inline: "\u4e16\u754c \u00e9\u00e0\u00fc"
tab_escape: "col1\tcol2\tcol3"
newline_escape: "line1\nline2\nline3"
single_quote: 'it''s a test with ''embedded'' quotes'
backslash: "path\\to\\file"
null_value: ~
bool_values: [true, false, yes, no]
int_values: [0, 42, -7]
float_values: [3.14, -2.7e10]
empty_string: ''
''';
      const iterations = 500;
      dynamic result;
      _benchmark('special characters', iterations, () {
        result = loadYaml(yaml);
      });

      expect(result, isA<YamlMap>());
      expect((result as YamlMap)['null_value'], isNull);
      expect((result)['bool_values'], isA<YamlList>());
    });
  });

  group('loadYamlValue performance', () {
    test('small flat map (10 entries)', () {
      const yaml = '''
key1: value1
key2: value2
key3: value3
key4: value4
key5: value5
key6: value6
key7: value7
key8: value8
key9: value9
key10: value10
''';
      const iterations = 1000;
      dynamic result;
      _benchmark('loadYamlValue small flat map', iterations, () {
        result = loadYamlValue(yaml);
      });

      expect(result, isA<Map>());
      expect((result as Map).length, 10);
      expect(result['key1'], 'value1');
    });

    test('large flat map (100 entries)', () {
      final buf = StringBuffer();
      for (var i = 1; i <= 100; i++) {
        buf.writeln('key$i: value$i');
      }
      final yaml = buf.toString();

      const iterations = 500;
      dynamic result;
      _benchmark('loadYamlValue large flat map', iterations, () {
        result = loadYamlValue(yaml);
      });

      expect(result, isA<Map>());
      expect((result as Map).length, 100);
    });

    test('deeply nested map (10 levels)', () {
      final buf = StringBuffer();
      for (var i = 1; i <= 9; i++) {
        buf.write('  ' * (i - 1));
        buf.writeln('level$i:');
      }
      buf.write('  ' * 9);
      buf.write('level10: deep_value');
      final yaml = buf.toString();

      const iterations = 500;
      dynamic result;
      _benchmark('loadYamlValue deeply nested map', iterations, () {
        result = loadYamlValue(yaml);
      });

      expect(result, isA<Map>());
      var node = result as Map;
      for (var i = 1; i < 10; i++) {
        node = node['level$i'] as Map;
      }
      expect(node['level10'], 'deep_value');
    });

    test('large list (500 scalars)', () {
      final buf = StringBuffer();
      for (var i = 1; i <= 500; i++) {
        buf.writeln('- item$i');
      }
      final yaml = buf.toString();

      const iterations = 200;
      dynamic result;
      _benchmark('loadYamlValue large list', iterations, () {
        result = loadYamlValue(yaml);
      });

      expect(result, isA<List>());
      expect((result as List).length, 500);
    });

    test('anchors and aliases (20 anchors x 5 references each)', () {
      final buf = StringBuffer();
      for (var i = 1; i <= 20; i++) {
        buf.writeln('anchor$i: &anchor$i {name: item$i, value: $i}');
        for (var j = 1; j <= 5; j++) {
          buf.writeln('ref${i}_$j: *anchor$i');
        }
      }
      final yaml = buf.toString();

      const iterations = 500;
      dynamic result;
      _benchmark('loadYamlValue anchors and aliases', iterations, () {
        result = loadYamlValue(yaml);
      });

      expect(result, isA<Map>());
      expect((result as Map).length, 120);
    });

    test('multi-line block scalars (literal and folded)', () {
      const yaml = '''
literal_block: |
  Line one of a literal block scalar.
  Line two with some extra content here.
  Line three continues on and on.
  Line four wraps up the literal block.
  Line five ends the section.

folded_block: >
  This folded block scalar joins
  adjacent lines together with
  a single space between them
  until a blank line is found.

  This starts a new paragraph in
  the folded block scalar output.
''';
      const iterations = 500;
      dynamic result;
      _benchmark('loadYamlValue block scalars', iterations, () {
        result = loadYamlValue(yaml);
      });

      expect(result, isA<Map>());
      expect((result as Map).containsKey('literal_block'), isTrue);
      expect(result.containsKey('folded_block'), isTrue);
    });

    test('flow style (inline maps and lists)', () {
      const yaml = '''
point: {x: 1.5, y: 2.7, z: -0.3}
colors: [red, green, blue, alpha]
matrix: [[1, 0, 0], [0, 1, 0], [0, 0, 1]]
config: {debug: false, retries: 3, tags: [a, b, c]}
nested: {a: {b: {c: {d: end}}}}
''';
      const iterations = 500;
      dynamic result;
      _benchmark('loadYamlValue flow style', iterations, () {
        result = loadYamlValue(yaml);
      });

      expect(result, isA<Map>());
      expect((result as Map)['colors'], isA<List>());
      expect((result)['colors'].length, 4);
    });

    test('special characters and quoted strings', () {
      // ignore: unnecessary_raw_strings
      const yaml = r'''
unicode_inline: "\u4e16\u754c \u00e9\u00e0\u00fc"
tab_escape: "col1\tcol2\tcol3"
newline_escape: "line1\nline2\nline3"
single_quote: 'it''s a test with ''embedded'' quotes'
backslash: "path\\to\\file"
null_value: ~
bool_values: [true, false, yes, no]
int_values: [0, 42, -7]
float_values: [3.14, -2.7e10]
empty_string: ''
''';
      const iterations = 500;
      dynamic result;
      _benchmark('loadYamlValue special characters', iterations, () {
        result = loadYamlValue(yaml);
      });

      expect(result, isA<Map>());
      expect((result as Map)['null_value'], isNull);
      expect(result['bool_values'], isA<List>());
    });
  });
}
