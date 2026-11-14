import 'package:collection/collection.dart';
import 'package:dart_mappable/dart_mappable.dart';
import 'package:trios/catalog/models/catalog_extras.dart';
import 'package:trios/utils/log_collapser.dart';

part 'forum_llm_data.mapper.dart';

/// Decodes the `llm` block defensively: a malformed block costs that topic
/// its LLM data (null) instead of failing the whole bundle parse.
class ForumLlmDataHook extends MappingHook {
  const ForumLlmDataHook();

  /// Blocks dropped so far in the bundle being decoded.
  static LogCollapser _dropped = LogCollapser();

  /// Logs everything dropped during one bundle parse as a single line, then
  /// starts counting again. The forum data manager calls this once the bundle
  /// is decoded.
  ///
  /// One line per bundle rather than one per topic: the bundle holds thousands
  /// of entries, and a change to the scraper's output breaks all of them at
  /// once.
  static void flushDroppedBlocks() {
    _dropped.flush(
      'Forum bundle llm blocks',
      noun: 'dropped block',
      asInfo: true,
    );
    _dropped = LogCollapser();
  }

  @override
  ForumLlmData? beforeDecode(dynamic value) {
    if (value == null) return null;
    if (value is ForumLlmData) return value;
    try {
      return ForumLlmDataMapper.fromMap(
        Map<String, dynamic>.from(value as Map),
      );
    } catch (ex) {
      // Don't stay silent: a dropped block means the mod shows up in the
      // catalog with no summary, no downloads, and no changelog.
      _dropped.add('$ex');
      return null;
    }
  }
}

/// The scraper writes a parent mod as one name, and sometimes as several
/// joined by commas ("GraphicsLib, MagicLib"). Accept a string or a list.
class RequiredModsHook extends MappingHook {
  const RequiredModsHook();

  @override
  dynamic beforeDecode(dynamic value) {
    if (value is String) {
      return value
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return value;
  }
}

/// Turns a mod written in the old answer format into the new one before it is
/// decoded, so files published before the scraper switched still read.
class OldLlmFormatHook extends MappingHook {
  const OldLlmFormatHook();

