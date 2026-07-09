import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/codex/codex_index.dart';
import 'package:trios/codex/codex_page_controller.dart';
import 'package:trios/codex/models/codex_entry.dart';
import 'package:trios/faction_viewer/widgets/faction_card.dart';
import 'package:trios/faction_viewer/widgets/faction_profile_dialog.dart';
import 'package:trios/fighter_viewer/widgets/wing_codex_card.dart';
import 'package:trios/hullmod_viewer/models/hullmod.dart';
import 'package:trios/hullmod_viewer/widgets/hullmod_codex_card.dart';
import 'package:trios/hullmod_viewer/widgets/hullmod_details_dialog.dart';
import 'package:trios/ship_systems_manager/ship_system.dart';
import 'package:trios/ship_systems_manager/widgets/ship_system_codex_card.dart';
import 'package:trios/ship_viewer/widgets/ship_blueprint_view.dart';
import 'package:trios/ship_viewer/widgets/ship_codex_card.dart';
import 'package:trios/ship_viewer/widgets/ship_details_dialog.dart';
import 'package:trios/trios/app_state.dart';
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
            ? () => controller.select((CodexEntryType.ship, wing.hullId!))
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
          onTap: () {},
        ),
      ),
    };

    final openDialog = _dialogOpener(context, ref, entry);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (openDialog != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: Align(
              alignment: Alignment.centerRight,
              child: MovingTooltipWidget.text(
                message: 'Open the full details window for this entry.',
                child: OutlinedButton.icon(
                  onPressed: openDialog,
                  icon: const Icon(Icons.open_in_full, size: 16),
                  label: const Text('Open details'),
                ),
              ),
            ),
          ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: card,
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
        return () => showDialog(
          context: context,
          builder: (_) =>
              FactionProfileDialog(faction: faction, gameCoreDir: gameCoreDir),
        );
      case WingCodexEntry():
      case ShipSystemCodexEntry():
        return null;
    }
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
