// lib/presentation/pages/subscriptions/subscriptions_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/subscription_entity.dart';
import '../../../domain/entities/category_entity.dart';
import '../../providers/app_providers.dart';

class SubscriptionsPage extends ConsumerWidget {
  const SubscriptionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subs   = ref.watch(subscriptionsProvider);
    final symbol = ref.watch(settingsProvider).currencySymbol;
    final active = subs.where((s) => s.status == SubStatus.active).toList();
    final paused = subs.where((s) => s.status == SubStatus.paused).toList();
    final monthlyTotal = ref.watch(monthlySubscriptionCostProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Abonnements'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _SubFormSheet.show(context, ref),
          ),
        ],
      ),
      body: subs.isEmpty
          ? _EmptyState(onAdd: () => _SubFormSheet.show(context, ref))
          : ListView(
              padding: const EdgeInsets.only(bottom: 100),
              children: [
                // Monthly cost summary
                _MonthlySummaryCard(total: monthlyTotal, symbol: symbol),

                if (active.isNotEmpty) ...[
                  _header(context, 'ACTIFS'),
                  ...active.map((s) => _SubCard(
                    sub: s, symbol: symbol,
                    onPay:    () => _pay(context, ref, s),
                    onToggle: () => ref.read(subscriptionsProvider.notifier)
                        .update(s.copyWith(status: SubStatus.paused)),
                    onDelete: () => _delete(context, ref, s),
                    onEdit:   () => _SubFormSheet.show(context, ref, existing: s),
                  )),
                ],
                if (paused.isNotEmpty) ...[
                  _header(context, 'EN PAUSE'),
                  ...paused.map((s) => _SubCard(
                    sub: s, symbol: symbol, paused: true,
                    onPay:    () {},
                    onToggle: () => ref.read(subscriptionsProvider.notifier)
                        .update(s.copyWith(status: SubStatus.active)),
                    onDelete: () => _delete(context, ref, s),
                    onEdit:   () => _SubFormSheet.show(context, ref, existing: s),
                  )),
                ],
              ],
            ),
      floatingActionButton: subs.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => _SubFormSheet.show(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Nouvel abonnement'),
            )
          : null,
    );
  }

  Widget _header(BuildContext c, String t) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
    child: Text(t, style: Theme.of(c).textTheme.labelSmall?.copyWith(
        fontWeight: FontWeight.w800, letterSpacing: 1.2)),
  );

  Future<void> _pay(BuildContext context, WidgetRef ref,
      SubscriptionEntity sub) async {
    await ref.read(subscriptionsProvider.notifier).pay(sub);
    if (context.mounted)
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('✓ ${sub.title} payé et enregistré'),
        backgroundColor: Colors.green.shade700,
      ));
  }

  Future<void> _delete(BuildContext context, WidgetRef ref,
      SubscriptionEntity sub) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer l\'abonnement ?'),
        content: Text('"${sub.title}" sera supprimé.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (ok == true) ref.read(subscriptionsProvider.notifier).delete(sub.id);
  }
}

// ── Monthly Summary Card ──────────────────────────────────────────────────────
class _MonthlySummaryCard extends StatelessWidget {
  final double total;
  final String symbol;
  const _MonthlySummaryCard({required this.total, required this.symbol});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        Icon(Icons.repeat_rounded, color: cs.onPrimaryContainer, size: 28),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Coût mensuel estimé',
                style: TextStyle(fontSize: 12, color: cs.onPrimaryContainer)),
            Text(
              CurrencyFormatter.format(total, symbol),
              style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.w800,
                color: cs.onPrimaryContainer),
            ),
          ],
        )),
      ]),
    );
  }
}

// ── Sub Card ──────────────────────────────────────────────────────────────────
class _SubCard extends StatelessWidget {
  final SubscriptionEntity sub;
  final String symbol;
  final bool paused;
  final VoidCallback onPay, onToggle, onDelete, onEdit;

  const _SubCard({
    required this.sub, required this.symbol,
    required this.onPay, required this.onToggle,
    required this.onDelete, required this.onEdit,
    this.paused = false,
  });

