// lib/core/utils/export_service.dart
import 'dart:io';
import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/financial_summary_entity.dart';

class ExportService {
  static final ExportService _instance = ExportService._();
  factory ExportService() => _instance;
  ExportService._();

  Future<String> exportToCsv(List<Map<String, dynamic>> data) async {
    final headers = ['ID', 'Montant', 'Type', 'Catégorie', 'Note', 'Date', 'Heure'];
    final rows = <List<dynamic>>[headers];

    for (final row in data) {
      rows.add([
        row['id'] ?? '',
        row['montant'] ?? 0,
        row['type'] ?? '',
        row['categorie'] ?? '',
        row['note'] ?? '',
        row['date'] ?? '',
        row['heure'] ?? '',
      ]);
    }

    final csvData = ListToCsvConverter(fieldDelimiter: ';').convert(rows);
    final dir = await getApplicationDocumentsDirectory();
    final now = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final file = File('${dir.path}/monnaie_export_$now.csv');
    // Write with UTF-8 BOM for Excel compatibility
    final bytes = [0xEF, 0xBB, 0xBF, ...utf8.encode(csvData)];
    await file.writeAsBytes(bytes);
    return file.path;
  }

  Future<void> shareFile(String path) async {
    await Share.shareXFiles(
      [XFile(path)],
      text: 'Export Monnaie - ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
    );
  }

  Future<void> exportAndShare(List<Map<String, dynamic>> data) async {
    final path = await exportToCsv(data);
    await shareFile(path);
  }

  Future<String> generateMonthlyReport(
    FinancialSummaryEntity summary,
    String currencySymbol,
    DateTime month,
  ) async {
    final monthName = DateFormat('MMMM yyyy', 'fr_FR').format(month);
    final buffer = StringBuffer();

    buffer.writeln('RAPPORT MENSUEL - $monthName');
    buffer.writeln('=' * 40);
    buffer.writeln();
    buffer.writeln('RÉSUMÉ FINANCIER');
    buffer.writeln('-' * 20);
    buffer.writeln(
        'Revenus totaux: ${summary.totalIncome.toStringAsFixed(0)} $currencySymbol');
    buffer.writeln(
        'Dépenses totales: ${summary.totalExpenses.toStringAsFixed(0)} $currencySymbol');
    buffer.writeln(
        'Solde: ${summary.balance.toStringAsFixed(0)} $currencySymbol');
    buffer.writeln(
        "Taux d'épargne: ${summary.savingsRate.toStringAsFixed(1)}%");
    buffer.writeln();
    buffer.writeln('DÉPENSES PAR CATÉGORIE');
    buffer.writeln('-' * 20);

    final sortedExpenses = summary.expensesByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    for (final entry in sortedExpenses) {
      final percent = summary.totalExpenses > 0
          ? (entry.value / summary.totalExpenses * 100).toStringAsFixed(1)
          : '0';
      buffer.writeln(
          '${entry.key}: ${entry.value.toStringAsFixed(0)} $currencySymbol ($percent%)');
    }

    buffer.writeln();
    buffer.writeln(
        'Généré par Monnaie App le ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}');

    final dir = await getApplicationDocumentsDirectory();
    final nowStr = DateFormat('yyyy-MM').format(month);
    final file = File('${dir.path}/rapport_mensuel_$nowStr.txt');
    await file.writeAsString(buffer.toString(), encoding: utf8);
    return file.path;
  }
}