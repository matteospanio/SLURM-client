import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/connection.dart';

// Conditional imports for web vs desktop
import 'ssh_service_stub.dart'
    if (dart.library.io) 'ssh_service_io.dart'
    if (dart.library.html) 'ssh_service_web.dart';

// Export the platform-specific implementation
export 'ssh_service_stub.dart'
    if (dart.library.io) 'ssh_service_io.dart'
    if (dart.library.html) 'ssh_service_web.dart';
