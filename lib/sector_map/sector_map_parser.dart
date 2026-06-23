import 'dart:convert';

import 'package:trios/sector_map/finder/hazard.dart';
import 'package:trios/sector_map/models/sector.dart';
import 'package:xml/xml_events.dart';

/// Landmark `j0.f3` type ids the finder cares about.
const _landmarkTypeIds = {
  'derelict_cryosleeper',
  'inactive_gate',
  'coronal_tap',
};

/// `j0.f3` type id marking a stable-location entity.
const _stableLocationTypeId = 'stable_location';

/// Parses a Starsector `campaign.xml` (a Java XStream object graph) into the
/// minimal [Sector] model needed to render the hyperspace overview.
///
/// This is a single streaming pass that harvests only map-relevant data and
/// ignores everything else (fleets, commodities, officers, memory, etc.). It is
/// a pure, top-level function so it can run on a background isolate.
///
/// Approach (validated against 44 real saves; see the parse spike in
/// `test/`): systems are positioned via `UFHLOrbt`
/// (UpdateFromHyperspaceLocation), which carries `s`=starSystem and `a`=anchor
/// token; the token's `loc` is the hyperspace position. Markets live in a
/// central economy list and join to their system via
/// `primaryEntity -> containingLocation (cL) -> Sstm`.
Sector parseCampaignXml(String xml, {String gameVersion = ''}) {
  final p = _Parser();
  return p.parse(xml, gameVersion);
}

class _Frame {
  final String name;
  final String? cl;
  final String? z;
  final String? ref;
  final StringBuffer text = StringBuffer();

  String? containingSystemId; // from <cL cl="Sstm" ref=N>
  String? locText; // direct <loc> child text
  String? orbitSystemId; // UFHLOrbt <s cl="Sstm" ref|z>
  String? orbitAnchorId; // UFHLOrbt <a ... ref|z>
  String? conId; // <con> child id (def or ref)
  String? j0Text; // packed JSON blob (planet/star)
  bool isStarTagged = false; // has <st>star</st>
  String? planetType; // direct <type> child of a Plnt
  final List<String> conditionIds = []; // MCon ids found within a Plnt
  String? marketFactionId;
  String? marketSize;
  String? marketName;
  String? marketPrimaryEntityId;

  _Frame(this.name, this.cl, this.z, this.ref);
}

bool _isClass(_Frame? x, String cls) =>
    x != null && (x.cl == cls || x.name == cls);

class _Parser {
  final stack = <_Frame>[];

  // Collected, keyed by Sstm object id.
  final sstm = <String, _SstmInfo>{};
  final conName = <String, String>{};
  final tokenLoc = <String, ({double x, double y})>{}; // anchor token -> pos
  final ufhl = <({String systemId, String anchorId})>[];
  final entityToSystem = <String, String>{}; // entityId -> systemId
  final starColor = <String, List<int>>{}; // systemId -> rgba
  final markets = <_RawMarket>[];
  final fleetLoc = <String, ({double x, double y})>{}; // fltId -> own loc
  String? playerFleetRef;

  // Finder data.
  // Non-star planets, keyed by Plnt object id.
  final plntInfo = <String, ({String type, String name, String systemId})>{};
  // Conditions per market primaryEntity (planet/entity id) -> condition ids.
  final marketConditionsByEntity = <String, List<String>>{};
  final stableLocBySystem = <String, int>{}; // systemId -> count
  final landmarks = <SectorLandmark>[];

  static String? _attr(XmlStartElementEvent e, String n) {
    for (final a in e.attributes) {
      if (a.name == n) return a.value;
    }
    return null;
  }

  Sector parse(String xml, String gameVersion) {
    for (final event in parseEvents(xml)) {
      if (event is XmlStartElementEvent) {
        _onStart(event);
      } else if (event is XmlTextEvent) {
        if (stack.isNotEmpty) stack.last.text.write(event.value);
      } else if (event is XmlEndElementEvent) {
        if (stack.isEmpty) continue;
        _onClose(stack.removeLast());
      }
    }
    return _assemble(gameVersion);
  }

