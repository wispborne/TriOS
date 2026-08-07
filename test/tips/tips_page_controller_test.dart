import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trios/models/mod.dart';
import 'package:trios/models/mod_info.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/models/version.dart';
import 'package:trios/tips/tip.dart';
import 'package:trios/tips/tips_notifier.dart';
import 'package:trios/tips/tips_page_controller.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/trios/settings/settings.dart';

import '../riverpod_test_helpers.dart';

/// Stands in for the real tips notifier so nothing reads or writes a mod's
/// `tips.json`. Hidden tips are just a set held in memory.
class _FakeTipsNotifier extends TipsNotifier {
  _FakeTipsNotifier(this.tips, this.hidden);

  List<ModTip> tips;
  Set<ModTip> hidden;

  @override
  Future<List<ModTip>> build() async => tips;

  @override
  List<ModTip> getHidden(List<ModTip> tips) =>
      tips.where(hidden.contains).toList();

  @override
  Future<void> hideTips(
    Iterable<ModTip> tipsToRemove, {
    bool dryRun = false,
    bool reloadTipsAfter = true,
  }) async {
    hidden.addAll(tipsToRemove);
    state = AsyncValue.data([...tips]);
  }

  @override
  Future<void> unhideTips(
    Iterable<ModTip> tipsToUnhide, {
    bool reloadTipsAfter = true,
  }) async {
    hidden.removeAll(tipsToUnhide);
    state = AsyncValue.data([...tips]);
  }

  /// Stands in for a mod being added or removed and the tips being reloaded.
  void reloadWith(List<ModTip> newTips) {
    tips = newTips;
    state = AsyncValue.data(newTips);
  }
}

/// Stands in for the real settings notifier so nothing touches the settings
/// file on disk.
class _FakeSettings extends AppSettingNotifier {
  _FakeSettings(this.initial);

  final Settings initial;

  @override
  Settings build() => initial;
}

typedef TipsTestHarness = ({
  ProviderContainer container,
  TipsPageController controller,
  _FakeTipsNotifier tipsNotifier,
});

ModVariant _variant(String modId, String modName) => ModVariant(
  modInfo: ModInfo(id: modId, name: modName, version: Version.parse('1.0.0')),
  versionCheckerInfo: null,
  modFolder: Directory('mods/$modId'),
  hasNonBrickedModInfo: true,
  gameCoreFolder: Directory('core'),
);

Mod _mod(ModVariant variant, {required bool enabled}) => Mod(
  id: variant.modInfo.id,
  isEnabledInGame: enabled,
  modVariants: [variant],
);

ModTip _tip(String text, ModVariant variant, {String freq = '1'}) => ModTip(
  tipObj: Tip(freq: freq, tip: text),
  variants: [variant],
  tipFile: File('mods/${variant.modInfo.id}/data/strings/tips.json'),
);

/// Builds a container with fixed tips, mods and settings, then waits for the
/// tips to arrive so the controller has them.
Future<TipsTestHarness> _harness({
  required List<ModTip> tips,
  Set<ModTip> hidden = const {},
  List<Mod> mods = const [],
  Settings? settings,
}) async {
  final tipsNotifier = _FakeTipsNotifier(tips, hidden.toSet());
  final container = createTestContainer(
    overrides: [
      AppState.tipsProvider.overrideWith(() => tipsNotifier),
      AppState.mods.overrideWithValue(mods),
      appSettings.overrideWith(() => _FakeSettings(settings ?? Settings())),
    ],
  );

  // Hold the controller open so it keeps up with the tips provider.
  container.listen(tipsPageControllerProvider, (_, _) {}, fireImmediately: true);
  await awaitFirstValue(container, AppState.tipsProvider);

  return (
    container: container,
    controller: container.read(tipsPageControllerProvider.notifier),
    tipsNotifier: tipsNotifier,
  );
}

List<String?> _texts(List<ModTip> tips) =>
    tips.map((tip) => tip.tipObj.tip).toList();

