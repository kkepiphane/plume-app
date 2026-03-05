// lib/core/utils/formatters.dart
import 'package:intl/intl.dart';

class CurrencyFormatter {
  static String format(double amount, String symbol, {bool compact = false}) {
    if (compact && amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M $symbol';
    }
    if (compact && amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K $symbol';
    }
    final formatter = NumberFormat('#,###', 'fr_FR');
    final formatted = formatter.format(amount);
    return '$formatted $symbol';
  }

  static String formatCompact(double amount, String symbol) =>
      format(amount, symbol, compact: true);
}

class DateFormatter {
  static String formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final d = DateTime(date.year, date.month, date.day);

    if (d == today) return "Aujourd'hui";
    if (d == yesterday) return 'Hier';
    return DateFormat('d MMM yyyy', 'fr_FR').format(date);
  }

  static String formatTime(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }

  static String formatDateShort(DateTime date) {
    return DateFormat('d MMM', 'fr_FR').format(date);
  }

  static String formatMonth(DateTime date) {
    return DateFormat('MMMM yyyy', 'fr_FR').format(date);
  }

  static String formatDayOfWeek(DateTime date) {
    return DateFormat('E', 'fr_FR').format(date);
  }
}

class PercentFormatter {
  static String format(double percent) {
    return '${percent.toStringAsFixed(1)}%';
  }
}