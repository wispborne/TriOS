// mod_image.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:trios/modBrowser/models/scraped_mod.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/widgets/conditional_wrap.dart';
import 'package:trios/widgets/moving_tooltip.dart';
import 'package:trios/widgets/tooltip_frame.dart';

class ScrapedModCard extends StatefulWidget {
  final ScrapedMod mod;
  final void Function(String) linkLoader;

  const ScrapedModCard({
    super.key,
    required this.mod,
    required this.linkLoader,
  });

  @override
  State<ScrapedModCard> createState() => _ScrapedModCardState();
}

class _ScrapedModCardState extends State<ScrapedModCard> {
  bool isBeingHovered = false;

  @override
  Widget build(BuildContext context) {
    final mod = widget.mod;
    final urls = mod.urls;
    const markdownWidth = 800.0;

    return MouseRegion(
      onEnter: (_) {
        setState(() {
          isBeingHovered = true;
        });
      },
      onExit: (_) {
        setState(() {
          isBeingHovered = false;
        });
      },
      child: GestureDetector(
        onTap: () {
          if (urls == null) {
            return;
          }

          if (urls.containsKey(ModUrlType.Forum)) {
            widget.linkLoader(urls[ModUrlType.Forum]!);
          } else if (urls.containsKey(ModUrlType.NexusMods)) {
            widget.linkLoader(urls[ModUrlType.NexusMods]!);
          } else if (urls.containsKey(ModUrlType.DirectDownload)) {
            _showDirectDownloadDialog(
                context, mod.name, urls[ModUrlType.DirectDownload]!);
          }
        },
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
            side: BorderSide(
              color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
            ),
          ),
          child: IntrinsicHeight(
            child: Container(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  SizedBox(width: 80.0, child: ModImage(mod: mod)),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mod.name.isNotEmpty ? mod.name : '???',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14.0,
                              fontFamily: 'Orbitron', // Customize your font
                            ),
                          ),
                          if (mod.authorsList?.isNotEmpty == true)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                mod.authorsList!.join(', '),
                                style: const TextStyle(
                                  fontSize: 11.0,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          if ((mod.summary?.isNotEmpty ?? false) ||
                              (mod.description?.isNotEmpty ?? false))
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                (mod.summary ?? mod.description)!
                                    .split('\n')
                                    .where((line) => line.isNotEmpty)
                                    .take(2)
                                    .join('\n'),
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .textTheme
                                          .labelLarge
                                          ?.color
                                          ?.withOpacity(0.6),
                                    ),
                              ),
                            ),
                          if ((mod.description?.isNotEmpty ?? false))
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: ConditionalWrap(
                                condition: mod.description?.isNotEmpty == true,
                                wrapper: (child) => MovingTooltipWidget(
                                    tooltipWidget: TooltipFrame(
                                        child: Text(mod.description ?? '')),
                                    child: child),
                                child: OutlinedButton(
                                  onPressed: () {
                                    _showDescriptionDialog(
                                        context, mod.name, mod.description!);
                                  },
                                  child: Text(
                                    'View Desc.',
                                    style:
                                        Theme.of(context).textTheme.labelLarge,
                                  ),
                                ),
                              ),
                            ),
                          const Spacer(),
                          const SizedBox(height: 8.0),
                          Tags(mod: mod),
                        ],
                      ),
                    ),
                  ),
                  Builder(builder: (context) {
                    const size = 14.0;
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        BrowserIcon(
                          mod: mod,
                          iconOpacity: isBeingHovered ? 1.0 : 0.7,
                          linkLoader: widget.linkLoader,
                          size: size,
                        ),
                        DiscordIcon(
                          mod: mod,
                          iconOpacity: isBeingHovered ? 1.0 : 0.7,
                          size: size,
                        ),
                        NexusModsIcon(
                          mod: mod,
                          iconOpacity: isBeingHovered ? 1.0 : 0.7,
                          size: size,
                        ),
                        DirectDownloadIcon(
                          mod: mod,
                          iconOpacity: isBeingHovered ? 1.0 : 0.7,
                          size: size,
                          linkLoader: widget.linkLoader,
                        ),
                        DebugIcon(
                          mod: mod,
                          iconOpacity: isBeingHovered ? 1.0 : 0.7,
                          size: size,
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showDirectDownloadDialog(
      BuildContext context, String modName, String downloadUrl) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(modName),
          content: Text("Do you want to download '$modName'?"),
          actions: [
            TextButton(
              onPressed: () {
                widget.linkLoader(downloadUrl);
                Navigator.of(context).pop();
              },
              child: const Text('Download'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _showDescriptionDialog(
      BuildContext context, String modName, String description) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(modName),
          content: SingleChildScrollView(
            child: Text(description),
            // If you have markdown content, you can use flutter_markdown package
            // child: MarkdownBody(data: description),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Ok'),
            ),
          ],
        );
      },
    );
  }
}

class ModImage extends StatelessWidget {
  final ScrapedMod mod;

  const ModImage({super.key, required this.mod});

  @override
  Widget build(BuildContext context) {
    final mainImage =
        mod.images?.values.isNotEmpty == true ? mod.images?.values.first : null;

    if (mainImage != null && mainImage.url != null) {
      return MovingTooltipWidget.text(
        message: mainImage.description ?? "",
        child: Image.network(
          mainImage.url!,
          // width: 192.0,
          // height: 160.0,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _defaultImage();
          },
        ),
      );
    } else {
      return _defaultImage();
    }
  }

  Widget _defaultImage() {
    return Container(
      width: 192.0,
      height: 160.0,
      alignment: Alignment.center,
      child: Icon(
        Icons.image_not_supported,
        size: 64.0,
        color: Colors.grey.withOpacity(0.5),
      ),
    );
  }
}

