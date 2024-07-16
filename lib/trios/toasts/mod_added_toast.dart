import 'package:dart_extensions_methods/dart_extension_methods.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:toastification/toastification.dart';
import 'package:trios/mod_manager/mod_manager_logic.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/themes/theme_manager.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/widgets/trios_app_icon.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../utils/logging.dart';

class ModAddedToast extends ConsumerStatefulWidget {
  const ModAddedToast(this.modVariant, this.item, this.durationMillis,
      {super.key});

  final ToastificationItem item;
  final ModVariant modVariant;
  final int durationMillis;

  @override
  ConsumerState createState() => _ModAddedToastState();
}

class _ModAddedToastState extends ConsumerState<ModAddedToast> {
  PaletteGenerator? palette;
  int timeRemaining = 1;

  @override
  void initState() {
    super.initState();
    _generatePalette();
    timeRemaining = widget.durationMillis;
    // loop to update the time remaining every 5ms
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 5));
      if (mounted) {
        setState(() {
          timeRemaining -= 5;
        });
      }
      return timeRemaining > 0;
    });
  }

  Future<void> _generatePalette() async {
    if (widget.modVariant.iconFilePath.isNotNullOrEmpty()) {
      final icon = Image.file((widget.modVariant.iconFilePath ?? "").toFile());
      palette = await PaletteGenerator.fromImageProvider(icon.image);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final modString = widget.modVariant.modInfo.nameOrId;
    final mods = ref.read(AppState.mods);
    final mod = widget.modVariant.mod(mods);
    final currentVariant = mod?.findFirstEnabled;

    final icon = widget.modVariant.iconFilePath.isNotNullOrEmpty()
        ? Image.file((widget.modVariant.iconFilePath ?? "").toFile())
        : null;

    if (timeRemaining <= 0) {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        toastification.dismiss(widget.item);
      });
    }

    return Padding(
      padding: const EdgeInsets.only(top: 4, right: 32),
      child: Container(
        decoration: const BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4.0,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Theme(
          data: createPaletteTheme(context, palette),
          child: Builder(builder: (context) {
            final theme =
                Theme.of(context); // Ensure the theme is within the Builder
            return Card(
              child: Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius:
                      BorderRadius.circular(ThemeManager.cornerRadius),
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
                    Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: Tooltip(
                        message: widget.modVariant.modInfo.nameOrId,
                        child: SizedBox(
                            width: 40,
                            height: 40,
                            child: icon ?? const TriOSAppIcon()),
                      ),
                    ),
                    Expanded(
                      child: SelectionArea(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              modString ?? "",
                              style: theme.textTheme.bodyMedium,
                            ),
                            Opacity(
                              opacity: 0.9,
                              child: Text(
                                widget.modVariant.modInfo.version.toString(),
                                style: theme.textTheme.labelMedium,
                              ),
                            ),
                            if (currentVariant != null)
                              Text(
                                "Currently enabled: ${currentVariant.modInfo.version}",
                                style: theme.textTheme.labelMedium,
                              ),
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      // open folder in file explorer
                                      launchUrlString(
                                          widget.modVariant.modsFolder.path);
                                    },
                                    icon: Icon(Icons.folder_open,
                                        color: theme.colorScheme.onSurface),
                                    label: Text("Open",
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                                color: theme
                                                    .colorScheme.onSurface)),
                                  ),
                                  if (widget.modVariant.bestVersion !=
                                      currentVariant?.bestVersion)
                                    Row(
                                      children: [
                                        const SizedBox(width: 8),
                                        ElevatedButton.icon(
                                          onPressed: () async {
                                            if (mod == null) {
                                              Fimber.w(
                                                  "Cannot enable, mod not found for variant ${widget.modVariant.smolId}");
                                              return;
                                            }
                                            await changeActiveModVariant(
                                                mod, widget.modVariant, ref);
                                            toastification.dismiss(widget.item);
                                          },
                                          icon: const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child:
                                                Icon(Icons.power_settings_new),
                                          ),
                                          label: const Text("Enable"),
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
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 32,
                          height: 32,
                          child: CircularProgressIndicator(
                            value: timeRemaining / widget.durationMillis,
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                theme.colorScheme.onSurface),
                          ),
                        ),
                        IconButton(
                          onPressed: () => toastification.dismiss(widget.item),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