void main() {
  setUpAll(() {
    // The settings manager resolves its file on construction, so point it at a
    // throwaway folder rather than the user's real config.
    Constants.configDataFolderPath = Directory.systemTemp.createTempSync(
      'trios_tips_page_test',
    );
  });

  final enabledVariant = _variant('mod_a', 'First Mod');
  final disabledVariant = _variant('mod_b', 'Second Mod');
  final mods = [
    _mod(enabledVariant, enabled: true),
    _mod(disabledVariant, enabled: false),
  ];

  group('which tips are shown', () {
    test('every tip is shown by default', () async {
      final fromEnabled = _tip('Tip from the enabled mod', enabledVariant);
      final fromDisabled = _tip('Tip from the disabled mod', disabledVariant);
      final harness = await _harness(
        tips: [fromEnabled, fromDisabled],
        mods: mods,
      );

      final state = harness.container.read(tipsPageControllerProvider);
      expect(state.allTips, hasLength(2));
      expect(state.visibleTips, hasLength(2));
    });

    test("'Enabled Mods Only' drops tips from disabled mods", () async {
      final fromEnabled = _tip('Tip from the enabled mod', enabledVariant);
      final fromDisabled = _tip('Tip from the disabled mod', disabledVariant);
      final harness = await _harness(
        tips: [fromEnabled, fromDisabled],
        mods: mods,
      );

      harness.controller.toggleOnlyEnabledMods();

      final state = harness.container.read(tipsPageControllerProvider);
      expect(_texts(state.visibleTips), ['Tip from the enabled mod']);
      expect(
        state.allTips,
        hasLength(2),
        reason: 'filtering must not change the full list',
      );
    });

    test("'Show Hidden' controls whether hidden tips appear", () async {
      final shown = _tip('A tip you can see', enabledVariant);
      final hiddenTip = _tip('A tip you hid', enabledVariant, freq: '0');
      final harness = await _harness(
        tips: [shown, hiddenTip],
        hidden: {hiddenTip},
        mods: mods,
      );

      expect(
        _texts(harness.container.read(tipsPageControllerProvider).visibleTips),
        ['A tip you can see'],
      );

      harness.controller.toggleShowHidden();

      expect(
        harness.container
            .read(tipsPageControllerProvider)
            .visibleTips
            .length,
        2,
      );
    });
  });

  group('search', () {
    test('matches the tip text, ignoring case', () async {
      final matching = _tip('Fly casual near the Hegemony', enabledVariant);
      final other = _tip('Refit before a fight', enabledVariant);
      final harness = await _harness(tips: [matching, other], mods: mods);

      harness.controller.setSearchQuery('HEGEMONY');

      expect(
        _texts(harness.container.read(tipsPageControllerProvider).visibleTips),
        ['Fly casual near the Hegemony'],
      );
    });

    test('matches the name of the mod that added the tip', () async {
      final fromFirst = _tip('One', enabledVariant);
      final fromSecond = _tip('Two', disabledVariant);
      final harness = await _harness(
        tips: [fromFirst, fromSecond],
        mods: mods,
      );

      harness.controller.setSearchQuery('Second Mod');

      expect(
        _texts(harness.container.read(tipsPageControllerProvider).visibleTips),
        ['Two'],
      );
    });

    test('an empty search shows everything again', () async {
      final harness = await _harness(
        tips: [_tip('One', enabledVariant), _tip('Two', enabledVariant)],
        mods: mods,
      );

      harness.controller.setSearchQuery('One');
      expect(
        harness.container.read(tipsPageControllerProvider).visibleTips,
        hasLength(1),
      );

      harness.controller.setSearchQuery('');
      expect(
        harness.container.read(tipsPageControllerProvider).visibleTips,
        hasLength(2),
      );
    });
  });

  test('visible tips are sorted longest first, leaving the loaded list alone',
      () async {
    final short = _tip('Short', enabledVariant);
    final long = _tip('The longest tip of the three', enabledVariant);
    final middle = _tip('Middle length tip', enabledVariant);
    final loaded = [short, long, middle];
    final harness = await _harness(tips: loaded, mods: mods);

    expect(
      _texts(harness.container.read(tipsPageControllerProvider).visibleTips),
      ['The longest tip of the three', 'Middle length tip', 'Short'],
    );
    expect(
      _texts(loaded),
      ['Short', 'The longest tip of the three', 'Middle length tip'],
      reason: 'sorting must not reorder the list the tips provider handed out',
    );
  });

  group('selection', () {
    test('Select All selects every visible tip, then clears them', () async {
      final first = _tip('One', enabledVariant);
      final second = _tip('Two', enabledVariant);
      final harness = await _harness(tips: [first, second], mods: mods);

      final visible = harness.container
          .read(tipsPageControllerProvider)
          .visibleTips;

      harness.controller.toggleSelectAll(visible);
      expect(
        harness.container.read(tipsPageControllerProvider).selectedTips,
        {first, second},
      );

      harness.controller.toggleSelectAll(visible);
      expect(
        harness.container.read(tipsPageControllerProvider).selectedTips,
        isEmpty,
      );
    });

    test('hiding tips clears them from the selection', () async {
      final first = _tip('One', enabledVariant);
      final second = _tip('Two', enabledVariant);
      final harness = await _harness(tips: [first, second], mods: mods);

      harness.controller.setSelected(first, true);
      harness.controller.setSelected(second, true);

      harness.controller.hideTips([first]);
      await pumpEventQueue();

      final state = harness.container.read(tipsPageControllerProvider);
      expect(state.selectedTips, {second});
      expect(state.hiddenTips, [first]);
      expect(
        _texts(state.visibleTips),
        ['Two'],
        reason: 'a hidden tip goes away while Show Hidden is off',
      );
    });

    test('unhiding a tip brings it back', () async {
      final tip = _tip('One', enabledVariant, freq: '0');
      final harness = await _harness(
        tips: [tip],
        hidden: {tip},
        mods: mods,
      );

      harness.controller.unhideTips([tip]);
      await pumpEventQueue();

      final state = harness.container.read(tipsPageControllerProvider);
      expect(state.hiddenTips, isEmpty);
      expect(_texts(state.visibleTips), ['One']);
    });

    test('a tip that disappears on reload leaves the selection', () async {
      final staying = _tip('Staying', enabledVariant);
      final leaving = _tip('Leaving', enabledVariant);
      final harness = await _harness(
        tips: [staying, leaving],
        mods: mods,
      );

      harness.controller.toggleSelectAll([staying, leaving]);
      harness.tipsNotifier.reloadWith([staying]);
      await pumpEventQueue();

      expect(
        harness.container.read(tipsPageControllerProvider).selectedTips,
        {staying},
      );
    });
  });

  test('the toolbar toggles are saved to settings', () async {
    final harness = await _harness(
      tips: [_tip('One', enabledVariant)],
      mods: mods,
    );

    harness.controller.toggleOnlyEnabledMods();
    harness.controller.toggleShowHidden();
    harness.controller.setGrouping(TipsGrouping.mod);

    final saved = harness.container.read(appSettings).tipsPageState;
    expect(saved?.onlyEnabledMods, isTrue);
    expect(saved?.showHidden, isTrue);
    expect(saved?.grouping, TipsGrouping.mod);
  });

  test('saved toggles are used when the page is first built', () async {
    final fromEnabled = _tip('Tip from the enabled mod', enabledVariant);
    final fromDisabled = _tip('Tip from the disabled mod', disabledVariant);
    final harness = await _harness(
      tips: [fromEnabled, fromDisabled],
      mods: mods,
      settings: Settings(
        tipsPageState: const TipsPageStatePersisted(onlyEnabledMods: true),
      ),
    );

    final state = harness.container.read(tipsPageControllerProvider);
    expect(state.onlyEnabledMods, isTrue);
    expect(_texts(state.visibleTips), ['Tip from the enabled mod']);
  });

  test('grouping by mod puts each tip under its own mod', () async {
    final fromFirst = _tip('One', enabledVariant);
    final fromSecond = _tip('Two', disabledVariant);
    final harness = await _harness(
      tips: [fromFirst, fromSecond],
      mods: mods,
    );

    final grouped = harness.controller.groupVisibleTipsByMod();

    expect(grouped.keys.map((mod) => mod.id).toList(), ['mod_a', 'mod_b']);
    expect(grouped[mods.first]!, [fromFirst]);
    expect(grouped[mods.last]!, [fromSecond]);
  });
}