  String get _recurrenceLabel {
    switch (sub.recurrence) {
      case RecurrenceType.daily:   return 'Quotidien';
      case RecurrenceType.weekly:  return 'Hebdomadaire';
      case RecurrenceType.monthly: return 'Mensuel';
      case RecurrenceType.yearly:  return 'Annuel';
    }
  }

  @override
  Widget build(BuildContext context) {
    final catColor = Color(sub.categoryColor);
    final isDue    = sub.isDueToday || sub.isOverdue;
    final daysLeft = sub.daysUntilDue;
    final dueStr   = sub.isOverdue
        ? 'En retard !'
        : sub.isDueToday
            ? 'Dû aujourd\'hui'
            : 'Dans $daysLeft jours';

    return Opacity(
      opacity: paused ? 0.55 : 1.0,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDue && !paused
                ? Colors.orange.withOpacity(0.5)
                : Theme.of(context).dividerColor,
            width: isDue && !paused ? 1.5 : 1,
          ),
        ),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: catColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12)),
            child: Icon(CategoryIcons.get(sub.categoryIcon),
                color: catColor, size: 22),
          ),
          title: Text(sub.title,
              style: Theme.of(context).textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          subtitle: Text(
            '$_recurrenceLabel · $dueStr',
            style: TextStyle(
              fontSize: 12,
              color: isDue && !paused ? Colors.orange : null),
          ),
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            Column(mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(
                CurrencyFormatter.format(sub.amount, symbol),
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w800),
              ),
              if (isDue && !paused)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6)),
                  child: Text(
                    sub.isOverdue ? 'EN RETARD' : 'PAYER',
                    style: const TextStyle(
                        fontSize: 9, fontWeight: FontWeight.w800,
                        color: Colors.orange),
                  ),
                ),
            ]),
            const SizedBox(width: 4),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert,
                  size: 20,
                  color: Theme.of(context)
                      .colorScheme.onSurface.withOpacity(0.4)),
              onSelected: (v) {
                if (v == 'pay')    onPay();
                if (v == 'toggle') onToggle();
                if (v == 'edit')   onEdit();
                if (v == 'delete') onDelete();
              },
              itemBuilder: (_) => [
                if (!paused) const PopupMenuItem(
                    value: 'pay',
                    child: Text('Marquer comme payé')),
                PopupMenuItem(
                    value: 'toggle',
                    child: Text(paused ? 'Réactiver' : 'Mettre en pause')),
                const PopupMenuItem(value: 'edit',
                    child: Text('Modifier')),
                const PopupMenuItem(value: 'delete',
                    child: Text('Supprimer',
                        style: TextStyle(color: Colors.red))),
              ],
            ),
          ]),
        ),
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('🔄', style: TextStyle(fontSize: 56)),
        const SizedBox(height: 20),
        Text('Aucun abonnement',
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          'Ajoutez vos dépenses récurrentes : loyer, mobile, streaming...',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 28),
        ElevatedButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add),
          label: const Text('Ajouter un abonnement'),
          style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 14)),
        ),
      ]),
    ),
  );
}

// ── Sub Form Sheet ────────────────────────────────────────────────────────────
class _SubFormSheet extends StatefulWidget {
  final SubscriptionEntity? existing;
  final WidgetRef ref;
  const _SubFormSheet({this.existing, required this.ref});

  static void show(BuildContext context, WidgetRef ref,
      {SubscriptionEntity? existing}) {
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _SubFormSheet(existing: existing, ref: ref),
    );
  }

  @override
  State<_SubFormSheet> createState() => _SubFormSheetState();
}

