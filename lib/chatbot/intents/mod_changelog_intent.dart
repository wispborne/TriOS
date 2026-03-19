import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/utils/search.dart' as mod_search;

import '../chatbot_engine.dart';
import '../chatbot_models.dart';
import 'mod_aware_intent.dart';

/// Shows the changelog for a specific mod, or lists mods with changelogs.
class ModChangelogIntent extends ChatIntent with ModAwareIntent {
  @override
  final Ref ref;

  ModChangelogIntent(this.ref);

  static const _phrases = [
    'mod changelog',
    'changelog for',
    'show changelog',
    'what changed in',
    'recent changes for mod',
    'mod release notes',
    'release notes',
    "what's new in",
  ];

  static const _primaryKeywords = {
    'changelog': 0.55,
    'changelogs': 0.55,
    'release notes': 0.5,
  };

  static const _secondaryKeywords = {
    'mod': 0.1,
    'changes': 0.1,
    'recent': 0.1,
    'show': 0.1,
    'what': 0.1,
    'new': 0.1,
  };

  @override
  String get id => 'mod_changelog';

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

    final changelogs =
        ref.read(AppState.changelogsProvider).valueOrNull;

    if (changelogs == null || changelogs.isEmpty) {
      return const ChatResponse(
        text: 'No changelogs loaded yet. Changelogs are fetched when '
            'mod updates are checked.',
      );
    }

    // Try to extract a mod name from the input.
    final query = _extractModName(input);
    if (query.isEmpty) {
      // List mods with changelogs.
      final modNames = <String>[];
      for (final entry in changelogs.entries) {
        final mod =
            mods.where((m) => m.id == entry.value.modId).firstOrNull;
        final name =
            mod?.findFirstEnabledOrHighestVersion?.modInfo.nameOrId ??
                entry.value.modId;
        modNames.add(name);
      }
      modNames.sort();
      final buf = StringBuffer(
        '${changelogs.length} mods have changelogs:\n',
      );
      for (final name in modNames.take(20)) {
        buf.writeln('  $name');
      }
      if (modNames.length > 20) {
        buf.writeln('  ...and ${modNames.length - 20} more');
      }
      buf.writeln(
        '\nAsk "changelog for <mod name>" to see a specific one.',
      );
      return ChatResponse(text: buf.toString().trimRight());
    }

    // Search for the mod.
    final results = mod_search.searchMods(mods, query);
    if (results == null || results.isEmpty) {
      return ChatResponse(
        text: 'No mod found matching "$query".',
      );
    }

    // Find a changelog for the first matching mod.
    for (final mod in results) {
      final changelog = changelogs[mod.id];
      if (changelog != null) {
        final name = mod.findFirstEnabledOrHighestVersion?.modInfo
                .nameOrId ??
            mod.id;
        var text = changelog.changelog;
        if (text.length > 500) {
          text = '${text.substring(0, 500)}...\n(truncated)';
        }
        return ChatResponse(
          text: 'Changelog for $name:\n$text',
        );
      }
    }

    return ChatResponse(
      text:
          'No changelog available for "${results.first.id}".',
    );
  }

  String _extractModName(String input) {
    var cleaned = input;
    const triggers = [
      'changelog for',
      'show changelog',
      'mod changelog',
      'release notes for',
      'release notes',
      "what's new in",
      'what changed in',
      'recent changes for mod',
      'recent changes for',
      'changelog',
    ];
    for (final trigger in triggers) {
      final pattern = RegExp(r'\b' + RegExp.escape(trigger) + r'\b');
      cleaned = cleaned.replaceAll(pattern, ' ');
    }
    const filler = ['mod', 'the', 'a', 'an', 'for', 'of', 'show'];
    for (final word in filler) {
      final pattern = RegExp(r'\b' + RegExp.escape(word) + r'\b');
      cleaned = cleaned.replaceAll(pattern, ' ');
    }
    return cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}
