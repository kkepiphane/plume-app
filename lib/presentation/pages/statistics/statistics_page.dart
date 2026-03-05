// lib/presentation/pages/statistics/statistics_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../domain/entities/financial_summary_entity.dart';
import '../../providers/app_providers.dart';

class StatisticsPage extends ConsumerStatefulWidget {
  const StatisticsPage({super.key});

  @override
  ConsumerState<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends ConsumerState<StatisticsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this, initialIndex: 2);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final symbol = ref.watch(settingsProvider).currencySymbol;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistiques'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: cs.primary,
          unselectedLabelColor: cs.onSurface.withOpacity(0.5),
          indicatorColor: cs.primary,
          indicatorWeight: 2,
          tabs: const [
            Tab(text: "Aujourd'hui"),
            Tab(text: 'Semaine'),
            Tab(text: 'Mois'),
            Tab(text: 'Année'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _StatView(summary: ref.watch(todaySummaryProvider), symbol: symbol, period: 'day'),
          _StatView(summary: ref.watch(weeklySummaryProvider), symbol: symbol, period: 'week'),
          _StatView(summary: ref.watch(monthlySummaryProvider), symbol: symbol, period: 'month'),
          _StatView(summary: ref.watch(yearlySummaryProvider), symbol: symbol, period: 'year'),
        ],
      ),
    );
  }
}

class _StatView extends StatelessWidget {
  final FinancialSummaryEntity summary;
  final String symbol;
  final String period;

  const _StatView({required this.summary, required this.symbol, required this.period});

