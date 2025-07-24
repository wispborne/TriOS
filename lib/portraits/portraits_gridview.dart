import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/portraits/portrait_model.dart';
import 'package:trios/portraits/portrait_replacements_manager.dart';
import 'package:trios/thirdparty/flutter_context_menu/flutter_context_menu.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/logging.dart';
import 'package:trios/widgets/conditional_wrap.dart';
import 'package:trios/widgets/moving_tooltip.dart';
import 'package:url_launcher/url_launcher_string.dart';

class PortraitsGridView extends ConsumerWidget {
  final List<({Portrait image, ModVariant variant})> modsAndImages;
  final List<({Portrait image, ModVariant variant})> allPortraits;
  final Map<String, String> replacements;
  final Future<void> Function(
    Portrait,
    List<({Portrait image, ModVariant variant})>,
  )
  onAddRandomReplacement;
  final bool isDraggable;
  final void Function(Portrait original, Portrait replacement)?
  onAcceptDraggable;

  const PortraitsGridView({
    super.key,
    required this.modsAndImages,
    required this.allPortraits,
    required this.replacements,
    required this.onAddRandomReplacement,
    this.isDraggable = false,
    this.onAcceptDraggable,
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
                            'Replacement Dimensions: ${replacementDetails!.replacementPortrait!.width} x ${replacementDetails.replacementPortrait!.height}',
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
                      label: 'Set Random Replacement',
                      icon: Icons.shuffle,
                      onSelected: () {
                        onAddRandomReplacement(portrait, allPortraits);
                      },
                    ),
                    if (hasReplacement)
                      MenuItem(
                        label: 'Clear Replacement',
                        icon: Icons.undo,
                        onSelected: () {
                          ref
                              .read(portraitReplacementsManager.notifier)
                              .removeReplacement(portrait.hash);
                        },
                      ),
                    MenuDivider(),
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
                  ],
                ),
                child: ConditionalWrap(
                  condition: onAcceptDraggable != null,
                  wrapper: (child) => DragTarget(
                    builder:
                        (
                          BuildContext context,
                          List<dynamic> accepted,
                          List<dynamic> rejected,
                        ) => Container(
                          foregroundDecoration: BoxDecoration(
                            color: accepted.isNotEmpty
                                ? Colors.black54
                                : Colors.transparent,
                          ),
                          child: child,
                        ),
                    onAcceptWithDetails: (DragTargetDetails<Portrait> details) {
                      onAcceptDraggable!(portrait, details.data);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Replaced ${portrait.imageFile.nameWithExtension} with\n${details.data.imageFile.nameWithExtension}',
                          ),
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    },
                  ),
                  child: ConditionalWrap(
                    condition: isDraggable,
                    wrapper: (child) => Draggable<Portrait>(
                      data: portrait,
                      feedback: Opacity(opacity: 0.5, child: child),
                      onDragUpdate: (details) {},
                      onDragCompleted: () {},
                      onDraggableCanceled: (velocity, offset) {},
                      maxSimultaneousDrags: 1,
                      child: child,
                    ),
                    child: PortraitImageWidget(
                      originalPortrait: portrait,
                      replacementPath: replacementPath,
                      hasReplacement: hasReplacement,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class PortraitImageWidget extends ConsumerStatefulWidget {
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
  ConsumerState<PortraitImageWidget> createState() =>
      _PortraitImageWidgetState();
}

class _PortraitImageWidgetState extends ConsumerState<PortraitImageWidget> {
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
            ? _buildStackedCards(theme, ref)
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
            color: Colors.black.withValues(alpha: 0.1),
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

  Widget _buildStackedCards(ThemeData theme, WidgetRef ref) {
    final replacementFile = _isHovering
        ? widget.originalPortrait.imageFile
        : File(widget.replacementPath!);
    final originalFile = _isHovering
        ? File(widget.replacementPath!)
        : widget.originalPortrait.imageFile;

    return Builder(
      builder: (context) {
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
                    color: Colors.black.withValues(alpha: 0.2),
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
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
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
            Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(0),
                child: IconButton(
                  icon: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.primaryContainer,
                    ),
                    child: Icon(
                      Icons.undo,
                      color: theme.colorScheme.primary,
                      size: 16,
                    ),
                  ),
                  onPressed: () {
                    ref
                        .read(portraitReplacementsManager.notifier)
                        .removeReplacement(widget.originalPortrait.hash);
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
