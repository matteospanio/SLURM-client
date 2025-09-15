import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/connection.dart';
import '../models/settings.dart';

class StorageService {
  static const String _connectionsKey = 'saved_connections';
  static const String _settingsKey = 'app_settings';
  static const String _windowStateKey = 'window_state';

  SharedPreferences? _prefs;

  /// Initialize the storage service
  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Save connections to storage
  Future<void> saveConnections(List<SshConnection> connections) async {
    await initialize();
    final connectionsJson = connections.map((conn) => conn.toJson()).toList();
    await _prefs!.setString(_connectionsKey, jsonEncode(connectionsJson));
  }

  /// Load connections from storage
  Future<List<SshConnection>> loadConnections() async {
    await initialize();
    final connectionsString = _prefs!.getString(_connectionsKey);
    
    if (connectionsString != null) {
      try {
        final connectionsJson = jsonDecode(connectionsString) as List;
        return connectionsJson
            .map((conn) => SshConnection.fromJson(conn))
            .toList();
      } catch (e) {
        // If parsing fails, return empty list
        return [];
      }
    }
    
    return [];
  }

  /// Save app settings to storage
  Future<void> saveSettings(AppSettings settings) async {
    await initialize();
    await _prefs!.setString(_settingsKey, jsonEncode(settings.toJson()));
  }

  /// Load app settings from storage
  Future<AppSettings> loadSettings() async {
    await initialize();
    final settingsString = _prefs!.getString(_settingsKey);
    
    if (settingsString != null) {
      try {
        final settingsJson = jsonDecode(settingsString);
        return AppSettings.fromJson(settingsJson);
      } catch (e) {
        // If parsing fails, return default settings
        return const AppSettings();
      }
    }
    
    return const AppSettings();
  }

  /// Save window state (position, size, etc.)
  Future<void> saveWindowState(Map<String, dynamic> windowState) async {
    await initialize();
    await _prefs!.setString(_windowStateKey, jsonEncode(windowState));
  }

  /// Load window state
  Future<Map<String, dynamic>?> loadWindowState() async {
    await initialize();
    final windowStateString = _prefs!.getString(_windowStateKey);
    
    if (windowStateString != null) {
      try {
        return jsonDecode(windowStateString) as Map<String, dynamic>;
      } catch (e) {
        return null;
      }
    }
    
    return null;
  }

  /// Save a generic key-value pair
  Future<void> saveString(String key, String value) async {
    await initialize();
    await _prefs!.setString(key, value);
  }

  /// Load a generic string value
  Future<String?> loadString(String key) async {
    await initialize();
    return _prefs!.getString(key);
  }

  /// Save a boolean value
  Future<void> saveBool(String key, bool value) async {
    await initialize();
    await _prefs!.setBool(key, value);
  }

  /// Load a boolean value
  Future<bool> loadBool(String key, {bool defaultValue = false}) async {
    await initialize();
    return _prefs!.getBool(key) ?? defaultValue;
  }

  /// Save an integer value
  Future<void> saveInt(String key, int value) async {
    await initialize();
    await _prefs!.setInt(key, value);
  }

  /// Load an integer value
  Future<int> loadInt(String key, {int defaultValue = 0}) async {
    await initialize();
    return _prefs!.getInt(key) ?? defaultValue;
  }

  /// Save a double value
  Future<void> saveDouble(String key, double value) async {
    await initialize();
    await _prefs!.setDouble(key, value);
  }

  /// Load a double value
  Future<double> loadDouble(String key, {double defaultValue = 0.0}) async {
    await initialize();
    return _prefs!.getDouble(key) ?? defaultValue;
  }

  /// Save a list of strings
  Future<void> saveStringList(String key, List<String> value) async {
    await initialize();
    await _prefs!.setStringList(key, value);
  }

  /// Load a list of strings
  Future<List<String>> loadStringList(String key) async {
    await initialize();
    return _prefs!.getStringList(key) ?? [];
  }

  /// Remove a specific key
  Future<void> remove(String key) async {
    await initialize();
    await _prefs!.remove(key);
  }

  /// Clear all stored data
  Future<void> clear() async {
    await initialize();
    await _prefs!.clear();
  }

  /// Check if a key exists
  Future<bool> containsKey(String key) async {
    await initialize();
    return _prefs!.containsKey(key);
  }

  /// Get all keys
  Future<Set<String>> getAllKeys() async {
    await initialize();
    return _prefs!.getKeys();
  }

  /// Export all data (for backup)
  Future<Map<String, dynamic>> exportData() async {
    await initialize();
    final allKeys = _prefs!.getKeys();
    final data = <String, dynamic>{};
    
    for (final key in allKeys) {
      final value = _prefs!.get(key);
      if (value != null) {
        data[key] = value;
      }
    }
    
    return {
      'data': data,
      'exportDate': DateTime.now().toIso8601String(),
      'version': '1.0.0',
    };
  }

  /// Import data (from backup)
  Future<void> importData(Map<String, dynamic> backup) async {
    await initialize();
    
    final data = backup['data'] as Map<String, dynamic>?;
    if (data != null) {
      // Clear existing data
      await _prefs!.clear();
      
      // Import new data
      for (final entry in data.entries) {
        final key = entry.key;
        final value = entry.value;
        
        if (value is String) {
          await _prefs!.setString(key, value);
        } else if (value is bool) {
          await _prefs!.setBool(key, value);
        } else if (value is int) {
          await _prefs!.setInt(key, value);
        } else if (value is double) {
          await _prefs!.setDouble(key, value);
        } else if (value is List<String>) {
          await _prefs!.setStringList(key, value);
        }
      }
    }
  }

  /// Get storage usage information
  Future<Map<String, dynamic>> getStorageInfo() async {
    await initialize();
    final allKeys = _prefs!.getKeys();
    int totalSize = 0;
    final keyInfo = <String, int>{};
    
    for (final key in allKeys) {
      final value = _prefs!.get(key);
      if (value != null) {
        final size = value.toString().length;
        keyInfo[key] = size;
        totalSize += size;
      }
    }
    
    return {
      'totalKeys': allKeys.length,
      'totalSize': totalSize,
      'keyInfo': keyInfo,
    };
  }
}