class _SubFormSheetState extends State<_SubFormSheet> {
  final _titleCtrl  = TextEditingController();
  final _amountCtrl = TextEditingController();
  RecurrenceType _recurrence  = RecurrenceType.monthly;
  int _dayOfMonth = DateTime.now().day;
  CategoryEntity? _category;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final s = widget.existing!;
      _titleCtrl.text  = s.title;
      _amountCtrl.text = s.amount.toStringAsFixed(0);
      _recurrence      = s.recurrence;
      _dayOfMonth      = s.dayOfMonth;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose(); _amountCtrl.dispose(); super.dispose();
  }

  String _recLabel(RecurrenceType r) {
    switch (r) {
      case RecurrenceType.daily:   return 'Quotidien';
      case RecurrenceType.weekly:  return 'Hebdomadaire';
      case RecurrenceType.monthly: return 'Mensuel';
      case RecurrenceType.yearly:  return 'Annuel';
    }
  }

  Future<void> _save() async {
    final title  = _titleCtrl.text.trim();
    final amount = double.tryParse(
        _amountCtrl.text.replaceAll(',', '.')) ?? 0;
    if (title.isEmpty || amount <= 0 || _category == null) return;

    final now      = DateTime.now();
    DateTime nextDue;
    if (_recurrence == RecurrenceType.monthly) {
      nextDue = DateTime(now.year, now.month, _dayOfMonth);
      if (nextDue.isBefore(now)) {
        nextDue = DateTime(now.year, now.month + 1, _dayOfMonth);
      }
    } else {
      nextDue = now;
    }

    final sub = SubscriptionEntity(
      id:            widget.existing?.id ?? const Uuid().v4(),
      title:         title,
      categoryId:    _category!.id,
      categoryLabel: _category!.label,
      categoryIcon:  _category!.icon,
      categoryColor: _category!.color,
      amount:        amount,
      recurrence:    _recurrence,
      dayOfMonth:    _dayOfMonth,
      nextDueDate:   nextDue,
      startDate:     widget.existing?.startDate ?? now,
    );

    if (widget.existing != null) {
      await widget.ref.read(subscriptionsProvider.notifier).update(sub);
    } else {
      await widget.ref.read(subscriptionsProvider.notifier).add(sub);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final cats = widget.ref.read(expenseCategoriesProvider);
    final cs   = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Text(
            widget.existing == null ? 'Nouvel abonnement' : 'Modifier',
            style: Theme.of(context).textTheme.titleMedium)),
          const SizedBox(height: 20),

          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(
              labelText: 'Nom',
              hintText: 'Ex: Abonnement mobile'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Montant',
              prefixIcon: Icon(Icons.payment_rounded)),
          ),
          const SizedBox(height: 16),

          Text('Catégorie', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          SizedBox(height: 50, child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: cats.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final cat   = cats[i];
              final sel   = _category?.id == cat.id;
              final color = Color(cat.color);
              return GestureDetector(
                onTap: () => setState(() => _category = cat),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: sel
                        ? color.withOpacity(0.15)
                        : cs.surfaceVariant,
                    borderRadius: BorderRadius.circular(24),
                    border: sel ? Border.all(
                        color: color, width: 1.5) : null,
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(CategoryIcons.get(cat.icon),
                        color: sel ? color : cs.onSurfaceVariant,
                        size: 16),
                    const SizedBox(width: 6),
                    Text(cat.label,
                        style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600,
                          color: sel ? color : cs.onSurfaceVariant)),
                  ]),
                ),
              );
            },
          )),
          const SizedBox(height: 16),

          Text('Fréquence', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Row(children: RecurrenceType.values.map((r) {
            final sel = _recurrence == r;
            return Expanded(child: Padding(
              padding: const EdgeInsets.only(right: 6),
              child: GestureDetector(
                onTap: () => setState(() => _recurrence = r),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: sel
                        ? cs.primary.withOpacity(0.1) : cs.surfaceVariant,
                    borderRadius: BorderRadius.circular(10),
                    border: sel ? Border.all(color: cs.primary) : null,
                  ),
                  child: Center(child: Text(_recLabel(r),
                      style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w700,
                        color: sel ? cs.primary : cs.onSurfaceVariant))),
                ),
              ),
            ));
          }).toList()),

          if (_recurrence == RecurrenceType.monthly) ...[
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_month_outlined),
              title: const Text('Jour du prélèvement'),
              subtitle: Text('Le $_dayOfMonth du mois'),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: () => setState(() =>
                      _dayOfMonth = (_dayOfMonth - 1).clamp(1, 28)),
                ),
                Text('$_dayOfMonth',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () => setState(() =>
                      _dayOfMonth = (_dayOfMonth + 1).clamp(1, 28)),
                ),
              ]),
            ),
          ],

          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14)),
              child: Text(
                widget.existing == null
                    ? 'Ajouter l\'abonnement' : 'Enregistrer',
                style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      )),
    );
  }
}