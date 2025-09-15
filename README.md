# SLURM Queue Client

A modern Flutter desktop application for monitoring and managing SLURM job queues through SSH connections. Built with Material Design 3, this cross-platform client provides an intuitive interface for SLURM cluster administrators and users.

## Features

### 🚀 Core Functionality
- **SSH Connection Management**: Secure connections to SLURM clusters with key-based or password authentication
- **Real-time Job Monitoring**: Live job queue monitoring using `squeue --me` command
- **Job Management**: Cancel running or pending jobs with `scancel` command
- **Advanced Filtering**: Filter jobs by user, name, state, partition, and node
- **Job Statistics**: Real-time dashboard with job state summaries

### 🎨 User Interface
- **Material Design 3**: Modern, clean interface with light/dark theme support
- **Responsive Layout**: Optimized for desktop environments (Linux, Windows, macOS)
- **Expandable Job Cards**: Detailed job information with quick actions
- **Smart Search**: Search jobs by name or ID with instant filtering
- **Sortable Lists**: Sort jobs by ID, name, user, state, time, or nodes

### ⚙️ System Integration
- **System Tray Support**: Background monitoring with system tray integration (Linux primary)
- **Auto-refresh**: Configurable automatic job list updates
- **Desktop Notifications**: Alerts for job status changes
- **Connection Persistence**: Save and manage multiple cluster connections
- **Settings Management**: Comprehensive configuration options

## Getting Started

### Prerequisites
- Flutter SDK 3.9.2 or higher
- Dart SDK (bundled with Flutter)
- SSH access to SLURM cluster(s)
- Linux desktop environment (GTK3) for optimal experience

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/matteospanio/SLURM-client.git
   cd SLURM-client
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate code (JSON serialization)**
   ```bash
   flutter packages pub run build_runner build
   ```

4. **Run the application**
   ```bash
   flutter run -d linux
   ```

### Building for Production

```bash
# Build for Linux
flutter build linux --release

# Build for Windows
flutter build windows --release

# Build for macOS
flutter build macos --release
```

## Usage

### Setting Up Connections

1. **Launch the application**
2. **Click the "Connect" button** or connection icon in the app bar
3. **Configure your SSH connection:**
   - **Connection Name**: A friendly name for your cluster
   - **Hostname**: Your SLURM cluster hostname/IP
   - **Username**: Your cluster username
   - **Port**: SSH port (default: 22)
   - **Authentication**: Choose between SSH key or password

4. **Test the connection** before saving
5. **Save and connect** to start monitoring

### Monitoring Jobs

- **View job queue**: Connected clusters automatically display your job queue
- **Filter jobs**: Use the filter dialog to narrow down results
- **Sort jobs**: Click column headers or use the sort menu
- **Search**: Use the search bar to find specific jobs
- **Refresh**: Manual refresh or enable auto-refresh in settings

### Managing Jobs

- **View details**: Click the info icon or expand job cards
- **Cancel jobs**: Use the cancel button for running/pending jobs
- **Monitor status**: Real-time status updates with color-coded states

### System Tray Usage

When enabled, the system tray provides:
- **Quick status**: Job count and connection status in tooltip
- **Show/Hide**: Toggle application window visibility
- **Refresh**: Manually refresh job list
- **Settings**: Quick access to configuration
- **Quit**: Close the application

## Configuration

### SSH Authentication

#### Key-based Authentication (Recommended)
```bash
# Generate SSH key pair (if needed)
ssh-keygen -t ed25519 -C "your_email@example.com"

# Copy public key to cluster
ssh-copy-id username@cluster-hostname
```

#### Password Authentication
- Enable "Use Password Authentication" in connection dialog
- Password will be cached for the session

### Auto-refresh Settings
- **Interval**: Set refresh frequency (default: 30 seconds)
- **Enable/Disable**: Toggle automatic updates
- **System tray**: Monitor jobs in background

### Theme Configuration
- **Light Mode**: Traditional light interface
- **Dark Mode**: Dark interface for low-light environments
- **System**: Follow system theme preference

