import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/mod_manager/mod_manager_logic.dart';

import '../../models/mod.dart';
import '../../models/mod_variant.dart';
import '../../utils/search.dart' as mod_search;
import '../chatbot_engine.dart';
import '../chatbot_models.dart';
import 'mod_aware_intent.dart';

/// Searches for a specific mod by name, ID, acronym, or author and shows its details.
///
/// Uses the same fuzzy search engine as the mod manager grid (text_search package)
/// with tag-based matching, acronym generation, author aliases, and negative queries.
class ModSearchIntent extends ChatIntent with ModAwareIntent {
  @override
  final Ref ref;

  ModSearchIntent(this.ref);

  // Phrases that trigger an exact match (0.85 score).
  // Keep these mod-specific to avoid stealing from other intents.
  static const _phrases = [
    'find mod',
    'search mod',
    'search for mod',
    'look up mod',
    'do i have mod',
    'do i have the mod',
    'have i installed',
    'is mod installed',
    'tell me about mod',
    'tell me about the mod',
    'mod info for',
    'info about mod',
    'describe mod',
    'show mod',
    'what mod is',
    'which mod is',
    'what is mod',
  ];

  static const _primaryKeywords = {
    'find': 0.4,
    'search': 0.4,
    'look up': 0.4,
    'lookup': 0.4,
    'details': 0.4,
    'describe': 0.4,
    'which': 0.3,
    'have': 0.3,
    'got': 0.3,
  };

  static const _secondaryKeywords = {
    'mod': 0.15,
    'installed': 0.15,
    'called': 0.1,
    'named': 0.1,
    'about': 0.1,
    'info': 0.15,
    'show': 0.1,
    'describe': 0.1,
  };

  @override
  String get id => 'mod_search';

  @override
  double match(String input, ConversationContext context) {
    // Follow-up bonus: if the last matched intent was mod_search,
    // the user might just be typing another mod name.
    final contextBonus =
        context.lastMatchedIntentId == 'mod_search' ? 0.2 : 0.0;

    return ModAwareIntent.scoreInput(
      input,
      _phrases,
      _primaryKeywords,
      _secondaryKeywords,
      contextBonus: contextBonus,
    );
  }

  @override
  ChatResponse respond(String input, ConversationContext context) {
    final guard = guardModData();
    if (guard != null) return guard;

    var query = _extractSearchTerm(input);

    // If the query is empty but we had a previous search, treat raw input as
    // a follow-up query (e.g. user just types a mod name).
    if (query.isEmpty && context.lastMatchedIntentId == 'mod_search') {
      query = input.trim();
    }

    if (query.isEmpty) {
      return const ChatResponse(
        text:
            'What mod are you looking for? Try "find <name>", "do i have <name>", or just type a mod name.',
      );
    }

    // Use the same search engine as the mod manager grid.
    final results = mod_search.searchMods(mods, query);

    if (results == null || results.isEmpty) {
      return ChatResponse(
        text: 'No mod found matching "$query". Check your spelling, '
            'try a shorter name, or use an acronym.',
      );
    }

    if (results.length == 1) {
      return ChatResponse(
        text: _formatModDetails(results.first),
        memoryUpdates: {'last_searched_mod': results.first.id},
      );
    }

    // Multiple matches
    final buf =
        StringBuffer('Found ${results.length} mods matching "$query":\n');
    for (final mod in results.take(15)) {
      final variant = mod.findFirstEnabledOrHighestVersion;
      final info = variant?.modInfo;
      final name = info?.nameOrId ?? mod.id;
      final version =
          info?.version != null ? ' v${info!.version}' : '';
      final author =
          info?.author != null && info!.author!.isNotEmpty
              ? ' by ${info.author}'
              : '';
      final tags = <String>[
        if (mod.isEnabledInGame) 'ON' else 'OFF',
        if (info?.isUtility == true) 'Utility',
        if (info?.isTotalConversion == true) 'TC',
      ];
      buf.writeln('  [${tags.join('|')}] $name$version$author');
    }
    if (results.length > 15) {
      buf.writeln('  ...and ${results.length - 15} more');
    }
    buf.writeln(
      '\nAsk about a specific mod for full details.',
    );

    return ChatResponse(
      text: buf.toString().trimRight(),
      memoryUpdates: {'last_searched_mod': results.first.id},
    );
  }

