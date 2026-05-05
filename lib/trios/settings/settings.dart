import 'dart:io';

import 'package:dart_mappable/dart_mappable.dart';
import 'package:trios/catalog/mod_browser_page_controller.dart';
import 'package:trios/catalog/models/catalog_card_click_action.dart';
import 'package:trios/mod_manager/homebrew_grid/wisp_grid_state.dart';
import 'package:trios/models/launch_settings.dart';
import 'package:trios/hullmod_viewer/hullmods_page_controller.dart';
import 'package:trios/ship_viewer/ships_page_controller.dart';
import 'package:trios/portraits/portraits_page_controller.dart';
import 'package:trios/toolbar/nav_order_entry.dart';
import 'package:trios/trios/navigation.dart';
import 'package:trios/utils/dart_mappable_utils.dart';
import 'package:trios/vram_estimator/selectors/referenced_assets_selector_config.dart';
import 'package:trios/vram_estimator/selectors/vram_selector_id.dart';
import 'package:trios/weapon_viewer/weapons_page_controller.dart';
import 'package:trios/widgets/filter_group_persistence/persisted_filter_group.dart';

part 'settings.mapper.dart';

const sharedPrefsSettingsKey = "settings";

/// MacOs: /Users/<user>/Library/Preferences/org.wisp.TriOS.plist

/// Settings object model
@MappableClass(ignoreNull: true)
class Settings with SettingsMappable {
  /// DO NOT USE directly; use `AppState.gameFolder`
  @MappableField(hook: DirectoryHook())
  final Directory? gameDir;

  /// DO NOT USE directly; use `AppState.gameCoreFolder`
  @MappableField(hook: DirectoryHook())
  final Directory? gameCoreDir;

  // Paths
  final String? customGameExePath;
  final bool useCustomGameExePath;

  /// Custom mods folder.
  /// DO NOT USE directly; use `AppState.modsFolder`
  @MappableField(hook: DirectoryHook())
  final Directory? modsDir;

  /// Whether custom mods folder is being used instead of the default
  final bool hasCustomModsDir;

  /// DO NOT USE directly; use `AppState.savesFolder`
  @MappableField(hook: DirectoryHook())
  final Directory? customSavesPath;
  final bool useCustomSavesPath;

  /// DO NOT USE directly; use `AppState.gameCoreFolder`
  @MappableField(hook: DirectoryHook())
  final Directory? customCoreFolderPath;
  final bool useCustomCoreFolderPath;

  final bool isRulesHotReloadEnabled;

  // Window State
  final double? windowXPos;
  final double? windowYPos;
  final double? windowWidth;
  final double? windowHeight;
  final bool? isMaximized;
  final bool? isMinimized;
  final TriOSTools defaultTool;
  final bool isSidebarCollapsed;
  final bool useTopToolbar;

  /// User-customized ordering of the 11 reorderable nav icons plus the
  /// section divider. Nullable: null means "use [defaultNavOrder]".
  /// The `NavOrderController` handles reconciliation (missing/unknown/duplicate
  /// entries) on load.
  @MappableField(hook: SafeDecodeHook())
  final List<NavOrderEntry>? navIconOrder;

  /// Relative paths from game dir to files the user has selected as vmparams files.
  final List<String> vmparamsFilePaths;

  final String? themeKey;
  final bool? showChangelogNextLaunch;

  /// If true, TriOS acts as the launcher. If false, basically just clicks game exe.
  final bool enableDirectLaunch;
  final LaunchSettings launchSettings;
  final String? lastStarsectorVersion;
  final DashboardGridModUpdateVisibility dashboardGridModUpdateVisibility;
  final ModsGridUpdateVisibility modsGridUpdateVisibility;
  @MappableField(hook: SafeDecodeHook())
  final WispGridState modsGridState;
  final WispGridState weaponsGridState;
  final WispGridState shipsGridState;
  @MappableField(hook: SafeDecodeHook())
  final ShipsPageStatePersisted? shipsPageState;
  @MappableField(hook: SafeDecodeHook())
  final WeaponsPageStatePersisted? weaponsPageState;
  final WispGridState hullmodsGridState;
  @MappableField(hook: SafeDecodeHook())
  final HullmodsPageStatePersisted? hullmodsPageState;
  @MappableField(hook: SafeDecodeHook())
  final PortraitsPageStatePersisted? portraitsPageState;

