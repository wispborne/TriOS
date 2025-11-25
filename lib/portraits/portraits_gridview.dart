import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/portraits/portrait_model.dart';
import 'package:trios/thirdparty/flutter_context_menu/flutter_context_menu.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/logging.dart';
import 'package:trios/widgets/conditional_wrap.dart';
import 'package:trios/widgets/moving_tooltip.dart';
import 'package:url_launcher/url_launcher_string.dart';

class PortraitsGridView extends ConsumerWidget {
  final List<({Portrait image, ModVariant? variant})> modsAndImages;
  final List<({Portrait image, ModVariant? variant})> allPortraits;
  final Map<String, Portrait> replacements;
  final Future<void> Function(
    Portrait,
    List<({Portrait image, ModVariant? variant})>,
  )
  onAddRandomReplacement;
  final bool isDraggable;
  final void Function(Portrait original, Portrait replacement)?
  onAcceptDraggable;
  final void Function(Portrait selectedPortrait) onSelectedPortraitToReplace;
  final bool showPickReplacementIcon;

  const PortraitsGridView({
    super.key,
    required this.modsAndImages,
    required this.allPortraits,
    required this.replacements,
    required this.onAddRandomReplacement,
    required this.onSelectedPortraitToReplace,
    required this.showPickReplacementIcon,
    this.isDraggable = false,
    this.onAcceptDraggable,
  });

