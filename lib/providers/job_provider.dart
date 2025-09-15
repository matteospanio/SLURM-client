import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/job.dart';
import '../models/settings.dart';
import '../services/slurm_service.dart';

class JobProvider extends ChangeNotifier {
  final SlurmService _slurmService;
  
  List<SlurmJob> _jobs = [];
  List<SlurmJob> _filteredJobs = [];
  JobFilter _filter = const JobFilter();
  bool _isLoading = false;
  String? _error;
  DateTime? _lastUpdate;
  Timer? _refreshTimer;
  Map<String, int> _jobStatistics = {};

  JobProvider(this._slurmService);

  // Getters
  List<SlurmJob> get jobs => _filteredJobs;
  List<SlurmJob> get allJobs => _jobs;
  JobFilter get filter => _filter;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime? get lastUpdate => _lastUpdate;
  Map<String, int> get jobStatistics => _jobStatistics;
  bool get hasJobs => _jobs.isNotEmpty;
  int get totalJobs => _jobs.length;
  int get filteredJobsCount => _filteredJobs.length;

  /// Load jobs from the SLURM cluster
  Future<void> loadJobs({bool showLoading = true}) async {
    if (showLoading) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    try {
      _jobs = await _slurmService.getUserJobs();
      _lastUpdate = DateTime.now();
      _error = null;
      
      // Update statistics
      await _updateJobStatistics();
      
      // Apply current filter
      _applyFilter();
    } catch (e) {
      final errorMessage = e.toString();
      
      // Check if it's a connection issue
      if (errorMessage.contains('Not connected to SSH server')) {
        _error = 'Not connected to SSH server. Please connect to a cluster first.';
        // Clear jobs when not connected
        _jobs = [];
        _filteredJobs = [];
        _jobStatistics = {};
      } else {
        _error = errorMessage;
      }
      
      debugPrint('Error loading jobs: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh jobs (same as load but with different semantics)
  Future<void> refreshJobs() async {
    await loadJobs(showLoading: false);
  }

  /// Apply job filter
  void applyFilter(JobFilter filter) {
    _filter = filter;
    _applyFilter();
    notifyListeners();
  }

  /// Clear all filters
  void clearFilter() {
    _filter = const JobFilter();
    _applyFilter();
    notifyListeners();
  }

  /// Apply the current filter to the jobs list
  void _applyFilter() {
    if (_filter.isEmpty) {
      _filteredJobs = List.from(_jobs);
    } else {
      _filteredJobs = _jobs.where((job) {
        return job.matchesFilter(
          userFilter: _filter.user,
          nameFilter: _filter.name,
          stateFilter: _filter.state,
          nodeFilter: _filter.node,
        );
      }).toList();
    }
  }

  /// Cancel a specific job
  Future<bool> cancelJob(String jobId) async {
    try {
      final success = await _slurmService.cancelJob(jobId);
      if (success) {
        // Refresh jobs after cancellation
        await refreshJobs();
      }
      return success;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Get detailed information for a job
  Future<Map<String, dynamic>?> getJobDetails(String jobId) async {
    try {
      return await _slurmService.getJobDetails(jobId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Start auto-refresh timer
  void startAutoRefresh(int intervalSeconds) {
    stopAutoRefresh();
    _refreshTimer = Timer.periodic(
      Duration(seconds: intervalSeconds),
      (_) {
        // Only refresh if we're likely to be connected
        // The loadJobs method will handle the not-connected case gracefully
        refreshJobs();
      },
    );
  }

  /// Stop auto-refresh timer
  void stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  /// Check if auto-refresh is active
  bool get isAutoRefreshActive => _refreshTimer?.isActive ?? false;

  /// Get jobs by state
  List<SlurmJob> getJobsByState(String state) {
    return _filteredJobs.where((job) => job.state.toLowerCase() == state.toLowerCase()).toList();
  }

  /// Get running jobs
  List<SlurmJob> get runningJobs => getJobsByState('R');

  /// Get pending jobs
  List<SlurmJob> get pendingJobs => getJobsByState('PD');

  /// Get completed jobs
  List<SlurmJob> get completedJobs => getJobsByState('CD');

  /// Get failed jobs
  List<SlurmJob> get failedJobs => getJobsByState('F');

  /// Update job statistics
  Future<void> _updateJobStatistics() async {
    try {
      _jobStatistics = await _slurmService.getJobStatistics();
    } catch (e) {
      debugPrint('Error updating job statistics: $e');
      _jobStatistics = {};
    }
  }

  /// Search jobs by name
  List<SlurmJob> searchJobsByName(String query) {
    if (query.isEmpty) return _filteredJobs;
    
    final lowerQuery = query.toLowerCase();
    return _filteredJobs.where((job) {
      return job.name.toLowerCase().contains(lowerQuery) ||
             job.jobId.contains(query);
    }).toList();
  }

  /// Sort jobs by different criteria
  void sortJobs(JobSortCriteria criteria, {bool ascending = true}) {
    _filteredJobs.sort((a, b) {
      int comparison;
      switch (criteria) {
        case JobSortCriteria.jobId:
          comparison = a.jobId.compareTo(b.jobId);
          break;
        case JobSortCriteria.name:
          comparison = a.name.compareTo(b.name);
          break;
        case JobSortCriteria.user:
          comparison = a.user.compareTo(b.user);
          break;
        case JobSortCriteria.state:
          comparison = a.state.compareTo(b.state);
          break;
        case JobSortCriteria.time:
          comparison = a.time.compareTo(b.time);
          break;
        case JobSortCriteria.nodes:
          comparison = int.parse(a.nodes).compareTo(int.parse(b.nodes));
          break;
      }
      return ascending ? comparison : -comparison;
    });
    notifyListeners();
  }

  /// Get unique values for filter dropdowns
  List<String> get uniqueUsers {
    return _jobs.map((job) => job.user).toSet().toList()..sort();
  }

  List<String> get uniqueStates {
    return _jobs.map((job) => SlurmJob.getStateName(job.state)).toSet().toList()..sort();
  }

  List<String> get uniquePartitions {
    return _jobs
        .where((job) => job.partition != null)
        .map((job) => job.partition!)
        .toSet()
        .toList()
      ..sort();
  }

  /// Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    stopAutoRefresh();
    super.dispose();
  }
}

enum JobSortCriteria {
  jobId,
  name,
  user,
  state,
  time,
  nodes,
}