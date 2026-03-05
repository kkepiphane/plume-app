// lib/core/utils/notification_service.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );
  }

  Future<void> requestPermission() async {
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  // ── BUDGET ALERTS ─────────────────────────────────────────────────────────

  Future<void> checkAndNotifyBudget({
    required double totalExpenses,
    required double budget,
    required double threshold1,
    required double threshold2,
    required double threshold3,
    required String currencySymbol,
  }) async {
    if (budget <= 0) return;
    final percent = (totalExpenses / budget) * 100;

    String title; String body; int id;

    if (percent >= threshold3) {
      title = 'Budget dépassé !';
      body  = 'Vous avez dépassé votre budget de ${budget.toStringAsFixed(0)} $currencySymbol';
      id    = AppConstants.notifThreshold3Id;
    } else if (percent >= threshold2) {
      title = '${threshold2.toInt()}% du budget atteint';
      body  = 'Dépensé: ${totalExpenses.toStringAsFixed(0)} sur ${budget.toStringAsFixed(0)} $currencySymbol';
      id    = AppConstants.notifThreshold2Id;
    } else if (percent >= threshold1) {
      title = '${threshold1.toInt()}% du budget atteint';
      body  = 'La moitié de votre budget mensuel est utilisée';
      id    = AppConstants.notifThreshold1Id;
    } else {
      return; // below all thresholds
    }

    await _show(id: id, title: title, body: body, channelId: 'budget_alerts', channelName: 'Alertes Budget');
  }

  // ── EVENING REMINDER ──────────────────────────────────────────────────────

  /// Call after every transaction save so we know the user logged today.
  Future<void> recordTransactionAdded() async {
    final prefs  = await SharedPreferences.getInstance();
    final now    = DateTime.now();
    final todayKey = '${now.year}-${now.month}-${now.day}';
    await prefs.setString(AppConstants.lastTransactionDateKey, todayKey);
    // Cancel the reminder since the user already logged
    await _plugin.cancel(AppConstants.notifEveningId);
  }

  /// Called at app resume. Fires the reminder only if:
  ///  1. eveningReminder is enabled
  ///  2. No transaction was added today
  ///  3. Current time is between [reminderHour:reminderMinute] and [reminderHour+1:30]
  Future<void> checkEveningReminder({
    required bool enabled,
    required int reminderHour,
    required int reminderMinute,
  }) async {
    if (!enabled) return;

    final prefs    = await SharedPreferences.getInstance();
    final now      = DateTime.now();
    final todayKey = '${now.year}-${now.month}-${now.day}';
    final lastKey  = prefs.getString(AppConstants.lastTransactionDateKey) ?? '';

    // User already logged today — nothing to do
    if (lastKey == todayKey) return;

    // Only fire within the configurable window (up to 90 min after reminder time)
    final windowStart = DateTime(now.year, now.month, now.day, reminderHour, reminderMinute);
    final windowEnd   = windowStart.add(const Duration(minutes: 90));

    if (now.isAfter(windowStart) && now.isBefore(windowEnd)) {
      await _show(
        id: AppConstants.notifEveningId,
        title: 'Bilan de la journée',
        body: "Vous n'avez pas encore enregistré vos transactions d'aujourd'hui.",
        channelId: 'evening_reminder',
        channelName: 'Rappel du soir',
      );
    }
  }

  // ── INTERNAL ──────────────────────────────────────────────────────────────

  Future<void> _show({
    required int id,
    required String title,
    required String body,
    required String channelId,
    required String channelName,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      channelId, channelName,
      importance: Importance.high,
      priority:   Priority.high,
      showWhen:   true,
    );
    await _plugin.show(id, title, body, NotificationDetails(android: androidDetails));
  }
}