import 'dart:async';
import '../models/connection.dart';

/// Web-compatible SSH service that provides a placeholder implementation
/// for web platform where native SSH is not supported
class SshService {
  SshConnection? _currentConnection;

  bool get isConnected => false; // Always false on web
  SshConnection? get currentConnection => _currentConnection;

  /// Connect to SSH server - not supported on web
  Future<bool> connect(SshConnection connection, {String? password}) async {
    _currentConnection = connection;
    throw Exception(
      'SSH connections are not supported on web platform. '
      'This feature is only available in the desktop version of the app.',
    );
  }

  /// Disconnect from the SSH server
  Future<void> disconnect() async {
    _currentConnection = null;
  }

  /// Execute a command on the remote server - not supported on web
  Future<String> executeCommand(String command) async {
    throw Exception(
      'SSH command execution is not supported on web platform. '
      'Please use the desktop version to connect to SLURM clusters.',
    );
  }

  /// Execute command and return both stdout and stderr
  Future<CommandResult> executeCommandWithDetails(String command) async {
    return CommandResult(
      stdout: '',
      stderr: 'SSH command execution is not supported on web platform',
      exitCode: 1,
      command: command,
    );
  }

  /// Test connection to the server - always returns false on web
  Future<bool> testConnection(
    SshConnection connection, {
    String? password,
  }) async {
    return false;
  }

  /// Cache password for a connection (no-op on web)
  void cachePassword(String connectionString, String password) {
    // No-op on web
  }

  /// Clear cached password for a connection (no-op on web)
  void clearPassword(String connectionString) {
    // No-op on web
  }

  /// Clear all cached passwords (no-op on web)
  void clearAllPasswords() {
    // No-op on web
  }

  /// Get the current connection status
  ConnectionStatus getConnectionStatus() {
    return ConnectionStatus.disconnected;
  }

  /// Dispose the service and cleanup resources
  Future<void> dispose() async {
    await disconnect();
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
