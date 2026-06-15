import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/chipper/utils.dart';

import '../chatbot_engine.dart';
import '../chatbot_models.dart';
import 'mod_aware_intent.dart';

/// Reviews the user's enabled modlist with opinionated, snarky commentary.
class ModlistRatingIntent extends ChatIntent with ModAwareIntent {
  @override
  final Ref ref;

  ModlistRatingIntent(this.ref);

  static const _phrases = [
    'rate my modlist',
    'rate my mods',
    'modlist rating',
    'judge my mods',
    'how good is my modlist',
    'grade my mods',
    'roast my mods',
    'review my mods',
    'what do you think of my mods',
    'rate modlist',
    'judge modlist',
    'roast modlist',
  ];

  static const _primaryKeywords = {
    'rate': 0.5,
    'rating': 0.5,
    'roast': 0.5,
    'judge': 0.45,
    'grade': 0.45,
    'review': 0.4,
  };

  static const _secondaryKeywords = {
    'modlist': 0.2,
    'mods': 0.15,
    'mod': 0.1,
    'my': 0.05,
    'think': 0.1,
    'good': 0.1,
    'opinion': 0.15,
  };

  @override
  String get id => 'modlist_rating';

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

    final enabledMods = mods.where((m) => m.isEnabledInGame).toList();

    if (enabledMods.isEmpty) {
      return const ChatResponse(
        text: "You have zero mods enabled. That's not a modlist.",
      );
    }

    final enabledIds = <String>{};
    final recognizedEntries = <String>[];
    final unrecognizedNames = <String>[];
    var factionCount = 0;
    var libraryCount = 0;
    var qolCount = 0;

    for (final mod in enabledMods) {
      final variant = mod.findFirstEnabled;
      if (variant == null) continue;

      final modId = variant.modInfo.id;
      final name = variant.modInfo.nameOrId;
      enabledIds.add(modId);

      final opinion = _modOpinions[modId];
      if (opinion != null) {
        recognizedEntries.add('  ${opinion.comment}');
        switch (opinion.tier) {
          case _Tier.library:
            libraryCount++;
          case _Tier.faction:
            factionCount++;
          case _Tier.qol:
            qolCount++;
          case _Tier.gameplay:
          case _Tier.content:
          case _Tier.meme:
            break;
        }
      } else {
        unrecognizedNames.add(name);
        if (variant.modInfo.isUtility) {
          libraryCount++;
        } else if (variant.modInfo.isTotalConversion) {
          factionCount++;
        }
      }
    }

    final buf = StringBuffer(
      'Modlist Review (${enabledMods.length} mods enabled)\n\n',
    );

    // Show recognized mods first (capped at 15).
    const maxDisplay = 15;
    for (final entry in recognizedEntries.take(maxDisplay)) {
      buf.writeln(entry);
    }
    if (recognizedEntries.length > maxDisplay) {
      buf.writeln(
        '  ...and ${recognizedEntries.length - maxDisplay} more mods '
        "I have opinions about",
      );
    }

    // Unrecognized mods.
    if (unrecognizedNames.isNotEmpty) {
      if (unrecognizedNames.length <= 3) {
        for (final name in unrecognizedNames) {
          buf.writeln("  $name — never heard of it. You're on your own.");
        }
      } else {
        buf.writeln(
          '  ...plus ${unrecognizedNames.length} mods I don\'t recognize.',
        );
      }
    }

    // Combo roasts.
    final combos = _detectCombos(enabledIds, factionCount);
    if (combos.isNotEmpty) {
      buf.writeln();
      // for (final combo in combos) {
        buf.writeln('  ${combos.random()}');
      // }
    }

    // Overall verdict.
    buf.writeln();
    buf.write(_generateVerdict(
      enabledMods.length,
      recognizedEntries.length,
      unrecognizedNames.length,
      factionCount,
      libraryCount,
      qolCount,
      enabledIds,
    ));

