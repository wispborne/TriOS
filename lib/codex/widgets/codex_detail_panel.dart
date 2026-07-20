import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:trios/codex/codex_index.dart';
import 'package:trios/codex/codex_page_controller.dart';
import 'package:trios/codex/models/codex_entry.dart';
import 'package:trios/faction_viewer/models/faction.dart';
import 'package:trios/faction_viewer/widgets/faction_card.dart';
import 'package:trios/faction_viewer/widgets/faction_profile_dialog.dart';
import 'package:trios/fighter_viewer/widgets/wing_codex_card.dart';
import 'package:trios/hullmod_viewer/models/hullmod.dart';
import 'package:trios/hullmod_viewer/widgets/hullmod_codex_card.dart';
import 'package:trios/hullmod_viewer/widgets/hullmod_details_dialog.dart';
import 'package:trios/ship_systems_manager/ship_system.dart';
import 'package:trios/ship_systems_manager/widgets/ship_system_codex_card.dart';
import 'package:trios/ship_viewer/models/ship.dart';
import 'package:trios/ship_viewer/widgets/ship_blueprint_view.dart';
import 'package:trios/ship_viewer/widgets/ship_codex_card.dart';
import 'package:trios/ship_viewer/widgets/ship_details_dialog.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/weapon_viewer/models/weapon.dart';
import 'package:trios/weapon_viewer/widgets/weapon_codex_card.dart';
import 'package:trios/weapon_viewer/widgets/weapon_details_dialog.dart';
import 'package:trios/widgets/moving_tooltip.dart';

/// The middle panel: renders the reused per-type card for the selected entry.
class CodexDetailPanel extends ConsumerWidget {
  final (CodexEntryType, String)? selected;

