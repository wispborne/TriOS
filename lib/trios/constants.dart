import 'package:trios/utils/extensions.dart';

class Constants {
  static const version = "0.0.50";

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
    "Persean Chronicles Died For This",
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
  static const changelogUrl = "https://raw.githubusercontent.com/wispborne/TriOS/main/changelog.md";
  static const supportedArchiveExtensions = [
    ".zip",
    ".7z",
    ".rar",
    ".tar",
    ".gz",
    ".bz2",
  ];
}
