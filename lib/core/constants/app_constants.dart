// lib/core/constants/app_constants.dart
import 'package:flutter/material.dart';

class AppConstants {
  AppConstants._();

  static const String appName = 'Plume';
  static const String appVersion = '1.0.4';

  // ── Hive Boxes ─────────────────────────────────────────────────────────────
  static const String transactionsBox = 'transactions_box';
  static const String settingsBox = 'settings_box';
  static const String categoriesBox = 'categories_box';

  // ── Settings Keys (Hive) ───────────────────────────────────────────────────
  static const String currencyKey = 'currency';
  static const String monthlyBudgetKey = 'monthly_budget';
  static const String alertThreshold1Key = 'alert_threshold_1';
  static const String alertThreshold2Key = 'alert_threshold_2';
  static const String alertThreshold3Key = 'alert_threshold_3';
  static const String darkModeKey = 'dark_mode';
  static const String onboardingDoneKey = 'onboarding_done';
  static const String eveningReminderKey = 'evening_reminder';
  static const String reminderHourKey = 'reminder_hour';
  static const String reminderMinuteKey = 'reminder_minute';
  static const String lastTransactionDateKey = 'last_transaction_date';
  static const String autoBackupKey = 'auto_backup';
  static const String backupEmailKey = 'backup_email';

  // ── Auth / Backup Keys (SharedPreferences) ─────────────────────────────────
  static const String authEmailKey = 'auth_email';
  static const String authUserIdKey = 'auth_user_id';
  static const String driveFileIdKey = 'drive_file_id';
  static const String lastSyncKey = 'last_sync_ts';
  static const String accessTokenKey = 'drive_access_token';
  static const String refreshTokenKey = 'drive_refresh_token';
  static const String tokenExpiryKey = 'drive_token_expiry';

  // ── Background Sync ────────────────────────────────────────────────────────
  static const String syncTaskName = 'plume_nightly_sync';
  static const int syncHour = 2; // 2h du matin
  static const int syncMinute = 0;

  // ── Notification IDs ───────────────────────────────────────────────────────
  static const int notifThreshold1Id = 1001;
  static const int notifThreshold2Id = 1002;
  static const int notifThreshold3Id = 1003;
  static const int notifEveningId = 3001;
  static const int notifSyncSuccessId = 4001;
  static const int notifSyncErrorId = 4002;

  // ── Currencies ─────────────────────────────────────────────────────────────
  static const List<Map<String, String>> supportedCurrencies = [
    {'code': 'XOF', 'symbol': 'F', 'name': 'Franc CFA (BCEAO)'},
    {'code': 'USD', 'symbol': '\$', 'name': 'Dollar américain'},
    {'code': 'EUR', 'symbol': '€', 'name': 'Euro'},
    {'code': 'CNY', 'symbol': '¥', 'name': 'Yuan chinois'},
    {'code': 'GHS', 'symbol': '₵', 'name': 'Cedi ghanéen'},
    {'code': 'XAF', 'symbol': 'F', 'name': 'Franc CFA (BEAC)'},
    {'code': 'GNF', 'symbol': 'FG', 'name': 'Franc guinéen'},
    {'code': 'MAD', 'symbol': 'DH', 'name': 'Dirham marocain'},
    {'code': 'NGN', 'symbol': '₦', 'name': 'Naira nigérian'},
    {'code': 'CUSTOM', 'symbol': '', 'name': 'Devise personnalisée'},
  ];

  static const Duration fastAnim = Duration(milliseconds: 200);
  static const Duration normalAnim = Duration(milliseconds: 350);
}

