import 'dart:math';

import 'package:trios/catalog/catalog_page_controller.dart';
import 'package:trios/catalog/models/catalog_mod.dart';
import 'package:trios/catalog/models/mod_repo_entry.dart';
import 'package:trios/utils/catalog_search.dart';

// The Catalog search. A straight port of Starmodder's `site/search.js`, kept
// in the same parts so the two are easy to compare when one of them changes.
//
// Comma-separated groups are alternatives. Every word within a group must
// match one of the mod's facts.

// --- The clean-up ---

/// Apostrophes, taken out without leaving a gap, so "Amazigh's" is "amazighs".
final _apostrophes = RegExp("['’‘´`]");
final _notALetterDigitOrDot = RegExp(r'[^\p{L}\p{N}.]+', unicode: true);
final _accentMarks = RegExp(r'\p{M}', unicode: true);

/// A dot with no digit on one side of it. Only "0.98"-style dots are kept.
final _loneDot = RegExp(r'(?<!\p{N})\.|\.(?!\p{N})', unicode: true);
final _spaces = RegExp(r'\s+');

/// Accented Latin letters and the plain letter each one becomes. Dart has no
/// built-in way to take accents off, so this covers the common ones. Letters of
/// other alphabets are left alone.
const _accented =
    'àáâãäåāăąǎçćĉċčďèéêëēĕėęěĝğġģĥìíîïĩīĭįǐĵķĺļľñńņňòóôõöōŏőǒŕŗřśŝşšţťùúûüũūŭůűųǔŵýÿŷźżž';
const _plain =
    'aaaaaaaaaacccccdeeeeeeeeegggghiiiiiiiiijklllnnnnooooooooorrrssssttuuuuuuuuuuuwyyyzzz';
final Map<int, int> _plainLetterFor = {
  for (var i = 0; i < _accented.length; i++)
    _accented.codeUnitAt(i): _plain.codeUnitAt(i),
};

String _removeAccents(String text) {
  if (!text.codeUnits.any(_plainLetterFor.containsKey)) return text;
  return String.fromCharCodes(
    text.codeUnits.map((unit) => _plainLetterFor[unit] ?? unit),
  );
}

/// Text reduced to lowercase words with single spaces between them: accents
/// off, apostrophes gone, every other mark a space, and a dot kept only
/// between two digits so a version like "0.98a" survives. Letters of every
/// alphabet are kept.
String normalizeSearchText(String? text) {
  if (text == null) return '';
  return _removeAccents(
        text
            .replaceAll(_apostrophes, '')
            .replaceAll(_notALetterDigitOrDot, ' ')
            .toLowerCase(),
      )
      .replaceAll(_accentMarks, '')
      .replaceAll(_notALetterDigitOrDot, ' ')
      .replaceAll(_loneDot, ' ')
      .replaceAll(_spaces, ' ')
      .trim();
}

/// The same text with the spaces taken out, so "shipweapon" can match
/// "Ship/Weapon Pack".
String _squash(String cleaned) => cleaned.replaceAll(' ', '');

final _smallThenCapital = RegExp(r'(\p{Ll})(\p{Lu})', unicode: true);

/// A name split where a small letter is followed by a capital, so
/// "GraphicsLib" is also read as "Graphics Lib" and its initials are "gl".
String _splitAtCapitals(String text) =>
    text.replaceAllMapped(_smallThenCapital, (m) => '${m[1]} ${m[2]}');

// --- Spelling distance ---

/// How many single-letter changes turn one word into the other: a letter
/// added, taken away or swapped for another, or two letters next to each
/// other trading places. Stops early and answers `limit + 1` once the answer
/// is sure to be over [limit].
int editDistance(String a, String b, {int? limit}) {
  final most = limit ?? a.length + b.length;
  if ((a.length - b.length).abs() > most) return most + 1;
  List<int> before = const [];
  var previous = List<int>.generate(b.length + 1, (j) => j);
  for (var i = 1; i <= a.length; i++) {
    final row = <int>[i];
    var smallest = i;
    for (var j = 1; j <= b.length; j++) {
      final change = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
      var cost = min(
        min(previous[j] + 1, row[j - 1] + 1),
        previous[j - 1] + change,
      );
      if (i > 1 &&
          j > 1 &&
          a.codeUnitAt(i - 1) == b.codeUnitAt(j - 2) &&
          a.codeUnitAt(i - 2) == b.codeUnitAt(j - 1)) {
        cost = min(cost, before[j - 2] + 1);
      }
      row.add(cost);
      if (cost < smallest) smallest = cost;
    }
    if (smallest > most) return most + 1;
    before = previous;
    previous = row;
  }
  return previous[b.length];
}

