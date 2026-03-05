// lib/presentation/pages/transactions/transactions_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../domain/entities/transaction_entity.dart';
import '../../providers/app_providers.dart';

class TransactionsPage extends ConsumerStatefulWidget {
  const TransactionsPage({super.key});

  @override
  ConsumerState<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends ConsumerState<TransactionsPage> {
  final _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final txState = ref.watch(transactionsProvider);
    final settings = ref.watch(settingsProvider);
    final symbol = settings.currencySymbol;
    final grouped = _groupByDate(txState.transactions);

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Rechercher...',
                  border: InputBorder.none, enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none, filled: false, contentPadding: EdgeInsets.zero,
                ),
                onChanged: (q) {
                  ref.read(transactionsProvider.notifier).setFilter(
                    txState.filter.copyWith(searchQuery: q.isEmpty ? null : q, clearSearch: q.isEmpty),
                  );
                },
              )
            : const Text('Transactions'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search_rounded),
            onPressed: () {
              setState(() => _isSearching = !_isSearching);
              if (!_isSearching) {
                _searchController.clear();
                ref.read(transactionsProvider.notifier).setFilter(
                  txState.filter.copyWith(clearSearch: true),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            onPressed: () => _showFilterSheet(context, ref, txState),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildPeriodTabs(ref, txState),
          Expanded(
            child: txState.transactions.isEmpty
                ? EmptyState(
                    icon: Icons.inbox_outlined,
                    title: 'Aucune transaction',
                    subtitle: txState.filter.searchQuery != null
                        ? 'Aucun résultat pour "${txState.filter.searchQuery}"'
                        : 'Commencez par ajouter une transaction',
                    onAction: () => context.push('/add-transaction', extra: {'isExpense': true}),
                    actionLabel: 'Ajouter',
                  )
                : ListView.builder(
                    itemCount: grouped.length,
                    itemBuilder: (context, i) {
                      final entry = grouped.entries.elementAt(i);
                      return _DateGroup(
                        date: entry.key,
                        transactions: entry.value,
                        symbol: symbol,
                        onTap: (tx) => context.push('/add-transaction',
                            extra: {'isExpense': tx.isExpense, 'transaction': tx}),
                        onDelete: (tx) => _confirmDelete(context, ref, tx),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/add-transaction', extra: {'isExpense': true}),
        icon: const Icon(Icons.add),
        label: const Text('Ajouter'),
      ),
    );
  }

  Widget _buildPeriodTabs(WidgetRef ref, TransactionsState state) {
    final periods = [
      (PeriodFilter.today, "Auj."),
      (PeriodFilter.week, "Semaine"),
      (PeriodFilter.month, "Mois"),
      (PeriodFilter.year, "Année"),
      (PeriodFilter.all, "Tout"),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: periods.map((p) {
          final isSelected = state.filter.period == p.$1;
          return GestureDetector(
            onTap: () => ref.read(transactionsProvider.notifier)
                .setFilter(state.filter.copyWith(period: p.$1)),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).dividerColor,
                ),
              ),
              child: Text(
                p.$2,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? Colors.white
                      : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Map<String, List<TransactionEntity>> _groupByDate(List<TransactionEntity> txs) {
    final grouped = <String, List<TransactionEntity>>{};
    for (final tx in txs) {
      final key = DateFormatter.formatDate(tx.date);
      grouped.putIfAbsent(key, () => []).add(tx);
    }
    return grouped;
  }

  void _showFilterSheet(BuildContext context, WidgetRef ref, TransactionsState state) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Filtrer par type', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            Row(
              children: [
                _FilterChip(label: 'Tout', icon: Icons.list_rounded,
                    isSelected: state.filter.type == null,
                    onTap: () { ref.read(transactionsProvider.notifier).setFilter(state.filter.copyWith(clearType: true)); Navigator.pop(context); }),
                const SizedBox(width: 8),
                _FilterChip(label: 'Dépenses', icon: Icons.arrow_upward_rounded,
                    isSelected: state.filter.type == TransactionType.expense,
                    onTap: () { ref.read(transactionsProvider.notifier).setFilter(state.filter.copyWith(type: TransactionType.expense)); Navigator.pop(context); }),
                const SizedBox(width: 8),
                _FilterChip(label: 'Revenus', icon: Icons.arrow_downward_rounded,
                    isSelected: state.filter.type == TransactionType.income,
                    onTap: () { ref.read(transactionsProvider.notifier).setFilter(state.filter.copyWith(type: TransactionType.income)); Navigator.pop(context); }),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, TransactionEntity tx) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer la transaction'),
        content: Text('Supprimer "${tx.categoryLabel}" — ${tx.amount} ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(transactionsProvider.notifier).delete(tx.id);
    }
  }
}

// ── Date Group ────────────────────────────────────────────────────────────────

class _DateGroup extends StatelessWidget {
  final String date;
  final List<TransactionEntity> transactions;
  final String symbol;
  final Function(TransactionEntity) onTap;
  final Function(TransactionEntity) onDelete;

  const _DateGroup({
    required this.date, required this.transactions,
    required this.symbol, required this.onTap, required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    double dayTotal = 0;
    for (final tx in transactions) {
      dayTotal += tx.isExpense ? -tx.amount : tx.amount;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(date.toUpperCase(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700, letterSpacing: 0.5)),
              Text(
                '${dayTotal >= 0 ? '+' : ''}${dayTotal.toStringAsFixed(0)} $symbol',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: dayTotal >= 0 ? Colors.green.shade700 : Colors.red.shade700,
                ),
              ),
            ],
          ),
        ),
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
            itemCount: transactions.length,
            separatorBuilder: (_, __) =>
                Divider(height: 1, indent: 72, color: Theme.of(context).dividerColor),
            itemBuilder: (context, i) {
              final tx = transactions[i];
              return Dismissible(
                key: Key(tx.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: i == 0
                        ? const BorderRadius.vertical(top: Radius.circular(16))
                        : i == transactions.length - 1
                            ? const BorderRadius.vertical(bottom: Radius.circular(16))
                            : BorderRadius.zero,
                  ),
                  child: const Icon(Icons.delete_outline, color: Colors.red),
                ),
                confirmDismiss: (_) async { onDelete(tx); return false; },
                child: TransactionListItem(
                  icon: CategoryIcons.get(tx.categoryIcon),
                  categoryLabel: tx.categoryLabel,
                  note: tx.note,
                  amount: '${tx.amount.toStringAsFixed(0)} $symbol',
                  time: DateFormatter.formatTime(tx.date),
                  isExpense: tx.isExpense,
                  categoryColor: Color(tx.categoryColor),
                  onTap: () => onTap(tx),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.icon, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primary.withOpacity(0.1) : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? primary : Theme.of(context).dividerColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isSelected ? primary : Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                color: isSelected ? primary : Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
          ],
        ),
      ),
    );
  }
}