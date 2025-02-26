import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/portraits/portraits_loader.dart';
import 'package:trios/thirdparty/flutter_context_menu/flutter_context_menu.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/widgets/moving_tooltip.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../utils/logging.dart';

// Define the state for the list of images
class ImageListState extends StateNotifier<Map<ModVariant, List<Portrait>>> {
  ImageListState() : super({});

  void setImageList(Map<ModVariant, List<Portrait>> images) {
    state = images;
  }

  void addImages(Map<ModVariant, List<Portrait>> images) {
    if (images.isNotEmpty) {
      final existingHashes = state.values.expand(
        (element) => element.map((e) => e.hash),
      );
      images = images.map(
        (key, value) => MapEntry(
          key,
          value
              .where((element) => !existingHashes.contains(element.hash))
              .toList(),
        ),
      );

      state = state..addAll(images);
    }
  }
}

// Create a provider for the ImageListState
final imageListProvider =
    StateNotifierProvider<ImageListState, Map<ModVariant, List<Portrait>>>((
      ref,
    ) {
      return ImageListState();
    });

class ImageGridScreen extends ConsumerStatefulWidget {
  const ImageGridScreen({super.key});

  @override
  ConsumerState<ImageGridScreen> createState() => _ImageGridScreenState();
}

class _ImageGridScreenState extends ConsumerState<ImageGridScreen>
    with AutomaticKeepAliveClientMixin<ImageGridScreen> {
  @override
  bool get wantKeepAlive => true;
  bool isLoading = false;

  void _loadImages(List<ModVariant> modVariants) async {
    if (isLoading) return;
    setState(() {
      isLoading = true;
    });
    final images = (await scanModFoldersForSquareImages(modVariants));
    ref.read(imageListProvider.notifier).addImages(images);
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    // ref.listen(AppState.modVariants, (prev, after) {
    //   final modsAdded = (after.valueOrNull ?? []) - (prev?.valueOrNull ?? []);
    //   _loadImages(modsAdded);
    // });

    final images = ref.watch(imageListProvider);
    final List<({Portrait image, ModVariant variant})> modsAndImages =
        images.entries
            .expand(
              (element) =>
                  element.value.map((e) => (variant: element.key, image: e)),
            )
            .toList();

    final sortedImages = sortModsAndImages(
      modsAndImages,
      r'graphics\\.*portraits\\',
    );
    final theme = Theme.of(context);

    return isLoading
        ? const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              Padding(
                padding: EdgeInsets.all(16),
                child: Text('Loading images...'),
              ),
            ],
          ),
        )
        : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              margin: const EdgeInsets.all(0),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        ref.read(imageListProvider.notifier).setImageList({});
                        _loadImages(
                          ref.read(AppState.modVariants).valueOrNull ?? [],
                        );
                      },
                      style: ButtonStyle(
                        foregroundColor: WidgetStateProperty.all(
                          theme.colorScheme.onSurface,
                        ),
                      ),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reload'),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        'Showing ${sortedImages.length} images',
                        style: theme.textTheme.labelLarge,
                      ),
                    ),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Text(
                        'Currently just a portrait viewer. Will allow portrait replacement in the future.',
                        style: theme.textTheme.labelLarge,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(child: ResponsiveImageGrid(modsAndImages: sortedImages)),
          ],
        );
  }

  List<({Portrait image, ModVariant variant})> sortModsAndImages(
    List<({Portrait image, ModVariant variant})> modsAndImages,
    String regexPattern,
  ) {
    final regex = RegExp(regexPattern);

    return modsAndImages..sort((a, b) {
      final aMatches = regex.hasMatch(a.image.imageFile.path);
      final bMatches = regex.hasMatch(b.image.imageFile.path);

      if (aMatches && !bMatches) return -1;
      if (!aMatches && bMatches) return 1;

      final variantComparison = a.variant.modInfo.nameOrId.compareTo(
        b.variant.modInfo.nameOrId,
      );
      if (variantComparison != 0) return variantComparison;

      return a.image.imageFile.path.compareTo(b.image.imageFile.path);
    });
  }
}

class ResponsiveImageGrid extends ConsumerWidget {
  final List<({Portrait image, ModVariant variant})> modsAndImages;

  const ResponsiveImageGrid({super.key, required this.modsAndImages});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modsPath =
        ref.watch(AppState.modsFolder).valueOrNull ?? Directory("");

    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = (constraints.maxWidth ~/ 150).clamp(1, 100);
        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: modsAndImages.length,
          itemBuilder: (context, index) {
            final mod = modsAndImages[index].variant;
            final portrait = modsAndImages[index].image;
            String bytesAsReadableKB = "unknown";
            try {
              bytesAsReadableKB =
                  portrait.imageFile.lengthSync().bytesAsReadableKB();
            } catch (error) {
              Fimber.w('Error reading file size: $error');
            }
            return MovingTooltipWidget.framed(
              tooltipWidget: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(mod.modInfo.nameOrId),
                  Text(portrait.imageFile.path.toFile().relativeTo(modsPath)),
                  Text(bytesAsReadableKB),
                  Text('${portrait.width} x ${portrait.height}'),
                ],
              ),
              child: ContextMenuRegion(
                contextMenu: ContextMenu(
                  entries: <ContextMenuEntry>[
                    MenuItem(
                      label: 'Open',
                      icon: Icons.open_in_new,
                      onSelected: () {
                        launchUrlString(portrait.imageFile.path);
                      },
                    ),
                    MenuItem(
                      label: "Open Folder",
                      icon: Icons.folder_open,
                      onSelected: () {
                        launchUrlString(portrait.imageFile.parent.path);
                      },
                    ),
                  ],
                ),
                child: SizedBox(
                  width: 128,
                  height: 128,
                  child: Image.file(portrait.imageFile),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
