import 'package:material_ui/material_ui.dart';
import 'package:trios/catalog/details_dialog/details_panel_section.dart';
import 'package:trios/catalog/models/catalog_extras.dart';
import 'package:trios/catalog/models/catalog_mod.dart';
import 'package:trios/catalog/models/mod_image_source.dart';
import 'package:trios/catalog/catalog_mod_card.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/trios/constants_theme.dart';
import 'package:trios/widgets/moving_tooltip.dart';
import 'package:trios/widgets/text_trios.dart';

/// The pictures that could stand for [mod], best first: the card's picture,
/// then the gallery's logos and banners, then the gallery pictures the AI
/// thought would make a good card picture.
///
/// More than one, because forum and Discord picture links often stop working.
List<ModImageSource> modPictureSources(CatalogMod mod) {
  final gallery = [
    for (final picture
        in mod.extras?.gallery ?? const <CatalogGalleryPicture>[])
      if (!picture.aiUnreadable) picture,
  ];
  final urls = <String>{
    for (final picture in gallery)
      if (picture.aiKind == CatalogPictureKind.logo ||
          picture.aiKind == CatalogPictureKind.banner)
        picture.url,
    for (final picture in gallery)
      if (picture.aiFit == CatalogPictureFit.good) picture.url,
  };
  return [?mod.catalogImage, for (final url in urls) ?ModImageSource.web(url)];
}

/// A mod's picture in a rounded box of [size]. Tries each of
/// [modPictureSources] in turn, and shows a plain icon when none loads.
class ModPicture extends StatelessWidget {
  final CatalogMod mod;
  final double size;

  const ModPicture({super.key, required this.mod, required this.size});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(TriOSThemeConstants.cornerRadius),
      child: SizedBox(
        width: size,
        height: size,
        child: _PictureFromSources(
          sources: modPictureSources(mod),
          cacheSize: (size * 2).round(),
          placeholder: Icon(
            Icons.extension,
            size: size / 2,
            color: theme.disabledColor,
          ),
        ),
      ),
    );
  }
}

class _PictureFromSources extends StatelessWidget {
  final List<ModImageSource> sources;
  final int cacheSize;
  final Widget placeholder;

  const _PictureFromSources({
    required this.sources,
    required this.cacheSize,
    required this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    if (sources.isEmpty) return Center(child: placeholder);
    final provider = switch (sources.first) {
      WebModImage(:final url) => NetworkImage(url),
      FileModImage(:final file) => FileImage(file) as ImageProvider,
    };
    return Image(
      image: ResizeImage(provider, width: cacheSize, policy: .fit),
      fit: BoxFit.contain,
      // A broken link moves on to the next picture.
      errorBuilder: (_, _, _) => _PictureFromSources(
        sources: sources.sublist(1),
        cacheSize: cacheSize,
        placeholder: placeholder,
      ),
    );
  }
}

/// The top of the details dialog: picture, name, summary, authors, tags, and
/// the dialog's buttons.
class DetailsHeader extends StatelessWidget {
  final CatalogMod mod;

  /// The short summary, shown under the name. Hidden when null.
  final String? summary;

  /// True when [summary] is the AI sentence. It gets the same sparkle as on
  /// the catalog card.
  final bool summaryIsAi;

  /// Goes back to the mod shown before a link was followed. Hidden when null.
  final VoidCallback? onBack;

  /// The Previous / Next pair from the dialog's pager.
  final Widget pagerControls;

  /// Hidden when null.
  final VoidCallback? onOpenInEmbeddedBrowser;

  /// Hidden when null.
  final VoidCallback? onOpenInSystemBrowser;
  final VoidCallback onToggleFullScreen;
  final bool isFullScreen;
  final VoidCallback onClose;

  /// Opens the Add-ons tab. Called by the "From the forum thread" line.
  final VoidCallback? onShowThreadMods;

