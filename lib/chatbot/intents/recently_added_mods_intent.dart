import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../chatbot_engine.dart';
import '../chatbot_models.dart';
import 'mod_aware_intent.dart';

/// Lists mods that were recently added, using firstSeen metadata.
class RecentlyAddedModsIntent extends ChatIntent with ModAwareIntent {
  @override
  final Ref ref;

  RecentlyAddedModsIntent(this.ref);

  static const _phrases = [
    'recently added mods',
    'new mods',
    'newest mods',
    'recently installed',
    'latest mods',
    'what mods did i add',
    'recently added',
  ];

  static const _primaryKeywords = {
    'recently': 0.45,
    'recent': 0.45,
    'new': 0.4,
    'newest': 0.45,
    'latest': 0.4,
    'added': 0.35,
  };

  static const _secondaryKeywords = {
    'mods': 0.15,
    'mod': 0.15,
    'installed': 0.15,
    'show': 0.1,
  };

  @override
  String get id => 'recently_added_mods';

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

    final metadata = modsMetadata;
    if (metadata == null) {
      return const ChatResponse(
        text: 'Mod metadata is not available yet.',
      );
    }

    // Pair each mod with its firstSeen timestamp
    final modsWithDate = <({String name, String version, int firstSeen})>[];
    for (final mod in mods) {
      final modMeta = metadata.getMergedModMetadata(mod.id);
      if (modMeta == null) continue;
      final variant = mod.findFirstEnabledOrHighestVersion;
      final name = variant?.modInfo.nameOrId ?? mod.id;
      final version =
          variant?.modInfo.version != null ? 'v${variant!.modInfo.version}' : '';
      modsWithDate.add((
        name: name,
        version: version,
        firstSeen: modMeta.firstSeen,
      ));
    }

    if (modsWithDate.isEmpty) {
      return const ChatResponse(text: 'No mod metadata available.');
    }

    // Sort by firstSeen descending (most recent first)
    modsWithDate.sort((a, b) => b.firstSeen.compareTo(a.firstSeen));

    final now = DateTime.now();
    final buf = StringBuffer('Recently Added Mods\n');
    for (final entry in modsWithDate.take(10)) {
      final addedDate =
          DateTime.fromMillisecondsSinceEpoch(entry.firstSeen);
      final age = _formatAge(now.difference(addedDate));
      buf.writeln('  ${entry.name} ${entry.version} — added $age');
    }

    return ChatResponse(text: buf.toString().trimRight());
  }

  String _formatAge(Duration duration) {
    if (duration.inDays > 365) {
      final years = duration.inDays ~/ 365;
      return '$years year${years == 1 ? '' : 's'} ago';
    } else if (duration.inDays > 30) {
      final months = duration.inDays ~/ 30;
      return '$months month${months == 1 ? '' : 's'} ago';
    } else if (duration.inDays > 0) {
      return '${duration.inDays} day${duration.inDays == 1 ? '' : 's'} ago';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} hour${duration.inHours == 1 ? '' : 's'} ago';
    } else {
      return 'just now';
    }
  }
}