  void _onStart(XmlStartElementEvent e) {
    final f = _Frame(e.name, _attr(e, 'cl'), _attr(e, 'z'), _attr(e, 'ref'));

    // Sstm definition: literal <Sstm> or any element with cl="Sstm", with a z
    // and no ref.
    if ((e.name == 'Sstm' || f.cl == 'Sstm') && f.z != null && f.ref == null) {
      sstm[f.z!] = _SstmInfo(
        name: _attr(e, 'dN') ?? _attr(e, 'bN') ?? 'Unknown',
        baseName: _attr(e, 'bN') ?? _attr(e, 'dN') ?? 'Unknown',
        type: _attr(e, 'ty') ?? '?',
      );
    }

    // CampaignEngine.playerFleet reference.
    if (e.name == 'playerFleet' && f.ref != null) playerFleetRef = f.ref;

    // MCon condition: attach its id to the nearest enclosing market. Conditions
    // are a market's field, so walking to the market (not the planet) works for
    // both colonized markets (nested in the Plnt) and standalone uninhabited
    // planet markets (serialized in the economy list, joined back via
    // primaryEntity). The planet/system join happens in assembly.
    if (e.name == 'MCon' || f.cl == 'MCon') {
      final id = _attr(e, 'i');
      if (id != null) {
        for (var i = stack.length - 1; i >= 0; i--) {
          if (_isClass(stack[i], 'Market')) {
            stack[i].conditionIds.add(id);
            break;
          }
        }
      }
    }

    if (e.isSelfClosing) {
      _onClose(f);
    } else {
      stack.add(f);
    }
  }

