import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_color/flutter_color.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:trios/shipWeaponViewer/models/weapon.dart';
import 'package:trios/shipWeaponViewer/weaponsManager.dart';
import 'package:trios/thirdparty/pluto_grid_plus/lib/pluto_grid_plus.dart';
import 'package:trios/trios/settings/settings.dart';
import 'package:trios/utils/logging.dart';
import 'package:trios/widgets/checkbox_with_label.dart';

class WeaponPage extends ConsumerStatefulWidget {
  const WeaponPage({super.key});

  @override
  ConsumerState<WeaponPage> createState() => _WeaponPageState();
}

class _WeaponPageState extends ConsumerState<WeaponPage>
    with AutomaticKeepAliveClientMixin<WeaponPage> {
  @override
  bool get wantKeepAlive => true;
  final SearchController _searchController = SearchController();
  PlutoGridStateManager? _gridStateManager;
  late final String gameCorePath;
  bool showHiddenWeapons = false;

  @override
  void initState() {
    super.initState();
    // Obtain gameCorePath from settings or wherever it's stored
    gameCorePath =
        ref.read(appSettings.select((s) => s.gameCoreDir))?.path ?? '';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _notifyGridFilterChanged() {
    if (_gridStateManager == null) return;
    final filters = <FilteredListFilter<PlutoRow>>[];

    if (!showHiddenWeapons) {
      filters.add((PlutoRow row) {
        final weapon = row.data as Weapon;
        return weapon.weaponType?.toLowerCase() != "decorative";
      });
    }

    final query = _searchController.value.text;
    if (query.isNotEmpty) {
      filters.add((PlutoRow row) {
        return row.cells.values.any((cell) {
          final value = cell.value.toString().toLowerCase();
          return value.contains(query.toLowerCase());
        });
      });
    }

    if (filters.isEmpty) {
      _gridStateManager!.setFilter(null);
    } else {
      _gridStateManager!.setFilter(
        (PlutoRow row) {
          return filters.every((filter) => filter(row));
        },
      );
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    // Watch the weapons provider
    final weaponListAsyncValue = ref.watch(weaponListNotifierProvider);
    final theme = Theme.of(context);

    // Configure columns for the PlutoGrid
    List<PlutoColumn> columns = [
      PlutoColumn(
        title: 'Mod',
        field: 'modVariant',
        type: PlutoColumnType.text(),
        width: 100,
        renderer: (rendererContext) {
          final modName = rendererContext.cell.value;
          return Tooltip(
            message: modName,
            child: Text(
              modName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.headlineSmall!.copyWith(fontSize: 14),
            ),
          );
        },
      ),
      PlutoColumn(
        title: '',
        field: 'spritePaths',
        type: PlutoColumnType.text(),
        renderer: (rendererContext) {
          List<String>? imagePaths = rendererContext.cell.value;
          return Tooltip(
            message: imagePaths?.firstWhere((path) => path.isNotEmpty,
                    orElse: () => '') ??
                '',
            child: Center(
              child: imagePaths == null || imagePaths.isEmpty
                  ? Container()
                  : WeaponImageCell(imagePaths: imagePaths),
            ),
          );
        },
        width: 60,
        minWidth: 50,
      ),
      PlutoColumn(
        title: 'Name',
        field: 'name',
        type: PlutoColumnType.text(),
      ),
      PlutoColumn(
        title: 'Tier',
        field: 'tier',
        type: PlutoColumnType.number(),
        width: 60,
      ),
      PlutoColumn(
        title: 'Rarity',
        field: 'rarity',
        type: PlutoColumnType.number(),
        width: 70,
      ),
      PlutoColumn(
        title: 'Dmg/Shot',
        field: 'damagePerShot',
        type: PlutoColumnType.number(),
        width: 110,
      ),
      PlutoColumn(
        title: 'Type',
        field: 'type',
        type: PlutoColumnType.text(),
      ),
      // Add additional columns as necessary
    ];

    return weaponListAsyncValue.when(
      data: (weapons) {
        List<Weapon> filteredWeapons = weapons;

        // Map weapons to rows for PlutoGrid
        List<PlutoRow> rows = filteredWeapons.map((weapon) {
          // Determine the base path
          final modFolderPath =
              weapon.modVariant?.modFolder.path ?? gameCorePath;

          // Collect all potential sprite paths
          final spriteFields = [
            weapon.hardpointGunSprite,
            weapon.hardpointSprite,
            weapon.turretGunSprite,
            weapon.turretSprite,
          ];

          // Build the full paths
          final spritePaths = spriteFields
              .where((sprite) => sprite != null && sprite.isNotEmpty)
              .map((sprite) => p.normalize(p.join(modFolderPath, sprite!)))
              .toList();

          return PlutoRow(
            cells: {
              'modVariant': PlutoCell(
                  value: weapon.modVariant?.modInfo.nameOrId ?? "(vanilla)"),
              'spritePaths': PlutoCell(value: spritePaths),
              'name': PlutoCell(value: weapon.name ?? weapon.id),
              'tier': PlutoCell(value: weapon.tier ?? ""),
              'rarity': PlutoCell(value: weapon.rarity ?? ""),
              'damagePerShot': PlutoCell(value: weapon.damagePerShot ?? ""),
              'type': PlutoCell(value: weapon.type ?? ""),
              // Add other fields if needed
            },
            data: weapon,
          );
        }).toList();

        final weaponCount = weaponListAsyncValue.valueOrNull?.length;
        final filteredWeaponCount = _gridStateManager?.rows.length;

        return Column(
          children: [
            SizedBox(
              height: 50,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.only(left: 8, right: 8),
                  child: Stack(
                    children: [
                      const SizedBox(width: 4),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${weaponCount ?? "..."}${weaponCount != filteredWeaponCount ? " ($filteredWeaponCount)" : ""} Weapons',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontSize: 20),
                        ),
                      ),
                      Center(
                        child: buildSearchBox(),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              height: 30,
                              child: Card.outlined(
                                margin: const EdgeInsets.symmetric(),
                                child: CheckboxWithLabel(
                                  labelWidget: Padding(
                                    padding: const EdgeInsets.only(right: 4),
                                    child: Text("Hidden Weapons",
                                        style: theme.textTheme.labelLarge!
                                            .copyWith(fontSize: 14)),
                                  ),
                                  textPadding: const EdgeInsets.only(left: 4),
                                  checkWrapper: (child) => Padding(
                                    padding: const EdgeInsets.only(left: 4),
                                    child: child,
                                  ),
                                  value: showHiddenWeapons,
                                  onChanged: (value) {
                                    setState(() {
                                      showHiddenWeapons = value ?? false;
                                      _notifyGridFilterChanged();
                                    });
                                  },
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.refresh),
                              onPressed: () {
                                ref.invalidate(weaponListNotifierProvider);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: PlutoGrid(
                  columns: columns,
                  rows: rows,
                  onLoaded: (PlutoGridOnLoadedEvent event) {
                    _gridStateManager = event.stateManager;
                    // Enable column filtering if needed
                    _gridStateManager!.setShowColumnFilter(false);
                  },
                  configuration: PlutoGridConfiguration(
                    columnSize: const PlutoGridColumnSizeConfig(),
                    scrollbar: const PlutoGridScrollbarConfig(
                      isAlwaysShown: true,
                      hoverWidth: 10,
                      scrollbarThickness: 8,
                      scrollbarRadius: Radius.circular(5),
                      dragDevices: {
                        PointerDeviceKind.stylus,
                        PointerDeviceKind.touch,
                        PointerDeviceKind.trackpad,
                        PointerDeviceKind.invertedStylus,
                      },
                    ),
                    style: PlutoGridStyleConfig.dark(
                      enableCellBorderHorizontal: false,
                      enableCellBorderVertical: false,
                      activatedBorderColor: Colors.transparent,
                      inactivatedBorderColor: Colors.transparent,
                      menuBackgroundColor: theme.colorScheme.surface,
                      gridBackgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                      rowColor: Colors.transparent,
                      borderColor: Colors.transparent,
                      cellColorInEditState: Colors.transparent,
                      cellColorInReadOnlyState: Colors.transparent,
                      gridBorderColor: Colors.transparent,
                      activatedColor:
                          theme.colorScheme.onSurface.withOpacity(0.1),
                      evenRowColor: theme.colorScheme.surface.withOpacity(0.4),
                      defaultCellPadding: EdgeInsets.zero,
                      defaultColumnFilterPadding: EdgeInsets.zero,
                      defaultColumnTitlePadding: EdgeInsets.zero,
                      enableRowColorAnimation: true,
                      iconSize: 12,
                      columnTextStyle: theme.textTheme.headlineSmall!
                          .copyWith(fontSize: 14, fontWeight: FontWeight.bold),
                      dragTargetColumnColor:
                          theme.colorScheme.surface.darker(20),
                      iconColor: theme.colorScheme.onSurface.withAlpha(150),
                      cellTextStyle:
                          theme.textTheme.labelLarge!.copyWith(fontSize: 14),
                    ),
                  ),
                  onChanged: (PlutoGridOnChangedEvent event) {
                    Fimber.d(
                        'Value changed from ${event.oldValue} to ${event.value}');
                  },
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: SelectableText('Error loading weapons: $error'),
      ),
    );
  }

  SizedBox buildSearchBox() {
    return SizedBox(
      height: 30,
      width: 300,
      child: SearchAnchor(
        searchController: _searchController,
        builder: (BuildContext context, SearchController controller) {
          return SearchBar(
            controller: controller,
            leading: const Icon(Icons.search),
            hintText: "Filter...",
            trailing: [
              controller.value.text.isEmpty
                  ? Container()
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        controller.clear();
                        _notifyGridFilterChanged();
                      },
                    )
            ],
            backgroundColor: WidgetStateProperty.all(
              Theme.of(context).colorScheme.surfaceContainer,
            ),
            onChanged: (value) {
              _notifyGridFilterChanged();
            },
          );
        },
        suggestionsBuilder:
            (BuildContext context, SearchController controller) {
          return [];
        },
      ),
    );
  }
}

// Custom widget for asynchronously checking file existence and displaying the image
class WeaponImageCell extends StatefulWidget {
  final List<String> imagePaths;

  const WeaponImageCell({super.key, required this.imagePaths});

  @override
  State<WeaponImageCell> createState() => _WeaponImageCellState();
}

class _WeaponImageCellState extends State<WeaponImageCell> {
  static final Map<String, bool> _fileExistsCache = {};

  String? _existingImagePath;

  @override
  void initState() {
    super.initState();
    _findExistingImagePath();
  }

  void _findExistingImagePath() async {
    for (String path in widget.imagePaths) {
      if (_fileExistsCache.containsKey(path)) {
        if (_fileExistsCache[path] == true) {
          _existingImagePath = path;
          break;
        }
      } else {
        bool exists = await File(path).exists();
        _fileExistsCache[path] = exists;
        if (exists) {
          _existingImagePath = path;
          break;
        }
      }
    }

    if (mounted) {
      setState(() {
        // Trigger a rebuild with the found image path
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_existingImagePath == null) {
      // While checking or if no image is found, show a placeholder
      return const SizedBox(
        width: 50,
        height: 50,
        child: Center(child: Icon(Icons.image_not_supported)),
      );
    } else {
      return Image.file(
        File(_existingImagePath!),
        width: 50,
        height: 50,
        fit: BoxFit.contain,
      );
    }
  }
}
