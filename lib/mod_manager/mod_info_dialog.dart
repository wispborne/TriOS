import 'package:dart_extensions_methods/dart_extension_methods.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:trios/catalog/models/forum_mod_index.dart';
import 'package:trios/catalog/models/scraped_mod.dart';
import 'package:trios/mod_manager/mod_manager_extensions.dart';
import 'package:trios/mod_manager/mod_manager_logic.dart';
import 'package:trios/models/mod.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/themes/theme_manager.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/trios/download_manager/download_manager.dart';
import 'package:trios/utils/dialogs.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/widgets/mod_type_icon.dart';
import 'package:trios/widgets/moving_tooltip.dart';
import 'package:trios/widgets/palette_generator_mixin.dart';
import 'package:trios/widgets/text_trios.dart';
import 'package:url_launcher/url_launcher.dart';

/// Shows the mod info dialog for a mod (installed, catalog, or both).
void showModInfoDialog(
  BuildContext context, {
  Mod? mod,
  ScrapedMod? scrapedMod,
  ForumModIndex? forumModIndex,
  VersionCheckComparison? versionCheckComparison,
}) {
  showDialog(
    context: context,
    builder: (context) => ModInfoDialog(
      mod: mod,
      scrapedMod: scrapedMod,
      forumModIndex: forumModIndex,
      versionCheckComparison: versionCheckComparison,
    ),
  );
}

class ModInfoDialog extends ConsumerStatefulWidget {
  final Mod? mod;
  final ScrapedMod? scrapedMod;
  final ForumModIndex? forumModIndex;
  final VersionCheckComparison? versionCheckComparison;

  const ModInfoDialog({
    super.key,
    this.mod,
    this.scrapedMod,
    this.forumModIndex,
    this.versionCheckComparison,
  });

  @override
  ConsumerState<ModInfoDialog> createState() => _ModInfoDialogState();
}

