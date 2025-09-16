import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:ssh2/ssh2.dart';
import '../models/connection.dart';
import 'base_ssh_service.dart';

/// Desktop SSH service implementation using the ssh2 package
class DesktopSSHService extends BaseSSHService {
  SSHClient? _client;
  final Map<String, String> _passwordCache = {};

  @override
  bool get isConnected => _client != null;

  /// Connect to SSH server using the provided connection details
  @override
  Future<bool> connect(SshConnection connection, {String? password}) async {
    try {
      await disconnect(); // Disconnect any existing connection

      final passwordOrKey = await _getPasswordOrKey(connection, password);
      
      _client = SSHClient(
        host: connection.hostname,
        port: connection.port,
        username: connection.username,
        passwordOrKey: passwordOrKey,
      );

      await _client!.connect();
      setCurrentConnection(connection);
      
      // Cache password if provided
      if (password != null && connection.usePassword) {
        _passwordCache[connection.connectionString] = password;
      }
      
      debugPrint('SSH connection established successfully to ${connection.connectionString}');
      return true;
    } catch (e) {
      debugPrint('SSH connection failed: $e');
      await disconnect();
      rethrow; // Re-throw to preserve the original error for proper error handling
    }
  }

  /// Disconnect from the SSH server
  @override
  Future<void> disconnect() async {
    try {
      await _client?.disconnect();
    } catch (e) {
      debugPrint('Error during SSH disconnect: $e');
      // Ignore disconnect errors
    }
    _client = null;
    setCurrentConnection(null);
  }

  /// Execute a command on the remote server
  @override
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
  @override
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
  @override
  Future<bool> testConnection(
    SshConnection connection, {
    String? password,
  }) async {
    SSHClient? tempClient;
    try {
      final passwordOrKey = await _getPasswordOrKey(connection, password);

      tempClient = SSHClient(
        host: connection.hostname,
        port: connection.port,
        username: connection.username,
        passwordOrKey: passwordOrKey,
      );

      await tempClient.connect();
      
      // Test basic command
      final result = await tempClient.execute('echo test');
      if (result == null || !result.contains('test')) {
        throw Exception('Failed to execute test command');
      }
      
      await tempClient.disconnect();
      return true;
    } catch (e) {
      try {
        await tempClient?.disconnect();
      } catch (_) {
        // Ignore disconnect errors during cleanup
      }
      debugPrint('SSH test connection failed: $e');
      rethrow; // Re-throw to preserve the original error
    }
  }

  /// Cache password for a connection
  @override
  void cachePassword(String connectionString, String password) {
    _passwordCache[connectionString] = password;
  }

  /// Clear cached password for a connection
  @override
  void clearPassword(String connectionString) {
    _passwordCache.remove(connectionString);
  }

  /// Clear all cached passwords
  @override
  void clearAllPasswords() {
    _passwordCache.clear();
  }

  /// Get the current connection status
  @override
  ConnectionStatus getConnectionStatus() {
    if (_client == null) return ConnectionStatus.disconnected;
    // Note: ssh2 package doesn't provide connection status check
    // We assume connected if client exists
    return ConnectionStatus.connected;
  }

  /// Dispose the service and cleanup resources
  @override
  Future<void> dispose() async {
    await disconnect();
    clearAllPasswords();
  }

  /// Get password or key for authentication
  Future<String> _getPasswordOrKey(SshConnection connection, String? password) async {
    if (connection.usePassword) {
      // Use password authentication
      final pwd = password ?? _passwordCache[connection.connectionString];
      if (pwd == null) {
        throw Exception('Password required for connection');
      }
      return pwd;
    } else {
      // Use key-based authentication
      if (connection.privateKeyPath != null) {
        final keyFile = File(connection.privateKeyPath!);
        if (!keyFile.existsSync()) {
          throw Exception(
            'Private key file not found: ${connection.privateKeyPath}',
          );
        }
        return await keyFile.readAsString();
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

          for (final keyPath in defaultKeyPaths) {
            final keyFile = File(keyPath);
            if (keyFile.existsSync()) {
              return await keyFile.readAsString();
            }
          }

          throw Exception(
            'No SSH key found. Please specify a private key path.',
          );
        } else {
          throw Exception('Cannot determine home directory for SSH keys');
        }
      }
    }
  }
}
