import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:trios/catalog/models/ai_summary_mode.dart';
import 'package:trios/catalog/models/forum_llm_data.dart';
import 'package:trios/catalog/catalog_mod_card.dart';
import 'package:trios/catalog/widgets/mod_summary/mod_summary_data.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/widgets/moving_tooltip.dart';
import 'package:trios/widgets/svg_image_icon.dart';
import 'package:trios/widgets/text_trios.dart';
import 'package:trios/widgets/trios_expansion_tile.dart';
import 'package:url_launcher/url_launcher.dart';

/// Which fields the [ModSummaryWidget] shows, plus sizing and whether it's
/// interactive. Two presets cover the two uses: [tooltip] (passive hover card)
/// and [dialogHeader] (the info block atop a mod pop-up).
class ModSummaryConfig {
  final bool showImage;
  final bool showAuthor;
  final bool showTitle;
  final bool showCategory;
  final bool showDates;
  final bool showStats;
  final bool showSummary;
  final bool showChangelog;
  final bool showDonationLinks;
  final bool showSaveCompatibility;

  /// How many changelog entries to list, newest first.
  final int maxChangelogEntries;

  /// When false, links and buttons are inert (used in a tooltip, which can't
  /// be clicked through).
  final bool interactive;

  /// The mod image's max width/height in logical pixels.
  final double imageSize;

  const ModSummaryConfig({
    this.showImage = true,
    this.showAuthor = true,
    this.showTitle = true,
    this.showCategory = true,
    this.showDates = true,
    this.showStats = true,
    this.showSummary = true,
    this.showChangelog = true,
    this.showDonationLinks = true,
    this.showSaveCompatibility = true,
    this.maxChangelogEntries = 3,
    this.interactive = true,
    this.imageSize = 160,
  });

  /// Passive hover card: shows everything readable, no clickable links, one
  /// changelog entry, smaller image.
  static const tooltip = ModSummaryConfig(
    showDonationLinks: false,
    maxChangelogEntries: 1,
    interactive: false,
    imageSize: 120,
  );

  /// The info block at the top of a mod pop-up: everything, interactive, with
  /// more changelog entries (collapsible, so they stay compact).
  static const dialogHeader = ModSummaryConfig(maxChangelogEntries: 5);
}

/// A configurable overview of a mod: image, title, author, where and when it
/// was posted, forum stats, summary, save compatibility, recent changelog, and
/// donation links. Used as the catalog-card hover tooltip and as the header of
/// the mod pop-ups.
class ModSummaryWidget extends ConsumerWidget {
  final ModSummaryData data;
  final ModSummaryConfig config;
  final Widget? headerButtons;

  const ModSummaryWidget({
    super.key,
    required this.data,
    this.config = const ModSummaryConfig(),
    this.headerButtons,
  });

  static final _dateFormat = DateFormat.yMMMMd().add_jm();
  static final _decimalFormat = NumberFormat.decimalPattern();
  static final _compactFormat = NumberFormat.compact();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final aiMode = ref.watch(appSettings.select((s) => s.catalogAiSummaryMode));

    final summary = config.showSummary ? _resolveSummary(data, aiMode) : null;
    final saveCompat = data.saveCompatibility?.trim();
    final showSaveCompat =
        config.showSaveCompatibility && (saveCompat?.isNotEmpty ?? false);
    final showChangelog =
        config.showChangelog && _changelogHasContent(data.changelog);
    final showDonation =
        config.showDonationLinks &&
        config.interactive &&
        data.supportLinks.isNotEmpty;

    final hasContent =
        summary != null || showSaveCompat || showChangelog || showDonation;

