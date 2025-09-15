import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/connection_provider.dart';
import '../models/settings.dart' as models;
import '../widgets/connection_dialog.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _refreshIntervalController = TextEditingController();
  final TextEditingController _maxJobsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsProvider>().settings;
    _refreshIntervalController.text = settings.refreshInterval.toString();
    _maxJobsController.text = settings.maxJobsToShow.toString();
  }

  @override
  void dispose() {
    _refreshIntervalController.dispose();
    _maxJobsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) {
          final settings = settingsProvider.settings;
          
          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildSection(
                title: 'Auto-Refresh',
                children: [
                  SwitchListTile(
                    title: const Text('Enable Auto-Refresh'),
                    subtitle: const Text('Automatically refresh job list'),
                    value: settings.autoRefresh,
                    onChanged: (bool value) {
                      settingsProvider.toggleAutoRefresh(value);
                    },
                  ),
                  ListTile(
                    title: const Text('Refresh Interval (seconds)'),
                    subtitle: TextField(
                      controller: _refreshIntervalController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Enter refresh interval',
                      ),
                      onSubmitted: (value) {
                        final interval = int.tryParse(value);
                        if (interval != null && interval > 0) {
                          settingsProvider.updateRefreshInterval(interval);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSection(
                title: 'Display',
                children: [
                  ListTile(
                    title: const Text('Theme'),
                    subtitle: DropdownButton<models.ThemeMode>(
                      value: settings.themeMode,
                      onChanged: (models.ThemeMode? newValue) {
                        if (newValue != null) {
                          settingsProvider.updateThemeMode(newValue);
                        }
                      },
                      items: models.ThemeMode.values.map((mode) {
                        return DropdownMenuItem<models.ThemeMode>(
                          value: mode,
                          child: Text(_getThemeModeLabel(mode)),
                        );
                      }).toList(),
                    ),
                  ),
                  ListTile(
                    title: const Text('Max Jobs to Show'),
                    subtitle: TextField(
                      controller: _maxJobsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Enter maximum number of jobs',
                      ),
                      onSubmitted: (value) {
                        final maxJobs = int.tryParse(value);
                        if (maxJobs != null && maxJobs > 0) {
                          settingsProvider.updateMaxJobsToShow(maxJobs);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSection(
                title: 'System Integration',
                children: [
                  SwitchListTile(
                    title: const Text('Show System Tray'),
                    subtitle: const Text('Display icon in system tray'),
                    value: settings.showSystemTray,
                    onChanged: (bool value) {
                      settingsProvider.toggleSystemTray(value);
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Start Minimized'),
                    subtitle: const Text('Start application in system tray'),
                    value: settings.startMinimized,
                    onChanged: (bool value) {
                      settingsProvider.toggleStartMinimized(value);
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Show Notifications'),
                    subtitle: const Text('Show desktop notifications for job changes'),
                    value: settings.showNotifications,
                    onChanged: (bool value) {
                      settingsProvider.toggleNotifications(value);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSection(
                title: 'Connections',
                children: [
                  Consumer<ConnectionProvider>(
                    builder: (context, connectionProvider, child) {
                      return Column(
                        children: [
                          ListTile(
                            title: const Text('Saved Connections'),
                            subtitle: Text('${connectionProvider.savedConnections.length} connections saved'),
                            trailing: IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () => _showConnectionDialog(),
                            ),
                          ),
                          ...connectionProvider.savedConnections.map((connection) {
                            return ListTile(
                              title: Text(connection.name),
                              subtitle: Text(connection.connectionString),
                              leading: connection.isDefault 
                                  ? const Icon(Icons.star, color: Colors.amber)
                                  : const Icon(Icons.computer),
                              trailing: PopupMenuButton(
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: const Text('Edit'),
                                  ),
                                  PopupMenuItem(
                                    value: 'default',
                                    child: Text(connection.isDefault ? 'Remove Default' : 'Set as Default'),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: const Text('Delete'),
                                  ),
                                ],
                                onSelected: (value) => _handleConnectionAction(value, connection.name),
                              ),
                            );
                          }).toList(),
                        ],
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSection(
                title: 'Data Management',
                children: [
                  ListTile(
                    title: const Text('Export Settings'),
                    subtitle: const Text('Export all settings and connections'),
                    trailing: const Icon(Icons.download),
                    onTap: () => _exportSettings(),
                  ),
                  ListTile(
                    title: const Text('Import Settings'),
                    subtitle: const Text('Import settings from file'),
                    trailing: const Icon(Icons.upload),
                    onTap: () => _importSettings(),
                  ),
                  const Divider(),
                  ListTile(
                    title: const Text('Reset to Defaults'),
                    subtitle: const Text('Reset all settings to default values'),
                    trailing: const Icon(Icons.restore, color: Colors.red),
                    onTap: () => _resetSettings(),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSection({required String title, required List<Widget> children}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  String _getThemeModeLabel(models.ThemeMode mode) {
    switch (mode) {
      case models.ThemeMode.light:
        return 'Light';
      case models.ThemeMode.dark:
        return 'Dark';
      case models.ThemeMode.system:
        return 'System';
    }
  }

  void _showConnectionDialog() {
    showDialog(
      context: context,
      builder: (context) => const ConnectionDialog(),
    );
  }

  void _handleConnectionAction(dynamic action, String connectionName) {
    final connectionProvider = context.read<ConnectionProvider>();
    
    switch (action) {
      case 'edit':
        final connection = connectionProvider.getConnectionByName(connectionName);
        if (connection != null) {
          showDialog(
            context: context,
            builder: (context) => ConnectionDialog(initialConnection: connection),
          );
        }
        break;
      case 'default':
        connectionProvider.setDefaultConnection(connectionName);
        break;
      case 'delete':
        _confirmDeleteConnection(connectionName);
        break;
    }
  }

  void _confirmDeleteConnection(String connectionName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Connection'),
        content: Text('Are you sure you want to delete the connection "$connectionName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<ConnectionProvider>().deleteConnection(connectionName);
              Navigator.of(context).pop();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _exportSettings() {
    // This would implement actual file export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export settings functionality not yet implemented')),
    );
  }

  void _importSettings() {
    // This would implement actual file import functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Import settings functionality not yet implemented')),
    );
  }

  void _resetSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text('Are you sure you want to reset all settings to their default values?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<SettingsProvider>().resetToDefaults();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings reset to defaults')),
              );
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}