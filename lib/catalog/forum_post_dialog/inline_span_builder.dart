import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:html/dom.dart' as dom;

/// Context for inline span building, threaded through recursive calls.
class InlineBuildContext {
  final BuildContext buildContext;
  final void Function(String href) onLinkTap;
  final void Function(String? href) onLinkHover;
  final String? baseUrl;

  InlineBuildContext({
    required this.buildContext,
    required this.onLinkTap,
    required this.onLinkHover,
    required this.baseUrl,
  });
}

/// Walks inline descendants of [node] and returns a list of `InlineSpan`s.
/// Handles SMF BBC-output inline tags and class/style conventions.
List<InlineSpan> buildInlineSpans(
  dom.Node node,
  TextStyle baseStyle,
  InlineBuildContext ctx,
) {
  final spans = <InlineSpan>[];
  for (final child in node.nodes) {
    spans.addAll(_nodeToSpans(child, baseStyle, ctx));
  }
  return spans;
}

/// Variant of [buildInlineSpans] that accepts an explicit list of sibling
/// nodes (useful when the caller is buffering inline runs without a shared
/// parent element).
List<InlineSpan> buildInlineSpansFromNodes(
  List<dom.Node> nodes,
  TextStyle baseStyle,
  InlineBuildContext ctx,
) {
  final spans = <InlineSpan>[];
  for (final child in nodes) {
    spans.addAll(_nodeToSpans(child, baseStyle, ctx));
  }
  return spans;
}

/// Expose the single-node span builder for callers that need it (e.g. the
/// block-level renderer when walking a mixed-content container).
List<InlineSpan> nodeToSpans(
  dom.Node node,
  TextStyle style,
  InlineBuildContext ctx,
) => _nodeToSpans(node, style, ctx);

List<InlineSpan> _nodeToSpans(
  dom.Node node,
  TextStyle style,
  InlineBuildContext ctx,
) {
  if (node is dom.Text) {
    final text = node.text;
    if (text.isEmpty) return const [];
    return [TextSpan(text: text, style: style)];
  }
  if (node is! dom.Element) return const [];

  final tag = node.localName?.toLowerCase() ?? '';

  // Dropped entirely.
  if (tag == 'script' || tag == 'style') return const [];

  // Line break.
  if (tag == 'br') return [TextSpan(text: '\n', style: style)];

  // Image as a WidgetSpan.
  if (tag == 'img') {
    final src = node.attributes['src'];
    if (src == null || src.isEmpty) return const [];
    final resolved = _resolveUrl(src, ctx.baseUrl);
    final alt = node.attributes['alt'];
    return [
      WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: _InlineImage(url: resolved, alt: alt, canToggleFullSize: true),
      ),
    ];
  }

  // Link — rendered as a WidgetSpan with GestureDetector so taps always
  // work (TextSpan.recognizer is unreliable inside Text.rich).
  if (tag == 'a') {
    final href = node.attributes['href'];
    if (href == null || href.isEmpty) {
      return buildInlineSpans(node, style, ctx);
    }
    // Anchor-only links (e.g. "#section") can't scroll inside the dialog.
    if (href.startsWith('#')) {
      return buildInlineSpans(node, style, ctx);
    }
    final resolved = _resolveUrl(href, ctx.baseUrl);

    // If the link wraps ONLY image(s), make each image tappable directly.
    if (_containsOnlyImages(node)) {
      return node.nodes.expand((child) {
        if (child is dom.Element && child.localName?.toLowerCase() == 'img') {
          final src = child.attributes['src'];
          if (src == null || src.isEmpty) return <InlineSpan>[];
          final imgResolved = _resolveUrl(src, ctx.baseUrl);
          final alt = child.attributes['alt'];
          return [
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: _LinkWrapper(
                url: resolved,
                onTap: () => ctx.onLinkTap(resolved),
                onHover: ctx.onLinkHover,
                child: _InlineImage(url: imgResolved, alt: alt),
              ),
            ),
          ];
        }
        return <InlineSpan>[];
      }).toList();
    }

    // Text link — build children as inline spans, then wrap the whole
    // thing in a single WidgetSpan with GestureDetector + MouseRegion.
    final linkStyle = style.copyWith(
      color: Theme.of(ctx.buildContext).colorScheme.primary,
      decoration: TextDecoration.underline,
    );
    final children = buildInlineSpans(node, linkStyle, ctx);
    return [
      WidgetSpan(
        alignment: PlaceholderAlignment.baseline,
        baseline: TextBaseline.alphabetic,
        child: _LinkWrapper(
          url: resolved,
          onTap: () => ctx.onLinkTap(resolved),
          onHover: ctx.onLinkHover,
          child: Text.rich(TextSpan(children: children, style: linkStyle)),
        ),
      ),
    ];
  }

  // Style-mutating tags. Apply style change, recurse.
  TextStyle nextStyle = style;
  switch (tag) {
    case 'strong':
    case 'b':
      nextStyle = nextStyle.copyWith(fontWeight: FontWeight.bold);
      break;
    case 'em':
    case 'i':
      nextStyle = nextStyle.copyWith(fontStyle: FontStyle.italic);
      break;
    case 'u':
      nextStyle = _addDecoration(nextStyle, TextDecoration.underline);
      break;
    case 'del':
    case 's':
    case 'strike':
      nextStyle = _addDecoration(nextStyle, TextDecoration.lineThrough);
      break;
    case 'sub':
      nextStyle = nextStyle.copyWith(
        fontSize: (nextStyle.fontSize ?? 14) * 0.8,
        textBaseline: TextBaseline.alphabetic,
      );
      // Approximate sub/sup with a vertical offset via FontFeature not
      // available in TextStyle; just rely on smaller size here.
      break;
    case 'sup':
      nextStyle = nextStyle.copyWith(
        fontSize: (nextStyle.fontSize ?? 14) * 0.8,
        textBaseline: TextBaseline.alphabetic,
      );
      break;
    case 'tt':
    case 'code':
      nextStyle = nextStyle.copyWith(fontFamily: 'monospace');
      break;
    case 'span':
      nextStyle = _applySpanClassesAndStyle(node, nextStyle, ctx);
      break;
    default:
      // Unknown/transparent inline tag: recurse with current style.
      break;
  }

  return buildInlineSpans(node, nextStyle, ctx);
}

