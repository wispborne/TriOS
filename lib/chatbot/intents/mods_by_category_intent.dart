import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/mod_tag_manager/category_manager.dart';

import '../chatbot_engine.dart';
import '../chatbot_models.dart';
import 'mod_aware_intent.dart';

/// Lists mod categories and the mods assigned to each.
class ModsByCategoryIntent extends ChatIntent with ModAwareIntent {
  @override
  final Ref ref;

  ModsByCategoryIntent(this.ref);

  static const _phrases = [
    'mods by category',
    'mod categories',
    'show categories',
    'list categories',
    'what categories',
    'mod tags',
    'mods by tag',
  ];

  static const _primaryKeywords = {
    'categories': 0.55,
    'category': 0.55,
    'tags': 0.45,
    'tag': 0.45,
  };

  static const _secondaryKeywords = {
    'mods': 0.1,
    'list': 0.1,
    'show': 0.1,
    'by': 0.1,
  };

  @override
  String get id => 'mods_by_category';

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
    final store =
        ref.read(categoryManagerProvider).valueOrNull;

    if (store == null || store.categories.isEmpty) {
      return const ChatResponse(
        text: 'No mod categories defined yet.\n'
            'You can create categories in the Mod Manager by right-clicking a mod.',
      );
    }

    final categories = store.categories.toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    final buf = StringBuffer(
      'Mod Categories (${categories.length})\n',
    );

    for (final cat in categories) {
      // Count mods assigned to this category.
      final assignedCount = store.modAssignments.values
          .where(
            (assignments) =>
                assignments.any((a) => a.categoryId == cat.id),
          )
          .length;
      buf.writeln('  ${cat.name} ($assignedCount mods)');
    }

    if (store.modAssignments.isEmpty) {
      buf.writeln(
        '\nNo mods are assigned to categories yet.',
      );
    }

    return ChatResponse(text: buf.toString().trimRight());
  }
}
