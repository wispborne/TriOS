// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'vram_selector_id.dart';

class VramSelectorIdMapper extends EnumMapper<VramSelectorId> {
  VramSelectorIdMapper._();

  static VramSelectorIdMapper? _instance;
  static VramSelectorIdMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = VramSelectorIdMapper._());
    }
    return _instance!;
  }

  static VramSelectorId fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  VramSelectorId decode(dynamic value) {
    switch (value) {
      case 'folder-scan':
        return VramSelectorId.folderScan;
      case 'referenced':
        return VramSelectorId.referenced;
      default:
        return VramSelectorId.values[0];
    }
  }

  @override
  dynamic encode(VramSelectorId self) {
    switch (self) {
      case VramSelectorId.folderScan:
        return 'folder-scan';
      case VramSelectorId.referenced:
        return 'referenced';
    }
  }
}

extension VramSelectorIdMapperExtension on VramSelectorId {
  dynamic toValue() {
    VramSelectorIdMapper.ensureInitialized();
    return MapperContainer.globals.toValue<VramSelectorId>(this);
  }
}

