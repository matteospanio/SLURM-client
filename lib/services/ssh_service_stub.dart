import 'dart:async';
import '../models/connection.dart';
import 'base_ssh_service.dart';

/// Stub SSH service - fallback implementation that should not be used
class StubSSHService extends BaseSSHService {
  @override
  bool get isConnected => false;

  @override
  Future<bool> connect(SshConnection connection, {String? password}) async {
    throw UnsupportedError('SSH service not available on this platform');
  }

  @override
  Future<void> disconnect() async {}

  @override
  Future<String> executeCommand(String command) async {
    throw UnsupportedError('SSH service not available on this platform');
  }

  @override
  Future<CommandResult> executeCommandWithDetails(String command) async {
    throw UnsupportedError('SSH service not available on this platform');
  }

  @override
  Future<bool> testConnection(
    SshConnection connection, {
    String? password,
  }) async {
    return false;
  }

  @override
  void cachePassword(String connectionString, String password) {}
  
  @override
  void clearPassword(String connectionString) {}
  
  @override
  void clearAllPasswords() {}

  @override
  ConnectionStatus getConnectionStatus() => ConnectionStatus.disconnected;

  @override
  Future<void> dispose() async {}
}
