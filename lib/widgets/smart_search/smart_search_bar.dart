import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:trios/widgets/filter_pill.dart';
import 'package:trios/widgets/smart_search/search_dsl_field.dart';
import 'package:trios/widgets/smart_search/search_dsl_parser.dart';

class SmartSearchBar extends StatefulWidget {
  final List<SearchFieldMeta> fields;
  final List<String> recentHistory;
  final ValueChanged<String> onChanged;

  /// Called when the user explicitly submits a query (Enter key or history
  /// selection). Use this to persist the query to search history.
  final VoidCallback? onSubmitted;
  final String initialValue;
  final String hintText;

  const SmartSearchBar({
    super.key,
    required this.fields,
    required this.recentHistory,
    required this.onChanged,
    this.onSubmitted,
    this.initialValue = '',
    this.hintText = 'field:value — Space to commit',
  });

  @override
  State<SmartSearchBar> createState() => _SmartSearchBarState();
}

enum _SuggestionKind { fieldName, fieldValue, historyEntry }

class _Suggestion {
  final _SuggestionKind kind;
  final String label;
  final String insertText;
  final String? subtitle;

  const _Suggestion({
    required this.kind,
    required this.label,
    required this.insertText,
    this.subtitle,
  });
}

class _SmartSearchBarState extends State<SmartSearchBar> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  List<FieldToken> _committedPills = [];
  int _selectedPillIndex = -1; // -1 = focus is in the text field
  List<_Suggestion> _suggestions = [];
  int _highlightedIndex = -1;
  OverlayEntry? _overlayEntry;
  String _previousText = '';
  bool _isFocused = false;
  bool _isSelectingSuggestion = false;
  Map<String, SearchFieldMeta> _fieldsByKey = const {};

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode(onKeyEvent: _handleKeyEvent);
    _controller = TextEditingController();
    _rebuildFieldsByKey();
    _initFromQuery(widget.initialValue); // also adds _onTextChange listener
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(SmartSearchBar old) {
    super.didUpdateWidget(old);
    if (!identical(old.fields, widget.fields)) {
      _rebuildFieldsByKey();
    }
    // Only reinitialize when the new value is an external reset, not an echo
    // of the user's own typing that already updated _fullQuery.
    if (old.initialValue != widget.initialValue &&
        widget.initialValue != _fullQuery) {
      _initFromQuery(widget.initialValue);
    }
    if (old.recentHistory != widget.recentHistory && _isFocused) {
      // Defer: didUpdateWidget runs during the build phase, and _updateSuggestions
      // calls markNeedsBuild on the overlay entry, which is illegal mid-build.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _isFocused) _updateSuggestions();
      });
    }
  }

  void _rebuildFieldsByKey() {
    _fieldsByKey = {for (final f in widget.fields) f.key: f};
  }

  void _setTextSilently(String text, {bool moveCursorToEnd = true}) {
    _controller.removeListener(_onTextChange);
    _controller.text = text;
    if (moveCursorToEnd) {
      _controller.selection = TextSelection.collapsed(offset: text.length);
    }
    _previousText = text;
    _controller.addListener(_onTextChange);
  }

  @override
  void dispose() {
    _hideOverlay();
    _controller.removeListener(_onTextChange);
    _focusNode.removeListener(_onFocusChange);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _initFromQuery(String query) {
    final parsed = SearchDslParser.parse(query);
    final pills = parsed.tokens.whereType<FieldToken>().toList();
    final text = parsed.tokens
        .whereType<TextToken>()
        .map((t) => t.text)
        .join(' ');

    _setTextSilently(text, moveCursorToEnd: false);

    if (mounted) {
      setState(() => _committedPills = pills);
    } else {
      _committedPills = pills;
    }
  }

  String get _fullQuery {
    final parts = [
      ..._committedPills.map((t) => t.toQueryString()),
      if (_controller.text.trim().isNotEmpty) _controller.text.trim(),
    ];
    return parts.join(' ');
  }

  void _emitQuery() => widget.onChanged(_fullQuery);

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    // Pill selection mode: a committed pill is "focused" for keyboard nav.
    if (_selectedPillIndex >= 0) {
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        setState(() {
          _selectedPillIndex = (_selectedPillIndex - 1).clamp(
            0,
            _committedPills.length - 1,
          );
        });
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        setState(() {
          if (_selectedPillIndex >= _committedPills.length - 1) {
            _selectedPillIndex = -1; // back into text field
            _controller.selection = const TextSelection.collapsed(offset: 0);
          } else {
            _selectedPillIndex++;
          }
        });
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.backspace ||
          event.logicalKey == LogicalKeyboardKey.delete) {
        final idx = _selectedPillIndex;
        final isDelete = event.logicalKey == LogicalKeyboardKey.delete;
        setState(() {
          _committedPills = [
            ..._committedPills.sublist(0, idx),
            ..._committedPills.sublist(idx + 1),
          ];
          if (_committedPills.isEmpty) {
            _selectedPillIndex = -1;
          } else if (isDelete) {
            if (idx < _committedPills.length) {
              _selectedPillIndex = idx;
            } else {
              _selectedPillIndex = -1;
              _controller.selection =
                  const TextSelection.collapsed(offset: 0);
            }
          } else {
            _selectedPillIndex = (idx - 1).clamp(
              0,
              _committedPills.length - 1,
            );
          }
        });
        _emitQuery();
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        setState(() => _selectedPillIndex = -1);
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.home) {
        setState(() => _selectedPillIndex = 0);
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.end) {
        setState(() => _selectedPillIndex = -1);
        _controller.selection = TextSelection.collapsed(
          offset: _controller.text.length,
        );
        return KeyEventResult.handled;
      }
      // Any printable character returns focus to the text field and lets
      // the keystroke be typed normally.
      final ch = event.character;
      if (ch != null && ch.isNotEmpty && ch.codeUnitAt(0) >= 0x20) {
        setState(() => _selectedPillIndex = -1);
        _controller.selection = const TextSelection.collapsed(offset: 0);
        return KeyEventResult.ignored;
      }
      return KeyEventResult.ignored;
    }

    // In text field: backspace / left arrow at the very start jumps onto the
    // last committed pill.
    if (_committedPills.isNotEmpty &&
        _controller.selection.isCollapsed &&
        _controller.selection.baseOffset == 0 &&
        (event.logicalKey == LogicalKeyboardKey.backspace ||
            event.logicalKey == LogicalKeyboardKey.arrowLeft)) {
      _hideOverlay();
      setState(() {
        _selectedPillIndex = _committedPills.length - 1;
        _suggestions = [];
        _highlightedIndex = -1;
      });
      return KeyEventResult.handled;
    }

    if (_committedPills.isNotEmpty &&
        event.logicalKey == LogicalKeyboardKey.home) {
      _hideOverlay();
      setState(() {
        _selectedPillIndex = 0;
        _suggestions = [];
        _highlightedIndex = -1;
      });
      return KeyEventResult.handled;
    }

    if (_suggestions.isNotEmpty) {
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        setState(() {
          _highlightedIndex = (_highlightedIndex + 1).clamp(
            0,
            _suggestions.length - 1,
          );
        });
        _overlayEntry?.markNeedsBuild();
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        setState(() {
          _highlightedIndex = (_highlightedIndex - 1).clamp(
            0,
            _suggestions.length - 1,
          );
        });
        _overlayEntry?.markNeedsBuild();
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.enter ||
          event.logicalKey == LogicalKeyboardKey.tab) {
        if (_highlightedIndex >= 0 && _highlightedIndex < _suggestions.length) {
          _acceptSuggestion(_suggestions[_highlightedIndex]);
          return KeyEventResult.handled;
        }
      }
    }

    if (event.logicalKey == LogicalKeyboardKey.enter) {
      widget.onSubmitted?.call();
      return KeyEventResult.ignored;
    }

    if (event.logicalKey == LogicalKeyboardKey.escape) {
      _hideOverlay();
      setState(() {
        _suggestions = [];
        _highlightedIndex = -1;
      });
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _onFocusChange() {
    final focused = _focusNode.hasFocus;
    if (focused == _isFocused) return;
    setState(() => _isFocused = focused);
    if (focused) {
      _updateSuggestions();
    } else {
      // Defer via microtask: on desktop, pointer-down unfocuses the TextField
      // before the InkWell's onTapDown fires. Deferring lets onTapDown set
      // _isSelectingSuggestion = true before we decide to close.
      Future.microtask(() {
        if (!_isSelectingSuggestion && mounted) {
          _hideOverlay();
          setState(() {
            _suggestions = [];
            _highlightedIndex = -1;
            _selectedPillIndex = -1;
          });
        }
      });
    }
  }

  bool _isInsideOpenQuote(String text) {
    var inQuote = false;
    for (var i = 0; i < text.length; i++) {
      if (text[i] == '"') inQuote = !inQuote;
    }
    return inQuote;
  }

  void _onTextChange() {
    final newText = _controller.text;

    if (newText.endsWith(' ') && !_previousText.endsWith(' ')) {
      // Don't commit while the user is typing inside an open quoted value.
      if (!_isInsideOpenQuote(newText.trimRight())) {
        _tryCommitLastToken();
      }
    }

    _previousText = _controller.text;
    _updateSuggestions();
    _emitQuery();
  }

  void _tryCommitLastToken() {
    final text = _controller.text.trimRight();
    if (text.isEmpty) return;

    final parts = SearchDslParser.splitRespectingQuotes(text);
    if (parts.isEmpty) return;
    final lastWord = parts.last;
    if (lastWord.isEmpty) return;

    final parsed = SearchDslParser.parse(lastWord);
    if (parsed.tokens.length == 1 && parsed.tokens.first is FieldToken) {
      final token = parsed.tokens.first as FieldToken;
      final remaining = parts.sublist(0, parts.length - 1).join(' ');
      _setTextSilently(remaining.isEmpty ? '' : '$remaining ');
      setState(() => _committedPills = [..._committedPills, token]);
    }
  }

  void _removePill(int index) {
    setState(() {
      _committedPills = [
        ..._committedPills.sublist(0, index),
        ..._committedPills.sublist(index + 1),
      ];
      if (_selectedPillIndex >= _committedPills.length) {
        _selectedPillIndex = _committedPills.isEmpty
            ? -1
            : _committedPills.length - 1;
      } else if (_selectedPillIndex > index) {
        _selectedPillIndex--;
      }
    });
    _emitQuery();
  }

  void _clearAll() {
    setState(() {
      _committedPills = [];
      _suggestions = [];
      _highlightedIndex = -1;
      _selectedPillIndex = -1;
    });
    _setTextSilently('');
    _hideOverlay();
    _emitQuery();
  }

  void _updateSuggestions() {
    final text = _controller.text;
    final parts = SearchDslParser.splitRespectingQuotes(text);
    final currentToken = parts.isEmpty ? '' : parts.last;

    List<_Suggestion> suggestions;

    if (currentToken.isEmpty && text.trim().isEmpty && _isFocused) {
      suggestions = widget.recentHistory
          .map(
            (h) => _Suggestion(
              kind: _SuggestionKind.historyEntry,
              label: h,
              insertText: h,
            ),
          )
          .toList();
    } else if (!currentToken.contains(':')) {
      final negated = currentToken.startsWith('-');
      final negPrefix = negated ? '-' : '';
      final queryPart = negated ? currentToken.substring(1) : currentToken;
      final query = queryPart.toLowerCase();
      suggestions = widget.fields
          .where(
            (f) =>
                (query.isEmpty || f.key.contains(query)) &&
                (!negated || f.supportsNegation),
          )
          .map(
            (f) => _Suggestion(
              kind: _SuggestionKind.fieldName,
              label: negated ? '-${f.key}' : f.key,
              subtitle: f.description,
              insertText: '$negPrefix${f.key}:',
            ),
          )
          .toList();
    } else {
      final colonIdx = currentToken.indexOf(':');
      var fieldKey = currentToken.substring(0, colonIdx);
      final negated = fieldKey.startsWith('-');
      if (negated) fieldKey = fieldKey.substring(1);
      final negPrefix = negated ? '-' : '';
      final afterColon = currentToken.substring(colonIdx + 1);
      final opMatch = RegExp(r'^(>=|<=|>|<)').firstMatch(afterColon);
      final opPart = opMatch?.group(0) ?? '';
      // Strip an opening quote so `field:"anti` still filters by `anti`.
      var valuePrefix = afterColon.substring(opPart.length).toLowerCase();
      if (valuePrefix.startsWith('"')) valuePrefix = valuePrefix.substring(1);

      final field = _fieldsByKey[fieldKey];
      if (field != null && (!negated || field.supportsNegation)) {
        final values = field.valueSuggestions();
        suggestions = values
            .where(
              (v) =>
                  valuePrefix.isEmpty || v.toLowerCase().contains(valuePrefix),
            )
            .map(
              (v) => _Suggestion(
                kind: _SuggestionKind.fieldValue,
                label: v,
                insertText:
                    '$negPrefix$fieldKey:$opPart${v.contains(' ') ? '"$v"' : v}',
              ),
            )
            .toList();
      } else {
        suggestions = [];
      }
    }

    final unchanged = _suggestionsEqual(_suggestions, suggestions);
    if (!unchanged) {
      setState(() {
        _suggestions = suggestions;
        if (_highlightedIndex >= suggestions.length) _highlightedIndex = -1;
      });
    } else if (_highlightedIndex >= suggestions.length) {
      setState(() => _highlightedIndex = -1);
    }

    if (suggestions.isNotEmpty && _isFocused && _selectedPillIndex < 0) {
      _showOrUpdateOverlay();
    } else {
      _hideOverlay();
    }
  }

  static bool _suggestionsEqual(List<_Suggestion> a, List<_Suggestion> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].kind != b[i].kind ||
          a[i].label != b[i].label ||
          a[i].insertText != b[i].insertText) {
        return false;
      }
    }
    return true;
  }

  void _acceptSuggestion(_Suggestion suggestion) {
    if (suggestion.kind == _SuggestionKind.historyEntry) {
      _initFromQuery(suggestion.insertText);
      _emitQuery();
      widget.onSubmitted?.call();
      _hideOverlay();
      setState(() {
        _suggestions = [];
        _highlightedIndex = -1;
      });
      _focusNode.requestFocus();
      return;
    }

    final text = _controller.text;
    final spaceIdx = text.lastIndexOf(' ');
    final prefix = spaceIdx < 0 ? '' : text.substring(0, spaceIdx + 1);

    if (suggestion.kind == _SuggestionKind.fieldValue) {
      final parsed = SearchDslParser.parse(suggestion.insertText);
      if (parsed.tokens.length == 1 && parsed.tokens.first is FieldToken) {
        final token = parsed.tokens.first as FieldToken;
        _setTextSilently(prefix);
        setState(() {
          _committedPills = [..._committedPills, token];
          _suggestions = [];
          _highlightedIndex = -1;
        });
        _hideOverlay();
        _emitQuery();
        _focusNode.requestFocus();
        return;
      }
    }

    // Field name selected — insert and keep typing for value
    _setTextSilently('$prefix${suggestion.insertText}');
    _updateSuggestions();
    _emitQuery();
  }

  void _showOrUpdateOverlay() {
    if (_overlayEntry != null) {
      _overlayEntry!.markNeedsBuild();
      return;
    }
    final overlay = Overlay.of(context);
    _overlayEntry = OverlayEntry(builder: _buildOverlayContent);
    overlay.insert(_overlayEntry!);
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Widget _buildOverlayContent(BuildContext overlayCtx) {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.attached) {
      return const SizedBox.shrink();
    }

    final barSize = renderBox.size;
    final barPos = renderBox.localToGlobal(Offset.zero);
    final screenH = MediaQuery.of(context).size.height;
    const maxDropdownH = 280.0;
    final spaceBelow = screenH - barPos.dy - barSize.height;
    final flipAbove = spaceBelow < maxDropdownH + 8;
    final top = flipAbove
        ? barPos.dy - maxDropdownH - 4
        : barPos.dy + barSize.height + 4;

    return Positioned(
      left: barPos.dx,
      top: top,
      width: max(barSize.width, 280),
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: maxDropdownH),
          child: _buildDropdownList(),
        ),
      ),
    );
  }

  Widget _buildDropdownList() {
    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: _suggestions.length,
      itemBuilder: (ctx, index) {
        final s = _suggestions[index];
        final isHighlighted = index == _highlightedIndex;
        return Material(
          color: isHighlighted
              ? Theme.of(context).colorScheme.primaryContainer
              : Colors.transparent,
          child: InkWell(
            onTapDown: (_) => _isSelectingSuggestion = true,
            onTapCancel: () => _isSelectingSuggestion = false,
            onTap: () {
              _isSelectingSuggestion = false;
              _acceptSuggestion(s);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                spacing: 8,
                children: [
                  Icon(
                    _suggestionIcon(s.kind),
                    size: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          s.label,
                          style: Theme.of(context).textTheme.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (s.subtitle != null)
                          Text(
                            s.subtitle!,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                  fontSize: 10,
                                ),
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  IconData _suggestionIcon(_SuggestionKind kind) => switch (kind) {
    _SuggestionKind.fieldName => Icons.label_outline,
    _SuggestionKind.fieldValue => Icons.check_circle_outline,
    _SuggestionKind.historyEntry => Icons.history,
  };

  void _showInfoPanel() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Search Field Reference'),
        content: SizedBox(
          width: 440,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SelectableText(
                  'Syntax: field:value   field:>value   -field:value   field:"multi word"',
                  style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                for (final f in widget.fields) _buildFieldInfoRow(ctx, f),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldInfoRow(BuildContext ctx, SearchFieldMeta f) {
    final ops = [
      'field:value',
      if (f.supportsNumeric) 'field:>value  field:<value',
      if (f.supportsNegation) '-field:value (exclude)',
    ].join('   ');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            spacing: 8,
            children: [
              SelectableText(
                f.key,
                style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
              Expanded(
                child: Text(
                  f.description,
                  style: Theme.of(ctx).textTheme.bodySmall,
                ),
              ),
            ],
          ),
          Text(
            ops,
            style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
              color: Theme.of(ctx).colorScheme.onSurfaceVariant,
              fontFamily: 'monospace',
            ),
          ),
          const Divider(height: 8),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasSomething =
        _committedPills.isNotEmpty || _controller.text.isNotEmpty;

    return Row(
      mainAxisSize: MainAxisSize.max,
      children: [
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => _focusNode.requestFocus(),
            child: MouseRegion(
              cursor: SystemMouseCursors.text,
              child: Container(
            height: 34,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const SizedBox(width: 8),
                Icon(
                  Icons.search,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: LayoutBuilder(
                    builder: (ctx, constraints) => SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      reverse: true,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: constraints.maxWidth,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ..._committedPills.asMap().entries.map(
                              (e) => _buildPill(
                                theme,
                                e.key,
                                e.value,
                                selected: e.key == _selectedPillIndex,
                              ),
                            ),
                            IntrinsicWidth(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  minWidth: 120,
                                ),
                                child: TextField(
                                  controller: _controller,
                                  focusNode: _focusNode,
                                  onSubmitted: (_) =>
                                      widget.onSubmitted?.call(),
                                  decoration: InputDecoration(
                                    hintText: _committedPills.isEmpty
                                        ? widget.hintText
                                        : null,
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding:
                                        const EdgeInsets.symmetric(
                                          vertical: 8,
                                          horizontal: 4,
                                        ),
                                  ),
                                  style: theme.textTheme.bodySmall,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (hasSomething)
                  IconButton(
                    icon: const Icon(Icons.clear, size: 16),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 28,
                      minHeight: 28,
                    ),
                    tooltip: 'Clear search',
                    onPressed: _clearAll,
                  ),
                const SizedBox(width: 2),
              ],
            ),
          ),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.info_outline, size: 18),
          tooltip: 'View search field reference',
          padding: const EdgeInsets.all(6),
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          onPressed: _showInfoPanel,
        ),
      ],
    );
  }

  Widget _buildPill(
    ThemeData theme,
    int index,
    FieldToken token, {
    bool selected = false,
  }) {
    final opStr = token.operator.symbol;
    final label = token.negated
        ? '-${token.key}:$opStr${token.value}'
        : '${token.key}:$opStr${token.value}';
    final pill = FilterPill(
      label: label,
      backgroundColor: token.negated
          ? theme.colorScheme.errorContainer
          : theme.cardColor,
      foregroundColor: token.negated
          ? theme.colorScheme.onErrorContainer
          : theme.colorScheme.onSurface,
      deleteTooltip: 'Remove "$label" filter',
      onDeleted: () => _removePill(index),
    );
    return GestureDetector(
      onTap: () {
        setState(() => _selectedPillIndex = index);
        _hideOverlay();
        _focusNode.requestFocus();
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: pill,
      ),
    );
  }
}
