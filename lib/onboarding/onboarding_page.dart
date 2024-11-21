import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/trios/settings/settings.dart';
import 'package:trios/utils/platform_paths.dart';
import 'package:trios/widgets/checkbox_with_label.dart';
import 'package:trios/widgets/disable.dart';

class OnboardingDialog extends ConsumerStatefulWidget {
  const OnboardingDialog({super.key});

  @override
  ConsumerState<OnboardingDialog> createState() => _OnboardingDialogState();
}

class _OnboardingDialogState extends ConsumerState<OnboardingDialog> {
  final _formKey = GlobalKey<FormState>();
  String? gameDirPath;
  bool enableDirectLaunch = false;
  late TextEditingController textEditingController;
  bool enableMultipleVersions = true;
  int? lastNVersionsSetting = null;

  @override
  void initState() {
    super.initState();
    gameDirPath = ref.read(appSettings).gameDir?.path;
    textEditingController = TextEditingController(text: gameDirPath);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 650),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Align(
                  child: Text(
                    "${Constants.appName} First Time Setup",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    if (validateGameFolderPath(textEditingController.text))
                      const Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: Icon(Icons.check),
                      ),
                    Expanded(
                      child: TextFormField(
                        controller: textEditingController,
                        decoration: const InputDecoration(
                          labelText: 'Game Location',
                          hintText: 'Select your game directory',
                        ),
                        validator: (value) =>
                            value == null || !validateGameFolderPath(value)
                                ? 'Game not found'
                                : null,
                        onChanged: (value) => setState(() {
                          gameDirPath = value;
                        }),
                        onSaved: (value) => gameDirPath = value,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.folder),
                      onPressed: () async {
                        var newGameDir =
                            await FilePicker.platform.getDirectoryPath();
                        if (newGameDir == null) return;
                        // tryUpdateGamePath(newGameDir, settings);
                        textEditingController.text = newGameDir;
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 36),
                const Padding(
                  padding: EdgeInsets.only(left: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("How do you want to handle mod updates?",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text("This will not affect your existing mods.",
                          style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
                RadioListTile(
                  title: const Text("Keep only one mod version"),
                  value: false,
                  groupValue: enableMultipleVersions,
                  onChanged: (value) => setState(() {
                    enableMultipleVersions = value!;
                  }),
                ),
                Row(
                  children: [
                    IntrinsicWidth(
                      child: RadioListTile(
                        title: const Text("Keep all mod versions"),
                        value: true,
                        groupValue: enableMultipleVersions,
                        onChanged: (value) => setState(() {
                          enableMultipleVersions = value!;
                        }),
                      ),
                    ),
                    Disable(
                      isEnabled: enableMultipleVersions,
                      child: Row(
                        children: [
                          const Text(" (up to "),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: DropdownButton<int>(
                              value: lastNVersionsSetting,
                              items: [
                                for (int i = 2; i <= 10; i++)
                                  DropdownMenuItem(
                                      value: i, child: Text(" $i")),
                                const DropdownMenuItem(
                                    value: null, child: Text(" ∞")),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  lastNVersionsSetting = value;
                                });
                              },
                              isDense: true,
                            ),
                          ),
                          const Text(")"),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 32),
                  child: Disable(
                    isEnabled: enableMultipleVersions,
                    child: CheckboxWithLabel(
                      value: ref.watch(
                              appSettings.select((s) => s.modUpdateBehavior)) ==
                          ModUpdateBehavior.switchToNewVersionIfWasEnabled,
                      onChanged: (newValue) {
                        setState(() {
                          ref.read(appSettings.notifier).update((s) =>
                              s.copyWith(
                                  modUpdateBehavior: newValue == true
                                      ? ModUpdateBehavior
                                          .switchToNewVersionIfWasEnabled
                                      : ModUpdateBehavior.doNotChange));
                        });
                      },
                      labelWidget: const Text(
                          "After updating an enabled mod, switch to the new version"),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Skip'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          _formKey.currentState!.save();
                          _saveSettings(context);
                        }
                      },
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _saveSettings(BuildContext context) {
    final settings = ref.read(appSettings.notifier);

    settings.update((state) => state.copyWith(
          gameDir: gameDirPath != null ? Directory(gameDirPath!) : null,
          enableDirectLaunch: enableDirectLaunch,
        ));

    Navigator.of(context).pop();
  }
}
