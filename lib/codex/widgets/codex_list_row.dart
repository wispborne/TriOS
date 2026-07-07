import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/codex/codex_labels.dart';
import 'package:trios/codex/models/codex_entry.dart';
import 'package:trios/ship_viewer/models/ship.dart';
import 'package:trios/ship_viewer/widgets/ship_blueprint_view.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/weapon_viewer/widgets/weapon_image_cell.dart';

/// One row in the Codex list (and the related panel): a square image cell, the
/// name, a grey subtitle, and — in the related panel and search results — a
/// small category type hint. Reuses the viewer pages' image widgets so the
/// hover effects (ship/wing engine glow, weapon glow) carry over.
class CodexListRow extends ConsumerStatefulWidget {
  final CodexEntry entry;

  /// For wing rows: the resolved ship behind the wing, if any. Lets the row
  /// show the ship's blueprint (with engine glow).
  final Ship? wingShip;

  final bool selected;
  final bool showTypeHint;

  /// Smaller name text, for dense contexts like the Related bar.
  final bool compact;

  final VoidCallback onTap;

  const CodexListRow({
    super.key,
    required this.entry,
    required this.onTap,
    this.wingShip,
    this.selected = false,
    this.showTypeHint = false,
    this.compact = true,
  });

  @override
  ConsumerState<CodexListRow> createState() => _CodexListRowState();
}

class _CodexListRowState extends ConsumerState<CodexListRow> {
  bool _hovered = false;

  static const double _imageSize = 40;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entry = widget.entry;
    final subtitle = entry.subtitle;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          color: widget.selected
              ? theme.colorScheme.primary.withValues(alpha: 0.18)
              : _hovered
              ? theme.colorScheme.onSurface.withValues(alpha: 0.06)
              : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          child: Row(
            spacing: 8,
            children: [
              SizedBox(
                width: _imageSize,
                height: _imageSize,
                child: _image(),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      entry.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: widget.compact
                          ? theme.textTheme.bodySmall
                          : theme.textTheme.bodyMedium,
                    ),
                    if (widget.showTypeHint)
                      Text(
                        codexCategoryLabel(entry.type),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      )
                    else if (subtitle != null && subtitle.isNotEmpty)
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _image() {
    final entry = widget.entry;
    switch (entry) {
      case ShipCodexEntry(:final ship):
        return _shipImage(ship);
      case WingCodexEntry():
        final ship = widget.wingShip;
        return ship != null ? _shipImage(ship) : _categoryFallback();
      case WeaponCodexEntry(:final weapon):
        return WeaponImageCell(
          weapon: weapon,
          size: _imageSize,
          rowHovered: _hovered,
        );
      case HullmodCodexEntry(:final hullmod):
        return _fileImage(hullmod.sprite);
      case ShipSystemCodexEntry(:final system):
        return _fileImage(system.icon);
      case FactionCodexEntry(:final faction):
        final dir = ref.watch(AppState.gameCoreFolder).valueOrNull;
        final file = faction.resolveImageFile(
          faction.crest ?? faction.logo,
          dir,
        );
        return file != null
            ? Image.file(
                file,
                fit: BoxFit.scaleDown,
                errorBuilder: (_, _, _) => _categoryFallback(),
              )
            : _categoryFallback();
    }
  }

  Widget _shipImage(Ship ship) {
    return ShipBlueprintView.minimal(
      ship: ship,
      cacheWidth: _imageSize.toInt(),
      fit: BoxFit.contain,
      clipContent: false,
      forceEngineGlow: _hovered,
    );
  }

  Widget _fileImage(String? path) {
    if (path == null || path.isEmpty) return _categoryFallback();
    return Image.file(
      File(path),
      fit: BoxFit.scaleDown,
      errorBuilder: (_, _, _) => _categoryFallback(),
    );
  }

  /// Fallback when an entry has no image: the category's own icon (the same
  /// one the sidebar/menus use), dimmed.
  Widget _categoryFallback() {
    return Center(
      child: codexCategoryIcon(
        widget.entry.type,
        size: 22,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45),
      ),
    );
  }
}
