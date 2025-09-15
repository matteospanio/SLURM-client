import 'dart:async';
import '../models/connection.dart';

/// Stub SSH service - should not be used
class SshService {
  SshConnection? _currentConnection;

  bool get isConnected => false;
  SshConnection? get currentConnection => _currentConnection;

  Future<bool> connect(SshConnection connection, {String? password}) async {
    throw UnsupportedError('SSH service not available on this platform');
  }

  Future<void> disconnect() async {}

  Future<String> executeCommand(String command) async {
    throw UnsupportedError('SSH service not available on this platform');
  }

  Future<CommandResult> executeCommandWithDetails(String command) async {
    throw UnsupportedError('SSH service not available on this platform');
  }

  Future<bool> testConnection(SshConnection connection, {String? password}) async {
    return false;
  }

  void cachePassword(String connectionString, String password) {}
  void clearPassword(String connectionString) {}
  void clearAllPasswords() {}

  ConnectionStatus getConnectionStatus() => ConnectionStatus.disconnected;

  Future<void> dispose() async {}
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