// ── Categories ────────────────────────────────────────────────────────────────
class ExpenseCategories {
  ExpenseCategories._();
  static const List<Map<String, dynamic>> defaults = [
    // Dépenses quotidiennes
    {
      'id': 'nourriture',
      'label': 'Nourriture',
      'icon': 'food',
      'color': 0xFFFF9800
    },
    {
      'id': 'transport',
      'label': 'Transport',
      'icon': 'transport',
      'color': 0xFF4CAF50
    },
    {
      'id': 'mega',
      'label': 'Méga (Données mobiles)',
      'icon': 'phone',
      'color': 0xFF03A9F4
    },
    {'id': 'wifi', 'label': 'Wifi', 'icon': 'wifi', 'color': 0xFF2196F3},
    {
      'id': 'credit_tel',
      'label': 'Crédit téléphone',
      'icon': 'phone',
      'color': 0xFF00BCD4
    },

    //Dépenses maison
    // {'id': 'loyer', 'label': 'Loyer', 'icon': 'home', 'color': 0xFF9C27B0},
    {
      'id': 'eau_electricite',
      'label': 'Eau / Électricité',
      'icon': 'utilities',
      'color': 0xFFFF5722
    },
    {
      'id': 'gaz',
      'label': 'Gaz / Charbon',
      'icon': 'utilities',
      'color': 0xFFFF7043
    },
    {
      'id': 'maison',
      'label': 'Maison (réparations)',
      'icon': 'home',
      'color': 0xFF795548
    },

    //Dépenses personnelles
    {'id': 'sante', 'label': 'Santé', 'icon': 'health', 'color': 0xFFF44336},
    {
      'id': 'vetements',
      'label': 'Vêtements',
      'icon': 'clothes',
      'color': 0xFF00BCD4
    },
    {
      'id': 'loisirs',
      'label': 'Loisirs',
      'icon': 'leisure',
      'color': 0xFFE91E63
    },
    {
      'id': 'education',
      'label': 'Éducation',
      'icon': 'education',
      'color': 0xFF3F51B5
    },

    //Finances
    {'id': 'dette', 'label': 'Dette', 'icon': 'transfer', 'color': 0xFF6D4C41},
    {
      'id': 'epargne',
      'label': 'Épargne',
      'icon': 'investment',
      'color': 0xFF8BC34A
    },
    {
      'id': 'transfert',
      'label': 'Transfert envoyé',
      'icon': 'transfer',
      'color': 0xFF607D8B
    },
    {'id': 'cadeau', 'label': 'Cadeau', 'icon': 'gift', 'color': 0xFFE91E63},

    // Social
    {
      'id': 'famille',
      'label': 'Famille',
      'icon': 'family',
      'color': 0xFF795548
    },
    {
      'id': 'sorties',
      'label': 'Sorties',
      'icon': 'leisure',
      'color': 0xFF9C27B0
    },
    {
      'id': 'evenements',
      'label': 'Événements (mariage, baptême...)',
      'icon': 'gift',
      'color': 0xFFFFC107
    },
    {
      'id': 'autres_dep',
      'label': 'Autres',
      'icon': 'other',
      'color': 0xFF607D8B
    },
  ];
}

class IncomeCategories {
  IncomeCategories._();
  static const List<Map<String, dynamic>> defaults = [
    {
      'id': 'salaire',
      'label': 'Salaire',
      'icon': 'salary',
      'color': 0xFF4CAF50
    },
    {
      'id': 'transfert',
      'label': 'Transfert reçu',
      'icon': 'transfer',
      'color': 0xFF2196F3
    },
    {
      'id': 'business',
      'label': 'Business',
      'icon': 'business',
      'color': 0xFFFF9800
    },
    {
      'id': 'investissement',
      'label': 'Investissement',
      'icon': 'investment',
      'color': 0xFF9C27B0
    },
    {
      'id': 'freelance',
      'label': 'Freelance',
      'icon': 'freelance',
      'color': 0xFF00BCD4
    },
    {'id': 'cadeau', 'label': 'Cadeau', 'icon': 'gift', 'color': 0xFFE91E63},
    {
      'id': 'autres_rev',
      'label': 'Autres',
      'icon': 'other',
      'color': 0xFF607D8B
    },
  ];
}

class CategoryIcons {
  CategoryIcons._();
  static IconData get(String key) {
    switch (key.trim()) {
      case 'transport':
        return Icons.directions_bus_rounded;
      case 'food':
        return Icons.restaurant_rounded;
      case 'wifi':
        return Icons.wifi_rounded;
      case 'phone':
        return Icons.smartphone_rounded;
      case 'home':
        return Icons.home_rounded;
      case 'health':
        return Icons.local_hospital_rounded;
      case 'leisure':
        return Icons.sports_esports_rounded;
      case 'clothes':
        return Icons.checkroom_rounded;
      case 'education':
        return Icons.school_rounded;
      case 'utilities':
        return Icons.bolt_rounded;
      case 'family':
        return Icons.people_rounded;
      case 'salary':
        return Icons.work_rounded;
      case 'transfer':
        return Icons.swap_horiz_rounded;
      case 'business':
        return Icons.storefront_rounded;
      case 'investment':
        return Icons.trending_up_rounded;
      case 'freelance':
        return Icons.laptop_rounded;
      case 'gift':
        return Icons.card_giftcard_rounded;
      case 'network_wifi':
        return Icons.wifi_rounded;
      case 'school_outlined':
        return Icons.school_rounded;
      case 'famille':
        return Icons.people_rounded;
      case 'other':
      default:
        return Icons.category_rounded;
    }
  }

  static Color color(int v) => Color(v);
}
