import 'package:flutter_test/flutter_test.dart';
import 'package:trios/starsector_json/starsector_json.dart';

void main() {
  test('leaves a file with nothing to strip completely alone', () {
    const text = '{\n  "a": 1\n}';
    expect(removeHashComments(text), same(text));
  });

  test('strips a comment to the end of the line but keeps the newline', () {
    expect(
      removeHashComments('{ # a note\n  "a": 1\n}'),
      '{ \n  "a": 1\n}',
    );
  });

  test('drops carriage returns', () {
    expect(removeHashComments('{\r\n"a": 1\r\n}'), '{\n"a": 1\n}');
  });

  test('keeps a # inside a quoted string', () {
    expect(removeHashComments('{"a": "x#y"}'), '{"a": "x#y"}');
  });

  test('a comment on its own line leaves an empty line', () {
    expect(removeHashComments('{\n# gone\n"a": 1}'), '{\n\n"a": 1}');
  });

  test('a comment can run to the end of the file', () {
    expect(removeHashComments('{"a": 1} # trailing'), '{"a": 1} ');
  });

  // The game counts every double quote, so a quote written as \" flips the
  // flag the wrong way and a later # is treated as a comment. Here the four
  // quotes before the # leave the flag off, so the rest of the line is lost.
  test('an escaped quote confuses the string tracking, same as the game', () {
    expect(removeHashComments(r'{"a": "x \" # y"}'), r'{"a": "x \" ');
  });

  // With an odd number of quotes before it the # is treated as being inside a
  // string, and the line survives.
  test('an even earlier escaped quote leaves the line intact', () {
    expect(
      removeHashComments(r'{"a": "say \"hi\" #x"}'),
      r'{"a": "say \"hi\" #x"}',
    );
  });

  test('a line break clears the inside-a-string flag', () {
    // The unbalanced quote on the first line does not carry over, so the # on
    // the second line still starts a comment.
    expect(removeHashComments('{"a\n# gone\n}'), '{"a\n\n}');
  });

  test('a quote inside a comment still flips the flag', () {
    // One quote in the comment turns the flag on, so the # on the same line
    // after it would not start a comment. It is already inside one, so the
    // visible result is just the truncated line.
    expect(removeHashComments('a # one " two # three\nb'), 'a \nb');
  });
}
