import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:trios/bug_report/screenshot_editor.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/utils/logging.dart';
import 'package:trios/widgets/checkbox_with_label.dart';
import 'package:trios/widgets/moving_tooltip.dart';
import 'package:trios/widgets/snackbar.dart';

/// What the user has entered so far. Kept between openings of the dialog, so
/// closing it or retaking the screenshot doesn't lose anything.
class _BugReportDraft {
  final description = TextEditingController();
  final name = TextEditingController();
  final email = TextEditingController();
  var includeScreenshot = true;
  var includeModList = true;
  BugReportScreenshot? screenshot;
  var marks = <ScreenshotMark>[];

  void setScreenshot(BugReportScreenshot? newScreenshot) {
    screenshot = newScreenshot;
    marks = [];
    if (newScreenshot != null) includeScreenshot = true;
  }

  void clear() {
    description.clear();
    name.clear();
    email.clear();
    includeScreenshot = true;
    includeModList = true;
    setScreenshot(null);
  }
}

final _draft = _BugReportDraft();

enum _DialogResult { cancelled, sent, retake }

/// Takes a screenshot of the app, then opens the bug report dialog.
Future<void> showBugReportDialog(BuildContext context) async {
  // The toolbar holding the button can be rebuilt while the user is retaking
  // the screenshot, so use the navigator, which stays around.
  final navigator = Navigator.of(context, rootNavigator: true);
  _draft.setScreenshot(await _captureScreenshot());

  while (navigator.mounted) {
    final navigatorContext = navigator.context;
    if (!navigatorContext.mounted) return;
    final result = await showDialog<_DialogResult>(
      context: navigatorContext,
      // Escape or a click outside would close the form by accident.
      barrierDismissible: false,
      builder: (_) => _BugReportDialog(draft: _draft),
    );
    switch (result) {
      case _DialogResult.retake:
        await _retakeScreenshot(navigator);
      case _DialogResult.sent:
        _draft.clear();
        return;
      case _DialogResult.cancelled || null:
        return;
    }
  }
}

Future<BugReportScreenshot?> _captureScreenshot() async {
  try {
    final attachment = await SentryFlutter.captureScreenshot();
    if (attachment == null) return null;
    return await BugReportScreenshot.fromBytes(await attachment.bytes);
  } catch (e, st) {
    Fimber.w("Unable to take a bug report screenshot.", ex: e, stacktrace: st);
    return null;
  }
}

/// Shows a bar at the top of the window while the user goes to the screen they
/// want, then takes the screenshot. Keeps the old screenshot if they cancel.
Future<void> _retakeScreenshot(NavigatorState navigator) async {
  final overlay = navigator.overlay;
  if (overlay == null) return;

  final clicked = Completer<bool>();
  void finish(bool takeScreenshot) {
    if (!clicked.isCompleted) clicked.complete(takeScreenshot);
  }

  final bar = OverlayEntry(
    builder: (_) =>
        _RetakeBar(onTake: () => finish(true), onCancel: () => finish(false)),
  );
  overlay.insert(bar);
  final takeScreenshot = await clicked.future;
  bar.remove();
  if (!takeScreenshot) return;

  // Wait for the bar to disappear, so it isn't in the screenshot.
  await WidgetsBinding.instance.endOfFrame;
  _draft.setScreenshot(await _captureScreenshot());
}

class _RetakeBar extends StatelessWidget {
  final VoidCallback onTake;
  final VoidCallback onCancel;

