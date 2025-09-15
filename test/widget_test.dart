// Test file for SLURM Queue Client

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:slurm_queue_client/main.dart';
import 'package:slurm_queue_client/models/job.dart';
import 'package:slurm_queue_client/models/connection.dart';
import 'package:slurm_queue_client/models/settings.dart';
import 'package:slurm_queue_client/providers/job_provider.dart';
import 'package:slurm_queue_client/providers/connection_provider.dart';
import 'package:slurm_queue_client/providers/settings_provider.dart';
import 'package:slurm_queue_client/services/ssh_service.dart';
import 'package:slurm_queue_client/services/slurm_service.dart';
import 'package:slurm_queue_client/services/storage_service.dart';

void main() {
  testWidgets('SLURM Queue Client loads dashboard', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SlurmQueueApp());

    // Verify that the app bar shows the correct title
    expect(find.text('SLURM Queue Monitor'), findsOneWidget);
    
    // Verify that we show the not connected state initially
    expect(find.text('Not connected to cluster'), findsOneWidget);
    expect(find.text('Connect'), findsOneWidget);
  });

  testWidgets('Connection dialog can be opened', (WidgetTester tester) async {
    await tester.pumpWidget(const SlurmQueueApp());

    // Find and tap the connect button
    await tester.tap(find.text('Connect'));
    await tester.pumpAndSettle();

    // Verify that the connection dialog is shown
    expect(find.text('SSH Connection'), findsOneWidget);
    expect(find.text('Connection Name'), findsOneWidget);
    expect(find.text('Hostname'), findsOneWidget);
    expect(find.text('Username'), findsOneWidget);
  });

  group('Job Model Tests', () {
    test('SlurmJob.fromSqueueLine parses job correctly', () {
      const line = '12345 main test_job user01 R 00:15:30 2 node01,node02';
      final job = SlurmJob.fromSqueueLine(line);

      expect(job.jobId, '12345');
      expect(job.partition, 'main');
      expect(job.name, 'test_job');
      expect(job.user, 'user01');
      expect(job.state, 'R');
      expect(job.time, '00:15:30');
      expect(job.nodes, '2');
      expect(job.nodeList, 'node01,node02');
    });

    test('SlurmJob.getStateName returns correct names', () {
      expect(SlurmJob.getStateName('R'), 'Running');
      expect(SlurmJob.getStateName('PD'), 'Pending');
      expect(SlurmJob.getStateName('CD'), 'Completed');
      expect(SlurmJob.getStateName('F'), 'Failed');
    });

    test('SlurmJob.matchesFilter works correctly', () {
      const job = SlurmJob(
        jobId: '12345',
        name: 'test_job',
        user: 'user01',
        state: 'R',
        time: '00:15:30',
        nodes: '2',
        nodeList: 'node01,node02',
      );

      expect(job.matchesFilter(userFilter: 'user01'), true);
      expect(job.matchesFilter(userFilter: 'user02'), false);
      expect(job.matchesFilter(nameFilter: 'test'), true);
      expect(job.matchesFilter(nameFilter: 'other'), false);
    });
  });

  group('Connection Model Tests', () {
    test('SshConnection validation works', () {
      const validConnection = SshConnection(
        name: 'test',
        hostname: 'example.com',
        username: 'user',
        port: 22,
      );

      const invalidConnection = SshConnection(
        name: '',
        hostname: 'example.com',
        username: 'user',
        port: 22,
      );

      expect(validConnection.isValid, true);
      expect(invalidConnection.isValid, false);
    });

    test('SshConnection connectionString is correct', () {
      const connection = SshConnection(
        name: 'test',
        hostname: 'example.com',
        username: 'user',
        port: 2222,
      );

      expect(connection.connectionString, 'user@example.com:2222');
    });
  });

  group('SSH Service Tests', () {
    test('SSH service handles web platform correctly', () {
      final sshService = SshService();
      const testConnection = SshConnection(
        name: 'test',
        hostname: 'example.com',
        username: 'user',
      );

      // On web, SSH operations should fail gracefully
      expect(sshService.isConnected, false);
      expect(sshService.getConnectionStatus(), ConnectionStatus.disconnected);
      
      // These should complete without throwing on both platforms
      expect(() => sshService.cachePassword('test', 'password'), returnsNormally);
      expect(() => sshService.clearPassword('test'), returnsNormally);
      expect(() => sshService.clearAllPasswords(), returnsNormally);
    });

    test('CommandResult works correctly', () {
      const result = CommandResult(
        stdout: 'test output',
        stderr: '',
        exitCode: 0,
        command: 'echo test',
      );

      expect(result.isSuccess, true);
      expect(result.hasError, false);

      const errorResult = CommandResult(
        stdout: '',
        stderr: 'error message',
        exitCode: 1,
        command: 'false',
      );

      expect(errorResult.isSuccess, false);
      expect(errorResult.hasError, true);
    });
  });

  group('Settings Model Tests', () {
    test('AppSettings has correct defaults', () {
      const settings = AppSettings();

      expect(settings.refreshInterval, 30);
      expect(settings.autoRefresh, true);
      expect(settings.showSystemTray, true);
      expect(settings.startMinimized, false);
      expect(settings.themeMode, ThemeMode.system);
      expect(settings.showNotifications, true);
      expect(settings.maxJobsToShow, 100);
      expect(settings.jobStateFilters, isEmpty);
    });

    test('AppSettings copyWith works correctly', () {
      const settings = AppSettings();
      final updated = settings.copyWith(
        refreshInterval: 60,
        autoRefresh: false,
        themeMode: ThemeMode.dark,
      );

      expect(updated.refreshInterval, 60);
      expect(updated.autoRefresh, false);
      expect(updated.themeMode, ThemeMode.dark);
      // Check that other values remain unchanged
      expect(updated.showSystemTray, true);
      expect(updated.maxJobsToShow, 100);
    });

    test('JobFilter isEmpty works correctly', () {
      const emptyFilter = JobFilter();
      const nonEmptyFilter = JobFilter(user: 'test');

      expect(emptyFilter.isEmpty, true);
      expect(emptyFilter.isNotEmpty, false);
      expect(nonEmptyFilter.isEmpty, false);
      expect(nonEmptyFilter.isNotEmpty, true);
    });
  });
}
