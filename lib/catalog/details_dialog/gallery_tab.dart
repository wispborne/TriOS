import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/catalog/forum_post_dialog/inline_span_builder.dart';
import 'package:trios/catalog/models/catalog_mod.dart';
import 'package:trios/catalog/models/forum_mod_details.dart';
import 'package:trios/catalog/models/mod_repo_entry.dart';
import 'package:trios/trios/constants_theme.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/widgets/moving_tooltip.dart';
import 'package:trios/widgets/picture_viewer.dart';

/// One picture in the Gallery tab.
class GalleryPicture {
  final String url;
  final String? caption;
  final String? aiCaption;

  /// A badge, button, icon or other small picture. Hidden until asked for.
  final bool small;

  const GalleryPicture({
    required this.url,
    this.caption,
    this.aiCaption,
    this.small = false,
  });

  ViewerPicture toViewerPicture() =>
      ViewerPicture(url: url, caption: caption, aiCaption: aiCaption);
}

/// The mod's gallery: the extras record's pictures when it has any, else the
/// catalog's pictures followed by the forum post's, without repeats. SVG
/// pictures are left out, since they can't be drawn.
///
/// Only the extras record knows which pictures are small, so nothing is
/// marked small without it.
List<GalleryPicture> galleryPicturesFor(
  CatalogMod mod,
  ForumModDetails? forumDetails,
) {
  final gallery = mod.extras?.gallery ?? const [];
  if (gallery.isNotEmpty) {
    return [
      for (final picture in gallery)
        if (!isSvgPictureUrl(picture.url))
          GalleryPicture(
            url: picture.url,
            caption: picture.caption,
            aiCaption: picture.aiCaption,
            small: picture.small,
          ),
    ];
  }

  final urls = <String>{
    for (final image in mod.entry.images?.values ?? const <ModRepoImage>[])
      ?image.url,
    ...?forumDetails?.images,
  };
  return [
    for (final url in urls)
      if (url.isNotEmpty && !isSvgPictureUrl(url)) GalleryPicture(url: url),
  ];
}

/// The Gallery tab: a grid of the mod's pictures. Clicking one opens the
/// picture viewer.
class GalleryTab extends ConsumerStatefulWidget {
  final List<GalleryPicture> pictures;

  const GalleryTab({super.key, required this.pictures});

  @override
  ConsumerState<GalleryTab> createState() => _GalleryTabState();
}

class _GalleryTabState extends ConsumerState<GalleryTab> {
  bool _showSmall = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showAi = ref.watch(appSettings.select((s) => s.enableAiFeatures));
    final smallCount = widget.pictures.where((p) => p.small).length;
    final shown = [
      for (final picture in widget.pictures)
        if (_showSmall || !picture.small) picture,
    ];

    return Column(
      crossAxisAlignment: .start,
      spacing: 16,
      children: [
        if (shown.isEmpty)
          Text(
            "No screenshots in this mod's posts.",
            style: theme.textTheme.bodyMedium?.copyWith(
              fontStyle: FontStyle.italic,
            ),
          ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (index, picture) in shown.indexed)
              _Thumbnail(
                picture: picture,
                showAiCaption: showAi,
                onTap: () => showPictureViewer(
                  context,
                  pictures: [for (final p in shown) p.toViewerPicture()],
                  startIndex: index,
                ),
              ),
          ],
        ),
        if (smallCount > 0 && !_showSmall)
          OutlinedButton(
            onPressed: () => setState(() => _showSmall = true),
            child: Text('Show $smallCount small pictures'),
          ),
      ],
    );
  }
}

class _Thumbnail extends StatelessWidget {
  static const double _width = 200;
  static const double _height = 150;

  final GalleryPicture picture;
  final bool showAiCaption;
  final VoidCallback onTap;

  const _Thumbnail({
    required this.picture,
    required this.showAiCaption,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tooltip = [
      ?picture.caption?.trim(),
      if (showAiCaption && picture.aiCaption?.trim() != null)
        'AI description: ${picture.aiCaption!.trim()}',
    ].where((line) => line.isNotEmpty).join('\n\n');

    final image = ClipRRect(
      borderRadius: BorderRadius.circular(TriOSThemeConstants.cornerRadius),
      child: Material(
        color: theme.colorScheme.surfaceContainerHighest,
        child: InkWell(
          onTap: onTap,
          mouseCursor: SystemMouseCursors.zoomIn,
          child: SizedBox(
            width: _width,
            height: _height,
            child: Image.network(
              picture.url,
              fit: BoxFit.cover,
              cacheWidth: (_width * 2).round(),
              errorBuilder: (_, _, _) =>
                  Icon(Icons.broken_image_outlined, color: theme.disabledColor),
            ),
          ),
        ),
      ),
    );

    if (tooltip.isEmpty) return image;
    return MovingTooltipWidget.text(message: tooltip, child: image);
  }
}