/// Apply SMF `bbc_*` classes plus any inline `style` attribute values that
/// the forum bundle actually uses (`font-size`, `color`).
TextStyle _applySpanClassesAndStyle(
  dom.Element el,
  TextStyle style,
  InlineBuildContext ctx,
) {
  var next = style;
  final classes = el.className.split(RegExp(r'\s+'));

  if (classes.contains('bbc_u')) {
    next = _addDecoration(next, TextDecoration.underline);
  }
  // `hljs-*` spans are flattened transparently via the default recursion.

  final inline = el.attributes['style'];
  if (inline != null && inline.isNotEmpty) {
    final props = _parseInlineStyle(inline);

    final fontSize = props['font-size'];
    if (fontSize != null) {
      final parsed = _parseFontSize(fontSize, next.fontSize ?? 14);
      if (parsed != null) next = next.copyWith(fontSize: parsed);
    }

    final color = props['color'];
    if (color != null) {
      final parsed = _parseCssColor(color);
      if (parsed != null) {
        next = next.copyWith(
          color: _contrastSafeColor(ctx.buildContext, parsed),
        );
      }
    }

    final fontFamily = props['font-family'];
    if (fontFamily != null) {
      final resolved = _resolveFont(fontFamily, next);
      if (resolved != null) next = resolved;
    }
  }

  return next;
}

TextStyle _addDecoration(TextStyle style, TextDecoration deco) {
  final existing = style.decoration;
  if (existing == null || existing == TextDecoration.none) {
    return style.copyWith(decoration: deco);
  }
  return style.copyWith(decoration: TextDecoration.combine([existing, deco]));
}

Map<String, String> _parseInlineStyle(String style) {
  final result = <String, String>{};
  for (final part in style.split(';')) {
    final idx = part.indexOf(':');
    if (idx < 0) continue;
    final k = part.substring(0, idx).trim().toLowerCase();
    final v = part.substring(idx + 1).trim();
    if (k.isNotEmpty) result[k] = v;
  }
  return result;
}

double? _parseFontSize(String value, double baseSize) {
  final v = value.trim().toLowerCase();
  // Handle "Npt" — convert points to logical pixels, then anchor at body
  // 10pt ≈ baseSize for readability.
  final ptMatch = RegExp(r'^([0-9.]+)\s*pt$').firstMatch(v);
  if (ptMatch != null) {
    final pt = double.tryParse(ptMatch.group(1)!);
    if (pt == null) return null;
    return baseSize * (pt / 10.0);
  }
  final pxMatch = RegExp(r'^([0-9.]+)\s*px$').firstMatch(v);
  if (pxMatch != null) {
    return double.tryParse(pxMatch.group(1)!);
  }
  final emMatch = RegExp(r'^([0-9.]+)\s*em$').firstMatch(v);
  if (emMatch != null) {
    final em = double.tryParse(emMatch.group(1)!);
    if (em == null) return null;
    return baseSize * em;
  }
  return null;
}

