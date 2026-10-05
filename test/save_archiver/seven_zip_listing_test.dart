import 'package:flutter_test/flutter_test.dart';
import 'package:trios/compression/seven_zip/seven_zip.dart';
import 'package:trios/save_archiver/save_archive_tool.dart';

/// Reading `7z l -slt` output. The archiver compares this against the folder
/// it just compressed, so a parser that quietly drops an entry would let a
/// missing file through.
void main() {
  // Real output from 7-Zip 24.09, trimmed.
  const listing = '''
7-Zip (z) 24.09 (x64) : Copyright (c) 1999-2024 Igor Pavlov : 2024-11-28
 64-bit locale=C.UTF-8 Threads:4

Scanning the drive for archives:
1 file, 237 bytes (1 KiB)

Listing archive: /tmp/out.7z

--
Path = /tmp/out.7z
Type = 7z
Physical Size = 237
Headers Size = 225
Method = LZMA2:12
Solid = +
Blocks = 1

----------
Path = save_x
Size = 0
Packed Size = 0
Modified = 2026-09-21 20:35:25.9453472
Attributes = D drwxr-xr-x
CRC = 
Encrypted = -
Method = 
Block = 

Path = save_x/sub
Size = 0
Packed Size = 0
Modified = 2026-09-21 20:35:25.9453472
Attributes = D drwxr-xr-x
CRC = 
Encrypted = -
Method = 
Block = 

Path = save_x/empty.txt
Size = 0
Packed Size = 0
Modified = 2026-09-21 20:35:25.9453472
Attributes = A -rw-r--r--
CRC = 
Encrypted = -
Method = 
Block = 

Path = save_x/descriptor.xml
Size = 3
Packed Size = 12
Modified = 2026-09-21 20:35:25.9453472
Attributes = A -rw-r--r--
CRC = ED6F7A7A
Encrypted = -
Method = LZMA2:12
Block = 0
''';

  test('the archive file itself is not read as an entry', () {
    final entries = parseSevenZipDetailedListing(listing);

    expect(entries.map((entry) => entry.path), isNot(contains('/tmp/out.7z')));
    expect(entries, hasLength(4));
  });

  test('folders are marked as folders', () {
    final entries = parseSevenZipDetailedListing(listing);

    expect(
      entries
          .where((entry) => entry.isDirectory)
          .map((entry) => entry.path)
          .toList(),
      ['save_x', 'save_x/sub'],
    );
  });

  test('sizes and checksums are read', () {
    final entries = parseSevenZipDetailedListing(listing);
    final descriptor = entries.firstWhere(
      (entry) => entry.path == 'save_x/descriptor.xml',
    );

    expect(descriptor.size, 3);
    expect(descriptor.crc32, 0xED6F7A7A);
    expect(descriptor.isDirectory, isFalse);
  });

  test('an empty file has a size but no checksum', () {
    final entries = parseSevenZipDetailedListing(listing);
    final empty = entries.firstWhere(
      (entry) => entry.path == 'save_x/empty.txt',
    );

    expect(empty.size, 0);
    expect(empty.crc32, isNull);
    expect(empty.isDirectory, isFalse);
  });

  test('Windows attributes mark folders too', () {
    const windowsListing = '''
Listing archive: C:\\out.7z

--
Path = C:\\out.7z
Type = 7z

----------
Path = save_x
Size = 0
Attributes = D....
CRC = 

Path = save_x\\descriptor.xml
Size = 7
Attributes = A....
CRC = 12AB34CD
''';

    final entries = parseSevenZipDetailedListing(windowsListing);

    expect(entries, hasLength(2));
    expect(entries.first.isDirectory, isTrue);
    expect(entries.last.path, r'save_x\descriptor.xml');
    expect(entries.last.crc32, 0x12AB34CD);
  });

  test('a listing with no items at all reads as empty', () {
    expect(
      parseSevenZipDetailedListing('''
Listing archive: /tmp/out.7z

--
Path = /tmp/out.7z
Type = 7z

----------
'''),
      isEmpty,
    );
  });

  test('two blocks with no blank line between them stay two entries', () {
    final entries = parseSevenZipDetailedListing('''
----------
Path = a.txt
Size = 1
Path = b.txt
Size = 2
''');

    expect(entries.map((entry) => entry.path), ['a.txt', 'b.txt']);
    expect(entries.last.size, 2);
  });

  group('putting paths in one shape', () {
    test('Windows separators become forward slashes', () {
      expect(
        normalizeArchivePath(r'save_x\nested\file.xml'),
        'save_x/nested/file.xml',
      );
    });

    test('leading and trailing separators are dropped', () {
      expect(normalizeArchivePath('/save_x/nested/'), 'save_x/nested');
    });

    test('a "./" prefix is dropped', () {
      expect(normalizeArchivePath('./save_x/file.xml'), 'save_x/file.xml');
    });

    test('a path already in shape is left alone', () {
      expect(normalizeArchivePath('save_x/file.xml'), 'save_x/file.xml');
    });
  });
}
