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
  final _searchCtrl = TextEditingController();
  bool  _searching  = false;

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final txs      = ref.watch(filteredTransactionsProvider);
    final filter   = ref.watch(transactionFilterProvider);
    final settings = ref.watch(settingsProvider);
    final symbol   = settings.currencySymbol;
    final cs       = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: _searching
            ? TextField(
                controller: _searchCtrl,
                autofocus:  true,
                decoration: const InputDecoration(
                  hintText: 'Rechercher…',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (q) => ref
                    .read(transactionFilterProvider.notifier)
                    .state = filter.copyWith(
                        search: q, clearSearch: q.isEmpty),
              )
            : const Text('Transactions'),
        actions: [
          IconButton(
            icon: Icon(_searching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() => _searching = !_searching);
              if (!_searching) {
                _searchCtrl.clear();
                ref.read(transactionFilterProvider.notifier).state =
                    filter.copyWith(clearSearch: true);
              }
            },
          ),
          IconButton(
            icon: Badge(
              isLabelVisible: filter.type != FilterType.all,
              child: const Icon(Icons.filter_list_rounded),
            ),
            onPressed: () => _showFilterSheet(context, ref, filter),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: _buildPeriodTabs(ref, filter),
        ),
      ),
      body: txs.isEmpty
          ? EmptyState(
              icon:     Icons.receipt_long_outlined,
              title:    'Aucune transaction',
              subtitle: filter.search.isNotEmpty
                  ? 'Aucun résultat pour "${filter.search}"'
                  : 'Ajoutez votre première transaction',
            )
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 100),
              itemCount: _grouped(txs).length,
              itemBuilder: (_, i) {
                final entry = _grouped(txs).entries.elementAt(i);
                return _DateGroup(
                  date: entry.key,
                  transactions: entry.value,
                  symbol: symbol,
                  cs: cs,
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/add-transaction',
            extra: {'isExpense': true}),
        child: const Icon(Icons.add),
      ),
    );
  }

  Map<DateTime, List<TransactionEntity>> _grouped(
      List<TransactionEntity> txs) {
    final map = <DateTime, List<TransactionEntity>>{};
    for (final tx in txs) {
      final day = DateTime(tx.date.year, tx.date.month, tx.date.day);
      (map[day] ??= []).add(tx);
    }
    return Map.fromEntries(
        map.entries.toList()..sort((a, b) => b.key.compareTo(a.key)));
  }

  Widget _buildPeriodTabs(WidgetRef ref, TransactionFilter filter) {
    final cs = Theme.of(context).colorScheme;
    final tabs = [
      (FilterPeriod.today, 'Auj.'),
      (FilterPeriod.week,  'Semaine'),
      (FilterPeriod.month, 'Mois'),
      (FilterPeriod.year,  'Année'),
      (FilterPeriod.all,   'Tout'),
    ];
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        children: tabs.map((tab) {
          final selected = filter.period == tab.$1;
          return GestureDetector(
            onTap: () => ref
                .read(transactionFilterProvider.notifier)
                .state = filter.copyWith(period: tab.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: selected ? cs.primary : cs.surfaceVariant,
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              child: Text(
                tab.$2,
                style: TextStyle(
                  fontSize:   13,
                  fontWeight: FontWeight.w600,
                  color: selected ? cs.onPrimary : cs.onSurfaceVariant,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showFilterSheet(BuildContext context, WidgetRef ref,
      TransactionFilter filter) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Filtrer par type',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            _FilterOption(
              icon:     Icons.list_rounded,
              label:    'Toutes',
              selected: filter.type == FilterType.all,
              onTap: () {
                ref.read(transactionFilterProvider.notifier).state =
                    filter.copyWith(type: FilterType.all);
                Navigator.pop(context);
              },
            ),
            _FilterOption(
              icon:     Icons.arrow_upward_rounded,
              label:    'Dépenses',
              selected: filter.type == FilterType.expense,
              color:    Colors.red,
              onTap: () {
                ref.read(transactionFilterProvider.notifier).state =
                    filter.copyWith(type: FilterType.expense);
                Navigator.pop(context);
              },
            ),
            _FilterOption(
              icon:     Icons.arrow_downward_rounded,
              label:    'Revenus',
              selected: filter.type == FilterType.income,
              color:    Colors.green,
              onTap: () {
                ref.read(transactionFilterProvider.notifier).state =
                    filter.copyWith(type: FilterType.income);
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ── Date group ────────────────────────────────────────────────────────────────
class _DateGroup extends StatelessWidget {
  final DateTime date;
  final List<TransactionEntity> transactions;
  final String symbol;
  final ColorScheme cs;
  const _DateGroup({
    required this.date,
    required this.transactions,
    required this.symbol,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    final dayTotal = transactions.fold<double>(
      0, (s, t) => s + (t.isExpense ? -t.amount : t.amount));

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(DateFormatter.formatDate(date),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700)),
            Text(
              CurrencyFormatter.format(dayTotal.abs(), symbol,
                  compact: false),
              style: TextStyle(
                fontSize:   12,
                fontWeight: FontWeight.w700,
                color: dayTotal >= 0
                    ? Colors.green.shade600
                    : Colors.red.shade600,
              ),
            ),
          ],
        ),
      ),
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Column(
          children: transactions.asMap().entries.map((e) {
            final isLast = e.key == transactions.length - 1;
            return Column(children: [
              _TxRow(tx: e.value, symbol: symbol, cs: cs),
              if (!isLast)
                Divider(height: 1, indent: 64,
                    color: Theme.of(context).dividerColor),
            ]);
          }).toList(),
        ),
      ),
    ]);
  }
}

// ── Transaction row ───────────────────────────────────────────────────────────
class _TxRow extends StatelessWidget {
  final TransactionEntity tx;
  final String symbol;
  final ColorScheme cs;
  const _TxRow({required this.tx, required this.symbol, required this.cs});

  @override
  Widget build(BuildContext context) {
    final catColor = Color(tx.categoryColor);
    final isExp    = tx.isExpense;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => context.push('/add-transaction',
          extra: {'isExpense': isExp, 'transaction': tx}),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          // Icon
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: catColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(CategoryIcons.get(tx.categoryIcon),
                color: catColor, size: 20),
          ),
          const SizedBox(width: 12),
          // Label + note
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx.categoryLabel,
                    style: Theme.of(context).textTheme.titleSmall),
                if (tx.note?.isNotEmpty == true)
                  Text(tx.note!,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          // Amount
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(
              '${isExp ? '-' : '+'}${CurrencyFormatter.format(tx.amount, symbol)}',
              style: TextStyle(
                fontSize:   14,
                fontWeight: FontWeight.w700,
                color: isExp ? Colors.red.shade600 : Colors.green.shade600,
              ),
            ),
            Text(DateFormatter.formatTime(tx.date),
                style: Theme.of(context).textTheme.labelSmall),
          ]),
        ]),
      ),
    );
  }
}

// ── Filter option ─────────────────────────────────────────────────────────────
class _FilterOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final Color? color;
  final VoidCallback onTap;
  const _FilterOption({
    required this.icon, required this.label,
    required this.selected, this.color, required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return ListTile(
      leading: Icon(icon,
          color: selected ? c : Theme.of(context).colorScheme.onSurfaceVariant),
      title: Text(label,
          style: TextStyle(
            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
            color: selected ? c : null,
          )),
      trailing: selected ? Icon(Icons.check_circle, color: c) : null,
      onTap: onTap,
    );
  }
}