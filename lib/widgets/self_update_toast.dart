import 'package:fimber_io/fimber_io.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toastification/toastification.dart';
import 'package:trios/trios/trios_theme.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/widgets/trios_app_icon.dart';

import '../main.dart';
import '../trios/app_state.dart';
import '../trios/self_updater/self_updater.dart';
import '../utils/network_util.dart';

class SelfUpdateToast extends ConsumerWidget {
  const SelfUpdateToast(this.latestRelease, this.item, {super.key});

  final Release latestRelease;
  final ToastificationItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(right: 32),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(TriOSTheme.cornerRadius),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4.0,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const TriOSAppIcon(),
            Expanded(
              child: Column(
                children: [
                  const Text("New $appName version"),
                  Text("${latestRelease.tagName} is now available!", style: Theme.of(context).textTheme.labelLarge),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ElevatedButton(
                        onPressed: () {
                          SelfUpdater.update(latestRelease, downloadProgress: (bytesReceived, contentLength) {
                            ref
                                .read(AppState.selfUpdateDownloadProgress.notifier)
                                .update((_) => bytesReceived / contentLength);
                            Fimber.i(
                                "Downloaded: ${bytesReceived.bytesAsReadableMB()} / ${contentLength.bytesAsReadableMB()}");
                          });
                        },
                        child: const Text("Update")),
                  ),
                  LinearProgressIndicator(
                    value: ref.watch(AppState.selfUpdateDownloadProgress) ?? 0,
                  ),
                ],
              ),
            ),
            IconButton(onPressed: () => toastification.dismiss(item), icon: const Icon(Icons.close))
          ],
        ),
      ),
    );
  }
}
