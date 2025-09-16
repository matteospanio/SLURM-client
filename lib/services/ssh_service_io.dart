import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dartssh2/dartssh2.dart';
import '../models/connection.dart';
import 'base_ssh_service.dart';

/// Desktop SSH service implementation using the dartssh2 package
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

      // Create SSH socket connection
      final socket = await SSHSocket.connect(
        connection.hostname,
        connection.port,
      );

      // Create SSH client
      if (connection.usePassword) {
        // Password authentication
        final pwd = password ?? _passwordCache[connection.connectionString];
        if (pwd == null) {
          throw Exception('Password required for connection');
        }

        _client = SSHClient(
          socket,
          username: connection.username,
          onPasswordRequest: () => pwd,
        );
      } else {
        // Key-based authentication
        final privateKey = await _getPrivateKey(connection);

        _client = SSHClient(
          socket,
          username: connection.username,
          identities: [privateKey],
        );
      }

      setCurrentConnection(connection);

      // Cache password if provided
      if (password != null && connection.usePassword) {
        _passwordCache[connection.connectionString] = password;
      }

      debugPrint(
        'SSH connection established successfully to ${connection.connectionString}',
      );
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
      _client?.close();
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
      final session = await _client!.execute(command);
      await session.done;

      // Read stdout
      final stdout = await session.stdout.map(utf8.decode).join();
      return stdout;
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
      final session = await _client!.execute(command);

      // Read both stdout and stderr concurrently
      final stdoutFuture = session.stdout.map(utf8.decode).join();
      final stderrFuture = session.stderr.map(utf8.decode).join();

      await session.done;

      final stdout = await stdoutFuture;
      final stderr = await stderrFuture;
      final exitCode = session.exitCode ?? 0;

      return CommandResult(
        stdout: stdout,
        stderr: stderr,
        exitCode: exitCode,
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
      // Create SSH socket connection
      final socket = await SSHSocket.connect(
        connection.hostname,
        connection.port,
      );

      // Create SSH client for testing
      if (connection.usePassword) {
        // Password authentication
        final pwd = password ?? _passwordCache[connection.connectionString];
        if (pwd == null) {
          throw Exception('Password required for connection');
        }

        tempClient = SSHClient(
          socket,
          username: connection.username,
          onPasswordRequest: () => pwd,
        );
      } else {
        // Key-based authentication
        final privateKey = await _getPrivateKey(connection);

        tempClient = SSHClient(
          socket,
          username: connection.username,
          identities: [privateKey],
        );
      }

      // Test basic command
      final session = await tempClient.execute('echo test');
      await session.done;
      final result = await session.stdout.map(utf8.decode).join();

      if (!result.contains('test')) {
        throw Exception('Failed to execute test command');
      }

      tempClient.close();
      return true;
    } catch (e) {
      try {
        tempClient?.close();
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
    // Note: dartssh2 package doesn't provide direct connection status check
    // We assume connected if client exists
    return ConnectionStatus.connected;
  }

  /// Dispose the service and cleanup resources
  @override
  Future<void> dispose() async {
    await disconnect();
    clearAllPasswords();
  }

  /// Get private key for authentication
  Future<SSHKeyPair> _getPrivateKey(SshConnection connection) async {
    String? keyContent;

    if (connection.privateKeyPath != null) {
      final keyFile = File(connection.privateKeyPath!);
      if (!keyFile.existsSync()) {
        throw Exception(
          'Private key file not found: ${connection.privateKeyPath}',
        );
      }
      keyContent = await keyFile.readAsString();
    } else {
      // Try default SSH keys
      final homeDir =
          Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
      if (homeDir != null) {
        final defaultKeyPaths = [
          '$homeDir/.ssh/id_rsa',
          '$homeDir/.ssh/id_ed25519',
          '$homeDir/.ssh/id_ecdsa',
        ];

        for (final keyPath in defaultKeyPaths) {
          final keyFile = File(keyPath);
          if (keyFile.existsSync()) {
            keyContent = await keyFile.readAsString();
            break;
          }
        }

        if (keyContent == null) {
          throw Exception(
            'No SSH key found. Please specify a private key path.',
          );
        }
      } else {
        throw Exception('Cannot determine home directory for SSH keys');
      }
    }

    // Parse the private key
    try {
      final keyPairs = SSHKeyPair.fromPem(keyContent);
      if (keyPairs.isEmpty) {
        throw Exception('No valid SSH key found in the provided PEM.');
      }
      return keyPairs.first;
    } catch (e) {
      throw Exception('Failed to parse private key: $e');
    }
  }
}
