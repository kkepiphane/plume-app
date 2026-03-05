class FinancialSummaryEntity {
  final double totalIncome;
  final double totalExpenses;
  final double balance;
  final double savingsRate;
  final double budgetUsagePercent;
  final Map<String, double> expensesByCategory;
  final Map<String, double> incomeByCategory;
  final List<DailyBalance> dailyBalances;

  const FinancialSummaryEntity({
    required this.totalIncome,
    required this.totalExpenses,
    required this.balance,
    required this.savingsRate,
    required this.budgetUsagePercent,
    required this.expensesByCategory,
    required this.incomeByCategory,
    required this.dailyBalances,
  });

  bool get isSaving => balance >= 0;
  bool get isOverBudget => budgetUsagePercent >= 100;
}

class DailyBalance {
  final DateTime date;
  final double income;
  final double expense;
  final double balance;

  const DailyBalance({
    required this.date,
    required this.income,
    required this.expense,
    required this.balance,
  });
}