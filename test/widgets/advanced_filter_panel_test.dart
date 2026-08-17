import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/trios/settings/settings.dart';
import 'package:trios/widgets/filter_engine/filter_engine.dart';
import 'package:trios/widgets/filter_widget.dart';

/// Settings that live only in memory, so the panel's lock buttons don't touch
/// the real settings file during tests.
class _TestSettings extends AppSettingNotifier {
  @override
  Settings build() => Settings();
}

class _Item {
  final String hullSize;
  final String shieldType;

  _Item(this.hullSize, this.shieldType);
}

final _items = [
  _Item('Frigate', 'Front'),
  _Item('Destroyer', 'Omni'),
  _Item('Cruiser', 'Phase'),
];

ChipFilterGroup<_Item> _hullSizeGroup() => ChipFilterGroup<_Item>(
  id: 'hullSize',
  name: 'Hull Size',
  valueGetter: (item) => item.hullSize,
);

ChipFilterGroup<_Item> _shieldGroup() => ChipFilterGroup<_Item>(
  id: 'shieldType',
  name: 'Shield Type',
  valueGetter: (item) => item.shieldType,
);

Widget _panel({
  required List<FilterGroup<_Item>> groups,
  bool isAdvanced = false,
}) {
  return ProviderScope(
    overrides: [appSettings.overrideWith(_TestSettings.new)],
    child: MaterialApp(
      home: Scaffold(
        body: SizedBox(
          height: 800,
          child: FiltersPanel(
            onHide: () {},
            activeFilterCount: 0,
            showSearch: true,
            isAdvanced: isAdvanced,
            onAdvancedChanged: (_) {},
            filterWidgets: [
              for (final g in groups)
                FilterGroupRenderer<_Item>(
                  group: g,
                  scope: const FilterScope('test'),
                  items: _items,
                  onChanged: () {},
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Types in the panel's search box and waits out the 150ms debounce.
Future<void> _search(WidgetTester tester, String term) async {
  await tester.enterText(find.byType(TextField).first, term);
  await tester.pump(const Duration(milliseconds: 250));
  await tester.pumpAndSettle();
}

Future<void> _tapWithShift(WidgetTester tester, Finder finder) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
  await tester.tap(finder);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() {
    // The settings notifier builds a file manager that needs this path, even
    // though these tests never read or write the file.
    Constants.configDataFolderPath = Directory.systemTemp.createTempSync(
      'trios_filter_test',
    );
  });

  testWidgets('shift-clicking a chip clears the group and includes that one', (
    tester,
  ) async {
    final hullSize = _hullSizeGroup();
    hullSize.setSelections({'Frigate': true, 'Destroyer': false});
    await tester.pumpWidget(_panel(groups: [hullSize]));
    await tester.pumpAndSettle();

    await _tapWithShift(tester, find.widgetWithText(FilterChip, 'Cruiser'));

    expect(hullSize.filterStates, {'Cruiser': true});
  });

  testWidgets('the search box hides chips that do not match', (tester) async {
    await tester.pumpWidget(_panel(groups: [_hullSizeGroup()]));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(FilterChip, 'Frigate'), findsOneWidget);
    expect(find.widgetWithText(FilterChip, 'Cruiser'), findsOneWidget);

    await _search(tester, 'fri');

    expect(find.widgetWithText(FilterChip, 'Frigate'), findsOneWidget);
    expect(find.widgetWithText(FilterChip, 'Cruiser'), findsNothing);
  });

  testWidgets('the search box hides groups with nothing left in them', (
    tester,
  ) async {
    await tester.pumpWidget(
      _panel(groups: [_hullSizeGroup(), _shieldGroup()]),
    );
    await tester.pumpAndSettle();
    expect(find.text('Shield Type'), findsOneWidget);

    await _search(tester, 'fri');

    expect(find.text('Hull Size'), findsOneWidget);
    expect(find.text('Shield Type'), findsNothing);
  });

  testWidgets('a group whose name matches keeps all of its chips', (
    tester,
  ) async {
    await tester.pumpWidget(
      _panel(groups: [_hullSizeGroup(), _shieldGroup()]),
    );
    await tester.pumpAndSettle();

    await _search(tester, 'shield');

    expect(find.text('Hull Size'), findsNothing);
    expect(find.widgetWithText(FilterChip, 'Omni'), findsOneWidget);
    expect(find.widgetWithText(FilterChip, 'Phase'), findsOneWidget);
  });

  testWidgets('include all and exclude all only touch what the search shows', (
    tester,
  ) async {
    final hullSize = _hullSizeGroup();
    await tester.pumpWidget(_panel(groups: [hullSize]));
    await tester.pumpAndSettle();

    await _search(tester, 'fri');
    await tester.tap(find.byIcon(Icons.check_box));
    await tester.pumpAndSettle();

    expect(hullSize.filterStates, {'Frigate': true});

    await tester.tap(find.byIcon(Icons.indeterminate_check_box));
    await tester.pumpAndSettle();

    expect(hullSize.filterStates, {'Frigate': false});
  });

  testWidgets('clear all only clears what the search shows', (tester) async {
    final hullSize = _hullSizeGroup();
    hullSize.setSelections({'Frigate': true, 'Cruiser': true});
    await tester.pumpWidget(_panel(groups: [hullSize]));
    await tester.pumpAndSettle();

    await _search(tester, 'fri');
    await tester.tap(find.byIcon(Icons.check_box_outline_blank));
    await tester.pumpAndSettle();

    expect(hullSize.filterStates, {'Cruiser': true});
  });

  testWidgets('the any/all button only shows in advanced mode', (tester) async {
    await tester.pumpWidget(_panel(groups: [_hullSizeGroup()]));
    await tester.pumpAndSettle();
    expect(find.text('any'), findsNothing);

    await tester.pumpWidget(
      _panel(groups: [_hullSizeGroup()], isAdvanced: true),
    );
    await tester.pumpAndSettle();
    expect(find.text('any'), findsOneWidget);
  });

  testWidgets('a group set to "all" keeps showing why, even in simple mode', (
    tester,
  ) async {
    final hullSize = _hullSizeGroup();
    hullSize.logicMode = ChipLogicMode.all;

    await tester.pumpWidget(_panel(groups: [hullSize]));
    await tester.pumpAndSettle();

    expect(find.text('all'), findsOneWidget);
  });

  testWidgets('the any/all button switches the group between the two modes', (
    tester,
  ) async {
    final hullSize = _hullSizeGroup();
    await tester.pumpWidget(
      _panel(groups: [hullSize], isAdvanced: true),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('any'));
    await tester.pumpAndSettle();

    expect(hullSize.logicMode, ChipLogicMode.all);
    expect(find.text('all'), findsOneWidget);
  });

  testWidgets('number sliders show whether advanced mode is on or off', (
    tester,
  ) async {
    final points = RangeFilterGroup<_Item>(
      id: 'points',
      name: 'Deployment Points',
      valueGetter: (item) => item.hullSize.length,
    )..updateRange(_items);

    await tester.pumpWidget(_panel(groups: [points]));
    await tester.pumpAndSettle();
    expect(find.byType(RangeSlider), findsOneWidget);

    await tester.pumpWidget(_panel(groups: [points], isAdvanced: true));
    await tester.pumpAndSettle();
    expect(find.byType(RangeSlider), findsOneWidget);
  });

  testWidgets('the slider track is one notch per value in the data', (
    tester,
  ) async {
    final points = RangeFilterGroup<_Item>(
      id: 'points',
      name: 'Deployment Points',
      // 7, 9 and 7 again — two distinct values.
      valueGetter: (item) => item.hullSize.length,
    )..updateRange(_items);

    await tester.pumpWidget(_panel(groups: [points]));
    await tester.pumpAndSettle();

    final slider = tester.widget<RangeSlider>(find.byType(RangeSlider));
    expect(points.stops, [7, 9]);
    expect(slider.min, 0);
    expect(slider.max, 1, reason: 'positions, not the values themselves');
    expect(slider.values, const RangeValues(0, 1));
  });

  testWidgets('a slider handle is not left highlighted after dragging it', (
    tester,
  ) async {
    final points = RangeFilterGroup<_Item>(
      id: 'points',
      name: 'Deployment Points',
      valueGetter: (item) => item.hullSize.length,
    )..updateRange(_items);

    await tester.pumpWidget(_panel(groups: [points]));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(RangeSlider), const Offset(-40, 0));
    await tester.pumpAndSettle();

    // The slider focuses the handle you grab, and rings it for as long as it
    // holds the focus. Nothing is focused when the focus sits on a scope.
    expect(FocusManager.instance.primaryFocus, isA<FocusScopeNode>());
  });

  testWidgets('the search box hides sliders whose name does not match', (
    tester,
  ) async {
    final points = RangeFilterGroup<_Item>(
      id: 'points',
      name: 'Deployment Points',
      valueGetter: (item) => item.hullSize.length,
    )..updateRange(_items);

    await tester.pumpWidget(_panel(groups: [points, _hullSizeGroup()]));
    await tester.pumpAndSettle();

    await _search(tester, 'fri');

    expect(find.byType(RangeSlider), findsNothing);
    expect(find.widgetWithText(FilterChip, 'Frigate'), findsOneWidget);
  });
}
