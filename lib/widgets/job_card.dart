import 'package:flutter/material.dart';
import '../models/job.dart';

class JobCard extends StatelessWidget {
  final SlurmJob job;
  final VoidCallback? onCancel;
  final VoidCallback? onDetails;

  const JobCard({
    super.key,
    required this.job,
    this.onCancel,
    this.onDetails,
  });

  @override
  Widget build(BuildContext context) {
    final stateColor = _getStateColor(job.state);
    final stateName = SlurmJob.getStateName(job.state);

    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: stateColor,
          child: Text(
            job.state,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        title: Text(
          job.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text('Job ID: ${job.jobId} • User: ${job.user}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: stateColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: stateColor, width: 1),
              ),
              child: Text(
                stateName,
                style: TextStyle(
                  color: stateColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (job.state.toLowerCase() == 'r' || job.state.toLowerCase() == 'pd')
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (String value) {
                  switch (value) {
                    case 'cancel':
                      onCancel?.call();
                      break;
                    case 'details':
                      onDetails?.call();
                      break;
                  }
                },
                itemBuilder: (BuildContext context) => [
                  const PopupMenuItem(
                    value: 'details',
                    child: Row(
                      children: [
                        Icon(Icons.info),
                        SizedBox(width: 8),
                        Text('Details'),
                      ],
                    ),
                  ),
                  if (job.state.toLowerCase() == 'r' || job.state.toLowerCase() == 'pd')
                    const PopupMenuItem(
                      value: 'cancel',
                      child: Row(
                        children: [
                          Icon(Icons.cancel, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Cancel Job'),
                        ],
                      ),
                    ),
                ],
              )
            else
              IconButton(
                icon: const Icon(Icons.info),
                onPressed: onDetails,
                tooltip: 'Job details',
              ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildInfoRow(Icons.schedule, 'Runtime', job.time),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.computer, 'Nodes', '${job.nodes} (${job.nodeList})'),
                if (job.partition != null) ...[
                  const SizedBox(height: 8),
                  _buildInfoRow(Icons.category, 'Partition', job.partition!),
                ],
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton.icon(
                      onPressed: onDetails,
                      icon: const Icon(Icons.info),
                      label: const Text('Details'),
                    ),
                    if (job.state.toLowerCase() == 'r' || job.state.toLowerCase() == 'pd')
                      TextButton.icon(
                        onPressed: onCancel,
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        label: const Text(
                          'Cancel',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        Expanded(
          child: Text(
            value,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Color _getStateColor(String state) {
    switch (state.toLowerCase()) {
      case 'r':
      case 'running':
        return Colors.green;
      case 'pd':
      case 'pending':
        return Colors.orange;
      case 'cg':
      case 'completing':
        return Colors.blue;
      case 'cd':
      case 'completed':
        return Colors.grey;
      case 'f':
      case 'failed':
        return Colors.red;
      case 'ca':
      case 'cancelled':
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }
}