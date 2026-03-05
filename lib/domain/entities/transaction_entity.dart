// lib/domain/entities/transaction_entity.dart

enum TransactionType { expense, income }

class TransactionEntity {
  final String id;
  final double amount;
  final TransactionType type;
  final String categoryId;
  final String categoryLabel;
  final String categoryIcon;
  final int categoryColor;   // stored as int (e.g. 0xFF4CAF50)
  final String? note;
  final DateTime date;
  final DateTime createdAt;

  const TransactionEntity({
    required this.id,
    required this.amount,
    required this.type,
    required this.categoryId,
    required this.categoryLabel,
    required this.categoryIcon,
    this.categoryColor = 0xFF00897B,
    this.note,
    required this.date,
    required this.createdAt,
  });

  bool get isExpense => type == TransactionType.expense;
  bool get isIncome  => type == TransactionType.income;

  TransactionEntity copyWith({
    String? id,
    double? amount,
    TransactionType? type,
    String? categoryId,
    String? categoryLabel,
    String? categoryIcon,
    int? categoryColor,
    String? note,
    DateTime? date,
    DateTime? createdAt,
  }) {
    return TransactionEntity(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      categoryLabel: categoryLabel ?? this.categoryLabel,
      categoryIcon: categoryIcon ?? this.categoryIcon,
      categoryColor: categoryColor ?? this.categoryColor,
      note: note ?? this.note,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}