// lib/presentation/providers/app_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/local_datasource.dart';
import '../../data/repositories/repositories.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/entities/settings_entity.dart';
import '../../domain/entities/financial_summary_entity.dart';

// ── INFRASTRUCTURE ────────────────────────────────────────────────────────────

final localDataSourceProvider =
    Provider<LocalDataSource>((ref) => LocalDataSource());

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) =>
    TransactionRepository(ref.read(localDataSourceProvider)));

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) =>
    SettingsRepository(ref.read(localDataSourceProvider)));

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) =>
    CategoryRepository(ref.read(localDataSourceProvider)));

// ── SETTINGS ──────────────────────────────────────────────────────────────────

class SettingsNotifier extends StateNotifier<SettingsEntity> {
  final SettingsRepository _repo;
  SettingsNotifier(this._repo) : super(_repo.get());

  Future<void> update(SettingsEntity settings) async {
    await _repo.save(settings);
    state = settings;
  }

  Future<void> toggleDarkMode() async {
    final updated = state.copyWith(isDarkMode: !state.isDarkMode);
    await _repo.save(updated);
    state = updated;
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsEntity>((ref) =>
        SettingsNotifier(ref.read(settingsRepositoryProvider)));

// ── TRANSACTIONS ──────────────────────────────────────────────────────────────

enum PeriodFilter { today, week, month, year, all }

class TransactionFilter {
  final PeriodFilter period;
  final String? searchQuery;
  final String? categoryId;
  final TransactionType? type;

  const TransactionFilter({
    this.period = PeriodFilter.all,   // Default: show ALL transactions
    this.searchQuery,
    this.categoryId,
    this.type,
  });

  TransactionFilter copyWith({
    PeriodFilter? period,
    String? searchQuery,
    bool clearSearch = false,
    String? categoryId,
    TransactionType? type,
    bool clearType = false,
  }) {
    return TransactionFilter(
      period: period ?? this.period,
      searchQuery: clearSearch ? null : (searchQuery ?? this.searchQuery),
      categoryId: categoryId ?? this.categoryId,
      type: clearType ? null : (type ?? this.type),
    );
  }
}

class TransactionsState {
  final List<TransactionEntity> transactions;
  final TransactionFilter filter;
  final bool isLoading;

  const TransactionsState({
    this.transactions = const [],
    this.filter = const TransactionFilter(),
    this.isLoading = false,
  });

  TransactionsState copyWith({
    List<TransactionEntity>? transactions,
    TransactionFilter? filter,
    bool? isLoading,
  }) {
    return TransactionsState(
      transactions: transactions ?? this.transactions,
      filter: filter ?? this.filter,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class TransactionsNotifier extends StateNotifier<TransactionsState> {
  final TransactionRepository _repo;

  TransactionsNotifier(this._repo) : super(const TransactionsState()) {
    load();
  }

  void load() {
    state = state.copyWith(isLoading: true);
    final txs = _getByFilter(state.filter);
    state = state.copyWith(transactions: txs, isLoading: false);
  }

  List<TransactionEntity> _getByFilter(TransactionFilter f) {
    // 1. Get by period
    List<TransactionEntity> txs;
    switch (f.period) {
      case PeriodFilter.today:
        txs = _repo.getToday();
        break;
      case PeriodFilter.week:
        txs = _repo.getThisWeek();
        break;
      case PeriodFilter.month:
        txs = _repo.getThisMonth();
        break;
      case PeriodFilter.year:
        txs = _repo.getThisYear();
        break;
      case PeriodFilter.all:
      default:
        txs = _repo.getAll();
        break;
    }

    // 2. Apply search WITHIN the period results (not replacing them)
    if (f.searchQuery != null && f.searchQuery!.isNotEmpty) {
      final q = f.searchQuery!.toLowerCase();
      txs = txs.where((t) =>
          t.categoryLabel.toLowerCase().contains(q) ||
          (t.note?.toLowerCase().contains(q) ?? false) ||
          t.amount.toString().contains(q)).toList();
    }

    // 3. Apply type filter
    if (f.type != null) {
      txs = txs.where((t) => t.type == f.type).toList();
    }

    // 4. Apply category filter
    if (f.categoryId != null) {
      txs = txs.where((t) => t.categoryId == f.categoryId).toList();
    }

    return txs;
  }

  void setFilter(TransactionFilter filter) {
    state = state.copyWith(filter: filter);
    load();
  }

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
    StateNotifierProvider<TransactionsNotifier, TransactionsState>((ref) =>
        TransactionsNotifier(ref.read(transactionRepositoryProvider)));

// ── SUMMARY PROVIDERS ─────────────────────────────────────────────────────────
// Use ref.watch(transactionsProvider) to auto-recompute when transactions change

final todaySummaryProvider = Provider<FinancialSummaryEntity>((ref) {
  ref.watch(transactionsProvider); // recompute on any transaction change
  final repo = ref.read(transactionRepositoryProvider);
  final budget = ref.watch(settingsProvider).monthlyBudget;
  return repo.computeSummary(repo.getToday(), budget);
});

final monthlySummaryProvider = Provider<FinancialSummaryEntity>((ref) {
  ref.watch(transactionsProvider);
  final repo = ref.read(transactionRepositoryProvider);
  final budget = ref.watch(settingsProvider).monthlyBudget;
  return repo.computeSummary(repo.getThisMonth(), budget);
});

final weeklySummaryProvider = Provider<FinancialSummaryEntity>((ref) {
  ref.watch(transactionsProvider);
  final repo = ref.read(transactionRepositoryProvider);
  final budget = ref.watch(settingsProvider).monthlyBudget;
  return repo.computeSummary(repo.getThisWeek(), budget);
});

final yearlySummaryProvider = Provider<FinancialSummaryEntity>((ref) {
  ref.watch(transactionsProvider);
  final repo = ref.read(transactionRepositoryProvider);
  final budget = ref.watch(settingsProvider).monthlyBudget;
  return repo.computeSummary(repo.getThisYear(), budget);
});

// ── CATEGORIES ────────────────────────────────────────────────────────────────

final expenseCategoriesProvider = Provider<List<CategoryEntity>>((ref) =>
    ref.read(categoryRepositoryProvider).getAll(isExpense: true));

final incomeCategoriesProvider = Provider<List<CategoryEntity>>((ref) =>
    ref.read(categoryRepositoryProvider).getAll(isExpense: false));