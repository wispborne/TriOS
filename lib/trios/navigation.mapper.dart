// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'navigation.dart';

class TriOSToolsMapper extends EnumMapper<TriOSTools> {
  TriOSToolsMapper._();

  static TriOSToolsMapper? _instance;
  static TriOSToolsMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = TriOSToolsMapper._());
    }
    return _instance!;
  }

  static TriOSTools fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  TriOSTools decode(dynamic value) {
    switch (value) {
      case 'dashboard':
        return TriOSTools.dashboard;
      case 'modManager':
        return TriOSTools.modManager;
      case 'modProfiles':
        return TriOSTools.modProfiles;
      case 'vramEstimator':
        return TriOSTools.vramEstimator;
      case 'chipper':
        return TriOSTools.chipper;
      case 'jreManager':
        return TriOSTools.jreManager;
      case 'portraits':
        return TriOSTools.portraits;
      case 'weapons':
        return TriOSTools.weapons;
      case 'settings':
        return TriOSTools.settings;
      case 'modBrowser':
        return TriOSTools.modBrowser;
      default:
        throw MapperException.unknownEnumValue(value);
    }
  }

  @override
  dynamic encode(TriOSTools self) {
    switch (self) {
      case TriOSTools.dashboard:
        return 'dashboard';
      case TriOSTools.modManager:
        return 'modManager';
      case TriOSTools.modProfiles:
        return 'modProfiles';
      case TriOSTools.vramEstimator:
        return 'vramEstimator';
      case TriOSTools.chipper:
        return 'chipper';
      case TriOSTools.jreManager:
        return 'jreManager';
      case TriOSTools.portraits:
        return 'portraits';
      case TriOSTools.weapons:
        return 'weapons';
      case TriOSTools.settings:
        return 'settings';
      case TriOSTools.modBrowser:
        return 'modBrowser';
    }
  }
}

extension TriOSToolsMapperExtension on TriOSTools {
  String toValue() {
    TriOSToolsMapper.ensureInitialized();
    return MapperContainer.globals.toValue<TriOSTools>(this) as String;
  }
}