    return Column(
      crossAxisAlignment: .start,
      mainAxisSize: .min,
      spacing: 12,
      children: [
        _HeaderRow(data: data, config: config, headerButtons: headerButtons),
        // A divider keeps the "who/when" header visually apart from the
        // "what" content below it.
        ?(hasContent ? Divider(height: 1, color: theme.dividerColor) : null),
        ?(summary != null
            ? _SummarySection(text: summary.text, isAi: summary.isAi)
            : null),
        ?(showSaveCompat ? _SaveCompatibilitySection(text: saveCompat!) : null),
        ?(showChangelog
            ? _ChangelogSection(
                changelog: data.changelog!,
                maxEntries: config.maxChangelogEntries,
                interactive: config.interactive,
              )
            : null),
        ?(showDonation
            ? _DonationLinksSection(links: data.supportLinks)
            : null),
      ],
    );
  }

  /// Picks the summary text to show and whether it's AI-written, following the
  /// user's AI-summary setting. Null when there's nothing to show.
  static ({String text, bool isAi})? _resolveSummary(
    ModSummaryData data,
    AiSummaryMode aiMode,
  ) {
    final authorText = data.authorText?.trim();
    final hasAuthorText = authorText?.isNotEmpty ?? false;
    final aiParagraph = data.aiSummary?.paragraph.trim();
    final hasAi = aiParagraph?.isNotEmpty ?? false;

    final String? shown = switch (aiMode) {
      AiSummaryMode.always => hasAi ? aiParagraph : authorText,
      AiSummaryMode.whenNoAuthorText =>
        hasAuthorText ? authorText : aiParagraph,
      AiSummaryMode.never => authorText,
    };
    if (shown == null || shown.isEmpty) return null;
    return (text: shown, isAi: shown == aiParagraph && hasAi);
  }

  static bool _changelogHasContent(ForumLlmChangelog? changelog) {
    if (changelog == null) return false;
    final hasEntries = changelog.entries?.isNotEmpty ?? false;
    final hasLink = changelog.link?.trim().isNotEmpty ?? false;
    return hasEntries || hasLink;
  }
}

/// Image on the left, then the title / author / dates / stats column.
class _HeaderRow extends StatelessWidget {
  final ModSummaryData data;
  final ModSummaryConfig config;
  final Widget? headerButtons;

  const _HeaderRow({
    required this.data,
    required this.config,
    this.headerButtons,
  });

  @override
  Widget build(BuildContext context) {
    final catalogMod = data.catalogMod;
    return Row(
      crossAxisAlignment: .start,
      spacing: 12,
      children: [
        if (config.showImage && catalogMod != null)
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: config.imageSize,
              maxHeight: config.imageSize,
            ),
            child: ModImage(
              mod: catalogMod,
              size: config.imageSize.round(),
              fallbackImageUrl: data.fallbackImageUrl,
            ),
          ),
        Expanded(
          child: _InfoColumn(
            data: data,
            config: config,
            headerButtons: headerButtons,
          ),
        ),
      ],
    );
  }
}

class _InfoColumn extends StatelessWidget {
  final ModSummaryData data;
  final ModSummaryConfig config;
  final Widget? headerButtons;

