// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'catalog_card_click_action.dart';

class CatalogCardClickActionMapper extends EnumMapper<CatalogCardClickAction> {
  CatalogCardClickActionMapper._();

  static CatalogCardClickActionMapper? _instance;
  static CatalogCardClickActionMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = CatalogCardClickActionMapper._());
    }
    return _instance!;
  }

  static CatalogCardClickAction fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  CatalogCardClickAction decode(dynamic value) {
    switch (value) {
      case r'forumDialog':
        return CatalogCardClickAction.forumDialog;
      case r'embeddedBrowser':
        return CatalogCardClickAction.embeddedBrowser;
      case r'systemBrowser':
        return CatalogCardClickAction.systemBrowser;
      default:
        return CatalogCardClickAction.values[0];
    }
  }

  @override
  dynamic encode(CatalogCardClickAction self) {
    switch (self) {
      case CatalogCardClickAction.forumDialog:
        return r'forumDialog';
      case CatalogCardClickAction.embeddedBrowser:
        return r'embeddedBrowser';
      case CatalogCardClickAction.systemBrowser:
        return r'systemBrowser';
    }
  }
}

extension CatalogCardClickActionMapperExtension on CatalogCardClickAction {
  String toValue() {
    CatalogCardClickActionMapper.ensureInitialized();
    return MapperContainer.globals.toValue<CatalogCardClickAction>(this)
        as String;
  }
}

