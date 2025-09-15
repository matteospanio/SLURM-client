import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'providers/job_provider.dart';
import 'providers/connection_provider.dart';
import 'services/ssh_service.dart';
import 'services/slurm_service.dart';
import 'services/storage_service.dart';
import 'screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize window manager for desktop platforms
  if (!isWeb()) {
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
    
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }
  
  runApp(const SlurmQueueApp());
}

bool isWeb() {
  return identical(0, 0.0);
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
        ChangeNotifierProxyProvider<SlurmService, JobProvider>(
          create: (context) => JobProvider(context.read<SlurmService>()),
          update: (_, slurmService, previous) =>
              previous ?? JobProvider(slurmService),
        ),
      ],
      child: MaterialApp(
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
        themeMode: ThemeMode.system,
        home: const DashboardScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}


