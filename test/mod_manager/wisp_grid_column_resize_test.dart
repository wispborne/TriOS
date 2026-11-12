import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:trios/mod_manager/homebrew_grid/wisp_grid.dart';
import 'package:trios/mod_manager/homebrew_grid/wisp_grid_state.dart';
import 'package:trios/mod_manager/homebrew_grid/wispgrid_column_fit.dart';
import 'package:trios/mod_manager/homebrew_grid/wispgrid_header_row_view.dart';

class _FakeItem implements WispGridItem {
  @override
  final String key;
  final String? text;

  _FakeItem(this.key, this.text);
}

WispGridColumn<_FakeItem> _column(
  String key, {
  required int position,
  double width = 100,
  bool fits = true,
}) => WispGridColumn<_FakeItem>(
  key: key,
  name: key,
  isSortable: false,
  csvValue: null,
  autoFitText: fits ? (item) => item.text : null,
  defaultState: WispGridColumnState(position: position, width: width),
);

WispGridState _stateWith(Map<String, WispGridColumnState> columnsState) =>
    WispGridState(columnsState: columnsState, groupingSetting: null);

double _widthOf(
  WispGridState state,
  List<WispGridColumn> columns,
  String key,
) => state.sortedColumns(columns).firstWhere((e) => e.key == key).value.width;

Future<void> _measure(
  WispGridColumnFit<_FakeItem> fit,
  List<WispGridColumn<_FakeItem>> columns,
  List<_FakeItem> items,
) async {
  fit.measure(
    columns: columns,
    items: items,
    cellStyle: const TextStyle(fontSize: 10),
    headerStyle: const TextStyle(fontSize: 10),
    textScaler: TextScaler.noScaling,
  );
}

