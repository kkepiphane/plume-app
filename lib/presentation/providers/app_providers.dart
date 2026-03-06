// lib/presentation/providers/app_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/sync_service.dart';
import '../../data/datasources/local_datasource.dart';
import '../../data/repositories/repositories.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/entities/settings_entity.dart';
import '../../domain/entities/financial_summary_entity.dart';

// ── Repositories ──────────────────────────────────────────────────────────────
final transactionRepositoryProvider = Provider((ref) =>
    TransactionRepository(LocalDataSource()));
final categoryRepositoryProvider = Provider((ref) =>
    CategoryRepository(LocalDataSource()));
final settingsRepositoryProvider = Provider((ref) =>
    SettingsRepository(LocalDataSource()));

// ── Auth state ────────────────────────────────────────────────────────────────
final authStateProvider = StateProvider<bool>((ref) => AuthService().isLoggedIn);

// ── Settings ──────────────────────────────────────────────────────────────────
class SettingsNotifier extends StateNotifier<SettingsEntity> {
  final SettingsRepository _repo;
  SettingsNotifier(this._repo) : super(_repo.get());

  Future<void> update(SettingsEntity s) async {
    await _repo.save(s);
    state = s;
  }

  Future<void> toggleDarkMode() async {
    final s = state.copyWith(isDarkMode: !state.isDarkMode);
    await _repo.save(s);
    state = s;
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsEntity>(
  (ref) => SettingsNotifier(ref.read(settingsRepositoryProvider)),
);

// ── Transactions ──────────────────────────────────────────────────────────────
class TransactionsNotifier extends StateNotifier<List<TransactionEntity>> {
  final TransactionRepository _repo;
  TransactionsNotifier(this._repo) : super([]) { load(); }

  void load() => state = _repo.getAll();

  Future<void> add(TransactionEntity tx) async {
    await _repo.add(tx);
    load();
  }

  Future<void> update(TransactionEntity tx) async {
    await _repo.update(tx);
    load();
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    load();
  }
}

final transactionsProvider =
    StateNotifierProvider<TransactionsNotifier, List<TransactionEntity>>(
  (ref) => TransactionsNotifier(ref.read(transactionRepositoryProvider)),
);

// ── Categories ────────────────────────────────────────────────────────────────
final expenseCategoriesProvider = Provider<List<CategoryEntity>>((ref) =>
    ref.read(categoryRepositoryProvider).getAll(isExpense: true));
final incomeCategoriesProvider = Provider<List<CategoryEntity>>((ref) =>
    ref.read(categoryRepositoryProvider).getAll(isExpense: false));

// ── Transaction Filter ────────────────────────────────────────────────────────
enum FilterPeriod { today, week, month, year, all }
enum FilterType   { all, expense, income }

class TransactionFilter {
  final FilterPeriod period;
  final FilterType   type;
  final String       search;
  final String?      categoryId;

  const TransactionFilter({
    this.period     = FilterPeriod.all,
    this.type       = FilterType.all,
    this.search     = '',
    this.categoryId,
  });

  TransactionFilter copyWith({
    FilterPeriod? period,
    FilterType?   type,
    String?       search,
    String?       categoryId,
    bool          clearSearch    = false,
    bool          clearCategory  = false,
  }) => TransactionFilter(
    period:     period     ?? this.period,
    type:       type       ?? this.type,
    search:     clearSearch    ? '' : (search     ?? this.search),
    categoryId: clearCategory  ? null : (categoryId ?? this.categoryId),
  );
}

final transactionFilterProvider =
    StateProvider<TransactionFilter>((ref) => const TransactionFilter());

// ── Filtered transactions ─────────────────────────────────────────────────────
final filteredTransactionsProvider = Provider<List<TransactionEntity>>((ref) {
  final all    = ref.watch(transactionsProvider);
  final filter = ref.watch(transactionFilterProvider);
  return _applyFilter(all, filter);
});

List<TransactionEntity> _applyFilter(
    List<TransactionEntity> all, TransactionFilter f) {
  final now   = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  // 1. Period
  List<TransactionEntity> result;
  switch (f.period) {
    case FilterPeriod.today:
      result = all.where((t) => t.date.isAfter(today)).toList();
    case FilterPeriod.week:
      result = all.where((t) =>
          t.date.isAfter(today.subtract(const Duration(days: 7)))).toList();
    case FilterPeriod.month:
      result = all.where((t) =>
          t.date.year == now.year && t.date.month == now.month).toList();
    case FilterPeriod.year:
      result = all.where((t) => t.date.year == now.year).toList();
    case FilterPeriod.all:
      result = List.from(all);
  }

  // 2. Search (within period)
  if (f.search.isNotEmpty) {
    final q = f.search.toLowerCase();
    result = result.where((t) =>
        t.categoryLabel.toLowerCase().contains(q) ||
        (t.note?.toLowerCase().contains(q) ?? false) ||
        t.amount.toString().contains(q)).toList();
  }

  // 3. Type
  if (f.type == FilterType.expense) result = result.where((t) => t.isExpense).toList();
  if (f.type == FilterType.income)  result = result.where((t) => t.isIncome).toList();

  // 4. Category
  if (f.categoryId != null) {
    result = result.where((t) => t.categoryId == f.categoryId).toList();
  }

  return result;
}

// ── Summaries ─────────────────────────────────────────────────────────────────
final todaySummaryProvider = Provider<FinancialSummaryEntity>((ref) {
  final txs   = ref.watch(transactionsProvider);
  final now   = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  return _buildSummary(txs.where((t) => t.date.isAfter(today)).toList());
});

final weeklySummaryProvider = Provider<FinancialSummaryEntity>((ref) {
  final txs = ref.watch(transactionsProvider);
  final now = DateTime.now();
  final weekAgo = DateTime(now.year, now.month, now.day)
      .subtract(const Duration(days: 7));
  return _buildSummary(txs.where((t) => t.date.isAfter(weekAgo)).toList());
});

final monthlySummaryProvider = Provider<FinancialSummaryEntity>((ref) {
  final txs = ref.watch(transactionsProvider);
  final now = DateTime.now();
  return _buildSummary(txs.where((t) =>
      t.date.year == now.year && t.date.month == now.month).toList());
});

final yearlySummaryProvider = Provider<FinancialSummaryEntity>((ref) {
  final txs = ref.watch(transactionsProvider);
  final now = DateTime.now();
  return _buildSummary(txs.where((t) => t.date.year == now.year).toList());
});

final allTimeSummaryProvider = Provider<FinancialSummaryEntity>((ref) {
  return _buildSummary(ref.watch(transactionsProvider));
});

FinancialSummaryEntity _buildSummary(List<TransactionEntity> txs) {
  double expenses = 0, income = 0;
  final expCat  = <String, double>{};
  final incCat  = <String, double>{};
  final byDay   = <String, DailyBalance>{};

  for (final t in txs) {
    if (t.isExpense) {
      expenses += t.amount;
      expCat[t.categoryLabel] = (expCat[t.categoryLabel] ?? 0) + t.amount;
    } else {
      income += t.amount;
      incCat[t.categoryLabel] = (incCat[t.categoryLabel] ?? 0) + t.amount;
    }
    final dayKey = '${t.date.year}-${t.date.month}-${t.date.day}';
    final prev   = byDay[dayKey];
    byDay[dayKey] = DailyBalance(
      date:    DateTime(t.date.year, t.date.month, t.date.day),
      income:  (prev?.income  ?? 0) + (t.isIncome  ? t.amount : 0),
      expense: (prev?.expense ?? 0) + (t.isExpense ? t.amount : 0),
      balance: (prev?.balance ?? 0) + (t.isIncome  ? t.amount : -t.amount),
    );
  }

  final dailyList = byDay.values.toList()
    ..sort((a, b) => a.date.compareTo(b.date));

  final savingsRate = income > 0
      ? ((income - expenses) / income * 100).clamp(0.0, 100.0)
      : 0.0;

  return FinancialSummaryEntity(
    totalExpenses:       expenses,
    totalIncome:         income,
    balance:             income - expenses,
    savingsRate:         savingsRate,
    budgetUsagePercent:  0.0, // computed in UI with budget setting
    expensesByCategory:  expCat,
    incomeByCategory:    incCat,
    dailyBalances:       dailyList,
  );
}

// ── Last sync time (for settings display) ────────────────────────────────────
final lastSyncProvider = FutureProvider<DateTime?>((ref) =>
    SyncService().lastSync());