  /// Per-filter-group persisted selections, keyed by
  /// `"{pageId}::{filterGroupId}"`.
  @MappableField(hook: SafeDecodeHook())
  final Map<String, PersistedFilterGroup> persistedFilterGroups;

  // Mods Page
  final bool doubleClickForModsPanel;
  final bool pinFavorites;
  final bool dashboardModListColorful;
  final bool modsGridColorful;
  final bool modsGridUpdatesShowDisabledMods;
  final bool modsGridShowModInAllCategories;

  // Settings Page
  @Deprecated(
    "Bad idea, can get stuck in crash -> downgrade -> auto-update -> crash loop.",
  )
  final bool shouldAutoUpdateOnLaunch;
  final int secondsBetweenModFolderChecks;
  final int toastDurationSeconds;
  final int maxHttpRequestsAtOnce;
  final FolderNamingSetting folderNamingSetting;
  final int? keepLastNVersions;
  final bool? allowCrashReporting;
  final bool updateToPrereleases;
  final bool autoEnableAndDisableDependencies;
  final bool enableLauncherPrecheck;
  final ModUpdateBehavior modUpdateBehavior;
  final DashboardModListSort dashboardModListSort;
  final bool checkIfGameIsRunning;
  final CompressionLib compressionLib;
  final double windowScaleFactor;
  final bool enableAccessibilitySemanticsOnLinux;

  final bool? hasHiddenForumDarkModeTip;

  // Catalog page — collapsible browser panel and card-click action
  final bool catalogBrowserPanelOpen;
  final double? catalogBrowserPanelWidth;
  final CatalogCardClickAction catalogCardClickAction;
  final double catalogMinItemWidth;
  final double catalogCardSpacing;
  @MappableField(hook: SafeDecodeHook())
  final CatalogPageStatePersisted? catalogPageState;

  // Mod profiles are stored in [ModProfilesSettings] and [ModProfileManagerNotifier],
  // in a different shared_prefs key.
  final String? activeModProfileId;

  final bool showForceUpdateWarning;
  final bool showDonationButton;
  final bool showReportBugButton;
  final bool allowInsecureConnections;
  final bool shouldLoadWebView;

  final bool? showAprilFools2026;
  final bool? forceShowAprilFools2026;

  final bool debugMode;

  final List<String> weaponsSearchHistory;

  /// Unknown ids fall back to folder-scan.
  final VramSelectorId vramEstimatorSelectorId;
  final ReferencedAssetsSelectorConfig referencedAssetsSelectorConfig;

  /// When true, the VRAM scan runs across an isolate pool via `async_task`.
  /// When false (default), runs the legacy single-isolate sequential pipeline.
  final bool vramEstimatorMultithreaded;

