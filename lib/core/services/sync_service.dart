// lib/core/services/sync_service.dart
//
// Orchestrates the nightly background sync at 2h00.
// Uses WorkManager (Android) for reliable background execution.
//
// The sync task:
//   1. Checks if user is logged in
//   2. Calls DriveBackupService.backup()
//   3. Shows a silent notification on success / error

import 'package:workmanager/workmanager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../constants/app_constants.dart';
import '../services/auth_service.dart';
import '../services/drive_backup_service.dart';

// ── Top-level callback (required by WorkManager — must be top-level) ─────────
@pragma('vm:entry-point')
void workManagerDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    if (taskName == AppConstants.syncTaskName) {
      await _runNightlySync();
    }
    return Future.value(true);
  });
}

Future<void> _runNightlySync() async {
  // Restore session before anything
  final sessionOk = await AuthService().restoreSession();
  if (!sessionOk) return; // not logged in, skip silently

  final error = await DriveBackupService().backup();

  final notif = FlutterLocalNotificationsPlugin();
  await notif.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    ),
  );

  if (error == null) {
    await notif.show(
      AppConstants.notifSyncSuccessId,
      'Plume — Sauvegarde réussie',
      'Vos données ont été sauvegardées sur Google Drive.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'sync_channel', 'Synchronisation',
          importance: Importance.low,
          priority: Priority.low,
          silent: true,
        ),
      ),
    );
  }
  // On error, we stay silent — don't wake the user at 2h for an error
}

// ── SyncService ───────────────────────────────────────────────────────────────

class SyncService {
  static final SyncService _i = SyncService._();
  factory SyncService() => _i;
  SyncService._();

  /// Call once in main.dart BEFORE runApp.
  static Future<void> initialize() async {
    await Workmanager().initialize(
      workManagerDispatcher,
      isInDebugMode: false,
    );
  }

  /// Register the nightly sync task.
  /// Safe to call multiple times — cancels & re-registers.
  Future<void> scheduleNightlySync() async {
    await Workmanager().cancelByUniqueName(AppConstants.syncTaskName);

    // Calculate delay until next 2h00
    final now   = DateTime.now();
    var   next2 = DateTime(now.year, now.month, now.day, AppConstants.syncHour, AppConstants.syncMinute);
    if (now.isAfter(next2)) next2 = next2.add(const Duration(days: 1));
    final delay = next2.difference(now);

    await Workmanager().registerOneOffTask(
      AppConstants.syncTaskName,
      AppConstants.syncTaskName,
      initialDelay: delay,
      constraints: Constraints(
        networkType: NetworkType.connected,   // only when connected
        requiresBatteryNotLow: true,           // don't drain battery
      ),
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );
  }

  /// Cancel the nightly sync (when user logs out).
  Future<void> cancelSync() async {
    await Workmanager().cancelByUniqueName(AppConstants.syncTaskName);
  }

  /// Trigger an immediate manual backup (called from settings).
  Future<String?> backupNow() async {
    return DriveBackupService().backup();
  }

  /// Restore from Drive (called on new phone).
  Future<int> restoreNow() async {
    return DriveBackupService().restore();
  }

  /// Last sync timestamp.
  Future<DateTime?> lastSync() => DriveBackupService().lastSyncTime();
}