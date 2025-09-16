import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/connection.dart';
import '../services/base_ssh_service.dart';
import '../services/storage_service.dart';

class ConnectionProvider extends ChangeNotifier {
  final BaseSSHService _sshService;
  final StorageService _storageService;
  
  ConnectionState _connectionState = const ConnectionState();
  List<SshConnection> _savedConnections = [];
  String? _error;

  ConnectionProvider(this._sshService, this._storageService) {
    _loadSavedConnections();
  }

  // Getters
  ConnectionState get connectionState => _connectionState;
  List<SshConnection> get savedConnections => _savedConnections;
  String? get error => _error;
  bool get isConnected => _connectionState.isConnected;
  bool get isConnecting => _connectionState.isConnecting;
  bool get hasError => _connectionState.hasError;
  SshConnection? get currentConnection => _connectionState.connection;

  /// Connect to SSH server
  Future<bool> connect(SshConnection connection, {String? password}) async {
    _setConnectionState(
      _connectionState.copyWith(
        status: ConnectionStatus.connecting,
        connection: connection,
        errorMessage: null,
      ),
    );

    try {
      final success = await _sshService.connect(connection, password: password);
      if (success) {
        _setConnectionState(
          _connectionState.copyWith(
            status: ConnectionStatus.connected,
            lastConnected: DateTime.now(),
            errorMessage: null,
          ),
        );
        
        // Cache password if provided
        if (password != null) {
          _sshService.cachePassword(connection.connectionString, password);
        }
        
        return true;
      } else {
        _setConnectionState(
          _connectionState.copyWith(
            status: ConnectionStatus.error,
            errorMessage: 'Connection failed',
          ),
        );
        return false;
      }
    } catch (e) {
      final errorMessage = e.toString().replaceFirst('Exception: ', '');
      _setConnectionState(
        _connectionState.copyWith(
          status: ConnectionStatus.error,
          errorMessage: errorMessage,
        ),
      );
      return false;
    }
  }

  /// Disconnect from SSH server
  Future<void> disconnect() async {
    try {
      await _sshService.disconnect();
      _setConnectionState(
        _connectionState.copyWith(
          status: ConnectionStatus.disconnected,
          errorMessage: null,
        ),
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Test connection without connecting
  Future<bool> testConnection(SshConnection connection, {String? password}) async {
    try {
      return await _sshService.testConnection(connection, password: password);
    } catch (e) {
      final errorMessage = e.toString().replaceFirst('Exception: ', '');
      _error = errorMessage;
      notifyListeners();
      return false;
    }
  }

  /// Save a new connection
  Future<void> saveConnection(SshConnection connection) async {
    try {
      // Remove existing connection with same name
      _savedConnections.removeWhere((conn) => conn.name == connection.name);
      
      // If this is set as default, remove default from others
      if (connection.isDefault) {
        _savedConnections = _savedConnections
            .map((conn) => conn.copyWith(isDefault: false))
            .toList();
      }
      
      _savedConnections.add(connection);
      await _storageService.saveConnections(_savedConnections);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Update an existing connection
  Future<void> updateConnection(SshConnection connection) async {
    try {
      final index = _savedConnections.indexWhere((conn) => conn.name == connection.name);
      if (index != -1) {
        // If this is set as default, remove default from others
        if (connection.isDefault) {
          _savedConnections = _savedConnections
              .map((conn) => conn.copyWith(isDefault: false))
              .toList();
        }
        
        _savedConnections[index] = connection;
        await _storageService.saveConnections(_savedConnections);
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Delete a saved connection
  Future<void> deleteConnection(String connectionName) async {
    try {
      _savedConnections.removeWhere((conn) => conn.name == connectionName);
      await _storageService.saveConnections(_savedConnections);
      
      // If we're currently connected to this connection, disconnect
      if (_connectionState.connection?.name == connectionName) {
        await disconnect();
      }
      
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Get default connection
  SshConnection? get defaultConnection {
    try {
      return _savedConnections.firstWhere((conn) => conn.isDefault);
    } catch (e) {
      return _savedConnections.isNotEmpty ? _savedConnections.first : null;
    }
  }

  /// Set a connection as default
  Future<void> setDefaultConnection(String connectionName) async {
    try {
      _savedConnections = _savedConnections.map((conn) {
        return conn.copyWith(isDefault: conn.name == connectionName);
      }).toList();
      
      await _storageService.saveConnections(_savedConnections);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Connect to default connection
  Future<bool> connectToDefault({String? password}) async {
    final defaultConn = defaultConnection;
    if (defaultConn != null) {
      return await connect(defaultConn, password: password);
    }
    return false;
  }

  /// Reconnect to current connection
  Future<bool> reconnect({String? password}) async {
    if (_connectionState.connection != null) {
      return await connect(_connectionState.connection!, password: password);
    }
    return false;
  }

  /// Load saved connections from storage
  Future<void> _loadSavedConnections() async {
    try {
      _savedConnections = await _storageService.loadConnections();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading saved connections: $e');
      notifyListeners();
    }
  }

  /// Set connection state and notify listeners
  void _setConnectionState(ConnectionState state) {
    _connectionState = state;
    notifyListeners();
  }

  /// Get connection by name
  SshConnection? getConnectionByName(String name) {
    try {
      return _savedConnections.firstWhere((conn) => conn.name == name);
    } catch (e) {
      return null;
    }
  }

  /// Check if connection name is available
  bool isConnectionNameAvailable(String name, {String? excludeName}) {
    return !_savedConnections.any((conn) => 
        conn.name == name && conn.name != excludeName);
  }

  /// Export connections (for backup)
  Map<String, dynamic> exportConnections() {
    return {
      'connections': _savedConnections.map((conn) => conn.toJson()).toList(),
      'exportDate': DateTime.now().toIso8601String(),
    };
  }

  /// Import connections (from backup)
  Future<void> importConnections(Map<String, dynamic> data) async {
    try {
      final connections = (data['connections'] as List)
          .map((conn) => SshConnection.fromJson(conn))
          .toList();
      
      _savedConnections = connections;
      await _storageService.saveConnections(_savedConnections);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to import connections: $e';
      notifyListeners();
    }
  }

  /// Clear cached passwords
  void clearPasswords() {
    _sshService.clearAllPasswords();
  }

  /// Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _sshService.dispose();
    super.dispose();
  }
}