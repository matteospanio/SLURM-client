import 'dart:async';
import '../models/connection.dart';

/// Base abstract class for SSH service implementations
abstract class BaseSSHService {
  SshConnection? _currentConnection;

  /// Whether the service is currently connected
  bool get isConnected;
  
  /// Get the current connection if any
  SshConnection? get currentConnection => _currentConnection;

  /// Connect to SSH server using the provided connection details
  Future<bool> connect(SshConnection connection, {String? password});

  /// Disconnect from the SSH server
  Future<void> disconnect();

  /// Execute a command on the remote server
  Future<String> executeCommand(String command);

  /// Execute command and return both stdout and stderr
  Future<CommandResult> executeCommandWithDetails(String command);

  /// Test connection to the server without maintaining the connection
  Future<bool> testConnection(SshConnection connection, {String? password});

  /// Cache password for a connection
  void cachePassword(String connectionString, String password);

  /// Clear cached password for a connection
  void clearPassword(String connectionString);

  /// Clear all cached passwords
  void clearAllPasswords();

  /// Get the current connection status
  ConnectionStatus getConnectionStatus();

  /// Dispose the service and cleanup resources
  Future<void> dispose();

  /// Protected method to update current connection (used by implementations)
  void setCurrentConnection(SshConnection? connection) {
    _currentConnection = connection;
  }
}

/// Command execution result
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