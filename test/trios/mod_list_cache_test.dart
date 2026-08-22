import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:trios/models/mod_info.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/models/version.dart';
import 'package:trios/models/version_checker_info.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/trios/mod_list_cache.dart';

ModVariant _variant({
  required String id,
  String version = '1.2.3',
  required Directory modsFolder,
  required Directory gameCoreFolder,
  bool enabled = true,
  VersionCheckerInfo? versionCheckerInfo,
}) => ModVariant(
  modInfo: ModInfo(
    id: id,
    name: 'Mod $id',
    version: Version.parse(version),
    author: 'Someone',
    gameVersion: '0.98a-RC8',
  ),
  versionCheckerInfo: versionCheckerInfo,
  modFolder: Directory('${modsFolder.path}${Platform.pathSeparator}$id'),
  hasNonBrickedModInfo: enabled,
  gameCoreFolder: gameCoreFolder,
);

void main() {
  late Directory modsFolder;
  late Directory gameCoreFolder;
  late ModListCache cache;

  setUpAll(() {
    Constants.configDataFolderPath = Directory.systemTemp.createTempSync(
      'trios_mod_list_cache_test',
    );
  });

  setUp(() {
    modsFolder = Directory.systemTemp.createTempSync('trios_mods_folder');
    gameCoreFolder = Directory.systemTemp.createTempSync('trios_game_core');
    cache = ModListCache();
  });

  tearDown(() async {
    await cache.delete();
    for (final dir in [modsFolder, gameCoreFolder]) {
      if (dir.existsSync()) dir.deleteSync(recursive: true);
    }
  });

  test('saved mods come back the same', () async {
    final saved = [
      _variant(id: 'alpha', modsFolder: modsFolder, gameCoreFolder: gameCoreFolder),
      _variant(
        id: 'beta',
        version: '0.9.5-RC2',
        modsFolder: modsFolder,
        gameCoreFolder: gameCoreFolder,
        enabled: false,
        versionCheckerInfo: VersionCheckerInfo(
          modName: 'Beta',
          modThreadId: '1234',
        ),
      ),
    ];

    await cache.write(saved, modsFolder);
    final loaded = await cache.read(modsFolder);

    expect(loaded, isNotNull);
    expect(loaded!.length, 2);
    expect(loaded.map((v) => v.smolId), saved.map((v) => v.smolId));
    expect(loaded.map((v) => v.modInfo.name), ['Mod alpha', 'Mod beta']);
    expect(loaded.map((v) => v.modInfo.version.toString()), [
      '1.2.3',
      '0.9.5-RC2',
    ]);
    expect(loaded.map((v) => v.hasNonBrickedModInfo), [true, false]);
    expect(loaded.map((v) => v.modFolder.path), saved.map((v) => v.modFolder.path));
    expect(loaded[1].versionCheckerInfo?.modThreadId, '1234');
  });

  test('nothing saved means nothing to show', () async {
    expect(await cache.read(modsFolder), isNull);
  });

  test('a list saved from another mods folder is thrown away', () async {
    await cache.write([
      _variant(id: 'alpha', modsFolder: modsFolder, gameCoreFolder: gameCoreFolder),
    ], modsFolder);

    final otherModsFolder = Directory.systemTemp.createTempSync(
      'trios_other_mods_folder',
    );
    addTearDown(() => otherModsFolder.deleteSync(recursive: true));

    expect(await cache.read(otherModsFolder), isNull);
    expect(cache.file!.existsSync(), isFalse);
  });

  test('an unreadable file is thrown away', () async {
    await cache.write([
      _variant(id: 'alpha', modsFolder: modsFolder, gameCoreFolder: gameCoreFolder),
    ], modsFolder);

    await cache.file!.writeAsString('this is not json {{{');

    expect(await cache.read(modsFolder), isNull);
    expect(cache.file!.existsSync(), isFalse);
  });

  test('saving again replaces what was there', () async {
    await cache.write([
      _variant(id: 'alpha', modsFolder: modsFolder, gameCoreFolder: gameCoreFolder),
    ], modsFolder);
    await cache.write([
      _variant(id: 'beta', modsFolder: modsFolder, gameCoreFolder: gameCoreFolder),
    ], modsFolder);

    final loaded = await cache.read(modsFolder);
    expect(loaded!.map((v) => v.modInfo.id), ['beta']);
  });
}
