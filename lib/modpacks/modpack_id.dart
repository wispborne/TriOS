import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:trios/modpacks/modpack_format.dart';

const int _packIdBytes = 16;

final Random _random = Random.secure();

/// Makes a new pack ID: 16 random bytes as 22 unpadded base64url characters.
///
/// The ID is opaque, case-sensitive, and stays with a pack across versions.
String generateModpackId() {
  final bytes = Uint8List(_packIdBytes);
  for (var i = 0; i < _packIdBytes; i++) {
    bytes[i] = _random.nextInt(256);
  }
  final id = base64Url.encode(bytes).replaceAll('=', '');
  assert(
    isValidModpackId(id),
    'Generated pack ID $id is not ${ModpackLimits.packIdLength} base64url '
    'characters.',
  );
  return id;
}
