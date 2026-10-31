import 'package:flutter_test/flutter_test.dart';
import 'package:trios/catalog/ai_use_filter.dart';
import 'package:trios/catalog/models/catalog_extras.dart';

/// A port of Starmodder's `test/site/ai_filter_test.mjs`, case for case. The
/// address tests are ported as tests of the saved form, since TriOS saves the
/// filter to settings instead of a web address.

class _Mod {
  final String id;
  final CatalogAiUse? aiUse;

  _Mod(this.id, [this.aiUse]);
}

CatalogAiUse _used(List<CatalogAiUseEntry> uses) =>
    CatalogAiUse(usesAi: true, uses: uses);

final _mods = [
  _Mod('ai-portraits', _used([
    CatalogAiUseEntry(area: 'portraits', how: 'generated'),
  ])),
  _Mod('optional-portraits', _used([
    CatalogAiUseEntry(area: 'portraits', how: 'edited', optional: true),
  ])),
  _Mod('assisted-code', _used([
    CatalogAiUseEntry(area: 'code', how: 'assisted'),
  ])),
  _Mod('unsaid-how', _used([CatalogAiUseEntry(area: 'music')])),
  _Mod('all-code', _used([
    CatalogAiUseEntry(area: 'code', how: 'generated', extent: 'all'),
  ])),
  _Mod('edited-all-code', _used([
    CatalogAiUseEntry(area: 'code', how: 'edited', extent: 'all'),
  ])),
  _Mod('no-ai', CatalogAiUse(usesAi: false)),
  _Mod('silent'),
];

final _allIds = [for (final mod in _mods) mod.id];

List<String> _kept(AiUseFilterSettings settings) => [
  for (final mod in _mods)
    if (keepsForAi(mod.aiUse, settings)) mod.id,
];

/// Custom with every part checked, unless [parts] says otherwise.
AiUseFilterSettings _withSettings({
  AiUseMode mode = AiUseMode.hide,
  Set<String>? parts,
  AiUseLevel level = AiUseLevel.any,
  bool skipOptional = false,
}) => AiUseFilterSettings(
  preset: AiUsePreset.custom,
  mode: mode,
  parts: parts ?? aiUseAreas.toSet(),
  level: level,
  skipOptional: skipOptional,
);

AiUseFilterSettings _preset(AiUsePreset preset) =>
    withPreset(const AiUseFilterSettings(), preset);

const _off = AiUseFilterSettings();
final _hideAll = _withSettings();
final _hideArt = _withSettings(
  parts: {'portraits', 'illustrations', 'sprites', 'icons'},
);

