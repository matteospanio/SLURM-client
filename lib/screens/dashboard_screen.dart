import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/job_provider.dart';
import '../providers/connection_provider.dart';
import '../models/job.dart';
import '../models/settings.dart';
import '../widgets/job_card.dart';
import '../widgets/connection_dialog.dart';
import '../widgets/job_filter_dialog.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TextEditingController _searchController = TextEditingController();
  JobSortCriteria _sortCriteria = JobSortCriteria.jobId;
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    
    // Auto-connect to default connection if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final connectionProvider = context.read<ConnectionProvider>();
      if (!connectionProvider.isConnected && connectionProvider.defaultConnection != null) {
        _showConnectionDialog();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SLURM Queue Monitor'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          Consumer<ConnectionProvider>(
            builder: (context, connectionProvider, child) {
              return IconButton(
                icon: Icon(
                  connectionProvider.isConnected 
                      ? Icons.cloud_done 
                      : Icons.cloud_off,
                  color: connectionProvider.isConnected 
                      ? Colors.green 
                      : Colors.red,
                ),
                onPressed: () => _showConnectionDialog(),
                tooltip: connectionProvider.isConnected 
                    ? 'Connected to ${connectionProvider.currentConnection?.name}'
                    : 'Not connected',
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(),
            tooltip: 'Filter jobs',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (String value) {
              setState(() {
                if (_sortCriteria.toString() == value) {
                  _sortAscending = !_sortAscending;
                } else {
                  _sortCriteria = JobSortCriteria.values.firstWhere(
                    (criteria) => criteria.toString() == value,
                  );
                  _sortAscending = true;
                }
              });
              context.read<JobProvider>().sortJobs(_sortCriteria, ascending: _sortAscending);
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem(
                value: JobSortCriteria.jobId.toString(),
                child: Text('Sort by Job ID'),
              ),
              PopupMenuItem(
                value: JobSortCriteria.name.toString(),
                child: Text('Sort by Name'),
              ),
              PopupMenuItem(
                value: JobSortCriteria.user.toString(),
                child: Text('Sort by User'),
              ),
              PopupMenuItem(
                value: JobSortCriteria.state.toString(),
                child: Text('Sort by State'),
              ),
              PopupMenuItem(
                value: JobSortCriteria.time.toString(),
                child: Text('Sort by Time'),
              ),
              PopupMenuItem(
                value: JobSortCriteria.nodes.toString(),
                child: Text('Sort by Nodes'),
              ),
            ],
          ),
          Consumer<JobProvider>(
            builder: (context, jobProvider, child) {
              return IconButton(
                icon: jobProvider.isLoading 
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                onPressed: jobProvider.isLoading ? null : () => _refreshJobs(),
                tooltip: 'Refresh jobs',
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _navigateToSettings(),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildJobStatistics(),
          Expanded(child: _buildJobsList()),
        ],
      ),
      floatingActionButton: Consumer<ConnectionProvider>(
        builder: (context, connectionProvider, child) {
          if (!connectionProvider.isConnected) {
            return FloatingActionButton(
              onPressed: () => _showConnectionDialog(),
              child: const Icon(Icons.add),
              tooltip: 'Connect to cluster',
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search jobs by name or ID...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
        onChanged: _onSearchChanged,
      ),
    );
  }

  Widget _buildJobStatistics() {
    return Consumer<JobProvider>(
      builder: (context, jobProvider, child) {
        if (jobProvider.jobStatistics.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatChip('Total', jobProvider.totalJobs.toString(), Colors.blue),
                  _buildStatChip('Running', jobProvider.jobStatistics['Running']?.toString() ?? '0', Colors.green),
                  _buildStatChip('Pending', jobProvider.jobStatistics['Pending']?.toString() ?? '0', Colors.orange),
                  _buildStatChip('Failed', jobProvider.jobStatistics['Failed']?.toString() ?? '0', Colors.red),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatChip(String label, String count, Color color) {
    return Column(
      children: [
        Text(
          count,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildJobsList() {
    return Consumer2<JobProvider, ConnectionProvider>(
      builder: (context, jobProvider, connectionProvider, child) {
        if (!connectionProvider.isConnected) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cloud_off, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                const Text('Not connected to cluster'),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => _showConnectionDialog(),
                  child: const Text('Connect'),
                ),
              ],
            ),
          );
        }

        if (jobProvider.isLoading && jobProvider.jobs.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (jobProvider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 64, color: Colors.red[400]),
                const SizedBox(height: 16),
                Text('Error: ${jobProvider.error}'),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => _refreshJobs(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (jobProvider.jobs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.work_off, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                const Text('No jobs found'),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => _refreshJobs(),
                  child: const Text('Refresh'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _refreshJobs,
          child: ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: jobProvider.jobs.length,
            itemBuilder: (context, index) {
              final job = jobProvider.jobs[index];
              return JobCard(
                job: job,
                onCancel: () => _cancelJob(job.jobId),
                onDetails: () => _showJobDetails(job),
              );
            },
          ),
        );
      },
    );
  }

  void _onSearchChanged(String query) {
    // Filter jobs based on search query
    // This could be implemented in the JobProvider
  }

  Future<void> _refreshJobs() async {
    final jobProvider = context.read<JobProvider>();
    await jobProvider.loadJobs();
  }

  void _showConnectionDialog() {
    showDialog(
      context: context,
      builder: (context) => const ConnectionDialog(),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => const JobFilterDialog(),
    );
  }

  Future<void> _cancelJob(String jobId) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Job'),
        content: Text('Are you sure you want to cancel job $jobId?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (result == true) {
      final jobProvider = context.read<JobProvider>();
      final success = await jobProvider.cancelJob(jobId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success 
                  ? 'Job $jobId cancelled successfully'
                  : 'Failed to cancel job $jobId',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  void _showJobDetails(SlurmJob job) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Job Details: ${job.jobId}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Job ID', job.jobId),
              _buildDetailRow('Name', job.name),
              _buildDetailRow('User', job.user),
              _buildDetailRow('State', SlurmJob.getStateName(job.state)),
              _buildDetailRow('Time', job.time),
              _buildDetailRow('Nodes', job.nodes),
              _buildDetailRow('Node List', job.nodeList),
              if (job.partition != null) _buildDetailRow('Partition', job.partition!),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _navigateToSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
  }
}