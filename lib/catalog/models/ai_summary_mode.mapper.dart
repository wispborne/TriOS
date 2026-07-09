// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'ai_summary_mode.dart';

class AiSummaryModeMapper extends EnumMapper<AiSummaryMode> {
  AiSummaryModeMapper._();

  static AiSummaryModeMapper? _instance;
  static AiSummaryModeMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = AiSummaryModeMapper._());
    }
    return _instance!;
  }

  static AiSummaryMode fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  AiSummaryMode decode(dynamic value) {
    switch (value) {
      case r'always':
        return AiSummaryMode.always;
      case r'whenNoAuthorText':
        return AiSummaryMode.whenNoAuthorText;
      case r'never':
        return AiSummaryMode.never;
      default:
        return AiSummaryMode.values[1];
    }
  }

  @override
  dynamic encode(AiSummaryMode self) {
    switch (self) {
      case AiSummaryMode.always:
        return r'always';
      case AiSummaryMode.whenNoAuthorText:
        return r'whenNoAuthorText';
      case AiSummaryMode.never:
        return r'never';
    }
  }
}

extension AiSummaryModeMapperExtension on AiSummaryMode {
  String toValue() {
    AiSummaryModeMapper.ensureInitialized();
    return MapperContainer.globals.toValue<AiSummaryMode>(this) as String;
  }
}

