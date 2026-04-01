import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../chatbot_engine.dart';
import '../chatbot_models.dart';
import 'mod_aware_intent.dart';

/// Lists mods by a specific author, or lists all authors with mod counts.
class ModsByAuthorIntent extends ChatIntent with ModAwareIntent {
  @override
  final Ref ref;

  ModsByAuthorIntent(this.ref);

  static const _phrases = [
    'mods by',
    'mod authors',
    'list authors',
    'who made',
    'which author',
  ];

  static const _primaryKeywords = {
    'author': 0.5,
    'authors': 0.5,
    'made': 0.35,
    'created': 0.35,
  };

  static const _secondaryKeywords = {
    'mods': 0.15,
    'mod': 0.15,
    'by': 0.15,
    'who': 0.1,
    'which': 0.1,
    'list': 0.1,
  };

  @override
  String get id => 'mods_by_author';

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

    final authorQuery = _extractAuthorName(input);

    // Group mods by author
    final byAuthor = <String, List<String>>{};
    for (final mod in mods) {
      final variant = mod.findFirstEnabledOrHighestVersion;
      final author = variant?.modInfo.author;
      if (author == null || author.isEmpty) continue;
      final name = variant?.modInfo.nameOrId ?? mod.id;
      final version =
          variant?.modInfo.version != null ? ' v${variant!.modInfo.version}' : '';
      final status = mod.isEnabledInGame ? '[ON]' : '[OFF]';
      byAuthor.putIfAbsent(author, () => []).add('$status $name$version');
    }

    if (authorQuery.isNotEmpty) {
      // Search for specific author
      final lowerQuery = authorQuery.toLowerCase();
      final matchingAuthors = byAuthor.entries
          .where((e) => e.key.toLowerCase().contains(lowerQuery))
          .toList();

      if (matchingAuthors.isEmpty) {
        return ChatResponse(
          text: 'No mods found by author "$authorQuery".',
        );
      }

      final buf = StringBuffer();
      for (final entry in matchingAuthors) {
        buf.writeln('Mods by ${entry.key} (${entry.value.length})');
        for (final mod in entry.value) {
          buf.writeln('  $mod');
        }
      }
      return ChatResponse(text: buf.toString().trimRight());
    }

    // List all authors sorted by mod count
    final sorted = byAuthor.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));

    final buf = StringBuffer('Mod Authors\n');
    for (final entry in sorted.take(20)) {
      final count = entry.value.length;
      buf.writeln('  ${entry.key}: $count mod${count == 1 ? '' : 's'}');
    }
    if (sorted.length > 20) {
      buf.writeln('  ...and ${sorted.length - 20} more authors');
    }

    return ChatResponse(text: buf.toString().trimRight());
  }

  String _extractAuthorName(String input) {
    // Try to extract author name after "by" or "from"
    for (final prefix in ['mods by ', 'by ', 'from ', 'who made ']) {
      final idx = input.indexOf(prefix);
      if (idx != -1) {
        return input.substring(idx + prefix.length).trim();
      }
    }

    // Remove known trigger words
    var cleaned = input;
    for (final word in [
      'mod authors',
      'list authors',
      'which author',
      'authors',
      'author',
      'mods',
      'mod',
      'list',
      'show',
    ]) {
      cleaned = cleaned.replaceAll(word, '');
    }
    return cleaned.trim();
  }
}