void main() {
  final columns = [
    _column('name', position: 0),
    _column('author', position: 1),
    _column('version', position: 2),
  ];

  group('dragging a column edge', () {
    Future<WispGridState Function()> pumpHeader(WidgetTester tester) async {
      var state = _stateWith({});
      late StateSetter rebuild;
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 600,
                height: 30,
                child: StatefulBuilder(
                  builder: (context, setState) {
                    rebuild = setState;
                    return WispGridHeaderRowView(
                      gridState: state,
                      updateGridState: (update) =>
                          rebuild(() => state = update(state)!),
                      columns: columns,
                      groups: const [],
                      contentWidths: const {'author': 42},
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );
      return () => state;
    }

    testWidgets('changes only that column', (tester) async {
      final state = await pumpHeader(tester);
      final handle = find.byKey(wispGridResizeHandleKey('name'));

      await tester.drag(handle, const Offset(40, 0));
      await tester.pump();

      expect(_widthOf(state(), columns, 'name'), 140);
      expect(_widthOf(state(), columns, 'author'), 100);
      expect(_widthOf(state(), columns, 'version'), 100);
    });

    testWidgets('stops at the minimum width', (tester) async {
      final state = await pumpHeader(tester);
      final handle = find.byKey(wispGridResizeHandleKey('name'));

      await tester.drag(handle, const Offset(-300, 0));
      await tester.pump();

      expect(_widthOf(state(), columns, 'name'), WispGrid.minColumnWidth);
      expect(_widthOf(state(), columns, 'author'), 100);
    });

    testWidgets('the last column can grow too', (tester) async {
      final state = await pumpHeader(tester);
      final handle = find.byKey(wispGridResizeHandleKey('version'));

      await tester.drag(handle, const Offset(40, 0));
      await tester.pump();

      expect(_widthOf(state(), columns, 'version'), 140);
    });

    testWidgets('double-clicking an edge fits that column', (tester) async {
      final state = await pumpHeader(tester);
      final handle = find.byKey(wispGridResizeHandleKey('author'));

      await tester.tap(handle);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(handle);
      await tester.pumpAndSettle();

      expect(_widthOf(state(), columns, 'author'), 42);
      expect(_widthOf(state(), columns, 'name'), 100);
    });
  });

  group('automatic widths', () {
    test('a column narrower than its default shrinks to its contents', () {
      final result = withAutoFitWidths(_stateWith({}), columns, {'name': 60});

      expect(_widthOf(result, columns, 'name'), 60);
      expect(_widthOf(result, columns, 'author'), 100);
    });

    test('the default width is the limit', () {
      final result = withAutoFitWidths(_stateWith({}), columns, {'name': 500});

      expect(_widthOf(result, columns, 'name'), 100);
    });

    test('a column the user resized is left alone', () {
      final state = setColumnWidths(_stateWith({}), columns, {'name': 150});

      final result = withAutoFitWidths(state, columns, {'name': 60});

      expect(_widthOf(result, columns, 'name'), 150);
    });

    test('dragging back to the default width still counts as resized', () {
      final state = setColumnWidths(_stateWith({}), columns, {'name': 100});

      final result = withAutoFitWidths(state, columns, {'name': 60});

      expect(_widthOf(result, columns, 'name'), 100);
    });

    test('a width resized before this feature existed is left alone', () {
      final oldSaved = WispGridColumnStateMapper.fromMap({
        'position': 0,
        'width': 150.0,
        'isVisible': true,
      });

      final result = withAutoFitWidths(
        _stateWith({'name': oldSaved}),
        columns,
        {'name': 60},
      );

      expect(oldSaved.isWidthSetByUser, isFalse);
      expect(_widthOf(result, columns, 'name'), 150);
    });

    test('a column saved at its default width is sized automatically', () {
      final result = withAutoFitWidths(
        _stateWith({
          'name': const WispGridColumnState(position: 0, width: 100),
        }),
        columns,
        {'name': 60},
      );

      expect(_widthOf(result, columns, 'name'), 60);
    });

    test('resetting a column makes it automatic again', () {
      final resized = setColumnWidths(_stateWith({}), columns, {
        'name': 150,
        'author': 170,
      });

      final state = resetColumnWidths(resized, columns, ['name']);

      expect(_widthOf(state, columns, 'name'), 100);
      expect(_widthOf(state, columns, 'author'), 170);
      final displayed = withAutoFitWidths(state, columns, {'name': 60});
      expect(_widthOf(displayed, columns, 'name'), 60);
    });
  });

  group('measuring', () {
    TestWidgetsFlutterBinding.ensureInitialized();

    final textColumn = _column('name', position: 0);

    test('a column with no text to fit is not measured', () async {
      final fit = WispGridColumnFit<_FakeItem>();
      final icons = _column('icons', position: 0, fits: false);

      await _measure(fit, [icons], [_FakeItem('a', 'some text')]);

      expect(fit.contentWidths, isEmpty);
    });

    test('a column with no text yet keeps its default', () async {
      final fit = WispGridColumnFit<_FakeItem>();

      await _measure(fit, [textColumn], [_FakeItem('a', null)]);

      expect(fit.contentWidths, isEmpty);
    });

    test('width grows with longer text', () async {
      final fit = WispGridColumnFit<_FakeItem>();

      await _measure(fit, [textColumn], [_FakeItem('a', 'short text here')]);
      final shortWidth = fit.contentWidths['name']!;
      await _measure(
        fit,
        [textColumn],
        [_FakeItem('b', 'much much longer text here')],
      );

      expect(fit.contentWidths['name']!, greaterThan(shortWidth));
    });

    test('width does not shrink when a filter hides the longest row', () async {
      final fit = WispGridColumnFit<_FakeItem>();
      final longItem = _FakeItem('a', 'much much longer text here');
      final shortItem = _FakeItem('b', 'short');

      await _measure(fit, [textColumn], [longItem, shortItem]);
      final fullWidth = fit.contentWidths['name']!;
      await _measure(fit, [textColumn], [shortItem]);

      expect(fit.contentWidths['name'], fullWidth);
    });

    test('an item whose text arrives late is still measured', () async {
      final fit = WispGridColumnFit<_FakeItem>();

      await _measure(fit, [textColumn], [_FakeItem('a', null)]);
      await _measure(
        fit,
        [textColumn],
        [_FakeItem('a', 'data finished loading')],
      );

      expect(fit.contentWidths, contains('name'));
    });

    test('the header name counts toward the width', () async {
      final fit = WispGridColumnFit<_FakeItem>();
      final wideHeader = _column('a very long column heading', position: 0);

      await _measure(fit, [wideHeader], [_FakeItem('a', 'x')]);

      // 26 characters at 10 wide each in the test font, plus padding.
      expect(fit.contentWidths[wideHeader.key], 268);
    });
  });

  testWidgets('reordering columns does not save automatic widths', (
    tester,
  ) async {
    final savedState = _stateWith({});
    // What the grid draws: automatic widths applied on top of the saved state.
    final displayedState = withAutoFitWidths(savedState, columns, {'name': 60});
    late WispGridState result;

    Widget header(String key) => SizedBox(
      width: 100,
      height: 30,
      child: DraggableHeader(
        header: key,
        showDragHandle: false,
        gridState: displayedState,
        updateGridState: (update) => result = update(savedState)!,
        columns: columns,
        child: Text(key),
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Row(children: [header('name'), header('author')]),
          ),
        ),
      ),
    );

    await tester.drag(find.text('author'), const Offset(-100, 0));
    await tester.pumpAndSettle();

    expect(result.columnsState['name']!.width, 100);
  });
}
