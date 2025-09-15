// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppSettings _$AppSettingsFromJson(Map<String, dynamic> json) => AppSettings(
  refreshInterval: (json['refreshInterval'] as num?)?.toInt() ?? 30,
  autoRefresh: json['autoRefresh'] as bool? ?? true,
  showSystemTray: json['showSystemTray'] as bool? ?? true,
  startMinimized: json['startMinimized'] as bool? ?? false,
  themeMode:
      $enumDecodeNullable(_$ThemeModeEnumMap, json['themeMode']) ??
      ThemeMode.system,
  showNotifications: json['showNotifications'] as bool? ?? true,
  maxJobsToShow: (json['maxJobsToShow'] as num?)?.toInt() ?? 100,
  jobStateFilters:
      (json['jobStateFilters'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
);

Map<String, dynamic> _$AppSettingsToJson(AppSettings instance) =>
    <String, dynamic>{
      'refreshInterval': instance.refreshInterval,
      'autoRefresh': instance.autoRefresh,
      'showSystemTray': instance.showSystemTray,
      'startMinimized': instance.startMinimized,
      'themeMode': _$ThemeModeEnumMap[instance.themeMode]!,
      'showNotifications': instance.showNotifications,
      'maxJobsToShow': instance.maxJobsToShow,
      'jobStateFilters': instance.jobStateFilters,
    };

const _$ThemeModeEnumMap = {
  ThemeMode.light: 'light',
  ThemeMode.dark: 'dark',
  ThemeMode.system: 'system',
};

JobFilter _$JobFilterFromJson(Map<String, dynamic> json) => JobFilter(
  user: json['user'] as String?,
  name: json['name'] as String?,
  state: json['state'] as String?,
  node: json['node'] as String?,
  partition: json['partition'] as String?,
);

Map<String, dynamic> _$JobFilterToJson(JobFilter instance) => <String, dynamic>{
  'user': instance.user,
  'name': instance.name,
  'state': instance.state,
  'node': instance.node,
  'partition': instance.partition,
};
