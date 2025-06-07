import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toastification/toastification.dart';
import 'package:trios/models/version.dart';
import 'package:trios/themes/theme_manager.dart';
import 'package:trios/widgets/svg_image_icon.dart';
import 'package:trios/widgets/trios_app_icon.dart';

import '../trios/constants.dart';
import 'changelog_viewer.dart';

class PostUpdateToast extends ConsumerWidget {
  const PostUpdateToast({required this.item, super.key});

  final ToastificationItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(right: 32),
      child: Card(
        surfaceTintColor: Theme.of(context).colorScheme.secondary,
        elevation: 8,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ThemeManager.cornerRadius),
        ),
        child: Container(
          clipBehavior: Clip.antiAlias,
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(ThemeManager.cornerRadius),
            border: Border.all(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.15),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: const TriOSAppIcon(),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${Constants.appName} was updated to ${Constants.version}!",
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    Row(
                      children: [
                        Spacer(),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ElevatedButton.icon(
                            onPressed: () => showTriOSChangelogDialog(
                              context,
                              lastestVersionToShow: Version.parse(
                                Constants.version,
                                sanitizeInput: false,
                              ),
                            ),
                            icon: const SvgImageIcon(
                              "assets/images/icon-bullhorn-variant.svg",
                            ),
                            label: const Text("View Changelog"),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => toastification.dismiss(item),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
