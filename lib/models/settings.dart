import 'package:json_annotation/json_annotation.dart';

part 'settings.g.dart';

@JsonSerializable()
class AppSettings {
  final int refreshInterval; // in seconds
  final bool autoRefresh;
  final bool showSystemTray;
  final bool startMinimized;
  final ThemeMode themeMode;
  final bool showNotifications;
  final int maxJobsToShow;
  final List<String> jobStateFilters;

  const AppSettings({
    this.refreshInterval = 30,
    this.autoRefresh = true,
    this.showSystemTray = true,
    this.startMinimized = false,
    this.themeMode = ThemeMode.system,
    this.showNotifications = true,
    this.maxJobsToShow = 100,
    this.jobStateFilters = const [],
  });

  factory AppSettings.fromJson(Map<String, dynamic> json) =>
      _$AppSettingsFromJson(json);

  Map<String, dynamic> toJson() => _$AppSettingsToJson(this);

  AppSettings copyWith({
    int? refreshInterval,
    bool? autoRefresh,
    bool? showSystemTray,
    bool? startMinimized,
    ThemeMode? themeMode,
    bool? showNotifications,
    int? maxJobsToShow,
    List<String>? jobStateFilters,
  }) {
    return AppSettings(
      refreshInterval: refreshInterval ?? this.refreshInterval,
      autoRefresh: autoRefresh ?? this.autoRefresh,
      showSystemTray: showSystemTray ?? this.showSystemTray,
      startMinimized: startMinimized ?? this.startMinimized,
      themeMode: themeMode ?? this.themeMode,
      showNotifications: showNotifications ?? this.showNotifications,
      maxJobsToShow: maxJobsToShow ?? this.maxJobsToShow,
      jobStateFilters: jobStateFilters ?? this.jobStateFilters,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppSettings &&
          runtimeType == other.runtimeType &&
          refreshInterval == other.refreshInterval &&
          autoRefresh == other.autoRefresh &&
          showSystemTray == other.showSystemTray &&
          startMinimized == other.startMinimized &&
          themeMode == other.themeMode &&
          showNotifications == other.showNotifications &&
          maxJobsToShow == other.maxJobsToShow;

  @override
  int get hashCode => Object.hash(
        refreshInterval,
        autoRefresh,
        showSystemTray,
        startMinimized,
        themeMode,
        showNotifications,
        maxJobsToShow,
      );

  @override
  String toString() {
    return 'AppSettings{refreshInterval: $refreshInterval, autoRefresh: $autoRefresh, themeMode: $themeMode}';
  }
}

enum ThemeMode {
  light,
  dark,
  system,
}

@JsonSerializable()
class JobFilter {
  final String? user;
  final String? name;
  final String? state;
  final String? node;
  final String? partition;

  const JobFilter({
    this.user,
    this.name,
    this.state,
    this.node,
    this.partition,
  });

  factory JobFilter.fromJson(Map<String, dynamic> json) =>
      _$JobFilterFromJson(json);

  Map<String, dynamic> toJson() => _$JobFilterToJson(this);

  JobFilter copyWith({
    String? user,
    String? name,
    String? state,
    String? node,
    String? partition,
  }) {
    return JobFilter(
      user: user ?? this.user,
      name: name ?? this.name,
      state: state ?? this.state,
      node: node ?? this.node,
      partition: partition ?? this.partition,
    );
  }

  bool get isEmpty =>
      (user?.isEmpty ?? true) &&
      (name?.isEmpty ?? true) &&
      (state?.isEmpty ?? true) &&
      (node?.isEmpty ?? true) &&
      (partition?.isEmpty ?? true);

  bool get isNotEmpty => !isEmpty;

  @override
  String toString() {
    return 'JobFilter{user: $user, name: $name, state: $state, node: $node, partition: $partition}';
  }
}