    return ChatResponse(text: buf.toString().trimRight());
  }

  List<String> _detectCombos(Set<String> ids, int factionCount) {
    final combos = <String>[];

    if (ids.contains('shaderLib') && factionCount >= 6) {
      combos.add(
        'GraphicsLib and $factionCount faction mods? '
      );
    }

    if (ids.contains('nexerelin') && factionCount >= 8) {
      combos.add(
        'Nex + $factionCount factions. Hope you brought a book for those '
        'load times.',
      );
    }

    if (!ids.contains('nexerelin') && factionCount >= 4) {
      combos.add(
        "You know, most people would be using Nexerelin with that many factions.",
      );
    } else if (!ids.contains('nexerelin')) {
      combos.add(
        "No Nex?",
      );
    }

    if (ids.contains('lw_console') && ids.contains('nexerelin')) {
      combos.add(
        'Console Commands + Nexerelin. "Totally legit conquest playthrough."',
      );
    }

    final contentMods = ids.length -
        ids.where((id) => _modOpinions[id]?.tier == _Tier.library).length;
    if (ids.length >= 5 && contentMods <= 2) {
      combos.add(
        'Nice library collection. Where are the actual mods?',
      );
    }

    return combos;
  }

  String _generateVerdict(
    int totalEnabled,
    int recognizedCount,
    int unrecognizedCount,
    int factionCount,
    int libraryCount,
    int qolCount,
    Set<String> enabledIds,
  ) {
    final hasNex = enabledIds.contains('nexerelin');
    final hasGraphics = enabledIds.contains('shaderLib');
    final recognizedRatio =
        totalEnabled > 0 ? recognizedCount / totalEnabled : 0.0;

    // Base score out of 10.
    var score = 5;

    if (hasNex) score += 1;
    if (hasGraphics) score += 1;
    if (factionCount >= 3) score += 1;
    if (recognizedRatio > 0.6) score += 1;
    if (totalEnabled >= 10) score += 1;
    if (factionCount >= 10) score -= 1; // bloat penalty
    if (unrecognizedCount > recognizedCount) score -= 1;
    score = score.clamp(1, 10);

    final verdict = switch (score) {
      10 => "You're not really playing Starsector at this point.",
      9 => "Genuinely solid modlist. You know what you're doing.",
      8 => "Good taste. Your PC might not agree but I do.",
      7 => "Pretty solid. A few questionable choices but overall not bad.",
      6 => "Decent. Could be better, could be way worse.",
      5 => "Mid. Like, aggressively average. Add some faction mods or "
          "something.",
      4 => "This modlist needs work. I've seen better from first-time "
          "modders.",
      3 => "Are you even trying? This is barely modded.",
      2 => "This is sad. Install Nexerelin at minimum.",
      _ => "One mod? Really? That's not a modlist, that's a suggestion.",
    };

    return '  Verdict: $score/10 — $verdict';
  }
}

enum _Tier { library, gameplay, faction, content, qol, meme }

class _ModOpinion {
  final String comment;
  final _Tier tier;

  const _ModOpinion(this.comment, this.tier);
}

