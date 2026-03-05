// lib/data/models/transaction_model.g.dart
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_model.dart';

class TransactionModelAdapter extends TypeAdapter<TransactionModel> {
  @override
  final int typeId = 0;

  @override
  TransactionModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TransactionModel()
      ..id            = fields[0] as String
      ..amount        = fields[1] as double
      ..type          = fields[2] as String
      ..categoryId    = fields[3] as String
      ..categoryLabel = fields[4] as String
      ..categoryIcon  = fields[5] as String
      ..note          = fields[6] as String?
      ..date          = fields[7] as DateTime
      ..createdAt     = fields[8] as DateTime
      ..categoryColor = (fields[9] as int?) ?? 0xFF00897B;  // safe for old records
  }

  @override
  void write(BinaryWriter writer, TransactionModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)  ..write(obj.id)
      ..writeByte(1)  ..write(obj.amount)
      ..writeByte(2)  ..write(obj.type)
      ..writeByte(3)  ..write(obj.categoryId)
      ..writeByte(4)  ..write(obj.categoryLabel)
      ..writeByte(5)  ..write(obj.categoryIcon)
      ..writeByte(6)  ..write(obj.note)
      ..writeByte(7)  ..write(obj.date)
      ..writeByte(8)  ..write(obj.createdAt)
      ..writeByte(9)  ..write(obj.categoryColor);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;

  @override
  int get hashCode => typeId.hashCode;
}

class CategoryModelAdapter extends TypeAdapter<CategoryModel> {
  @override
  final int typeId = 1;

  @override
  CategoryModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CategoryModel()
      ..id        = fields[0] as String
      ..label     = fields[1] as String
      ..icon      = fields[2] as String
      ..color     = fields[3] as int
      ..isExpense = fields[4] as bool
      ..isCustom  = fields[5] as bool;
  }

  @override
  void write(BinaryWriter writer, CategoryModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0) ..write(obj.id)
      ..writeByte(1) ..write(obj.label)
      ..writeByte(2) ..write(obj.icon)
      ..writeByte(3) ..write(obj.color)
      ..writeByte(4) ..write(obj.isExpense)
      ..writeByte(5) ..write(obj.isCustom);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;

  @override
  int get hashCode => typeId.hashCode;
}