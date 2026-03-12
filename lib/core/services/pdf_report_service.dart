// lib/core/services/pdf_report_service.dart
//
// Génère un rapport PDF mensuel propre et le partage via share_plus.
// Dépendances: pdf ^3.11.1, printing ^5.13.1, share_plus
//
import 'dart:io';
import 'package:flutter/material.dart' show Color;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import '../../data/datasources/local_datasource.dart';
import '../../domain/entities/transaction_entity.dart';
import '../utils/formatters.dart';

class PdfReportService {
  static final PdfReportService _i = PdfReportService._();
  factory PdfReportService() => _i;
  PdfReportService._();

  // ── Palette Plume ──────────────────────────────────────────────────────────
  static const _primary   = PdfColor.fromInt(0xFF4A3AFF); // violet Plume
  static const _gold      = PdfColor.fromInt(0xFFFFC107);
  static const _green     = PdfColor.fromInt(0xFF43A047);
  static const _red       = PdfColor.fromInt(0xFFE53935);
  static const _dark      = PdfColor.fromInt(0xFF1A1A2E);
  static const _grey      = PdfColor.fromInt(0xFF9E9E9E);
  static const _lightGrey = PdfColor.fromInt(0xFFF5F5F5);
  static const _white     = PdfColors.white;

  /// Génère et partage le rapport du mois [year]/[month].
  /// Si year/month sont nuls, utilise le mois courant.
  Future<void> generateAndShare({
    required String currencySymbol,
    int? year,
    int? month,
  }) async {
    final now   = DateTime.now();
    final y     = year  ?? now.year;
    final m     = month ?? now.month;
    final start = DateTime(y, m, 1);
    final end   = DateTime(y, m + 1, 1);

    final allTxs = LocalDataSource().getAllTransactions()
        .where((t) => t.date.isAfter(start.subtract(const Duration(seconds: 1)))
            && t.date.isBefore(end))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    final pdf = pw.Document(
      title:   'Rapport Plume — ${_monthName(m)} $y',
      author:  'Plume Finance',
      creator: 'Plume',
    );

    final double income   = allTxs.where((t) => t.isIncome)
        .fold(0, (s, t) => s + t.amount);
    final double expenses = allTxs.where((t) => t.isExpense)
        .fold(0, (s, t) => s + t.amount);
    final double balance  = income - expenses;

    // Category breakdown
    final expByCat = <String, double>{};
    for (final t in allTxs.where((t) => t.isExpense)) {
      expByCat[t.categoryLabel] = (expByCat[t.categoryLabel] ?? 0) + t.amount;
    }
    final incByCat = <String, double>{};
    for (final t in allTxs.where((t) => t.isIncome)) {
      incByCat[t.categoryLabel] = (incByCat[t.categoryLabel] ?? 0) + t.amount;
    }

    final sortedExp = expByCat.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(36),
      header: (_) => _buildHeader(y, m),
      footer: (ctx) => _buildFooter(ctx),
      build: (ctx) => [
        _buildSummaryCards(income, expenses, balance, currencySymbol),
        pw.SizedBox(height: 24),
        if (sortedExp.isNotEmpty) ...[
          _sectionTitle('DÉPENSES PAR CATÉGORIE'),
          pw.SizedBox(height: 8),
          _buildCategoryChart(sortedExp, expenses, currencySymbol),
          pw.SizedBox(height: 24),
        ],
        if (incByCat.isNotEmpty) ...[
          _sectionTitle('REVENUS PAR CATÉGORIE'),
          pw.SizedBox(height: 8),
          _buildCategoryBars(incByCat.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value)),
              income, currencySymbol, isIncome: true),
          pw.SizedBox(height: 24),
        ],
        _sectionTitle('TOUTES LES TRANSACTIONS (${allTxs.length})'),
        pw.SizedBox(height: 8),
        _buildTransactionsTable(allTxs, currencySymbol),
      ],
    ));

    // Save + share
    final dir  = await getTemporaryDirectory();
    final path = '${dir.path}/plume_${_monthName(m).toLowerCase()}_$y.pdf';
    final file = File(path);
    await file.writeAsBytes(await pdf.save());

    await Share.shareXFiles(
      [XFile(path, mimeType: 'application/pdf')],
      subject:
          'Rapport Plume — ${_monthName(m)} $y',
      text: 'Rapport financier Plume du mois de ${_monthName(m)} $y.',
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  pw.Widget _buildHeader(int year, int month) => pw.Container(
    padding: const pw.EdgeInsets.only(bottom: 12),
    decoration: const pw.BoxDecoration(
      border: pw.Border(bottom: pw.BorderSide(color: _primary, width: 2)),
    ),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text('✦ PLUME',
              style: pw.TextStyle(
                fontSize: 18, fontWeight: pw.FontWeight.bold,
                color: _primary)),
          pw.Text('Rapport financier mensuel',
              style: pw.TextStyle(fontSize: 10, color: _grey)),
        ]),
        pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
          pw.Text('${_monthName(month)} $year',
              style: pw.TextStyle(
                fontSize: 14, fontWeight: pw.FontWeight.bold,
                color: _dark)),
          pw.Text(
            DateFormat('Généré le d MMMM yyyy', 'fr_FR')
                .format(DateTime.now()),
            style: pw.TextStyle(fontSize: 9, color: _grey)),
        ]),
      ],
    ),
  );

  // ── Footer ─────────────────────────────────────────────────────────────────
  pw.Widget _buildFooter(pw.Context ctx) => pw.Container(
    padding: const pw.EdgeInsets.only(top: 8),
    decoration: const pw.BoxDecoration(
      border: pw.Border(top: pw.BorderSide(color: _lightGrey))),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text('Plume Finance — Confidentiel',
            style: pw.TextStyle(fontSize: 8, color: _grey)),
        pw.Text('Page ${ctx.pageNumber} / ${ctx.pagesCount}',
            style: pw.TextStyle(fontSize: 8, color: _grey)),
      ],
    ),
  );

  // ── Summary Cards ──────────────────────────────────────────────────────────
  pw.Widget _buildSummaryCards(double income, double expenses,
      double balance, String symbol) {
    final isPos = balance >= 0;
    return pw.Row(children: [
      _summaryCard('REVENUS', income, symbol, _green),
      pw.SizedBox(width: 12),
      _summaryCard('DÉPENSES', expenses, symbol, _red),
      pw.SizedBox(width: 12),
      _summaryCard('SOLDE', balance, symbol,
          isPos ? _green : _red, isBold: true),
    ]);
  }

  pw.Widget _summaryCard(String label, double amount,
      String symbol, PdfColor color, {bool isBold = false}) {
    return pw.Expanded(child: pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: isBold ? color : PdfColors.white,
        border: pw.Border.all(color: color, width: isBold ? 0 : 1.5),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: pw.TextStyle(
            fontSize: 8, fontWeight: pw.FontWeight.bold,
            color: isBold ? _white : _grey, letterSpacing: 1.2)),
          pw.SizedBox(height: 6),
          pw.Text(
            CurrencyFormatter.format(amount.abs(), symbol),
            style: pw.TextStyle(
              fontSize: 15, fontWeight: pw.FontWeight.bold,
              color: isBold ? _white : color)),
        ],
      ),
    ));
  }

  // ── Category chart (horizontal bar) ───────────────────────────────────────
  pw.Widget _buildCategoryChart(List<MapEntry<String, double>> cats,
      double total, String symbol) {
    return pw.Column(children: cats.take(8).map((e) {
      final pct = total > 0 ? e.value / total : 0.0;
      return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 6),
        child: pw.Row(children: [
          pw.SizedBox(width: 130,
              child: pw.Text(e.key,
                  style: pw.TextStyle(fontSize: 10),
                  maxLines: 1)),
          pw.SizedBox(width: 8),
          pw.Expanded(child: pw.Stack(children: [
            pw.Container(height: 14,
                decoration: pw.BoxDecoration(
                  color: _lightGrey,
                  borderRadius: const pw.BorderRadius.all(
                      pw.Radius.circular(4)))),
            pw.Container(
              height: 14,
              width: pct * 200,
              decoration: pw.BoxDecoration(
                color: _red,
                borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(4))),
            ),
          ])),
          pw.SizedBox(width: 8),
          pw.SizedBox(width: 90,
              child: pw.Text(
                CurrencyFormatter.formatCompact(e.value, symbol),
                style: pw.TextStyle(
                    fontSize: 10, fontWeight: pw.FontWeight.bold),
                textAlign: pw.TextAlign.right)),
          pw.SizedBox(width: 42,
              child: pw.Text(
                '${(pct * 100).toStringAsFixed(1)}%',
                style: pw.TextStyle(
                    fontSize: 9, color: _grey),
                textAlign: pw.TextAlign.right)),
        ]),
      );
    }).toList());
  }

  pw.Widget _buildCategoryBars(List<MapEntry<String, double>> cats,
      double total, String symbol, {bool isIncome = false}) =>
      _buildCategoryChart(cats, total, symbol);

  // ── Transactions table ─────────────────────────────────────────────────────
  pw.Widget _buildTransactionsTable(
      List<TransactionEntity> txs, String symbol) {
    final headers = ['Date', 'Catégorie', 'Note', 'Type', 'Montant'];
    final rows = txs.take(100).map((t) => [
      DateFormat('dd/MM/yyyy').format(t.date),
      t.categoryLabel,
      t.note ?? '',
      t.isExpense ? 'Dépense' : 'Revenu',
      '${t.isExpense ? '-' : '+'}${CurrencyFormatter.formatCompact(t.amount, symbol)}',
    ]).toList();

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: rows,
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold, fontSize: 9,
        color: _white),
      headerDecoration: const pw.BoxDecoration(color: _primary),
      cellStyle: pw.TextStyle(fontSize: 9),
      rowDecoration: const pw.BoxDecoration(color: _white),
      oddRowDecoration: const pw.BoxDecoration(color: _lightGrey),
      columnWidths: {
        0: const pw.FixedColumnWidth(70),
        1: const pw.FixedColumnWidth(90),
        2: const pw.FlexColumnWidth(),
        3: const pw.FixedColumnWidth(55),
        4: const pw.FixedColumnWidth(80),
      },
      cellAlignments: {
        4: pw.Alignment.centerRight,
      },
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  pw.Widget _sectionTitle(String t) => pw.Text(t,
      style: pw.TextStyle(
        fontSize: 11, fontWeight: pw.FontWeight.bold,
        color: _primary, letterSpacing: 1.1));

  String _monthName(int m) {
    const names = [
      '', 'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre',
    ];
    return names[m.clamp(1, 12)];
  }
}