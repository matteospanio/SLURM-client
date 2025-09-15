import 'dart:async';
import 'dart:io';
import 'package:ssh2/ssh2.dart';
import '../models/connection.dart';

class SshService {
  SSHClient? _client;
  SshConnection? _currentConnection;
  final Map<String, String> _passwordCache = {};

  bool get isConnected => _client != null;
  SshConnection? get currentConnection => _currentConnection;

  /// Connect to SSH server using the provided connection details
  Future<bool> connect(SshConnection connection, {String? password}) async {
    try {
      await disconnect(); // Disconnect any existing connection

      _client = SSHClient(
        host: connection.hostname,
        port: connection.port,
        username: connection.username,
      );

      if (connection.usePassword) {
        // Use password authentication
        final pwd = password ?? _passwordCache[connection.connectionString];
        if (pwd == null) {
          throw Exception('Password required for connection');
        }
        await _client!.connect(password: pwd);
        _passwordCache[connection.connectionString] = pwd; // Cache password
      } else {
        // Use key-based authentication
        if (connection.privateKeyPath != null) {
          final keyFile = File(connection.privateKeyPath!);
          if (!keyFile.existsSync()) {
            throw Exception(
              'Private key file not found: ${connection.privateKeyPath}',
            );
          }
          final privateKey = await keyFile.readAsString();
          await _client!.connect(privateKey: privateKey);
        } else {
          // Try default SSH keys
          final homeDir =
              Platform.environment['HOME'] ??
              Platform.environment['USERPROFILE'];
          if (homeDir != null) {
            final defaultKeyPaths = [
              '$homeDir/.ssh/id_rsa',
              '$homeDir/.ssh/id_ed25519',
              '$homeDir/.ssh/id_ecdsa',
            ];

            String? privateKey;
            for (final keyPath in defaultKeyPaths) {
              final keyFile = File(keyPath);
              if (keyFile.existsSync()) {
                privateKey = await keyFile.readAsString();
                break;
              }
            }

            if (privateKey != null) {
              await _client!.connect(privateKey: privateKey);
            } else {
              throw Exception(
                'No SSH key found. Please specify a private key path.',
              );
            }
          } else {
            throw Exception('Cannot determine home directory for SSH keys');
          }
        }
      }

      _currentConnection = connection;
      return true;
    } catch (e) {
      await disconnect();
      throw Exception('Failed to connect to SSH server: $e');
    }
  }

  /// Disconnect from the SSH server
  Future<void> disconnect() async {
    try {
      await _client?.disconnect();
    } catch (e) {
      // Ignore disconnect errors
    }
    _client = null;
    _currentConnection = null;
  }

  /// Execute a command on the remote server
  Future<String> executeCommand(String command) async {
    if (_client == null) {
      throw Exception('Not connected to SSH server');
    }

    try {
      final result = await _client!.execute(command);
      return result ?? '';
    } catch (e) {
      throw Exception('Failed to execute command "$command": $e');
    }
  }

  /// Execute command and return both stdout and stderr
  Future<CommandResult> executeCommandWithDetails(String command) async {
    if (_client == null) {
      throw Exception('Not connected to SSH server');
    }

    try {
      final result = await _client!.execute(command);
      return CommandResult(
        stdout: result ?? '',
        stderr: '',
        exitCode: 0,
        command: command,
      );
    } catch (e) {
      return CommandResult(
        stdout: '',
        stderr: e.toString(),
        exitCode: 1,
        command: command,
      );
    }
  }

  /// Test connection to the server
  Future<bool> testConnection(
    SshConnection connection, {
    String? password,
  }) async {
    try {
      final passwordOrKey = connection.usePassword
          ? (password ?? _passwordCache[connection.connectionString])
          : (connection.privateKeyPath != null
                ? await File(connection.privateKeyPath!).readAsString()
                : null);

      if (passwordOrKey == null) return false;

      final tempClient = SSHClient(
        host: connection.hostname,
        port: connection.port,
        username: connection.username,
        passwordOrKey: passwordOrKey,
      );

      // Test basic command
      await tempClient.execute('echo test');
      await tempClient.disconnect();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Cache password for a connection
  void cachePassword(String connectionString, String password) {
    _passwordCache[connectionString] = password;
  }

  /// Clear cached password for a connection
  void clearPassword(String connectionString) {
    _passwordCache.remove(connectionString);
  }

  /// Clear all cached passwords
  void clearAllPasswords() {
    _passwordCache.clear();
  }

  /// Get the current connection status
  ConnectionStatus getConnectionStatus() {
    if (_client == null) return ConnectionStatus.disconnected;
    // Note: ssh2 package doesn't provide connection status check
    // We assume connected if client exists
    return ConnectionStatus.connected;
  }

  /// Dispose the service and cleanup resources
  Future<void> dispose() async {
    await disconnect();
    clearAllPasswords();
  }
}

class CommandResult {
  final String stdout;
  final String stderr;
  final int exitCode;
  final String command;

  const CommandResult({
    required this.stdout,
    required this.stderr,
    required this.exitCode,
    required this.command,
  });

  bool get isSuccess => exitCode == 0;
  bool get hasError => exitCode != 0 || stderr.isNotEmpty;

  @override
  String toString() {
    return 'CommandResult{command: $command, exitCode: $exitCode, stdout: ${stdout.length} chars, stderr: ${stderr.length} chars}';
  }
}
