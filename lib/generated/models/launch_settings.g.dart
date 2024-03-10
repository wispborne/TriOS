// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../models/launch_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$LaunchSettingsImpl _$$LaunchSettingsImplFromJson(Map<String, dynamic> json) =>
    _$LaunchSettingsImpl(
      isFullscreen: json['isFullscreen'] as bool?,
      hasSound: json['hasSound'] as bool?,
      resolutionWidth: json['resolutionWidth'] as int?,
      resolutionHeight: json['resolutionHeight'] as int?,
    );

Map<String, dynamic> _$$LaunchSettingsImplToJson(
        _$LaunchSettingsImpl instance) =>
    <String, dynamic>{
      'isFullscreen': instance.isFullscreen,
      'hasSound': instance.hasSound,
      'resolutionWidth': instance.resolutionWidth,
      'resolutionHeight': instance.resolutionHeight,
    };
