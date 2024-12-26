import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:trios/widgets/code.dart';
import 'package:trios/widgets/trios_expansion_tile.dart';

import '../../trios/constants.dart';

class VramCheckerExplanationDialog extends ConsumerStatefulWidget {
  const VramCheckerExplanationDialog({super.key});

  @override
  ConsumerState createState() => _VramCheckerExplanationDialogState();
}

class _VramCheckerExplanationDialogState
    extends ConsumerState<VramCheckerExplanationDialog> {
  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
        );
    return AlertDialog(
      title: const Text("About VRAM Estimator"),
      icon: const Icon(Icons.memory),
      content: SingleChildScrollView(
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text("Your VRAM is based on your GPU and can't be adjusted."),
              const SizedBox(height: 8),
              Text(
                  "It's used by mods with ships and weapons. Running out crashes the game."),
              const SizedBox(height: 8),
              Text(
                  "${Constants.appName} can estimate how much VRAM your mods use, but it's not perfect."
                  "\nTo see accurate usage, open the console (from Console Commands) and look in the top-left corner."),
              const SizedBox(height: 16),
              TriOSExpansionTile(
                  title: Text("View more Info"),
                  leading: const Icon(Icons.menu_book),
                  backgroundColor:
                      Theme.of(context).colorScheme.surfaceContainer,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: SingleChildScrollView(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text("What is VRAM?", style: titleStyle),
                              const SizedBox(height: 8),
                              Text(
                                  "VRAM is Video RAM. It's different than RAM, being physically located on the graphics card. It cannot be upgraded without a new graphics card."),
                              const SizedBox(height: 8),
                              Text(
                                  "Unlike RAM, VRAM cannot be manually assigned (vmparams file is for normal RAM only), and the game will use as much as it needs."),
                              const SizedBox(height: 8),
                              Text(
                                  "Essentially, the more images (ships, weapons, etc.) you load, the more VRAM you need. If you run out, it will use normal RAM instead, but very inefficiently, and if that runs out, the game will crash."),
                              const SizedBox(height: 8),
                              Text(
                                  "GraphicsLib's default settings uses additional VRAM to improve visuals, so if you are running out but don't want to disable mods, try adjusting its settings."),
                              const SizedBox(height: 16),
                              Text("About this tool", style: titleStyle),
                              const SizedBox(height: 8),
                              const Text(
                                  'This tool estimates the amount of VRAM used by a mod, based on the images in the mod folder.'
                                  '\nIt has no way of reliably telling whether the mod actually uses the image in-game, which means'
                                  ' that unused images will still be counted against it.'),
                              const SizedBox(height: 8),
                              Text(
                                  'A few mods, such as Illustrated Entities, load images only when needed, so their real VRAM use will be much lower than estimated.'),
                              const SizedBox(height: 8),
                              Text(
                                  "To see true VRAM usage, enable the Console Commands mod and open it in-game. The amount of free VRAM will be shown in the top-left corner.",
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        decoration: TextDecoration.underline,
                                      )),
                              const SizedBox(height: 16),
                              Text("Calculation", style: titleStyle),
                              const SizedBox(height: 8),
                              Text(
                                  "VRAM use is based on an image's width, height, and number of channels. File size is irrelevant."),
                              const SizedBox(height: 8),
                              Code(
                                child: Text(
                                    '((numOfChannels * bitsPerChannel) / bitsPerByte) * widthRoundedUpToNearestPowerOfTwo * heightRoundedUpToNearestPowerOfTwo * multiplier',
                                    style: GoogleFonts.robotoMono()
                                        .copyWith(fontSize: 14)),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                  'Multiplier = 1x for background images and 1.33x for other images. The 1.33x is extra memory used for mipmapping.'),
                              const SizedBox(height: 8),
                              Text(
                                  "Backgrounds are ignored if they are the same size as vanilla's backgrounds (because vanilla always has only one background loaded, so a vanilla-sized background is not adding more VRAM use)."),
                              const SizedBox(height: 8),
                              Text(
                                  "If the mod has one or more backgrounds that are larger than a vanilla background, then the single largest of them is counted as additional VRAM used (additionalVRAMUse = modBackgroundVRAMUse - vanillaBackgroundVRAMUse).")
                            ]),
                      ),
                    ),
                  ]),
            ]),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("Close"),
        ),
      ],
    );
  }
}