// --- What a mod can be found by ---

/// Words too small to count when a name is shortened to its initials, or to
/// stop a run of word starts ("aotd" and "ad" are both Ashes of the Domain).
const _stopWords = {
  'of',
  'the',
  'and',
  'for',
  'a',
  'an',
  'in',
  'on',
  'to',
  'by',
  'or',
  'at',
};

/// The kinds of fact a mod can be found by. Each has a cost, which is taken
/// off the score of any match on it, so a match on the name ranks ahead of one
/// in the description.
enum CatalogFactKind {
  name(0),
  namePiece(10),
  initials(0),
  person(0),
  category(20),
  version(20),
  summary(40),
  description(45),
  link(45);

  final int cost;

  const CatalogFactKind(this.cost);

  /// The kinds that say who or what the mod is. A typed word that hits none
  /// of these is the one a close spelling is tried for.
  bool get isIdentity => switch (this) {
    name || namePiece || initials || person => true,
    _ => false,
  };
}

/// One cleaned-up fact about a mod and what a match on it costs.
class CatalogSearchTerm {
  final String term;
  final CatalogFactKind kind;

  const CatalogSearchTerm(this.term, this.kind);

  int get cost => kind.cost;
}

/// Everything worked out for a mod, kept so it is done once per mod.
class CatalogSearchFacts {
  /// Every fact, cleaned up. When two facts clean to the same text, the
  /// cheaper one is kept.
  final List<CatalogSearchTerm> terms;

  /// The cleaned shown name, catalog name and nicknames.
  final List<String> names;

  /// The words of the shown name, as written and split at capitals. Used for
  /// word-start shorthand.
  final List<List<String>> nameWords;

  /// The words of every name and person, for close spellings.
  final List<String> closeWords;

  /// The summary texts searched, for `summary:`.
  final List<String> summaries;

  /// Whether the AI sentence is among the facts.
  final bool includesAiText;

  const CatalogSearchFacts({
    required this.terms,
    required this.names,
    required this.nameWords,
    required this.closeWords,
    required this.summaries,
    required this.includesAiText,
  });

