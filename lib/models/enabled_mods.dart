import 'package:dart_json_mapper/dart_json_mapper.dart';

@jsonSerializable
class EnabledMods {
  List<String> enabledMods;

  EnabledMods(this.enabledMods);
}
