// lib/data/repositories/repositories.dart
import '../../domain/entities/transaction_entity.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/entities/settings_entity.dart';
import '../../domain/entities/financial_summary_entity.dart';
import '../datasources/local_datasource.dart';

class TransactionRepository {
  final LocalDataSource _dataSource;
  TransactionRepository(this._dataSource);

  Future<String> add(TransactionEntity entity) => _dataSource.addTransaction(entity);
  Future<void> update(TransactionEntity entity) => _dataSource.updateTransaction(entity);
  Future<void> delete(String id) => _dataSource.deleteTransaction(id);

  List<TransactionEntity> getAll() => _dataSource.getAllTransactions();

  List<TransactionEntity> getByDateRange(DateTime from, DateTime to) =>
      _dataSource.getTransactionsByDateRange(from, to);

  List<TransactionEntity> search(String query) =>
      _dataSource.searchTransactions(query);

  List<TransactionEntity> getToday() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    return getByDateRange(start, end);
  }

  List<TransactionEntity> getThisWeek() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final start = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    return getByDateRange(start, DateTime.now());
  }

  List<TransactionEntity> getThisMonth() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    return getByDateRange(start, DateTime.now());
  }

  List<TransactionEntity> getThisYear() {
    final now = DateTime.now();
    final start = DateTime(now.year, 1, 1);
    return getByDateRange(start, DateTime.now());
  }

  FinancialSummaryEntity computeSummary(
      List<TransactionEntity> txs, double budget) {
    double totalIncome = 0;
    double totalExpenses = 0;
    final expensesByCategory = <String, double>{};
    final incomeByCategory = <String, double>{};

    for (final tx in txs) {
      if (tx.isExpense) {
        totalExpenses += tx.amount;
        expensesByCategory[tx.categoryLabel] =
            (expensesByCategory[tx.categoryLabel] ?? 0) + tx.amount;
      } else {
        totalIncome += tx.amount;
        incomeByCategory[tx.categoryLabel] =
            (incomeByCategory[tx.categoryLabel] ?? 0) + tx.amount;
      }
    }

    final balance = totalIncome - totalExpenses;
    final savingsRate =
        totalIncome > 0 ? (balance / totalIncome) * 100 : 0.0;
    final budgetUsage =
        budget > 0 ? (totalExpenses / budget) * 100 : 0.0;

    final dailyMap = <String, DailyBalance>{};
    for (final tx in txs) {
      final key =
          '${tx.date.year}-${tx.date.month}-${tx.date.day}';
      final existing = dailyMap[key];
      if (existing == null) {
        dailyMap[key] = DailyBalance(
          date: DateTime(tx.date.year, tx.date.month, tx.date.day),
          income: tx.isIncome ? tx.amount : 0,
          expense: tx.isExpense ? tx.amount : 0,
          balance: tx.isIncome ? tx.amount : -tx.amount,
        );
      } else {
        dailyMap[key] = DailyBalance(
          date: existing.date,
          income: existing.income + (tx.isIncome ? tx.amount : 0),
          expense: existing.expense + (tx.isExpense ? tx.amount : 0),
          balance:
              existing.balance + (tx.isIncome ? tx.amount : -tx.amount),
        );
      }
    }

    final dailyBalances = dailyMap.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    return FinancialSummaryEntity(
      totalIncome: totalIncome,
      totalExpenses: totalExpenses,
      balance: balance,
      savingsRate: savingsRate,
      budgetUsagePercent: budgetUsage,
      expensesByCategory: expensesByCategory,
      incomeByCategory: incomeByCategory,
      dailyBalances: dailyBalances,
    );
  }
}

class SettingsRepository {
  final LocalDataSource _dataSource;
  SettingsRepository(this._dataSource);

  SettingsEntity get() => _dataSource.getSettings();
  Future<void> save(SettingsEntity settings) => _dataSource.saveSettings(settings);
  bool isOnboardingDone() => _dataSource.isOnboardingDone();
  Future<void> setOnboardingDone() => _dataSource.setOnboardingDone();
}

class CategoryRepository {
  final LocalDataSource _dataSource;
  CategoryRepository(this._dataSource);

  List<CategoryEntity> getAll({bool? isExpense}) =>
      _dataSource.getCategories(isExpense: isExpense);

  Future<void> save(CategoryEntity entity) => _dataSource.saveCategory(entity);
  Future<void> delete(String id) => _dataSource.deleteCategory(id);
}