Color? _parseCssColor(String value) {
  final v = value.trim().toLowerCase();
  if (v.startsWith('#')) {
    final hex = v.substring(1);
    if (hex.length == 3) {
      final r = int.parse(hex[0] * 2, radix: 16);
      final g = int.parse(hex[1] * 2, radix: 16);
      final b = int.parse(hex[2] * 2, radix: 16);
      return Color.fromARGB(255, r, g, b);
    }
    if (hex.length == 6) {
      return Color(int.parse('ff$hex', radix: 16));
    }
    if (hex.length == 8) {
      return Color(int.parse(hex, radix: 16));
    }
    return null;
  }
  final rgbMatch = RegExp(
    r'^rgba?\(\s*([0-9]+)\s*,\s*([0-9]+)\s*,\s*([0-9]+)(?:\s*,\s*([0-9.]+))?\s*\)$',
  ).firstMatch(v);
  if (rgbMatch != null) {
    final r = int.parse(rgbMatch.group(1)!);
    final g = int.parse(rgbMatch.group(2)!);
    final b = int.parse(rgbMatch.group(3)!);
    final a = double.tryParse(rgbMatch.group(4) ?? '1') ?? 1.0;
    return Color.fromARGB((a * 255).round(), r, g, b);
  }
  return _cssNamedColors[v];
}

const _cssNamedColors = <String, Color>{
  'black': Color(0xff000000),
  'white': Color(0xffffffff),
  'red': Color(0xffff0000),
  'green': Color(0xff008000),
  'blue': Color(0xff0000ff),
  'yellow': Color(0xffffff00),
  'orange': Color(0xffffa500),
  'purple': Color(0xff800080),
  'gray': Color(0xff808080),
  'grey': Color(0xff808080),
  'silver': Color(0xffc0c0c0),
  'maroon': Color(0xff800000),
  'lime': Color(0xff00ff00),
  'aqua': Color(0xff00ffff),
  'cyan': Color(0xff00ffff),
  'teal': Color(0xff008080),
  'navy': Color(0xff000080),
  'fuchsia': Color(0xffff00ff),
  'magenta': Color(0xffff00ff),
  'olive': Color(0xff808000),
  'pink': Color(0xffffc0cb),
  'brown': Color(0xffa52a2a),
};

/// Resolves a CSS `font-family` value to a [TextStyle] with the appropriate
/// font. Tries GoogleFonts first, then falls back to generic family keywords.
/// Returns `null` if no recognisable font is found (keeps the inherited style).
TextStyle? _resolveFont(String fontFamily, TextStyle base) {
  // CSS font-family can be a comma-separated list of names; try each in order.
  final candidates =
      fontFamily
          .split(',')
          .map((f) => f.trim().replaceAll(RegExp(r'''['"]'''), '').toLowerCase())
          .where((f) => f.isNotEmpty);

  for (final name in candidates) {
    // Generic CSS families → system defaults.
    final generic = _genericFontFamilies[name];
    if (generic != null) {
      return base.copyWith(fontFamily: generic);
    }

    // Exact-match lookup against known GoogleFonts.
    final googleFont = _googleFontBuilders[name];
    if (googleFont != null) {
      final gf = googleFont(base);
      return base.copyWith(
        fontFamily: gf.fontFamily,
        fontFamilyFallback: gf.fontFamilyFallback,
      );
    }
  }
  return null;
}

/// Generic CSS font-family keywords mapped to platform font families.
const _genericFontFamilies = <String, String>{
  'serif': 'serif',
  'sans-serif': 'sans-serif',
  'monospace': 'monospace',
  'cursive': 'cursive',
  'fantasy': 'fantasy',
  'system-ui': 'system-ui',
};

