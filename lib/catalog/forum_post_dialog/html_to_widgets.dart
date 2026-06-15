import 'package:flutter/material.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;
import 'package:trios/catalog/forum_post_dialog/inline_span_builder.dart';
import 'package:trios/catalog/forum_post_dialog/spoiler_block.dart';

/// Parses [html] and returns a list of block-level Flutter widgets styled
/// against the current theme. Designed for SMF BBC-output (fractalsoftworks
/// forum).
///
/// Unsupported tags degrade gracefully to their text content. `<script>` and
/// `<style>` are dropped entirely. Empty / malformed input returns `[]`.
List<Widget> htmlToWidgets(
  String html,
  BuildContext context, {
  required void Function(String href) onLinkTap,
  required void Function(String? href) onLinkHover,
  String? baseUrl,
}) {
  if (html.isEmpty) return const [];
  dom.Document doc;
  try {
    doc = html_parser.parse(html);
  } catch (_) {
    return const [];
  }

  final body = doc.body;
  if (body == null) return const [];

  final inlineCtx = InlineBuildContext(
    buildContext: context,
    onLinkTap: onLinkTap,
    onLinkHover: onLinkHover,
    baseUrl: baseUrl,
  );
  return _renderNodes(body.nodes, context, inlineCtx);
}

List<Widget> _renderNodes(
  List<dom.Node> nodes,
  BuildContext context,
  InlineBuildContext inlineCtx, {
  TextAlign? inheritedAlign,
}) {
  final widgets = <Widget>[];
  // Buffer contiguous inline content into a single Text.rich.
  final inlineBuffer = <dom.Node>[];

  void flushInline() {
    if (inlineBuffer.isEmpty) return;
    final baseStyle =
        Theme.of(context).textTheme.bodyMedium ?? const TextStyle();
    final spans = buildInlineSpansFromNodes(inlineBuffer, baseStyle, inlineCtx);
    inlineBuffer.clear();
    if (spans.isEmpty) return;
    widgets.add(
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 2.0),
        child: SelectableText.rich(
          TextSpan(children: spans, style: baseStyle),
          textAlign: inheritedAlign ?? TextAlign.start,
        ),
      ),
    );
  }

  for (final node in nodes) {
    if (node is dom.Text) {
      if (node.text.trim().isEmpty) continue;
      inlineBuffer.add(node);
      continue;
    }
    if (node is! dom.Element) continue;

    final tag = node.localName?.toLowerCase() ?? '';

    if (tag == 'script' || tag == 'style') continue;

    if (_isInlineTag(tag)) {
      inlineBuffer.add(node);
      continue;
    }

    flushInline();
    widgets.addAll(
      _renderBlock(node, context, inlineCtx, inheritedAlign: inheritedAlign),
    );
  }

  flushInline();
  return widgets;
}

bool _isInlineTag(String tag) {
  const inline = {
    'a',
    'b',
    'strong',
    'i',
    'em',
    'u',
    'del',
    's',
    'strike',
    'sub',
    'sup',
    'tt',
    'code',
    'span',
    'br',
    'img',
    'font',
    'small',
    'big',
  };
  return inline.contains(tag);
}