  factory CatalogSearchFacts.of(
    CatalogMod mod, {
    required bool includeAiText,
  }) {
    final terms = <String, CatalogSearchTerm>{};
    void add(String? value, CatalogFactKind kind) {
      final term = normalizeSearchText(value);
      if (term.isEmpty) return;
      final had = terms[term];
      if (had == null || kind.cost < had.cost) {
        terms[term] = CatalogSearchTerm(term, kind);
      }
    }

    final shown = mod.title;
    final entry = mod.entry;
    final names = [
      shown,
      entry.name,
      ...mod.nicknames,
    ].map(normalizeSearchText).where((name) => name.isNotEmpty).toList();
    for (final name in names) {
      add(name, CatalogFactKind.name);
      add(_squash(name), CatalogFactKind.name);
    }

    final nameWords = <List<String>>[];
    final forms = {
      normalizeSearchText(shown),
      normalizeSearchText(_splitAtCapitals(shown)),
    };
    for (final form in forms) {
      final words = form.split(' ').where((w) => w.isNotEmpty).toList();
      if (words.isEmpty) continue;
      nameWords.add(words);
      for (final word in words) {
        add(word, CatalogFactKind.namePiece);
      }
      if (words.length < 2) continue;
      // The initials, and again with the little words left out: "Ashes of the
      // Domain" is "aotd" taking every word and "ad" taking only the ones that
      // mean anything, and people write it both ways.
      add(words.map((w) => w[0]).join(), CatalogFactKind.initials);
      final solid = words.where((w) => !_stopWords.contains(w)).toList();
      if (solid.length >= 2) {
        add(solid.map((w) => w[0]).join(), CatalogFactKind.initials);
      }
    }
    for (final word in normalizeSearchText(entry.name).split(' ')) {
      add(word, CatalogFactKind.namePiece);
    }

    final people = [
      ...entry.getAuthors(),
      ...mod.otherAuthorNames,
    ].map(normalizeSearchText).where((p) => p.isNotEmpty).toList();
    for (final person in people) {
      add(person, CatalogFactKind.person);
      add(_squash(person), CatalogFactKind.person);
    }

    for (final category in entry.getCategories()) {
      add(category, CatalogFactKind.category);
    }
    add(entry.gameVersionReq, CatalogFactKind.version);
    add(entry.modVersion, CatalogFactKind.version);

    // The AI sentence counts only while AI summaries can be shown, so a match
    // never comes from text the user has turned off.
    final summaries = [
      ?mod.summaryText,
      if (includeAiText) ?mod.aiSentence,
    ];
    for (final summary in summaries) {
      add(summary, CatalogFactKind.summary);
    }
    add(mod.descriptionText, CatalogFactKind.description);
    for (final link in mod.allLinks) {
      add(link, CatalogFactKind.link);
    }

    final closeWords = <String>{
      for (final text in [...names, ...people])
        for (final word in text.split(' '))
          if (word.isNotEmpty) word,
    };

    return CatalogSearchFacts(
      terms: terms.values.toList(),
      names: names,
      nameWords: nameWords,
      closeWords: closeWords.toList(),
      summaries: summaries,
      includesAiText: includeAiText,
    );
  }
}

/// Facts kept on the mod itself, because two mods can share a name. A rebuilt
/// catalog makes new [CatalogMod] objects, which get new facts.
final _factsByMod = Expando<CatalogSearchFacts>('catalog search facts');

CatalogSearchFacts _factsOf(CatalogMod mod, bool includeAiText) {
  final known = _factsByMod[mod];
  if (known != null && known.includesAiText == includeAiText) return known;
  final facts = CatalogSearchFacts.of(mod, includeAiText: includeAiText);
  _factsByMod[mod] = facts;
  return facts;
}

// --- How well one typed word answers ---

/// How well one fact answers a typed word: the fact being exactly the word,
/// starting with it, having a word inside it that starts with it, or holding
/// it somewhere. Below zero when it does not answer at all.
int _scoreTerm(CatalogSearchTerm fact, String wanted) {
  int score;
  if (fact.term == wanted) {
    score = 100;
  } else if (fact.term.startsWith(wanted)) {
    score = 80;
  } else if (fact.term.contains(' $wanted')) {
    score = 70;
  } else if (fact.term.contains(wanted)) {
    score = 50;
  } else {
    return -1;
  }
  // Typing a mod's initials exactly is naming it, near enough.
  if (score == 100 && fact.kind == CatalogFactKind.initials) score += 40;
  return score - fact.cost;
}

/// A run of word starts scores below any match on the name's own words, so a
/// mod whose name really holds the letters always comes first.
const _wordStartsScore = 45;

/// A close spelling of a name scores below every exact match on a name or a
/// person, and above a word found mid-way through a summary. Indexed by the
/// number of changes.
const _closeScores = [-1, 38, 34];

final _hasDigit = RegExp(r'\p{N}', unicode: true);
final _onlyLetters = RegExp(r'^\p{L}+$', unicode: true);

/// The best score a plain word or a quoted phrase gets against a mod. Exact
/// matching first; then, for a plain word, the two looser ways in.
int _scoreWord(CatalogSearchFacts facts, String wanted, {required bool loose}) {
  var best = -1;
  var hitsIdentity = false;
  for (final fact in facts.terms) {
    final score = _scoreTerm(fact, wanted);
    if (score < 0) continue;
    if (score > best) best = score;
    if (fact.kind.isIdentity) hitsIdentity = true;
  }
  if (!loose) return best;

  if (best < _wordStartsScore &&
      _builtFromWordStarts(wanted, facts.nameWords)) {
    best = _wordStartsScore;
  }
  if (!hitsIdentity) {
    final close = _closeSpelling(wanted, facts.closeWords);
    if (close > best) best = close;
  }
  return best;
}

