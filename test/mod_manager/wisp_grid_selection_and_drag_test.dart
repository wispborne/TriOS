import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:trios/mod_manager/homebrew_grid/wisp_grid.dart';
import 'package:trios/mod_manager/homebrew_grid/wisp_grid_state.dart';

class _FakeItem implements WispGridItem {
  @override
  final String key;

  _FakeItem(this.key);
}

WispGridColumn<_FakeItem> _nameColumn() => WispGridColumn<_FakeItem>(
  key: 'name',
  name: 'Name',
  isSortable: false,
  csvValue: (item) => item.key,
  itemCellBuilder: (item, modifiers) => Text(item.key),
  defaultState: const WispGridColumnState(position: 0, width: 100),
);

Widget _wrap(Widget child) => ProviderScope(
  child: MaterialApp(
    home: Scaffold(body: SizedBox(width: 600, child: child)),
  ),
);

void main() {
  final items = [_FakeItem('alpha'), _FakeItem('beta'), _FakeItem('gamma')];

  Future<void> ctrlTap(WidgetTester tester, String label) async {
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.tap(find.text(label));
    await tester.pump();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
  }

  testWidgets(
    'a caller-controlled grid reports checks instead of keeping them',
    (tester) async {
      final reported = <Set<String>>[];

      await tester.pumpWidget(
        _wrap(
          WispGrid<_FakeItem>(
            items: items,
            columns: [_nameColumn()],
            gridState: const WispGridState(
              columnsState: {},
              groupingSetting: null,
            ),
            updateGridState: (_) {},
            checkedItemKeys: const {},
            onCheckedItemsChanged: reported.add,
          ),
        ),
      );

      await ctrlTap(tester, 'beta');
      await ctrlTap(tester, 'gamma');

      // The caller still supplies an empty selection after each click.
      expect(reported, [
        {'beta'},
        {'gamma'},
      ]);
    },
  );

  testWidgets('a grid with no caller-supplied checks keeps its own', (
    tester,
  ) async {
    final reported = <Set<String>>[];

    await tester.pumpWidget(
      _wrap(
        WispGrid<_FakeItem>(
          items: items,
          columns: [_nameColumn()],
          gridState: const WispGridState(
            columnsState: {},
            groupingSetting: null,
          ),
          updateGridState: (_) {},
          onCheckedItemsChanged: reported.add,
        ),
      ),
    );

    await ctrlTap(tester, 'beta');
    await ctrlTap(tester, 'gamma');
    await ctrlTap(tester, 'beta');

    expect(reported, [
      {'beta'},
      {'beta', 'gamma'},
      {'gamma'},
    ]);
  });

  testWidgets('rows are draggable when the grid names a drag type', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        WispGrid<_FakeItem>(
          items: items,
          columns: [_nameColumn()],
          gridState: const WispGridState(
            columnsState: {},
            groupingSetting: null,
          ),
          updateGridState: (_) {},
          rowDragType: 'installedMods',
          rowDragLabel: (keys) => '${keys.length} mods',
        ),
      ),
    );

    expect(find.byType(Draggable<WispGridDragPayload>), findsNWidgets(3));
  });

  testWidgets('rows are not draggable without a drag type', (tester) async {
    await tester.pumpWidget(
      _wrap(
        WispGrid<_FakeItem>(
          items: items,
          columns: [_nameColumn()],
          gridState: const WispGridState(
            columnsState: {},
            groupingSetting: null,
          ),
          updateGridState: (_) {},
        ),
      ),
    );

    expect(find.byType(Draggable<WispGridDragPayload>), findsNothing);
  });

  testWidgets('a grid accepting a drag type takes rows dropped on it', (
    tester,
  ) async {
    WispGridDragPayload? dropped;

    await tester.pumpWidget(
      _wrap(
        WispGrid<_FakeItem>(
          items: items,
          columns: [_nameColumn()],
          gridState: const WispGridState(
            columnsState: {},
            groupingSetting: null,
          ),
          updateGridState: (_) {},
          acceptedRowDragTypes: const {'installedMods'},
          onRowsDropped: (payload) => dropped = payload,
        ),
      ),
    );

    final target = tester
        .widgetList<DragTarget<WispGridDragPayload>>(
          find.byType(DragTarget<WispGridDragPayload>),
        )
        .first;

    const accepted = WispGridDragPayload(
      itemKeys: ['alpha', 'beta'],
      dragDataType: 'installedMods',
    );
    const rejected = WispGridDragPayload(
      itemKeys: ['alpha'],
      dragDataType: 'somethingElse',
    );

    expect(
      target.onWillAcceptWithDetails!(
        DragTargetDetails(data: accepted, offset: Offset.zero),
      ),
      isTrue,
    );
    expect(
      target.onWillAcceptWithDetails!(
        DragTargetDetails(data: rejected, offset: Offset.zero),
      ),
      isFalse,
    );

    target.onAcceptWithDetails!(
      DragTargetDetails(data: accepted, offset: Offset.zero),
    );
    expect(dropped?.itemKeys, ['alpha', 'beta']);
  });

  testWidgets('a row grows to fit content when no item extent is set', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        WispGrid<_FakeItem>(
          items: [_FakeItem('alpha')],
          columns: [_nameColumn()],
          gridState: const WispGridState(
            columnsState: {},
            groupingSetting: null,
          ),
          updateGridState: (_) {},
          rowBuilder: ({required item, required modifiers, required child}) =>
              Column(
                children: [
                  child,
                  const SizedBox(height: 120, child: Text('details')),
                ],
              ),
        ),
      ),
    );

    expect(find.text('details'), findsOneWidget);
    expect(tester.getSize(find.text('details')).height, greaterThan(0));
  });
}
