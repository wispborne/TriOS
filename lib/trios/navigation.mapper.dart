// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
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
      case r'dashboard':
        return TriOSTools.dashboard;
      case r'modManager':
        return TriOSTools.modManager;
      case r'modProfiles':
        return TriOSTools.modProfiles;
      case r'vramEstimator':
        return TriOSTools.vramEstimator;
      case r'chipper':
        return TriOSTools.chipper;
      case r'jreManager':
        return TriOSTools.jreManager;
      case r'portraits':
        return TriOSTools.portraits;
      case r'weapons':
        return TriOSTools.weapons;
      case r'ships':
        return TriOSTools.ships;
      case r'settings':
        return TriOSTools.settings;
      case r'catalog':
        return TriOSTools.catalog;
      case r'tips':
        return TriOSTools.tips;
      default:
        return TriOSTools.values[0];
    }
  }

  @override
  dynamic encode(TriOSTools self) {
    switch (self) {
      case TriOSTools.dashboard:
        return r'dashboard';
      case TriOSTools.modManager:
        return r'modManager';
      case TriOSTools.modProfiles:
        return r'modProfiles';
      case TriOSTools.vramEstimator:
        return r'vramEstimator';
      case TriOSTools.chipper:
        return r'chipper';
      case TriOSTools.jreManager:
        return r'jreManager';
      case TriOSTools.portraits:
        return r'portraits';
      case TriOSTools.weapons:
        return r'weapons';
      case TriOSTools.ships:
        return r'ships';
      case TriOSTools.settings:
        return r'settings';
      case TriOSTools.catalog:
        return r'catalog';
      case TriOSTools.tips:
        return r'tips';
    }
  }
}

extension TriOSToolsMapperExtension on TriOSTools {
  String toValue() {
    TriOSToolsMapper.ensureInitialized();
    return MapperContainer.globals.toValue<TriOSTools>(this) as String;
  }
}

