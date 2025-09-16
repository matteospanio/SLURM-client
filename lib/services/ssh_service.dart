import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/connection.dart';
import 'base_ssh_service.dart';

// Conditional imports for web vs desktop
import 'ssh_service_stub.dart' as stub
    if (dart.library.io) 'ssh_service_io.dart' as io
    if (dart.library.html) 'ssh_service_web.dart' as web;

// Export the base class and result types
export 'base_ssh_service.dart';

// Platform-specific SSH service factory
BaseSSHService createSSHService() {
  if (kIsWeb) {
    return web.WebSSHService();
  } else {
    return io.DesktopSSHService();
  }
}

// Type alias for backward compatibility  
typedef SshService = BaseSSHService;