/// True when the typed word can be built from the starts of words standing
/// next to each other in a name, in order, little words skipped where needed:
/// "indevo" is Ind-ustrial Evo-lution, "kol" is K-nights O-f L-udd.
///
/// Two limits keep ordinary words out: three letters or more, and either
/// every piece is one letter or every piece but the last is two letters or
/// more. Without the second, "faction" finds Fleet Action History ("f" +
/// "action").
bool _builtFromWordStarts(String wanted, List<List<String>> nameWords) {
  if (wanted.length < 3 || !_onlyLetters.hasMatch(wanted)) return false;
  for (final words in nameWords) {
    if (words.length < 2) continue;
    bool fits(int at, int from, List<int> pieces) {
      if (at == wanted.length) {
        if (pieces.length < 2) return false;
        return pieces.every((size) => size == 1) ||
            pieces
                .sublist(0, pieces.length - 1)
                .every((size) => size >= 2);
      }
      for (var i = from; i < words.length; i++) {
        final word = words[i];
        for (
          var size = min(word.length, wanted.length - at);
          size >= 1;
          size--
        ) {
          if (word.startsWith(wanted.substring(at, at + size)) &&
              fits(at + size, i + 1, [...pieces, size])) {
            return true;
          }
        }
        if (!_stopWords.contains(word)) break;
      }
      return false;
    }

    for (var first = 0; first < words.length; first++) {
      if (fits(0, first, const [])) return true;
    }
  }
  return false;
}

/// The score for a word spelled almost like one in a name or a person's name,
/// or -1. Only for words of five letters or more with no digits, and only
/// where the first letter is right, which almost every typo keeps. Without
/// that, "faction" is one letter from "action". One mistake is allowed in a
/// word of five to seven letters, two from eight letters up. A word is also
/// compared with the start of each longer word, so a half-typed word with a
/// mistake in it is still found.
int _closeSpelling(String wanted, List<String> words) {
  if (wanted.length < 5 || _hasDigit.hasMatch(wanted)) return -1;
  final allowed = wanted.length >= 8 ? 2 : 1;
  var fewest = allowed + 1;
  for (final word in words) {
    if (word.codeUnitAt(0) != wanted.codeUnitAt(0)) continue;
    fewest = min(fewest, editDistance(wanted, word, limit: allowed));
    if (word.length > wanted.length) {
      fewest = min(
        fewest,
        editDistance(
          wanted,
          word.substring(0, wanted.length),
          limit: allowed,
        ),
      );
    }
    if (fewest == 1) break;
  }
  return fewest >= 1 && fewest <= allowed ? _closeScores[fewest] : -1;
}

// --- Asking about one field ---

/// Gives back the values a field looks in for one mod.
typedef CatalogFieldValues =
    List<String?> Function(CatalogMod mod, CatalogSearchFacts facts);

/// Where the mod was posted, as the words `from:` matches.
List<String> _postedIn(CatalogMod mod) => [
  for (final source in mod.entry.getSources())
    ...switch (source) {
      ModSource.Index => const ['forum', 'index'],
      ModSource.ModdingSubforum => const ['forum'],
      ModSource.Discord => const ['discord'],
      ModSource.NexusMods => const ['nexus'],
    },
];

List<String?> _authorValues(CatalogMod mod, CatalogSearchFacts facts) => [
  ...mod.entry.getAuthors(),
  ...mod.otherAuthorNames,
];

List<String?> _categoryValues(CatalogMod mod, CatalogSearchFacts facts) =>
    mod.entry.getCategories();

List<String?> _gameVersionValues(CatalogMod mod, CatalogSearchFacts facts) => [
  mod.entry.gameVersionReq,
];

List<String?> _fromValues(CatalogMod mod, CatalogSearchFacts facts) =>
    _postedIn(mod);

