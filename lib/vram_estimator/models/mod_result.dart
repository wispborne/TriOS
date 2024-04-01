import 'package:collection/collection.dart';

import '../vram_checker.dart';
import 'mod_image.dart';

class Mod {
  VramCheckerMod info;
  bool isEnabled;
  List<ModImage> images;

  Mod(this.info, this.isEnabled, this.images);

  late final totalBytesForMod = images.map((e) => e.bytesUsed).sum;
// .fold(0, (prev, next) => prev + next.bytesUsed);
}
