import 'package:json_annotation/json_annotation.dart';

part 'job.g.dart';

@JsonSerializable()
class SlurmJob {
  final String jobId;
  final String name;
  final String user;
  final String state;
  final String time;
  final String nodes;
  final String nodeList;
  final String? partition;
  final String? qos;
  final DateTime? submitTime;
  final DateTime? startTime;

  const SlurmJob({
    required this.jobId,
    required this.name,
    required this.user,
    required this.state,
    required this.time,
    required this.nodes,
    required this.nodeList,
    this.partition,
    this.qos,
    this.submitTime,
    this.startTime,
  });

  factory SlurmJob.fromJson(Map<String, dynamic> json) =>
      _$SlurmJobFromJson(json);

  Map<String, dynamic> toJson() => _$SlurmJobToJson(this);

  /// Parse a job from squeue output line
  /// Format: JOBID PARTITION NAME USER ST TIME NODES NODELIST(REASON)
  factory SlurmJob.fromSqueueLine(String line) {
    final parts = line.trim().split(RegExp(r'\s+'));
    if (parts.length < 8) {
      throw FormatException('Invalid squeue line format: $line');
    }

    return SlurmJob(
      jobId: parts[0],
      partition: parts[1] == 'null' ? null : parts[1],
      name: parts[2],
      user: parts[3],
      state: parts[4],
      time: parts[5],
      nodes: parts[6],
      nodeList: parts[7],
    );
  }

  SlurmJob copyWith({
    String? jobId,
    String? name,
    String? user,
    String? state,
    String? time,
    String? nodes,
    String? nodeList,
    String? partition,
    String? qos,
    DateTime? submitTime,
    DateTime? startTime,
  }) {
    return SlurmJob(
      jobId: jobId ?? this.jobId,
      name: name ?? this.name,
      user: user ?? this.user,
      state: state ?? this.state,
      time: time ?? this.time,
      nodes: nodes ?? this.nodes,
      nodeList: nodeList ?? this.nodeList,
      partition: partition ?? this.partition,
      qos: qos ?? this.qos,
      submitTime: submitTime ?? this.submitTime,
      startTime: startTime ?? this.startTime,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SlurmJob &&
          runtimeType == other.runtimeType &&
          jobId == other.jobId;

  @override
  int get hashCode => jobId.hashCode;

  @override
  String toString() {
    return 'SlurmJob{jobId: $jobId, name: $name, user: $user, state: $state}';
  }

  /// Check if job matches the given filter criteria
  bool matchesFilter({
    String? userFilter,
    String? nameFilter,
    String? stateFilter,
    String? nodeFilter,
  }) {
    if (userFilter != null &&
        userFilter.isNotEmpty &&
        !user.toLowerCase().contains(userFilter.toLowerCase())) {
      return false;
    }
    if (nameFilter != null &&
        nameFilter.isNotEmpty &&
        !name.toLowerCase().contains(nameFilter.toLowerCase())) {
      return false;
    }
    if (stateFilter != null &&
        stateFilter.isNotEmpty &&
        !state.toLowerCase().contains(stateFilter.toLowerCase())) {
      return false;
    }
    if (nodeFilter != null &&
        nodeFilter.isNotEmpty &&
        !nodeList.toLowerCase().contains(nodeFilter.toLowerCase())) {
      return false;
    }
    return true;
  }

  /// Get a color for the job state
  static String getStateColor(String state) {
    switch (state.toLowerCase()) {
      case 'r':
      case 'running':
        return '#4CAF50'; // Green
      case 'pd':
      case 'pending':
        return '#FF9800'; // Orange
      case 'cg':
      case 'completing':
        return '#2196F3'; // Blue
      case 'cd':
      case 'completed':
        return '#9E9E9E'; // Grey
      case 'f':
      case 'failed':
        return '#F44336'; // Red
      case 'ca':
      case 'cancelled':
        return '#795548'; // Brown
      default:
        return '#757575'; // Default grey
    }
  }

  /// Get human-readable state name
  static String getStateName(String state) {
    switch (state.toLowerCase()) {
      case 'r':
        return 'Running';
      case 'pd':
        return 'Pending';
      case 'cg':
        return 'Completing';
      case 'cd':
        return 'Completed';
      case 'f':
        return 'Failed';
      case 'ca':
        return 'Cancelled';
      case 's':
        return 'Suspended';
      default:
        return state.toUpperCase();
    }
  }
}