/// The fields a user can ask about by name, as in `author:Wisp`. The plural
/// and old spellings work too. An unknown name is not an error: it falls
/// through to an ordinary search, so a mod whose name has a colon in it can
/// still be found.
final Map<String, CatalogFieldValues> _fields = {
  'name': (mod, facts) => [mod.entry.name, mod.title],
  'author': _authorValues,
  'authors': _authorValues,
  'category': _categoryValues,
  'categories': _categoryValues,
  'version': _gameVersionValues,
  'gameversion': _gameVersionValues,
  'modversion': (mod, facts) => [mod.entry.modVersion],
  'from': _fromValues,
  'source': _fromValues,
  'sources': _fromValues,
  'url': (mod, facts) => mod.allLinks,
  'summary': (mod, facts) => facts.summaries,
};

/// The yes-or-no questions a user can ask with `has:` or `is:`, as in
/// `has:source` or `-is:wip`. Both words work with every question, so nobody
/// has to remember which goes with which. A mod whose author says nothing
/// about AI answers no to both `ai` and `noai`.
final Map<String, bool Function(CatalogMod mod)> _flags = {
  'source': _hasSourceCode,
  'code': _hasSourceCode,
  'sourcecode': _hasSourceCode,
  // The same rule as the "Has Download Link" filter, so the two agree.
  'download': (mod) => mod.attributeKeys.contains(kAttrDownload),
  'addable': (mod) => mod.canAddToSave,
  'safe': (mod) => mod.canAddToSave,
  'wip': (mod) => mod.isWip,
  'tool': (mod) => mod.isTool,
  'ai': (mod) => mod.usesAi == true,
  'noai': (mod) => mod.usesAi == false,
};

bool _hasSourceCode(CatalogMod mod) => mod.sourceCodeUrl != null;

const _flagWords = {'has', 'is'};

/// A field asked about by name answers as well as a mod's own name does, so
/// `author:Wisp` puts Wisp's mods at the top.
const _fieldScore = 100;

// --- Reading what was typed ---

/// One piece of a comma group: something to look for, or with [leaveOut],
/// something that keeps a mod off the list.
sealed class SearchPiece {
  final bool leaveOut;

  const SearchPiece({required this.leaveOut});
}

/// A plain word. Shorthand and close spellings are tried for it.
class WordPiece extends SearchPiece {
  final String value;

  const WordPiece(this.value, {required super.leaveOut});
}

/// Text matched as one cleaned run, with no shorthand or close spellings.
class PhrasePiece extends SearchPiece {
  final String value;

  const PhrasePiece(this.value, {required super.leaveOut});
}

/// `field:value`: matches when one of the field's values holds [value].
class FieldPiece extends SearchPiece {
  final CatalogFieldValues field;
  final String value;

  const FieldPiece(this.field, this.value, {required super.leaveOut});
}

/// `has:word` or `is:word`: keeps or removes mods without changing their
/// score.
class FlagPiece extends SearchPiece {
  final bool Function(CatalogMod mod) test;

  const FlagPiece(this.test, {required super.leaveOut});
}

/// One comma group: every [wanted] piece must match, and no [unwanted] one.
class CatalogSearchGroup {
  final List<SearchPiece> wanted;
  final List<SearchPiece> unwanted;

  const CatalogSearchGroup({required this.wanted, required this.unwanted});
}

/// Splits text at a character, except inside double quotes.
List<String> _splitOutsideQuotes(String text, bool Function(String) isBreak) {
  final parts = <String>[];
  final current = StringBuffer();
  var quoted = false;
  for (var i = 0; i < text.length; i++) {
    final ch = text[i];
    if (ch == '"') quoted = !quoted;
    if (!quoted && isBreak(ch)) {
      parts.add(current.toString());
      current.clear();
    } else {
      current.write(ch);
    }
  }
  parts.add(current.toString());
  return parts;
}

