// lib/domain/entities/subscription_entity.dart
enum RecurrenceType { daily, weekly, monthly, yearly }
enum SubStatus      { active, paused, cancelled }

class SubscriptionEntity {
  final String         id;
  final String         title;
  final String         categoryId;
  final String         categoryLabel;
  final String         categoryIcon;
  final int            categoryColor;
  final double         amount;
  final RecurrenceType recurrence;
  final int            dayOfMonth;   // 1–28 (for monthly)
  final DateTime       nextDueDate;
  final DateTime       startDate;
  final SubStatus      status;
  final String?        note;

  const SubscriptionEntity({
    required this.id,
    required this.title,
    required this.categoryId,
    required this.categoryLabel,
    required this.categoryIcon,
    required this.categoryColor,
    required this.amount,
    required this.recurrence,
    required this.dayOfMonth,
    required this.nextDueDate,
    required this.startDate,
    this.status = SubStatus.active,
    this.note,
  });

  bool get isDueToday {
    final now = DateTime.now();
    return nextDueDate.year == now.year &&
           nextDueDate.month == now.month &&
           nextDueDate.day == now.day;
  }

  bool get isOverdue => nextDueDate.isBefore(DateTime.now());

  int get daysUntilDue => nextDueDate.difference(DateTime.now()).inDays;

  /// Compute next due date after a given date
  DateTime computeNextDue(DateTime from) {
    switch (recurrence) {
      case RecurrenceType.daily:
        return from.add(const Duration(days: 1));
      case RecurrenceType.weekly:
        return from.add(const Duration(days: 7));
      case RecurrenceType.monthly:
        final next = DateTime(from.year, from.month + 1, dayOfMonth);
        return next;
      case RecurrenceType.yearly:
        return DateTime(from.year + 1, from.month, from.day);
    }
  }

  SubscriptionEntity copyWith({
    String? title, String? categoryId, String? categoryLabel,
    String? categoryIcon, int? categoryColor, double? amount,
    RecurrenceType? recurrence, int? dayOfMonth,
    DateTime? nextDueDate, SubStatus? status, String? note,
  }) => SubscriptionEntity(
    id:            id,
    title:         title         ?? this.title,
    categoryId:    categoryId    ?? this.categoryId,
    categoryLabel: categoryLabel ?? this.categoryLabel,
    categoryIcon:  categoryIcon  ?? this.categoryIcon,
    categoryColor: categoryColor ?? this.categoryColor,
    amount:        amount        ?? this.amount,
    recurrence:    recurrence    ?? this.recurrence,
    dayOfMonth:    dayOfMonth    ?? this.dayOfMonth,
    nextDueDate:   nextDueDate   ?? this.nextDueDate,
    startDate:     startDate,
    status:        status        ?? this.status,
    note:          note          ?? this.note,
  );
}