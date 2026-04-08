import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_color/flutter_color.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/catalog/models/scraped_mod.dart';
import 'package:trios/dashboard/version_check_icon.dart';
import 'package:trios/mod_manager/mod_manager_logic.dart';
import 'package:trios/models/mod.dart';
import 'package:trios/thirdparty/flutter_context_menu/core/utils/extensions.dart';
import 'package:trios/trios/constants_theme.dart';
import 'package:trios/trios/download_manager/download_manager.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/widgets/conditional_wrap.dart';
import 'package:trios/widgets/moving_tooltip.dart';
import 'package:trios/widgets/stroke_text.dart';
import 'package:trios/widgets/text_trios.dart';

class ScrapedModCard extends StatefulWidget {
  final ScrapedMod mod;
  final void Function(String) linkLoader;
  final bool isSelected;
  final Mod? installedMod;
  final VersionCheckComparison? versionCheckComparison;

  const ScrapedModCard({
    super.key,
    required this.mod,
    required this.linkLoader,
    this.isSelected = false,
    this.installedMod,
    this.versionCheckComparison,
  });

  @override
  State<ScrapedModCard> createState() => _ScrapedModCardState();
}

class _ScrapedModCardState extends State<ScrapedModCard> {
  bool isBeingHovered = false;

  Color _statusBarColor(ThemeData theme) {
    final mod = widget.installedMod;
    if (mod == null) return Colors.transparent;
    if (mod.isEnabledInGame) {
      return theme.statusColors.success.withValues(alpha: 0.7);
    }
    return theme.statusColors.neutral.withValues(alpha: 0.5);
  }

