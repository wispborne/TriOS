import 'package:flutter_test/flutter_test.dart';
import 'package:trios/mod_manager/batch_installation/mod_id_change.dart';
import 'package:trios/models/mod_info.dart';
import 'package:trios/models/version.dart';
import 'package:trios/trios/download_manager/download_manager.dart';
import 'package:trios/trios/download_manager/download_request.dart';
import 'package:trios/trios/download_manager/download_task.dart';

ModInfo _modInfo(String id) =>
    ModInfo(id: id, name: 'Mod $id', version: Version.parse('1.0.0'));

DownloadTask _task() =>
    DownloadTask(DownloadRequest('https://example.com/mod.zip', '', null));

/// A download started from an update button for the mod with [oldId].
ModDownload _updateDownload(String oldId) =>
    ModDownload('id', 'Mod $oldId', _task(), _modInfo(oldId));

void main() {
  group('detectModIdChange', () {
    test('returns null when the installed mod has the same ID', () {
      final result = detectModIdChange(
        download: _updateDownload('old_mod'),
        modsInArchive: 1,
        installedMods: [_modInfo('old_mod')],
      );

      expect(result, isNull);
    });

    test('returns both mods when the installed mod has a different ID', () {
      final download = _updateDownload('old_mod');
      final newModInfo = _modInfo('new_mod');

      final result = detectModIdChange(
        download: download,
        modsInArchive: 1,
        installedMods: [newModInfo],
      );

      expect(result, isNotNull);
      expect(result!.oldModInfo, same(download.modInfo));
      expect(result.newModInfo, same(newModInfo));
    });

    test('returns null when two mods installed', () {
      final result = detectModIdChange(
        download: _updateDownload('old_mod'),
        modsInArchive: 2,
        installedMods: [_modInfo('new_mod'), _modInfo('library')],
      );

      expect(result, isNull);
    });

    test(
      'returns null when the archive held two mods and only one installed',
      () {
        final result = detectModIdChange(
          download: _updateDownload('old_mod'),
          modsInArchive: 2,
          installedMods: [_modInfo('new_mod')],
        );

        expect(result, isNull);
      },
    );

    test('returns null for a plain download that is not tied to a mod', () {
      final result = detectModIdChange(
        download: Download('id', 'Some mod', _task()),
        modsInArchive: 1,
        installedMods: [_modInfo('new_mod')],
      );

      expect(result, isNull);
    });

    test('returns null when nothing installed', () {
      final result = detectModIdChange(
        download: _updateDownload('old_mod'),
        modsInArchive: 1,
        installedMods: [],
      );

      expect(result, isNull);
    });
  });
}