/// A quote with no closing mark runs to the end of its comma group, so the
/// missing mark is put there.
String _closeOpenQuote(String text) {
  if ('"'.allMatches(text).length.isEven) return text;
  final open = text.lastIndexOf('"');
  final comma = text.indexOf(',', open);
  return comma < 0
      ? '$text"'
      : '${text.substring(0, comma)}"${text.substring(comma)}';
}

final _fieldTerm = RegExp(r'^([a-z]+):(.*)$', caseSensitive: false, dotAll: true);
final _pieceBreak = RegExp(r'[\s+]');
final _closingQuote = RegExp(r'"$');
final _wrappingQuotes = RegExp(r'^"|"$');

/// One piece of a group, read as what it asks for. Gives back a list, because
/// a plain word that clean-up turns into several ("seeker-unidentified") is
/// several words.
List<SearchPiece> _readPiece(String piece) {
  final leaveOut = piece.startsWith('-');
  final body = leaveOut ? piece.substring(1) : piece;
  if (body.isEmpty) return const [];

  if (body.startsWith('"')) {
    final phrase = normalizeSearchText(
      body.substring(1).replaceFirst(_closingQuote, ''),
    );
    return phrase.isEmpty ? const [] : [PhrasePiece(phrase, leaveOut: leaveOut)];
  }

  final asField = _fieldTerm.firstMatch(body);
  if (asField != null) {
    final key = asField[1]!.toLowerCase();
    if (_flagWords.contains(key)) {
      final test = _flags[_squash(normalizeSearchText(asField[2]))];
      if (test != null) return [FlagPiece(test, leaveOut: leaveOut)];
    }
    final field = _fields[key];
    final value = normalizeSearchText(
      asField[2]!.replaceAll(_wrappingQuotes, ''),
    );
    if (field != null && value.isNotEmpty) {
      return [FieldPiece(field, value, leaveOut: leaveOut)];
    }
  }

  final cleaned = normalizeSearchText(body);
  if (cleaned.isEmpty) return const [];
  // A word to leave out that cleans to several stays one thing to leave out.
  if (leaveOut) return [PhrasePiece(cleaned, leaveOut: true)];
  return [for (final word in cleaned.split(' ')) WordPiece(word, leaveOut: false)];
}

/// Splits what the user typed into comma groups, each a list of things to
/// look for and things to leave out. Commas inside quotes are part of the
/// phrase. A plus means the same as a space. A minus, a plus or a quote with
/// nothing to go with it is ignored rather than emptying the list.
List<CatalogSearchGroup> readCatalogSearch(String text) {
  final groups = <CatalogSearchGroup>[];
  for (final raw in _splitOutsideQuotes(_closeOpenQuote(text), (ch) => ch == ',')) {
    final wanted = <SearchPiece>[];
    final unwanted = <SearchPiece>[];
    for (final piece in _splitOutsideQuotes(raw, _pieceBreak.hasMatch)) {
      for (final part in _readPiece(piece.trim())) {
        (part.leaveOut ? unwanted : wanted).add(part);
      }
    }
    if (wanted.isNotEmpty || unwanted.isNotEmpty) {
      groups.add(CatalogSearchGroup(wanted: wanted, unwanted: unwanted));
    }
  }
  return groups;
}

// --- Scoring a whole search ---

/// How well a mod answers one piece of a group, or below zero.
int _scorePiece(CatalogMod mod, CatalogSearchFacts facts, SearchPiece piece) {
  return switch (piece) {
    // A yes-or-no question lets a mod in or keeps it out, and says nothing
    // about how well it answers the words.
    FlagPiece(:final test) => test(mod) ? 0 : -1,
    FieldPiece(:final field, :final value) =>
      field(mod, facts).any((v) => normalizeSearchText(v).contains(value))
          ? _fieldScore
          : -1,
    // Nothing loose is tried for a word to leave out: a guess must never take
    // a mod off the list.
    WordPiece(:final value) => _scoreWord(
      facts,
      value,
      loose: !piece.leaveOut,
    ),
    PhrasePiece(:final value) => _scoreWord(facts, value, loose: false),
  };
}

