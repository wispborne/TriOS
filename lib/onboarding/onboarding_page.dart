import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/trios/settings/settings.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/platform_paths.dart';
import 'package:trios/utils/util.dart';
import 'package:trios/widgets/code.dart';
import 'package:trios/widgets/disable.dart';
import 'package:trios/widgets/moving_tooltip.dart';
import 'package:trios/widgets/restartable_app.dart';
import 'package:trios/widgets/trios_app_icon.dart';

import '../widgets/svg_image_icon.dart';

class OnboardingCarousel extends ConsumerStatefulWidget {
  const OnboardingCarousel({super.key});

  @override
  ConsumerState<OnboardingCarousel> createState() => _OnboardingCarouselState();
}

class _OnboardingCarouselState extends ConsumerState<OnboardingCarousel> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  String? gameDirPath;
  late TextEditingController textEditingController;
  bool enableMultipleVersions = true;
  int? lastNVersionsSetting;
  bool allowCrashReporting = false;
  List<Widget Function()> pages = [];

  int get totalPages => pages.length;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(appSettings);
    gameDirPath = settings.gameDir?.path;
    textEditingController = TextEditingController(text: gameDirPath);
    enableMultipleVersions = settings.keepLastNVersions != 1;
    lastNVersionsSetting =
        enableMultipleVersions ? settings.keepLastNVersions : null;
    allowCrashReporting = settings.allowCrashReporting ?? false;
    pages = [];
    if (Platform.isMacOS) pages.add(() => _buildMacOSPage());
    pages.add(() => _buildGameDirectoryAndModPreferencesPage());
    pages.add(() => _buildCrashReportingPage());
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: PopScope(
        canPop: false,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Stack(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: MovingTooltipWidget.text(
                  message: "ಠ_ಠ",
                  child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close)),
                ),
              ),
              Column(
                children: [
                  TriOSAppIcon(),
                  const Text(
                    "Setup",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() {
                          _currentPage = index;
                        });
                      },
                      children: pages.map((page) => page()).toList(),
                    ),
                  ),
                  _buildBottomNavigation(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameDirectoryAndModPreferencesPage() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Transform.translate(
              offset: const Offset(-4, 0),
              child: SvgImageIcon(
                'assets/images/icon-folder-game.svg',
                width: 45,
                height: 45,
              ),
            ),
            SizedBox(height: 8),
            const Text(
              "1. Where is Starsector located?",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(
                    validateGameFolderPath(textEditingController.text)
                        ? Icons.check
                        : Icons.close,
                  ),
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
                    setState(() {
                      textEditingController.text = newGameDir;
                      gameDirPath = newGameDir;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 8 * 7),
            const Padding(
              padding: EdgeInsets.only(left: 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SvgImageIcon(
                    'assets/images/icon-folder-multiple.svg',
                    width: 45,
                    height: 45,
                  ),
                  SizedBox(height: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("2. How do you want to handle mod updates?",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                          "This will only affect your mods when you update them.",
                          style: TextStyle(fontSize: 12)),
                      Text("No mods will be affected immediately.",
                          style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            MovingTooltipWidget.text(
              message:
                  "Installing or updating a mod will replace the previous version of it.",
              child: RadioListTile(
                title: const Text("Keep only one mod version"),
                value: false,
                groupValue: enableMultipleVersions,
                onChanged: (value) => setState(() {
                  enableMultipleVersions = value!;
                }),
              ),
            ),
            Row(
              children: [
                IntrinsicWidth(
                  child: MovingTooltipWidget.text(
                    message: lastNVersionsSetting == null
                        ? "TriOS will never automatically remove mod versions."
                        : "Installing or updating a mod will remove all but the last $lastNVersionsSetting highest versions.",
                    child: RadioListTile(
                      title: const Text("Keep all mod versions"),
                      value: true,
                      groupValue: enableMultipleVersions,
                      onChanged: (value) => setState(() {
                        enableMultipleVersions = value!;
                      }),
                    ),
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
                              DropdownMenuItem(value: i, child: Text(" $i")),
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
          ],
        ),
      ),
    );
  }

  Widget _buildCrashReportingPage() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Transform.translate(
            offset: const Offset(-2, 0),
            child: SvgImageIcon(
              'assets/images/icon-spider-web.svg',
              width: 45,
              height: 45,
            ),
          ),
          SizedBox(height: 8),
          const Text(
            "3: Bug Reporting",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 16),
          Linkify(
            text:
                "${Constants.appName} can send crash/error reports to help me find and fix issues (it does actually help!)."
                "\nExample of a report: https://i.imgur.com/k9E6zxO.png."
                "\n\nNothing identifiable or personal is ever sent."
                "\n\nSent: app version, mod list, basic PC info (screen resolution, OS, RAM...), randomly generated user ID, and crash details."
                "\nNot sent: IP address, language, region, zip code, PC name, PC username, anything about other apps, etc.",
            onOpen: (link) => OpenFilex.open(link.url),
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),
          RadioListTile<bool>(
            title: Row(
              children: [
                const Icon(Icons.track_changes),
                const SizedBox(width: 16),
                const Text("Allow Reporting"),
              ],
            ),
            value: true,
            groupValue: allowCrashReporting,
            onChanged: (value) {
              setState(() {
                allowCrashReporting = value!;
              });
            },
          ),
          RadioListTile<bool>(
            title: Row(
              children: [
                const SvgImageIcon("assets/images/icon-incognito-circle.svg"),
                const SizedBox(width: 16),
                const Text("Keep Reporting Disabled"),
              ],
            ),
            value: false,
            groupValue: allowCrashReporting,
            onChanged: (value) {
              setState(() {
                allowCrashReporting = value!;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMacOSPage() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Transform.translate(
            offset: const Offset(-12, 0), child: Icon(Icons.apple, size: 72)),
        Text("MacOS-only Instructions",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 8),
        Text("Required for self-update, mod updates & mod installs.",
            style: TextStyle(fontStyle: FontStyle.italic)),
        const SizedBox(height: 16),
        Text("1. Open the Terminal app."),
        const SizedBox(height: 8),
        Text("2. Paste into Terminal to install Homebrew: "),
        Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Code(
            showCopyButton: true,
            child: SelectableText(
              '/bin/bash -c "\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"',
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text("3. Paste into Terminal to install compression libs: "),
        Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Code(
            showCopyButton: true,
            child: SelectableText(
              "brew install xz zstd zlib",
            ),
          ),
        )
      ]),
    );
  }

  Widget _buildBottomNavigation() {
    return Stack(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "You can always change these on the Settings page later",
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.color
                            ?.withOpacity(0.7),
                      ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: List.generate(totalPages, (index) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            _currentPage == index ? Colors.blue : Colors.grey,
                      ),
                    );
                  }),
                ),
              ],
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (_currentPage > 0)
              SizedBox(
                height: 8 * 5,
                child: OutlinedButton(
                  onPressed: () {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: const Text("Back"),
                ),
              )
            else
              const SizedBox(),
            Builder(builder: (context) {
              final isLast = _currentPage == totalPages - 1;
              return SizedBox(
                height: 8 * 5,
                child: Disable(
                  isEnabled: gameDirPath != null &&
                      validateGameFolderPath(gameDirPath!),
                  child: ElevatedButton.icon(
                    icon: Icon(isLast ? Icons.check : Icons.arrow_forward),
                    iconAlignment: IconAlignment.end,
                    onPressed: () {
                      if (!isLast) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        _saveSettings(context);
                      }
                    },
                    label: Text(isLast ? "Finish" : "Next"),
                  ),
                ),
              );
            }),
          ],
        ),
      ],
    );
  }

  void _saveSettings(BuildContext context) {
    final settings = ref.read(appSettings.notifier);
    settings.update((state) => state.copyWith(
          gameDir: gameDirPath != null ? Directory(gameDirPath!) : null,
          modsDir:
              generateModsFolderPath(gameDirPath!.toDirectory())?.toDirectory(),
          keepLastNVersions: enableMultipleVersions ? lastNVersionsSetting : 1,
          allowCrashReporting: allowCrashReporting,
        ));
    RestartableApp.restartApp(context);
    Navigator.of(context).pop();
  }
}
