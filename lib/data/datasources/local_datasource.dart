// lib/data/datasources/local_datasource.dart
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction_model.dart';
import '../../core/constants/app_constants.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/entities/settings_entity.dart';

class LocalDataSource {
  static final LocalDataSource _instance = LocalDataSource._();
  factory LocalDataSource() => _instance;
  LocalDataSource._();

  late Box<TransactionModel> _transactionsBox;
  late Box<CategoryModel>    _categoriesBox;
  late Box                   _settingsBox;

  final _uuid = const Uuid();

  Future<void> init() async {
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(TransactionModelAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(CategoryModelAdapter());

    _transactionsBox = await Hive.openBox<TransactionModel>(AppConstants.transactionsBox);
    _categoriesBox   = await Hive.openBox<CategoryModel>(AppConstants.categoriesBox);
    _settingsBox     = await Hive.openBox(AppConstants.settingsBox);

    await _initDefaultCategories();
  }

  Future<void> _initDefaultCategories() async {
    // Always refresh defaults to pick up new/updated icon keys
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
        // Update icon key in case it was wrong before
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
      currencyCode:    _settingsBox.get(AppConstants.currencyKey,          defaultValue: 'XOF'),
      currencySymbol:  _settingsBox.get('currency_symbol',                 defaultValue: 'F'),
      currencyName:    _settingsBox.get('currency_name',                   defaultValue: 'Franc CFA'),
      monthlyBudget:   _settingsBox.get(AppConstants.monthlyBudgetKey,     defaultValue: 0.0),
      alertThreshold1: _settingsBox.get(AppConstants.alertThreshold1Key,   defaultValue: 50.0),
      alertThreshold2: _settingsBox.get(AppConstants.alertThreshold2Key,   defaultValue: 75.0),
      alertThreshold3: _settingsBox.get(AppConstants.alertThreshold3Key,   defaultValue: 100.0),
      isDarkMode:      _settingsBox.get(AppConstants.darkModeKey,          defaultValue: false),
      autoBackup:      _settingsBox.get(AppConstants.autoBackupKey,        defaultValue: false),
      eveningReminder: _settingsBox.get(AppConstants.eveningReminderKey,   defaultValue: true),
      reminderHour:    _settingsBox.get(AppConstants.reminderHourKey,      defaultValue: 20),
      reminderMinute:  _settingsBox.get(AppConstants.reminderMinuteKey,    defaultValue: 30),
      backupEmail:     _settingsBox.get(AppConstants.backupEmailKey),
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
      AppConstants.autoBackupKey:        s.autoBackup,
      AppConstants.eveningReminderKey:   s.eveningReminder,
      AppConstants.reminderHourKey:      s.reminderHour,
      AppConstants.reminderMinuteKey:    s.reminderMinute,
      if (s.backupEmail != null) AppConstants.backupEmailKey: s.backupEmail,
    });
  }

  bool isOnboardingDone() =>
      _settingsBox.get(AppConstants.onboardingDoneKey, defaultValue: false);

  Future<void> setOnboardingDone() async =>
      await _settingsBox.put(AppConstants.onboardingDoneKey, true);

  // ── EXPORT (for email backup) ─────────────────────────────────────────────

  List<Map<String, dynamic>> exportToCsv({DateTime? from, DateTime? to}) {
    List<TransactionModel> txs;
    if (from != null && to != null) {
      txs = _transactionsBox.values
          .where((m) => m.date.isAfter(from) && m.date.isBefore(to))
          .toList();
    } else {
      txs = _transactionsBox.values.toList();
    }
    txs.sort((a, b) => b.date.compareTo(a.date));
    return txs.map((m) => m.toCsv()).toList();
  }

  /// Returns ALL transaction data as JSON for email backup
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

  /// Imports transactions from JSON (used during restore)
  Future<void> importFromJson(List<Map<String, dynamic>> data) async {
    for (final item in data) {
      final model = TransactionModel()
        ..id            = item['id'] as String
        ..amount        = (item['amount'] as num).toDouble()
        ..type          = item['type'] as String
        ..categoryId    = item['categoryId'] as String
        ..categoryLabel = item['categoryLabel'] as String
        ..categoryIcon  = item['categoryIcon'] as String
        ..categoryColor = (item['categoryColor'] as int?) ?? 0xFF00897B
        ..note          = item['note'] as String?
        ..date          = DateTime.parse(item['date'] as String)
        ..createdAt     = DateTime.parse(item['createdAt'] as String);
      await _transactionsBox.put(model.id, model);
    }
  }
}