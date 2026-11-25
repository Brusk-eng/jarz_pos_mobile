// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'studio_me.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$StudioMeImpl _$$StudioMeImplFromJson(Map<String, dynamic> json) =>
    _$StudioMeImpl(
      user: json['user'] as String,
      fullName: json['full_name'] as String? ?? '',
      roles:
          (json['roles'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          const <String>[],
      isFounder: json['is_founder'] as bool? ?? false,
      mode: json['mode'] as String? ?? 'live',
      serverTime: json['server_time'] as String? ?? '',
    );

Map<String, dynamic> _$$StudioMeImplToJson(_$StudioMeImpl instance) =>
    <String, dynamic>{
      'user': instance.user,
      'full_name': instance.fullName,
      'roles': instance.roles,
      'is_founder': instance.isFounder,
      'mode': instance.mode,
      'server_time': instance.serverTime,
    };
