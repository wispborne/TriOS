import 'mod_image.dart';
import 'mod_info.dart';

class Mod {
  ModInfo info;
  bool isEnabled;
  List<ModImage> images;

  Mod(this.info, this.isEnabled, this.images);

  late final totalBytesForMod = images
      .fold(0.00, (prev, next) => prev + next.bytesUsed.toDouble())
      .round();
}