  // Helper method to find replacement details
  ({Portrait? replacementPortrait, ModVariant? replacementMod})?
  _findReplacementDetails(
    String replacementPath,
    List<({Portrait image, ModVariant? variant})> allPortraits,
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
            final replacement = replacements[portrait.hash];
            final hasReplacement =
                replacements.containsKey(portrait.hash) && replacement != null;

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

            if (hasReplacement) {
              replacementDetails = _findReplacementDetails(
                replacement.imageFile.path,
                allPortraits,
              );
              try {
                final replacementFile = replacement.imageFile;
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
                      // Replacement info if exists
                      if (hasReplacement) ...[
                        Text(
                          'Replacement: ${replacement.imageFile.nameWithExtension}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        if (replacementDetails?.replacementMod != null)
                          Text(
                            'Replacement Mod: ${replacementDetails!.replacementMod!.modInfo.nameOrId}',
                          )
                        else
                          Text('Vanilla'),
                        Text('Path: ${replacement.relativePath}'),
                        if (replacementBytesAsReadableKB != null)
                          Text('Size: $replacementBytesAsReadableKB'),
                        if (replacementDetails?.replacementPortrait != null)
                          Text(
                            'Dimensions: ${replacementDetails!.replacementPortrait!.width} x ${replacementDetails.replacementPortrait!.height}',
                          ),
                        const SizedBox(height: 8),
                        Divider(color: Theme.of(context).colorScheme.onSurface),
                        const SizedBox(height: 4),
                      ],
                      // Original portrait info
                      Text(
                        hasReplacement
                            ? "Original: ${portrait.imageFile.nameWithExtension}"
                            : portrait.imageFile.nameWithExtension,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: hasReplacement
                              ? null
                              : Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      Text(
                        mod == null
                            ? "Vanilla"
                            : 'Mod: ${mod.modInfo.nameOrId}',
                      ),
                      Text('Path: ${portrait.relativePath}'),
                      Text('Size: $bytesAsReadableKB'),
                      Text(
                        'Dimensions: ${portrait.width} x ${portrait.height}',
                      ),
                    ],
                  ),
                ],
              ),
              child: ContextMenuRegion(
                contextMenu: ContextMenu(
                  entries: <ContextMenuEntry>[
                    // MenuItem(
                    //   label: 'Set Random Replacement',
                    //   icon: Icons.shuffle,
                    //   onSelected: () {
                    //     onAddRandomReplacement(portrait, allPortraits);
                    //   },
                    // ),
                    MenuItem(
                      label: 'Pick Replacement',
                      icon: Icons.swap_horiz,
                      onSelected: () {
                        onSelectedPortraitToReplace(portrait);
                      },
                    ),
                    if (hasReplacement)
                      MenuItem(
                        label: 'Revert to Original',
                        icon: Icons.undo,
                        onSelected: () {
                          ref
                              .read(
                                AppState.portraitReplacementsManager.notifier,
                              )
                              .removeReplacement(portrait);
                        },
                      ),
                    MenuDivider(),
                    if (hasReplacement) ...[
                      MenuDivider(),
                      MenuItem(
                        label: 'Open Replacement',
                        icon: Icons.open_in_new,
                        onSelected: () {
                          launchUrlString(replacement.imageFile.path);
                        },
                      ),
                      MenuItem(
                        label: "Open Folder of Replacement",
                        icon: Icons.folder_open,
                        onSelected: () {
                          launchUrlString(replacement.imageFile.parent.path);
                        },
                      ),
                      MenuDivider(),
                    ],
                    MenuItem(
                      label: 'Open Original',
                      icon: Icons.open_in_new,
                      onSelected: () {
                        launchUrlString(portrait.imageFile.path);
                      },
                    ),
                    MenuItem(
                      label: "Open Folder Of Original",
                      icon: Icons.folder_open,
                      onSelected: () {
                        launchUrlString(portrait.imageFile.parent.path);
                      },
                    ),
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
                      // ScaffoldMessenger.of(context).showSnackBar(
                      //   SnackBar(
                      //     content: Text(
                      //       'Replaced ${portrait.imageFile.nameWithExtension} with\n${details.data.imageFile.nameWithExtension}',
                      //     ),
                      //     duration: const Duration(seconds: 3),
                      //   ),
                      // );
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
                      replacementPath: replacement?.imageFile.path,
                      hasReplacement: hasReplacement,
                      showPickReplacementIcon: showPickReplacementIcon,
                      onSelectedPortraitToReplace: onSelectedPortraitToReplace,
                      isDraggable: isDraggable,
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
  final void Function(Portrait selectedPortrait) onSelectedPortraitToReplace;
  final bool isDraggable;
  final bool showPickReplacementIcon;

  const PortraitImageWidget({
    super.key,
    required this.originalPortrait,
    required this.replacementPath,
    required this.hasReplacement,
    required this.showPickReplacementIcon,
    required this.onSelectedPortraitToReplace,
    required this.isDraggable,
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
      cursor: widget.isDraggable
          ? SystemMouseCursors.move
          : SystemMouseCursors.basic,
      child: SizedBox(
        width: 128,
        height: 128,
        child: widget.hasReplacement
            ? _buildStackedCards(theme, ref)
            : _buildSingleCard(widget.originalPortrait),
      ),
    );
  }

  Widget _buildSingleCard(Portrait portrait) {
    final theme = Theme.of(context);
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
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            Image.file(
              portrait.imageFile,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[300],
                  child: const Icon(Icons.broken_image),
                );
              },
            ),
            if (widget.showPickReplacementIcon)
              Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 0, right: 2),
                  child: MovingTooltipWidget.text(
                    message: 'Pick Replacement',
                    child: IconButton(
                      icon: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: theme.colorScheme.secondaryContainer
                              .withValues(alpha: 0.6),
                          border: Border.all(
                            color: theme.colorScheme.onSecondaryContainer
                                .withValues(alpha: 0.3),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 1),
                              blurRadius: 4,
                              offset: const Offset(2, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.swap_horiz,
                          size: 20,
                          color: theme.colorScheme.onSecondaryContainer,
                        ),
                      ),
                      onPressed: () {
                        widget.onSelectedPortraitToReplace(portrait);
                      },
                    ),
                  ),
                ),
              ),
          ],
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
                  border: Border.all(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    width: 2,
                    strokeAlign: BorderSide.strokeAlignInside,
                  ),
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
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8, right: 8),
                child: MovingTooltipWidget.text(
                  message: 'Revert to Original',
                  child: IconButton(
                    icon: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.colorScheme.primaryContainer,
                        border: Border.all(
                          color: theme.colorScheme.onPrimaryContainer
                              .withValues(alpha: 0.3),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.8),
                            blurRadius: 4,
                            offset: const Offset(2, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.undo,
                        color: theme.colorScheme.primary,
                        size: 18,
                      ),
                    ),
                    onPressed: () {
                      ref
                          .read(AppState.portraitReplacementsManager.notifier)
                          .removeReplacement(widget.originalPortrait);
                    },
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
