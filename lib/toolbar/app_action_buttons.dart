import 'dart:io';
import 'package:trios/trios/constants_theme.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:trios/models/version.dart';
import 'package:trios/rules_autofresh/rules_hotreload.dart';
import 'package:trios/themes/theme_manager.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/trios/navigation.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/logging.dart';
import 'package:trios/widgets/changelog_viewer.dart';
import 'package:trios/widgets/disable.dart';
import 'package:trios/widgets/moving_tooltip.dart';
import 'package:trios/widgets/svg_image_icon.dart';

import '../toolbar/app_right_toolbar.dart';
import '../trios/app_state.dart';
import '../utils/dialogs.dart';

/// Opens the Starsector game folder.
class GameFolderButton extends ConsumerWidget {
  const GameFolderButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var gameFolderPath = ref.watch(AppState.gameFolder).value?.path;
    if (gameFolderPath == null) return const SizedBox.shrink();
    return MovingTooltipWidget.text(
      message: "Open Starsector folder",
      child: IconButton(
        icon: const SvgImageIcon("assets/images/icon-folder-game.svg"),
        color: Theme.of(context).iconTheme.color,
        onPressed: () async {
          if (Platform.isMacOS) {
            try {
              final process = await Process.start('open', [
                "-R",
                "$gameFolderPath/Contents",
              ]);
              final result = await process.exitCode;
              if (result != 0) {
                Fimber.e("Error opening game folder: $result");
              }
            } catch (e, st) {
              Fimber.e("Error opening game folder: $e", ex: e, stacktrace: st);
            }
          } else {
            OpenFilex.open(gameFolderPath);
          }
        },
      ),
    );
  }
}

/// Opens the TriOS log file folder.
class LogFileButton extends StatelessWidget {
  const LogFileButton({super.key});

  @override
  Widget build(BuildContext context) {
    if (logFilePath == null) return const SizedBox.shrink();
    return MovingTooltipWidget.text(
      message: "Open ${Constants.appName} log file folder",
      child: IconButton(
        icon: const SvgImageIcon("assets/images/icon-file-debug.svg"),
        color: Theme.of(context).iconTheme.color,
        onPressed: () {
          try {
            logFilePath!.toFile().normalize.parent.path.openAsUriInBrowser();
          } catch (e, st) {
            Fimber.e("Error opening log file: $e", ex: e, stacktrace: st);
          }
        },
      ),
    );
  }
}