  @override
  Widget build(BuildContext context) {
    final mod = widget.mod;
    final urls = mod.urls;

    final theme = Theme.of(context);
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
      child: Builder(
        builder: (context) {
          final websiteUrl = mod.getBestWebsiteUrl();
          final hasClickableLink =
              websiteUrl != null ||
              urls?.containsKey(ModUrlType.DirectDownload) == true;

          return Card(
            margin: const EdgeInsets.all(0),
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
              side: BorderSide(
                color: theme.colorScheme.surface.withOpacity(0.5),
              ),
            ),
            child: ConditionalWrap(
              condition: hasClickableLink,
              wrapper: (child) => InkWell(
                onTap: () {
                  if (urls == null) {
                    return;
                  }

                  if (websiteUrl != null) {
                    widget.linkLoader(websiteUrl);
                  } else if (urls.containsKey(ModUrlType.DirectDownload)) {
                    _showDirectDownloadDialog(
                      context,
                      mod.name,
                      urls[ModUrlType.DirectDownload]!,
                    );
                  }
                },
                child: child,
              ),
              child: Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: widget.isSelected
                          ? theme.cardColor.lighter(5)
                          : null,
                    ),
                    child: Row(
                      children: [
                        Stack(
                          children: [
                            ConstrainedBox(
                              constraints: const BoxConstraints(
                                maxWidth: 80.0,
                                minWidth: 80.0,
                                maxHeight: 80.0,
                              ),
                              child: ModImage(mod: mod),
                            ),
                          ],
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(
                              left: 16.0,
                              right: 16.0,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  spacing: 4,
                                  children: [
                                    Flexible(
                                      child: TextTriOS(
                                        mod.name.isNotEmpty ? mod.name : '???',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14.0,
                                          fontFamily:
                                              TriOSThemeConstants.orbitron,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (widget
                                            .versionCheckComparison
                                            ?.hasUpdate ==
                                        true)
                                      Padding(
                                        padding: const EdgeInsets.only(left: 6),
                                        child: MovingTooltipWidget.text(
                                          message: 'Update available',
                                          child:
                                              VersionCheckIcon.fromComparison(
                                                comparison: widget
                                                    .versionCheckComparison,
                                                modId:
                                                    widget.installedMod?.id ??
                                                    '',
                                                theme: theme,
                                              ),
                                        ),
                                      ),
                                  ],
                                ),
                                if (mod.authorsList?.isNotEmpty == true)
                                  Text(
                                    mod.authorsList!.join(', '),
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      fontSize: 10,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                if ((mod.summary?.isNotEmpty ?? false) ||
                                    (mod.description?.isNotEmpty ?? false))
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: ConditionalWrap(
                                      condition:
                                          mod.description?.isNotEmpty == true,
                                      wrapper: (child) =>
                                          MovingTooltipWidget.framed(
                                            tooltipWidget: SizedBox(
                                              width: 400,
                                              child: Text(
                                                mod.description ?? '',
                                                style:
                                                    theme.textTheme.bodySmall,
                                              ),
                                            ),
                                            child: Material(
                                              color: Colors.transparent,
                                              child: InkWell(
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                                hoverColor: theme
                                                    .colorScheme
                                                    .onSurface
                                                    .withValues(alpha: 0.08),
                                                onTap: () =>
                                                    _showDescriptionDialog(
                                                      context,
                                                      mod.name,
                                                      mod.description!,
                                                    ),
                                                child: child,
                                              ),
                                            ),
                                          ),
                                      child: Text(
                                        (mod.summary ?? mod.description)!
                                            .split('\n')
                                            .where((line) => line.isNotEmpty)
                                            .take(2)
                                            .join('\n'),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.labelSmall,
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 8.0),
                                Tags(mod: mod),
                              ],
                            ),
                          ),
                        ),
                        Builder(
                          builder: (context) {
                            const size = 14.0;
                            return Column(
                              mainAxisAlignment: .start,
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
                                DebugIcon(
                                  mod: mod,
                                  iconOpacity: isBeingHovered ? 1.0 : 0.7,
                                  size: size,
                                ),
                                CatalogDownloadButton(
                                  mod: mod,
                                  installedMod: widget.installedMod,
                                  versionCheckComparison:
                                      widget.versionCheckComparison,
                                  linkLoader: widget.linkLoader,
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  if (mod.gameVersionReq?.isNotEmpty == true)
                    Positioned(
                      left: 8,
                      top: 4,
                      child: _ScrapedModGameVersionReq(theme: theme, mod: mod),
                    ),
                  if (widget.installedMod != null)
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      child: MovingTooltipWidget.text(
                        message: widget.installedMod!.isEnabledInGame
                            ? 'Enabled'
                            : 'Installed, disabled',
                        child: Container(
                          width: 4,
                          color: _statusBarColor(theme),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showDirectDownloadDialog(
    BuildContext context,
    String modName,
    String downloadUrl,
  ) {
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
    BuildContext context,
    String modName,
    String description,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(modName),
          content: SingleChildScrollView(
            child: SelectableText(
              description,
              style: context.theme.textTheme.bodyMedium,
            ),
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

class _ScrapedModGameVersionReq extends StatelessWidget {
  const _ScrapedModGameVersionReq({required this.theme, required this.mod});

  final ThemeData theme;
  final ScrapedMod mod;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 2),
      child: MovingTooltipWidget.text(
        message: "Game version required: ${mod.gameVersionReq}",
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: theme.cardColor.withOpacity(0.9),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 6,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(
                    color: theme.colorScheme.onSurface.darker(15),
                    strokeAlign: BorderSide.strokeAlignOutside,
                    width: 1,
                  ),
                ),
                child: SizedBox(
                  width: 14,
                  height: 14,
                  child: Transform.translate(
                    offset: const Offset(2.0, -1.0),
                    child: StrokeText(
                      'S',
                      strokeWidth: 1,
                      borderOnTop: true,
                      strokeColor: theme.colorScheme.surfaceTint.darker(70),
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontFamily: "Orbitron",
                        fontSize: 11,
                        color: theme.colorScheme.onSurface.darker(5),
                      ),
                    ),
                  ),
                ),
              ),
              TextTriOS(
                mod.gameVersionReq ?? "",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.0,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.labelLarge?.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ModImage extends StatelessWidget {
  final ScrapedMod mod;

  const ModImage({super.key, required this.mod});

  @override
  Widget build(BuildContext context) {
    final mainImage = mod.images?.values.isNotEmpty == true
        ? mod.images?.values.first
        : null;

    if (mainImage != null && mainImage.url != null) {
      return MovingTooltipWidget.text(
        message: mainImage.description ?? "",
        child: Image.network(
          mainImage.url!,
          fit: .scaleDown,
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
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(
                  context,
                ).textTheme.labelSmall?.color?.withOpacity(0.6),
              ),
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
                forumUrl.openAsUriInBrowser();
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
                icon: Icon(Icons.discord, size: size),
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
              icon: Icon(Icons.extension, size: size),
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

enum _CatalogDownloadState {
  updateDirectDownload,
  updateWebsite,
  installedEnabled,
  installedDisabled,
  notInstalledDirectDownload,
  notInstalledWebsite,
  noDownloadLink,
}

class CatalogDownloadButton extends ConsumerWidget {
  final ScrapedMod mod;
  final Mod? installedMod;
  final VersionCheckComparison? versionCheckComparison;
  final void Function(String) linkLoader;

  const CatalogDownloadButton({
    super.key,
    required this.mod,
    required this.installedMod,
    required this.versionCheckComparison,
    required this.linkLoader,
  });

  _CatalogDownloadState _resolveState() {
    final hasDirectDownload =
        mod.urls?[ModUrlType.DirectDownload]?.isNotEmpty == true;
    final hasWebsite = mod.getBestWebsiteUrl() != null;
    final hasUpdate = versionCheckComparison?.hasUpdate == true;

    if (installedMod != null && hasUpdate) {
      return hasDirectDownload
          ? _CatalogDownloadState.updateDirectDownload
          : _CatalogDownloadState.updateWebsite;
    }
    if (installedMod != null) {
      return installedMod!.isEnabledInGame
          ? _CatalogDownloadState.installedEnabled
          : _CatalogDownloadState.installedDisabled;
    }
    if (hasDirectDownload) {
      return _CatalogDownloadState.notInstalledDirectDownload;
    }
    if (hasWebsite) return _CatalogDownloadState.notInstalledWebsite;
    return _CatalogDownloadState.noDownloadLink;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = _resolveState();

    final IconData icon;
    final Color backgroundColor;
    final Color foregroundColor;
    final String tooltip;
    final VoidCallback? onPressed;

    switch (state) {
      case _CatalogDownloadState.updateDirectDownload:
        icon = Icons.download;
        backgroundColor = theme.statusColors.info;
        foregroundColor = theme.statusColors.onInfo;
        tooltip = 'Update available';
        onPressed = () => _confirmAndDownload(
          context,
          ref,
          mod.name,
          mod.urls![ModUrlType.DirectDownload]!,
        );
      case _CatalogDownloadState.updateWebsite:
        icon = Icons.open_in_browser;
        backgroundColor = theme.statusColors.info;
        foregroundColor = theme.statusColors.onInfo;
        tooltip = 'Update available — open download page';
        onPressed = () => linkLoader(mod.getBestWebsiteUrl()!);
      case _CatalogDownloadState.installedEnabled:
        icon = Icons.check;
        backgroundColor = theme.statusColors.success.withValues(alpha: 0.85);
        foregroundColor = theme.statusColors.onSuccess;
        tooltip = 'Enabled — click to disable';
        onPressed = () => _toggleMod(ref, enabled: false);
      case _CatalogDownloadState.installedDisabled:
        icon = Icons.check;
        backgroundColor = theme.statusColors.neutral.withValues(alpha: 0.7);
        foregroundColor = theme.statusColors.onNeutral;
        tooltip = 'Installed, disabled — click to enable';
        onPressed = () => _toggleMod(ref, enabled: true);
      case _CatalogDownloadState.notInstalledDirectDownload:
        icon = Icons.download;
        backgroundColor = theme.statusColors.info;
        foregroundColor = theme.statusColors.onInfo;
        tooltip = 'Download ${mod.name}';
        onPressed = () => _confirmAndDownload(
          context,
          ref,
          mod.name,
          mod.urls![ModUrlType.DirectDownload]!,
        );
      case _CatalogDownloadState.notInstalledWebsite:
        icon = Icons.open_in_browser;
        backgroundColor = theme.statusColors.info;
        foregroundColor = theme.statusColors.onInfo;
        tooltip = 'Download from website';
        onPressed = () => linkLoader(mod.getBestWebsiteUrl()!);
      case _CatalogDownloadState.noDownloadLink:
        icon = Icons.download;
        backgroundColor = theme.colorScheme.surfaceContainer.withValues(
          alpha: 0.5,
        );
        foregroundColor = theme.disabledColor;
        tooltip = 'No download available';
        onPressed = null;
    }

    return MovingTooltipWidget.text(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(color: backgroundColor, shape: .circle),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(80),
            child: SizedBox(
              width: 28,
              height: 28,
              child: Icon(icon, size: 18, color: foregroundColor),
            ),
          ),
        ),
      ),
    );
  }

  void _confirmAndDownload(
    BuildContext context,
    WidgetRef ref,
    String modName,
    String downloadUrl,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(modName),
        content: Text("Do you want to download '$modName'?"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref
                  .read(downloadManager.notifier)
                  .downloadAndInstallMod(
                    modName,
                    downloadUrl,
                    activateVariantOnComplete: false,
                  );
            },
            child: const Text('Download'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _toggleMod(WidgetRef ref, {required bool enabled}) {
    final mod = installedMod;
    if (mod == null) return;

    if (enabled) {
      final variant = mod.findHighestVersion;
      if (variant == null) return;
      ref.read(modManager.notifier).changeActiveModVariant(mod, variant);
    } else {
      ref.read(modManager.notifier).changeActiveModVariant(mod, null);
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
            icon: Icon(Icons.bug_report, size: size),
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
          content: SingleChildScrollView(child: SelectableText(mod.toString())),
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