## SLURM Commands Used

The application executes these SLURM commands via SSH:

```bash
# Get user's job queue
squeue --me --format="%18i %.9P %.20j %.8u %.2t %.10M %.6D %R"

# Cancel a specific job
scancel <job_id>

# Get detailed job information
scontrol show job <job_id>

# Get cluster information (optional)
sinfo --format="%20P %.5a %.10l %.6D %.6t %N"

# Check SLURM availability
which squeue
sinfo --version
```

## Architecture

### Project Structure
```
lib/
├── main.dart                 # Application entry point
├── models/                   # Data models
│   ├── job.dart             # SLURM job representation
│   ├── connection.dart      # SSH connection configuration
│   └── settings.dart        # Application settings
├── providers/               # State management
│   ├── job_provider.dart    # Job queue state
│   ├── connection_provider.dart # SSH connections
│   └── settings_provider.dart  # User preferences
├── services/                # Business logic
│   ├── ssh_service.dart     # SSH communication
│   ├── slurm_service.dart   # SLURM command execution
│   ├── storage_service.dart # Local data persistence
│   └── system_tray_service.dart # System integration
├── widgets/                 # Reusable UI components
│   ├── job_card.dart        # Job display component
│   ├── connection_dialog.dart # SSH setup dialog
│   └── job_filter_dialog.dart # Filtering interface
└── screens/                 # Application screens
    ├── dashboard_screen.dart # Main interface
    └── settings_screen.dart  # Configuration screen
```

### Key Technologies
- **Flutter**: Cross-platform UI framework
- **Provider**: State management pattern
- **ssh2**: SSH client for secure connections
- **shared_preferences**: Local data storage
- **system_tray**: System tray integration
- **window_manager**: Desktop window management
- **JSON serialization**: Type-safe data persistence

## Troubleshooting

### SSH Connection Issues
1. **Verify network connectivity**
   ```bash
   ping cluster-hostname
   ```

2. **Test SSH access manually**
   ```bash
   ssh username@cluster-hostname
   ```

3. **Check SSH key permissions**
   ```bash
   chmod 600 ~/.ssh/id_rsa
   chmod 644 ~/.ssh/id_rsa.pub
   ```

4. **Verify SLURM commands**
   ```bash
   ssh username@cluster-hostname 'squeue --me'
   ```

### Application Issues
1. **Clear application data**: Delete cached preferences
2. **Reset connections**: Remove saved connections in settings
3. **Check system tray**: Ensure tray is supported on your desktop
4. **Review logs**: Check console output for error messages

### Performance Optimization
- Adjust refresh interval based on cluster load
- Limit maximum jobs displayed in settings
- Use filtering to reduce data processing

## Development

### Contributing
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Submit a pull request

### Testing
```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/widget_test.dart

# Generate test coverage
flutter test --coverage
```

### Code Generation
```bash
# Regenerate JSON serialization
flutter packages pub run build_runner build --delete-conflicting-outputs
```

## Platform-Specific Notes

### Linux
- Primary target platform with full feature support
- System tray integration via GTK3
- Desktop notifications support
- Window management capabilities

### Windows
- Full functionality with Windows-style system tray
- Requires Windows 10 or higher
- SSH key location: `%USERPROFILE%\.ssh\`

### macOS
- System tray in menu bar
- macOS 10.14 or higher required
- SSH key location: `~/.ssh/`

## Security Considerations

- SSH credentials are stored locally using secure storage
- Passwords are cached in memory only during session
- SSH keys should have appropriate file permissions (600)
- Network communication uses encrypted SSH tunnels
- No data is transmitted to external services

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For issues, questions, or contributions:
- **GitHub Issues**: Report bugs and request features
- **Documentation**: Check inline code documentation
- **SLURM Documentation**: Refer to official SLURM documentation for cluster-specific issues

## Acknowledgments

- **SLURM Workload Manager**: For providing the job scheduling system
- **Flutter Team**: For the excellent cross-platform framework
- **SSH2 Package**: For reliable SSH connectivity
- **Material Design 3**: For the modern UI guidelines
