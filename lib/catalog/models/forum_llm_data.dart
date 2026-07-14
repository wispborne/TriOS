import 'package:collection/collection.dart';
import 'package:dart_mappable/dart_mappable.dart';

part 'forum_llm_data.mapper.dart';

/// Decodes the `llm` block defensively: a malformed block costs that topic
/// its LLM data (null) instead of failing the whole bundle parse.
class ForumLlmDataHook extends MappingHook {
  const ForumLlmDataHook();

  @override
  ForumLlmData? beforeDecode(dynamic value) {
    if (value == null) return null;
    if (value is ForumLlmData) return value;
    try {
      return ForumLlmDataMapper.fromMap(
        Map<String, dynamic>.from(value as Map),
      );
    } catch (_) {
      return null;
    }
  }
}

/// The role of a mod within a forum topic. Ordered by priority.
@MappableEnum(defaultValue: LlmModRole.unknown)
enum LlmModRole { main, addon, separate, unknown }

/// How a download link works. Ordered by priority: `trios` links are
/// "Install With TriOS" deep links, `direct` links point at the mod archive,
/// `mirror` links are alternate hosts.
@MappableEnum(defaultValue: LlmDownloadKind.unknown)
enum LlmDownloadKind { trios, direct, mirror, unknown }

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
@MappableClass()
class ForumLlmMod with ForumLlmModMappable {
  final String name;
  final LlmModRole role;

  /// Names of mods this mod requires (e.g. "LazyLib").
  final List<String>? requires;
  final List<ForumLlmDownload> downloads;
  final ForumLlmExtras? extras;

  /// A preview image for the mod, as found in the forum post. Stored with a
  /// source prefix, e.g. `ext:https://example.com/logo.png` for an external
  /// URL. Use [imageUrl] to get a usable link.
  final String? image;

  ForumLlmMod({
    required this.name,
    this.role = LlmModRole.unknown,
    this.requires,
    this.downloads = const [],
    this.extras,
    this.image,
  });

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
  final LlmDownloadKind kind;
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
    this.kind = LlmDownloadKind.unknown,
    this.confidence = LlmDownloadConfidence.unknown,
    this.requiresManualStep = false,
    this.sourceHost,
    this.resolvedDirectUrl,
    this.fileName,
  });
}

/// Optional extra metadata about a mod.
@MappableClass()
class ForumLlmExtras with ForumLlmExtrasMappable {
  final String? version;
  final ForumLlmSummary? summary;
  final ForumLlmChangelog? changelog;
  final String? license;
  final List<ForumLlmSupportLink>? supportLinks;

  /// Free-form text describing whether updating the mod breaks existing saves,
  /// e.g. "Should be fully save compatible with 1.05". From QB's forum bundle.
  final String? saveCompatibility;

  ForumLlmExtras({
    this.version,
    this.summary,
    this.changelog,
    this.license,
    this.supportLinks,
    this.saveCompatibility,
  });
}

/// An AI-written summary of a mod, in two lengths.
@MappableClass()
class ForumLlmSummary with ForumLlmSummaryMappable {
  final String sentence;
  final String paragraph;

  ForumLlmSummary({required this.sentence, required this.paragraph});
}

/// A mod's changelog: version-to-changes entries and/or a link to an
/// external changelog.
@MappableClass()
class ForumLlmChangelog with ForumLlmChangelogMappable {
  final Map<String, String>? entries;
  final String? link;

  ForumLlmChangelog({this.entries, this.link});
}

/// A donation/support link (e.g. Patreon, Ko-fi).
@MappableClass()
class ForumLlmSupportLink with ForumLlmSupportLinkMappable {
  final String url;

  /// One of: patreon, kofi, paypal, boosty, other.
  final String type;

  ForumLlmSupportLink({required this.url, this.type = 'other'});
}