/// Common web/forum font names mapped to GoogleFonts builder functions.
/// Each builder merges the requested family into an existing [TextStyle].
final _googleFontBuilders = <String, TextStyle Function(TextStyle)>{
  // Sans-serif
  'arial': (s) => GoogleFonts.roboto(textStyle: s),
  'helvetica': (s) => GoogleFonts.roboto(textStyle: s),
  'helvetica neue': (s) => GoogleFonts.roboto(textStyle: s),
  'verdana': (s) => GoogleFonts.openSans(textStyle: s),
  'tahoma': (s) => GoogleFonts.openSans(textStyle: s),
  'trebuchet ms': (s) => GoogleFonts.openSans(textStyle: s),
  'calibri': (s) => GoogleFonts.lato(textStyle: s),
  'segoe ui': (s) => GoogleFonts.lato(textStyle: s),
  'roboto': (s) => GoogleFonts.roboto(textStyle: s),
  'open sans': (s) => GoogleFonts.openSans(textStyle: s),
  'lato': (s) => GoogleFonts.lato(textStyle: s),
  'montserrat': (s) => GoogleFonts.montserrat(textStyle: s),
  'nunito': (s) => GoogleFonts.nunito(textStyle: s),
  'poppins': (s) => GoogleFonts.poppins(textStyle: s),
  'inter': (s) => GoogleFonts.inter(textStyle: s),
  'oswald': (s) => GoogleFonts.oswald(textStyle: s),
  'raleway': (s) => GoogleFonts.raleway(textStyle: s),
  'ubuntu': (s) => GoogleFonts.ubuntu(textStyle: s),
  'noto sans': (s) => GoogleFonts.notoSans(textStyle: s),
  'source sans pro': (s) => GoogleFonts.sourceCodePro(textStyle: s),

  // Serif
  'times new roman': (s) => GoogleFonts.playfairDisplay(textStyle: s),
  'times': (s) => GoogleFonts.playfairDisplay(textStyle: s),
  'georgia': (s) => GoogleFonts.merriweather(textStyle: s),
  'garamond': (s) => GoogleFonts.ebGaramond(textStyle: s),
  'palatino': (s) => GoogleFonts.lora(textStyle: s),
  'palatino linotype': (s) => GoogleFonts.lora(textStyle: s),
  'book antiqua': (s) => GoogleFonts.lora(textStyle: s),
  'cambria': (s) => GoogleFonts.merriweather(textStyle: s),
  'playfair display': (s) => GoogleFonts.playfairDisplay(textStyle: s),
  'merriweather': (s) => GoogleFonts.merriweather(textStyle: s),
  'eb garamond': (s) => GoogleFonts.ebGaramond(textStyle: s),
  'lora': (s) => GoogleFonts.lora(textStyle: s),
  'noto serif': (s) => GoogleFonts.notoSerif(textStyle: s),
  'pt serif': (s) => GoogleFonts.ptSerif(textStyle: s),
  'roboto slab': (s) => GoogleFonts.robotoSlab(textStyle: s),
  'source serif pro': (s) => GoogleFonts.sourceSerif4(textStyle: s),

  // Monospace
  'courier new': (s) => GoogleFonts.robotoMono(textStyle: s),
  'courier': (s) => GoogleFonts.robotoMono(textStyle: s),
  'consolas': (s) => GoogleFonts.sourceCodePro(textStyle: s),
  'lucida console': (s) => GoogleFonts.robotoMono(textStyle: s),
  'monaco': (s) => GoogleFonts.sourceCodePro(textStyle: s),
  'andale mono': (s) => GoogleFonts.robotoMono(textStyle: s),
  'roboto mono': (s) => GoogleFonts.robotoMono(textStyle: s),
  'source code pro': (s) => GoogleFonts.sourceCodePro(textStyle: s),
  'fira code': (s) => GoogleFonts.firaCode(textStyle: s),
  'jetbrains mono': (s) => GoogleFonts.jetBrainsMono(textStyle: s),

  // Display / Decorative
  'impact': (s) => GoogleFonts.oswald(textStyle: s),
  'comic sans ms': (s) => GoogleFonts.comicNeue(textStyle: s),
  'comic sans': (s) => GoogleFonts.comicNeue(textStyle: s),
  'comic neue': (s) => GoogleFonts.comicNeue(textStyle: s),
  'lobster': (s) => GoogleFonts.lobster(textStyle: s),
  'pacifico': (s) => GoogleFonts.pacifico(textStyle: s),
  'dancing script': (s) => GoogleFonts.dancingScript(textStyle: s),
};

/// Returns [color] if it has reasonable contrast against the current theme's
/// surface, otherwise returns the theme's body text color.
Color _contrastSafeColor(BuildContext context, Color color) {
  final theme = Theme.of(context);
  final surface = theme.colorScheme.surface;
  final ratio = _contrastRatio(color, surface);
  if (ratio < 2.5) {
    return theme.textTheme.bodyMedium?.color ?? theme.colorScheme.onSurface;
  }
  return color;
}

double _contrastRatio(Color a, Color b) {
  final la = _relativeLuminance(a);
  final lb = _relativeLuminance(b);
  final brighter = la > lb ? la : lb;
  final darker = la > lb ? lb : la;
  return (brighter + 0.05) / (darker + 0.05);
}