  static const List<Color> _chartColors = [
    Color(0xFF00897B), Color(0xFFFFB300), Color(0xFF1E88E5),
    Color(0xFFE53935), Color(0xFF8E24AA), Color(0xFF00ACC1),
    Color(0xFFFF7043), Color(0xFF43A047),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCards(context),
          if (summary.dailyBalances.isNotEmpty && period != 'day')
            _buildLineChart(context),
          if (summary.expensesByCategory.isNotEmpty)
            _buildExpensePieChart(context),
          if (summary.incomeByCategory.isNotEmpty)
            _buildIncomeBar(context),
          _buildInsightBanner(context),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(children: [
            Expanded(child: _StatCard(label: 'Revenus',
                amount: CurrencyFormatter.format(summary.totalIncome, symbol),
                color: Colors.green.shade700, icon: Icons.arrow_downward_rounded)),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(label: 'Dépenses',
                amount: CurrencyFormatter.format(summary.totalExpenses, symbol),
                color: Colors.red.shade700, icon: Icons.arrow_upward_rounded)),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _StatCard(
                label: 'Solde',
                amount: CurrencyFormatter.format(summary.balance.abs(), symbol),
                color: summary.balance >= 0 ? Colors.green.shade700 : Colors.red.shade700,
                icon: summary.balance >= 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                prefix: summary.balance < 0 ? '-' : '')),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(label: "Taux d'épargne",
                amount: '${summary.savingsRate.toStringAsFixed(1)}%',
                color: Colors.blue.shade700, icon: Icons.savings_rounded)),
          ]),
        ],
      ),
    );
  }

  Widget _buildLineChart(BuildContext context) {
    final balances = summary.dailyBalances;
    if (balances.isEmpty) return const SizedBox.shrink();
    final spots = <FlSpot>[
      for (int i = 0; i < balances.length; i++)
        FlSpot(i.toDouble(), balances[i].expense)
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'ÉVOLUTION DES DÉPENSES'),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(16),
          height: 200,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: LineChart(LineChartData(
            gridData: FlGridData(
              show: true, drawVerticalLine: false,
              getDrawingHorizontalLine: (v) => FlLine(color: Theme.of(context).dividerColor, strokeWidth: 1),
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(sideTitles: SideTitles(
                showTitles: true, reservedSize: 50,
                getTitlesWidget: (v, _) => Text(CurrencyFormatter.formatCompact(v, symbol),
                    style: TextStyle(fontSize: 9, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4))),
              )),
              bottomTitles: AxisTitles(sideTitles: SideTitles(
                showTitles: true,
                interval: (balances.length / 4).ceilToDouble().clamp(1, double.infinity),
                getTitlesWidget: (v, _) {
                  final idx = v.toInt();
                  if (idx >= 0 && idx < balances.length)
                    return Text(DateFormatter.formatDateShort(balances[idx].date),
                        style: TextStyle(fontSize: 9, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4)));
                  return const SizedBox.shrink();
                },
              )),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: Colors.red.shade700,
                barWidth: 2.5,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(show: true, color: Colors.red.withOpacity(0.08)),
              ),
            ],
          )),
        ),
      ],
    );
  }

  Widget _buildExpensePieChart(BuildContext context) {
    final sorted = (summary.expensesByCategory.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)))
        .take(6)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'DÉPENSES PAR CATÉGORIE'),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Column(
            children: [
              SizedBox(
                height: 180,
                child: PieChart(PieChartData(
                  sections: sorted.asMap().entries.map((e) {
                    final pct = summary.totalExpenses > 0
                        ? e.value.value / summary.totalExpenses * 100 : 0.0;
                    return PieChartSectionData(
                      color: _chartColors[e.key % _chartColors.length],
                      value: e.value.value,
                      title: '${pct.toStringAsFixed(0)}%',
                      radius: 70,
                      titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                    );
                  }).toList(),
                  centerSpaceRadius: 20,
                  sectionsSpace: 2,
                )),
              ),
              const SizedBox(height: 16),
              ...sorted.asMap().entries.map((e) {
                final pct = summary.totalExpenses > 0
                    ? (e.value.value / summary.totalExpenses * 100) : 0.0;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(children: [
                    Container(width: 12, height: 12,
                        decoration: BoxDecoration(color: _chartColors[e.key % _chartColors.length], shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(e.value.key, style: Theme.of(context).textTheme.bodyMedium)),
                    Text(CurrencyFormatter.format(e.value.value, symbol),
                        style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(width: 8),
                    SizedBox(width: 36, child: Text('${pct.toStringAsFixed(0)}%',
                        style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.end)),
                  ]),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIncomeBar(BuildContext context) {
    final sorted = (summary.incomeByCategory.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)))
        .take(5)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'REVENUS PAR SOURCE'),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Column(
            children: sorted.asMap().entries.map((e) {
              final pct = summary.totalIncome > 0 ? e.value.value / summary.totalIncome : 0.0;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(children: [
                  Row(children: [
                    Container(width: 10, height: 10,
                        decoration: BoxDecoration(color: _chartColors[e.key % _chartColors.length], shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(e.value.key, style: Theme.of(context).textTheme.bodyMedium)),
                    Text(CurrencyFormatter.format(e.value.value, symbol),
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.green.shade700)),
                  ]),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: pct, minHeight: 4,
                      backgroundColor: Theme.of(context).dividerColor,
                      valueColor: AlwaysStoppedAnimation(_chartColors[e.key % _chartColors.length]),
                    ),
                  ),
                ]),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildInsightBanner(BuildContext context) {
    if (summary.totalIncome == 0 && summary.totalExpenses == 0) return const SizedBox.shrink();
    String message; IconData icon; Color color;

    if (summary.isSaving && summary.savingsRate > 20) {
      message = 'Excellent ! Vous économisez ${summary.savingsRate.toStringAsFixed(0)}% de vos revenus.';
      icon = Icons.emoji_events_rounded; color = Colors.green.shade700;
    } else if (summary.isSaving) {
      message = 'Vous économisez ce mois-ci. Continuez vos efforts !';
      icon = Icons.check_circle_outline_rounded; color = Colors.green.shade700;
    } else if (summary.totalExpenses > summary.totalIncome) {
      message = 'Vos dépenses dépassent vos revenus. Essayez de réduire les dépenses non essentielles.';
      icon = Icons.warning_amber_rounded; color = Colors.red.shade700;
    } else {
      message = 'Enregistrez plus de transactions pour obtenir une analyse précise.';
      icon = Icons.info_outline_rounded; color = Colors.blue.shade700;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: InsightCard(icon: icon, message: message, color: color),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, amount, prefix;
  final Color color;
  final IconData icon;
  const _StatCard({required this.label, required this.amount, required this.color,
      required this.icon, this.prefix = ''});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 10),
          Text('$prefix$amount',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: color, letterSpacing: -0.3),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}