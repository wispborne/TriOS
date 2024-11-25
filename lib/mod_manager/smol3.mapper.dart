// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'smol3.dart';

class SmolColumnMapper extends EnumMapper<SmolColumn> {
  SmolColumnMapper._();

  static SmolColumnMapper? _instance;
  static SmolColumnMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = SmolColumnMapper._());
    }
    return _instance!;
  }

  static SmolColumn fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  SmolColumn decode(dynamic value) {
    switch (value) {
      case 'enableDisable':
        return SmolColumn.enableDisable;
      case 'versionSelector':
        return SmolColumn.versionSelector;
      case 'utilityIcon':
        return SmolColumn.utilityIcon;
      case 'modIcon':
        return SmolColumn.modIcon;
      case 'name':
        return SmolColumn.name;
      case 'author':
        return SmolColumn.author;
      case 'versions':
        return SmolColumn.versions;
      case 'vramEstimate':
        return SmolColumn.vramEstimate;
      case 'gameVersion':
        return SmolColumn.gameVersion;
      default:
        throw MapperException.unknownEnumValue(value);
    }
  }

  @override
  dynamic encode(SmolColumn self) {
    switch (self) {
      case SmolColumn.enableDisable:
        return 'enableDisable';
      case SmolColumn.versionSelector:
        return 'versionSelector';
      case SmolColumn.utilityIcon:
        return 'utilityIcon';
      case SmolColumn.modIcon:
        return 'modIcon';
      case SmolColumn.name:
        return 'name';
      case SmolColumn.author:
        return 'author';
      case SmolColumn.versions:
        return 'versions';
      case SmolColumn.vramEstimate:
        return 'vramEstimate';
      case SmolColumn.gameVersion:
        return 'gameVersion';
    }
  }
}

extension SmolColumnMapperExtension on SmolColumn {
  String toValue() {
    SmolColumnMapper.ensureInitialized();
    return MapperContainer.globals.toValue<SmolColumn>(this) as String;
  }
}