  const CodexDetailPanel({super.key, required this.selected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    if (selected == null) {
      return _placeholder(theme, 'Select an entry to see its details.');
    }

    final visible = ref.watch(codexVisibleIndexProvider);
    final entry = visible.where((e) => e.key == selected).firstOrNull;
    if (entry == null) {
      return _placeholder(theme, 'This entry is not available.');
    }

    final controller = ref.read(codexPageControllerProvider.notifier);

    // A hull's key type depends on whether it's a station (separate category),
    // so resolve it from the index rather than assuming the ship category.
    CodexEntryType hullKeyType(String hullId) => visible
        .whereType<ShipCodexEntry>()
        .where((e) => e.ship.id == hullId)
        .map((e) => e.type)
        .firstOrNull ??
        CodexEntryType.ship;

    final card = switch (entry) {
      // Full interactive blueprint above the stats card, replacing the card's
      // small side sprite — same arrangement as the ship details dialog.
      ShipCodexEntry(:final ship) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (ship.spriteFile != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 140),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ShipBlueprintView(ship: ship),
                  ),
                ),
              ),
            ),
          ShipCodexCard.create(
            ship: ship,
            showSprite: false,
            shipSystemsMap: _mapById<ShipSystem>(
              visible,
              (e) => e is ShipSystemCodexEntry ? e.system : null,
              (s) => s.id,
            ),
            weaponsMap: _mapById<Weapon>(
              visible,
              (e) => e is WeaponCodexEntry ? e.weapon : null,
              (w) => w.id,
            ),
            hullmodsMap: _mapById<Hullmod>(
              visible,
              (e) => e is HullmodCodexEntry ? e.hullmod : null,
              (h) => h.id,
            ),
            onEntitySelected: controller.select,
          ),
        ],
      ),
      WeaponCodexEntry(:final weapon) => WeaponCodexCard.create(weapon: weapon),
      HullmodCodexEntry(:final hullmod) => HullmodCodexCard.create(
        hullmod: hullmod,
      ),
      ShipSystemCodexEntry(:final system) => ShipSystemCodexCard.create(
        system: system,
      ),
      WingCodexEntry(:final wing, :final shipName) => WingCodexCard.create(
        wing: wing,
        title: shipName ?? wing.id,
        onShipTap: wing.hullId != null
            ? () => controller.select((hullKeyType(wing.hullId!), wing.hullId!))
            : null,
      ),
      // FactionCard is built for a fixed-size grid cell (it uses a Spacer), so
      // it needs a bounded height — unlike the shrink-wrapping codex cards it
      // can't live directly in the scroll view.
      FactionCodexEntry(:final faction) => SizedBox(
        height: 220,
        child: FactionCard(
          faction: faction,
          gameCoreDir: ref.watch(AppState.gameCoreFolder).valueOrNull,
          onlyEnabledMods: ref.watch(
            appSettings.select((s) => s.codexEnabledModsOnly),
          ),
          onTap: () {},
        ),
      ),
    };

    final openDialog = _dialogOpener(context, ref, entry);
    final modBadge = _buildModSourceBadge(context, ref, entry);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (openDialog != null || modBadge != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: Row(
              children: [
                ?modBadge,
                const Spacer(),
                if (openDialog != null)
                  MovingTooltipWidget.text(
                    message: 'Open the full details window for this entry.',
                    child: OutlinedButton.icon(
                      onPressed: openDialog,
                      icon: const Icon(Icons.open_in_full, size: 16),
                      label: const Text('Open details'),
                    ),
                  ),
              ],
            ),
          ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                card,
                // "This ship is used by this faction…" — the in-game Codex's
                // ship→factions section. Only ships have it.
                if (entry is ShipCodexEntry)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: _ShipUsedByFactions(
                      ship: entry.ship,
                      onFactionTap: (id) =>
                          controller.select((CodexEntryType.faction, id)),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// The dialog to open for [entry] — the same one its viewer opens on a row
  /// click. Returns null for entry types that have no standalone viewer
  /// (fighters and ship systems live only in the Codex).
  VoidCallback? _dialogOpener(
    BuildContext context,
    WidgetRef ref,
    CodexEntry entry,
  ) {
    switch (entry) {
      case ShipCodexEntry(:final ship):
        return () => showShipDetailsDialog(context, ref, ship);
      case WeaponCodexEntry(:final weapon):
        return () => showWeaponDetailsDialog(context, weapon);
      case HullmodCodexEntry(:final hullmod):
        return () => showHullmodDetailsDialog(context, hullmod);
      case FactionCodexEntry(:final faction):
        final gameCoreDir = ref.read(AppState.gameCoreFolder).valueOrNull;
        final onlyEnabledMods = ref.read(appSettings).codexEnabledModsOnly;
        return () => showDialog(
          context: context,
          builder: (_) => FactionProfileDialog(
            faction: faction,
            gameCoreDir: gameCoreDir,
            onlyEnabledMods: onlyEnabledMods,
          ),
        );
      case WingCodexEntry():
      case ShipSystemCodexEntry():
        return null;
    }
  }

  /// A small "mod source" badge shown in the header when the entry comes from a
  /// mod (like the in-game Codex's mod_info icon). Vanilla entries have no
  /// source mod, so this returns null and no badge is shown. Hovering names the
  /// mod, copying the game's third-party-data flavor tooltip.
  Widget? _buildModSourceBadge(
    BuildContext context,
    WidgetRef ref,
    CodexEntry entry,
  ) {
    if (entry.modIds.isEmpty) return null;

    final mods = ref.watch(AppState.mods);
    final nameById = {
      for (final mod in mods)
        mod.id:
            mod.findFirstEnabledOrHighestVersion?.modInfo.nameOrId ?? mod.id,
    };
    final names = entry.modIds.map((id) => nameById[id] ?? id).toList()..sort();
    if (names.isEmpty) return null;
    final modList = names.join(', ');

    final theme = Theme.of(context);
    final gray = theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7);
    final highlight = theme.colorScheme.secondary;

    return MovingTooltipWidget.framed(
      tooltipWidget: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Text.rich(
          TextSpan(
            style: theme.textTheme.bodySmall?.copyWith(color: gray),
            children: [
              const TextSpan(text: 'Third party data provided by '),
              TextSpan(
                text: modList,
                style: TextStyle(color: highlight, fontWeight: FontWeight.bold),
              ),
              const TextSpan(
                text:
                    '. The Tri-Tachyon corporation is not responsible for the '
                    'accuracy or reliability of information supplied by external '
                    'sources. By accessing this Codex adjunct, you acknowledge '
                    'and agree to relieve Tri-Tachyon of any liability and '
                    'responsibility for any damages resulting from use or '
                    'cognition of third party data.',
              ),
            ],
          ),
        ),
      ),
      child: Icon(
        Symbols.frame_exclamation_rounded,
        size: 18,
        color: theme.colorScheme.primary,
      ),
    );
  }

  Widget _placeholder(ThemeData theme, String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }

  Map<String, V> _mapById<V>(
    List<CodexEntry> pool,
    V? Function(CodexEntry) extract,
    String Function(V) idOf,
  ) {
    final out = <String, V>{};
    for (final e in pool) {
      final v = extract(e);
      if (v != null) out.putIfAbsent(idOf(v), () => v);
    }
    return out;
  }
}

