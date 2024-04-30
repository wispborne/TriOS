// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../models/launch_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$LaunchSettingsImpl _$$LaunchSettingsImplFromJson(Map<String, dynamic> json) =>
    _$LaunchSettingsImpl(
      isFullscreen: json['isFullscreen'] as bool?,
      hasSound: json['hasSound'] as bool?,
      resolutionWidth: (json['resolutionWidth'] as num?)?.toInt(),
      resolutionHeight: (json['resolutionHeight'] as num?)?.toInt(),
      numAASamples: (json['numAASamples'] as num?)?.toInt(),
      screenScaling: (json['screenScaling'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$$LaunchSettingsImplToJson(
        _$LaunchSettingsImpl instance) =>
    <String, dynamic>{
      'isFullscreen': instance.isFullscreen,
      'hasSound': instance.hasSound,
      'resolutionWidth': instance.resolutionWidth,
      'resolutionHeight': instance.resolutionHeight,
      'numAASamples': instance.numAASamples,
      'screenScaling': instance.screenScaling,
    };
