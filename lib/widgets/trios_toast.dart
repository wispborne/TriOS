import 'package:fimber_io/fimber_io.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toastification/toastification.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/widgets/TriOSAppIcon.dart';

import '../app_state.dart';
import '../main.dart';
import '../trios/self_updater/self_updater.dart';
import '../utils/network_util.dart';

class TriOSToast extends ConsumerWidget {
  const TriOSToast(this.latestRelease, this.item, {super.key});

  final Release latestRelease;
  final ToastificationItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          const TriOSAppIcon(),
          Expanded(
            child: Column(
              children: [
                const Text("New $appName version"),
                Text("${latestRelease.tagName} is now available!", style: Theme.of(context).textTheme.labelLarge),
                ElevatedButton(
                    onPressed: () {
                      SelfUpdater.update(latestRelease, downloadProgress: (bytesReceived, contentLength) {
                        ref.read(selfUpdateDownloadProgress.notifier).update((_) => bytesReceived / contentLength);
                        Fimber.i(
                            "Downloaded: ${bytesReceived.bytesAsReadableMB()} / ${contentLength.bytesAsReadableMB()}");
                      });
                    },
                    child: const Text("Update")),
                LinearProgressIndicator(
                  value: ref.watch(selfUpdateDownloadProgress) ?? 0,
                ),
              ],
            ),
          ),
          IconButton(onPressed: () => toastification.dismiss(item), icon: const Icon(Icons.close))
        ],
      ),
    );
  }
}