List<Widget> _renderBlock(
  dom.Element el,
  BuildContext context,
  InlineBuildContext inlineCtx, {
  TextAlign? inheritedAlign,
}) {
  final tag = el.localName?.toLowerCase() ?? '';
  final theme = Theme.of(context);

  // Resolve alignment: element's own style takes priority, then inherited.
  final ownAlign = _textAlignFromStyle(el.attributes['style']);
  final effectiveAlign = ownAlign ?? inheritedAlign;

  // Spoiler block detection.
  if (tag == 'div' && el.className.contains('sp-wrap')) {
    return [_renderSpoiler(el, context, inlineCtx)];
  }

  switch (tag) {
    case 'p':
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: _buildInlineText(
            el,
            context,
            inlineCtx,
            textAlign: effectiveAlign,
          ),
        ),
      ];

    case 'div':
      final center =
          el.attributes['align']?.toLowerCase() == 'center' ||
          _hasCenterAlign(el.attributes['style']);
      final divAlign = center ? TextAlign.center : effectiveAlign;
      final children = _renderNodes(
        el.nodes,
        context,
        inlineCtx,
        inheritedAlign: divAlign,
      );
      if (children.isEmpty) return const [];
      if (center) {
        return [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: children
                  .map((c) => Align(alignment: Alignment.center, child: c))
                  .toList(),
            ),
          ),
        ];
      }
      return children;

    case 'h1':
      return [_heading(el, context, inlineCtx, theme.textTheme.headlineSmall)];
    case 'h2':
      return [_heading(el, context, inlineCtx, theme.textTheme.titleLarge)];
    case 'h3':
      return [_heading(el, context, inlineCtx, theme.textTheme.titleMedium)];
    case 'h4':
      return [_heading(el, context, inlineCtx, theme.textTheme.titleSmall)];
    case 'h5':
      return [_heading(el, context, inlineCtx, theme.textTheme.labelLarge)];
    case 'h6':
      return [_heading(el, context, inlineCtx, theme.textTheme.labelMedium)];

    case 'ul':
      return [_renderList(el, context, inlineCtx, ordered: false)];
    case 'ol':
      return [_renderList(el, context, inlineCtx, ordered: true)];

    case 'blockquote':
      return [_renderBlockquote(el, context, inlineCtx)];

    case 'pre':
      return [_renderPre(el, context)];

    case 'hr':
      return [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 4.0),
          child: Divider(height: 1),
        ),
      ];

    case 'table':
      return [_renderTable(el, context, inlineCtx)];

    case 'iframe':
      final src = el.attributes['src'];
      if (src == null || src.isEmpty) return const [];
      return [_renderIframePlaceholder(src, context, inlineCtx.onLinkTap)];

    case 'marquee':
      return _renderNodes(
        el.nodes,
        context,
        inlineCtx,
        inheritedAlign: effectiveAlign,
      );

    default:
      // Unknown block-ish tag: recurse into children, preserving text.
      return _renderNodes(
        el.nodes,
        context,
        inlineCtx,
        inheritedAlign: effectiveAlign,
      );
  }
}

bool _hasCenterAlign(String? style) {
  if (style == null) return false;
  return style.toLowerCase().contains('text-align: center') ||
      style.toLowerCase().contains('text-align:center');
}

Widget _heading(
  dom.Element el,
  BuildContext context,
  InlineBuildContext inlineCtx,
  TextStyle? style,
) {
  return Padding(
    padding: const EdgeInsets.only(top: 6.0, bottom: 4.0),
    child: _buildInlineText(el, context, inlineCtx, overrideStyle: style),
  );
}

Widget _buildInlineText(
  dom.Element el,
  BuildContext context,
  InlineBuildContext inlineCtx, {
  TextStyle? overrideStyle,
  TextAlign? textAlign,
}) {
  final baseStyle =
      overrideStyle ??
      Theme.of(context).textTheme.bodyMedium ??
      const TextStyle();
  final spans = buildInlineSpans(el, baseStyle, inlineCtx);
  if (spans.isEmpty) return const SizedBox.shrink();
  // Resolve text alignment from the element's own style if not overridden.
  final align = textAlign ?? _textAlignFromStyle(el.attributes['style']);
  return SelectableText.rich(
    TextSpan(children: spans, style: baseStyle),
    textAlign: align ?? TextAlign.start,
  );
}

/// Extracts a [TextAlign] from an inline `style` attribute, if present.
TextAlign? _textAlignFromStyle(String? style) {
  if (style == null) return null;
  final lower = style.toLowerCase();
  if (lower.contains('text-align') == false) return null;
  if (lower.contains('center')) return TextAlign.center;
  if (lower.contains('right')) return TextAlign.right;
  if (lower.contains('justify')) return TextAlign.justify;
  return null;
}

Widget _renderList(
  dom.Element el,
  BuildContext context,
  InlineBuildContext inlineCtx, {
  required bool ordered,
}) {
  final items = <Widget>[];
  var index = 1;
  for (final child in el.children) {
    if (child.localName?.toLowerCase() != 'li') continue;
    final marker = ordered ? '${index++}.' : '•';
    items.add(
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 1.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 24,
              child: Text(
                marker,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.right,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _renderNodes(child.nodes, context, inlineCtx),
              ),
            ),
          ],
        ),
      ),
    );
  }
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items,
    ),
  );
}

