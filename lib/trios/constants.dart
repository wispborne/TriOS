import 'dart:io';

import 'package:trios/utils/extensions.dart';

class Constants {
  static const version = "0.1.4";

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
  ].random();

  static const enabledModsFilename = "enabled_mods.json";
  static const modsFolderName = "mods";
  static const savesFolderName = "saves";
  static const archivesFolderName = "Mod_Backups";
  static const modInfoFileName = "mod_info.json";
  static const unbrickedModInfoFileName = modInfoFileName;

  //     // Backwards compat, first one is the one used for new disable actions.
  static const modInfoFileDisabledNames = [
    "mod_info.json.disabled-by-TriOS",
    "mod_info.json.disabled-by-SMOL",
    "mod_info.json.disabled"
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
    ["astarat.", "Astarat", "Astarat and PureTilt"],
    ["Soren", "Søren", "Harmful Mechanic"],
  ];
}

final currentDirectory = Platform.resolvedExecutable.toFile().parent;