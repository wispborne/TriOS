import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../chatbot_engine.dart';
import '../chatbot_models.dart';
import 'mod_aware_intent.dart';
import 'profile_aware_intent.dart';

/// Shows details about the currently active mod profile.
class CurrentProfileIntent extends ChatIntent with ProfileAwareIntent {
  @override
  final Ref ref;

  CurrentProfileIntent(this.ref);

  static const _phrases = [
    'current profile',
    'active profile',
    'which profile',
    'what profile am i using',
    'selected profile',
    'my current profile',
  ];

  static const _primaryKeywords = {
    'current': 0.4,
    'active': 0.4,
    'selected': 0.4,
  };

  static const _secondaryKeywords = {
    'profile': 0.2,
    'which': 0.1,
    'using': 0.1,
  };

  @override
  String get id => 'current_profile';

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
    final profile = currentProfile;
    if (profile == null) {
      return const ChatResponse(
        text: 'No mod profile is currently active.\n'
            'Create and activate a profile on the Mod Profiles page.',
      );
    }

    final buf = StringBuffer('Active Profile: ${profile.name}\n');
    if (profile.description.isNotEmpty) {
      buf.writeln('  Description: ${profile.description}');
    }
    buf.writeln('  Mods: ${profile.enabledModVariants.length}');
    if (profile.dateCreated != null) {
      buf.writeln(
        '  Created: ${profile.dateCreated!.toLocal().toString().split('.').first}',
      );
    }
    if (profile.dateModified != null) {
      buf.writeln(
        '  Modified: ${profile.dateModified!.toLocal().toString().split('.').first}',
      );
    }

    return ChatResponse(text: buf.toString().trimRight());
  }
}
