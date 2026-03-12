// lib/data/models/savings_goal_model.g.dart
// GENERATED — do not edit manually
part of 'savings_goal_model.dart';

class SavingsGoalModelAdapter extends TypeAdapter<SavingsGoalModel> {
  @override final int typeId = 3;

  @override
  SavingsGoalModel read(BinaryReader reader) {
    final n = reader.readByte();
    final f = <int, dynamic>{
      for (int i = 0; i < n; i++) reader.readByte(): reader.read()
    };
    return SavingsGoalModel()
      ..id           = (f[0] as String)
      ..title        = (f[1] as String)
      ..emoji        = (f[2] as String)
      ..targetAmount = (f[3] as double)
      ..savedAmount  = (f[4] as double)
      ..deadline     = (f[5] as DateTime)
      ..createdAt    = (f[6] as DateTime)
      ..statusIndex  = (f[7] as int)
      ..color        = (f[8] as int);
  }

  @override
  void write(BinaryWriter writer, SavingsGoalModel obj) {
    writer.writeByte(9);
    writer..writeByte(0)..write(obj.id)
          ..writeByte(1)..write(obj.title)
          ..writeByte(2)..write(obj.emoji)
          ..writeByte(3)..write(obj.targetAmount)
          ..writeByte(4)..write(obj.savedAmount)
          ..writeByte(5)..write(obj.deadline)
          ..writeByte(6)..write(obj.createdAt)
          ..writeByte(7)..write(obj.statusIndex)
          ..writeByte(8)..write(obj.color);
  }

  @override bool operator ==(Object other) =>
      identical(this, other) || other is SavingsGoalModelAdapter &&
      runtimeType == other.runtimeType && typeId == other.typeId;
  @override int get hashCode => typeId.hashCode;
}