  const DetailsHeader({
    super.key,
    required this.mod,
    required this.pagerControls,
    required this.onToggleFullScreen,
    required this.isFullScreen,
    required this.onClose,
    this.summary,
    this.summaryIsAi = false,
    this.onBack,
    this.onOpenInEmbeddedBrowser,
    this.onOpenInSystemBrowser,
    this.onShowThreadMods,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = mod.extras?.displayName ?? mod.title;
    final version = mod.entry.modVersion?.trim();
    final mutedStyle = theme.textTheme.bodySmall?.copyWith(
      color: detailsMutedColor(theme),
    );
    final threadTitle = mod.partOfThreadTitle;

    return Padding(
      padding: const .fromLTRB(16, 16, 8, 16),
      child: Row(
        crossAxisAlignment: .start,
        spacing: 16,
        children: [
          if (onBack != null)
            MovingTooltipWidget.text(
              message: 'Back',
              child: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: onBack,
              ),
            ),
          ModPicture(mod: mod, size: 88),
          Expanded(
            child: Column(
              crossAxisAlignment: .start,
              mainAxisSize: .min,
              spacing: 8,
              children: [
                TextTriOS(
                  name.isNotEmpty ? name : '???',
                  maxLines: 1,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (summary != null)
                  _Summary(text: summary!, isAi: summaryIsAi),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (mod.authors.trim().isNotEmpty)
                      Text('by ${mod.authors}', style: mutedStyle),
                    if (version != null && version.isNotEmpty)
                      CatalogBadge(label: version, tooltip: 'Mod version'),
                    if (mod.isWip)
                      const CatalogBadge(
                        label: 'WIP',
                        tooltip: 'Work in progress',
                      ),
                    if (mod.isTool)
                      const CatalogBadge(
                        label: 'Tool',
                        tooltip: 'Tool: anything that runs outside the game',
                      ),
                  ],
                ),
                if (threadTitle != null)
                  InkWell(
                    onTap: onShowThreadMods,
                    borderRadius: BorderRadius.circular(4),
                    child: Row(
                      mainAxisSize: .min,
                      spacing: 4,
                      children: [
                        Icon(Icons.layers, size: 14, color: mutedStyle?.color),
                        Flexible(
                          child: Text(
                            'From the forum thread $threadTitle',
                            style: mutedStyle?.copyWith(
                              fontStyle: FontStyle.italic,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Row(
            mainAxisSize: .min,
            children: [
              pagerControls,
              if (onOpenInEmbeddedBrowser != null)
                MovingTooltipWidget.text(
                  message: 'Open in the built-in browser',
                  child: IconButton(
                    icon: const Icon(Icons.web),
                    onPressed: onOpenInEmbeddedBrowser,
                  ),
                ),
              if (onOpenInSystemBrowser != null)
                MovingTooltipWidget.text(
                  message: 'Open in your web browser',
                  child: IconButton(
                    icon: const Icon(Icons.open_in_new),
                    onPressed: onOpenInSystemBrowser,
                  ),
                ),
              MovingTooltipWidget.text(
                message: isFullScreen ? 'Exit full screen' : 'Full screen',
                child: IconButton(
                  icon: Icon(
                    isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
                  ),
                  onPressed: onToggleFullScreen,
                ),
              ),
              MovingTooltipWidget.text(
                message: 'Close',
                child: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: onClose,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The summary under the mod's name. AI text starts with a sparkle and says
/// who wrote it on hover.
class _Summary extends StatelessWidget {
  final String text;
  final bool isAi;

  const _Summary({required this.text, required this.isAi});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
    );
    if (!isAi) return TextTriOS(text, maxLines: 3, style: style);

    return MovingTooltipWidget.text(
      message:
          '$text\n\nSummary generated by AI. See the ${Constants.appName} '
          'About page for AI Disclosure.',
      child: Text.rich(
        TextSpan(
          children: [
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Padding(
                padding: const .only(right: 6),
                child: Icon(Icons.auto_awesome, size: 14, color: style?.color),
              ),
            ),
            TextSpan(text: text),
          ],
        ),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: style,
      ),
    );
  }
}