  const _InfoColumn({
    required this.data,
    required this.config,
    this.headerButtons,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mutedStyle = theme.textTheme.labelSmall?.copyWith(
      color: theme.textTheme.labelSmall?.color?.withValues(alpha: 0.6),
    );

    final postDate = data.postDate;
    final lastEdit = data.lastEditDate;
    final showLastEdit = lastEdit != null && lastEdit != postDate;

    return Column(
      crossAxisAlignment: .start,
      mainAxisSize: .min,
      spacing: 4,
      children: [
        Row(
          mainAxisAlignment: .spaceBetween,
          children: [
            if (config.showTitle)
              Expanded(
                child: TextTriOS(
                  data.title.isNotEmpty ? data.title : '???',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ?headerButtons,
          ],
        ),
        if (config.showAuthor && data.author.trim().isNotEmpty)
          _AuthorChip(data: data, interactive: config.interactive),
        if (config.showCategory && (data.category?.trim().isNotEmpty ?? false))
          Text('in ${data.category!.trim()}', style: mutedStyle),
        if (config.showDates && (postDate != null || showLastEdit))
          Text.rich(
            TextSpan(
              children: [
                if (postDate != null) ...[
                  const TextSpan(
                    text: 'Posted ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: ModSummaryWidget._dateFormat.format(postDate)),
                ],
                if (showLastEdit) ...[
                  const TextSpan(
                    text: '  •  Edited ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: ModSummaryWidget._dateFormat.format(lastEdit)),
                ],
              ],
            ),
            style: mutedStyle,
          ),
        if (config.showStats && (data.views != null || data.replies != null))
          _StatsRow(views: data.views, replies: data.replies),
      ],
    );
  }
}

/// Author avatar + name, with forum title and post count when known. Opens the
/// author's forum profile on tap when interactive.
class _AuthorChip extends StatelessWidget {
  final ModSummaryData data;
  final bool interactive;

  const _AuthorChip({required this.data, required this.interactive});

  static Uri? _authorProfileUrl(String author) {
    final name = author.trim();
    if (name.isEmpty) return null;
    return Uri.parse(
      '${Constants.forumUserProfileUrl}${Uri.encodeComponent(name)}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profileUrl = interactive ? _authorProfileUrl(data.author) : null;
    final postCount = data.authorPostCount;
    final postCountText = postCount != null
        ? '${ModSummaryWidget._decimalFormat.format(postCount)} posts'
        : null;

    final content = Padding(
      padding: const .symmetric(vertical: 6.0, horizontal: 10),
      child: Row(
        crossAxisAlignment: .center,
        mainAxisSize: .min,
        spacing: 8,
        children: [
          _Avatar(path: data.authorAvatarPath),
          Column(
            crossAxisAlignment: .start,
            mainAxisSize: .min,
            children: [
              Text(
                data.author,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              if (data.authorTitle?.isNotEmpty ?? false)
                Text(
                  data.authorTitle!,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: theme.textTheme.labelSmall?.color?.withValues(
                      alpha: 0.7,
                    ),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ],
      ),
    );

    final card = Card(
      margin: .zero,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: profileUrl == null
          ? content
          : InkWell(
              borderRadius: BorderRadius.circular(24),
              mouseCursor: SystemMouseCursors.click,
              onTap: () => launchUrl(profileUrl),
              child: content,
            ),
    );

    final message = [
      if (profileUrl != null)
        "Open ${data.author}'s forum profile in your browser",
      ?postCountText,
    ].join('\n');

    if (message.isEmpty) return card;
    return MovingTooltipWidget.text(message: message, child: card);
  }
}

class _Avatar extends StatelessWidget {
  final String? path;

  const _Avatar({required this.path});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final url = _resolveAvatarUrl(path);
    final placeholder = CircleAvatar(
      radius: 20,
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      child: Icon(Icons.person, size: 22, color: theme.disabledColor),
    );
    if (url == null) return placeholder;
    return ClipOval(
      child: Image.network(
        url,
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => placeholder,
      ),
    );
  }

  String? _resolveAvatarUrl(String? p) {
    if (p == null || p.isEmpty) return null;
    if (p.startsWith('http://') || p.startsWith('https://')) return p;
    try {
      return Uri.parse(
        'https://fractalsoftworks.com/forum/',
      ).resolve(p).toString();
    } catch (_) {
      return null;
    }
  }
}

class _StatsRow extends StatelessWidget {
  final int? views;
  final int? replies;

  const _StatsRow({required this.views, required this.replies});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.labelSmall?.copyWith(
      color: theme.textTheme.labelSmall?.color?.withValues(alpha: 0.7),
    );
    return Row(
      crossAxisAlignment: .end,
      mainAxisSize: .min,
      spacing: 8,
      children: [
        if (views != null)
          MovingTooltipWidget.text(
            message:
                '${ModSummaryWidget._decimalFormat.format(views)} '
                'forum views',
            child: Row(
              mainAxisSize: .min,
              spacing: 4,
              children: [
                Icon(Icons.visibility, size: 12, color: style?.color),
                Text(
                  ModSummaryWidget._compactFormat.format(views),
                  style: style,
                ),
              ],
            ),
          ),
        if (replies != null)
          MovingTooltipWidget.text(
            message:
                '${ModSummaryWidget._decimalFormat.format(replies)} '
                'forum replies',
            child: Row(
              mainAxisSize: .min,
              spacing: 4,
              children: [
                Icon(Icons.forum, size: 12, color: style?.color),
                Text(
                  ModSummaryWidget._compactFormat.format(replies),
                  style: style,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// The mod's summary text (author's own or AI-written). Shows the
/// AI-disclosure note when AI text is displayed.
class _SummarySection extends StatelessWidget {
  final String text;
  final bool isAi;

  const _SummarySection({required this.text, required this.isAi});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: .start,
      mainAxisSize: .min,
      spacing: 2,
      children: [
        if (isAi)
          // A sparkle marks the text as AI-written, matching the catalog card.
          Text.rich(
            TextSpan(
              children: [
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Padding(
                    padding: const .only(right: 4),
                    child: Icon(
                      Icons.auto_awesome,
                      size: 12,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                TextSpan(text: text),
              ],
            ),
            style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurface),
          )
        else
          Text(text, style: theme.textTheme.labelMedium),
        if (isAi)
          Text(
            'Summary generated by AI. See the ${Constants.appName} About page '
            'for AI Disclosure.',
            style: theme.textTheme.labelSmall?.copyWith(
              fontStyle: FontStyle.italic,
              color: theme.colorScheme.onSurface.withAlpha(150),
            ),
          ),
      ],
    );
  }
}

/// A consistent header for the content sections: a small icon and a bold
/// label. Keeps the summary, save-compatibility, changelog, and donation
/// blocks visually grouped instead of running together.
class _SectionHeader extends StatelessWidget {
  final IconData? icon;
  final String? iconAsset;
  final String label;

  const _SectionHeader({this.icon, this.iconAsset, required this.label})
    : assert(icon != null || iconAsset != null);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurface.withValues(alpha: 0.75);
    return Row(
      mainAxisSize: .min,
      spacing: 6,
      children: [
        iconAsset != null
            ? SvgImageIcon(iconAsset!, width: 14, height: 14, color: color)
            : Icon(icon, size: 14, color: color),
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _SaveCompatibilitySection extends StatelessWidget {
  final String text;

  const _SaveCompatibilitySection({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MovingTooltipWidget.text(
      message:
          'What happens to your existing saved games when you update '
          'this mod',
      child: Column(
        crossAxisAlignment: .start,
        mainAxisSize: .min,
        spacing: 4,
        children: [
          const _SectionHeader(icon: Icons.save, label: 'Save compatibility'),
          Padding(
            padding: const .only(left: 20),
            child: Text(text, style: theme.textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}

/// The "Recent updates" section: the newest changelog entries as collapsible
/// tiles (the latest one open), plus a link to the full changelog.
class _ChangelogSection extends StatelessWidget {
  final ForumLlmChangelog changelog;
  final int maxEntries;
  final bool interactive;

  const _ChangelogSection({
    required this.changelog,
    required this.maxEntries,
    required this.interactive,
  });

  /// Tidies a raw changelog body: expands `&nbsp;`, strips markdown `#`
  /// heading markers, and drops a leading header line that just repeats the
  /// version (keeping any release date it carried).
  static ({String? date, String body}) _clean(String version, String raw) {
    final lines = raw.replaceAll('&nbsp;', ' ').split('\n');
    String? date;
    if (lines.isNotEmpty) {
      final firstStripped = lines.first.replaceAll('#', '').trim();
      if (firstStripped.toLowerCase().startsWith(version.toLowerCase())) {
        date = RegExp(
          r'\(([^)]+)\)',
        ).firstMatch(firstStripped)?.group(1)?.trim();
        lines.removeAt(0);
      }
    }
    final body = lines
        .map(
          (l) => l
              .replaceAll(RegExp(r'^\s*#+\s*'), '')
              .replaceAll(RegExp(r'\s*#+\s*$'), '')
              .trimRight(),
        )
        .join('\n')
        .trim();
    return (date: date, body: body);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entries = changelog.entries;
    final link = changelog.link?.trim();
    final hasEntries = entries != null && entries.isNotEmpty;
    final hasLink = link?.isNotEmpty ?? false;

    final versionStyle =
        (interactive ? theme.textTheme.bodyMedium : theme.textTheme.labelMedium)
            ?.copyWith(fontWeight: FontWeight.bold);
    final dateStyle = theme.textTheme.labelSmall?.copyWith(
      color: theme.textTheme.labelSmall?.color?.withValues(alpha: 0.6),
    );
    final bodyStyle = theme.textTheme.bodySmall;

    final shownEntries = hasEntries
        ? entries.entries.take(maxEntries).toList()
        : const <MapEntry<String, String>>[];

    return Column(
      crossAxisAlignment: .start,
      mainAxisSize: .min,
      spacing: 4,
      children: [
        const _SectionHeader(
          iconAsset: 'assets/images/icon-bullhorn-variant.svg',
          label: 'Recent updates',
        ),
        if (hasLink && interactive)
          Padding(
            padding: const .only(left: 0),
            child: MovingTooltipWidget.text(
              message: link!,
              child: InkWell(
                child: ActionChip(
                  label: Text('Open full changelog'),
                  avatar: Icon(
                    Icons.open_in_new,
                    color: theme.colorScheme.onSurface,
                  ),
                  onPressed: () => launchUrl(Uri.parse(link)),
                  visualDensity: VisualDensity.compact,
                  color: WidgetStatePropertyAll(
                    theme.colorScheme.surfaceContainerLow,
                  ),
                ),
              ),
            ),
          ),
        for (final entry in shownEntries)
          Builder(
            builder: (context) {
              final cleaned = _clean(entry.key, entry.value);
              final titleRow = Row(
                mainAxisSize: .min,
                spacing: 8,
                children: [
                  Text(entry.key, style: versionStyle),
                  if (cleaned.date != null)
                    Text(cleaned.date!, style: dateStyle),
                ],
              );

              // In a tooltip the tile can't be expanded, so show a short,
              // flat preview instead of a collapsible tile.
              if (!interactive) {
                return Padding(
                  padding: const .only(left: 20),
                  child: Column(
                    crossAxisAlignment: .start,
                    mainAxisSize: .min,
                    spacing: 2,
                    children: [
                      titleRow,
                      Text(
                        cleaned.body,
                        style: bodyStyle,
                        maxLines: 5,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              }

              return TriOSExpansionTile(
                title: titleRow,
                initiallyExpanded: false,
                tilePadding: const .symmetric(horizontal: 12),
                childrenPadding: const .fromLTRB(12, 0, 12, 12),
                expandedCrossAxisAlignment: .start,
                children: [SelectableText(cleaned.body, style: bodyStyle)],
              );
            },
          ),
      ],
    );
  }
}

/// Donation / support links as small tappable chips, one per link.
class _DonationLinksSection extends StatelessWidget {
  final List<ForumLlmSupportLink> links;

  const _DonationLinksSection({required this.links});

  static IconData _iconFor(String type) => switch (type.toLowerCase()) {
    'patreon' => Icons.favorite,
    'kofi' => Icons.coffee,
    'paypal' => Icons.paid,
    'boosty' => Icons.rocket_launch,
    _ => Icons.volunteer_activism,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: .start,
      mainAxisSize: .min,
      spacing: 6,
      children: [
        const _SectionHeader(icon: Icons.favorite, label: 'Donation links'),
        Padding(
          padding: const .only(left: 00),
          child: Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              for (final link in links)
                MovingTooltipWidget.text(
                  message: link.url,
                  child: ActionChip(
                    avatar: Icon(
                      _iconFor(link.type),
                      size: 16,
                      color: theme.colorScheme.onSurface,
                    ),
                    label: Text(link.type.toTitleCase()),
                    color: WidgetStatePropertyAll(
                      theme.colorScheme.surfaceContainerLow,
                    ),
                    visualDensity: VisualDensity.compact,
                    onPressed: () => launchUrl(Uri.parse(link.url)),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
