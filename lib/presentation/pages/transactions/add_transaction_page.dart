// lib/presentation/pages/transactions/add_transaction_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/notification_service.dart';
import '../../../domain/entities/transaction_entity.dart';
import '../../../domain/entities/category_entity.dart';
import '../../providers/app_providers.dart';

class AddTransactionPage extends ConsumerStatefulWidget {
  final bool isExpense;
  final TransactionEntity? transaction;

  const AddTransactionPage({super.key, required this.isExpense, this.transaction});

  @override
  ConsumerState<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends ConsumerState<AddTransactionPage> {
  late bool _isExpense;
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  CategoryEntity? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _isExpense = widget.isExpense;
    if (widget.transaction != null) {
      final tx = widget.transaction!;
      _isExpense = tx.isExpense;
      _amountController.text = tx.amount.toString();
      _noteController.text = tx.note ?? '';
      _selectedDate = tx.date;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  List<CategoryEntity> get _categories => _isExpense
      ? ref.read(expenseCategoriesProvider)
      : ref.read(incomeCategoriesProvider);

  Future<void> _save() async {
    final amountText = _amountController.text.replaceAll(',', '.');
    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer un montant valide')));
      return;
    }
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez choisir une catégorie')));
      return;
    }
    setState(() => _isSaving = true);

    final tx = TransactionEntity(
      id: widget.transaction?.id ?? '',
      amount: amount,
      type: _isExpense ? TransactionType.expense : TransactionType.income,
      categoryId: _selectedCategory!.id,
      categoryLabel: _selectedCategory!.label,
      categoryIcon: _selectedCategory!.icon,
      categoryColor: _selectedCategory!.color,
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      date: _selectedDate,
      createdAt: widget.transaction?.createdAt ?? DateTime.now(),
    );

    if (widget.transaction != null) {
      await ref.read(transactionsProvider.notifier).update(tx);
    } else {
      await ref.read(transactionsProvider.notifier).add(tx);
    }

    // Record that user added a transaction today (for evening reminder)
    await NotificationService().recordTransactionAdded();

    // Budget alert check
    final settings = ref.read(settingsProvider);
    if (settings.monthlyBudget > 0 && _isExpense) {
      final monthly = ref.read(monthlySummaryProvider);
      await NotificationService().checkAndNotifyBudget(
        totalExpenses: monthly.totalExpenses,
        budget: settings.monthlyBudget,
        threshold1: settings.alertThreshold1,
        threshold2: settings.alertThreshold2,
        threshold3: settings.alertThreshold3,
        currencySymbol: settings.currencySymbol,
      );
    }

    if (mounted) {
      HapticFeedback.lightImpact();
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final symbol = settings.currencySymbol;
    final cs = Theme.of(context).colorScheme;
    final primaryColor = _isExpense ? Colors.red.shade600 : Colors.green.shade600;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => context.pop()),
        title: Text(widget.transaction != null
            ? 'Modifier'
            : (_isExpense ? 'Nouvelle dépense' : 'Nouveau revenu')),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: Text('Enregistrer',
                style: TextStyle(color: primaryColor, fontWeight: FontWeight.w700, fontSize: 15)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type Toggle
            if (widget.transaction == null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Container(
                  decoration: BoxDecoration(
                    color: cs.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(child: _TypeToggle(
                        label: 'Dépense',
                        icon: Icons.remove_circle_outline_rounded,
                        selected: _isExpense,
                        activeColor: Colors.red.shade600,
                        onTap: () => setState(() => _isExpense = true),
                      )),
                      Expanded(child: _TypeToggle(
                        label: 'Revenu',
                        icon: Icons.add_circle_outline_rounded,
                        selected: !_isExpense,
                        activeColor: Colors.green.shade600,
                        onTap: () => setState(() => _isExpense = false),
                      )),
                    ],
                  ),
                ),
              ),

            // Amount Input
            Container(
              margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: primaryColor.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Montant',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: primaryColor, letterSpacing: 0.5)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(symbol,
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: primaryColor.withOpacity(0.6))),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                          style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: primaryColor, letterSpacing: -1),
                          decoration: InputDecoration(
                            hintText: '0',
                            hintStyle: TextStyle(color: primaryColor.withOpacity(0.3), fontSize: 36, fontWeight: FontWeight.w800),
                            border: InputBorder.none, enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none, filled: false, contentPadding: EdgeInsets.zero,
                          ),
                          autofocus: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Quick amounts
                  Wrap(
                    spacing: 8,
                    children: ['100', '500', '1000', '2000', '5000', '10000'].map((a) => GestureDetector(
                      onTap: () {
                        _amountController.text = a;
                        HapticFeedback.selectionClick();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        margin: const EdgeInsets.only(bottom: 6),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: primaryColor.withOpacity(0.2)),
                        ),
                        child: Text('$a $symbol',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: primaryColor)),
                      ),
                    )).toList(),
                  ),
                ],
              ),
            ),

            // Category
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Text('Catégorie', style: Theme.of(context).textTheme.titleMedium),
            ),
            SizedBox(
              height: 90,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _categories.length,
                itemBuilder: (context, i) {
                  final cat = _categories[i];
                  final isSelected = _selectedCategory?.id == cat.id;
                  final catColor = Color(cat.color);
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedCategory = cat);
                      HapticFeedback.selectionClick();
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? catColor.withOpacity(0.15) : Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? catColor : Theme.of(context).dividerColor,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(CategoryIcons.get(cat.icon), color: catColor, size: 24),
                          const SizedBox(height: 4),
                          Text(
                            cat.label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? catColor : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Note
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: TextField(
                controller: _noteController,
                decoration: const InputDecoration(
                  hintText: 'Note (optionnelle)',
                  prefixIcon: Icon(Icons.edit_note_rounded),
                ),
                maxLines: 2,
                textInputAction: TextInputAction.done,
              ),
            ),

            // Date
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: GestureDetector(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (date != null && context.mounted) {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(_selectedDate),
                    );
                    setState(() {
                      _selectedDate = DateTime(date.year, date.month, date.day,
                          time?.hour ?? _selectedDate.hour, time?.minute ?? _selectedDate.minute);
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 18),
                      const SizedBox(width: 10),
                      Text(_formatDateTime(_selectedDate),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
                      const Spacer(),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                ),
              ),
            ),

            // Save button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                      : Text(
                          widget.transaction != null ? 'Modifier' : 'Enregistrer',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final months = ['','jan','fév','mar','avr','mai','jun','jul','aoû','sep','oct','nov','déc'];
    final now = DateTime.now();
    final isToday = dt.year == now.year && dt.month == now.month && dt.day == now.day;
    final dayStr = isToday ? "Aujourd'hui" : '${dt.day} ${months[dt.month]}';
    return '$dayStr à ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
  }
}

class _TypeToggle extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color activeColor;
  final VoidCallback onTap;

  const _TypeToggle({required this.label, required this.icon, required this.selected,
      required this.activeColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: selected ? Colors.white : Theme.of(context).colorScheme.onSurface.withOpacity(0.5), size: 18),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(
              color: selected ? Colors.white : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              fontWeight: FontWeight.w600,
            )),
          ],
        ),
      ),
    );
  }
}