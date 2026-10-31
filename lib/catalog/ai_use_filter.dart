import 'package:trios/catalog/models/catalog_extras.dart';

/// The Catalog's AI use filter. A port of Starmodder's `site/ai_filter.js`,
/// kept rule for rule so both sites hide the same mods.
///
/// Uses only the author's statement ([CatalogAiUse]). Nothing is guessed.
/// - "Don't show AI-gen…" never hides a mod whose author says nothing about
///   AI.
/// - "Absolutely no AI" keeps only mods whose author says no AI was used.
///
/// No Flutter imports, so the rules can be tested on their own.

/// One part of a mod that AI can be used for, e.g. portraits.
class AiUseArea {
  /// The name the data uses.
  final String key;
  final String label;

  const AiUseArea(this.key, this.label);
}

/// A heading in the parts list, e.g. Art, with the parts under it.
class AiUseGroup {
  final String label;
  final List<AiUseArea> areas;

  const AiUseGroup(this.label, this.areas);
}

/// The parts, grouped, in display order.
const List<AiUseGroup> aiUseGroups = [
  AiUseGroup('Art', [
    AiUseArea('portraits', 'Portraits'),
    AiUseArea('illustrations', 'Illustrations'),
    AiUseArea('sprites', 'Sprites'),
    AiUseArea('icons', 'Icons'),
  ]),
  AiUseGroup('Sound', [
    AiUseArea('music', 'Music'),
    AiUseArea('voice', 'Voice'),
  ]),
  AiUseGroup('Text', [
    AiUseArea('writing', 'Writing'),
    AiUseArea('translation', 'Translation'),
  ]),
  AiUseGroup('Code', [AiUseArea('code', 'Code')]),
  AiUseGroup('Other', [AiUseArea('other', 'Other')]),
];

/// Every part's key, in display order.
final List<String> aiUseAreas = [
  for (final group in aiUseGroups)
    for (final area in group.areas) area.key,
];

/// The art parts' keys.
final List<String> _artAreas = [
  for (final area in aiUseGroups.first.areas) area.key,
];

/// What the filter does with the checked parts.
enum AiUseMode {
  /// Hide mods with AI use in a checked part. Nothing checked hides nothing.
  hide("Don't show AI-gen…"),

  /// Show only mods with AI use in a checked part. Nothing checked hides
  /// every mod.
  only('Only show AI-gen…'),

  /// Keep only mods whose author says no AI was used. Only the "Absolutely no
  /// AI" preset uses it. Parts, level and the optional switch don't apply.
  none('');

  final String label;

  const AiUseMode(this.label);
}

/// How much AI work counts. Each level includes the ones before it. A stated
/// use with no "how" counts at every level.
enum AiUseLevel {
  made('all of the work', {'generated'}),
  edited('some, but edited by a human', {'generated', 'edited'}),
  any('anything at all', {'generated', 'edited', 'assisted'});

  final String label;
  final Set<String> hows;

  const AiUseLevel(this.label, this.hows);
}

/// The presets, in display order. Only Custom shows the other settings.
enum AiUsePreset {
  off('Show everything'),
  noai(
    'No AI',
    tooltip:
        'Hide if author says AI was used. Also show mods without an '
        'AI disclosure.',
  ),
  none(
    'Absolutely no AI',
    tooltip: 'Only show mods whose author says no AI was used.',
  ),
  noimages('No AI images'),
  novibecode(
    'No vibecoded mods',
    tooltip: 'Hide mods whose code was written entirely by AI.',
  ),
  custom('Custom');

  final String label;
  final String? tooltip;

  const AiUsePreset(this.label, {this.tooltip});
}

/// Everything the AI use filter is set to.
class AiUseFilterSettings {
  final AiUsePreset preset;
  final AiUseMode mode;

  /// Keys from [aiUseAreas].
  final Set<String> parts;
  final AiUseLevel level;

  /// Don't count AI use in a part the player can leave out.
  final bool skipOptional;

  /// Count a use only when AI did all of that part. Only the "No vibecoded
  /// mods" preset sets it. Custom has no control for it.
  final bool wholeOnly;

  /// The starting settings: "Show everything", which hides nothing.
  const AiUseFilterSettings({
    this.preset = AiUsePreset.off,
    this.mode = AiUseMode.hide,
    this.parts = const {},
    this.level = AiUseLevel.any,
    this.skipOptional = false,
    this.wholeOnly = false,
  });

  AiUseFilterSettings copyWith({
    AiUsePreset? preset,
    AiUseMode? mode,
    Set<String>? parts,
    AiUseLevel? level,
    bool? skipOptional,
    bool? wholeOnly,
  }) => AiUseFilterSettings(
    preset: preset ?? this.preset,
    mode: mode ?? this.mode,
    parts: parts ?? this.parts,
    level: level ?? this.level,
    skipOptional: skipOptional ?? this.skipOptional,
    wholeOnly: wholeOnly ?? this.wholeOnly,
  );