class _ModInfoDialogState extends ConsumerState<ModInfoDialog>
    with PaletteGeneratorMixin {
  @override
  String? getIconPath() =>
      widget.mod?.findFirstEnabledOrHighestVersion?.iconFilePath;

  // --- Resolved data helpers ---

  String get _modName {
    final variant = widget.mod?.findFirstEnabledOrHighestVersion;
    return variant?.modInfo.name ?? widget.scrapedMod?.name ?? "(unknown)";
  }

  String? get _author {
    final variant = widget.mod?.findFirstEnabledOrHighestVersion;
    final installed = variant?.modInfo.author;
    if (installed.isNotNullOrEmpty()) return installed;
    final scraped = widget.scrapedMod?.getAuthors();
    if (scraped != null && scraped.isNotEmpty) return scraped.join(", ");
    return null;
  }

  String? get _version {
    final variant = widget.mod?.findFirstEnabledOrHighestVersion;
    return variant?.modInfo.version?.toString() ??
        widget.scrapedMod?.modVersion;
  }

  String? get _gameVersion {
    final variant = widget.mod?.findFirstEnabledOrHighestVersion;
    return variant?.modInfo.gameVersion ?? widget.scrapedMod?.gameVersionReq;
  }

  String? get _description {
    final variant = widget.mod?.findFirstEnabledOrHighestVersion;
    final installed = variant?.modInfo.description;
    if (installed.isNotNullOrEmpty()) return installed;
    return widget.scrapedMod?.description ?? widget.scrapedMod?.summary;
  }

  ModVariant? get _variant => widget.mod?.findFirstEnabledOrHighestVersion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final paletteTriosTheme = paletteGenerator.toTriOSTheme(context);
    final paletteTheme = paletteTriosTheme != null
        ? ThemeManager.convertToThemeData(paletteTriosTheme)
        : theme;

    return Builder(
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 60,
            vertical: 40,
          ),
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with palette theme
                Theme(data: paletteTheme, child: _buildHeader(paletteTheme)),
                // Scrollable body
                Flexible(
                  child: SingleChildScrollView(
                    padding: const .symmetric(horizontal: 16, vertical: 8),
                    child: SelectionArea(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 8,
                        children: [
                          _buildLinkButtons(theme),
                          _buildImageGallery(),
                          _buildModInfoCard(theme),
                          _buildModRepoCard(theme),
                          _buildModIndexCard(theme),
                        ].where((w) => w != null).cast<Widget>().toList(),
                      ),
                    ),
                  ),
                ),
                // Action bar
                _buildActionBar(paletteTheme),
              ],
            ),
          ),
        );
      },
    );
  }

  // ───────────────────── HEADER ─────────────────────

  Widget _buildHeader(ThemeData paletteTheme) {
    final iconPath = _variant?.iconFilePath;
    final isUtility = _variant?.modInfo.isUtility ?? false;
    final isTotalConversion = _variant?.modInfo.isTotalConversion ?? false;

    return Container(
      color: paletteTheme.cardColor,
      padding: const EdgeInsets.fromLTRB(16, 20, 8, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (iconPath != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Image.file(iconPath.toFile(), width: 64, height: 64),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 4,
              children: [
                Text(
                  _modName,
                  style: paletteTheme.textTheme.headlineSmall?.copyWith(
                    fontFamily: "Orbitron",
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_author != null)
                  Text("by $_author", style: paletteTheme.textTheme.bodyMedium),
                Row(
                  children: [
                    if (_version != null)
                      Text(
                        "v$_version",
                        style: paletteTheme.textTheme.bodySmall?.copyWith(
                          fontFamily: GoogleFonts.sourceCodePro().fontFamily,
                        ),
                      ),
                    if (isUtility || isTotalConversion) ...[
                      const SizedBox(width: 12),
                      ModTypeIcon(modVariant: _variant!),
                      const SizedBox(width: 4),
                      Text(
                        isTotalConversion ? "Total Conversion" : "Utility Mod",
                        style: paletteTheme.textTheme.bodySmall,
                      ),
                    ],
                    if (_gameVersion != null) ...[
                      const SizedBox(width: 12),
                      Text(
                        "Starsector $_gameVersion",
                        style: paletteTheme.textTheme.bodySmall?.copyWith(
                          fontFamily: GoogleFonts.sourceCodePro().fontFamily,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  // ───────────────────── LINK BUTTONS ─────────────────────

  Widget? _buildLinkButtons(ThemeData theme) {
    final links = <(String, IconData, String)>[];

    // From version checker
    final vcInfo = _variant?.versionCheckerInfo;
    if (vcInfo?.modThreadId.isNotNullOrEmpty() ?? false) {
      links.add((
        "Forum",
        Icons.forum,
        "${Constants.forumModPageUrl}${vcInfo!.modThreadId}",
      ));
    }
    if (vcInfo?.modNexusId.isNotNullOrEmpty() ?? false) {
      links.add((
        "NexusMods",
        Icons.store,
        "${Constants.nexusModsPageUrl}${vcInfo!.modNexusId}",
      ));
    }
    if (vcInfo?.changelogURL.isNotNullOrEmpty() ?? false) {
      links.add(("Changelog", Icons.history, vcInfo!.changelogURL!));
    }
    if (vcInfo?.directDownloadURL.isNotNullOrEmpty() ?? false) {
      links.add(("Download", Icons.download, vcInfo!.directDownloadURL!));
    }

    // From catalog
    final urls = widget.scrapedMod?.getUrls() ?? {};
    if (links.every((l) => l.$1 != "Forum") &&
        urls.containsKey(ModUrlType.Forum)) {
      links.add(("Forum", Icons.forum, urls[ModUrlType.Forum]!));
    }
    if (links.every((l) => l.$1 != "NexusMods") &&
        urls.containsKey(ModUrlType.NexusMods)) {
      links.add(("NexusMods", Icons.store, urls[ModUrlType.NexusMods]!));
    }
    if (urls.containsKey(ModUrlType.Discord)) {
      links.add(("Discord", Icons.discord, urls[ModUrlType.Discord]!));
    }

    if (links.isEmpty) return null;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: links.map((link) {
        return MovingTooltipWidget.text(
          message: link.$3,
          child: ElevatedButton.icon(
            icon: Icon(link.$2, size: 16),
            label: Text(link.$1),
            onPressed: () => launchUrl(Uri.parse(link.$3)),
          ),
        );
      }).toList(),
    );
  }

  // ───────────────────── IMAGE GALLERY ─────────────────────

  Widget? _buildImageGallery() {
    final images = widget.scrapedMod?.getImages() ?? {};
    if (images.isEmpty) return null;

    return SizedBox(
      height: 200,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final image = images.values.elementAt(index);
          final url = image.proxyUrl ?? image.url;
          if (url == null) return const SizedBox();
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              url,
              height: 200,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                width: 200,
                height: 200,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: const Icon(Icons.broken_image, size: 32),
              ),
            ),
          );
        },
      ),
    );
  }

  // ───────────────────── MOD INFO CARD (consolidated) ─────────────────────

  Widget? _buildModInfoCard(ThemeData theme) {
    final sections = <Widget>[];

    // Description
    final desc = _description;
    if (desc.isNotNullOrEmpty()) {
      sections.add(
        _buildCardSection(
          theme,
          title: "Description",
          child: TextTriOS(
            desc!,
            maxLines: 6,
            style: theme.textTheme.bodyMedium,
          ),
        ),
      );
    }

    // Installed versions + update status + categories + sources
    final statusContent = _buildStatusContent(theme);
    if (statusContent != null) {
      sections.add(statusContent);
    }

    // Dependencies
    final deps = _buildDependenciesContent(theme);
    if (deps != null) {
      sections.add(
        _buildCardSection(theme, title: "Dependencies", child: deps),
      );
    }

    // Dependents
    final dependents = _buildDependentsContent(theme);
    if (dependents != null) {
      sections.add(
        _buildCardSection(theme, title: "Dependents", child: dependents),
      );
    }

    // TriOS metadata
    final metadata = _buildTriOSMetadataContent(theme);
    if (metadata != null) {
      sections.add(_buildCardSection(theme, title: "TriOS", child: metadata));
    }

    if (sections.isEmpty) return null;

    return _SectionCard(title: "Mod Info", theme: theme, children: sections);
  }

  Widget _buildCardSection(
    ThemeData theme, {
    required String title,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 4,
      children: [
        Text(
          title,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
          ),
        ),
        child,
      ],
    );
  }

  Widget? _buildStatusContent(ThemeData theme) {
    final mod = widget.mod;
    final comparison = widget.versionCheckComparison;
    final children = <Widget>[];

    if (mod != null) {
      final variants = mod.modVariants.sortedDescending();
      if (variants.isNotEmpty) {
        children.add(
          _buildCardSection(
            theme,
            title: variants.length > 1
                ? "Installed Versions"
                : "Installed Version",
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 16,
              children: variants.map((variant) {
                final isEnabled = mod.isEnabled(variant);
                return MovingTooltipWidget.text(
                  message: "Open mod folder",
                  child: ElevatedButton.icon(
                    icon: Icon(
                      Icons.folder_open,
                      size: 18,
                      color: theme.colorScheme.onSurface,
                    ),
                    iconAlignment: .end,
                    onPressed: () =>
                        variant.modFolder.absolute.path.openAsUriInBrowser(),
                    label: Row(
                      spacing: 8,
                      children: [
                        Text(
                          "${variant.modInfo.version}",
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: isEnabled ? FontWeight.bold : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      }

      if (comparison != null && comparison.comparisonInt != null) {
        final cmp = comparison.comparisonInt!;
        final label = cmp < 0
            ? (comparison.remoteVersionCheck?.remoteVersion?.modVersion
                      ?.toString() ??
                  "Available")
            : "Up to date";
        children.add(
          _buildCardSection(
            theme,
            title: "Update",
            child: Text(label, style: theme.textTheme.bodyMedium),
          ),
        );
      }
    }

    if (children.isEmpty) return null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: children,
    );
  }

  Widget? _buildDependenciesContent(ThemeData theme) {
    final variant = _variant;
    if (variant == null || variant.modInfo.dependencies.isEmpty) return null;

    final modVariants = ref.watch(AppState.modVariants).value;
    final enabledMods = ref
        .watch(AppState.enabledModsFile)
        .value
        ?.enabledMods
        .toList();
    final gameVersion = ref.watch(AppState.starsectorVersion).value;
    if (modVariants == null || enabledMods == null) return null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: variant.modInfo.dependencies.map((dep) {
        final state = dep.isSatisfiedByAny(
          modVariants,
          enabledMods,
          gameVersion,
        );
        return Text(
          "  ${dep.formattedNameVersion} ${state.getDependencyStateText()}",
          style: theme.textTheme.bodyMedium?.copyWith(
            color:
                getStateColorForDependencyText(state) ??
                theme.textTheme.bodyMedium?.color,
          ),
        );
      }).toList(),
    );
  }

  Widget? _buildDependentsContent(ThemeData theme) {
    final variant = _variant;
    if (variant == null) return null;

    final modVariants = ref.watch(AppState.modVariants).value;
    final enabledMods = ref
        .watch(AppState.enabledModsFile)
        .value
        ?.enabledMods
        .toList();
    final allMods = ref.watch(AppState.mods);
    if (modVariants == null || enabledMods == null) return null;

    final dependentVariants = modVariants
        .where(
          (v) => v.modInfo.dependencies.any((dep) {
            final satisfiedBy = dep.isSatisfiedBy(variant, enabledMods);
            return satisfiedBy is VersionWarning ||
                satisfiedBy is Satisfied ||
                satisfiedBy is Disabled;
          }),
        )
        .toList();

    final dependents = dependentVariants.getAsMods(allMods);
    if (dependents.isEmpty) return null;

    final enabled = dependents.where((m) => m.hasEnabledVariant).toList();
    final disabled = dependents.where((m) => !m.hasEnabledVariant).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (enabled.isNotEmpty)
          Text(
            "  Enabled: ${enabled.map((m) => m.findFirstEnabledOrHighestVersion?.modInfo.name ?? m.id).join(", ")}",
            style: theme.textTheme.bodyMedium,
          ),
        if (disabled.isNotEmpty)
          Opacity(
            opacity: 0.7,
            child: Text(
              "  Disabled: ${disabled.map((m) => m.findFirstEnabledOrHighestVersion?.modInfo.name ?? m.id).join(", ")}",
              style: theme.textTheme.bodyMedium,
            ),
          ),
      ],
    );
  }

  Widget? _buildTriOSMetadataContent(ThemeData theme) {
    final mod = widget.mod;
    if (mod == null) return null;

    final modMetadata = ref
        .watch(AppState.modsMetadata)
        .value
        ?.getMergedModMetadata(mod.id);
    if (modMetadata == null) return null;

    final dateFormat = Constants.dateTimeFormat;
    final isMuted = modMetadata.areUpdatesMuted;

    return Wrap(
      spacing: 24,
      runSpacing: 4,
      children: [
        Text(
          "First seen: ${dateFormat.format(DateTime.fromMillisecondsSinceEpoch(modMetadata.firstSeen))}",
          style: theme.textTheme.bodyMedium,
        ),
        if (modMetadata.lastEnabled != null)
          Text(
            "Last enabled: ${dateFormat.format(DateTime.fromMillisecondsSinceEpoch(modMetadata.lastEnabled!))}",
            style: theme.textTheme.bodyMedium,
          ),
        Text(
          "Updates: ${isMuted ? 'Muted' : 'Unmuted'}",
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget? _buildModRepoCard(ThemeData theme) {
    final children = <Widget>[];

    final scrapedCategories = widget.scrapedMod?.getCategories() ?? [];
    if (scrapedCategories.isNotEmpty) {
      children.add(
        _buildCardSection(
          theme,
          title: "Categories",
          child: Text(
            scrapedCategories.join(", "),
            style: theme.textTheme.bodyMedium,
          ),
        ),
      );
    }

    final scrapedSources = widget.scrapedMod?.getSources() ?? [];
    if (scrapedSources.isNotEmpty) {
      children.add(
        _buildCardSection(
          theme,
          title: "Sources",
          child: Text(
            scrapedSources.map((s) => s.name).join(", "),
            style: theme.textTheme.bodyMedium,
          ),
        ),
      );
    }

    if (children.isEmpty) return null;

    return _SectionCard(title: "Mod Repo", theme: theme, children: children);
  }

  // ───────────────────── MOD INDEX CARD (forum data) ─────────────────────

  Widget? _buildModIndexCard(ThemeData theme) {
    final forum = widget.forumModIndex;
    if (forum == null) return null;

    final dateFormat = DateFormat.yMMMd();
    final rows = <(String, String)>[
      ("Views", NumberFormat.compact().format(forum.views)),
      ("Replies", NumberFormat.compact().format(forum.replies)),
      if (forum.lastPostDate != null)
        ("Last Post", dateFormat.format(forum.lastPostDate!)),
      if (forum.createdDate != null)
        ("Created", dateFormat.format(forum.createdDate!)),
      if (forum.category != null) ("Board", forum.category!),
      ("WIP", forum.isWip ? "Yes" : "No"),
    ];

    return _SectionCard(
      title: "Mod Index",
      theme: theme,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 4,
          children: rows
              .map(
                (row) => Row(
                  children: [
                    SizedBox(
                      width: 100,
                      child: Text(
                        row.$1,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(row.$2, style: theme.textTheme.bodyMedium),
                    ),
                  ],
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  // ───────────────────── ACTION BAR ─────────────────────

  Widget _buildActionBar(ThemeData theme) {
    final mod = widget.mod;
    final isGameRunning = ref.watch(AppState.isGameRunning).value == true;

    // Catalog-only: show only link buttons
    if (mod == null) {
      final bestUrl = widget.scrapedMod?.getBestWebsiteUrl();
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: theme.dividerColor)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          spacing: 8,
          children: [
            if (bestUrl != null)
              FilledButton.icon(
                icon: const Icon(Icons.open_in_browser, size: 18),
                label: const Text("Open Page"),
                onPressed: () => launchUrl(Uri.parse(bestUrl)),
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Close"),
            ),
          ],
        ),
      );
    }

    // Installed mod: show full action bar
    final isEnabled = mod.hasEnabledVariant;
    final hasUpdate = (widget.versionCheckComparison?.comparisonInt ?? 0) < 0;
    final variants = mod.modVariants.sortedDescending();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        spacing: 8,
        children: [
          // Enable/Disable
          if (isEnabled)
            MovingTooltipWidget.text(
              message: isGameRunning ? "Game is running" : "Disable this mod",
              child: OutlinedButton.icon(
                icon: const Icon(Icons.toggle_off, size: 18),
                label: const Text("Disable"),
                onPressed: isGameRunning
                    ? null
                    : () {
                        ref
                            .read(modManager.notifier)
                            .changeActiveModVariant(mod, null);
                        Navigator.of(context).pop();
                      },
              ),
            )
          else if (variants.length == 1)
            MovingTooltipWidget.text(
              message: isGameRunning ? "Game is running" : "Enable this mod",
              child: FilledButton.icon(
                icon: const Icon(Icons.toggle_on, size: 18),
                label: const Text("Enable"),
                onPressed: isGameRunning
                    ? null
                    : () {
                        ref
                            .read(modManager.notifier)
                            .changeActiveModVariantWithForceModGameVersionDialogIfNeeded(
                              mod,
                              variants.first,
                            );
                        Navigator.of(context).pop();
                      },
              ),
            )
          else
            MovingTooltipWidget.text(
              message: isGameRunning ? "Game is running" : "Enable a version",
              child: MenuAnchor(
                menuChildren: variants.map((v) {
                  return MenuItemButton(
                    onPressed: isGameRunning
                        ? null
                        : () {
                            ref
                                .read(modManager.notifier)
                                .changeActiveModVariantWithForceModGameVersionDialogIfNeeded(
                                  mod,
                                  v,
                                );
                            Navigator.of(context).pop();
                          },
                    child: Text("v${v.modInfo.version}"),
                  );
                }).toList(),
                builder: (context, controller, child) {
                  return FilledButton.icon(
                    icon: const Icon(Icons.toggle_on, size: 18),
                    label: const Text("Enable"),
                    onPressed: isGameRunning
                        ? null
                        : () {
                            if (controller.isOpen) {
                              controller.close();
                            } else {
                              controller.open();
                            }
                          },
                  );
                },
              ),
            ),

          // Update
          if (hasUpdate)
            MovingTooltipWidget.text(
              message: "Update available",
              child: FilledButton.tonalIcon(
                icon: const Icon(Icons.update, size: 18),
                label: const Text("Update"),
                onPressed: () {
                  final directUrl =
                      _variant?.versionCheckerInfo?.directDownloadURL;
                  if (directUrl != null) {
                    ref
                        .read(downloadManager.notifier)
                        .downloadAndInstallMod(
                          _variant!.modInfo.nameOrId,
                          directUrl,
                          activateVariantOnComplete: false,
                          modInfo: _variant!.modInfo,
                        );
                    Navigator.of(context).pop();
                  }
                },
              ),
            ),

          // Open Folder
          MovingTooltipWidget.text(
            message: "Open mod folder",
            child: OutlinedButton.icon(
              icon: const Icon(Icons.folder_open, size: 18),
              label: const Text("Open Folder"),
              onPressed: () =>
                  _variant?.modFolder.absolute.path.openAsUriInBrowser(),
            ),
          ),

          // VRAM Check
          MovingTooltipWidget.text(
            message: "Estimate VRAM usage",
            child: OutlinedButton.icon(
              icon: const Icon(Icons.memory, size: 18),
              label: const Text("VRAM"),
              onPressed: () {
                ref
                    .read(AppState.vramEstimatorProvider.notifier)
                    .startEstimating(
                      variantsToCheck: [mod.findFirstEnabledOrHighestVersion!],
                    );
              },
            ),
          ),

          const Spacer(),

          // Delete
          MovingTooltipWidget.text(
            message: isGameRunning ? "Game is running" : "Delete this mod",
            child: OutlinedButton.icon(
              icon: Icon(
                Icons.delete,
                size: 18,
                color: isGameRunning ? null : theme.colorScheme.onSurface,
              ),
              label: Text(
                "Delete",
                style: TextStyle(
                  color: isGameRunning ? null : theme.colorScheme.onSurface,
                ),
              ),
              onPressed: isGameRunning
                  ? null
                  : () {
                      Navigator.of(context).pop();
                      showDeleteModFoldersConfirmationDialog(
                        mod.modVariants.toList(),
                        context,
                        ref,
                      );
                    },
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────── SHARED WIDGETS ─────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final ThemeData theme;

  const _SectionCard({
    required this.title,
    required this.children,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 10,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}
