import 'package:flutter_test/flutter_test.dart';
import 'package:trios/utils/strip_markdown.dart';

void main() {
  test('takes off emphasis markers', () {
    expect(stripMarkdown('**bold** and *italic*'), 'bold and italic');
    expect(stripMarkdown('___all in___ and ~~gone~~'), 'all in and gone');
    expect(stripMarkdown('***everything***'), 'everything');
  });

  test('leaves underscores inside words alone', () {
    expect(
      stripMarkdown('lw_lazylib and mod_info.json'),
      'lw_lazylib and mod_info.json',
    );
  });

  test('keeps link text, drops the address', () {
    expect(
      stripMarkdown('See [the forum](https://example.com/thread) for more.'),
      'See the forum for more.',
    );
    expect(stripMarkdown('![a ship](ship.png)'), 'a ship');
    expect(stripMarkdown('<https://example.com>'), 'https://example.com');
  });

  test('takes off headings, quotes, and dividers', () {
    expect(
      stripMarkdown('# Title\n\n> quoted line\n\n---\n\nBody'),
      'Title\n\nquoted line\n\nBody',
    );
  });

  test('leaves # alone when it is not a heading', () {
    expect(stripMarkdown('#1 rated faction mod'), '#1 rated faction mod');
    expect(stripMarkdown('#hashtag'), '#hashtag');
  });

  test('bullets keep a dash', () {
    expect(stripMarkdown('* one\n* two'), '- one\n- two');
    expect(stripMarkdown('- one\n- two'), '- one\n- two');
  });

  test('takes off code marks', () {
    expect(stripMarkdown('Run `flutter test` now'), 'Run flutter test now');
    expect(stripMarkdown('```dart\nvar a = 1;\n```'), 'var a = 1;');
  });

  test('a backslash means show the character', () {
    expect(stripMarkdown(r'2 \* 3 \= 6'), r'2 * 3 \= 6');
  });

  test('leaves plain text as it was', () {
    const plain =
        'Adds 12 new ships. Requires LazyLib.\n\nNot save compatible.';
    expect(stripMarkdown(plain), plain);
  });
}
