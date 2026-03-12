// lib/presentation/pages/anomalies/anomalies_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/formatters.dart';
import '../../providers/app_providers.dart';

class AnomaliesPage extends ConsumerWidget {
  const AnomaliesPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final anomalies = ref.watch(anomaliesProvider);
    final symbol    = ref.watch(settingsProvider).currencySymbol;
    return Scaffold(
      appBar: AppBar(title: const Text('Depenses inhabituelles')),
      body: anomalies.isEmpty
          ? const _EmptyState()
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const _InfoCard(),
                const SizedBox(height: 12),
                ...anomalies.map((a) =>
                    _AnomalyCard(data: a, symbol: symbol)),
              ],
            ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard();
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        Icon(Icons.info_outline_rounded, color: cs.primary, size: 20),
        const SizedBox(width: 10),
        const Expanded(child: Text(
          'Categories ou vos depenses ce mois-ci depassent '
          '2x votre moyenne des 3 derniers mois.',
          style: TextStyle(fontSize: 12),
        )),
      ]),
    );
  }
}

class _AnomalyCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String symbol;
  const _AnomalyCard({required this.data, required this.symbol});
  @override
  Widget build(BuildContext context) {
    final ratio     = data['ratio']     as double;
    final thisMonth = data['thisMonth'] as double;
    final average   = data['average']   as double;
    final label     = data['categoryLabel'] as String;
    final pct       = ((ratio - 1) * 100).toStringAsFixed(0);
    final Color alertColor = ratio >= 4
        ? Colors.red.shade700
        : ratio >= 3
            ? Colors.deepOrange.shade600
            : Colors.orange.shade600;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: alertColor.withOpacity(0.3), width: 1.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: alertColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.trending_up_rounded, color: alertColor, size: 14),
              const SizedBox(width: 4),
              Text('+$pct%', style: TextStyle(fontSize: 12,
                  fontWeight: FontWeight.w800, color: alertColor)),
            ]),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(label,
              style: Theme.of(context).textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w800))),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _CompareBar(
            label: 'Moy. 3 mois',
            barValue: 1.0 / ratio.clamp(1.0, 10.0),
            amount: CurrencyFormatter.formatCompact(average, symbol),
            barColor: Colors.grey.shade400,
            bg: alertColor.withOpacity(0.08),
          )),
          const SizedBox(width: 16),
          Expanded(child: _CompareBar(
            label: 'Ce mois',
            barValue: 1.0,
            amount: CurrencyFormatter.formatCompact(thisMonth, symbol),
            barColor: alertColor,
            bg: alertColor.withOpacity(0.08),
            bold: true,
          )),
        ]),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: alertColor.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8)),
          child: Text(_advice(label, ratio),
              style: TextStyle(fontSize: 11,
                  color: alertColor.withOpacity(0.8))),
        ),
      ]),
    );
  }

  String _advice(String cat, double r) {
    if (r >= 4) return 'Depenses "$cat" 4x superieures a la normale. Verifiez si une depense exceptionnelle explique cette hausse.';
    if (r >= 3) return 'Depenses "$cat" tres elevees. Reduire dans cette categorie ameliorerait votre epargne.';
    return 'Legere hausse sur "$cat". Restez vigilant pour ne pas depasser votre budget.';
  }
}

class _CompareBar extends StatelessWidget {
  final String label, amount;
  final double barValue;
  final Color barColor, bg;
  final bool bold;
  const _CompareBar({required this.label, required this.barValue,
    required this.amount, required this.barColor, required this.bg,
    this.bold = false});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: Theme.of(context).textTheme.labelSmall),
    const SizedBox(height: 4),
    ClipRRect(borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: barValue, minHeight: 8,
        backgroundColor: bg,
        valueColor: AlwaysStoppedAnimation<Color>(barColor),
      ),
    ),
    const SizedBox(height: 4),
    Text(amount, style: TextStyle(fontSize: 12,
        fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
        color: bold ? barColor : null)),
  ]);
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('ok', style: TextStyle(fontSize: 52)),
        const SizedBox(height: 20),
        Text('Aucune anomalie', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text('Vos depenses sont coherentes avec vos habitudes.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium),
      ]),
    ),
  );
}