double _relativeLuminance(Color c) {
  double ch(int v) {
    final s = v / 255.0;
    return s <= 0.03928 ? s / 12.92 : pow((s + 0.055) / 1.055, 2.4).toDouble();
  }

  // ignore: deprecated_member_use
  final r = ch(c.red);
  // ignore: deprecated_member_use
  final g = ch(c.green);
  // ignore: deprecated_member_use
  final b = ch(c.blue);
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

/// Wraps a child widget with mouse hover (for the URL bar) and tap handling.
class _LinkWrapper extends StatelessWidget {
  final String url;
  final VoidCallback onTap;
  final void Function(String? href) onHover;
  final Widget child;

  const _LinkWrapper({
    required this.url,
    required this.onTap,
    required this.onHover,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    // SelectionContainer.disabled prevents SelectionArea from claiming
    // the cursor (text/I-beam) over this region, so MouseRegion's click
    // cursor takes effect.
    return SelectionContainer.disabled(
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => onHover(url),
        onExit: (_) => onHover(null),
        child: GestureDetector(onTap: onTap, child: child),
      ),
    );
  }
}

/// Returns true if [el] contains only `<img>` elements and whitespace text.
bool _containsOnlyImages(dom.Element el) {
  for (final child in el.nodes) {
    if (child is dom.Text) {
      if (child.text.trim().isNotEmpty) return false;
    } else if (child is dom.Element) {
      if (child.localName?.toLowerCase() != 'img') return false;
    }
  }
  return el.nodes.any(
    (n) => n is dom.Element && n.localName?.toLowerCase() == 'img',
  );
}

/// Heuristic: does [url] likely point to an SVG image?
bool _isSvgUrl(String url) {
  try {
    final uri = Uri.parse(url);
    final path = uri.path.toLowerCase();
    if (path.endsWith('.svg')) return true;
    // img.shields.io always returns SVGs.
    if (uri.host.contains('shields.io')) return true;
    return false;
  } catch (_) {
    return false;
  }
}

String _resolveUrl(String url, String? baseUrl) {
  if (url.startsWith('http://') || url.startsWith('https://')) return url;
  if (baseUrl == null) return url;
  try {
    final base = Uri.parse(baseUrl);
    return base.resolve(url).toString();
  } catch (_) {
    return url;
  }
}

class _InlineImage extends StatefulWidget {
  final String url;
  final String? alt;

  /// When true, clicking the image toggles between constrained and full 1:1.
  /// Set to false when the image is inside a link (link tap takes priority).
  final bool canToggleFullSize;

  const _InlineImage({
    required this.url,
    this.alt,
    this.canToggleFullSize = false,
  });

  @override
  State<_InlineImage> createState() => _InlineImageState();
}

class _InlineImageState extends State<_InlineImage> {
  bool _isFullSize = false;

  static const _constrainedBox = BoxConstraints(maxWidth: 640, maxHeight: 480);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_isSvgUrl(widget.url)) {
      return _svgFallback(theme);
    }

    final image = Image.network(
      widget.url,
      fit: _isFullSize ? BoxFit.none : BoxFit.scaleDown,
      errorBuilder: (_, _, _) => _errorFallback(theme),
      loadingBuilder: (ctx, child, progress) {
        if (progress == null) return child;
        return const SizedBox(
          width: 40,
          height: 40,
          child: Center(
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      },
    );

    Widget result;
    if (_isFullSize) {
      // Full 1:1 — no constraints, allow horizontal scroll for wide images.
      result = SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: image,
      );
    } else {
      result = ConstrainedBox(constraints: _constrainedBox, child: image);
    }

    if (widget.canToggleFullSize) {
      // SelectionContainer.disabled prevents SelectableText.rich from
      // swallowing taps on this WidgetSpan (same fix as _LinkWrapper).
      result = SelectionContainer.disabled(
        child: MouseRegion(
          cursor:
              _isFullSize ? SystemMouseCursors.zoomOut : SystemMouseCursors.zoomIn,
          child: GestureDetector(
            onTap: () => setState(() => _isFullSize = !_isFullSize),
            child: result,
          ),
        ),
      );
    }

    return result;
  }

  Widget _svgFallback(ThemeData theme) {
    // Show a compact badge with alt text or a generic label.
    final alt = widget.alt;
    final label = (alt != null && alt.isNotEmpty) ? alt : 'SVG Image';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: theme.dividerColor, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.image_outlined, size: 14, color: theme.hintColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(color: theme.hintColor),
          ),
        ],
      ),
    );
  }

  Widget _errorFallback(ThemeData theme) {
    final alt = widget.alt;
    if (alt != null && alt.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2.0),
        child: Text(
          alt,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.hintColor,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Icon(
        Icons.broken_image_outlined,
        size: 24,
        color: theme.disabledColor,
      ),
    );
  }
}
