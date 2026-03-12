// lib/presentation/pages/savings/savings_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/savings_goal_entity.dart';
import '../../providers/app_providers.dart';

// ── Main Page ─────────────────────────────────────────────────────────────────

class SavingsPage extends ConsumerWidget {
  const SavingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals    = ref.watch(goalsProvider);
    final symbol   = ref.watch(settingsProvider).currencySymbol;
    final active   = goals.where((g) => g.status == GoalStatus.active).toList();
    final achieved = goals.where((g) => g.status == GoalStatus.achieved).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Objectifs d'épargne"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _showAddGoalSheet(context),
          ),
        ],
      ),
      body: goals.isEmpty
          ? _EmptyState(onAdd: () => _showAddGoalSheet(context))
          : ListView(
              padding: const EdgeInsets.only(bottom: 100),
              children: [
                if (active.isNotEmpty) ...[
                  _sectionHeader(context, 'EN COURS', active.length),
                  ...active.map((g) => _GoalCard(
                    goal: g, symbol: symbol,
                    onDeposit: () => _showDepositSheet(context, g, symbol),
                    onEdit:    () => _showEditSheet(context, g),
                    onDelete:  () => _confirmDelete(context, ref, g),
                  )),
                ],
                if (achieved.isNotEmpty) ...[
                  _sectionHeader(context, 'ATTEINTS 🎉', achieved.length),
                  ...achieved.map((g) => _GoalCard(
                    goal: g, symbol: symbol, achieved: true,
                    onDeposit: () {},
                    onEdit:    () {},
                    onDelete:  () => _confirmDelete(context, ref, g),
                  )),
                ],
              ],
            ),
      floatingActionButton: goals.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => _showAddGoalSheet(context),
              icon: const Icon(Icons.add),
              label: const Text('Nouvel objectif'),
            )
          : null,
    );
  }

  Widget _sectionHeader(BuildContext c, String title, int count) {
    final tt = Theme.of(c).textTheme;
    final cs = Theme.of(c).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Row(children: [
        Text(title,
            style: tt.labelSmall?.copyWith(
                fontWeight: FontWeight.w800, letterSpacing: 1.2)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: cs.surfaceVariant,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text('$count', style: tt.labelSmall),
        ),
      ]),
    );
  }

  void _showAddGoalSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => const _GoalFormSheet(),
    );
  }

  void _showEditSheet(BuildContext context, SavingsGoalEntity goal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _GoalFormSheet(existing: goal),
    );
  }

  void _showDepositSheet(
      BuildContext context, SavingsGoalEntity goal, String symbol) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _DepositSheet(goal: goal, symbol: symbol),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, SavingsGoalEntity goal) async {
    final notifier = ref.read(goalsProvider.notifier);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Supprimer l'objectif ?"),
        content: Text('"${goal.title}" sera supprimé définitivement.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (ok == true) notifier.delete(goal.id);
  }
}

// ── Goal Card ─────────────────────────────────────────────────────────────────

class _GoalCard extends StatelessWidget {
  final SavingsGoalEntity goal;
  final String            symbol;
  final bool              achieved;
  final VoidCallback      onDeposit, onEdit, onDelete;

