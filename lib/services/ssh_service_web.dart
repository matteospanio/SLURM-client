import 'dart:async';
import '../models/connection.dart';
import 'base_ssh_service.dart';

/// Web-compatible SSH service that provides a placeholder implementation
/// for web platform where native SSH is not supported
class WebSSHService extends BaseSSHService {
  @override
  bool get isConnected => false; // Always false on web

  /// Connect to SSH server - not supported on web
  @override
  Future<bool> connect(SshConnection connection, {String? password}) async {
    setCurrentConnection(connection);
    throw Exception(
      'SSH connections are not supported on web platform. '
      'This feature is only available in the desktop version of the app.',
    );
  }

  /// Disconnect from the SSH server
  @override
  Future<void> disconnect() async {
    setCurrentConnection(null);
  }

  /// Execute a command on the remote server - not supported on web
  @override
  Future<String> executeCommand(String command) async {
    throw Exception(
      'SSH command execution is not supported on web platform. '
      'Please use the desktop version to connect to SLURM clusters.',
    );
  }

  /// Execute command and return both stdout and stderr
  @override
  Future<CommandResult> executeCommandWithDetails(String command) async {
    return CommandResult(
      stdout: '',
      stderr: 'SSH command execution is not supported on web platform',
      exitCode: 1,
      command: command,
    );
  }

  /// Test connection to the server - always returns false on web
  @override
  Future<bool> testConnection(
    SshConnection connection, {
    String? password,
  }) async {
    return false;
  }

  /// Cache password for a connection (no-op on web)
  @override
  void cachePassword(String connectionString, String password) {
    // No-op on web
  }

  /// Clear cached password for a connection (no-op on web)
  @override
  void clearPassword(String connectionString) {
    // No-op on web
  }

  /// Clear all cached passwords (no-op on web)
  @override
  void clearAllPasswords() {
    // No-op on web
  }

  /// Get the current connection status
  @override
  ConnectionStatus getConnectionStatus() {
    return ConnectionStatus.disconnected;
  }

  /// Dispose the service and cleanup resources
  @override
  Future<void> dispose() async {
    await disconnect();
  }
}