const _modOpinions = <String, _ModOpinion>{
  // === Libraries ===
  'lw_lazylib': _ModOpinion(
    "LazyLib — you literally can't run anything without this. "
        "Welcome to modding.",
    _Tier.library,
  ),
  'MagicLib': _ModOpinion(
    "MagicLib — the other tax you pay to mod this game.",
    _Tier.library,
  ),
  'shaderLib': _ModOpinion(
    "GraphicsLib — hope you like your GPU running at "
        "surface-of-the-sun temps.",
    _Tier.library,
  ),
  'lunalib': _ModOpinion(
    "LunaLib — another library. At this point your mod folder is "
        "50% libraries.",
    _Tier.library,
  ),

  // === Major gameplay ===
  'nexerelin': _ModOpinion(
    "Nexerelin — oh you wanted a 4X grand strategy game? "
        "Say goodbye to your free time.",
    _Tier.gameplay,
  ),
  'IndEvo': _ModOpinion(
    "Industrial Evolution — for when vanilla colonies aren't enough "
        "of a spreadsheet simulator.",
    _Tier.gameplay,
  ),
  'sun_starship_legends': _ModOpinion(
    "Starship Legends — your ships have feelings now. "
        "Great, more emotional baggage.",
    _Tier.gameplay,
  ),
  'second_in_command': _ModOpinion(
    "Second-in-Command — finally, someone else to blame when things "
        "go wrong.",
    _Tier.gameplay,
  ),
  'officer_extension': _ModOpinion(
    "Officer Extension — because the vanilla officer cap was clearly a "
        "personal insult.",
    _Tier.gameplay,
  ),
  'kcmods_knightsofludd': _ModOpinion(
    "Knights of Ludd — the Luddic Path got a glow-up and honestly "
        "they didn't deserve it.",
    _Tier.gameplay,
  ),
  'RealisticCombat': _ModOpinion(
    "Realistic Combat — for people who thought Starsector was too "
        "forgiving.",
    _Tier.gameplay,
  ),
  'RandomAssortmentOfThings': _ModOpinion(
    "Random Assortment of Things — the mod equivalent of a mystery box. "
        "Somehow it works.",
    _Tier.gameplay,
  ),

  // === Faction mods ===
  'diableavionics': _ModOpinion(
    "Diable Avionics — anime mechs in space. We all know why you "
        "installed this.",
    _Tier.faction,
  ),
  'blackrock_driveyards': _ModOpinion(
    "Blackrock Drive Yards — the faction for people who think the "
        "Hegemony isn't oppressive enough.",
    _Tier.faction,
  ),
  'SCY': _ModOpinion(
    "Scy Nation — gotta go fast. Until you get caught and die "
        "instantly.",
    _Tier.faction,
  ),
  'shadowyards': _ModOpinion(
    "Shadowyards — stealth faction for people who think cloaking is a "
        "personality trait.",
    _Tier.faction,
  ),
  'tahlan': _ModOpinion(
    "Tahlan Shipworks — Great Houses aesthetic goes hard ngl.",
    _Tier.faction,
  ),
  'arkgneisis': _ModOpinion(
    "Legacy of Arkgneisis — flying garbage cans held together with "
        "spite and duct tape.",
    _Tier.faction,
  ),
  'ORA': _ModOpinion(
    "Outer Rim Alliance — broadsides only. For people who think "
        "flanking is for cowards.",
    _Tier.faction,
  ),
  'al_ruk': _ModOpinion(
    "Al-Ruk Ascendancy — what if we made a faction and just cranked "
        "everything to 11?",
    _Tier.faction,
  ),
  'mayorate': _ModOpinion(
    "Mayorate — corporate dystopia faction. So just regular Starsector "
        "but more honest about it.",
    _Tier.faction,
  ),
  'kadur_remnant': _ModOpinion(
    "Kadur Remnant — space vikings. That's it. That's the pitch. "
        "And it works.",
    _Tier.faction,
  ),
  'dassault_mikoyan': _ModOpinion(
    "Dassault-Mikoyan — fighter spam: the faction. Your framerate "
        "weeps.",
    _Tier.faction,
  ),
  'perseanchronicles': _ModOpinion(
    "Persean Chronicles — someone actually wrote lore for this game. "
        "Like, a lot of it.",
    _Tier.faction,
  ),
  'vayra': _ModOpinion(
    "Vayra's Sector — more factions, more bounties, more everything. "
        "Quantity is a quality of its own.",
    _Tier.faction,
  ),
  'torchships': _ModOpinion(
    "Torchships — hard sci-fi in my Starsector? It's more likely than "
        "you think.",
    _Tier.faction,
  ),
  'roider': _ModOpinion(
    "Roider Union — space rednecks with welding torches. Surprisingly "
        "endearing.",
    _Tier.faction,
  ),
  'apex_design': _ModOpinion(
    "Apex Design Collective — these ships look like someone's thesis "
        "project and I mean that as a compliment.",
    _Tier.faction,
  ),
  'eis': _ModOpinion(
    "Enigma Industries — another faction mod. Sure. Why not. "
        "Throw it on the pile.",
    _Tier.faction,
  ),

  // === Content / ship packs ===
  'swp': _ModOpinion(
    "Ship/Weapon Pack — basically vanilla+ but actually good.",
    _Tier.content,
  ),
  'dmods': _ModOpinion(
    "Missing Ships — filling gaps you didn't know existed. "
        "Solid pick.",
    _Tier.content,
  ),
  'arsenalExpansion': _ModOpinion(
    "Arsenal Expansion — more guns, more ships, can't go wrong. "
        "Or can you.",
    _Tier.content,
  ),
  'armaa': _ModOpinion(
    "Arma Armatura — giant robots in Starsector. The Gundam fans "
        "found us.",
    _Tier.content,
  ),
  'unknownSkies': _ModOpinion(
    "Unknown Skies — 30 new planets to colonize. As if you needed "
        "more territory to mismanage.",
    _Tier.content,
  ),
  'more_portrait': _ModOpinion(
    "More Character Portraits — because staring at the same 20 faces "
        "gets old fast.",
    _Tier.content,
  ),

  // === QoL ===
  'lw_console': _ModOpinion(
    "Console Commands — \"I'm just using it for testing\" sure buddy.",
    _Tier.qol,
  ),
  'autosave': _ModOpinion(
    "Autosave — the fact this isn't in vanilla is a war crime.",
    _Tier.qol,
  ),
  'common_radar': _ModOpinion(
    "Common Radar — how did you play without this?",
    _Tier.qol,
  ),
  'lw_version_checker': _ModOpinion(
    "Version Checker — responsible modding. Boring but necessary.",
    _Tier.qol,
  ),
  'more_ship_names': _ModOpinion(
    "More Ship Names — 7500 new names and somehow still no HMS Boaty "
        "McBoatface.",
    _Tier.qol,
  ),
  'speedUp': _ModOpinion(
    "SpeedUp — because vanilla game speed is for people with infinite "
        "patience.",
    _Tier.qol,
  ),
  'transponder_off': _ModOpinion(
    "Transponder Off — running dark without consequences. Living the "
        "pirate dream.",
    _Tier.qol,
  ),
  'detailedcombatresults': _ModOpinion(
    "Detailed Combat Results — for when you need to know exactly which "
        "frigate let you down.",
    _Tier.qol,
  ),
  'leading_pip': _ModOpinion(
    "Leading Pip — aim assist for people who can't lead shots. "
        "No shame. Ok maybe a little.",
    _Tier.qol,
  ),
  'nexerelin_wardashboard': _ModOpinion(
    "War Dashboard — spreadsheet simulator for your war simulator. "
        "We've gone full circle.",
    _Tier.qol,
  ),

  // === Total conversions ===
  'swfactions': _ModOpinion(
    "Star Wars mod — because no space game is safe from Star Wars.",
    _Tier.faction,
  ),

  // === Meme / niche ===
  'vram_vore': _ModOpinion(
    "VRAM Vore — it's literally named VRAM Vore. "
        "You know what you signed up for.",
    _Tier.meme,
  ),
};
