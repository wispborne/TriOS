import 'package:flutter_test/flutter_test.dart';
import 'package:trios/mod_records/mod_record.dart';
import 'package:trios/mod_records/mod_record_source.dart';

void main() {
  group('ModRecord.downloadedFrom', () {
    test('is null when nothing was recorded', () {
      final record = ModRecord(recordKey: 'mod');
      expect(record.downloadedFrom, isNull);
    });

    test('uses the address TriOS recorded when there is no override', () {
      final record = ModRecord(
        recordKey: 'mod',
        sources: {
          'downloadHistory': DownloadHistorySource(
            lastDownloadedFrom: 'https://example.com/auto.zip',
          ),
        },
      );
      expect(record.downloadedFrom, 'https://example.com/auto.zip');
    });

    test('uses the address the user typed instead', () {
      final record = ModRecord(
        recordKey: 'mod',
        sources: {
          'downloadHistory': DownloadHistorySource(
            lastDownloadedFrom: 'https://example.com/auto.zip',
          ),
        },
        userOverrides: {
          'downloadHistory': DownloadHistorySource(
            lastDownloadedFrom: 'https://discord.com/channels/1/2/3',
          ),
        },
      );
      expect(record.downloadedFrom, 'https://discord.com/channels/1/2/3');
    });

    test('falls back to the recorded address once the override is removed', () {
      final withOverride = ModRecord(
        recordKey: 'mod',
        sources: {
          'downloadHistory': DownloadHistorySource(
            lastDownloadedFrom: 'https://example.com/auto.zip',
          ),
        },
        userOverrides: {
          'downloadHistory': DownloadHistorySource(
            lastDownloadedFrom: 'https://discord.com/channels/1/2/3',
          ),
        },
      );
      final cleared = withOverride.copyWith(userOverrides: const {});
      expect(cleared.downloadedFrom, 'https://example.com/auto.zip');
    });

    test('works for a mod that was only ever typed in by hand', () {
      final record = ModRecord(
        recordKey: 'mod',
        userOverrides: {
          'downloadHistory': DownloadHistorySource(
            lastDownloadedFrom: 'https://drive.google.com/some-folder',
          ),
        },
      );
      expect(record.downloadedFrom, 'https://drive.google.com/some-folder');
    });
  });
}