  const _RetakeBar({required this.onTake, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Center(
        child: Material(
          elevation: 8,
          borderRadius: .circular(8),
          color: theme.colorScheme.surfaceContainerHigh,
          child: Padding(
            padding: const .symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisSize: .min,
              spacing: 16,
              children: [
                const Text(
                  "Lets you navigate to the bug before clicking Take Screenshot.",
                ),
                TextButton(
                  onPressed: onTake,
                  child: const Text("Take Screenshot"),
                ),
                TextButton(onPressed: onCancel, child: const Text("Cancel")),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BugReportDialog extends StatefulWidget {
  final _BugReportDraft draft;

  const _BugReportDialog({required this.draft});

  @override
  State<_BugReportDialog> createState() => _BugReportDialogState();
}

class _BugReportDialogState extends State<_BugReportDialog> {
  final _formKey = GlobalKey<FormState>();
  var _isSending = false;

  _BugReportDraft get draft => widget.draft;

  Future<void> _editScreenshot(BugReportScreenshot screenshot) async {
    final marks = await showScreenshotEditor(
      context,
      screenshot: screenshot,
      marks: draft.marks,
    );
    if (marks != null && mounted) setState(() => draft.marks = marks);
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSending = true);

    try {
      final screenshot = draft.screenshot;
      final hint = screenshot != null && draft.includeScreenshot
          ? Hint.withScreenshot(
              SentryAttachment.fromScreenshotData(
                await flattenScreenshot(screenshot, draft.marks),
              ),
            )
          : Hint();
      if (!draft.includeModList) hint.set(excludeModListHintKey, true);

      String? orNull(String text) => text.trim().isEmpty ? null : text.trim();
      final id = await Sentry.captureFeedback(
        SentryFeedback(
          message: draft.description.text.trim(),
          name: orNull(draft.name.text),
          contactEmail: orNull(draft.email.text),
        ),
        hint: hint,
      );
      if (id == const SentryId.empty()) {
        throw Exception("Sentry did not accept the bug report.");
      }

      if (!mounted) return;
      showSnackBar(
        context: context,
        content: const Text("Bug report sent. Thank you!"),
        type: SnackBarType.info,
      );
      Navigator.of(context).pop(_DialogResult.sent);
    } catch (e, st) {
      Fimber.w("Unable to send bug report.", ex: e, stacktrace: st);
      if (!mounted) return;
      setState(() => _isSending = false);
      showSnackBar(
        context: context,
        content: const Text("Couldn't send the bug report. Try again later."),
        type: SnackBarType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final smallText = theme.textTheme.bodySmall;

    return AlertDialog(
      title: const Text("Report a ${Constants.appName} Bug"),
      content: SizedBox(
        width: 640,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: .start,
              mainAxisSize: .min,
              spacing: 16,
              children: [
                const Text(
                  "This sends a report to the ${Constants.appName} dev. "
                  "${Constants.appName} is not associated with Fractal Softworks, "
                  "and can't help with the game, payments, license keys, or mods.",
                ),
                TextFormField(
                  controller: draft.description,
                  autofocus: true,
                  minLines: 4,
                  maxLines: 8,
                  decoration: const InputDecoration(
                    labelText: "Description (required)",
                    hintText: "What were you doing, what happened, what did you expect to happen? Please be specific about any mods or other info involved.",
                    alignLabelWithHint: true,
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? "This is required."
                      : null,
                ),
                Row(
                  crossAxisAlignment: .start,
                  spacing: 16,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: draft.name,
                        decoration: const InputDecoration(
                          labelText: "Username (optional)",
                          hintText: "@YourUsername",
                          helperText:
                              "Your forum or Discord name, lets me follow up.",
                        ),
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: draft.email,
                        decoration: const InputDecoration(
                          labelText: "Email (optional)",
                          hintText: "you@email.com",
                        ),
                      ),
                    ),
                  ],
                ),
                _buildScreenshotSection(smallText),
                MovingTooltipWidget.text(
                  message: "Whether to send your modlist, including which mods are enabled/disabled.",
                  child: CheckboxWithLabel(
                    label: "Include mod list",
                    value: draft.includeModList,
                    onChanged: (value) =>
                        setState(() => draft.includeModList = value ?? true),
                  ),
                ),
                Text(
                  "Also sent: ${Constants.appName} version and anonymous hardware info (OS, RAM, screen size, etc).",
                  style: smallText,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSending
              ? null
              : () => Navigator.of(context).pop(_DialogResult.cancelled),
          child: const Text("Cancel"),
        ),
        TextButton(
          onPressed: _isSending ? null : _send,
          child: const Text("Send Report"),
        ),
      ],
    );
  }

  Widget _buildScreenshotSection(TextStyle? smallText) {
    final retakeButton = TextButton(
      onPressed: _isSending
          ? null
          : () => Navigator.of(context).pop(_DialogResult.retake),
      child: const Text("Retake"),
    );

    final screenshot = draft.screenshot;
    if (screenshot == null) {
      return Row(
        spacing: 8,
        children: [const Text("Unable to take a screenshot."), retakeButton],
      );
    }

    return Row(
      crossAxisAlignment: .start,
      spacing: 16,
      children: [
        InkWell(
          onTap: _isSending ? null : () => _editScreenshot(screenshot),
          child: SizedBox(
            width: 240,
            child: Opacity(
              opacity: draft.includeScreenshot ? 1 : 0.4,
              child: ScreenshotWithMarks(
                screenshot: screenshot,
                marks: draft.marks,
              ),
            ),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: .start,
            spacing: 8,
            children: [
              CheckboxWithLabel(
                label: "Include screenshot",
                value: draft.includeScreenshot,
                onChanged: (value) =>
                    setState(() => draft.includeScreenshot = value ?? true),
              ),
              Row(
                spacing: 8,
                children: [
                  TextButton(
                    onPressed: _isSending
                        ? null
                        : () => _editScreenshot(screenshot),
                    child: const Text("Edit"),
                  ),
                  retakeButton,
                ],
              ),
              Text(
                "Check the screenshot before sending. "
                "File paths on screen can include your PC username. "
                "Use Edit to hide anything private.",
                style: smallText,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