  /// Strips trigger phrases and filler words from [input] to isolate the
  /// actual search term, using word-boundary-aware matching to avoid
  /// mangling mod names (e.g. "mod" inside "modular").
  String _extractSearchTerm(String input) {
    var cleaned = input;

    // Strip longest trigger phrases first to avoid partial matches.
    const triggerPhrases = [
      'do i have the mod',
      'do i have mod',
      'have i installed',
      'is mod installed',
      'tell me about the mod',
      'tell me about mod',
      'search for mod',
      'info about mod',
      'what mod is',
      'which mod is',
      'what is mod',
      'what is the',
      'what is',
      'mod info for',
      'mod info',
      'find mod',
      'search mod',
      'look up mod',
      'describe mod',
      'show mod',
      'find',
      'search',
      'lookup',
      'look up',
      'describe',
      'show',
    ];

    for (final phrase in triggerPhrases) {
      // Use word boundary to avoid stripping "mod" from "modular" etc.
      final pattern = RegExp(r'\b' + RegExp.escape(phrase) + r'\b');
      cleaned = cleaned.replaceAll(pattern, ' ');
    }

    // Strip remaining filler words only if they're standalone.
    const fillerWords = [
      'mod',
      'called',
      'named',
      'about',
      'info',
      'the',
      'a',
      'an',
      'for',
      'is',
      'it',
      'me',
      'my',
      'installed',
    ];

    for (final word in fillerWords) {
      final pattern = RegExp(r'\b' + RegExp.escape(word) + r'\b');
      cleaned = cleaned.replaceAll(pattern, ' ');
    }

    // Collapse whitespace.
    return cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  String _formatModDetails(Mod mod) {
    final variant = mod.findFirstEnabledOrHighestVersion;
    final info = variant?.modInfo;
    final buf = StringBuffer('Found: ${info?.nameOrId ?? mod.id}\n');

    if (info?.version != null) buf.writeln('  Version: ${info!.version}');
    if (info?.author != null && info!.author!.isNotEmpty) {
      buf.writeln('  Author: ${info.author}');
    }
    buf.writeln(
      '  Status: ${mod.isEnabledInGame ? "Enabled" : "Disabled"}',
    );

    // Mod type.
    final types = <String>[
      if (info?.isUtility == true) 'Utility',
      if (info?.isTotalConversion == true) 'Total Conversion',
    ];
    if (types.isNotEmpty) {
      buf.writeln('  Type: ${types.join(', ')}');
    }

    if (info?.gameVersion != null) {
      buf.writeln('  Game version: ${info!.gameVersion}');
    }
    if (info?.description != null && info!.description!.isNotEmpty) {
      buf.writeln('  Description: ${info.description}');
    }

    // Dependencies.
    if (info != null && info.dependencies.isNotEmpty) {
      buf.writeln('  Dependencies:');
      for (final dep in info.dependencies) {
        final depName = dep.nameOrId;
        final depVersion =
            dep.version != null ? ' v${dep.version}' : '';
        // Check if the dependency is installed and enabled.
        final depMod = mods.where((m) => m.id == dep.id).firstOrNull;
        final depStatus = depMod == null
            ? ' [NOT INSTALLED]'
            : depMod.isEnabledInGame
                ? ''
                : ' [DISABLED]';
        buf.writeln('    - $depName$depVersion$depStatus');
      }
    }

    // Update availability.
    if (variant != null) {
      _appendUpdateInfo(buf, variant);
    }

    // Compatibility issues.
    if (variant != null) {
      _appendCompatibilityInfo(buf, variant);
    }

    if (mod.modVariants.length > 1) {
      buf.writeln('  Installed variants: ${mod.modVariants.length}');
    }

    return buf.toString().trimRight();
  }

  void _appendUpdateInfo(StringBuffer buf, ModVariant variant) {
    final versionChecks = versionCheckResults;
    if (versionChecks == null) return;

    final result =
        versionChecks.versionCheckResultsBySmolId[variant.smolId];
    if (result == null) return;

    final comparison = result.compareToLocal(variant);
    if (comparison != null && comparison.hasUpdate) {
      final remoteVersion = result.remoteVersion?.modVersion;
      buf.writeln(
        '  Update available: ${remoteVersion ?? "newer version"} '
        '(you have ${variant.modInfo.version ?? "unknown"})',
      );
    }
  }

  void _appendCompatibilityInfo(StringBuffer buf, ModVariant variant) {
    final check = modCompatibility[variant.smolId];
    if (check == null) return;

    final issues = <String>[];

    if (!check.isGameCompatible) {
      issues.add(
        'Game version incompatible '
        '(requires ${variant.modInfo.gameVersion ?? "unknown"}, '
        'game is ${starsectorVersion ?? "unknown"})',
      );
    } else if (check.gameCompatibility == GameCompatibility.warning) {
      issues.add(
        'Game version may be incompatible '
        '(mod targets ${variant.modInfo.gameVersion ?? "unknown"}, '
        'game is ${starsectorVersion ?? "unknown"})',
      );
    }

    for (final depCheck in check.dependencyChecks) {
      if (depCheck.isCurrentlySatisfied) continue;
      final depName = depCheck.dependency.nameOrId;
      final state = depCheck.satisfiedAmount;
      if (state is Missing) {
        issues.add('Missing dependency: $depName');
      } else if (state is Disabled) {
        issues.add('Disabled dependency: $depName');
      } else if (state is VersionWarning) {
        issues.add('Version mismatch: $depName');
      } else if (state is VersionInvalid) {
        issues.add('Incompatible version: $depName');
      }
    }

    if (issues.isNotEmpty) {
      buf.writeln('  Issues:');
      for (final issue in issues) {
        buf.writeln('    - $issue');
      }
    }
  }
}