/// The in-game Codex's "This ship is used by this faction…" section: a list of
/// the factions whose fleets can field this ship. Shown below a ship's card.
///
/// A faction counts as using the ship if it appears in the intel tab and knows
/// the hull — either by the hull id (a skin resolves to its base hull) or by a
/// tag the ship carries. This mirrors the game's rule; the game additionally
/// drops hulls a faction has explicitly weighted to zero, but that per-hull
/// weighting isn't parsed here, so those rare cases may still show.
class _ShipUsedByFactions extends ConsumerWidget {
  final Ship ship;
  final void Function(String factionId) onFactionTap;

  const _ShipUsedByFactions({required this.ship, required this.onFactionTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Only factions the Codex is currently showing: this respects the standing
    // filters (the "Only enabled mods" toggle, the mod picker, spoilers), so a
    // disabled mod's faction doesn't appear here.
    final factions = ref
        .watch(codexVisibleIndexProvider)
        .whereType<FactionCodexEntry>()
        .map((e) => e.faction)
        .toList();
    final gameCoreDir = ref.watch(AppState.gameCoreFolder).valueOrNull;

    // The hull the game would check known-ship membership against: a skin
    // resolves to its base hull, otherwise the ship's own id.
    final baseHullId = ship.isSkin ? (ship.baseHullId ?? ship.id) : ship.id;
    final shipTags = ship.tags?.toSet() ?? const <String>{};

    final users =
        factions.where((f) {
          if (!f.showInIntelTab) return false;
          if (f.knownShipIds.contains(baseHullId)) return true;
          if (f.knownShipIds.contains(ship.id)) return true;
          return f.knownShipTags.any(shipTags.contains);
        }).toList()..sort(
          (a, b) => a.displayNameBest.toLowerCase().compareTo(
            b.displayNameBest.toLowerCase(),
          ),
        );

    // No known users: show nothing at all, like the game.
    if (users.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final faction in users)
              _factionChip(context, faction, gameCoreDir),
          ],
        ),
      ],
    );
  }

  Widget _factionChip(
    BuildContext context,
    Faction faction,
    Directory? gameCoreDir,
  ) {
    final theme = Theme.of(context);
    final crestFile = faction.resolveImageFile(faction.crest, gameCoreDir);
    final nameColor =
        _uiColor(faction.baseUIColor) ?? theme.colorScheme.onSurface;

    return MovingTooltipWidget.text(
      message:
          'This ship is used by this faction, and may sometimes be found for '
          'sale at their colonies.',
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: () => onFactionTap(faction.id),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.outline.withAlpha(50)),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 6,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: crestFile != null
                    ? Image.file(
                        crestFile,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) =>
                            const Icon(Icons.flag, size: 14),
                      )
                    : const Icon(Icons.flag, size: 14),
              ),
              Text(
                faction.displayName,
                style: theme.textTheme.labelMedium?.copyWith(color: nameColor),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// A faction's `baseUIColor` ([r, g, b] or [r, g, b, a]) as a [Color].
  Color? _uiColor(List<int>? rgba) {
    if (rgba == null || rgba.length < 3) return null;
    return Color.fromARGB(
      rgba.length >= 4 ? rgba[3] : 255,
      rgba[0],
      rgba[1],
      rgba[2],
    );
  }
}
