import 'package:image_size_getter/image_size_getter.dart';

/// Convert hex a decimal list to int type.
///
/// If the number is stored in big endian, pass [reverse] as false.
///
/// If the number is stored in little endian, pass [reverse] as true.
int convertRadix16ToInt(List<int> list, {bool reverse = false}) {
  final sb = StringBuffer();
  if (reverse) {
    list = list.toList().reversed.toList();
  }

  for (final i in list) {
    sb.write(i.toRadixString(16).padLeft(2, '0'));
  }
  final numString = sb.toString();
  return int.tryParse(numString, radix: 16) ?? 0;
}

class PngFullDecoder extends BaseDecoder with SimpleTypeValidator {
  PngFullDecoder();

  @override
  String get decoderName => 'png';

  @override
  Size getSize(ImageInput input) {
    final widthList = input.getRange(0x10, 0x14);
    final heightList = input.getRange(0x14, 0x18);

    final width = convertRadix16ToInt(widthList);
    final height = convertRadix16ToInt(heightList);

    return Size(width, height);
  }

  @override
  Future<Size> getSizeAsync(AsyncImageInput input) async {
    final widthList = await input.getRange(0x10, 0x14);
    final heightList = await input.getRange(0x14, 0x18);
    // final bitDepthList = await input.getRange(0x19, 0x20);
    // final colorTypeList = await input.getRange(0x21, 0x22);
    final width = convertRadix16ToInt(widthList);
    final height = convertRadix16ToInt(heightList);
    return Size(width, height);
  }

  @override
  SimpleFileHeaderAndFooter get simpleFileHeaderAndFooter => _PngHeaders();

  late Future<int> getNumChannels;
  late Future<int> getBitDepth;
}

class _PngHeaders with SimpleFileHeaderAndFooter {
  static const sig = [
    0x89,
    0x50,
    0x4E,
    0x47,
    0x0D,
    0x0A,
    0x1A,
    0x0A,
  ];

  static const iend = [
    0x00,
    0x00,
    0x00,
    0x00,
    0x49,
    0x45,
    0x4E,
    0x44,
    0xAE,
    0x42,
    0x60,
    0x82
  ];

  @override
  List<int> get endBytes => iend;

  @override
  List<int> get startBytes => sig;
}
