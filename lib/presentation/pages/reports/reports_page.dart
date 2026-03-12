// lib/presentation/pages/reports/reports_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/pdf_report_service.dart';
import '../../providers/app_providers.dart';

class ReportsPage extends ConsumerWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final symbol = ref.watch(settingsProvider).currencySymbol;
    final now    = DateTime.now();
    final months = List.generate(12, (i) => DateTime(now.year, now.month - i, 1));

    return Scaffold(
      appBar: AppBar(title: const Text('Rapports PDF')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(children: [
              Icon(Icons.picture_as_pdf_rounded,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  size: 32),
              const SizedBox(width: 14),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Rapports mensuels',
                      style: TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 15,
                        color: Theme.of(context).colorScheme.onPrimaryContainer)),
                  const SizedBox(height: 3),
                  Text(
                    'Générez un PDF avec toutes vos transactions, '
                    'catégories et statistiques.',
                    style: TextStyle(fontSize: 12,
                        color: Theme.of(context).colorScheme.onPrimaryContainer
                            .withOpacity(0.7)),
                  ),
                ],
              )),
            ]),
          ),
          ...months.map((d) => _MonthCard(date: d, symbol: symbol)),
        ],
      ),
    );
  }
}

class _MonthCard extends ConsumerStatefulWidget {
  final DateTime date;
  final String symbol;
  const _MonthCard({required this.date, required this.symbol});
  @override
  ConsumerState<_MonthCard> createState() => _MonthCardState();
}

class _MonthCardState extends ConsumerState<_MonthCard> {
  bool _loading = false;

  Future<void> _generate() async {
    setState(() => _loading = true);
    try {
      await PdfReportService().generateAndShare(
        currencySymbol: widget.symbol,
        year: widget.date.year,
        month: widget.date.month,
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur PDF: $e'),
              backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs  = Theme.of(context).colorScheme;
    final txs = ref.watch(transactionsProvider).where((t) =>
        t.date.year == widget.date.year &&
        t.date.month == widget.date.month).toList();
    final inc = txs.where((t) => t.isIncome)
        .fold<double>(0, (s, t) => s + t.amount);
    final exp = txs.where((t) => t.isExpense)
        .fold<double>(0, (s, t) => s + t.amount);
    final isCurrent = widget.date.month == DateTime.now().month &&
        widget.date.year == DateTime.now().year;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCurrent ? cs.primary.withOpacity(0.4) : Theme.of(context).dividerColor,
          width: isCurrent ? 1.5 : 1,
        ),
      ),
      child: Row(children: [
        Container(
          width: 52, height: 52,
          decoration: BoxDecoration(
            color: isCurrent ? cs.primary.withOpacity(0.1) : cs.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(_fr3(widget.date.month),
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800,
                    color: isCurrent ? cs.primary : cs.onSurfaceVariant)),
            Text(widget.date.year.toString(),
                style: TextStyle(fontSize: 9, color: cs.onSurfaceVariant)),
          ]),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${_frFull(widget.date.month)} ${widget.date.year}',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 4),
          Row(children: [
            _Dot(Colors.green.shade600),
            Text(_compact(inc, widget.symbol),
                style: const TextStyle(fontSize: 11)),
            const SizedBox(width: 10),
            _Dot(Colors.red.shade600),
            Text(_compact(exp, widget.symbol),
                style: const TextStyle(fontSize: 11)),
            const SizedBox(width: 10),
            Text('${txs.length} tx',
                style: TextStyle(fontSize: 11,
                    color: cs.onSurface.withOpacity(0.4))),
          ]),
        ])),
        txs.isEmpty
            ? Text('—', style: TextStyle(color: cs.onSurface.withOpacity(0.3)))
            : _loading
                ? const SizedBox(width: 24, height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.5))
                : IconButton(
                    icon: Icon(Icons.download_rounded, color: cs.primary),
                    tooltip: 'Télécharger PDF',
                    onPressed: _generate,
                  ),
      ]),
    );
  }

  String _fr3(int m) {
    const s = ['','JAN','FÉV','MAR','AVR','MAI','JUN',
                'JUL','AOÛ','SEP','OCT','NOV','DÉC'];
    return s[m];
  }
  String _frFull(int m) {
    const n = ['','Janvier','Février','Mars','Avril','Mai','Juin',
                'Juillet','Août','Septembre','Octobre','Novembre','Décembre'];
    return n[m];
  }
  String _compact(double v, String s) {
    if (v >= 1000000) return '${(v/1000000).toStringAsFixed(1)}M $s';
    if (v >= 1000)    return '${(v/1000).toStringAsFixed(1)}K $s';
    return '${v.toStringAsFixed(0)} $s';
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  const _Dot(this.color);
  @override
  Widget build(BuildContext context) => Container(
    width: 6, height: 6, margin: const EdgeInsets.only(right: 4),
    decoration: BoxDecoration(color: color, shape: BoxShape.circle));
}