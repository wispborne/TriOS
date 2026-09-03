import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:trios/modpacks/modpack_format.dart';

/// How many random bytes go into a pack ID.
const int _packIdBytes = 16;

final Random _random = Random.secure();

/// Makes a new pack ID: 16 random bytes as exactly 22 unpadded base64url
/// characters.
///
/// The ID is opaque and case-sensitive. It is identity, not proof of
/// authorship, and every later version of the same pack keeps it.
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
