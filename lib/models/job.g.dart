// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'job.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SlurmJob _$SlurmJobFromJson(Map<String, dynamic> json) => SlurmJob(
  jobId: json['jobId'] as String,
  name: json['name'] as String,
  user: json['user'] as String,
  state: json['state'] as String,
  time: json['time'] as String,
  nodes: json['nodes'] as String,
  nodeList: json['nodeList'] as String,
  partition: json['partition'] as String?,
  qos: json['qos'] as String?,
  submitTime: json['submitTime'] == null
      ? null
      : DateTime.parse(json['submitTime'] as String),
  startTime: json['startTime'] == null
      ? null
      : DateTime.parse(json['startTime'] as String),
);

Map<String, dynamic> _$SlurmJobToJson(SlurmJob instance) => <String, dynamic>{
  'jobId': instance.jobId,
  'name': instance.name,
  'user': instance.user,
  'state': instance.state,
  'time': instance.time,
  'nodes': instance.nodes,
  'nodeList': instance.nodeList,
  'partition': instance.partition,
  'qos': instance.qos,
  'submitTime': instance.submitTime?.toIso8601String(),
  'startTime': instance.startTime?.toIso8601String(),
};
