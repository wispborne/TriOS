import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/portraits/portrait_model.dart';
import 'package:trios/portraits/portrait_replacements_manager.dart';
import 'package:trios/portraits/portraits_manager.dart';
import 'package:trios/thirdparty/flutter_context_menu/flutter_context_menu.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/widgets/moving_tooltip.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../utils/logging.dart';

class ImageGridScreen extends ConsumerStatefulWidget {
  const ImageGridScreen({super.key});

  @override
  ConsumerState<ImageGridScreen> createState() => _ImageGridScreenState();
}

class _ImageGridScreenState extends ConsumerState<ImageGridScreen>
    with AutomaticKeepAliveClientMixin<ImageGridScreen> {
  @override
  bool get wantKeepAlive => true;
  final SearchController _searchController = SearchController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _refreshPortraits() {
    // Invalidate the provider to trigger a reload
    ref.invalidate(portraitsProvider);
  }

  void _showReplacementsDialog() async {
    final PortraitReplacementsManager _replacementsManager = ref.read(portraitReplacementsStateProvider.notifier);
    final replacements = await _replacementsManager.loadReplacements();

    // Get current portraits to create hash-to-portrait lookup
    final portraitsAsync = ref.read(portraitsProvider);
    final Map<String, Portrait> hashToPortrait = {};

    portraitsAsync.whenData((portraits) {
      for (final entry in portraits.entries) {
        for (final portrait in entry.value) {
          hashToPortrait[portrait.hash] = portrait;
        }
      }
    });

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => ReplacementsDialog(
        replacements: replacements,
        hashToPortrait: hashToPortrait,
      ),
    );
  }

  Future<void> _addRandomReplacement(
    Portrait originalPortrait,
    List<({Portrait image, ModVariant variant})> allPortraits,
  ) async {
    try {
      // Filter out the original portrait and get a random replacement
      final otherPortraits = allPortraits
          .where((item) => item.image.hash != originalPortrait.hash)
          .toList();

      if (otherPortraits.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No other portraits available for replacement'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      final random = Random();
      final randomPortrait =
          otherPortraits[random.nextInt(otherPortraits.length)];

      // Save the replacement
      await _replacementsManager.saveReplacement(
        originalPortrait.hash,
        randomPortrait.image.imageFile.path,
      );

      // Update the replacements provider to trigger UI refresh
      final currentReplacements = ref.read(portraitReplacementsProvider);
      ref.read(portraitReplacementsProvider.notifier).state = {
        ...currentReplacements,
        originalPortrait.hash: randomPortrait.image.imageFile.path,
      };

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Replacement added: ${originalPortrait.imageFile.path.split('\\').last} -> ${randomPortrait.image.imageFile.path.split('\\').last}',
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }

      Fimber.i(
        'Random replacement added: ${originalPortrait.hash} -> ${randomPortrait.image.imageFile.path}',
      );
    } catch (e) {
      Fimber.e('Error adding random replacement: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding replacement: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // Watch the portraits provider and loading state
    final portraitsAsync = ref.watch(portraitsProvider);
    final isLoading = ref.watch(isLoadingPortraits);
    final replacements = ref.watch(portraitReplacementsProvider);

    return portraitsAsync.when(
      loading: () => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            Padding(
              padding: EdgeInsets.all(16),
              child: Text('Loading portraits...'),
            ),
          ],
        ),
      ),
      error: (error, stackTrace) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading portraits: $error',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _refreshPortraits,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (portraits) {
        final List<({Portrait image, ModVariant variant})> modsAndImages =
            portraits.entries
                .expand(
                  (element) => element.value.map(
                    (e) => (variant: element.key, image: e),
                  ),
                )
                .toList();

        var sortedImages = sortModsAndImages(
          modsAndImages,
          r'graphics\\.*portraits\\',
        );

        // Apply search filter
        final query = _searchController.value.text;
        if (query.isNotEmpty) {
          sortedImages = sortedImages.where((item) {
            final variant = item.variant;
            final portrait = item.image;
            return variant.modInfo.nameOrId.toLowerCase().contains(
                  query.toLowerCase(),
                ) ||
                portrait.imageFile.path.toLowerCase().contains(
                  query.toLowerCase(),
                );
          }).toList();
        }

        final theme = Theme.of(context);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              margin: const EdgeInsets.all(0),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Stack(
                  children: [
                    Row(
                      children: [
                        TextButton.icon(
                          onPressed: isLoading ? null : _refreshPortraits,
                          style: ButtonStyle(
                            foregroundColor: WidgetStateProperty.all(
                              theme.colorScheme.onSurface,
                            ),
                          ),
                          icon: isLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.refresh),
                          label: const Text('Reload'),
                        ),
                        TextButton.icon(
                          onPressed: _showReplacementsDialog,
                          style: ButtonStyle(
                            foregroundColor: WidgetStateProperty.all(
                              theme.colorScheme.onSurface,
                            ),
                          ),
                          icon: const Icon(Icons.swap_horiz),
                          label: const Text('Replacements'),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Text(
                            '${sortedImages.length} images',
                            style: theme.textTheme.labelLarge,
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),
                    Center(child: buildSearchBox()),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: ResponsiveImageGrid(
                  modsAndImages: sortedImages,
                  allPortraits: modsAndImages,
                  replacements: replacements,
                  onAddRandomReplacement: _addRandomReplacement,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  SizedBox buildSearchBox() {
    return SizedBox(
      height: 30,
      width: 300,
      child: SearchAnchor(
        searchController: _searchController,
        builder: (BuildContext context, SearchController controller) {
          return SearchBar(
            controller: controller,
            leading: const Icon(Icons.search),
            hintText: "Filter...",
            trailing: [
              controller.value.text.isEmpty
                  ? Container()
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        controller.clear();
                        setState(() {});
                      },
                    ),
            ],
            backgroundColor: WidgetStateProperty.all(
              Theme.of(context).colorScheme.surfaceContainer,
            ),
            onChanged: (value) {
              setState(() {});
            },
          );
        },
        suggestionsBuilder:
            (BuildContext context, SearchController controller) {
              return [];
            },
      ),
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

class ReplacementsDialog extends StatelessWidget {
  final Map<String, String> replacements;
  final Map<String, Portrait> hashToPortrait;

  const ReplacementsDialog({
    super.key,
    required this.replacements,
    required this.hashToPortrait,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Portrait Replacements'),
      content: SizedBox(
        width: 800,
        height: 600,
        child: replacements.isEmpty
            ? const Center(child: Text('No portrait replacements found.'))
            : ListView.builder(
                itemCount: replacements.length,
                itemBuilder: (context, index) {
                  final entry = replacements.entries.elementAt(index);
                  final originalHash = entry.key;
                  final replacementPath = entry.value;

                  return ReplacementListItem(
                    originalHash: originalHash,
                    replacementPath: replacementPath,
                    originalPortrait: hashToPortrait[originalHash],
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class ReplacementListItem extends StatelessWidget {
  final String originalHash;
  final String replacementPath;
  final Portrait? originalPortrait;

  const ReplacementListItem({
    super.key,
    required this.originalHash,
    required this.replacementPath,
    this.originalPortrait,
  });

  @override
  Widget build(BuildContext context) {
    final replacementFile = File(replacementPath);
    final fileExists = replacementFile.existsSync();
    final originalExists = originalPortrait?.imageFile.existsSync() ?? false;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Original portrait
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                border: Border.all(
                  color: originalExists ? Colors.grey : Colors.red,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: originalPortrait != null && originalExists
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.file(
                        originalPortrait!.imageFile,
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(Icons.broken_image, color: Colors.red),
                          );
                        },
                      ),
                    )
                  : const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.image, size: 24),
                          Text('Original', style: TextStyle(fontSize: 10)),
                        ],
                      ),
                    ),
            ),
            const SizedBox(width: 8),
            // Arrow
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Icon(Icons.arrow_forward, size: 24),
            ),
            const SizedBox(width: 8),
            // Replacement image
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                border: Border.all(
                  color: fileExists ? Colors.grey : Colors.red,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: fileExists
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.file(
                        replacementFile,
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(Icons.broken_image, color: Colors.red),
                          );
                        },
                      ),
                    )
                  : const Center(
                      child: Icon(Icons.broken_image, color: Colors.red),
                    ),
            ),
            const SizedBox(width: 12),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Original: ${originalPortrait?.imageFile.path.split(Platform.pathSeparator).last ?? "Unknown"}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (originalPortrait != null && originalExists)
                    Text(
                      'Path: ${originalPortrait!.imageFile.path}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  if (!originalExists)
                    const Text(
                      'Original file not found',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    'Replacement: ${replacementFile.path.split(Platform.pathSeparator).last}',
                    style: TextStyle(color: fileExists ? null : Colors.red),
                  ),
                  Text(
                    'Path: ${replacementFile.path}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  if (!fileExists)
                    const Text(
                      'Replacement file not found',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  if (fileExists)
                    Text(
                      'Size: ${replacementFile.lengthSync().bytesAsReadableKB()}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                ],
              ),
            ),
            // Actions
            Column(
              children: [
                if (originalPortrait != null && originalExists)
                  IconButton(
                    icon: const Icon(Icons.open_in_new),
                    onPressed: () =>
                        launchUrlString(originalPortrait!.imageFile.path),
                    tooltip: 'Open original image',
                  ),
                if (fileExists)
                  IconButton(
                    icon: const Icon(Icons.open_in_new),
                    onPressed: () => launchUrlString(replacementPath),
                    tooltip: 'Open replacement image',
                  ),
                if (fileExists)
                  IconButton(
                    icon: const Icon(Icons.folder_open),
                    onPressed: () =>
                        launchUrlString(replacementFile.parent.path),
                    tooltip: 'Open folder',
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ResponsiveImageGrid extends ConsumerWidget {
  final List<({Portrait image, ModVariant variant})> modsAndImages;
  final List<({Portrait image, ModVariant variant})> allPortraits;
  final Map<String, String> replacements;
  final Future<void> Function(
    Portrait,
    List<({Portrait image, ModVariant variant})>,
  )
  onAddRandomReplacement;

  const ResponsiveImageGrid({
    super.key,
    required this.modsAndImages,
    required this.allPortraits,
    required this.replacements,
    required this.onAddRandomReplacement,
  });

  // Helper method to find replacement details
  ({Portrait? replacementPortrait, ModVariant? replacementMod})?
  _findReplacementDetails(
    String replacementPath,
    List<({Portrait image, ModVariant variant})> allPortraits,
  ) {
    for (final item in allPortraits) {
      if (item.image.imageFile.path == replacementPath) {
        return (replacementPortrait: item.image, replacementMod: item.variant);
      }
    }
    return null;
  }

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
            final hasReplacement = replacements.containsKey(portrait.hash);
            final replacementPath = replacements[portrait.hash];

            String bytesAsReadableKB = "unknown";
            try {
              bytesAsReadableKB = portrait.imageFile
                  .lengthSync()
                  .bytesAsReadableKB();
            } catch (error) {
              Fimber.w('Error reading file size: $error');
            }

            // Get replacement details if replacement exists
            String? replacementBytesAsReadableKB;
            ({Portrait? replacementPortrait, ModVariant? replacementMod})?
            replacementDetails;

            if (hasReplacement && replacementPath != null) {
              replacementDetails = _findReplacementDetails(
                replacementPath,
                allPortraits,
              );
              try {
                final replacementFile = File(replacementPath);
                if (replacementFile.existsSync()) {
                  replacementBytesAsReadableKB = replacementFile
                      .lengthSync()
                      .bytesAsReadableKB();
                }
              } catch (error) {
                Fimber.w('Error reading replacement file size: $error');
              }
            }

            return MovingTooltipWidget.framed(
              tooltipWidget: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Original portrait info
                      Text(
                        'Original Portrait',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      Text('Mod: ${mod.modInfo.nameOrId}'),
                      Text(
                        'Path: ${portrait.imageFile.path.toFile().relativeTo(modsPath)}',
                      ),
                      Text('Size: $bytesAsReadableKB'),
                      Text(
                        'Dimensions: ${portrait.width} x ${portrait.height}',
                      ),

                      // Replacement info if exists
                      if (hasReplacement && replacementPath != null) ...[
                        const SizedBox(height: 8),
                        Divider(color: Theme.of(context).colorScheme.outline),
                        const SizedBox(height: 4),
                        Text(
                          'Replacement Portrait',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                        if (replacementDetails?.replacementMod != null)
                          Text(
                            'Replacement Mod: ${replacementDetails!.replacementMod!.modInfo.nameOrId}',
                          )
                        else
                          Text('Replacement Mod: Unknown'),
                        Text(
                          'Replacement Path: ${File(replacementPath).path.toFile().relativeTo(modsPath)}',
                        ),
                        if (replacementBytesAsReadableKB != null)
                          Text(
                            'Replacement Size: $replacementBytesAsReadableKB',
                          )
                        else
                          const Text('Replacement Size: Unknown'),
                        if (replacementDetails?.replacementPortrait != null)
                          Text(
                            'Replacement Dimensions: ${replacementDetails!.replacementPortrait!.width} x ${replacementDetails!.replacementPortrait!.height}',
                          )
                        else
                          const Text('Replacement Dimensions: Unknown'),
                      ],
                    ],
                  ),
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
                    if (hasReplacement && replacementPath != null) ...[
                      MenuDivider(),
                      MenuItem(
                        label: 'Open Replacement',
                        icon: Icons.open_in_new,
                        onSelected: () {
                          launchUrlString(replacementPath);
                        },
                      ),
                      MenuItem(
                        label: "Open Replacement Folder",
                        icon: Icons.folder_open,
                        onSelected: () {
                          launchUrlString(File(replacementPath).parent.path);
                        },
                      ),
                    ],
                    MenuDivider(),
                    MenuItem(
                      label: 'Add Random Replacement',
                      icon: Icons.shuffle,
                      onSelected: () {
                        onAddRandomReplacement(portrait, allPortraits);
                      },
                    ),
                  ],
                ),
                child: PortraitImageWidget(
                  originalPortrait: portrait,
                  replacementPath: replacementPath,
                  hasReplacement: hasReplacement,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class PortraitImageWidget extends StatefulWidget {
  final Portrait originalPortrait;
  final String? replacementPath;
  final bool hasReplacement;

  const PortraitImageWidget({
    super.key,
    required this.originalPortrait,
    required this.replacementPath,
    required this.hasReplacement,
  });

  @override
  State<PortraitImageWidget> createState() => _PortraitImageWidgetState();
}

class _PortraitImageWidgetState extends State<PortraitImageWidget> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: SizedBox(
        width: 128,
        height: 128,
        child: widget.hasReplacement
            ? _buildStackedCards(theme)
            : _buildSingleCard(widget.originalPortrait.imageFile),
      ),
    );
  }

  Widget _buildSingleCard(File imageFile) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.file(
          imageFile,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[300],
              child: const Icon(Icons.broken_image),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStackedCards(ThemeData theme) {
    final replacementFile = _isHovering
        ? widget.originalPortrait.imageFile
        : File(widget.replacementPath!);
    final originalFile = _isHovering
        ? File(widget.replacementPath!)
        : widget.originalPortrait.imageFile;

    return Stack(
      fit: StackFit.passthrough,
      children: [
        // Back card (original image) - always visible at bottom-right
        Container(
          padding: const EdgeInsets.only(left: 16, top: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(1, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
              child: Image.file(
                originalFile,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[400],
                    child: const Icon(Icons.broken_image, size: 30),
                  );
                },
              ),
            ),
          ),
        ),
        // Front card (replacement image) - covers most of the original
        Padding(
          padding: const EdgeInsets.only(bottom: 12, right: 12),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Stack(
                fit: StackFit.passthrough,
                children: [
                  // Background, prevents transparent images from being see-through
                  Container(color: Colors.black),
                  // Replacement image
                  Image.file(
                    replacementFile,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.broken_image),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
