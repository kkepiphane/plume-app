// lib/presentation/pages/home/home_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../domain/entities/transaction_entity.dart';
import '../../../domain/entities/financial_summary_entity.dart';
import '../../providers/app_providers.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final txState = ref.watch(transactionsProvider);
    final monthlySummary = ref.watch(monthlySummaryProvider);
    final todaySummary = ref.watch(todaySummaryProvider);
    final symbol = settings.currencySymbol;

    final now = DateTime.now();
    final todayTxs = txState.where((t) =>
        t.date.year == now.year &&
        t.date.month == now.month &&
        t.date.day == now.day).toList();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context, ref),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildBalanceHero(context, monthlySummary, symbol),
                _buildQuickActions(context),
                _buildTodayStats(context, todaySummary, symbol),
                if (settings.monthlyBudget > 0)
                  _buildBudgetSection(context, monthlySummary, symbol, settings.monthlyBudget),
                _buildInsights(context, monthlySummary),
                _buildRecentTransactions(context, todayTxs, symbol),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final hour = now.hour;
    final greeting = hour < 12 ? 'Bonjour' : hour < 17 ? 'Bon après-midi' : 'Bonsoir';

    return SliverAppBar(
      floating: true,
      snap: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(greeting, style: Theme.of(context).textTheme.bodySmall),
          Text(
            DateFormat('EEEE d MMMM', 'fr_FR').format(now),
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search_rounded),
          onPressed: () => context.go('/transactions'),
          tooltip: 'Rechercher',
        ),
      ],
    );
  }

  Widget _buildBalanceHero(BuildContext context, FinancialSummaryEntity summary, String symbol) {
    final isPositive = summary.balance >= 0;
    final primaryColor = isPositive
        ? Theme.of(context).colorScheme.primary
        : Colors.red.shade700;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isPositive
              ? [primaryColor, primaryColor.withOpacity(0.75)]
              : [Colors.red.shade800, Colors.red.shade600],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SOLDE DU MOIS',
            style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5),
          ),
          const SizedBox(height: 8),
          Text(
            CurrencyFormatter.format(summary.balance.abs(), symbol),
            style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w800, letterSpacing: -1),
          ),
          if (!isPositive)
            const Text(
              'Dépenses supérieures aux revenus',
              style: TextStyle(color: Colors.white60, fontSize: 12),
            ),
          const SizedBox(height: 20),
          Row(
            children: [
              _HeroStat(
                label: 'Revenus',
                amount: CurrencyFormatter.formatCompact(summary.totalIncome, symbol),
                icon: Icons.arrow_downward_rounded,
                color: Colors.greenAccent,
              ),
              const SizedBox(width: 24),
              _HeroStat(
                label: 'Dépenses',
                amount: CurrencyFormatter.formatCompact(summary.totalExpenses, symbol),
                icon: Icons.arrow_upward_rounded,
                color: Colors.orangeAccent,
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Épargne ${summary.savingsRate.toStringAsFixed(0)}%',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: _QuickActionButton(
              label: 'Dépense',
              icon: Icons.remove_circle_outline_rounded,
              color: Colors.red.shade600,
              onTap: () => context.push('/add-transaction', extra: {'isExpense': true}),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _QuickActionButton(
              label: 'Revenu',
              icon: Icons.add_circle_outline_rounded,
              color: Colors.green.shade600,
              onTap: () => context.push('/add-transaction', extra: {'isExpense': false}),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _QuickActionButton(
              label: 'Statistiques',
              icon: Icons.bar_chart_rounded,
              color: Colors.blue.shade600,
              onTap: () => context.go('/statistics'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayStats(BuildContext context, FinancialSummaryEntity today, String symbol) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: AmountCard(
              label: "Dépensé aujourd'hui",
              amount: CurrencyFormatter.formatCompact(today.totalExpenses, symbol),
              color: Colors.red.shade600,
              icon: Icons.trending_down_rounded,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AmountCard(
              label: "Gagné aujourd'hui",
              amount: CurrencyFormatter.formatCompact(today.totalIncome, symbol),
              color: Colors.green.shade600,
              icon: Icons.trending_up_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetSection(
      BuildContext context, FinancialSummaryEntity summary, String symbol, double budget) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: BudgetProgressBar(
        percent: summary.budgetUsagePercent,
        spent: CurrencyFormatter.formatCompact(summary.totalExpenses, symbol),
        budget: CurrencyFormatter.formatCompact(budget, symbol),
      ),
    );
  }

  Widget _buildInsights(BuildContext context, FinancialSummaryEntity summary) {
    final widgets = <Widget>[];

    if (summary.isSaving && summary.totalIncome > 0) {
      widgets.add(InsightCard(
        icon: Icons.check_circle_outline_rounded,
        message: 'Vous économisez ${summary.savingsRate.toStringAsFixed(1)}% de vos revenus ce mois-ci.',
        color: Colors.green.shade700,
      ));
    } else if (summary.totalExpenses > summary.totalIncome && summary.totalIncome > 0) {
      widgets.add(InsightCard(
        icon: Icons.warning_amber_rounded,
        message: 'Attention, vos dépenses dépassent vos revenus ce mois-ci.',
        color: Colors.red.shade700,
      ));
    }
    if (summary.isOverBudget) {
      widgets.add(InsightCard(
        icon: Icons.error_outline_rounded,
        message: 'Vous avez dépassé votre budget mensuel !',
        color: Colors.red.shade700,
      ));
    }
    if (widgets.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'ANALYSE'),
        ...widgets,
      ],
    );
  }

  Widget _buildRecentTransactions(
      BuildContext context, List<TransactionEntity> txs, String symbol) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: "TRANSACTIONS D'AUJOURD'HUI",
          trailing: TextButton(
            onPressed: () => context.go('/transactions'),
            child: const Text('Tout voir', style: TextStyle(fontSize: 12)),
          ),
        ),
        if (txs.isEmpty)
          EmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'Aucune transaction',
            subtitle: 'Enregistrez une dépense ou un revenu',
          )
        else
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: txs.take(5).length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                indent: 72,
                color: Theme.of(context).dividerColor,
              ),
              itemBuilder: (context, i) {
                final tx = txs[i];
                final catColor = Color(tx.categoryColor);
                return TransactionListItem(
                  icon: CategoryIcons.get(tx.categoryIcon),
                  categoryLabel: tx.categoryLabel,
                  note: tx.note,
                  amount: CurrencyFormatter.format(tx.amount, symbol),
                  time: DateFormatter.formatTime(tx.date),
                  isExpense: tx.isExpense,
                  categoryColor: catColor,
                );
              },
            ),
          ),
      ],
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String label;
  final String amount;
  final IconData icon;
  final Color color;
  const _HeroStat({required this.label, required this.amount, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
          child: Icon(icon, color: color, size: 14),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
            Text(amount, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
          ],
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _QuickActionButton({required this.label, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}