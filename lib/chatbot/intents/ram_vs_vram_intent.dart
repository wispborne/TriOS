import '../chatbot_engine.dart';
import '../chatbot_models.dart';
import 'mod_aware_intent.dart';

/// Explains the difference between RAM and VRAM in a Starsector context.
class RamVsVramIntent extends ChatIntent {
  static const _phrases = [
    'ram vs vram',
    'vram vs ram',
    'ram versus vram',
    'vram versus ram',
    'difference between ram and vram',
    'ram and vram difference',
    'ram vram difference',
    'what is vram',
    'what is ram',
    'ram or vram',
    'is it ram or vram',
    'do i need more ram or vram',
    'video memory vs ram',
    'video memory vs system memory',
    'system memory vs video memory',
    'how much vram',
    'how much ram',
    'how much video memory',
  ];

  static const _primaryKeywords = {
    'vram': 0.5,
    'video memory': 0.45,
    'gpu memory': 0.45,
    'graphics memory': 0.4,
  };

  static const _secondaryKeywords = {
    'ram': 0.2,
    'memory': 0.15,
    'difference': 0.15,
    'versus': 0.1,
    'vs': 0.1,
  };

  @override
  String get id => 'ram_vs_vram';

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

  static const _response = 'RAM vs VRAM — Quick Guide\n'
      '\n'
      'RAM (System Memory):\n'
      "  Used by Starsector's Java process for game logic, mod code, and data.\n"
      '  Controlled by the JVM heap size (-Xmx flag).\n'
      '  More RAM = more mods, bigger battles, fewer OutOfMemoryErrors.\n'
      '\n'
      'VRAM (Video Memory):\n'
      '  Lives on your GPU. Used for textures, sprites, and shaders.\n'
      '  NOT controlled by the -Xmx flag or any JVM setting.\n'
      '  More VRAM = more graphical mods, higher-res textures.\n'
      '\n'
      'Key Takeaway:\n'
      '  "OutOfMemoryError" in your log → you need more RAM.\n'
      '  Graphical glitches or missing textures → could be VRAM.\n'
      '  Most Starsector modding issues are RAM, not VRAM.\n'
      '\n'
      'Use the Dashboard page in TriOS to adjust your RAM allocation.';
}
