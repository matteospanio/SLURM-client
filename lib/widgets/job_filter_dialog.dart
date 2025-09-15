import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/job_provider.dart';
import '../models/settings.dart';

class JobFilterDialog extends StatefulWidget {
  const JobFilterDialog({super.key});

  @override
  State<JobFilterDialog> createState() => _JobFilterDialogState();
}

class _JobFilterDialogState extends State<JobFilterDialog> {
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _nodeController = TextEditingController();
  String? _selectedState;
  String? _selectedPartition;

  @override
  void initState() {
    super.initState();
    final jobProvider = context.read<JobProvider>();
    final currentFilter = jobProvider.filter;
    
    _userController.text = currentFilter.user ?? '';
    _nameController.text = currentFilter.name ?? '';
    _nodeController.text = currentFilter.node ?? '';
    _selectedState = currentFilter.state;
    _selectedPartition = currentFilter.partition;
  }

  @override
  void dispose() {
    _userController.dispose();
    _nameController.dispose();
    _nodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 400,
        constraints: const BoxConstraints(maxHeight: 500),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filter Jobs',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: _buildFilterForm(),
                ),
              ),
              const SizedBox(height: 16),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterForm() {
    return Consumer<JobProvider>(
      builder: (context, jobProvider, child) {
        return Column(
          children: [
            TextField(
              controller: _userController,
              decoration: const InputDecoration(
                labelText: 'User',
                hintText: 'Filter by username',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Job Name',
                hintText: 'Filter by job name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.work),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedState,
              decoration: const InputDecoration(
                labelText: 'Job State',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.info),
              ),
              hint: const Text('Select job state'),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('All States'),
                ),
                ...jobProvider.uniqueStates.map((state) => DropdownMenuItem<String>(
                  value: state,
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _getStateColor(state),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(state),
                    ],
                  ),
                )),
              ],
              onChanged: (String? value) {
                setState(() {
                  _selectedState = value;
                });
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedPartition,
              decoration: const InputDecoration(
                labelText: 'Partition',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              hint: const Text('Select partition'),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('All Partitions'),
                ),
                ...jobProvider.uniquePartitions.map((partition) => DropdownMenuItem<String>(
                  value: partition,
                  child: Text(partition),
                )),
              ],
              onChanged: (String? value) {
                setState(() {
                  _selectedPartition = value;
                });
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nodeController,
              decoration: const InputDecoration(
                labelText: 'Node',
                hintText: 'Filter by node name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.computer),
              ),
            ),
            const SizedBox(height: 24),
            _buildFilterSummary(),
          ],
        );
      },
    );
  }

  Widget _buildFilterSummary() {
    final hasFilters = _userController.text.isNotEmpty ||
        _nameController.text.isNotEmpty ||
        _selectedState != null ||
        _selectedPartition != null ||
        _nodeController.text.isNotEmpty;

    if (!hasFilters) {
      return const SizedBox.shrink();
    }

    return Card(
      color: Theme.of(context).colorScheme.surfaceVariant,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Active Filters:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                if (_userController.text.isNotEmpty)
                  _buildFilterChip('User: ${_userController.text}'),
                if (_nameController.text.isNotEmpty)
                  _buildFilterChip('Name: ${_nameController.text}'),
                if (_selectedState != null)
                  _buildFilterChip('State: $_selectedState'),
                if (_selectedPartition != null)
                  _buildFilterChip('Partition: $_selectedPartition'),
                if (_nodeController.text.isNotEmpty)
                  _buildFilterChip('Node: ${_nodeController.text}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    return Chip(
      label: Text(
        label,
        style: const TextStyle(fontSize: 12),
      ),
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextButton.icon(
          onPressed: _clearFilters,
          icon: const Icon(Icons.clear),
          label: const Text('Clear All'),
        ),
        Row(
          children: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _applyFilters,
              child: const Text('Apply'),
            ),
          ],
        ),
      ],
    );
  }

  void _clearFilters() {
    setState(() {
      _userController.clear();
      _nameController.clear();
      _nodeController.clear();
      _selectedState = null;
      _selectedPartition = null;
    });
  }

  void _applyFilters() {
    final filter = JobFilter(
      user: _userController.text.isEmpty ? null : _userController.text,
      name: _nameController.text.isEmpty ? null : _nameController.text,
      state: _selectedState,
      partition: _selectedPartition,
      node: _nodeController.text.isEmpty ? null : _nodeController.text,
    );

    final jobProvider = context.read<JobProvider>();
    jobProvider.applyFilter(filter);

    Navigator.of(context).pop();

    // Show feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          filter.isEmpty 
              ? 'Filters cleared' 
              : 'Filters applied - ${jobProvider.filteredJobsCount} jobs match',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Color _getStateColor(String state) {
    switch (state.toLowerCase()) {
      case 'running':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'completing':
        return Colors.blue;
      case 'completed':
        return Colors.grey;
      case 'failed':
        return Colors.red;
      case 'cancelled':
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }
}