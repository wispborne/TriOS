import 'package:flutter_test/flutter_test.dart';
import 'package:trios/mod_manager/homebrew_grid/wisp_grid.dart';
import 'package:trios/mod_manager/homebrew_grid/wisp_grid_state.dart';

class _FakeItem implements WispGridItem {
  @override
  final String key;

  _FakeItem(this.key);
}

WispGridColumn<_FakeItem> _column(String key, {required int position}) =>
    WispGridColumn<_FakeItem>(
      key: key,
      name: key,
      isSortable: false,
      csvValue: null,
      defaultState: WispGridColumnState(position: position, width: 100),
    );

WispGridState _stateWith(Map<String, WispGridColumnState> columnsState) =>
    WispGridState(columnsState: columnsState, groupingSetting: null);

void main() {
  final columns = [
    _column('name', position: 0),
    _column('author', position: 1),
    _column('version', position: 2),
    _column('range', position: 3),
  ];

  test('nothing is frozen by default, so the order is unchanged', () {
    final order = _stateWith(
      {},
    ).sortedVisibleColumns(columns).map((e) => e.key).toList();

    expect(order, ['name', 'author', 'version', 'range']);
  });

  test('frozen columns move to the front, everything keeps its order', () {
    final state = _stateWith({
      'version': const WispGridColumnState(
        position: 2,
        width: 100,
        isFrozen: true,
      ),
      'name': const WispGridColumnState(
        position: 0,
        width: 100,
        isFrozen: true,
      ),
    });

    final order = state
        .sortedVisibleColumns(columns)
        .map((e) => e.key)
        .toList();

    expect(order, ['name', 'version', 'author', 'range']);
    expect(state.frozenVisibleColumns(columns).map((e) => e.key), [
      'name',
      'version',
    ]);
  });

  test('unfreezing puts a column back where it was', () {
    final frozen = _stateWith({
      'range': const WispGridColumnState(
        position: 3,
        width: 100,
        isFrozen: true,
      ),
    });
    expect(frozen.sortedVisibleColumns(columns).map((e) => e.key), [
      'range',
      'name',
      'author',
      'version',
    ]);

    final unfrozen = _stateWith({
      'range': const WispGridColumnState(position: 3, width: 100),
    });
    expect(unfrozen.sortedVisibleColumns(columns).map((e) => e.key), [
      'name',
      'author',
      'version',
      'range',
    ]);
  });

  test('a hidden column is left out even when it is frozen', () {
    final state = _stateWith({
      'author': const WispGridColumnState(
        position: 1,
        width: 100,
        isVisible: false,
        isFrozen: true,
      ),
    });

    expect(state.sortedVisibleColumns(columns).map((e) => e.key), [
      'name',
      'version',
      'range',
    ]);
    expect(state.frozenVisibleColumns(columns), isEmpty);
  });

  test('the frozen block reaches to where the first loose column starts', () {
    expect(_stateWith({}).frozenBlockWidth(columns), 0);

    final state = _stateWith({
      'name': const WispGridColumnState(
        position: 0,
        width: 200,
        isFrozen: true,
      ),
      'author': const WispGridColumnState(
        position: 1,
        width: 150,
        isFrozen: true,
      ),
    });

    // Two spacings of left indent, then each column plus its trailing spacing.
    expect(state.frozenBlockWidth(columns), 16 + 200 + 150 + 16);
  });

  test('settings saved before freezing existed still load', () {
    final oldSaved = WispGridColumnStateMapper.fromMap({
      'position': 3,
      'width': 120.0,
      'isVisible': true,
    });

    expect(oldSaved.isFrozen, isFalse);
    expect(oldSaved.position, 3);
    expect(oldSaved.width, 120.0);
  });
}
