# SLURM Queue Client - GitHub Copilot Instructions

This repository contains a Flutter-based SLURM queue monitoring application that provides a modern desktop interface for monitoring and managing SLURM job queues through SSH connections.

## Project Overview

### Application Purpose
The SLURM Queue Client is a cross-platform desktop application designed to help users monitor and manage their SLURM job queues remotely. It connects to SLURM clusters via SSH and provides real-time job status monitoring with an intuitive Material Design 3 interface.

### Target Platforms
- Primary: Linux desktop environments (GTK3-based)
- Secondary: Windows, macOS (cross-platform Flutter support)

## Architecture & Technology Stack

### Core Framework
- **Flutter SDK**: ^3.9.2 with Dart
- **UI Framework**: Material Design 3 components
- **State Management**: Provider pattern for reactive state management
- **Serialization**: JSON serialization with code generation

### Key Dependencies
- `ssh2`: SSH connection management for secure cluster communication
- `provider`: State management and dependency injection
- `json_annotation` & `json_serializable`: Type-safe data persistence
- `flutter_lints`: Code quality and style enforcement

### Platform Integration
- **Linux**: GTK3 integration with system tray support
- **Desktop**: Native window management and desktop notifications

## Core Features & Modules

### 1. SSH Connection Management
- Secure SSH connections to SLURM clusters
- Connection pooling and session management
- Authentication handling (password, key-based)
- Multi-cluster support with connection switching

**Key Files:**
- Connection models and services
- SSH wrapper classes
- Authentication providers

### 2. SLURM Job Monitoring
- Real-time job queue display using `squeue --me`
- Auto-refresh capabilities with configurable intervals
- Job status parsing and data modeling
- Error handling for cluster communication

**Commands Integrated:**
- `squeue --me`: Display user's job queue
- `scancel <job_id>`: Cancel specific jobs
- `sinfo`: Cluster information (future feature)

### 3. User Interface Components

#### Dashboard
- Job status summary cards
- Detailed job list with expandable cards
- Real-time status updates
- Material Design 3 theming

#### Settings Management
- Tabbed interface for different configuration sections
- Account/connection management
- Application preferences
- Theme selection (light/dark/system)

#### Job Management
- Interactive job cancellation
- Job details expansion
- Status filtering and sorting

### 4. System Integration
- System tray functionality for Linux environments
- Background monitoring capabilities
- Desktop notifications for job status changes
- Window state management

## Code Patterns & Conventions

### State Management
- Use Provider pattern for application state
- Separate providers for different feature domains:
  - `ConnectionProvider`: SSH connection state
  - `JobProvider`: SLURM job data and operations
  - `SettingsProvider`: User preferences and configuration
  - `ThemeProvider`: UI theme management

### Data Models
- Use `@JsonSerializable()` for data classes that need persistence
- Implement `copyWith()` methods for immutable state updates
- Use factory constructors for JSON deserialization

### Error Handling
- Implement comprehensive error boundaries
- Provide user-friendly error messages
- Log errors appropriately for debugging
- Handle network timeouts and SSH connection failures gracefully

### UI Components
- Follow Material Design 3 guidelines
- Create reusable widget components
- Implement responsive design for different screen sizes
- Use proper accessibility labels and semantics

## File Organization

```
lib/
├── main.dart                 # Application entry point
├── models/                   # Data models and entities
│   ├── job.dart             # SLURM job model
│   ├── connection.dart      # SSH connection model
│   └── settings.dart        # Application settings model
├── providers/               # State management providers
│   ├── job_provider.dart    # Job queue state management
│   ├── connection_provider.dart # SSH connection management
│   └── settings_provider.dart  # User preferences
├── services/                # Business logic and external APIs
│   ├── ssh_service.dart     # SSH communication service
│   ├── slurm_service.dart   # SLURM command execution
│   └── storage_service.dart # Local data persistence
├── widgets/                 # Reusable UI components
│   ├── job_card.dart        # Individual job display
│   ├── connection_dialog.dart # SSH connection setup
│   └── settings_tabs.dart   # Settings interface
└── screens/                 # Full-screen UI components
    ├── dashboard_screen.dart # Main job monitoring interface
    ├── settings_screen.dart  # Configuration interface
    └── connection_screen.dart # Connection management
```

## Development Guidelines

### Testing
- Write widget tests for UI components
- Create unit tests for business logic
- Use integration tests for SSH connectivity
- Mock external dependencies in tests

### Code Quality
- Follow dart/flutter linting rules
- Use meaningful variable and function names
- Add documentation for public APIs
- Implement proper null safety

### Performance Considerations
- Minimize SSH connection overhead
- Implement efficient job list updates
- Use proper state management to avoid unnecessary rebuilds
- Optimize for desktop UI responsiveness

## Common Development Tasks

### Adding New SLURM Commands
1. Extend `SlurmService` with new command methods
2. Update job models if needed for new data fields
3. Add UI components for new functionality
4. Update providers to handle new state changes

### SSH Connection Features
- Always handle connection timeouts
- Implement proper authentication error handling
- Consider connection pooling for multiple simultaneous operations
- Add logging for debugging connection issues

### UI Enhancements
- Follow Material Design 3 principles
- Ensure proper theme support (light/dark modes)
- Implement responsive layouts
- Add loading states and error feedback

## Security Considerations
- Store SSH credentials securely (keyring integration)
- Validate all user inputs
- Sanitize command parameters to prevent injection
- Implement proper session management

## Future Development Areas
- Web interface support
- Mobile companion app
- Advanced job scheduling features
- Cluster resource monitoring
- Multi-user collaboration features