  void _onClose(_Frame f) {
    final parent = stack.isNotEmpty ? stack.last : null;
    final text = f.text.toString().trim();

    // entity -> containing system, via <cL cl="Sstm" ref=N>
    if (f.name == 'cL' && f.cl == 'Sstm' && f.ref != null && parent != null) {
      parent.containingSystemId = f.ref;
    }
    if (f.z != null && f.containingSystemId != null) {
      entityToSystem[f.z!] = f.containingSystemId!;
    }

    // direct <loc> child -> remember on the parent frame
    if (f.name == 'loc' && parent != null) parent.locText = text;

    // <j0> packed blob -> remember on the parent frame
    if (f.name == 'j0' && parent != null) parent.j0Text = text;

    // direct <type> child of a Plnt -> planet type
    if (f.name == 'type' && _isClass(parent, 'Plnt')) {
      parent!.planetType ??= text;
    }

    // <st>star</st> tag -> mark the nearest enclosing Plnt as a star
    if (f.name == 'st' && text == 'star') {
      for (var i = stack.length - 1; i >= 0; i--) {
        if (_isClass(stack[i], 'Plnt')) {
          stack[i].isStarTagged = true;
          break;
        }
      }
    }

    // a LocationToken with a position -> tokenLoc[id]
    if (_isClass(f, 'LocationToken') && f.z != null && f.locText != null) {
      final pos = _parseVec(f.locText!);
      if (pos != null) tokenLoc[f.z!] = pos;
    }

    // UFHLOrbt children: s = system, a = anchor token
    if (_isClass(parent, 'UFHLOrbt')) {
      if (f.name == 's' && f.cl == 'Sstm') parent!.orbitSystemId = f.ref ?? f.z;
      if (f.name == 'a') parent!.orbitAnchorId = f.ref ?? f.z;
    }
    if (_isClass(f, 'UFHLOrbt') &&
        f.orbitSystemId != null &&
        f.orbitAnchorId != null) {
      ufhl.add((systemId: f.orbitSystemId!, anchorId: f.orbitAnchorId!));
    }

    // star color: a star-tagged Plnt with a containing system + j0 color
    if (_isClass(f, 'Plnt') &&
        f.isStarTagged &&
        f.containingSystemId != null &&
        f.j0Text != null) {
      final rgba = _colorFromJ0(f.j0Text!);
      if (rgba != null) {
        starColor.putIfAbsent(f.containingSystemId!, () => rgba);
      }
    }

    // surveyable planet: remember every non-star Plnt; its conditions (if any)
    // are joined from its market in assembly (markets may be serialized after
    // the planet, so we can't read them here).
    if (_isClass(f, 'Plnt') &&
        !f.isStarTagged &&
        f.z != null &&
        f.containingSystemId != null &&
        f.planetType != null &&
        !_isStarType(f.planetType!)) {
      plntInfo[f.z!] = (
        type: f.planetType!,
        name: _stringFromJ0(f.j0Text, 'f0') ?? '',
        systemId: f.containingSystemId!,
      );
    }

    // market conditions -> keyed by the market's primaryEntity (its planet).
    if (_isClass(f, 'Market') &&
        f.marketPrimaryEntityId != null &&
        f.conditionIds.isNotEmpty) {
      marketConditionsByEntity[f.marketPrimaryEntityId!] = List.of(
        f.conditionIds,
      );
    }

    // stable locations & landmarks: CCEnt identified by j0.f3 type id
    if (_isClass(f, 'CCEnt') &&
        f.containingSystemId != null &&
        f.j0Text != null) {
      final f3 = _stringFromJ0(f.j0Text, 'f3');
      if (f3 == _stableLocationTypeId) {
        stableLocBySystem.update(
          f.containingSystemId!,
          (c) => c + 1,
          ifAbsent: () => 1,
        );
      } else if (f3 != null && _landmarkTypeIds.contains(f3)) {
        landmarks.add(
          SectorLandmark(
            typeId: f3,
            name: _stringFromJ0(f.j0Text, 'f0') ?? f3,
            systemId: f.containingSystemId!,
          ),
        );
      }
    }

    // fleet own loc (for resolving the player marker later)
    if (_isClass(f, 'Flt') && f.z != null && f.locText != null) {
      final pos = _parseVec(f.locText!);
      if (pos != null) fleetLoc[f.z!] = pos;
    }

    // constellation name: <name> under <spec> under a <con z=> def
    if (f.name == 'name' && parent?.name == 'spec') {
      for (var i = stack.length - 1; i >= 0; i--) {
        if (stack[i].name == 'con' && stack[i].z != null) {
          conName.putIfAbsent(stack[i].z!, () => text);
          break;
        }
      }
    }
    // <con> child of a Sstm -> attach constellation id (def or ref)
    if (f.name == 'con' && parent != null) {
      final conId = f.z ?? f.ref;
      if (conId != null && parent.z != null && sstm.containsKey(parent.z)) {
        sstm[parent.z!]!.conId = conId;
      }
    }

    // Market: factionId / size / name / primaryEntity from direct children
    if (_isClass(parent, 'Market')) {
      if (f.name == 'factionId') parent!.marketFactionId = text;
      if (f.name == 'size') parent!.marketSize ??= text;
      if (f.name == 'name') parent!.marketName ??= text;
      if (f.name == 'primaryEntity') parent!.marketPrimaryEntityId = f.z ?? f.ref;
    }
    if (_isClass(f, 'Market') && f.marketFactionId != null) {
      markets.add(
        _RawMarket(
          factionId: f.marketFactionId!,
          size: int.tryParse(f.marketSize ?? '') ?? 0,
          name: f.marketName ?? '',
          entityId: f.marketPrimaryEntityId,
        ),
      );
    }
  }

