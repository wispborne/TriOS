import 'package:flutter_test/flutter_test.dart';
import 'package:trios/ship_viewer/models/ship.dart';
import 'package:trios/ship_viewer/skin_collapsing.dart';

Ship _skin(String id, String name, {String baseHullId = 'base'}) =>
    Ship(id: id, name: name, isSkin: true, baseHullId: baseHullId);

CollapsedSkins<Ship> _collapse(List<Ship> ships) =>
    collapseSimilarSkins(ships, (ship) => ship);

List<String> _ids(CollapsedSkins<Ship> result) =>
    result.items.map((ship) => ship.id).toList();

void main() {
  test('skins with the same base hull and name share one row', () {
    final result = _collapse([_skin('b', 'Hubship'), _skin('a', 'Hubship')]);

    expect(_ids(result), ['a']);
    expect(result.groupSizes, {'a': 2});
  });

  test('different names stay separate', () {
    final result = _collapse([_skin('a', 'Crippled'), _skin('b', 'Restored')]);

    expect(_ids(result), ['a', 'b']);
    expect(result.groupSizes, isEmpty);
  });

  test('different base hulls stay separate', () {
    final result = _collapse([
      _skin('a', 'Hubship', baseHullId: 'one'),
      _skin('b', 'Hubship', baseHullId: 'two'),
    ]);

    expect(_ids(result), ['a', 'b']);
  });

  test('base hulls are never collapsed', () {
    final result = _collapse([
      Ship(id: 'a', name: 'Same'),
      Ship(id: 'b', name: 'Same'),
    ]);

    expect(_ids(result), ['a', 'b']);
  });

  test('rows keep their original order', () {
    final result = _collapse([
      Ship(id: 'z', name: 'Base'),
      _skin('c', 'Hubship'),
      Ship(id: 'y', name: 'Other'),
      _skin('b', 'Hubship'),
    ]);

    expect(_ids(result), ['z', 'y', 'b']);
  });

  test('items that are not ships are kept', () {
    final result = collapseSimilarSkins<String>(['x', 'y'], (_) => null);

    expect(result.items, ['x', 'y']);
  });
}