  const _GoalCard({
    required this.goal,
    required this.symbol,
    required this.onDeposit,
    required this.onEdit,
    required this.onDelete,
    this.achieved = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs    = Theme.of(context).colorScheme;
    final tt    = Theme.of(context).textTheme;
    final color = Color(goal.color);
    final pct   = goal.progressPercent / 100;
    final isOverdue = goal.daysLeft < 0;
    final daysStr   = isOverdue
        ? 'Délai dépassé'
        : goal.daysLeft == 0
            ? 'Dernier jour !'
            : '${goal.daysLeft} jours restants';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: [BoxShadow(
            color: color.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
          child: Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(child: Text(goal.emoji,
                  style: const TextStyle(fontSize: 22))),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(goal.title,
                    style: tt.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w800)),
                Text(daysStr, style: TextStyle(
                  fontSize: 12,
                  color: isOverdue
                      ? Colors.red : cs.onSurface.withOpacity(0.5),
                )),
              ],
            )),
            if (!achieved)
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert,
                    color: cs.onSurface.withOpacity(0.4)),
                onSelected: (v) {
                  if (v == 'edit') onEdit();
                  if (v == 'delete') onDelete();
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Modifier')),
                  PopupMenuItem(value: 'delete',
                      child: Text('Supprimer',
                          style: TextStyle(color: Colors.red))),
                ],
              )
            else
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Icon(Icons.check_circle_rounded,
                    color: Colors.green.shade600, size: 28),
              ),
          ]),
        ),

        // Progress
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  RichText(text: TextSpan(
                    style: DefaultTextStyle.of(context).style,
                    children: [
                      TextSpan(
                        text: CurrencyFormatter.formatCompact(
                            goal.savedAmount, symbol),
                        style: TextStyle(fontSize: 18,
                            fontWeight: FontWeight.w800, color: color),
                      ),
                      TextSpan(
                        text: ' / ${CurrencyFormatter.formatCompact(
                            goal.targetAmount, symbol)}',
                        style: TextStyle(fontSize: 13,
                            color: cs.onSurface.withOpacity(0.5)),
                      ),
                    ],
                  )),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${goal.progressPercent.toStringAsFixed(0)}%',
                      style: TextStyle(fontSize: 13,
                          fontWeight: FontWeight.w800, color: color),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: pct.clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: color.withOpacity(0.12),
                  valueColor: AlwaysStoppedAnimation<Color>(
                      achieved ? Colors.green.shade500 : color),
                ),
              ),
              if (!achieved && goal.remaining > 0) ...[
                const SizedBox(height: 8),
                Text(
                  '${CurrencyFormatter.formatCompact(goal.remaining, symbol)} restants'
                  ' · ~${CurrencyFormatter.formatCompact(
                      goal.monthlyNeeded, symbol)}/mois',
                  style: TextStyle(fontSize: 11,
                      color: cs.onSurface.withOpacity(0.45)),
                ),
              ],
            ],
          ),
        ),

        // Deposit button
        if (!achieved)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.tonal(
                onPressed: onDeposit,
                style: FilledButton.styleFrom(
                  backgroundColor: color.withOpacity(0.12),
                  foregroundColor: color,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('+ Déposer',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ),
      ]),
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
        const Text('🎯', style: TextStyle(fontSize: 56)),
        const SizedBox(height: 20),
        Text('Aucun objectif',
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          "Définissez un objectif d'épargne et suivez votre progression.",
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 28),
        ElevatedButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add),
          label: const Text('Créer un objectif'),
          style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 14)),
        ),
      ]),
    ),
  );
}

// ── Deposit Sheet — ConsumerStatefulWidget ────────────────────────────────────
// Utilise son propre ref interne → jamais de "ref after disposed"

class _DepositSheet extends ConsumerStatefulWidget {
  final SavingsGoalEntity goal;
  final String            symbol;
  const _DepositSheet({required this.goal, required this.symbol});

  @override
  ConsumerState<_DepositSheet> createState() => _DepositSheetState();
}

class _DepositSheetState extends ConsumerState<_DepositSheet> {
  final _ctrl = TextEditingController();

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final color = Color(widget.goal.color);
    return Padding(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('Déposer sur "${widget.goal.title}"',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          '${CurrencyFormatter.formatCompact(
              widget.goal.savedAmount, widget.symbol)}'
          ' / ${CurrencyFormatter.formatCompact(
              widget.goal.targetAmount, widget.symbol)}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _ctrl,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Montant',
            suffixText: widget.symbol,
            prefixIcon: const Icon(Icons.savings_outlined),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              final v = double.tryParse(
                  _ctrl.text.replaceAll(',', '.')) ?? 0;
              if (v <= 0) return;
              // Capturer le notifier ET préparer updated AVANT le pop
              final notifier = ref.read(goalsProvider.notifier);
              final updated  = widget.goal.copyWith(
                  savedAmount: widget.goal.savedAmount + v);
              notifier.addSaving(widget.goal.id, v);
              Navigator.pop(context);
              if (updated.isAchieved) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('🎉 Objectif "${widget.goal.title}" atteint !'),
                  backgroundColor: Colors.green.shade700,
                  duration: const Duration(seconds: 4),
                ));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('Déposer',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ),
      ]),
    );
  }
}

// ── Goal Form Sheet — ConsumerStatefulWidget ──────────────────────────────────
// Utilise son propre ref interne → plus de "ref after disposed"

class _GoalFormSheet extends ConsumerStatefulWidget {
  final SavingsGoalEntity? existing;
  const _GoalFormSheet({this.existing});

