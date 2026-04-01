import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/mod_manager/mod_manager_logic.dart';

import '../chatbot_engine.dart';
import '../chatbot_models.dart';
import 'mod_aware_intent.dart';

/// Lists mods with compatibility issues (missing deps, game version mismatch).
class ModCompatibilityIntent extends ChatIntent with ModAwareIntent {
  @override
  final Ref ref;

  ModCompatibilityIntent(this.ref);

  static const _phrases = [
    'compatibility issues',
    'broken mods',
    'mod problems',
    'missing dependencies',
    'dependency issues',
    'incompatible mods',
    'what mods are broken',
    'any issues',
    'any problems',
  ];

  static const _primaryKeywords = {
    'compatibility': 0.5,
    'incompatible': 0.5,
    'broken': 0.45,
    'problems': 0.4,
    'issues': 0.4,
    'missing': 0.35,
  };

  static const _secondaryKeywords = {
    'mods': 0.1,
    'mod': 0.1,
    'check': 0.1,
    'show': 0.1,
    'dependencies': 0.15,
  };

  @override
  String get id => 'mod_compatibility';

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
    final guard = guardModData();
    if (guard != null) return guard;

    final compatibility = modCompatibility;
    final enabledMods = mods.where((m) => m.isEnabledInGame).toList();
    final issueEntries = <String>[];

    for (final mod in enabledMods) {
      final variant = mod.findFirstEnabled;
      if (variant == null) continue;

      final check = compatibility[variant.smolId];
      if (check == null) continue;

      final problems = <String>[];

      if (!check.isGameCompatible) {
        problems.add(
          '    - Game version: incompatible '
          '(requires ${variant.modInfo.gameVersion ?? "unknown"}, '
          'game is ${starsectorVersion ?? "unknown"})',
        );
      } else if (check.gameCompatibility == GameCompatibility.warning) {
        problems.add(
          '    - Game version: may be incompatible '
          '(mod targets ${variant.modInfo.gameVersion ?? "unknown"}, '
          'game is ${starsectorVersion ?? "unknown"})',
        );
      }

      for (final depCheck in check.dependencyChecks) {
        if (depCheck.isCurrentlySatisfied) continue;
        final depName = depCheck.dependency.nameOrId;
        final state = depCheck.satisfiedAmount;
        if (state is Missing) {
          problems.add('    - Missing dependency: $depName');
        } else if (state is Disabled) {
          problems.add('    - Disabled dependency: $depName');
        } else if (state is VersionWarning) {
          problems.add('    - Version mismatch: $depName');
        } else if (state is VersionInvalid) {
          problems.add('    - Incompatible version: $depName');
        }
      }

      if (problems.isNotEmpty) {
        final name = variant.modInfo.nameOrId;
        final version =
            variant.modInfo.version != null ? ' v${variant.modInfo.version}' : '';
        issueEntries.add('  $name$version\n${problems.join('\n')}');
      }
    }

    if (issueEntries.isEmpty) {
      return const ChatResponse(
        text: 'All enabled mods appear compatible!',
      );
    }

    final buf = StringBuffer(
      'Compatibility Issues (${issueEntries.length} mod(s) affected)\n',
    );
    buf.writeAll(issueEntries, '\n');

    return ChatResponse(text: buf.toString().trimRight());
  }
}
