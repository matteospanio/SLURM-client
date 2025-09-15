import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'providers/job_provider.dart';
import 'providers/connection_provider.dart';
import 'providers/settings_provider.dart';
import 'services/ssh_service.dart';
import 'services/slurm_service.dart';
import 'services/storage_service.dart';
import 'services/system_tray_service.dart';
import 'screens/dashboard_screen.dart';
import 'models/settings.dart' as models;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize window manager for desktop platforms only
  if (!kIsWeb) {
    try {
      await windowManager.ensureInitialized();
      
      WindowOptions windowOptions = const WindowOptions(
        size: Size(1200, 800),
        minimumSize: Size(800, 600),
        center: true,
        backgroundColor: Colors.transparent,
        skipTaskbar: false,
        titleBarStyle: TitleBarStyle.normal,
        windowButtonVisibility: true,
      );
      
      // Show window and then initialize system tray
      await windowManager.waitUntilReadyToShow(windowOptions, () async {
        await windowManager.show();
        await windowManager.focus();
      });
    } catch (e) {
      debugPrint('Failed to initialize window manager: $e');
    }
  }
  
  runApp(const SlurmQueueApp());
}



class SlurmQueueApp extends StatelessWidget {
  const SlurmQueueApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<SshService>(
          create: (_) => SshService(),
          dispose: (_, service) => service.dispose(),
        ),
        Provider<StorageService>(
          create: (_) => StorageService(),
        ),
        ProxyProvider<SshService, SlurmService>(
          update: (_, sshService, __) => SlurmService(sshService),
        ),
        ChangeNotifierProxyProvider2<SshService, StorageService, ConnectionProvider>(
          create: (context) => ConnectionProvider(
            context.read<SshService>(),
            context.read<StorageService>(),
          ),
          update: (_, sshService, storageService, previous) =>
              previous ?? ConnectionProvider(sshService, storageService),
        ),
        ChangeNotifierProxyProvider<StorageService, SettingsProvider>(
          create: (context) => SettingsProvider(context.read<StorageService>()),
          update: (_, storageService, previous) =>
              previous ?? SettingsProvider(storageService),
        ),
        ChangeNotifierProxyProvider<SlurmService, JobProvider>(
          create: (context) => JobProvider(context.read<SlurmService>()),
          update: (_, slurmService, previous) =>
              previous ?? JobProvider(slurmService),
        ),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) {
          return MaterialApp(
            title: 'SLURM Queue Client',
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
              useMaterial3: true,
            ),
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.deepPurple,
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
            ),
            themeMode: _getFlutterThemeMode(settingsProvider.settings.themeMode),
            home: const DashboardScreen(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }

  ThemeMode _getFlutterThemeMode(models.ThemeMode themeMode) {
    switch (themeMode) {
      case models.ThemeMode.light:
        return ThemeMode.light;
      case models.ThemeMode.dark:
        return ThemeMode.dark;
      case models.ThemeMode.system:
        return ThemeMode.system;
    }
  }
}


