// test/mod_info_json_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:trios/models/mod_info_json.dart';
import 'package:trios/models/version.dart';

void main() {
  group('ModInfoJson deserialization tests', () {
    test('Test Knights of Ludd Normal Maps JSON', () {
      final jsonString = '''
      {
        "id": "knights_of_ludd_maps",
        "name": "Knights of Ludd Normal Maps",
        "author": "Selkie & Himemi",
        "version": "1.0",
        "description": "Adds extra graphicslib support to Knights of Ludd content!",
        "gameVersion": "0.97a-RC11",
        "originalGameVersion": "0.96a-RC10"
      }
      ''';

      final modInfo = ModInfoJsonMapper.fromJson(jsonString);

      expect(modInfo.id, 'knights_of_ludd_maps');
      expect(modInfo.name, 'Knights of Ludd Normal Maps');
      expect(modInfo.author, 'Selkie & Himemi');
      expect(modInfo.version, Version.parse('1.0', sanitizeInput: false));
      expect(
        modInfo.description,
        'Adds extra graphicslib support to Knights of Ludd content!',
      );
      expect(modInfo.gameVersion, '0.97a-RC11');
      expect(modInfo.originalGameVersion, '0.96a-RC10');
      expect(modInfo.dependencies, isEmpty);
      expect(modInfo.utility, false);
      expect(modInfo.totalConversion, false);
    });

    test('Test Hazard Mining Incorporated JSON', () {
      final jsonString = '''
      {
        "id":"HMI",
        "name":"Hazard Mining Incorporated",
        "author": "King Alfonzo",
        "version":"0.3.7b",
        "description":"A company created by an enterprising miner, this cut-throat organisation is out to exploit as much of the outer limits of the Sector as possible.",
        "gameVersion": "0.97a-RC8",
        "dependencies": [
            {
                "id": "lw_lazylib",
                "name": "LazyLib"
            },
            {
                "id": "MagicLib",
                "name": "MagicLib"
            }
        ]
      }
      ''';

      final modInfo = ModInfoJsonMapper.fromJson(jsonString);

      expect(modInfo.id, 'HMI');
      expect(modInfo.name, 'Hazard Mining Incorporated');
      expect(modInfo.author, 'King Alfonzo');
      expect(modInfo.version, Version.parse('0.3.7b', sanitizeInput: false));
      expect(
        modInfo.description,
        startsWith('A company created by an enterprising miner'),
      );
      expect(modInfo.gameVersion, '0.97a-RC8');
      expect(modInfo.dependencies.length, 2);

      final dep1 = modInfo.dependencies[0];
      expect(dep1.id, 'lw_lazylib');
      expect(dep1.name, 'LazyLib');
      expect(dep1.version, isNull);

      final dep2 = modInfo.dependencies[1];
      expect(dep2.id, 'MagicLib');
      expect(dep2.name, 'MagicLib');
      expect(dep2.version, isNull);

      expect(modInfo.utility, false);
      expect(modInfo.totalConversion, false);
    });

    test('Test Epta Consortium JSON', () {
      final jsonString = '''
      {
        "id": "seven_nexus",
        "name": "Epta Consortium",
        "author": "xSevenG7x",
        "version": "2.0.4",
        "description": "A consortium that protect AI and fights against the Hegemony. Have fun!",
        "gameVersion": "0.96a-RC8",
        "totalConversion": "false",
        "utility": "false",
        "dependencies": [
          {"id": "lw_lazylib", "name": "LazyLib"},
          {"id": "MagicLib", "name": "MagicLib"}
        ]
      }
      ''';

      final modInfo = ModInfoJsonMapper.fromJson(jsonString);

      expect(modInfo.id, 'seven_nexus');
      expect(modInfo.name, 'Epta Consortium');
      expect(modInfo.author, 'xSevenG7x');
      expect(modInfo.version, Version.parse('2.0.4', sanitizeInput: false));
      expect(modInfo.description, contains('A consortium that protect AI'));
      expect(modInfo.gameVersion, '0.96a-RC8');
      expect(modInfo.utility, false);
      expect(modInfo.totalConversion, false);

      expect(modInfo.dependencies.length, 2);

      final dep1 = modInfo.dependencies[0];
      expect(dep1.id, 'lw_lazylib');
      expect(dep1.name, 'LazyLib');
      expect(dep1.version, isNull);

      final dep2 = modInfo.dependencies[1];
      expect(dep2.id, 'MagicLib');
      expect(dep2.name, 'MagicLib');
      expect(dep2.version, isNull);
    });

    test('Test Iron Shell JSON with VersionObject', () {
      final jsonString = '''
      {
        "id": "timid_xiv",
        "name": "Iron Shell",
        "author": "Techpriest & Selkie",
        "utility": "false",
        "version": { "major": "1", "minor": "18", "patch": "3ad" },
        "description": "Adds a faction dedicated to the XIV Battlegroup and her legacy. Adds multiple XIV ships!",
        "gameVersion": "0.96a"
      }
      ''';

      final modInfo = ModInfoJsonMapper.fromJson(jsonString);

      expect(modInfo.id, 'timid_xiv');
      expect(modInfo.name, 'Iron Shell');
      expect(modInfo.author, 'Techpriest & Selkie');
      expect(modInfo.version, Version.parse('1.18.3ad', sanitizeInput: false));
      expect(
        modInfo.description,
        contains('Adds a faction dedicated to the XIV Battlegroup'),
      );
      expect(modInfo.gameVersion, '0.96a');
      expect(modInfo.utility, false);
      expect(modInfo.totalConversion, false);
    });

    test('Test serialization and deserialization symmetry', () {
      final modInfo = ModInfoJson(
        'test_mod',
        name: 'Test Mod',
        version: Version.parse('1.0.0', sanitizeInput: false),
        author: 'Author Name',
        gameVersion: '0.97a',
        dependencies: [
          Dependency(
            id: 'dep1',
            name: 'Dependency One',
            version: Version.parse('1.2.3', sanitizeInput: false),
          ),
          Dependency(id: 'dep2', name: 'Dependency Two'),
        ],
        utility: true,
        totalConversion: false,
      );

      final jsonMap = modInfo.toMap();
      final jsonString = modInfo.toJson();

      final deserializedModInfo = ModInfoJsonMapper.fromJson(jsonString);

      expect(deserializedModInfo.id, modInfo.id);
      expect(deserializedModInfo.name, modInfo.name);
      expect(deserializedModInfo.version, modInfo.version);
      expect(deserializedModInfo.author, modInfo.author);
      expect(deserializedModInfo.gameVersion, modInfo.gameVersion);
      expect(deserializedModInfo.dependencies.length, 2);

      expect(deserializedModInfo.dependencies[0].id, 'dep1');
      expect(deserializedModInfo.dependencies[0].name, 'Dependency One');
      expect(
        deserializedModInfo.dependencies[0].version,
        Version.parse('1.2.3', sanitizeInput: false),
      );

      expect(deserializedModInfo.dependencies[1].id, 'dep2');
      expect(deserializedModInfo.dependencies[1].name, 'Dependency Two');
      expect(deserializedModInfo.dependencies[1].version, isNull);

      expect(deserializedModInfo.utility, true);
      expect(deserializedModInfo.totalConversion, false);
    });
  });
}