  Settings({
    this.gameDir,
    this.gameCoreDir,
    this.modsDir,
    this.hasCustomModsDir = false,
    this.isRulesHotReloadEnabled = false,
    this.windowXPos,
    this.windowYPos,
    this.windowWidth,
    this.windowHeight,
    this.isMaximized,
    this.isMinimized,
    this.defaultTool = TriOSTools.dashboard,
    this.isSidebarCollapsed = true,
    this.useTopToolbar = false,
    this.navIconOrder,
    this.vmparamsFilePaths = const [],
    this.themeKey,
    this.showChangelogNextLaunch,
    this.enableDirectLaunch = false,
    this.launchSettings = const LaunchSettings(),
    this.lastStarsectorVersion,
    this.dashboardGridModUpdateVisibility =
        DashboardGridModUpdateVisibility.hideMuted,
    this.modsGridUpdateVisibility = ModsGridUpdateVisibility.hide,
    this.modsGridState = const WispGridState(
      groupingSetting: GroupingSetting(
        currentGroupedByKey: 'enabledState',
        isSortDescending: false,
      ),
      sortedColumnKey: 'name',
      columnsState: {},
    ),
    this.weaponsGridState = const WispGridState(
      groupingSetting: null,
      columnsState: {},
    ),
    this.shipsGridState = const WispGridState(
      groupingSetting: null,
      columnsState: {},
    ),
    this.shipsPageState,
    this.weaponsPageState,
    this.hullmodsGridState = const WispGridState(
      groupingSetting: null,
      columnsState: {},
    ),
    this.hullmodsPageState,
    this.portraitsPageState,
    this.persistedFilterGroups = const {},
    this.customGameExePath,
    this.useCustomGameExePath = false,
    this.customSavesPath,
    this.useCustomSavesPath = false,
    this.customCoreFolderPath,
    this.useCustomCoreFolderPath = false,
    this.doubleClickForModsPanel = true,
    this.pinFavorites = true,
    this.dashboardModListColorful = false,
    this.modsGridColorful = false,
    this.modsGridUpdatesShowDisabledMods = true,
    this.modsGridShowModInAllCategories = false,
    this.shouldAutoUpdateOnLaunch = false,
    this.secondsBetweenModFolderChecks = 15,
    this.toastDurationSeconds = 7,
    this.maxHttpRequestsAtOnce = 20,
    this.folderNamingSetting = FolderNamingSetting.allFoldersVersioned,
    this.keepLastNVersions,
    this.allowCrashReporting,
    this.updateToPrereleases = false,
    this.autoEnableAndDisableDependencies = false,
    this.enableLauncherPrecheck = true,
    this.modUpdateBehavior = ModUpdateBehavior.switchToNewVersionIfWasEnabled,
    this.dashboardModListSort = DashboardModListSort.name,
    this.checkIfGameIsRunning = true,
    this.compressionLib = CompressionLib.sevenZip,
    this.windowScaleFactor = 1.0,
    this.enableAccessibilitySemanticsOnLinux = false,
    this.hasHiddenForumDarkModeTip,
    this.catalogBrowserPanelOpen = false,
    this.catalogBrowserPanelWidth,
    this.catalogCardClickAction = CatalogCardClickAction.forumDialog,
    this.catalogMinItemWidth = 390,
    this.catalogCardSpacing = 4,
    this.catalogPageState,
    this.activeModProfileId,
    this.showForceUpdateWarning = true,
    this.showDonationButton = true,
    this.showReportBugButton = true,
    this.allowInsecureConnections = false,
    this.shouldLoadWebView = false,
    this.showAprilFools2026,
    this.forceShowAprilFools2026,
    this.debugMode = false,
    this.weaponsSearchHistory = const [],
    this.vramEstimatorSelectorId = VramSelectorId.folderScan,
    this.referencedAssetsSelectorConfig =
        ReferencedAssetsSelectorConfig.allEnabled,
    this.vramEstimatorMultithreaded = true,
  });
}

@MappableEnum(defaultValue: FolderNamingSetting.allFoldersVersioned)
enum FolderNamingSetting {
  @MappableValue(0)
  doNotChangeNameForHighestVersion,
  @MappableValue(1)
  allFoldersVersioned,
  @MappableValue(2)
  doNotChangeNamesEver,
}

@MappableEnum(defaultValue: ModUpdateBehavior.switchToNewVersionIfWasEnabled)
enum ModUpdateBehavior { doNotChange, switchToNewVersionIfWasEnabled }

@MappableEnum(defaultValue: DashboardGridModUpdateVisibility.hideMuted)
enum DashboardGridModUpdateVisibility { allVisible, hideMuted, hideAll }

@MappableEnum(defaultValue: ModsGridUpdateVisibility.hide)
enum ModsGridUpdateVisibility { showAll, showUnmuted, hide }

@MappableEnum(defaultValue: CompressionLib.sevenZip)
enum CompressionLib {
  sevenZip,
  @Deprecated("Removed libarchive, use sevenZip")
  libarchive,
}

@MappableEnum(defaultValue: DashboardModListSort.name)
enum DashboardModListSort {
  loadOrder,
  name,
  author,
  version,
  vram,
  gameVersion,
  enabled,
}
