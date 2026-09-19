import 'package:material_ui/material_ui.dart';
import 'package:trios/codex/models/codex_entry.dart';
import 'package:trios/trios/navigation.dart';
import 'package:trios/widgets/svg_image_icon.dart';

/// User-facing category names (approved copy).
String codexCategoryLabel(CodexEntryType type) => switch (type) {
  CodexEntryType.ship => 'Ships',
  CodexEntryType.station => 'Stations',
  CodexEntryType.weapon => 'Weapons',
  CodexEntryType.hullmod => 'Hullmods',
  CodexEntryType.shipSystem => 'Ship Systems',
  CodexEntryType.wing => 'Fighters',
  CodexEntryType.faction => 'Factions',
};

/// Category order shown at the root, mirroring the proposal.
const List<CodexEntryType> codexCategoryOrder = [
  CodexEntryType.ship,
  CodexEntryType.station,
  CodexEntryType.weapon,
  CodexEntryType.hullmod,
  CodexEntryType.shipSystem,
  CodexEntryType.wing,
  CodexEntryType.faction,
];

/// The sidebar tool a category maps to, or null when it has no viewer tab
/// (ship systems and fighters). Used to reuse the sidebar's own icons.
TriOSTools? codexCategoryTool(CodexEntryType type) => switch (type) {
  CodexEntryType.ship => TriOSTools.ships,
  CodexEntryType.weapon => TriOSTools.weapons,
  CodexEntryType.hullmod => TriOSTools.hullmods,
  CodexEntryType.faction => TriOSTools.factions,
  CodexEntryType.station => null,
  CodexEntryType.shipSystem => null,
  CodexEntryType.wing => null,
};

/// The category icon. Reuses the sidebar tool's icon where one exists so the
/// Codex menus match the sidebar. Fighters use their own formation icon; ship
/// systems and stations (no sidebar tab) fall back to a plain icon.
Widget codexCategoryIcon(CodexEntryType type, {double size = 24, Color? color}) {
  final tool = codexCategoryTool(type);
  if (tool != null) return tool.icon(size: size, color: color);
  if (type == CodexEntryType.wing) {
    return SvgImageIcon(
      "assets/images/icon-fighter-wing.svg",
      height: size,
      width: size,
      color: color,
    );
  }
  return Icon(
    switch (type) {
      CodexEntryType.station => Icons.hub,
      CodexEntryType.shipSystem => Icons.bolt,
      CodexEntryType.wing => Icons.keyboard_double_arrow_up,
      _ => Icons.help_outline,
    },
    size: size,
    color: color,
  );
}
