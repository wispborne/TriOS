import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toastification/toastification.dart';
import 'package:trios/themes/theme_manager.dart';
import 'package:trios/toolbar/chatbot_button.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/widgets/animated_gradient_border.dart';

class AprilFools2026Toast extends ConsumerStatefulWidget {
  const AprilFools2026Toast(this.item, {super.key});

  final ToastificationItem item;

  @override
  ConsumerState<AprilFools2026Toast> createState() =>
      _AprilFools2026ToastState();
}

class _AprilFools2026ToastState extends ConsumerState<AprilFools2026Toast> {
  bool _showSecondPhase = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final gradientColors = ChatbotButton.gradientColorsFrom(theme.colorScheme);

    return Padding(
      padding: const EdgeInsets.only(right: 32),
      child: Card(
        surfaceTintColor: theme.colorScheme.primary,
        elevation: 8,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ThemeManager.cornerRadius),
        ),
        child: AnimatedGradientBorder(
          colors: gradientColors,
          borderRadius: ThemeManager.cornerRadius,
          duration: const Duration(milliseconds: 6000),
          child: Container(
            clipBehavior: Clip.antiAlias,
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(ThemeManager.cornerRadius),
            ),
            child: Row(
              children: [
                Padding(
                  padding: const .only(left: 8),
                  child: Icon(
                    Icons.auto_awesome,
                    color: theme.colorScheme.primary,
                  ),
                ),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _showSecondPhase
                            ? "Ok, it's actually an April Fool's joke. It's completely offline and harmless, promise."
                            : "New! AI Chat is now available in TriOS.",
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        spacing: 8,
                        children: _showSecondPhase
                            ? [
                                ElevatedButton(
                                  onPressed: () {
                                    ref
                                        .read(appSettings.notifier)
                                        .update(
                                          (s) => s.copyWith(
                                            showAprilFools2026: false,
                                          ),
                                        );
                                    toastification.dismiss(widget.item);
                                  },
                                  child: const Text("Still no"),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    ref
                                        .read(appSettings.notifier)
                                        .update(
                                          (s) => s.copyWith(
                                            showAprilFools2026: true,
                                          ),
                                        );
                                    toastification.dismiss(widget.item);
                                  },
                                  child: const Text("Ok fine"),
                                ),
                              ]
                            : [
                                ElevatedButton(
                                  onPressed: () {
                                    ref
                                        .read(appSettings.notifier)
                                        .update(
                                          (s) => s.copyWith(
                                            showAprilFools2026: true,
                                          ),
                                        );
                                    toastification.dismiss(widget.item);
                                  },
                                  child: const Text("Enable"),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    setState(() => _showSecondPhase = true);
                                  },
                                  child: const Text("No thanks"),
                                ),
                              ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