  Sector _assemble(String gameVersion) {
    // system -> hyperspace position (dedup by system, first anchor wins)
    final systemPos = <String, ({double x, double y})>{};
    for (final o in ufhl) {
      if (systemPos.containsKey(o.systemId)) continue;
      final loc = tokenLoc[o.anchorId];
      if (loc != null) systemPos[o.systemId] = loc;
    }

    // planets per system, joining each planet to its market's conditions.
    final planetsBySystem = <String, List<SectorPlanet>>{};
    plntInfo.forEach((id, info) {
      final conds = marketConditionsByEntity[id] ?? const <String>[];
      (planetsBySystem[info.systemId] ??= []).add(
        SectorPlanet(
          name: info.name,
          type: info.type,
          conditionIds: List.unmodifiable(conds),
          hazardRating: computeHazardRating(conds),
        ),
      );
    });

    // markets per system, via entity -> system (orphans skipped)
    final marketsBySystem = <String, List<SectorMarket>>{};
    for (final m in markets) {
      final sysId = m.entityId == null ? null : entityToSystem[m.entityId!];
      if (sysId == null) continue;
      (marketsBySystem[sysId] ??= []).add(
        SectorMarket(factionId: m.factionId, size: m.size, name: m.name),
      );
    }

    final usedConIds = <String>{};
    final systems = <SectorSystem>[];
    for (final entry in systemPos.entries) {
      final info = sstm[entry.key];
      if (info == null) continue;
      if (info.conId != null) usedConIds.add(info.conId!);
      systems.add(
        SectorSystem(
          id: entry.key,
          name: info.name,
          baseName: info.baseName,
          type: info.type,
          constellationId: info.conId,
          x: entry.value.x,
          y: entry.value.y,
          starColor: starColor[entry.key],
          markets: marketsBySystem[entry.key] ?? const [],
          planets: planetsBySystem[entry.key] ?? const [],
          stableLocationCount: stableLocBySystem[entry.key] ?? 0,
        ),
      );
    }

    final constellations = usedConIds
        .map(
          (id) => SectorConstellation(id: id, name: conName[id] ?? 'Unknown'),
        )
        .toList();

    // player marker: if in a system, use that system's hyperspace position;
    // otherwise the fleet's own loc (which is hyperspace coords).
    ({double x, double y})? playerPos;
    if (playerFleetRef != null) {
      final sysId = entityToSystem[playerFleetRef!];
      if (sysId != null) {
        playerPos = systemPos[sysId];
      } else {
        playerPos = fleetLoc[playerFleetRef!];
      }
    }

    // Keep only landmarks whose system is on the map.
    final systemIds = systems.map((s) => s.id).toSet();
    final keptLandmarks =
        landmarks.where((l) => systemIds.contains(l.systemId)).toList();

    return Sector(
      systems: systems,
      constellations: constellations,
      landmarks: keptLandmarks,
      playerX: playerPos?.x,
      playerY: playerPos?.y,
      gameVersion: gameVersion,
    );
  }
}

class _SstmInfo {
  final String name;
  final String baseName;
  final String type;
  String? conId;
  _SstmInfo({required this.name, required this.baseName, required this.type});
}

class _RawMarket {
  final String factionId;
  final int size;
  final String name;
  final String? entityId;
  _RawMarket({
    required this.factionId,
    required this.size,
    required this.name,
    required this.entityId,
  });
}

/// Parses a Starsector vector serialized as "x|y".
({double x, double y})? _parseVec(String s) {
  final parts = s.split('|');
  if (parts.length != 2) return null;
  final x = double.tryParse(parts[0]);
  final y = double.tryParse(parts[1]);
  if (x == null || y == null) return null;
  return (x: x, y: y);
}

/// True if a planet `<type>` id is actually a star (or star-like) rather than a
/// surveyable planet.
bool _isStarType(String type) =>
    type.startsWith('star_') ||
    type == 'black_hole' ||
    type == 'nebula' ||
    type == 'neutron_star' ||
    type == 'pulsar';

/// Extracts a string field (e.g. `f0` name, `f3` custom type id) from a packed
/// `j0` JSON blob. Returns null if absent or malformed.
String? _stringFromJ0(String? j0, String key) {
  if (j0 == null) return null;
  try {
    final map = jsonDecode(j0);
    final v = map is Map ? map[key] : null;
    return v is String ? v : null;
  } catch (_) {
    return null;
  }
}

/// Extracts the RGBA color (`f2`) from a planet/star `j0` packed JSON blob,
/// e.g. `{"f6":0,"f0":"Galatia","f2":[255,245,225,255],"f4":"galatia"}`.
List<int>? _colorFromJ0(String j0) {
  try {
    final map = jsonDecode(j0);
    final f2 = map is Map ? map['f2'] : null;
    if (f2 is List && f2.length >= 3) {
      return f2.map((e) => (e as num).toInt()).toList();
    }
  } catch (_) {
    // malformed blob — no color
  }
  return null;
}
