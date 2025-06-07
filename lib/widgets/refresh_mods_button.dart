import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/widgets/disable.dart';

import '../trios/app_state.dart';
import 'conditional_wrap.dart';
import 'moving_tooltip.dart';

class RefreshModsButton extends ConsumerStatefulWidget {
  final double iconSize;
  final Widget? labelWidget;
  final EdgeInsetsGeometry padding;
  final bool isRefreshing;
  final bool iconOnly;
  final bool outlined;
  final bool isDense;

  const RefreshModsButton({
    super.key,
    this.iconSize = 20,
    this.padding = const EdgeInsets.all(4),
    this.labelWidget,
    this.outlined = false,
    this.isDense = false,
    required this.isRefreshing,
    required this.iconOnly,
  });

  @override
  ConsumerState<RefreshModsButton> createState() => _RefreshModsButtonState();
}

class _RefreshModsButtonState extends ConsumerState<RefreshModsButton> {
  @override
  Widget build(BuildContext context) {
    final modVariants = ref.watch(AppState.modVariants);
    final isRefreshing =
        (modVariants.isLoading ||
        ref.watch(AppState.versionCheckResults).isLoading ||
        widget.isRefreshing);

    return Disable(
      isEnabled: !isRefreshing,
      child: MovingTooltipWidget.text(
        message: "Refresh mods and recheck versions",
        child: widget.iconOnly
            ? IconButton(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                icon: _icon(isRefreshing),
                onPressed: () {
                  _refresh();
                },
                constraints: widget.isDense ? null : const BoxConstraints(),
              )
            : widget.outlined
            ? SizedBox(
                height: 32,
                child: IconButton.outlined(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  icon: _icon(isRefreshing),
                  onPressed: () {
                    _refresh();
                  },
                  style: OutlinedButton.styleFrom(
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(16)),
                    ),
                  ),
                ),
              )
            : Padding(
                padding: widget.padding,
                child: OutlinedButton.icon(
                  onPressed: () => _refresh(),
                  label: Text(isRefreshing ? "Refreshing" : "Refresh"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.8),
                    side: BorderSide(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.8),
                    ),
                  ),
                  icon: _icon(isRefreshing),
                ),
              ),
      ),
    );
  }

  ConditionalWrap _icon(bool isRefreshing) {
    return ConditionalWrap(
      condition: isRefreshing,
      wrapper: (child) => Animate(
        onComplete: (c) => c.repeat(),
        effects: [RotateEffect(duration: 2000.ms)],
        child: child,
      ),
      child: const Icon(Icons.refresh),
    );
  }

  void _refresh() {
    AppState.skipCacheOnNextVersionCheck = true;
    ModVariant.iconCache.clear();
    ref.invalidate(AppState.modVariants);
    ref.invalidate(AppState.changelogsProvider);
  }
}