Widget _renderBlockquote(
  dom.Element el,
  BuildContext context,
  InlineBuildContext inlineCtx,
) {
  final theme = Theme.of(context);
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4.0),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: theme.colorScheme.primary, width: 3),
        ),
        color: theme.colorScheme.surfaceContainer.withValues(alpha: 0.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _renderNodes(el.nodes, context, inlineCtx),
      ),
    ),
  );
}

Widget _renderPre(dom.Element el, BuildContext context) {
  final theme = Theme.of(context);
  // Flatten all descendants' text (hljs spans included).
  final text = el.text;
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4.0),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SelectableText(
          text,
          style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
        ),
      ),
    ),
  );
}

Widget _renderTable(
  dom.Element el,
  BuildContext context,
  InlineBuildContext inlineCtx,
) {
  final theme = Theme.of(context);
  final rows = <TableRow>[];
  int maxCols = 0;
  final rawRows = <List<dom.Element>>[];

  void collectRows(dom.Element from) {
    for (final c in from.children) {
      final t = c.localName?.toLowerCase();
      if (t == 'tr') {
        final cells = c.children
            .where(
              (e) =>
                  e.localName?.toLowerCase() == 'td' ||
                  e.localName?.toLowerCase() == 'th',
            )
            .toList();
        rawRows.add(cells);
        if (cells.length > maxCols) maxCols = cells.length;
      } else if (t == 'tbody' || t == 'thead' || t == 'tfoot') {
        collectRows(c);
      }
    }
  }

  collectRows(el);
  if (rawRows.isEmpty || maxCols == 0) return const SizedBox.shrink();

  for (final cells in rawRows) {
    final tableCells = <Widget>[];
    for (var i = 0; i < maxCols; i++) {
      if (i < cells.length) {
        tableCells.add(
          Padding(
            padding: const EdgeInsets.all(4.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _renderNodes(cells[i].nodes, context, inlineCtx),
            ),
          ),
        );
      } else {
        tableCells.add(const SizedBox.shrink());
      }
    }
    rows.add(TableRow(children: tableCells));
  }

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4.0),
    child: Table(
      border: TableBorder.all(color: theme.dividerColor, width: 0.5),
      defaultVerticalAlignment: TableCellVerticalAlignment.top,
      children: rows,
    ),
  );
}

Widget _renderSpoiler(
  dom.Element el,
  BuildContext context,
  InlineBuildContext inlineCtx,
) {
  // SMF structure: sp-wrap > (sp-head, sp-body [folded]) ; sp-foot lives
  // inside sp-body as the close affordance.
  String label = 'Spoiler';
  dom.Element? bodyEl;
  for (final child in el.children) {
    final cls = child.className;
    if (cls.contains('sp-head')) {
      final text = child.text.trim();
      if (text.isNotEmpty) label = text;
    } else if (cls.contains('sp-body')) {
      bodyEl = child;
    }
  }
  final collapsed = bodyEl?.className.contains('folded') ?? true;
  final bodyWidgets = bodyEl == null
      ? const <Widget>[]
      : _renderNodes(
          bodyEl.nodes.where((n) {
            // Filter out the inner sp-foot "[close]" affordance.
            if (n is dom.Element && n.className.contains('sp-foot')) {
              return false;
            }
            return true;
          }).toList(),
          context,
          inlineCtx,
        );
  return SpoilerBlock(
    label: label,
    body: bodyWidgets,
    initiallyCollapsed: collapsed,
  );
}

Widget _renderIframePlaceholder(
  String src,
  BuildContext context,
  void Function(String) onLinkTap,
) {
  final theme = Theme.of(context);
  String label = src;
  try {
    final uri = Uri.parse(src);
    label = uri.host.isNotEmpty ? uri.host : src;
  } catch (_) {}
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6.0),
    child: InkWell(
      onTap: () => onLinkTap(src),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: theme.dividerColor),
          borderRadius: BorderRadius.circular(4.0),
          color: theme.colorScheme.surfaceContainer.withValues(alpha: 0.3),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.play_circle_outline, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Embedded video · $label',
                style: theme.textTheme.bodyMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
