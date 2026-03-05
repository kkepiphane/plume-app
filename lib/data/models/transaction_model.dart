// lib/data/models/transaction_model.dart
import 'package:hive/hive.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/entities/category_entity.dart';

part 'transaction_model.g.dart';

@HiveType(typeId: 0)
class TransactionModel extends HiveObject {
  @HiveField(0) late String id;
  @HiveField(1) late double amount;
  @HiveField(2) late String type;        // 'expense' | 'income'
  @HiveField(3) late String categoryId;
  @HiveField(4) late String categoryLabel;
  @HiveField(5) late String categoryIcon;
  @HiveField(6) String? note;
  @HiveField(7) late DateTime date;
  @HiveField(8) late DateTime createdAt;
  @HiveField(9) int categoryColor = 0xFF00897B;  // NEW field — default teal

  TransactionModel();

  factory TransactionModel.fromEntity(TransactionEntity entity) {
    return TransactionModel()
      ..id            = entity.id
      ..amount        = entity.amount
      ..type          = entity.type == TransactionType.expense ? 'expense' : 'income'
      ..categoryId    = entity.categoryId
      ..categoryLabel = entity.categoryLabel
      ..categoryIcon  = entity.categoryIcon
      ..categoryColor = entity.categoryColor
      ..note          = entity.note
      ..date          = entity.date
      ..createdAt     = entity.createdAt;
  }

  TransactionEntity toEntity() {
    return TransactionEntity(
      id:            id,
      amount:        amount,
      type:          type == 'expense' ? TransactionType.expense : TransactionType.income,
      categoryId:    categoryId,
      categoryLabel: categoryLabel,
      categoryIcon:  categoryIcon,
      categoryColor: categoryColor,
      note:          note,
      date:          date,
      createdAt:     createdAt,
    );
  }

  Map<String, dynamic> toCsv() => {
    'id':        id,
    'montant':   amount,
    'type':      type == 'expense' ? 'Dépense' : 'Revenu',
    'categorie': categoryLabel,
    'note':      note ?? '',
    'date':      '${date.day}/${date.month}/${date.year}',
    'heure':     '${date.hour.toString().padLeft(2,'0')}:${date.minute.toString().padLeft(2,'0')}',
  };
}

@HiveType(typeId: 1)
class CategoryModel extends HiveObject {
  @HiveField(0) late String id;
  @HiveField(1) late String label;
  @HiveField(2) late String icon;
  @HiveField(3) late int color;
  @HiveField(4) late bool isExpense;
  @HiveField(5) late bool isCustom;

  CategoryModel();

  factory CategoryModel.fromEntity(CategoryEntity entity) {
    return CategoryModel()
      ..id       = entity.id
      ..label    = entity.label
      ..icon     = entity.icon
      ..color    = entity.color
      ..isExpense = entity.isExpense
      ..isCustom = entity.isCustom;
  }

  CategoryEntity toEntity() => CategoryEntity(
    id:       id,
    label:    label,
    icon:     icon,
    color:    color,
    isExpense: isExpense,
    isCustom: isCustom,
  );
}