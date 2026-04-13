import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:trios/catalog/models/forum_mod_details.dart';
import 'package:trios/catalog/models/forum_mod_index.dart';
import 'package:trios/trios/constants_theme.dart';
import 'package:trios/widgets/moving_tooltip.dart';

/// Header bar for the Forum Post Dialog. Shows mod title, author (with
/// avatar when available), post/last-edit dates, compact forum stats (from
/// the optional [ForumModIndex]), and an "Open in Browser" action.
class ForumPostHeader extends StatelessWidget {
  final ForumModDetails details;
  final ForumModIndex? index;
  final VoidCallback? onOpenInBrowser;
  final VoidCallback? onToggleFullScreen;
  final bool isFullScreen;
  final VoidCallback? onClose;

  static final _dateFormat = DateFormat.yMMMMd().add_jm();
  static final _decimalFormat = NumberFormat.decimalPattern();
  static final _compactFormat = NumberFormat.compact();

  const ForumPostHeader({
    super.key,
    required this.details,
    this.index,
    this.onOpenInBrowser,
    this.onToggleFullScreen,
    this.isFullScreen = false,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final postDate = details.postDate;
    final lastEdit = details.lastEditDate;
    final showLastEdit = lastEdit != null && lastEdit != postDate;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer.withValues(alpha: 0.6),
        border: Border(bottom: BorderSide(color: theme.dividerColor, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  details.title.isNotEmpty ? details.title : '???',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (onOpenInBrowser != null)
                Tooltip(
                  message: 'Open in browser',
                  child: IconButton(
                    icon: const Icon(Icons.open_in_browser),
                    onPressed: onOpenInBrowser,
                  ),
                ),
              if (onToggleFullScreen != null)
                Tooltip(
                  message: isFullScreen ? 'Exit full screen' : 'Full screen',
                  child: IconButton(
                    icon: Icon(
                      isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
                    ),
                    onPressed: onToggleFullScreen,
                  ),
                ),
              if (onClose != null)
                Tooltip(
                  message: 'Close',
                  child: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: onClose,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            spacing: 16,
            children: [
              Card(
                margin: .zero,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Padding(
                  padding: const .symmetric(vertical: 8.0, horizontal: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: .min,
                    children: [
                      _Avatar(path: details.authorAvatarPath),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: .start,
                        children: [
                          Text(
                            details.author,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (details.authorTitle != null &&
                              details.authorTitle!.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Text(
                              details.authorTitle!,
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontStyle: FontStyle.italic,
                                color: theme.textTheme.labelSmall?.color
                                    ?.withValues(alpha: 0.7),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          if (details.authorPostCount != null) ...[
                            const SizedBox(width: 6),
                            Text(
                              '${_decimalFormat.format(details.authorPostCount)} posts',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.textTheme.labelSmall?.color
                                    ?.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: .start,
                spacing: 8,
                children: [
                  if (postDate != null || showLastEdit)
                    Padding(
                      padding: const EdgeInsets.only(top: 2.0),
                      child: Column(
                        crossAxisAlignment: .start,
                        children: [
                          if (postDate != null)
                            Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'Posted ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  TextSpan(text: _dateFormat.format(postDate)),
                                ],
                              ),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.textTheme.labelSmall?.color
                                    ?.withValues(alpha: 0.6),
                              ),
                            ),
                          if (showLastEdit)
                            Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'Edited ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  TextSpan(text: _dateFormat.format(lastEdit)),
                                ],
                              ),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.textTheme.labelSmall?.color
                                    ?.withValues(alpha: 0.6),
                              ),
                            ),
                        ],
                      ),
                    ),
                  if (index != null)
                    _Stats(
                      index: index!,
                      compact: _compactFormat,
                      decimal: _decimalFormat,
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? path;

  const _Avatar({required this.path});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final url = _resolveAvatarUrl(path);
    if (url == null) {
      return CircleAvatar(
        radius: 20,
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        child: Icon(Icons.person, size: 22, color: theme.disabledColor),
      );
    }
    return ClipOval(
      child: Image.network(
        url,
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => CircleAvatar(
          radius: 20,
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          child: Icon(Icons.person, size: 22, color: theme.disabledColor),
        ),
      ),
    );
  }

  String? _resolveAvatarUrl(String? p) {
    if (p == null || p.isEmpty) return null;
    if (p.startsWith('http://') || p.startsWith('https://')) return p;
    // SMF avatar paths in the bundle are either absolute-ish ("avatars/xxx")
    // or full URLs. Fall back to the fractalsoftworks forum base when
    // possible.
    try {
      return Uri.parse(
        'https://fractalsoftworks.com/forum/',
      ).resolve(p).toString();
    } catch (_) {
      return null;
    }
  }
}

class _Stats extends StatelessWidget {
  final ForumModIndex index;
  final NumberFormat compact;
  final NumberFormat decimal;

  const _Stats({
    required this.index,
    required this.compact,
    required this.decimal,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.labelSmall?.copyWith(
      color: theme.textTheme.labelSmall?.color?.withValues(alpha: 0.7),
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      spacing: 8,
      children: [
        MovingTooltipWidget.text(
          message: '${decimal.format(index.views)} forum views',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 4,
            children: [
              Icon(Icons.visibility, size: 12, color: style?.color),
              Text(compact.format(index.views), style: style),
            ],
          ),
        ),
        MovingTooltipWidget.text(
          message: '${decimal.format(index.replies)} forum replies',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 4,
            children: [
              Icon(Icons.forum, size: 12, color: style?.color),
              Text(compact.format(index.replies), style: style),
            ],
          ),
        ),
      ],
    );
  }
}
