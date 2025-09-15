import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/settings.dart';
import '../services/storage_service.dart';

class SettingsProvider extends ChangeNotifier {
  final StorageService _storageService;
  AppSettings _settings = const AppSettings();
  
  SettingsProvider(this._storageService) {
    _loadSettings();
  }

  AppSettings get settings => _settings;

  /// Load settings from storage
  Future<void> _loadSettings() async {
    try {
      _settings = await _storageService.loadSettings();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading settings: $e');
    }
  }

  /// Update refresh interval
  Future<void> updateRefreshInterval(int seconds) async {
    _settings = _settings.copyWith(refreshInterval: seconds);
    await _saveSettings();
  }

  /// Toggle auto refresh
  Future<void> toggleAutoRefresh(bool enabled) async {
    _settings = _settings.copyWith(autoRefresh: enabled);
    await _saveSettings();
  }

  /// Toggle system tray
  Future<void> toggleSystemTray(bool enabled) async {
    _settings = _settings.copyWith(showSystemTray: enabled);
    await _saveSettings();
  }

  /// Toggle start minimized
  Future<void> toggleStartMinimized(bool enabled) async {
    _settings = _settings.copyWith(startMinimized: enabled);
    await _saveSettings();
  }

  /// Update theme mode
  Future<void> updateThemeMode(ThemeMode mode) async {
    _settings = _settings.copyWith(themeMode: mode);
    await _saveSettings();
  }

  /// Toggle notifications
  Future<void> toggleNotifications(bool enabled) async {
    _settings = _settings.copyWith(showNotifications: enabled);
    await _saveSettings();
  }

  /// Update max jobs to show
  Future<void> updateMaxJobsToShow(int maxJobs) async {
    _settings = _settings.copyWith(maxJobsToShow: maxJobs);
    await _saveSettings();
  }

  /// Update job state filters
  Future<void> updateJobStateFilters(List<String> filters) async {
    _settings = _settings.copyWith(jobStateFilters: filters);
    await _saveSettings();
  }

  /// Save settings to storage
  Future<void> _saveSettings() async {
    try {
      await _storageService.saveSettings(_settings);
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving settings: $e');
    }
  }

  /// Reset settings to default
  Future<void> resetToDefaults() async {
    _settings = const AppSettings();
    await _saveSettings();
  }

  /// Export settings
  Map<String, dynamic> exportSettings() {
    return {
      'settings': _settings.toJson(),
      'exportDate': DateTime.now().toIso8601String(),
    };
  }

  /// Import settings
  Future<void> importSettings(Map<String, dynamic> data) async {
    try {
      final settingsData = data['settings'] as Map<String, dynamic>;
      _settings = AppSettings.fromJson(settingsData);
      await _saveSettings();
    } catch (e) {
      debugPrint('Error importing settings: $e');
    }
  }
}