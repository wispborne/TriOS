import 'dart:io';

import 'package:flutter/material.dart';
import 'package:trios/codex/models/codex_entry.dart';
import 'package:trios/faction_viewer/widgets/faction_card.dart';
import 'package:trios/fighter_viewer/widgets/wing_codex_card.dart';
import 'package:trios/hullmod_viewer/models/hullmod.dart';
import 'package:trios/hullmod_viewer/widgets/hullmod_codex_card.dart';
import 'package:trios/ship_systems_manager/ship_system.dart';
import 'package:trios/ship_systems_manager/widgets/ship_system_codex_card.dart';
import 'package:trios/ship_viewer/widgets/ship_codex_card.dart';
import 'package:trios/weapon_viewer/models/weapon.dart';
import 'package:trios/weapon_viewer/widgets/weapon_codex_card.dart';
import 'package:trios/widgets/moving_tooltip.dart';

/// Wraps [child] in the same codex-card hover tooltip the viewer pages show,
/// picking the card for [entry]'s type. Opens upward ([TooltipPosition.topRight])
/// since these rows sit near the bottom of the page.
Widget codexEntryTooltip({
  required CodexEntry entry,
  required Widget child,
  required Map<String, ShipSystem> shipSystemsMap,
  required Map<String, Weapon> weaponsMap,
  required Map<String, Hullmod> hullmodsMap,
  required Directory? gameCoreDir,
}) {
  switch (entry) {
    case ShipCodexEntry(:final ship):
      return ShipCodexCard.tooltip(
        ship: ship,
        shipSystemsMap: shipSystemsMap,
        weaponsMap: weaponsMap,
        hullmodsMap: hullmodsMap,
        child: child,
      );
    case WeaponCodexEntry(:final weapon):
      return WeaponCodexCard.tooltip(weapon: weapon, child: child);
    case HullmodCodexEntry(:final hullmod):
      return HullmodCodexCard.tooltip(hullmod: hullmod, child: child);
    case ShipSystemCodexEntry(:final system):
      return _framed(
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300),
          child: ShipSystemCodexCard.create(system: system),
        ),
        child,
      );
    case WingCodexEntry(:final wing, :final shipName):
      return _framed(
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300),
          child: WingCodexCard.create(wing: wing, title: shipName ?? wing.id),
        ),
        child,
      );
    case FactionCodexEntry(:final faction):
      return _framed(
        SizedBox(
          width: 280,
          height: 220,
          child: FactionCard(
            faction: faction,
            gameCoreDir: gameCoreDir,
            onTap: () {},
          ),
        ),
        child,
      );
  }
}

Widget _framed(Widget tooltip, Widget child) => MovingTooltipWidget.framed(
  tooltipWidgetBuilder: (_) => tooltip,
  position: TooltipPosition.topRight,
  child: child,
);
