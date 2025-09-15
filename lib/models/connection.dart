import 'package:json_annotation/json_annotation.dart';

part 'connection.g.dart';

@JsonSerializable()
class SshConnection {
  final String name;
  final String hostname;
  final int port;
  final String username;
  final String? privateKeyPath;
  final bool usePassword;
  final bool isDefault;

  const SshConnection({
    required this.name,
    required this.hostname,
    this.port = 22,
    required this.username,
    this.privateKeyPath,
    this.usePassword = false,
    this.isDefault = false,
  });

  factory SshConnection.fromJson(Map<String, dynamic> json) =>
      _$SshConnectionFromJson(json);

  Map<String, dynamic> toJson() => _$SshConnectionToJson(this);

  SshConnection copyWith({
    String? name,
    String? hostname,
    int? port,
    String? username,
    String? privateKeyPath,
    bool? usePassword,
    bool? isDefault,
  }) {
    return SshConnection(
      name: name ?? this.name,
      hostname: hostname ?? this.hostname,
      port: port ?? this.port,
      username: username ?? this.username,
      privateKeyPath: privateKeyPath ?? this.privateKeyPath,
      usePassword: usePassword ?? this.usePassword,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SshConnection &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          hostname == other.hostname &&
          port == other.port &&
          username == other.username;

  @override
  int get hashCode => Object.hash(name, hostname, port, username);

  @override
  String toString() {
    return 'SshConnection{name: $name, hostname: $hostname, port: $port, username: $username}';
  }

  /// Generate connection string for display
  String get connectionString => '$username@$hostname:$port';

  /// Validate connection parameters
  bool get isValid {
    return name.isNotEmpty &&
        hostname.isNotEmpty &&
        username.isNotEmpty &&
        port > 0 &&
        port <= 65535;
  }
}

enum ConnectionStatus {
  disconnected,
  connecting,
  connected,
  error,
}

class ConnectionState {
  final SshConnection? connection;
  final ConnectionStatus status;
  final String? errorMessage;
  final DateTime? lastConnected;

  const ConnectionState({
    this.connection,
    this.status = ConnectionStatus.disconnected,
    this.errorMessage,
    this.lastConnected,
  });

  ConnectionState copyWith({
    SshConnection? connection,
    ConnectionStatus? status,
    String? errorMessage,
    DateTime? lastConnected,
  }) {
    return ConnectionState(
      connection: connection ?? this.connection,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      lastConnected: lastConnected ?? this.lastConnected,
    );
  }

  bool get isConnected => status == ConnectionStatus.connected;
  bool get isConnecting => status == ConnectionStatus.connecting;
  bool get hasError => status == ConnectionStatus.error;

  @override
  String toString() {
    return 'ConnectionState{status: $status, connection: ${connection?.name}}';
  }
}