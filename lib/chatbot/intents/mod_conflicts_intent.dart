import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/mod_manager/mod_manager_logic.dart';

import '../chatbot_engine.dart';
import '../chatbot_models.dart';
import 'mod_aware_intent.dart';

/// Lists enabled mods that have compatibility issues, missing deps, or version mismatches.
class ModConflictsIntent extends ChatIntent with ModAwareIntent {
  @override
  final Ref ref;

  ModConflictsIntent(this.ref);

  static const _phrases = [
    'mod conflicts',
    'conflicting mods',
    'which mods conflict',
    'incompatible mods',
    'broken mods',
    'mods with issues',
    'mods with problems',
  ];

  static const _primaryKeywords = {
    'conflicts': 0.5,
    'conflict': 0.5,
    'broken': 0.45,
    'incompatible': 0.45,
  };

  static const _secondaryKeywords = {
    'mods': 0.15,
    'mod': 0.15,
    'which': 0.1,
    'issues': 0.1,
  };

  @override
  String get id => 'mod_conflicts';

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

    final enabledVariants = enabledModVariants;
    final issues = <String>[];

    for (final variant in enabledVariants) {
      final check = modCompatibility[variant.smolId];
      if (check == null) continue;

      final modIssues = <String>[];

      if (!check.isGameCompatible) {
        modIssues.add(
          'game version incompatible (needs ${variant.modInfo.gameVersion ?? "?"}, '
          'game is ${starsectorVersion ?? "?"})',
        );
      } else if (check.gameCompatibility == GameCompatibility.warning) {
        modIssues.add('game version warning');
      }

      for (final depCheck in check.dependencyChecks) {
        if (depCheck.isCurrentlySatisfied) continue;
        final depName = depCheck.dependency.nameOrId;
        final state = depCheck.satisfiedAmount;
        if (state is Missing) {
          modIssues.add('missing dep: $depName');
        } else if (state is Disabled) {
          modIssues.add('disabled dep: $depName');
        } else if (state is VersionWarning) {
          modIssues.add('version mismatch: $depName');
        } else if (state is VersionInvalid) {
          modIssues.add('incompatible version: $depName');
        }
      }

      if (modIssues.isNotEmpty) {
        final name = variant.modInfo.nameOrId;
        issues.add('  $name\n${modIssues.map((i) => '    - $i').join('\n')}');
      }
    }

    if (issues.isEmpty) {
      return const ChatResponse(
        text: 'No conflicts found among your enabled mods.',
      );
    }

    final buf = StringBuffer(
      'Mods With Issues (${issues.length})\n',
    );
    buf.writeAll(issues, '\n');

    return ChatResponse(text: buf.toString().trimRight());
  }
}
