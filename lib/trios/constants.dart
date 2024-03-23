import 'dart:io';

import 'package:trios/utils/extensions.dart';

class Constants {
  static const version = "0.0.28";

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
    "Unavailable on Asher"
  ].random();

  static const ENABLED_MODS_FILENAME = "enabled_mods.json";
  static const MODS_FOLDER_NAME = "mods";
  static const SAVES_FOLDER_NAME = "saves";
  static const ARCHIVES_FOLDER_NAME = "Mod_Backups";

  static const VERSION_CHECKER_CSV_PATH = "data/config/version/version_files.csv";
  static const VERSION_CHECKER_FILE_ENDING = ".version";
  static const FORUM_URL = "https://fractalsoftworks.com/forum/index.php";
  static const NEXUS_MODS_PAGE_URL = "https://www.nexusmods.com/starsector/mods/";
  static const FORUM_MOD_PAGE_URL = "$FORUM_URL?topic=";
  static const FORUM_MOD_INDEX_URL = FORUM_MOD_PAGE_URL + "177";
  static const FORUM_MODDING_SUBFORUM_URL = "$FORUM_URL?board=3.0";
  static const FORUM_HOSTNAME = "fractalsoftworks.com";
  static const TIPS_FILE_RELATIVE_PATH = "data/strings/tips.json";
}
