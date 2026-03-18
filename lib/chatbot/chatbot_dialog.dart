import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'chatbot_controller.dart';
import 'chatbot_models.dart';

class ChatbotDialog extends ConsumerStatefulWidget {
  const ChatbotDialog({super.key});

  static void show(BuildContext context) {
    showDialog(context: context, builder: (context) => const ChatbotDialog());
  }

  @override
  ConsumerState<ChatbotDialog> createState() => _ChatbotDialogState();
}

class _ChatbotDialogState extends ConsumerState<ChatbotDialog> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  late final _focusNode = FocusNode(
    onKeyEvent: (node, event) {
      if (event is KeyDownEvent &&
          event.logicalKey == LogicalKeyboardKey.enter &&
          !HardwareKeyboard.instance.isShiftPressed) {
        _send();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    },
  );
  bool _isTyping = false;
  bool _showScrollToBottom = false;
  bool _isSendEnabled = false;
  final Map<DateTime, double> _waterUsage = {};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _textController.addListener(() {
      final enabled = _textController.text.trim().isNotEmpty;
      if (enabled != _isSendEnabled) {
        setState(() => _isSendEnabled = enabled);
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final isAtBottom =
        _scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 50;
    if (_showScrollToBottom == isAtBottom) {
      setState(() => _showScrollToBottom = !isAtBottom);
    }
  }

  void _send() {
    final text = _textController.text;
    if (text.trim().isEmpty || _isTyping) return;

    _textController.clear();
    // Keep focus on the text field
    _focusNode.requestFocus();

    setState(() => _isTyping = true);

    // Add user message to controller immediately so it shows in the list
    ref.read(chatbotControllerProvider.notifier).sendMessage(text);

    _scrollToBottom();

    final delaySecs = Random().nextInt(5) + 1;
    final delay = Duration(seconds: delaySecs);

    // Calculate water usage scaling with response time (joke stat)
    final liters = (delaySecs * 2.38) + Random().nextDouble() * 0.05;

    Future.delayed(delay, () {
      if (!mounted) return;
      // Tag the bot message with its water usage
      final history = ref.read(chatbotControllerProvider).history;
      if (history.isNotEmpty && history.last.sender == MessageSender.bot) {
        _waterUsage[history.last.timestamp] = liters;
      }
      setState(() => _isTyping = false);
      _focusNode.requestFocus();
      _scrollToBottom();
    });
  }

  void _sendPredefined(String text) {
    _textController.text = text;
    _send();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final conversation = ref.watch(chatbotControllerProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // When typing, hide the last bot message (it was already added by the controller)
    final visibleMessages = _isTyping && conversation.history.isNotEmpty
        ? conversation.history.sublist(
            0,
            conversation.history.length -
                (conversation.history.last.sender == MessageSender.bot ? 1 : 0),
          )
        : conversation.history;

    final isEmpty = conversation.history.isEmpty && !_isTyping;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 60, vertical: 40),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640, maxHeight: 720),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
              child: Row(
                spacing: 8,
                children: [
                  Icon(
                    Icons.auto_awesome,
                    color: colorScheme.primary,
                    size: 22,
                  ),
                  Text(
                    "Assistant",
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.insert_drive_file, size: 20),
                    tooltip: "Start a new chat",
                    onPressed: () {
                      ref.read(chatbotControllerProvider.notifier).clear();
                      setState(() => _isTyping = false);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    tooltip: "Close",
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Messages area
            Expanded(
              child: Stack(
                children: [
                  if (isEmpty)
                    _EmptyState(onSuggestionTap: _sendPredefined)
                  else
                    ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 16,
                      ),
                      itemCount: visibleMessages.length + (_isTyping ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (_isTyping && index == visibleMessages.length) {
                          return const _TypingIndicator();
                        }
                        final msg = visibleMessages[index];
                        return _ChatMessageView(
                          message: msg,
                          waterUsage: _waterUsage[msg.timestamp],
                        );
                      },
                    ),

                  // Scroll-to-bottom FAB
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: AnimatedScale(
                      scale: _showScrollToBottom ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: FloatingActionButton.small(
                        onPressed: _scrollToBottom,
                        elevation: 2,
                        child: const Icon(Icons.keyboard_arrow_down),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Input area
            Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Row(
                spacing: 8,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      focusNode: _focusNode,
                      decoration: InputDecoration(
                        hintText: "Message Assistant...",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(
                            color: colorScheme.outlineVariant,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(
                            color: colorScheme.primary,
                            width: 1.5,
                          ),
                        ),
                        filled: true,
                        fillColor: colorScheme.surfaceContainerLow,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      minLines: 1,
                      maxLines: 1,
                      keyboardType: TextInputType.multiline,
                      autofocus: true,
                    ),
                  ),
                  IconButton.filled(
                    icon: const Icon(Icons.arrow_upward, size: 20),
                    onPressed: _isSendEnabled && !_isTyping ? _send : null,
                    tooltip: "Send",
                    style: IconButton.styleFrom(
                      backgroundColor: _isSendEnabled && !_isTyping
                          ? colorScheme.primary
                          : colorScheme.surfaceContainerHighest,
                      foregroundColor: _isSendEnabled && !_isTyping
                          ? colorScheme.onPrimary
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty State
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  final void Function(String text) onSuggestionTap;

  const _EmptyState({required this.onSuggestionTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 8,
          children: [
            Icon(
              Icons.auto_awesome,
              size: 48,
              color: colorScheme.primary.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 8),
            Text(
              "How can I help?",
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              "Ask me about mods, settings, or troubleshooting.",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                ActionChip(
                  label: const Text("What can you do?"),
                  onPressed: () => onSuggestionTap("What can you do?"),
                ),
                ActionChip(
                  label: const Text("Help me with mods"),
                  onPressed: () => onSuggestionTap("Help me with mods"),
                ),
                ActionChip(
                  label: const Text("Troubleshoot"),
                  onPressed: () => onSuggestionTap("Troubleshoot"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Chat Message View
// ---------------------------------------------------------------------------

class _ChatMessageView extends StatefulWidget {
  final ChatMessage message;
  final double? waterUsage;

  const _ChatMessageView({required this.message, this.waterUsage});

  @override
  State<_ChatMessageView> createState() => _ChatMessageViewState();
}

class _ChatMessageViewState extends State<_ChatMessageView> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isUser = widget.message.sender == MessageSender.user;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final timeStr = DateFormat.jm().format(widget.message.timestamp);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: isUser
            ? _buildUserMessage(theme, colorScheme, timeStr)
            : _buildBotMessage(theme, colorScheme, timeStr),
      ),
    );
  }

  Widget _buildBotMessage(
    ThemeData theme,
    ColorScheme colorScheme,
    String timeStr,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 12,
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: colorScheme.primaryContainer,
          child: Icon(
            Icons.auto_awesome,
            size: 16,
            color: colorScheme.onPrimaryContainer,
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 4,
            children: [
              SelectableText(
                widget.message.text,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
              AnimatedOpacity(
                opacity: _isHovered ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 150),
                child: _MessageActions(
                  timeStr: timeStr,
                  text: widget.message.text,
                  waterUsageLiters: widget.waterUsage,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUserMessage(
    ThemeData theme,
    ColorScheme colorScheme,
    String timeStr,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      spacing: 4,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(18),
              ),
              child: SelectableText(
                widget.message.text,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ),
        ),
        AnimatedOpacity(
          opacity: _isHovered ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 150),
          child: Padding(
            padding: const EdgeInsets.only(right: 4),
            child: _MessageActions(
              timeStr: timeStr,
              text: widget.message.text,
              isUser: true,
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Message Actions (timestamp + copy)
// ---------------------------------------------------------------------------

class _MessageActions extends StatefulWidget {
  final String timeStr;
  final String text;
  final bool isUser;
  final double? waterUsageLiters;

  const _MessageActions({
    required this.timeStr,
    required this.text,
    this.isUser = false,
    this.waterUsageLiters,
  });

  @override
  State<_MessageActions> createState() => _MessageActionsState();
}

class _MessageActionsState extends State<_MessageActions> {
  bool _copied = false;

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: widget.text));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: widget.isUser
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      spacing: 4,
      children: [
        Text(
          widget.timeStr,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontSize: 11,
          ),
        ),
        if (widget.waterUsageLiters != null)
          Text(
            "\u00b7 ${widget.waterUsageLiters!.toStringAsFixed(2)}L H\u2082O used",
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              fontSize: 11,
            ),
          ),
        SizedBox(
          width: 24,
          height: 24,
          child: IconButton(
            icon: Icon(
              _copied ? Icons.check : Icons.copy_outlined,
              size: 14,
              color: _copied
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
            onPressed: _copyToClipboard,
            padding: EdgeInsets.zero,
            tooltip: _copied ? "Copied!" : "Copy",
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Typing Indicator
// ---------------------------------------------------------------------------

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: colorScheme.primaryContainer,
            child: Icon(
              Icons.auto_awesome,
              size: 16,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return Row(
                  spacing: 4,
                  children: List.generate(3, (i) {
                    final delay = i * 0.2;
                    final t = ((_controller.value - delay) % 1.0).clamp(
                      0.0,
                      1.0,
                    );
                    // Sine wave for smooth pulsing
                    final opacity = 0.3 + 0.7 * sin(t * pi);
                    return Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colorScheme.onSurfaceVariant.withValues(
                          alpha: opacity,
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