class Tags extends StatelessWidget {
  final ScrapedMod mod;

  const Tags({super.key, required this.mod});

  @override
  Widget build(BuildContext context) {
    final tags = [
      ...?mod.categories,
      ...?mod.sources?.map((source) {
        switch (source) {
          case ModSource.Index:
            return 'Index';
          case ModSource.ModdingSubforum:
            return 'Modding Subforum';
          case ModSource.Discord:
            return 'Discord';
          case ModSource.NexusMods:
            return 'NexusMods';
        }
      }),
    ];

    if (tags.isNotEmpty) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Opacity(opacity: 0.5, child: Icon(Icons.tag, size: 12.0)),
          const SizedBox(width: 6.0),
          Expanded(
            child: Text(
              tags.join(', '),
              style: const TextStyle(fontSize: 11.0),
            ),
          ),
        ],
      );
    } else {
      return const SizedBox.shrink();
    }
  }
}

class BrowserIcon extends StatelessWidget {
  final ScrapedMod mod;
  final double iconOpacity;
  final void Function(String) linkLoader;
  final double size;

  const BrowserIcon({
    super.key,
    required this.mod,
    required this.iconOpacity,
    required this.linkLoader,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final forumUrl = mod.urls?[ModUrlType.Forum];

    if (forumUrl != null && forumUrl.isNotEmpty) {
      return MovingTooltipWidget.text(
        message: 'Open in an external browser.\n$forumUrl',
        child: Opacity(
          opacity: iconOpacity,
          child: SizedBox(
            width: size * 2,
            height: size * 2,
            child: IconButton(
              icon: Icon(Icons.public, size: size),
              onPressed: () {
                InAppBrowser.openWithSystemBrowser(url: WebUri(forumUrl));
              },
            ),
          ),
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }
}

class DiscordIcon extends StatelessWidget {
  final ScrapedMod mod;
  final double iconOpacity;
  final double size;

  const DiscordIcon({
    super.key,
    required this.mod,
    required this.iconOpacity,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final discordUrl = mod.urls?[ModUrlType.Discord];

    if (discordUrl != null && discordUrl.isNotEmpty) {
      return MovingTooltipWidget.text(
        message: 'Open in Discord.\n$discordUrl\nRight-click to copy.',
        child: Opacity(
          opacity: iconOpacity,
          child: SizedBox(
            width: size * 2,
            height: size * 2,
            child: GestureDetector(
              onSecondaryTap: () {
                // Copy to clipboard
                Clipboard.setData(ClipboardData(text: discordUrl));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Discord URL copied to clipboard'),
                  ),
                );
              },
              child: IconButton(
                onPressed: () {
                  discordUrl
                      .toString()
                      .replaceAll("https://", "discord://")
                      .replaceAll("http://", "discord://")
                      .openAsUriInBrowser();
                },
                icon: Icon(
                  Icons.chat,
                  size: size,
                ),
              ),
            ),
          ),
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }
}

class NexusModsIcon extends StatelessWidget {
  final ScrapedMod mod;
  final double iconOpacity;
  final double size;

  const NexusModsIcon({
    super.key,
    required this.mod,
    required this.iconOpacity,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final nexusModsUrl = mod.urls?[ModUrlType.NexusMods];

    if (nexusModsUrl != null && nexusModsUrl.isNotEmpty) {
      return MovingTooltipWidget.text(
        message: 'Open in NexusMods.\n$nexusModsUrl',
        child: Opacity(
          opacity: iconOpacity,
          child: SizedBox(
            width: size * 2,
            height: size * 2,
            child: IconButton(
              icon: Icon(
                Icons.extension,
                size: size,
              ), // Use appropriate icon
              onPressed: () {
                // Implement opening NexusMods URL
              },
            ),
          ),
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }
}

class DirectDownloadIcon extends StatelessWidget {
  final ScrapedMod mod;
  final double iconOpacity;
  final void Function(String) linkLoader;
  final double size;

  const DirectDownloadIcon({
    super.key,
    required this.mod,
    required this.iconOpacity,
    required this.linkLoader,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final downloadUrl = mod.urls?[ModUrlType.DirectDownload];

    if (downloadUrl != null && downloadUrl.isNotEmpty) {
      return MovingTooltipWidget.text(
        message: 'Download.\n$downloadUrl',
        child: Opacity(
          opacity: iconOpacity,
          child: SizedBox(
            width: size * 2,
            height: size * 2,
            child: IconButton(
              icon: Icon(Icons.download, size: size),
              onPressed: () {
                linkLoader(downloadUrl);
              },
            ),
          ),
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }
}

class DebugIcon extends StatelessWidget {
  final ScrapedMod mod;
  final double iconOpacity;
  final double size;

  const DebugIcon({
    super.key,
    required this.mod,
    required this.iconOpacity,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return MovingTooltipWidget.text(
      message: 'Display all info (debug)',
      child: Opacity(
        opacity: iconOpacity,
        child: SizedBox(
          width: size * 2,
          height: size * 2,
          child: IconButton(
            icon: Icon(
              Icons.bug_report,
              size: size,
            ),
            onPressed: () {
              _showDebugDialog(context, mod);
            },
          ),
        ),
      ),
    );
  }

  void _showDebugDialog(BuildContext context, ScrapedMod mod) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(mod.name),
          content: SingleChildScrollView(
            child: SelectableText(mod.toString()),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}