  @override
  ConsumerState<_GoalFormSheet> createState() => _GoalFormSheetState();
}

class _GoalFormSheetState extends ConsumerState<_GoalFormSheet> {
  final _titleCtrl  = TextEditingController();
  final _targetCtrl = TextEditingController();
  final _savedCtrl  = TextEditingController();
  String   _emoji    = '🎯';
  DateTime _deadline = DateTime.now().add(const Duration(days: 90));
  int      _color    = 0xFF6C63FF;

  static const _emojis = [
    '🎯','📱','🏠','✈️','🚗','💻','📚','👗','🏥','💍','🎓','🌍','🛒','🎮','💰'
  ];
  static const _colors = [
    0xFF6C63FF, 0xFF00BCD4, 0xFF4CAF50, 0xFFFF9800,
    0xFFE91E63, 0xFF9C27B0, 0xFF2196F3, 0xFFFF5722,
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final g = widget.existing!;
      _titleCtrl.text  = g.title;
      _targetCtrl.text = g.targetAmount.toStringAsFixed(0);
      _savedCtrl.text  = g.savedAmount > 0
          ? g.savedAmount.toStringAsFixed(0) : '';
      _emoji    = g.emoji;
      _deadline = g.deadline;
      _color    = g.color;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _targetCtrl.dispose();
    _savedCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title  = _titleCtrl.text.trim();
    final target = double.tryParse(
        _targetCtrl.text.replaceAll(',', '.')) ?? 0;
    final saved  = double.tryParse(
        _savedCtrl.text.replaceAll(',', '.')) ?? 0;
    if (title.isEmpty || target <= 0) return;

    final goal = SavingsGoalEntity(
      id:           widget.existing?.id ?? const Uuid().v4(),
      title:        title,
      emoji:        _emoji,
      targetAmount: target,
      savedAmount:  saved,
      deadline:     _deadline,
      createdAt:    widget.existing?.createdAt ?? DateTime.now(),
      color:        _color,
    );

    // Capture notifier BEFORE any async gap / Navigator.pop
    final notifier = ref.read(goalsProvider.notifier);
    if (widget.existing != null) {
      await notifier.update(goal);
    } else {
      await notifier.add(goal);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Text(
              widget.existing == null ? 'Nouvel objectif' : 'Modifier',
              style: Theme.of(context).textTheme.titleMedium,
            )),
            const SizedBox(height: 20),

            // Emoji picker
            SizedBox(height: 52, child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _emojis.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final e = _emojis[i];
                return GestureDetector(
                  onTap: () => setState(() => _emoji = e),
                  child: Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      color: _emoji == e
                          ? Color(_color).withOpacity(0.15)
                          : Theme.of(context).colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                      border: _emoji == e
                          ? Border.all(color: Color(_color), width: 2)
                          : null,
                    ),
                    child: Center(child: Text(e,
                        style: const TextStyle(fontSize: 22))),
                  ),
                );
              },
            )),
            const SizedBox(height: 16),

            // Color picker
            SizedBox(height: 36, child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _colors.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final c = _colors[i];
                return GestureDetector(
                  onTap: () => setState(() => _color = c),
                  child: Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: Color(c),
                      shape: BoxShape.circle,
                      border: _color == c
                          ? Border.all(color: Colors.white, width: 2)
                          : null,
                      boxShadow: _color == c
                          ? [BoxShadow(
                              color: Color(c).withOpacity(0.5),
                              blurRadius: 6)]
                          : null,
                    ),
                  ),
                );
              },
            )),
            const SizedBox(height: 16),

            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: "Nom de l'objectif",
                hintText: 'Ex: Nouveau téléphone',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _targetCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Montant cible',
                prefixIcon: Icon(Icons.flag_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _savedCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Déjà épargné (optionnel)',
                prefixIcon: Icon(Icons.savings_outlined),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today_outlined),
              title: const Text('Date limite'),
              subtitle: Text(
                  '${_deadline.day}/${_deadline.month}/${_deadline.year}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _deadline,
                  firstDate: DateTime.now().add(const Duration(days: 1)),
                  lastDate: DateTime.now()
                      .add(const Duration(days: 365 * 5)),
                );
                if (d != null) setState(() => _deadline = d);
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(_color),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  widget.existing == null
                      ? "Créer l'objectif" : 'Enregistrer',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}