  /// The saved form. A preset other than Custom saves only its name, since
  /// the preset sets everything else.
  Map<String, Object?> toMap() => preset != AiUsePreset.custom
      ? {'preset': preset.name}
      : {
          'preset': preset.name,
          'mode': mode.name,
          // A fixed order, so the same settings save the same way.
          'parts': aiUseAreas.where(parts.contains).join(','),
          'level': level.name,
          'skipOptional': skipOptional,
        };

  /// Reads [toMap]'s output. Unknown or missing values use their defaults.
  static AiUseFilterSettings fromMap(Map<String, Object?> map) {
    final preset = AiUsePreset.values.asNameMap()[map['preset']];
    if (preset == null) return const AiUseFilterSettings();
    if (preset != AiUsePreset.custom) {
      return withPreset(const AiUseFilterSettings(), preset);
    }
    final mode = AiUseMode.values.asNameMap()[map['mode']];
    final saved = '${map['parts'] ?? ''}'.split(',');
    return AiUseFilterSettings(
      preset: AiUsePreset.custom,
      mode: mode == AiUseMode.only ? AiUseMode.only : AiUseMode.hide,
      parts: aiUseAreas.where(saved.contains).toSet(),
      level: AiUseLevel.values.asNameMap()[map['level']] ?? AiUseLevel.any,
      skipOptional: map['skipOptional'] == true,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AiUseFilterSettings &&
      other.preset == preset &&
      other.mode == mode &&
      other.parts.length == parts.length &&
      other.parts.containsAll(parts) &&
      other.level == level &&
      other.skipOptional == skipOptional &&
      other.wholeOnly == wholeOnly;

  @override
  int get hashCode => Object.hash(
    preset,
    mode,
    Object.hashAllUnordered(parts),
    level,
    skipOptional,
    wholeOnly,
  );

  @override
  String toString() =>
      'AiUseFilterSettings($preset, $mode, $parts, $level, '
      'skipOptional: $skipOptional, wholeOnly: $wholeOnly)';
}

/// The settings after picking [preset]. Custom starts from the current
/// settings, so a preset can be picked first and then changed.
AiUseFilterSettings withPreset(
  AiUseFilterSettings current,
  AiUsePreset preset,
) {
  const off = AiUseFilterSettings();
  return switch (preset) {
    AiUsePreset.custom => current.copyWith(
      preset: AiUsePreset.custom,
      mode: current.mode == AiUseMode.none ? AiUseMode.hide : current.mode,
      parts: {...current.parts},
      // Custom has no control for this, so it would hide mods without
      // saying why.
      wholeOnly: false,
    ),
    AiUsePreset.off => off,
    AiUsePreset.noai => off.copyWith(preset: preset, parts: aiUseAreas.toSet()),
    AiUsePreset.none => off.copyWith(preset: preset, mode: AiUseMode.none),
    AiUsePreset.noimages => off.copyWith(
      preset: preset,
      parts: _artAreas.toSet(),
    ),
    // Code that AI wrote all of, with no human edits stated.
    AiUsePreset.novibecode => off.copyWith(
      preset: preset,
      parts: {'code'},
      level: AiUseLevel.made,
      wholeOnly: true,
    ),
  };
}

/// Whether the settings can hide mods. "Only show AI-gen…" with nothing
/// checked hides every mod.
bool isOn(AiUseFilterSettings settings) =>
    settings.mode != AiUseMode.hide || settings.parts.isNotEmpty;

/// Whether a use matches the level and optional settings, whatever its part.
bool _useCounts(CatalogAiUseEntry use, AiUseFilterSettings settings) {
  if (settings.skipOptional && use.optional == true) return false;
  if (settings.wholeOnly && use.extent != 'all') return false;
  final how = use.how;
  if (how == null || how.isEmpty) return true;
  return settings.level.hows.contains(how);
}

/// Stands in for stated AI use that names no part.
final _vagueUse = CatalogAiUseEntry(area: 'other');

/// Whether the mod has AI use in a checked part that matches the level and
/// optional settings. False when the author states no AI use or says nothing.
bool _aiMatches(CatalogAiUse? aiUse, AiUseFilterSettings settings) {
  if (aiUse?.usesAi != true) return false;
  final stated = aiUse!.uses;
  final uses = stated != null && stated.isNotEmpty ? stated : [_vagueUse];
  return uses.any(
    (use) => settings.parts.contains(use.area) && _useCounts(use, settings),
  );
}

/// Whether a mod with [aiUse] stays on the list.
bool keepsForAi(CatalogAiUse? aiUse, AiUseFilterSettings settings) =>
    switch (settings.mode) {
      AiUseMode.none => aiUse?.usesAi == false,
      AiUseMode.only => _aiMatches(aiUse, settings),
      AiUseMode.hide => !_aiMatches(aiUse, settings),
    };
