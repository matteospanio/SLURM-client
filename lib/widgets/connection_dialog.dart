import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/connection_provider.dart';
import '../models/connection.dart';

class ConnectionDialog extends StatefulWidget {
  final SshConnection? initialConnection;

  const ConnectionDialog({super.key, this.initialConnection});

  @override
  State<ConnectionDialog> createState() => _ConnectionDialogState();
}

class _ConnectionDialogState extends State<ConnectionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _hostnameController = TextEditingController();
  final _portController = TextEditingController(text: '22');
  final _usernameController = TextEditingController();
  final _privateKeyController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _usePassword = false;
  bool _isDefault = false;
  bool _isConnecting = false;
  String? _selectedConnection;

  @override
  void initState() {
    super.initState();
    if (widget.initialConnection != null) {
      _populateFields(widget.initialConnection!);
    }
  }

  void _populateFields(SshConnection connection) {
    _nameController.text = connection.name;
    _hostnameController.text = connection.hostname;
    _portController.text = connection.port.toString();
    _usernameController.text = connection.username;
    _privateKeyController.text = connection.privateKeyPath ?? '';
    _usePassword = connection.usePassword;
    _isDefault = connection.isDefault;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _hostnameController.dispose();
    _portController.dispose();
    _usernameController.dispose();
    _privateKeyController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 500,
        constraints: const BoxConstraints(maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SSH Connection',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildConnectionSelector(),
                      const SizedBox(height: 16),
                      _buildConnectionForm(),
                    ],
                  ),
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

  Widget _buildConnectionSelector() {
    return Consumer<ConnectionProvider>(
      builder: (context, connectionProvider, child) {
        final connections = connectionProvider.savedConnections;
        
        if (connections.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Saved Connections:'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedConnection,
              decoration: const InputDecoration(
                labelText: 'Select Connection',
                border: OutlineInputBorder(),
              ),
              hint: const Text('Choose a saved connection'),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('New Connection'),
                ),
                ...connections.map((conn) => DropdownMenuItem<String>(
                  value: conn.name,
                  child: Text('${conn.name} (${conn.username}@${conn.hostname})'),
                )),
              ],
              onChanged: (String? value) {
                setState(() {
                  _selectedConnection = value;
                  if (value != null) {
                    final connection = connections.firstWhere((conn) => conn.name == value);
                    _populateFields(connection);
                  } else {
                    _clearFields();
                  }
                });
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildConnectionForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Connection Name',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a connection name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _hostnameController,
            decoration: const InputDecoration(
              labelText: 'Hostname',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a hostname';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a username';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _portController,
                  decoration: const InputDecoration(
                    labelText: 'Port',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Required';
                    }
                    final port = int.tryParse(value);
                    if (port == null || port <= 0 || port > 65535) {
                      return 'Invalid port';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Use Password Authentication'),
            subtitle: Text(_usePassword 
                ? 'Password will be required for connection'
                : 'SSH key authentication will be used'),
            value: _usePassword,
            onChanged: (bool value) {
              setState(() {
                _usePassword = value;
              });
            },
          ),
          if (!_usePassword) ...[
            const SizedBox(height: 16),
            TextFormField(
              controller: _privateKeyController,
              decoration: const InputDecoration(
                labelText: 'Private Key Path (optional)',
                hintText: 'Leave empty to use default SSH keys',
                border: OutlineInputBorder(),
              ),
            ),
          ],
          if (_usePassword) ...[
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              validator: _usePassword ? (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a password';
                }
                return null;
              } : null,
            ),
          ],
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Set as Default Connection'),
            value: _isDefault,
            onChanged: (bool value) {
              setState(() {
                _isDefault = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: _isConnecting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: _isConnecting ? null : _testConnection,
          child: const Text('Test'),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: _isConnecting ? null : _saveAndConnect,
          child: _isConnecting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Connect'),
        ),
      ],
    );
  }

  void _clearFields() {
    _nameController.clear();
    _hostnameController.clear();
    _portController.text = '22';
    _usernameController.clear();
    _privateKeyController.clear();
    _passwordController.clear();
    _usePassword = false;
    _isDefault = false;
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isConnecting = true;
    });

    final connection = _createConnection();
    final connectionProvider = context.read<ConnectionProvider>();

    try {
      final success = await connectionProvider.testConnection(
        connection,
        password: _usePassword ? _passwordController.text : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Connection successful!' : 'Connection failed'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connection test failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isConnecting = false;
        });
      }
    }
  }

  Future<void> _saveAndConnect() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isConnecting = true;
    });

    final connection = _createConnection();
    final connectionProvider = context.read<ConnectionProvider>();

    try {
      // Save the connection
      await connectionProvider.saveConnection(connection);

      // Attempt to connect
      final success = await connectionProvider.connect(
        connection,
        password: _usePassword ? _passwordController.text : null,
      );

      if (mounted) {
        if (success) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Connected successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Connection failed: ${connectionProvider.error}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isConnecting = false;
        });
      }
    }
  }

  SshConnection _createConnection() {
    return SshConnection(
      name: _nameController.text,
      hostname: _hostnameController.text,
      port: int.parse(_portController.text),
      username: _usernameController.text,
      privateKeyPath: _privateKeyController.text.isEmpty ? null : _privateKeyController.text,
      usePassword: _usePassword,
      isDefault: _isDefault,
    );
  }
}