  @override
  dynamic beforeDecode(dynamic value) {
    if (value is Map && value is! Map<String, dynamic>) {
      value = Map<String, dynamic>.from(value);
    }
    if (value is Map<String, dynamic>) return forumLlmModToNewFormat(value);
    return value;
  }
}

/// Keys only the old answer format has.
const Set<String> _oldOnlyKeys = {
  'extras',
  'requires',
  'image',
  'isTool',
  'descriptionAnchors',
};

/// True when [mod] is in the old answer format: it has a key only the old
/// format has, or a download that names its type `kind`.
bool isOldFormatLlmMod(Map<String, dynamic> mod) {
  if (mod.keys.any(_oldOnlyKeys.contains)) return true;
  final downloads = mod['downloads'];
  if (downloads is List) {
    for (final d in downloads) {
      if (d is Map && d.containsKey('kind') && !d.containsKey('type')) {
        return true;
      }
    }
  }
  return false;
}

/// One mod in the new answer format, from one in the old. A mod already in
/// the new format is returned unchanged. Only the fields TriOS reads are
/// carried over.
///
/// | Old | New |
/// |---|---|
/// | `requires` | `parentMod` |
/// | `isTool` | `types` |
/// | `image` | `imageUrl` |
/// | `downloads[].kind` | `type` |
/// | `extras.version`, `extras.changelog` (`link`) | `release.version`, `release.changelog` (`url`) |
/// | `saveCompatibility`, `canAdd` | `saveCompat.adding.quote`, `.answer` |
/// | `removalCompatibility`, `canRemove` | `saveCompat.removing.quote`, `.answer` |
/// | `updateNotes` | `saveCompat.updateNotes` |
/// | `needs`, `optionalNeeds` | `requirements.required`, `.optional` |
/// | `aiUse.uses[].optional` | `isOptional` |
/// | `sourceCode`, `license` | `sourceCode.url`, `.license` |
/// | `summary` | `description.summary` |
Map<String, dynamic> forumLlmModToNewFormat(Map<String, dynamic> mod) {
  if (!isOldFormatLlmMod(mod)) return mod;
  final extras = _asMap(mod['extras']) ?? const <String, dynamic>{};
  final out = <String, dynamic>{};

  _put(out, 'name', mod['name']);
  _put(out, 'role', mod['role']);
  _put(out, 'parentMod', mod['requires']);
  if (mod['isTool'] case final bool isTool) {
    out['types'] = isTool ? ['tool'] : ['mod'];
  }
  if (mod['downloads'] case final List downloads) {
    out['downloads'] = [
      for (final d in downloads)
        if (d is Map) _renamed(d, 'kind', 'type'),
    ];
  }
  _put(out, 'nicknames', mod['nicknames']);
  _put(out, 'imageUrl', mod['image']);

  final release = <String, dynamic>{};
  _put(release, 'version', extras['version']);
  if (_asMap(extras['changelog']) case final changelog?) {
    release['changelog'] = _renamed(changelog, 'link', 'url');
  }
  _putObject(out, 'release', release);

  final saveCompat = <String, dynamic>{};
  if (extras['saveCompatibility'] != null) {
    saveCompat['adding'] = <String, dynamic>{
      'quote': extras['saveCompatibility'],
      'answer': ?extras['canAdd'],
    };
  }
  if (extras['removalCompatibility'] != null) {
    saveCompat['removing'] = <String, dynamic>{
      'quote': extras['removalCompatibility'],
      'answer': ?extras['canRemove'],
    };
  }
  _put(saveCompat, 'updateNotes', extras['updateNotes']);
  _putObject(out, 'saveCompat', saveCompat);

  final requirements = <String, dynamic>{};
  _put(requirements, 'required', extras['needs']);
  _put(requirements, 'optional', extras['optionalNeeds']);
  _putObject(out, 'requirements', requirements);

  _put(out, 'conflicts', extras['conflicts']);
  if (_asMap(extras['aiUse']) case final aiUse?) {
    out['aiUse'] = aiUseToNewFormat(aiUse);
  }

  final sourceCode = <String, dynamic>{};
  _put(sourceCode, 'url', extras['sourceCode']);
  _put(sourceCode, 'license', extras['license']);
  _putObject(out, 'sourceCode', sourceCode);

  _put(out, 'supportLinks', extras['supportLinks']);
  if (extras['summary'] != null) {
    out['description'] = <String, dynamic>{'summary': extras['summary']};
  }
  return out;
}

Map<String, dynamic>? _asMap(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : null;

/// [map] with [from] renamed to [to], unless it already has [to].
Map<String, dynamic> _renamed(Map map, String from, String to) {
  final out = Map<String, dynamic>.from(map);
  if (out.containsKey(from) && !out.containsKey(to)) {
    out[to] = out.remove(from);
  }
  return out;
}

void _put(Map<String, dynamic> map, String key, Object? value) {
  if (value != null) map[key] = value;
}

void _putObject(
  Map<String, dynamic> map,
  String key,
  Map<String, dynamic> value,
) {
  if (value.isNotEmpty) map[key] = value;
}

/// The role of a mod within a forum topic. Ordered by priority.
@MappableEnum(defaultValue: LlmModRole.unknown)
enum LlmModRole { main, addon, separate, unknown }

/// How a download link works. Ordered by priority: `trios` links are
/// "Install With TriOS" deep links, `direct` links point at the mod archive,
/// `mirror` links are alternate hosts.
@MappableEnum(defaultValue: LlmDownloadType.unknown)
enum LlmDownloadType { trios, direct, mirror, unknown }

/// The scraper's confidence that a download link is what it claims to be.
/// Ordered by priority.
@MappableEnum(defaultValue: LlmDownloadConfidence.unknown)
enum LlmDownloadConfidence { high, medium, low, unknown }

/// The LLM-extracted `llm` block on a forum index entry.
@MappableClass()
class ForumLlmData with ForumLlmDataMappable {
  final List<ForumLlmMod> mods;

  ForumLlmData({this.mods = const []});

  /// The topic's primary mod: the first `main`-role entry, else the first
  /// mod. Null when the topic has no mods.
  ForumLlmMod? get mainMod =>
      mods.firstWhereOrNull((m) => m.role == LlmModRole.main) ??
      mods.firstOrNull;
}

/// A single mod described within a forum topic (a topic can contain several).
///
/// Read in the scraper's nested answer format. Mods in the old format are
/// converted first by [OldLlmFormatHook].
@MappableClass(hook: OldLlmFormatHook())
class ForumLlmMod with ForumLlmModMappable {
  final String name;
  final LlmModRole role;

  /// For an add-on: the mod on the same thread it needs.
  @MappableField(key: 'parentMod', hook: RequiredModsHook())
  final List<String>? parentMods;

  /// `mod`, `tool` or both. Null when the post hasn't been read for it.
  final List<String>? types;

  final List<ForumLlmDownload> downloads;

  /// Other names people use for the mod, found in the post (e.g. "SSP").
  final List<String>? nicknames;

  /// A preview image for the mod, as found in the forum post. Stored with a
  /// source prefix, e.g. `ext:https://example.com/logo.png` for an external
  /// URL. Use [imageUrl] to get a usable link.
  @MappableField(key: 'imageUrl')
  final String? image;

  /// The mod's version and changelog.
  final ForumLlmRelease? release;

  /// What the post says about adding, removing and updating the mod in a
  /// game in progress.
  final ForumLlmSaveCompat? saveCompat;

  /// Mods this mod needs or works with.
  final ForumLlmRequirements? requirements;

  /// Mods the author says conflict with this mod.
  final List<ForumLlmConflict>? conflicts;

  /// What the author says about using AI tools to make the mod.
  final CatalogAiUse? aiUse;

  /// Where the mod's code lives, and its license.
  final ForumLlmSourceCode? sourceCode;

  final List<ForumLlmSupportLink>? supportLinks;

  /// Holds the AI-written summary.
  final ForumLlmDescription? description;

  ForumLlmMod({
    required this.name,
    this.role = LlmModRole.unknown,
    this.parentMods,
    this.types,
    this.downloads = const [],
    this.nicknames,
    this.image,
    this.release,
    this.saveCompat,
    this.requirements,
    this.conflicts,
    this.aiUse,
    this.sourceCode,
    this.supportLinks,
    this.description,
  });

  /// True when the mod is a tool rather than a game mod. Null when the post
  /// hasn't been read for it.
  bool? get isTool => types?.contains('tool');

  /// The AI-written summary.
  ForumLlmSummary? get summary => description?.summary;

  /// The mod's preview image as a plain http(s) URL, or null if there isn't a
  /// usable one. Strips the `ext:` source prefix used in the raw data.
  String? get imageUrl {
    final raw = image?.trim();
    if (raw == null || raw.isEmpty) return null;
    final withoutPrefix = raw.startsWith('ext:') ? raw.substring(4) : raw;
    if (withoutPrefix.startsWith('http://') ||
        withoutPrefix.startsWith('https://')) {
      return withoutPrefix;
    }
    return null;
  }
}

/// A structured download link extracted from a forum post.
@MappableClass()
class ForumLlmDownload with ForumLlmDownloadMappable {
  final String url;
  final String label;
  final LlmDownloadType type;
  final LlmDownloadConfidence confidence;

  /// True when the link can't be downloaded directly (e.g. a page where the
  /// user must click through themselves).
  final bool requiresManualStep;
  final String? sourceHost;

  /// A pre-resolved direct-download form of [url] (e.g. Dropbox `?dl=1`).
  final String? resolvedDirectUrl;
  final String? fileName;

  ForumLlmDownload({
    required this.url,
    this.label = '',
    this.type = LlmDownloadType.unknown,
    this.confidence = LlmDownloadConfidence.unknown,
    this.requiresManualStep = false,
    this.sourceHost,
    this.resolvedDirectUrl,
    this.fileName,
  });
}

/// A mod the author says conflicts with this mod, with a quote from the author.
@MappableClass()
class ForumLlmConflict with ForumLlmConflictMappable {
  final String name;
  final String quote;

  ForumLlmConflict({required this.name, required this.quote});
}

/// The mod's own current version and its changelog.
@MappableClass()
class ForumLlmRelease with ForumLlmReleaseMappable {
  final String? version;
  final ForumLlmChangelog? changelog;

  ForumLlmRelease({this.version, this.changelog});
}

/// What the post says about saves.
@MappableClass()
class ForumLlmSaveCompat with ForumLlmSaveCompatMappable {
  /// Whether the mod can be added to a game in progress.
  final CatalogSaveStatement? adding;

  /// Whether the mod can be removed from a game in progress.
  final CatalogSaveStatement? removing;

  /// What the post says about updating from older versions, one note per
  /// release.
  final List<ForumLlmUpdateNote>? updateNotes;

  ForumLlmSaveCompat({this.adding, this.removing, this.updateNotes});
}

/// The mods this mod needs, by name, as the post writes them.
@MappableClass()
class ForumLlmRequirements with ForumLlmRequirementsMappable {
  /// Mods it won't run without, e.g. "LazyLib".
  final List<String>? required;

  /// Mods it works with but doesn't require.
  final List<String>? optional;

  ForumLlmRequirements({this.required, this.optional});
}

/// Where the mod's code lives and its license, as the post states them.
@MappableClass()
class ForumLlmSourceCode with ForumLlmSourceCodeMappable {
  /// Usually a GitHub link. Use [safeUrl] to get one that's safe to open.
  final String? url;
  final String? license;

  ForumLlmSourceCode({this.url, this.license});

  /// [url] as a plain http(s) link, or null when it isn't one. An AI reading
  /// forum posts writes this field and the app hands it to the browser, so
  /// it's checked rather than trusted.
  String? get safeUrl {
    final raw = url?.trim();
    if (raw == null) return null;
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
    return null;
  }
}

/// The mod's description. TriOS reads only the AI-written [summary].
@MappableClass()
class ForumLlmDescription with ForumLlmDescriptionMappable {
  final ForumLlmSummary? summary;

  ForumLlmDescription({this.summary});
}

/// What a post says about updating a mod: whether a game using an older
/// version survives moving to a newer one.
@MappableClass()
class ForumLlmUpdateNote with ForumLlmUpdateNoteMappable {
  /// The release the note is about. Null when it isn't tied to one release.
  final String? version;

  /// The post's own words.
  final String quote;

  /// "yes", "no" or "depends", read from [quote].
  final String? answer;

  ForumLlmUpdateNote({this.version, required this.quote, this.answer});
}

/// An AI-written summary of a mod, in two lengths.
@MappableClass()
class ForumLlmSummary with ForumLlmSummaryMappable {
  final String sentence;

  /// A handful of bundle entries only have the one-sentence version.
  final String? paragraph;

  ForumLlmSummary({required this.sentence, this.paragraph});
}

/// A mod's changelog: version-to-changes entries and/or a link to an
/// external changelog.
@MappableClass()
class ForumLlmChangelog with ForumLlmChangelogMappable {
  final Map<String, String>? entries;
  final String? url;

  ForumLlmChangelog({this.entries, this.url});
}

/// A donation/support link (e.g. Patreon, Ko-fi).
@MappableClass()
class ForumLlmSupportLink with ForumLlmSupportLinkMappable {
  final String url;

  /// One of: patreon, kofi, paypal, boosty, other.
  final String type;

  ForumLlmSupportLink({required this.url, this.type = 'other'});
}
