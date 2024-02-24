import 'dart:collection';

import 'mod_entry.dart';

class UserMods {
  UnmodifiableListView<ModEntry> modList;
  bool isPerfectList;

  UserMods(this.modList, {required this.isPerfectList});
}