/// Sends a bug report via Sentry.
class BugReportButton extends ConsumerWidget {
  const BugReportButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(appSettings.select((s) => s.showReportBugButton))) {
      return const SizedBox.shrink();
    }
    final allowSentry =
        ref.watch(appSettings.select((s) => s.allowCrashReporting)) ?? false;
    return MovingTooltipWidget.text(
      message: allowSentry
          ? "Report a bug"
          : "You must enable 'Allow Crash Reporting' in Settings to report bugs."
                "\nThis icon may be hidden on the Settings page.",
      child: Disable(
        isEnabled: allowSentry,
        child: IconButton(
          icon: const Icon(Icons.bug_report),
          color: Theme.of(context).iconTheme.color,
          onPressed: () async {
            try {
              final screenshot = await SentryFlutter.captureScreenshot();
              SentryId id = Sentry.lastEventId;

              if (id == SentryId.empty()) {
                id = await Sentry.captureMessage(reportBugMagicString);
              }

              if (id == SentryId.empty()) {
                id = SentryId.newId();
              }

              if (!context.mounted) return;
              showAlertDialog(
                context,
                title: "Are you sure?",
                content:
                    "Continuing will send a bug report. You will be able to enter additional details about the issue on the next page.",
                actions: [
                  TextButton(
                    child: const Text('Cancel'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  TextButton(
                    child: const Text(
                      'I want to report a ${Constants.appName} bug',
                    ),
                    onPressed: () async {
                      Navigator.of(context).pop();
                      await Future.delayed(const Duration(milliseconds: 500));
                      if (!context.mounted) return;
                      showDialog(
                        context: context,
                        builder: (context) => Padding(
                          padding: const EdgeInsets.all(16),
                          child: SentryFeedbackWidget(
                            associatedEventId: id,
                            screenshot: screenshot,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              );
            } catch (e, st) {
              Fimber.e("Error opening log file: $e", ex: e, stacktrace: st);
            }
          },
        ),
      ),
    );
  }
}

/// Toggles between sidebar and top toolbar layout.
class ToolbarLayoutToggle extends ConsumerWidget {
  const ToolbarLayoutToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final useTopToolbar = ref.watch(appSettings.select((s) => s.useTopToolbar));
    return MovingTooltipWidget.text(
      message: useTopToolbar ? "Switch to sidebar layout" : "Switch to top toolbar layout",
      child: IconButton(
        icon: Transform.flip(
          flipX: true,
          child: Icon(useTopToolbar ? Icons.view_sidebar : Icons.web),
        ),
        color: Theme.of(context).iconTheme.color,
        onPressed: () => ref
            .read(appSettings.notifier)
            .update((s) => s.copyWith(useTopToolbar: !useTopToolbar)),
      ),
    );
  }
}

/// Navigates to the Settings page.
class SettingsNavButton extends StatelessWidget {
  final TriOSTools currentPage;
  final ValueChanged<TriOSTools> onTabChanged;

  const SettingsNavButton({
    super.key,
    required this.currentPage,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MovingTooltipWidget.text(
      message: "Settings",
      child: IconButton(
        onPressed: () => onTabChanged(TriOSTools.settings),
        color: currentPage == TriOSTools.settings
            ? theme.colorScheme.primary
            : theme.iconTheme.color,
        isSelected: currentPage == TriOSTools.settings,
        icon: const Icon(Icons.settings),
      ),
    );
  }
}

/// Opens the TriOS changelog dialog.
class ChangelogButton extends StatelessWidget {
  const ChangelogButton({super.key});

  @override
  Widget build(BuildContext context) {
    return MovingTooltipWidget.text(
      message: "${Constants.appName} Changelog",
      child: IconButton(
        icon: const SvgImageIcon("assets/images/icon-bullhorn-variant.svg"),
        color: Theme.of(context).iconTheme.color,
        onPressed: () => showTriOSChangelogDialog(
          context,
          lastestVersionToShow: Version.parse(
            Constants.version,
            sanitizeInput: false,
          ),
        ),
      ),
    );
  }
}

/// Opens the TriOS about dialog.
class AboutButton extends StatelessWidget {
  const AboutButton({super.key});

  @override
  Widget build(BuildContext context) {
    return MovingTooltipWidget.text(
      message: "About",
      child: IconButton(
        icon: const SvgImageIcon("assets/images/icon-info.svg"),
        color: Theme.of(context).iconTheme.color,
        onPressed: () => showTriOSAboutDialog(context),
      ),
    );
  }
}

/// Shows donation popup. Right-click to hide.
class DonateButton extends ConsumerWidget {
  const DonateButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(appSettings.select((s) => s.showDonationButton))) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onSecondaryTapDown: (details) async {
        final result = await showMenu<String>(
          context: context,
          position: RelativeRect.fromLTRB(
            details.globalPosition.dx,
            details.globalPosition.dy,
            details.globalPosition.dx,
            details.globalPosition.dy,
          ),
          items: [
            const PopupMenuItem<String>(
              value: 'hide',
              child: Text('Hide donation button'),
            ),
          ],
        );
        if (result == 'hide') {
          ref
              .read(appSettings.notifier)
              .update((state) => state.copyWith(showDonationButton: false));
        }
      },
      child: MovingTooltipWidget.text(
        message: "Show donation popup",
        child: IconButton(
          icon: const SvgImageIcon("assets/images/icon-donate.svg"),
          color: Theme.of(context).iconTheme.color,
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: const Text("Donations"),
                  content: DonateView(),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text("Close"),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

/// Toggles rules.csv hot-reload.
class RulesHotReloadButton extends ConsumerWidget {
  final bool showText;

  const RulesHotReloadButton({super.key, this.showText = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isRulesHotReloadEnabled = ref.watch(
      appSettings.select((value) => value.isRulesHotReloadEnabled),
    );

    return MovingTooltipWidget.text(
      message:
          "When enabled, modifying a mod's rules.csv will\nreload in-game rules as long as dev mode is enabled."
          "\n\nrules.csv hot reload is ${isRulesHotReloadEnabled ? "enabled" : "disabled"}."
          "\nClick to ${isRulesHotReloadEnabled ? "disable" : "enable"}.",
      child: InkWell(
        borderRadius: BorderRadius.circular(TriOSThemeConstants.cornerRadius),
        onTap: () => ref
            .read(appSettings.notifier)
            .update(
              (state) => state.copyWith(
                isRulesHotReloadEnabled: !isRulesHotReloadEnabled,
              ),
            ),
        child: Padding(
          padding: .only(left: showText ? 16.0 : 0),
          child: RulesHotReload(
            isEnabled: isRulesHotReloadEnabled,
            showText: showText,
          ),
        ),
      ),
    );
  }
}

/// Debug toolbar icon. Only visible when debug mode is enabled.
/// Shows process detection diagnostics and cache stats in a tooltip.
class DebugToolbarButton extends ConsumerWidget {
  const DebugToolbarButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDebugMode = ref.watch(appSettings.select((s) => s.debugMode));
    if (!isDebugMode) return const SizedBox.shrink();

    return MovingTooltipWidget.framed(
      tooltipWidget: _DebugTooltipContent(),
      child: IconButton(
        icon: const Icon(Icons.bug_report_outlined),
        color: Theme.of(context).colorScheme.tertiary,
        onPressed: () {},
      ),
    );
  }
}

class _DebugTooltipContent extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final labelStyle = theme.textTheme.bodySmall;
    final valueStyle = theme.textTheme.bodySmall?.copyWith(
      fontWeight: FontWeight.bold,
    );

    final diagnostics = ref.watch(AppState.processDetectionDiagnostics);
    final isDetectionEnabled = ref.watch(
      appSettings.select((s) => s.checkIfGameIsRunning),
    );

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 350),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Debug Info", style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Text(
            "Game Detection",
            style: labelStyle?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          if (!isDetectionEnabled)
            Text("Disabled", style: labelStyle)
          else if (diagnostics == null)
            Text("Not yet detecting", style: labelStyle)
          else ...[
            _row("Starsector", diagnostics.wasGameRunning ? "Running" : "Not running", labelStyle, valueStyle),
            _row("Matched by", diagnostics.matchedDetectorName ?? "None", labelStyle, valueStyle),
            _row("Detectors", diagnostics.detectorNames.join(", "), labelStyle, valueStyle),
            _row("Check Duration", "${diagnostics.checkDuration.inMilliseconds} ms", labelStyle, valueStyle),
            if (diagnostics.runInterval != null)
              _row("Period", "${diagnostics.runInterval!.inMilliseconds} ms (${(60000 / diagnostics.runInterval!.inMilliseconds).toStringAsFixed(1)}/min)", labelStyle, valueStyle),
            if (diagnostics.errors.isNotEmpty)
              _row("Errors", diagnostics.errors.map((e) => e.toString()).join("; "), labelStyle, valueStyle?.copyWith(color: theme.colorScheme.error)),
          ],
        ],
      ),
    );
  }

  Widget _row(
    String label,
    String value,
    TextStyle? labelStyle,
    TextStyle? valueStyle,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text("$label:", style: labelStyle)),
          Flexible(child: Text(value, style: valueStyle)),
        ],
      ),
    );
  }
}
