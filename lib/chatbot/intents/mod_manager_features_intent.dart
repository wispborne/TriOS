import '../chatbot_engine.dart';
import '../chatbot_models.dart';
import 'mod_aware_intent.dart';

/// Describes mod manager power-user features: context menu, color tags,
/// grouping, and category assignment.
class ModManagerFeaturesIntent extends ChatIntent {
  static const _phrases = [
    'context menu',
    'right click',
    'right-click',
    'color tag',
    'color tags',
    'mod colors',
    'group by',
    'group mods',
    'mod categories',
    'assign category',
    'bulk actions',
    'bulk edit',
    'mod manager features',
    'mod manager tips',
    'what can i do with mods',
  ];

  static const _primaryKeywords = {
    'context menu': 0.55,
    'right click': 0.5,
    'right-click': 0.5,
    'color': 0.4,
    'tag': 0.35,
    'group': 0.35,
    'bulk': 0.4,
  };

  static const _secondaryKeywords = {
    'mod': 0.1,
    'mods': 0.1,
    'manager': 0.1,
    'organize': 0.1,
    'category': 0.15,
    'categories': 0.15,
    'label': 0.1,
  };

  @override
  String get id => 'mod_manager_features';

  @override
  double match(String input, ConversationContext context) {
    return ModAwareIntent.scoreInput(
      input,
      _phrases,
      _primaryKeywords,
      _secondaryKeywords,
    );
  }

  @override
  ChatResponse respond(String input, ConversationContext context) {
    return const ChatResponse(text: _response);
  }

  static const _response = 'Mod Manager Features\n'
      '\n'
      'Right-click a mod for options:\n'
      '  Change active version, open mod folder, open forum page,\n'
      '  assign categories, set a color tag, force game version,\n'
      '  view in ship/weapon/hullmod viewer, estimate VRAM,\n'
      '  mute updates, redownload & reinstall, and delete.\n'
      '\n'
      'Right-click with multiple mods selected:\n'
      '  Bulk enable/disable, check VRAM, check for updates,\n'
      '  set color tags, force game version, and delete selected.\n'
      '\n'
      'Color tags:\n'
      '  Assign one of 8 color presets to visually organize mods.\n'
      '\n'
      'Group By:\n'
      '  Use the "Group By" dropdown above the mod list to group\n'
      '  mods by various criteria.\n'
      '\n'
      'Categories:\n'
      '  Assign mods to categories via the right-click menu.\n'
      '  Mods can appear in multiple categories at once.';
}
