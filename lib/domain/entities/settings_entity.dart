// lib/domain/entities/settings_entity.dart

class SettingsEntity {
  final String currencyCode;
  final String currencySymbol;
  final String currencyName;
  final double monthlyBudget;
  final double alertThreshold1;
  final double alertThreshold2;
  final double alertThreshold3;
  final bool isDarkMode;
  final bool autoBackup;
  final bool eveningReminder;
  final int reminderHour;    // 0–23
  final int reminderMinute;  // 0–59
  final String? backupEmail; // email for backup/restore
  final DateTime? lastBackup;

  const SettingsEntity({
    this.currencyCode    = 'XOF',
    this.currencySymbol  = 'F',
    this.currencyName    = 'Franc CFA',
    this.monthlyBudget   = 0,
    this.alertThreshold1 = 50,
    this.alertThreshold2 = 75,
    this.alertThreshold3 = 100,
    this.isDarkMode      = false,
    this.autoBackup      = false,
    this.eveningReminder = true,
    this.reminderHour    = 20,
    this.reminderMinute  = 30,
    this.backupEmail,
    this.lastBackup,
  });

  SettingsEntity copyWith({
    String? currencyCode,
    String? currencySymbol,
    String? currencyName,
    double? monthlyBudget,
    double? alertThreshold1,
    double? alertThreshold2,
    double? alertThreshold3,
    bool? isDarkMode,
    bool? autoBackup,
    bool? eveningReminder,
    int? reminderHour,
    int? reminderMinute,
    String? backupEmail,
    DateTime? lastBackup,
  }) {
    return SettingsEntity(
      currencyCode:    currencyCode    ?? this.currencyCode,
      currencySymbol:  currencySymbol  ?? this.currencySymbol,
      currencyName:    currencyName    ?? this.currencyName,
      monthlyBudget:   monthlyBudget   ?? this.monthlyBudget,
      alertThreshold1: alertThreshold1 ?? this.alertThreshold1,
      alertThreshold2: alertThreshold2 ?? this.alertThreshold2,
      alertThreshold3: alertThreshold3 ?? this.alertThreshold3,
      isDarkMode:      isDarkMode      ?? this.isDarkMode,
      autoBackup:      autoBackup      ?? this.autoBackup,
      eveningReminder: eveningReminder ?? this.eveningReminder,
      reminderHour:    reminderHour    ?? this.reminderHour,
      reminderMinute:  reminderMinute  ?? this.reminderMinute,
      backupEmail:     backupEmail     ?? this.backupEmail,
      lastBackup:      lastBackup      ?? this.lastBackup,
    );
  }
}