void main() {
  test('the starting filter keeps every mod', () {
    expect(_kept(_off), _allIds);
    expect(isOn(_off), isFalse);
  });

  test('only mode with no parts checked shows no mods', () {
    final settings = _off.copyWith(mode: AiUseMode.only);
    expect(isOn(settings), isTrue);
    expect(_kept(settings), isEmpty);
  });

  test('hiding all parts keeps mods with no AI or unknown AI use', () {
    expect(_kept(_hideAll), ['no-ai', 'silent']);
  });

  test('hiding AI art keeps mods with AI code or music', () {
    expect(_kept(_hideArt), [
      'assisted-code',
      'unsaid-how',
      'all-code',
      'edited-all-code',
      'no-ai',
      'silent',
    ]);
  });

  test('only shows mods with AI use in the checked parts', () {
    expect(_kept(_withSettings(mode: AiUseMode.only, parts: {'code'})), [
      'assisted-code',
      'all-code',
      'edited-all-code',
    ]);
    expect(_kept(_withSettings(mode: AiUseMode.only)), [
      'ai-portraits',
      'optional-portraits',
      'assisted-code',
      'unsaid-how',
      'all-code',
      'edited-all-code',
    ]);
  });

  test('"Show everything" keeps every mod', () {
    expect(_kept(_preset(AiUsePreset.off)), _allIds);
    expect(isOn(_preset(AiUsePreset.off)), isFalse);
  });

  test('"Absolutely no AI" keeps only mods whose author says no AI was used',
      () {
    expect(_kept(_preset(AiUsePreset.none)), ['no-ai']);
    expect(isOn(_preset(AiUsePreset.none)), isTrue);
  });

  test('"No AI" keeps mods that say no AI was used or say nothing', () {
    expect(_kept(_preset(AiUsePreset.noai)), ['no-ai', 'silent']);
  });

  test('"No AI images" hides AI art and nothing else', () {
    expect(_kept(_preset(AiUsePreset.noimages)), [
      'assisted-code',
      'unsaid-how',
      'all-code',
      'edited-all-code',
      'no-ai',
      'silent',
    ]);
  });

  test('"No vibecoded mods" hides only mods whose code AI wrote all of', () {
    expect(
      _kept(_preset(AiUsePreset.novibecode)),
      _allIds.where((id) => id != 'all-code').toList(),
    );
  });

  test('Custom starts from the preset before it', () {
    final custom = withPreset(_preset(AiUsePreset.noimages), AiUsePreset.custom);
    expect(custom.preset, AiUsePreset.custom);
    expect(_kept(custom), _kept(_preset(AiUsePreset.noimages)));
    // "Absolutely no AI" has no Custom mode, so Custom starts from hiding.
    expect(
      withPreset(_preset(AiUsePreset.none), AiUsePreset.custom).mode,
      AiUseMode.hide,
    );
    // Custom has no control for "all of that part", so it is dropped.
    expect(
      withPreset(_preset(AiUsePreset.novibecode), AiUsePreset.custom).wholeOnly,
      isFalse,
    );
  });

  test('the level decides whether edited and assisted work counts', () {
    List<String> hide(AiUseLevel level) => _kept(_withSettings(level: level));
    expect(hide(AiUseLevel.made), [
      'optional-portraits',
      'assisted-code',
      'edited-all-code',
      'no-ai',
      'silent',
    ]);
    expect(hide(AiUseLevel.edited), ['assisted-code', 'no-ai', 'silent']);
    expect(
      hide(AiUseLevel.made),
      isNot(contains('unsaid-how')),
      reason: 'AI use without a stated how counts at every level',
    );
  });

  test('optional parts can be ignored', () {
    expect(
      _kept(_withSettings(skipOptional: true)),
      contains('optional-portraits'),
    );
    expect(
      _kept(_withSettings(mode: AiUseMode.only, skipOptional: true)),
      isNot(contains('optional-portraits')),
    );
  });

  test('AI use with no named part counts as other', () {
    final vague = CatalogAiUse(usesAi: true);
    expect(keepsForAi(vague, _withSettings(parts: {'other'})), isFalse);
    expect(keepsForAi(vague, _withSettings(parts: {'code'})), isTrue);
  });

  test('the saved form restores the same settings', () {
    final settingsList = [
      _off,
      _hideAll,
      _hideArt,
      _withSettings(
        mode: AiUseMode.only,
        parts: {'music', 'code'},
        level: AiUseLevel.made,
      ),
      _withSettings(
        parts: {},
        skipOptional: true,
        level: AiUseLevel.edited,
      ),
      _withSettings(parts: {}),
      _preset(AiUsePreset.none),
      _preset(AiUsePreset.noai),
      _preset(AiUsePreset.noimages),
      _preset(AiUsePreset.novibecode),
    ];
    for (final settings in settingsList) {
      final saved = settings.toMap();
      expect(AiUseFilterSettings.fromMap(saved), settings, reason: '$saved');
    }
  });

  test('a preset saves only its name', () {
    expect(_preset(AiUsePreset.noimages).toMap(), {'preset': 'noimages'});
  });

  test('the saved form lists checked parts in a fixed order', () {
    final settings = _withSettings(parts: {'code', 'music', 'portraits'});
    expect(settings.toMap()['parts'], 'portraits,music,code');
  });

  test('unknown saved values are ignored', () {
    final settings = AiUseFilterSettings.fromMap({
      'preset': 'custom',
      'mode': 'sometimes',
      'parts': 'portraits,lasers',
      'level': 'loud',
    });
    expect(settings.parts, {'portraits'});
    expect(settings.level, AiUseLevel.any);
    expect(settings.mode, AiUseMode.hide);

    final unknownPreset = AiUseFilterSettings.fromMap({'preset': 'sometimes'});
    expect(unknownPreset, _off);
    expect(isOn(unknownPreset), isFalse);
  });
}
