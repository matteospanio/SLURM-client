import 'dart:async';
import '../models/job.dart';
import 'base_ssh_service.dart';

class SlurmService {
  final BaseSSHService _sshService;

  SlurmService(this._sshService);

  /// Get user's job queue using squeue --me
  Future<List<SlurmJob>> getUserJobs() async {
    try {
      final command =
          'squeue --me --format="%18i %.9P %.20j %.8u %.2t %.10M %.6D %R"';
      final result = await _sshService.executeCommand(command);

      return _parseSqueuOutput(result);
    } catch (e) {
      throw Exception('Failed to get user jobs: $e');
    }
  }

  /// Get all jobs with optional filters
  Future<List<SlurmJob>> getJobs({
    String? user,
    String? partition,
    String? state,
  }) async {
    try {
      var command = 'squeue --format="%18i %.9P %.20j %.8u %.2t %.10M %.6D %R"';

      if (user != null && user.isNotEmpty) {
        command += ' --user=$user';
      }
      if (partition != null && partition.isNotEmpty) {
        command += ' --partition=$partition';
      }
      if (state != null && state.isNotEmpty) {
        command += ' --states=$state';
      }

      final result = await _sshService.executeCommand(command);
      return _parseSqueuOutput(result);
    } catch (e) {
      throw Exception('Failed to get jobs: $e');
    }
  }

  /// Cancel a specific job
  Future<bool> cancelJob(String jobId) async {
    try {
      final command = 'scancel $jobId';
      final result = await _sshService.executeCommandWithDetails(command);

      if (result.isSuccess) {
        return true;
      } else {
        throw Exception('scancel failed: ${result.stderr}');
      }
    } catch (e) {
      throw Exception('Failed to cancel job $jobId: $e');
    }
  }

  /// Get detailed job information
  Future<Map<String, dynamic>> getJobDetails(String jobId) async {
    try {
      final command = 'scontrol show job $jobId';
      final result = await _sshService.executeCommand(command);

      return _parseScontrolOutput(result);
    } catch (e) {
      throw Exception('Failed to get job details for $jobId: $e');
    }
  }

  /// Get cluster information
  Future<Map<String, dynamic>> getClusterInfo() async {
    try {
      final command = 'sinfo --format="%20P %.5a %.10l %.6D %.6t %N"';
      final result = await _sshService.executeCommand(command);

      return _parseSinfoOutput(result);
    } catch (e) {
      throw Exception('Failed to get cluster info: $e');
    }
  }

  /// Check if SLURM is available on the system
  Future<bool> isSlurmAvailable() async {
    try {
      final result = await _sshService.executeCommandWithDetails(
        'which squeue',
      );
      return result.isSuccess;
    } catch (e) {
      return false;
    }
  }

  /// Get SLURM version
  Future<String?> getSlurmVersion() async {
    try {
      final result = await _sshService.executeCommand('sinfo --version');
      final lines = result.split('\n');
      if (lines.isNotEmpty) {
        return lines.first.trim();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Parse squeue output into job objects
  List<SlurmJob> _parseSqueuOutput(String output) {
    final jobs = <SlurmJob>[];
    final lines = output.split('\n');

    // Skip header line and empty lines
    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      try {
        final job = SlurmJob.fromSqueueLine(line);
        jobs.add(job);
      } catch (e) {
        // Skip malformed lines
        continue;
      }
    }

    return jobs;
  }

  /// Parse scontrol output into job details
  Map<String, dynamic> _parseScontrolOutput(String output) {
    final details = <String, dynamic>{};
    final lines = output.split('\n');

    for (final line in lines) {
      if (line.trim().isEmpty) continue;

      // Parse key=value pairs
      final keyValuePairs = line.split(' ');
      for (final pair in keyValuePairs) {
        if (pair.contains('=')) {
          final parts = pair.split('=');
          if (parts.length >= 2) {
            final key = parts[0].trim();
            final value = parts.sublist(1).join('=').trim();
            details[key] = value;
          }
        }
      }
    }

    return details;
  }

  /// Parse sinfo output into cluster information
  Map<String, dynamic> _parseSinfoOutput(String output) {
    final partitions = <Map<String, dynamic>>[];
    final lines = output.split('\n');

    // Skip header line
    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      final parts = line.split(RegExp(r'\s+'));
      if (parts.length >= 5) {
        partitions.add({
          'partition': parts[0],
          'availability': parts[1],
          'timeLimit': parts[2],
          'nodes': parts[3],
          'state': parts[4],
          'nodeList': parts.length > 5 ? parts[5] : '',
        });
      }
    }

    return {'partitions': partitions, 'totalPartitions': partitions.length};
  }

  /// Get job statistics
  Future<Map<String, int>> getJobStatistics({String? user}) async {
    try {
      final jobs = user != null
          ? await getJobs(user: user)
          : await getUserJobs();
      final stats = <String, int>{};

      for (final job in jobs) {
        final state = SlurmJob.getStateName(job.state);
        stats[state] = (stats[state] ?? 0) + 1;
      }

      return stats;
    } catch (e) {
      throw Exception('Failed to get job statistics: $e');
    }
  }

  /// Get queue length for specific partition
  Future<int> getQueueLength({String? partition}) async {
    try {
      final jobs = await getJobs(partition: partition, state: 'PD');
      return jobs.length;
    } catch (e) {
      throw Exception('Failed to get queue length: $e');
    }
  }
}
