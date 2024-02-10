import 'package:collection/collection.dart';

import 'mod_image.dart';
import 'mod_info.dart';

class Mod {
  ModInfo info;
  bool isEnabled;
  List<ModImage> images;

  Mod(this.info, this.isEnabled, this.images);

  late final totalBytesForMod = images.map((e) => e.bytesUsed).sum;
      // .fold(0, (prev, next) => prev + next.bytesUsed);
}
