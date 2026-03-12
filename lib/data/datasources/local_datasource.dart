// lib/data/datasources/local_datasource.dart
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/savings_goal_model.dart';
import '../models/subscription_model.dart';
import '../../domain/entities/savings_goal_entity.dart';
import '../../domain/entities/subscription_entity.dart';
import '../models/transaction_model.dart';
import '../../core/constants/app_constants.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/entities/settings_entity.dart';

class LocalDataSource {
  static final LocalDataSource _instance = LocalDataSource._();
  factory LocalDataSource() => _instance;
  LocalDataSource._();

  late Box<TransactionModel>  _transactionsBox;
  late Box<CategoryModel>     _categoriesBox;
  late Box                    _settingsBox;
  late Box<SavingsGoalModel>  _goalsBox;
  late Box<SubscriptionModel> _subsBox;

  final _uuid = const Uuid();

  // ── Init ──────────────────────────────────────────────────────────────────

  Future<void> init() async {
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(TransactionModelAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(CategoryModelAdapter());
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(SavingsGoalModelAdapter());
    if (!Hive.isAdapterRegistered(4)) Hive.registerAdapter(SubscriptionModelAdapter());

    _transactionsBox = await Hive.openBox<TransactionModel>(AppConstants.transactionsBox);
    _categoriesBox   = await Hive.openBox<CategoryModel>(AppConstants.categoriesBox);
    _settingsBox     = await Hive.openBox(AppConstants.settingsBox);
    _goalsBox        = await Hive.openBox<SavingsGoalModel>('savings_goals_box');
    _subsBox         = await Hive.openBox<SubscriptionModel>('subscriptions_box');

    await _initDefaultCategories();
  }

  Future<void> _initDefaultCategories() async {
    for (final cat in ExpenseCategories.defaults) {
      if (!_categoriesBox.containsKey(cat['id'])) {
        final model = CategoryModel()
          ..id       = cat['id']
          ..label    = cat['label']
          ..icon     = cat['icon']
          ..color    = cat['color']
          ..isExpense = true
          ..isCustom = false;
        await _categoriesBox.put(cat['id'], model);
      } else {
        final existing = _categoriesBox.get(cat['id'])!;
        if (existing.icon != cat['icon']) {
          existing.icon = cat['icon'];
          await existing.save();
        }
      }
    }
    for (final cat in IncomeCategories.defaults) {
      if (!_categoriesBox.containsKey(cat['id'])) {
        final model = CategoryModel()
          ..id       = cat['id']
          ..label    = cat['label']
          ..icon     = cat['icon']
          ..color    = cat['color']
          ..isExpense = false
          ..isCustom = false;
        await _categoriesBox.put(cat['id'], model);
      } else {
        final existing = _categoriesBox.get(cat['id'])!;
        if (existing.icon != cat['icon']) {
          existing.icon = cat['icon'];
          await existing.save();
        }
      }
    }
  }

  // ── TRANSACTIONS ──────────────────────────────────────────────────────────

  Future<String> addTransaction(TransactionEntity entity) async {
    final id    = entity.id.isEmpty ? _uuid.v4() : entity.id;
    final model = TransactionModel.fromEntity(entity.copyWith(id: id));
    await _transactionsBox.put(id, model);
    return id;
  }

  Future<void> updateTransaction(TransactionEntity entity) async {
    await _transactionsBox.put(entity.id, TransactionModel.fromEntity(entity));
  }

  Future<void> deleteTransaction(String id) async {
    await _transactionsBox.delete(id);
  }

  List<TransactionEntity> getAllTransactions() {
    return _transactionsBox.values.map((m) => m.toEntity()).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  List<TransactionEntity> getTransactionsByDateRange(DateTime from, DateTime to) {
    return _transactionsBox.values
        .where((m) =>
            m.date.isAfter(from.subtract(const Duration(seconds: 1))) &&
            m.date.isBefore(to.add(const Duration(seconds: 1))))
        .map((m) => m.toEntity())
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  List<TransactionEntity> searchTransactions(String query) {
    final q = query.toLowerCase();
    return _transactionsBox.values
        .where((m) =>
            m.categoryLabel.toLowerCase().contains(q) ||
            (m.note?.toLowerCase().contains(q) ?? false) ||
            m.amount.toString().contains(q))
        .map((m) => m.toEntity())
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  // ── CATEGORIES ────────────────────────────────────────────────────────────

  List<CategoryEntity> getCategories({bool? isExpense}) {
    var values = _categoriesBox.values.map((m) => m.toEntity());
    if (isExpense != null) values = values.where((c) => c.isExpense == isExpense);
    return values.toList();
  }

  Future<void> saveCategory(CategoryEntity entity) async {
    await _categoriesBox.put(entity.id, CategoryModel.fromEntity(entity));
  }

  Future<void> deleteCategory(String id) async {
    await _categoriesBox.delete(id);
  }

  // ── SETTINGS ──────────────────────────────────────────────────────────────

  SettingsEntity getSettings() {
    return SettingsEntity(
      currencyCode:    _settingsBox.get(AppConstants.currencyKey,        defaultValue: 'XOF'),
      currencySymbol:  _settingsBox.get('currency_symbol',               defaultValue: 'F'),
      currencyName:    _settingsBox.get('currency_name',                 defaultValue: 'Franc CFA'),
      monthlyBudget:   _settingsBox.get(AppConstants.monthlyBudgetKey,   defaultValue: 0.0),
      alertThreshold1: _settingsBox.get(AppConstants.alertThreshold1Key, defaultValue: 50.0),
      alertThreshold2: _settingsBox.get(AppConstants.alertThreshold2Key, defaultValue: 75.0),
      alertThreshold3: _settingsBox.get(AppConstants.alertThreshold3Key, defaultValue: 100.0),
      isDarkMode:      _settingsBox.get(AppConstants.darkModeKey,        defaultValue: false),
      autoBackup:      _settingsBox.get('auto_backup',                   defaultValue: false),
      eveningReminder: _settingsBox.get(AppConstants.eveningReminderKey, defaultValue: true),
      reminderHour:    _settingsBox.get(AppConstants.reminderHourKey,    defaultValue: 20),
      reminderMinute:  _settingsBox.get(AppConstants.reminderMinuteKey,  defaultValue: 30),
      backupEmail:     _settingsBox.get('backup_email'),
    );
  }

  Future<void> saveSettings(SettingsEntity s) async {
    await _settingsBox.putAll({
      AppConstants.currencyKey:          s.currencyCode,
      'currency_symbol':                 s.currencySymbol,
      'currency_name':                   s.currencyName,
      AppConstants.monthlyBudgetKey:     s.monthlyBudget,
      AppConstants.alertThreshold1Key:   s.alertThreshold1,
      AppConstants.alertThreshold2Key:   s.alertThreshold2,
      AppConstants.alertThreshold3Key:   s.alertThreshold3,
      AppConstants.darkModeKey:          s.isDarkMode,
      'auto_backup':                     s.autoBackup,
      AppConstants.eveningReminderKey:   s.eveningReminder,
      AppConstants.reminderHourKey:      s.reminderHour,
      AppConstants.reminderMinuteKey:    s.reminderMinute,
      if (s.backupEmail != null) 'backup_email': s.backupEmail,
    });
  }

  bool isOnboardingDone() =>
      _settingsBox.get(AppConstants.onboardingDoneKey, defaultValue: false);

  Future<void> setOnboardingDone() async =>
      _settingsBox.put(AppConstants.onboardingDoneKey, true);

  // ── EXPORT / IMPORT ───────────────────────────────────────────────────────

  List<Map<String, dynamic>> exportAllAsJson() {
    return _transactionsBox.values.map((m) => {
      'id':            m.id,
      'amount':        m.amount,
      'type':          m.type,
      'categoryId':    m.categoryId,
      'categoryLabel': m.categoryLabel,
      'categoryIcon':  m.categoryIcon,
      'categoryColor': m.categoryColor,
      'note':          m.note,
      'date':          m.date.toIso8601String(),
      'createdAt':     m.createdAt.toIso8601String(),
    }).toList();
  }

  Future<void> importFromJson(List<Map<String, dynamic>> data) async {
    await _transactionsBox.clear();
    for (final item in data) {
      final model = TransactionModel()
        ..id            = item['id']            as String
        ..amount        = (item['amount'] as num).toDouble()
        ..type          = item['type']          as String
        ..categoryId    = item['categoryId']    as String
        ..categoryLabel = item['categoryLabel'] as String
        ..categoryIcon  = item['categoryIcon']  as String
        ..categoryColor = (item['categoryColor'] as num).toInt()
        ..note          = item['note']          as String?
        ..date          = DateTime.parse(item['date'] as String)
        ..createdAt     = DateTime.parse(item['createdAt'] as String);
      await _transactionsBox.put(model.id, model);
    }
  }

  // ── SAVINGS GOALS ─────────────────────────────────────────────────────────

  List<SavingsGoalEntity> getAllGoals() =>
      _goalsBox.values.map((m) => m.toEntity()).toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  Future<void> saveGoal(SavingsGoalEntity goal) async =>
      _goalsBox.put(goal.id, SavingsGoalModel.fromEntity(goal));

  Future<void> deleteGoal(String id) async => _goalsBox.delete(id);

  Future<void> addToGoal(String goalId, double amount) async {
    final model = _goalsBox.get(goalId);
    if (model == null) return;
    model.savedAmount += amount;
    await model.save();
  }

  // ── SUBSCRIPTIONS ─────────────────────────────────────────────────────────

  List<SubscriptionEntity> getAllSubscriptions() =>
      _subsBox.values.map((m) => m.toEntity()).toList()
        ..sort((a, b) => a.nextDueDate.compareTo(b.nextDueDate));

  Future<void> saveSubscription(SubscriptionEntity sub) async =>
      _subsBox.put(sub.id, SubscriptionModel.fromEntity(sub));

  Future<void> deleteSubscription(String id) async => _subsBox.delete(id);

  /// Returns subscriptions due within the next 3 days (or already overdue)
  List<SubscriptionEntity> getDueSubscriptions() {
    final now      = DateTime.now();
    final in3days  = now.add(const Duration(days: 3));
    return _subsBox.values
        .map((m) => m.toEntity())
        .where((s) =>
            s.status == SubStatus.active &&
            s.nextDueDate.isBefore(in3days))
        .toList()
      ..sort((a, b) => a.nextDueDate.compareTo(b.nextDueDate));
  }

  /// Marks a subscription as paid: creates a transaction + advances nextDueDate
  Future<void> paySubscription(
      SubscriptionEntity sub, String currencySymbol) async {
    // 1. Create transaction
    final tx = TransactionModel()
      ..id            = _uuid.v4()
      ..amount        = sub.amount
      ..type          = 'expense'
      ..categoryId    = sub.categoryId
      ..categoryLabel = sub.title
      ..categoryIcon  = sub.categoryIcon
      ..categoryColor = sub.categoryColor
      ..note          = 'Abonnement: ${sub.title}'
      ..date          = DateTime.now()
      ..createdAt     = DateTime.now();
    await _transactionsBox.put(tx.id, tx);

    // 2. Advance nextDueDate
    final model = _subsBox.get(sub.id);
    if (model == null) return;
    final entity  = model.toEntity();
    final updated = entity.copyWith(
        nextDueDate: entity.computeNextDue(entity.nextDueDate));
    _subsBox.put(sub.id, SubscriptionModel.fromEntity(updated));
  }

  // ── ANOMALY DETECTION ─────────────────────────────────────────────────────

  /// Compares this month's spending per category vs the 3-month average.
  /// Returns anomalies where ratio >= 2.0 (ignores amounts < 500).
  List<Map<String, dynamic>> detectAnomalies() {
    final now        = DateTime.now();
    final thisStart  = DateTime(now.year, now.month, 1);
    final thisEnd    = DateTime(now.year, now.month + 1, 1);
    final allTxs     = _transactionsBox.values
        .where((t) => t.type == 'expense')
        .toList();

    // This month spending per category
    final thisMonth = <String, double>{};
    for (final t in allTxs.where(
        (t) => t.date.isAfter(thisStart) && t.date.isBefore(thisEnd))) {
      thisMonth[t.categoryLabel] =
          (thisMonth[t.categoryLabel] ?? 0) + t.amount;
    }

    // Past 3 months spending per category
    final prev3 = <String, List<double>>{};
    for (var i = 1; i <= 3; i++) {
      final mStart = DateTime(now.year, now.month - i, 1);
      final mEnd   = DateTime(now.year, now.month - i + 1, 1);
      final monthMap = <String, double>{};
      for (final t in allTxs.where(
          (t) => t.date.isAfter(mStart) && t.date.isBefore(mEnd))) {
        monthMap[t.categoryLabel] =
            (monthMap[t.categoryLabel] ?? 0) + t.amount;
      }
      for (final e in monthMap.entries) {
        (prev3[e.key] ??= []).add(e.value);
      }
    }

    final anomalies = <Map<String, dynamic>>[];
    for (final cat in thisMonth.keys) {
      final hist = prev3[cat];
      if (hist == null || hist.isEmpty) continue;
      final avg   = hist.reduce((a, b) => a + b) / hist.length;
      if (avg < 500) continue;
      final ratio = thisMonth[cat]! / avg;
      if (ratio >= 2.0) {
        anomalies.add({
          'categoryLabel': cat,
          'thisMonth':     thisMonth[cat]!,
          'average':       avg,
          'ratio':         ratio,
        });
      }
    }
    anomalies.sort((a, b) =>
        (b['ratio'] as double).compareTo(a['ratio'] as double));
    return anomalies;
  }
}