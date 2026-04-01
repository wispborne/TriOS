import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../chatbot_engine.dart';
import '../chatbot_models.dart';
import 'mod_aware_intent.dart';
import 'profile_aware_intent.dart';

/// Lists all saved mod profiles.
class ListProfilesIntent extends ChatIntent with ProfileAwareIntent {
  @override
  final Ref ref;

  ListProfilesIntent(this.ref);

  static const _phrases = [
    'list profiles',
    'my profiles',
    'show profiles',
    'all profiles',
    'mod profiles',
    'what profiles',
  ];

  static const _primaryKeywords = {
    'profiles': 0.55,
    'profile': 0.5,
  };

  static const _secondaryKeywords = {
    'list': 0.1,
    'show': 0.1,
    'all': 0.1,
    'my': 0.1,
  };

  @override
  String get id => 'list_profiles';

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
    final profiles = modProfiles;
    if (profiles == null || profiles.modProfiles.isEmpty) {
      return const ChatResponse(
        text: 'No mod profiles saved yet.\n'
            'Create profiles on the Mod Profiles page to save different '
            'mod configurations.',
      );
    }

    final active = currentProfile;
    final buf = StringBuffer(
      'Mod Profiles (${profiles.modProfiles.length})\n',
    );

    for (final p in profiles.modProfiles) {
      final isActive = active != null && p.id == active.id;
      final marker = isActive ? ' ← active' : '';
      buf.writeln(
        '  ${p.name} (${p.enabledModVariants.length} mods)$marker',
      );
      if (p.description.isNotEmpty) {
        buf.writeln('    ${p.description}');
      }
    }

    return ChatResponse(text: buf.toString().trimRight());
  }
}
