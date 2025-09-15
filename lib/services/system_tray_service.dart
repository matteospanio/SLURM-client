import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:system_tray/system_tray.dart';
import 'package:window_manager/window_manager.dart';

class SystemTrayService {
  static final SystemTrayService _instance = SystemTrayService._internal();
  factory SystemTrayService() => _instance;
  SystemTrayService._internal();

  final SystemTray _systemTray = SystemTray();
  bool _isInitialized = false;
  Timer? _blinkTimer;

  /// Initialize system tray
  Future<void> initialize() async {
    if (_isInitialized || !Platform.isLinux) return;

    try {
      await _systemTray.initSystemTray(
        title: "SLURM Queue Client",
        iconPath: _getIconPath(),
      );

      await _setupContextMenu();
      _isInitialized = true;
    } catch (e) {
      debugPrint('Failed to initialize system tray: $e');
    }
  }

  /// Setup context menu for system tray
  Future<void> _setupContextMenu() async {
    final Menu menu = Menu();
    
    await menu.buildFrom([
      MenuItemLabel(
        label: 'SLURM Queue Client',
        enabled: false,
      ),
      MenuSeparator(),
      MenuItemLabel(
        label: 'Show/Hide',
        onClicked: (menuItem) => _toggleWindow(),
      ),
      MenuItemLabel(
        label: 'Refresh Jobs',
        onClicked: (menuItem) => _refreshJobs(),
      ),
      MenuSeparator(),
      MenuItemLabel(
        label: 'Settings',
        onClicked: (menuItem) => _showSettings(),
      ),
      MenuSeparator(),
      MenuItemLabel(
        label: 'Quit',
        onClicked: (menuItem) => _quit(),
      ),
    ]);

    await _systemTray.setContextMenu(menu);
  }

  /// Update tray icon and tooltip
  Future<void> updateStatus({
    required bool connected,
    required int totalJobs,
    required int runningJobs,
    required int pendingJobs,
  }) async {
    if (!_isInitialized) return;

    try {
      // Update tooltip
      final tooltip = connected
          ? 'SLURM Queue Client\nTotal: $totalJobs | Running: $runningJobs | Pending: $pendingJobs'
          : 'SLURM Queue Client\nNot connected';
      
      await _systemTray.setToolTip(tooltip);

      // Update icon based on status
      final iconPath = connected 
          ? _getIconPath(connected: true)
          : _getIconPath(connected: false);
      
      await _systemTray.setImage(iconPath);
    } catch (e) {
      debugPrint('Failed to update system tray status: $e');
    }
  }

  /// Show notification
  Future<void> showNotification({
    required String title,
    required String message,
    SystemTrayNotificationType type = SystemTrayNotificationType.info,
  }) async {
    if (!_isInitialized) return;

    try {
      await _systemTray.popUpContextMenu();
      // Note: system_tray package may not support notifications directly
      // This would need platform-specific implementation
    } catch (e) {
      debugPrint('Failed to show notification: $e');
    }
  }

  /// Start blinking tray icon (for alerts)
  void startBlinking() {
    if (!_isInitialized || _blinkTimer?.isActive == true) return;

    _blinkTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) async {
      try {
        // Alternate between normal and alert icons
        final isAlertIcon = timer.tick % 2 == 0;
        final iconPath = _getIconPath(alert: isAlertIcon);
        await _systemTray.setImage(iconPath);
      } catch (e) {
        debugPrint('Error during tray icon blinking: $e');
      }
    });
  }

  /// Stop blinking tray icon
  void stopBlinking() {
    _blinkTimer?.cancel();
    _blinkTimer = null;
    
    // Reset to normal icon
    if (_isInitialized) {
      _systemTray.setImage(_getIconPath());
    }
  }

  /// Get appropriate icon path
  String _getIconPath({bool connected = true, bool alert = false}) {
    // In a real implementation, you would have different icon files
    // For now, return a placeholder path
    if (alert) {
      return 'assets/icons/tray_alert.png';
    } else if (connected) {
      return 'assets/icons/tray_connected.png';
    } else {
      return 'assets/icons/tray_disconnected.png';
    }
  }

  /// Toggle main window visibility
  Future<void> _toggleWindow() async {
    try {
      final isVisible = await windowManager.isVisible();
      if (isVisible) {
        await windowManager.hide();
      } else {
        await windowManager.show();
        await windowManager.focus();
      }
    } catch (e) {
      debugPrint('Error toggling window: $e');
    }
  }

  /// Trigger jobs refresh (would need callback)
  void _refreshJobs() {
    // This would typically call a callback or emit an event
    debugPrint('Refresh jobs requested from system tray');
  }

  /// Show settings (would need callback)
  void _showSettings() {
    // This would typically call a callback or emit an event
    debugPrint('Settings requested from system tray');
  }

  /// Quit application
  Future<void> _quit() async {
    try {
      await destroy();
      exit(0);
    } catch (e) {
      debugPrint('Error quitting application: $e');
    }
  }

  /// Handle tray icon click
  void onTrayIconMouseDown() {
    _toggleWindow();
  }

  /// Handle tray icon right click
  void onTrayIconRightMouseDown() {
    // Context menu will be shown automatically
  }

  /// Destroy system tray
  Future<void> destroy() async {
    if (!_isInitialized) return;

    try {
      stopBlinking();
      await _systemTray.destroy();
      _isInitialized = false;
    } catch (e) {
      debugPrint('Error destroying system tray: $e');
    }
  }

  /// Check if system tray is supported
  static bool get isSupported => Platform.isLinux || Platform.isWindows || Platform.isMacOS;
}