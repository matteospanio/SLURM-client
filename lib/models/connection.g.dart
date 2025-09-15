// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'connection.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SshConnection _$SshConnectionFromJson(Map<String, dynamic> json) =>
    SshConnection(
      name: json['name'] as String,
      hostname: json['hostname'] as String,
      port: json['port'] as int? ?? 22,
      username: json['username'] as String,
      privateKeyPath: json['privateKeyPath'] as String?,
      usePassword: json['usePassword'] as bool? ?? false,
      isDefault: json['isDefault'] as bool? ?? false,
    );

Map<String, dynamic> _$SshConnectionToJson(SshConnection instance) =>
    <String, dynamic>{
      'name': instance.name,
      'hostname': instance.hostname,
      'port': instance.port,
      'username': instance.username,
      'privateKeyPath': instance.privateKeyPath,
      'usePassword': instance.usePassword,
      'isDefault': instance.isDefault,
    };