/// The bonus a group earns for naming the mod: most when its words are the
/// mod's whole name (or a nickname), less when a name starts with them, less
/// again when they sit in order somewhere inside it.
int _nameBonus(CatalogSearchFacts facts, CatalogSearchGroup group) {
  final typed = [
    for (final piece in group.wanted)
      if (piece is WordPiece) piece.value,
  ];
  if (typed.isEmpty) return 0;
  final joined = typed.join(' ');
  final squashed = _squash(joined);
  var bonus = 0;
  for (final name in facts.names) {
    if (name == joined || _squash(name) == squashed) return 60;
    if (name.startsWith(joined)) {
      bonus = max(bonus, 40);
    } else if (name.contains(joined)) {
      bonus = max(bonus, 30);
    }
  }
  return bonus;
}

/// A typed search, read once and then put to each mod.
///
/// Commas mean any of these: where several groups let a mod in, the best one
/// speaks for it. Within a group every word has to match and their scores are
/// added. A word with a minus in front narrows its own group; a group made
/// only of minus words takes mods out of the whole list. Typing only minus
/// words starts from every mod.
class CatalogSearchQuery {
  final List<CatalogSearchGroup> groups;

  /// Whether the AI sentence is searched. Off while AI summaries can't be
  /// shown.
  final bool searchAiText;

  final List<CatalogSearchGroup> _looking;
  final List<CatalogSearchGroup> _leaving;

  CatalogSearchQuery._(this.groups, this.searchAiText)
    : _looking = [
        for (final g in groups)
          if (g.wanted.isNotEmpty) g,
      ],
      _leaving = [
        for (final g in groups)
          if (g.wanted.isEmpty) g,
      ];

  factory CatalogSearchQuery(String text, {required bool searchAiText}) =>
      CatalogSearchQuery._(readCatalogSearch(text), searchAiText);

  /// True when there is nothing to look for, and every mod answers.
  bool get isEmpty => groups.isEmpty;

  /// True when at least one group looks for something, rather than only
  /// leaving mods out.
  bool get hasWanted => _looking.isNotEmpty;

  /// How well [mod] answers, or below zero when it should not be listed.
  int score(CatalogMod mod) {
    if (isEmpty) return 0;
    final facts = _factsOf(mod, searchAiText);
    bool leftOutBy(CatalogSearchGroup group) =>
        group.unwanted.any((piece) => _scorePiece(mod, facts, piece) >= 0);

    for (final group in _leaving) {
      if (leftOutBy(group)) return -1;
    }
    if (_looking.isEmpty) return 0;

    var best = -1;
    for (final group in _looking) {
      if (leftOutBy(group)) continue;
      var total = 0;
      for (final piece in group.wanted) {
        final pieceScore = _scorePiece(mod, facts, piece);
        if (pieceScore < 0) {
          total = -1;
          break;
        }
        total += pieceScore;
      }
      if (total < 0) continue;
      total += _nameBonus(facts, group);
      if (total > best) best = total;
    }
    return best;
  }
}

/// The mods that matched a search, best first, and each one's score.
class CatalogSearchResult {
  final List<CatalogMod> mods;

  /// Each listed mod's score. Empty when nothing was searched for.
  final Map<CatalogMod, int> scores;

  const CatalogSearchResult({required this.mods, required this.scores});
}

/// The mods that answer a search, best first. Ties go by name, then catalog
/// id, so the order never changes between two runs of the same search. With
/// nothing to look for, the mods come back in the order given, for the caller
/// to sort. The list passed in is never changed.
CatalogSearchResult searchCatalogMods(
  List<CatalogMod> mods,
  String text, {
  required bool searchAiText,
}) {
  final query = CatalogSearchQuery(text, searchAiText: searchAiText);
  if (query.isEmpty) return CatalogSearchResult(mods: [...mods], scores: {});

  final scores = Map<CatalogMod, int>.identity();
  for (final mod in mods) {
    final score = query.score(mod);
    if (score >= 0) scores[mod] = score;
  }
  final found = scores.keys.toList()
    ..sort((a, b) => compareBestMatch(a, b, scores[a]!, scores[b]!));
  return CatalogSearchResult(mods: found, scores: scores);
}
