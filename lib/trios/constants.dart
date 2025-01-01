import 'dart:io';

import 'package:intl/intl.dart';
import 'package:trios/utils/extensions.dart';

class Constants {
  static const version = "1.0.0";

  static const appName = "TriOS";
  static const appTitle = "$appName v$version";
  static String appSubtitle = [
    "Prerelease",
    "Corporate Toolkit",
    "by Wisp",
    "Hegemony Tolerated",
    "Tri-Tachyon Approved",
    "Powered by Moloch",
    "COMSEC Compliant",
    "Wave to Sebestyan",
    "Gargoyle-resistant",
    "Unavailable on Asher",
    "Artemisia's Choice",
    "Persean Chronicles Died For This?",
    "where is omega?",
    "at com.fs.starfarer.oOOOOOOO",
    "SMOL 2",
    "Interesting mods...",
    "Burn bright",
  ].random();

  static const enabledModsFilename = "enabled_mods.json";
  static const modsFolderName = "mods";
  static const savesFolderName = "saves";
  static const archivesFolderName = "Mod_Backups";
  static const modInfoFileName = "mod_info.json";
  static const unbrickedModInfoFileName = modInfoFileName;
  static const gameJreFolderName = "jre";

  //     // Backwards compat, first one is the one used for new disable actions.
  static const modInfoFileDisabledNames = [
    "mod_info.json.disabled",
    "mod_info.json.disabled-by-TriOS",
    "mod_info.json.disabled-by-SMOL",
  ];
  static const modInfoFileNames = [
    modInfoFileName,
    ...modInfoFileDisabledNames,
  ];

  static const versionCheckerCsvPath = "data/config/version/version_files.csv";
  static const versionCheckerFileEnding = ".version";
  static const forumUrl = "https://fractalsoftworks.com/forum/index.php";
  static const nexusModsPageUrl = "https://www.nexusmods.com/starsector/mods/";
  static const forumModPageUrl = "$forumUrl?topic=";
  static const forumModIndexUrl = "${forumModPageUrl}177";
  static const forumModdingSubforumUrl = "$forumUrl?board=3.0";
  static const forumHostname = "fractalsoftworks.com";
  static const tipsFileRelativePath = "data/strings/tips.json";
  static const graphicsLibId = "shaderLib";
  static const changelogUrl =
      "https://raw.githubusercontent.com/wispborne/TriOS/main/changelog.md";
  static const supportedArchiveExtensions = [
    ".zip",
    ".7z",
    ".rar",
    ".tar",
    ".gz",
    ".bz2",
  ];
  static const num maxPathLength = 260;

  static const String modRepoUrl =
      "https://github.com/wispborne/StarsectorModRepo/raw/refs/heads/main/ModRepo.json";
  static const String patreonUrl = "https://www.patreon.com/wispborne";
  static const String kofiUrl = "https://ko-fi.com/wispborne";

  /// Warning: DON'T ADD ANYTHING TO THIS DIRECTLY. It will mutate the shared instance.
  /// Creating a new one each time is expensive, and hardcoding the pattern will hardcode the locale.
  static DateFormat dateTimeFormat =
      DateFormat.yMd(Intl.getCurrentLocale()).add_jm();
  static DateFormat gameDateFormat =
      DateFormat("'Cycle' y , 'Month' M, 'Day' d");

  /// getApplicationSupportDirectory()
  static late final Directory configDataFolderPath; // Set in main

  static const modAuthorAliases = [
    ["RustyCabbage", "rubi", "ceruleanpancake"],
    ["Wisp", "Wispborne", "Tartiflette and Wispborne"],
    ["DesperatePeter", "Jannes"],
    ["shoi", "gettag"],
    ["Dark.Revenant", "DR"],
    ["LazyWizard", "Lazy"],
    ["Techpriest", "Timid"],
    ["Nick XR", "Nick", "nick7884"],
    ["PMMeCuteBugPhotos", "MrFluffster"],
    ["Dazs", "Spiritfox", "spiritfox_"],
    ["Histidine, Zaphide", "Histidine", "histidine_my"],
    ["Snrasha", "Snrasha, the tinkerer"],
    ["Hotpics", "jackwolfskin"],
    ["cptdash", "SpeedRacer"],
    ["Elseud", "Elseudo"],
    ["TobiaF", "Toby"],
    ["Mephyr", "Liral"],
    ["Tranquility", "tranquil_light"],
    ["FasterThanSleepyfish", "Sleepyfish"],
    ["Nerzhull_AI", "nerzhulai"],
    ["theDrag", "theDragn", "iryx"],
    ["Audax", "Audaxl"],
    ["Pogre", "noof"],
    ["lord_dalton", "Epta Consortium"],
    ["hakureireimu", "LngA7Gw"],
    ["Nes", "nescom"],
    ["float", "this_is_a_username"],
    ["AERO", "aero.assault"],
    ["Fellout", "felloutwastaken"],
    ["Mr. THG", "thog"],
    ["Derelict_Surveyor", "jdt15"],
    ["constat.", "Astarat", "Astarat and PureTilt"],
    ["Soren", "Søren", "Harmful Mechanic"],
  ];
}

final currentDirectory = Platform.resolvedExecutable.toFile().parent;
final currentMacOSAppPath = Platform.resolvedExecutable.toFile().parent.parent;
