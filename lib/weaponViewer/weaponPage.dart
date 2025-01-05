import 'dart:io';
import 'dart:ui';

import 'package:dart_extensions_methods/dart_extension_methods.dart';
import 'package:flutter/material.dart';
import 'package:flutter_color/flutter_color.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multi_split_view/multi_split_view.dart';
import 'package:path/path.dart' as p;
import 'package:trios/thirdparty/pluto_grid_plus/lib/pluto_grid_plus.dart';
import 'package:trios/trios/settings/settings.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/logging.dart';
import 'package:trios/weaponViewer/models/weapon.dart';
import 'package:trios/weaponViewer/weaponsManager.dart';
import 'package:trios/widgets/checkbox_with_label.dart';
import 'package:trios/widgets/moving_tooltip.dart';

import '../widgets/MultiSplitViewMixin.dart';

class WeaponPage extends ConsumerStatefulWidget {
  const WeaponPage({super.key});

  @override
  ConsumerState<WeaponPage> createState() => _WeaponPageState();
}

class _WeaponPageState extends ConsumerState<WeaponPage>
    with AutomaticKeepAliveClientMixin<WeaponPage>, MultiSplitViewMixin {
  @override
  bool get wantKeepAlive => true;
  final SearchController _searchController = SearchController();
  PlutoGridStateManager? _gridStateManagerTop;
  PlutoGridStateManager? _gridStateManagerBottom;
  bool showHiddenWeapons = false;
  bool splitPane = false;
  String gameCorePath = "";

  @override
  List<Area> get areas =>
      splitPane ? [Area(id: 'top'), Area(id: 'bottom')] : [Area(id: 'top')];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _notifyGridFilterChanged() {
    if (_gridStateManagerTop == null) return;
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
      _gridStateManagerTop?.setFilter(null);
      _gridStateManagerBottom?.setFilter(null);
    } else {
      _gridStateManagerTop?.setFilter(
        (PlutoRow row) {
          return filters.every((filter) => filter(row));
        },
      );
      _gridStateManagerBottom?.setFilter(
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
    final weaponListAsyncValue = ref.read(weaponListNotifierProvider);
    final theme = Theme.of(context);
    gameCorePath =
        ref.watch(appSettings.select((s) => s.gameCoreDir))?.path ?? '';

    List<PlutoColumn> columns = buildCols(theme);

    ref.listen(
      weaponListNotifierProvider,
      (before, after) {
        final existingRowIds = (_gridStateManagerTop?.rows ?? [])
            .map((row) => (row.data as Weapon).id)
            .toList();

        _gridStateManagerTop?.appendRows(buildRows((after.value ?? [])
            .where((weapon) => !existingRowIds.contains(weapon.id))
            .distinctBy((weapon) => weapon.id)
            .toList()));
        _gridStateManagerBottom?.appendRows(buildRows((after.value ?? [])
            .where((weapon) => !existingRowIds.contains(weapon.id))
            .distinctBy((weapon) => weapon.id)
            .toList()));

        _notifyGridFilterChanged();
      },
    );

    List<PlutoRow> rows = [];

    final weaponCount = weaponListAsyncValue.valueOrNull?.length;
    final filteredWeaponCount = _gridStateManagerTop?.rows.distinctBy((row) {
          final weapon = row.data as Weapon;
          return weapon.id;
        }).length ??
        0;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(4),
          child: SizedBox(
            height: 50,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.only(left: 8, right: 8),
                child: Stack(
                  children: [
                    const SizedBox(width: 4),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          Text(
                            '${weaponCount ?? "..."} Weapons${weaponCount != filteredWeaponCount ? " ($filteredWeaponCount shown)" : ""}',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontSize: 20),
                          ),
                          if (ref.watch(isLoadingWeaponsList))
                            const Padding(
                              padding: EdgeInsets.only(left: 8),
                              child: SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  strokeCap: StrokeCap.round,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Center(
                      child: buildSearchBox(),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        spacing: 8,
                        children: [
                          MovingTooltipWidget.text(
                            message: "Show hidden weapons",
                            child: buildToolbarButton(
                                theme, "Show Hidden", showHiddenWeapons,
                                (value) {
                              showHiddenWeapons = value ?? false;
                              _notifyGridFilterChanged();
                            }),
                          ),
                          buildToolbarButton(theme, "Compare", splitPane,
                              (value) {
                            splitPane = value ?? false;
                            multiSplitController.areas = areas;
                            _notifyGridFilterChanged();
                          }),
                          IconButton(
                            icon: const Icon(Icons.refresh),
                            onPressed: () {
                              setState(() {
                                _gridStateManagerTop?.removeAllRows();
                                _gridStateManagerBottom?.removeAllRows();
                              });
                              _notifyGridFilterChanged();
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
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: MultiSplitViewTheme(
              data: MultiSplitViewThemeData(
                  dividerThickness: 16,
                  dividerPainter: DividerPainters.dashed(
                    color: theme.colorScheme.onSurface.withOpacity(0.4),
                    highlightedColor: theme.colorScheme.onSurface,
                    highlightedThickness: 2,
                    gap: 1,
                    animationDuration: const Duration(milliseconds: 100),
                  )),
              child: MultiSplitView(
                  controller: multiSplitController,
                  axis: Axis.vertical,
                  builder: (context, area) {
                    switch (area.id) {
                      case 'top':
                        return buildPlutoGrid(columns, rows, theme, true);
                      case 'bottom':
                        return buildPlutoGrid(columns, rows, theme, false);
                      default:
                        return Container();
                    }
                  }),
            ),
          ),
        ),
      ],
    );
    // },
    // loading: () => const Center(child: CircularProgressIndicator()),
    // error: (error, stack) => Center(
    //   child: SelectableText('Error loading weapons: $error'),
    // ),
    // );
  }

  SizedBox buildToolbarButton(
      ThemeData theme, String text, bool value, ValueChanged<bool?> onChanged) {
    return SizedBox(
      height: 30,
      child: Card.outlined(
        margin: const EdgeInsets.symmetric(),
        child: CheckboxWithLabel(
          labelWidget: Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Text(text,
                style: theme.textTheme.labelLarge!.copyWith(fontSize: 14)),
          ),
          textPadding: const EdgeInsets.only(left: 4),
          checkWrapper: (child) => Padding(
            padding: const EdgeInsets.only(left: 4),
            child: child,
          ),
          value: value,
          onChanged: onChanged,
        ),
      ),
    );
  }

  List<PlutoRow<Weapon>> buildRows(List<Weapon> filteredWeapons) {
    return filteredWeapons.map((weapon) {
      // Determine the base path
      final modFolderPath = weapon.modVariant?.modFolder.path ?? gameCorePath;

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
        cells: buildCells(weapon, spritePaths),
        data: weapon,
      );
    }).toList();
  }

  PlutoGrid buildPlutoGrid(List<PlutoColumn> columns,
      List<PlutoRow<dynamic>> rows, ThemeData theme, bool isTop) {
    return PlutoGrid(
      columns: columns,
      rows: rows,
      mode: PlutoGridMode.multiSelect,
      onLoaded: (PlutoGridOnLoadedEvent event) {
        if (isTop) {
          _gridStateManagerTop = event.stateManager;
          _gridStateManagerTop?.setShowColumnFilter(false);
          _gridStateManagerTop?.clearCurrentSelecting();

          // Add rows to the bottom grid if it exists, so it shows up with the same data
          _gridStateManagerBottom?.appendRows(
              buildRows(ref.read(weaponListNotifierProvider).value ?? []));
        } else {
          _gridStateManagerBottom = event.stateManager;
          _gridStateManagerBottom?.setShowColumnFilter(false);
          _gridStateManagerBottom?.appendRows(
              buildRows(ref.read(weaponListNotifierProvider).value ?? []));
          _gridStateManagerBottom?.clearCurrentSelecting();
        }
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
          gridBackgroundColor: theme.colorScheme.surfaceContainerHighest,
          rowColor: Colors.transparent,
          borderColor: Colors.transparent,
          cellColorInEditState: Colors.transparent,
          cellColorInReadOnlyState: Colors.transparent,
          gridBorderColor: Colors.transparent,
          activatedColor: theme.colorScheme.onSurface.withOpacity(0.1),
          evenRowColor: theme.colorScheme.surface.withOpacity(0.4),
          defaultCellPadding: EdgeInsets.zero,
          defaultColumnFilterPadding: EdgeInsets.zero,
          defaultColumnTitlePadding: EdgeInsets.zero,
          enableRowColorAnimation: false,
          iconSize: 12,
          columnTextStyle: theme.textTheme.headlineSmall!
              .copyWith(fontSize: 14, fontWeight: FontWeight.bold),
          dragTargetColumnColor: theme.colorScheme.surface.darker(20),
          iconColor: theme.colorScheme.onSurface.withAlpha(150),
          cellTextStyle: theme.textTheme.labelLarge!.copyWith(fontSize: 14),
          columnHeight: isTop ? PlutoGridSettings.rowHeight : 0,
          oddRowColor: theme.colorScheme.surface.darker(5).withOpacity(0.4),
        ),
      ),
      onChanged: (PlutoGridOnChangedEvent event) {
        Fimber.d('Value changed from ${event.oldValue} to ${event.value}');
      },
    );
  }

  Map<String, PlutoCell> buildCells(Weapon weapon, List<String> spritePaths) {
    return {
      'modVariant':
          PlutoCell(value: weapon.modVariant?.modInfo.nameOrId ?? "(vanilla)"),
      'spritePaths': PlutoCell(value: spritePaths),
      'name': PlutoCell(value: weapon.name ?? weapon.id),
      'damagePerShot': PlutoCell(value: weapon.damagePerShot ?? ""),
      // New fields
      'baseValue': PlutoCell(value: weapon.baseValue ?? ""),
      'range': PlutoCell(value: weapon.range ?? ""),
      'damagePerSecond': PlutoCell(value: weapon.damagePerSecond ?? ""),
      'emp': PlutoCell(value: weapon.emp ?? ""),
      'impact': PlutoCell(value: weapon.impact ?? ""),
      'turnRate': PlutoCell(value: weapon.turnRate ?? ""),
      'ops': PlutoCell(value: weapon.ops ?? ""),
      'ammo': PlutoCell(value: weapon.ammo ?? ""),
      'ammoPerSec': PlutoCell(value: weapon.ammoPerSec ?? ""),
      'reloadSize': PlutoCell(value: weapon.reloadSize ?? ""),
      'energyPerShot': PlutoCell(value: weapon.energyPerShot ?? ""),
      'energyPerSecond': PlutoCell(value: weapon.energyPerSecond ?? ""),
      'tier': PlutoCell(value: weapon.tier ?? ""),
      'chargeup': PlutoCell(value: weapon.chargeup ?? ""),
      'chargedown': PlutoCell(value: weapon.chargedown ?? ""),
      'burstSize': PlutoCell(value: weapon.burstSize ?? ""),
      'burstDelay': PlutoCell(value: weapon.burstDelay ?? ""),
      'minSpread': PlutoCell(value: weapon.minSpread ?? ""),
      'maxSpread': PlutoCell(value: weapon.maxSpread ?? ""),
      'spreadPerShot': PlutoCell(value: weapon.spreadPerShot ?? ""),
      'spreadDecayPerSec': PlutoCell(value: weapon.spreadDecayPerSec ?? ""),
      'beamSpeed': PlutoCell(value: weapon.beamSpeed ?? ""),
      'projSpeed': PlutoCell(value: weapon.projSpeed ?? ""),
      'launchSpeed': PlutoCell(value: weapon.launchSpeed ?? ""),
      'flightTime': PlutoCell(value: weapon.flightTime ?? ""),
      'projHitpoints': PlutoCell(value: weapon.projHitpoints ?? ""),
      'autofireAccBonus': PlutoCell(value: weapon.autofireAccBonus ?? ""),
      'extraArcForAI': PlutoCell(value: weapon.extraArcForAI ?? ""),
      'hints': PlutoCell(value: weapon.hints ?? ""),
      'tags': PlutoCell(value: weapon.tags ?? ""),
      'groupTag': PlutoCell(value: weapon.groupTag ?? ""),
      'techManufacturer': PlutoCell(value: weapon.techManufacturer ?? ""),
      'primaryRoleStr': PlutoCell(value: weapon.primaryRoleStr ?? ""),
      'speedStr': PlutoCell(value: weapon.speedStr ?? ""),
      'trackingStr': PlutoCell(value: weapon.trackingStr ?? ""),
      'turnRateStr': PlutoCell(value: weapon.turnRateStr ?? ""),
      'accuracyStr': PlutoCell(value: weapon.accuracyStr ?? ""),
      'specClass': PlutoCell(value: weapon.specClass?.toTitleCase() ?? ""),
      'weaponType': PlutoCell(value: weapon.weaponType?.toTitleCase() ?? ""),
      'size': PlutoCell(value: weapon.size?.toTitleCase() ?? ""),
    };
  }

  List<PlutoColumn> buildCols(ThemeData theme) {
    // Configure columns for the PlutoGrid
    List<PlutoColumn> columns = [
      // Existing columns
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
        renderer: (rendererContext) {
          final weapon = rendererContext.row.data as Weapon;
          return Tooltip(
            message: weapon.id,
            child: Text(
              rendererContext.cell.value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.headlineSmall!.copyWith(fontSize: 14),
            ),
          );
        },
      ),
      PlutoColumn(
        title: 'Weapon Type',
        field: 'weaponType',
        type: PlutoColumnType.text(),
        width: 100,
      ),
      PlutoColumn(
        title: 'Size',
        field: 'size',
        type: PlutoColumnType.text(),
        width: 80,
      ),
      PlutoColumn(
        title: 'Tech/Manufacturer',
        field: 'techManufacturer',
        type: PlutoColumnType.text(),
        width: 150,
      ),
      PlutoColumn(
        title: 'Primary Role',
        field: 'primaryRoleStr',
        type: PlutoColumnType.text(),
        width: 120,
      ),
      PlutoColumn(
        title: 'Tier',
        field: 'tier',
        type: PlutoColumnType.number(),
        width: 60,
      ),
      PlutoColumn(
        title: 'Dmg/Shot',
        field: 'damagePerShot',
        type: PlutoColumnType.number(),
        width: 110,
      ),
      // New columns
      PlutoColumn(
        title: 'Base Value',
        field: 'baseValue',
        type: PlutoColumnType.number(),
        width: 90,
      ),
      PlutoColumn(
        title: 'Range',
        field: 'range',
        type: PlutoColumnType.number(),
        width: 80,
      ),
      PlutoColumn(
        title: 'Dmg/Sec',
        field: 'damagePerSecond',
        type: PlutoColumnType.number(),
        width: 90,
      ),
      PlutoColumn(
        title: 'EMP',
        field: 'emp',
        type: PlutoColumnType.number(),
        width: 80,
      ),
      PlutoColumn(
        title: 'Impact',
        field: 'impact',
        type: PlutoColumnType.number(),
        width: 80,
      ),
      PlutoColumn(
        title: 'Turn Rate',
        field: 'turnRate',
        type: PlutoColumnType.number(),
        width: 90,
      ),
      PlutoColumn(
        title: 'OPs',
        field: 'ops',
        type: PlutoColumnType.number(),
        width: 60,
      ),
      PlutoColumn(
        title: 'Ammo',
        field: 'ammo',
        type: PlutoColumnType.number(),
        width: 80,
      ),
      PlutoColumn(
        title: 'Ammo/Sec',
        field: 'ammoPerSec',
        type: PlutoColumnType.number(),
        width: 90,
      ),
      PlutoColumn(
        title: 'Reload Size',
        field: 'reloadSize',
        type: PlutoColumnType.number(),
        width: 90,
      ),
      PlutoColumn(
        title: 'Energy/Shot',
        field: 'energyPerShot',
        type: PlutoColumnType.number(),
        width: 100,
      ),
      PlutoColumn(
        title: 'Energy/Sec',
        field: 'energyPerSecond',
        type: PlutoColumnType.number(),
        width: 100,
      ),
      PlutoColumn(
        title: 'Charge Up',
        field: 'chargeup',
        type: PlutoColumnType.number(),
        width: 90,
      ),
      PlutoColumn(
        title: 'Charge Down',
        field: 'chargedown',
        type: PlutoColumnType.number(),
        width: 90,
      ),
      PlutoColumn(
        title: 'Burst Size',
        field: 'burstSize',
        type: PlutoColumnType.number(),
        width: 90,
      ),
      PlutoColumn(
        title: 'Burst Delay',
        field: 'burstDelay',
        type: PlutoColumnType.number(),
        width: 90,
      ),
      PlutoColumn(
        title: 'Min Spread',
        field: 'minSpread',
        type: PlutoColumnType.number(),
        width: 90,
      ),
      PlutoColumn(
        title: 'Max Spread',
        field: 'maxSpread',
        type: PlutoColumnType.number(),
        width: 90,
      ),
      PlutoColumn(
        title: 'Spread/Shot',
        field: 'spreadPerShot',
        type: PlutoColumnType.number(),
        width: 90,
      ),
      PlutoColumn(
        title: 'Spread Decay/Sec',
        field: 'spreadDecayPerSec',
        type: PlutoColumnType.number(),
        width: 110,
      ),
      PlutoColumn(
        title: 'Beam Speed',
        field: 'beamSpeed',
        type: PlutoColumnType.number(),
        width: 90,
      ),
      PlutoColumn(
        title: 'Proj Speed',
        field: 'projSpeed',
        type: PlutoColumnType.number(),
        width: 90,
      ),
      PlutoColumn(
        title: 'Launch Speed',
        field: 'launchSpeed',
        type: PlutoColumnType.number(),
        width: 100,
      ),
      PlutoColumn(
        title: 'Flight Time',
        field: 'flightTime',
        type: PlutoColumnType.number(),
        width: 90,
      ),
      PlutoColumn(
        title: 'Proj HP',
        field: 'projHitpoints',
        type: PlutoColumnType.number(),
        width: 90,
      ),
      PlutoColumn(
        title: 'Autofire Acc Bonus',
        field: 'autofireAccBonus',
        type: PlutoColumnType.number(),
        width: 130,
      ),
      PlutoColumn(
        title: 'Extra Arc for AI',
        field: 'extraArcForAI',
        type: PlutoColumnType.text(),
        width: 120,
      ),
      PlutoColumn(
        title: 'Hints',
        field: 'hints',
        type: PlutoColumnType.text(),
        width: 100,
      ),
      PlutoColumn(
        title: 'Tags',
        field: 'tags',
        type: PlutoColumnType.text(),
        width: 100,
      ),
      PlutoColumn(
        title: 'Group Tag',
        field: 'groupTag',
        type: PlutoColumnType.text(),
        width: 100,
      ),
      PlutoColumn(
        title: 'Speed',
        field: 'speedStr',
        type: PlutoColumnType.text(),
        width: 80,
      ),
      PlutoColumn(
        title: 'Tracking',
        field: 'trackingStr',
        type: PlutoColumnType.text(),
        width: 100,
      ),
      PlutoColumn(
        title: 'Turn Rate Str',
        field: 'turnRateStr',
        type: PlutoColumnType.text(),
        width: 100,
      ),
      PlutoColumn(
        title: 'Accuracy',
        field: 'accuracyStr',
        type: PlutoColumnType.text(),
        width: 100,
      ),
      PlutoColumn(
        title: 'Spec Class',
        field: 'specClass',
        type: PlutoColumnType.text(),
        width: 100,
      ),
      // Add additional columns if necessary
    ];
    return columns;
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
