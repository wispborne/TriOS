import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toastification/toastification.dart';
import 'package:trios/companion_mod/companion_mod_manager.dart';
import 'package:trios/models/version.dart';
import 'package:trios/themes/theme_manager.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/widgets/trios_app_icon.dart';

class CompanionModUpdateToast extends ConsumerStatefulWidget {
  const CompanionModUpdateToast(this.installedVersion, this.item, {super.key});

  final Version? installedVersion;
  final ToastificationItem item;

  @override
  ConsumerState<CompanionModUpdateToast> createState() =>
      _CompanionModUpdateToastState();
}

class _CompanionModUpdateToastState
    extends ConsumerState<CompanionModUpdateToast> {
  bool _isUpdating = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 32),
      child: Card(
        surfaceTintColor: Theme.of(context).colorScheme.tertiary,
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
          child: Stack(
            children: [
              Row(
                children: [
                  const TriOSAppIcon(),
                  Expanded(
                    child: Column(
                      children: [
                        const Text("Update ${Constants.appName} Companion Mod"),
                        Text(
                          widget.installedVersion != null
                              ? "${widget.installedVersion} → ${Constants.companionModVersion}"
                              : "Update to ${Constants.companionModVersion}",
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: _isUpdating
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : ElevatedButton.icon(
                                  onPressed: () async {
                                    setState(() => _isUpdating = true);
                                    try {
                                      await ref
                                          .read(companionModManagerProvider)
                                          .fullySetUpCompanionMod();
                                    } finally {
                                      toastification.dismiss(widget.item);
                                    }
                                  },
                                  icon: const Icon(Icons.download),
                                  label: const Text("Update"),
                                ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Positioned(
                top: 0,
                right: 0,
                child: IconButton(
                  onPressed: () => toastification.dismiss(widget.item),
                  icon: const Icon(Icons.close),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
