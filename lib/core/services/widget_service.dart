// lib/core/services/widget_service.dart
//
// Met à jour le widget Android écran d'accueil (2×1) avec :
//   - Solde du mois
//   - Budget restant (si défini)
//   - Total dépenses aujourd'hui
//
// Utilise home_widget ^0.7.0
// Le widget Android natif est dans:
//   android/app/src/main/res/layout/plume_widget.xml
//   android/app/src/main/java/.../PlumeWidgetProvider.kt
//
import 'package:home_widget/home_widget.dart';
import '../../data/datasources/local_datasource.dart';

class WidgetService {
  static final WidgetService _i = WidgetService._();
  factory WidgetService() => _i;
  WidgetService._();

  static const _appGroupId = 'group.plume.widget';
  static const _widgetName = 'PlumeWidgetProvider';

  Future<void> initialize() async {
    await HomeWidget.setAppGroupId(_appGroupId);
  }

  /// Appeler après chaque transaction, et au démarrage de l'app
  Future<void> updateWidget({
    required String currencySymbol,
    required double monthlyBudget,
  }) async {
    try {
      final ds  = LocalDataSource();
      final now = DateTime.now();
      final txs = ds.getAllTransactions();

      // Solde du mois
      final monthTxs = txs.where((t) =>
          t.date.year == now.year && t.date.month == now.month);
      final income   = monthTxs.where((t) => t.isIncome)
          .fold<double>(0, (s, t) => s + t.amount);
      final expenses = monthTxs.where((t) => t.isExpense)
          .fold<double>(0, (s, t) => s + t.amount);
      final balance  = income - expenses;

      // Dépenses aujourd'hui
      final todayTxs = txs.where((t) =>
          t.date.year  == now.year  &&
          t.date.month == now.month &&
          t.date.day   == now.day);
      final todayExp = todayTxs.where((t) => t.isExpense)
          .fold<double>(0, (s, t) => s + t.amount);

      // Budget restant
      final budgetStr = monthlyBudget > 0
          ? _fmt(monthlyBudget - expenses, currencySymbol)
          : null;

      // Push data to Android widget
      await HomeWidget.saveWidgetData<String>(
          'balance', _fmt(balance, currencySymbol));
      await HomeWidget.saveWidgetData<String>(
          'balance_sign', balance >= 0 ? '+' : '');
      await HomeWidget.saveWidgetData<bool>(
          'is_positive', balance >= 0);
      await HomeWidget.saveWidgetData<String>(
          'today_expenses', _fmt(todayExp, currencySymbol));
      await HomeWidget.saveWidgetData<String>(
          'budget_remaining', budgetStr ?? '');
      await HomeWidget.saveWidgetData<bool>(
          'has_budget', monthlyBudget > 0);
      await HomeWidget.saveWidgetData<String>(
          'symbol', currencySymbol);
      await HomeWidget.saveWidgetData<String>(
          'updated_at',
          '${now.hour.toString().padLeft(2,'0')}:${now.minute.toString().padLeft(2,'0')}');

      await HomeWidget.updateWidget(
        androidName: _widgetName,
      );
    } catch (_) {
      // Widget update is non-critical — silently ignore
    }
  }

  String _fmt(double v, String s) {
    final abs = v.abs();
    final sign = v < 0 ? '-' : '';
    if (abs >= 1000000) return '$sign${(abs/1000000).toStringAsFixed(1)}M $s';
    if (abs >= 1000)    return '$sign${(abs/1000).toStringAsFixed(1)}K $s';
    return '$sign${abs.toStringAsFixed(0)} $s';
  }
}