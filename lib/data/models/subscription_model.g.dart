// lib/data/models/subscription_model.g.dart
part of 'subscription_model.dart';

class SubscriptionModelAdapter extends TypeAdapter<SubscriptionModel> {
  @override final int typeId = 4;

  @override
  SubscriptionModel read(BinaryReader reader) {
    final n = reader.readByte();
    final f = <int, dynamic>{
      for (int i = 0; i < n; i++) reader.readByte(): reader.read()
    };
    return SubscriptionModel()
      ..id              = (f[0]  as String)
      ..title           = (f[1]  as String)
      ..categoryId      = (f[2]  as String)
      ..categoryLabel   = (f[3]  as String)
      ..categoryIcon    = (f[4]  as String)
      ..categoryColor   = (f[5]  as int)
      ..amount          = (f[6]  as double)
      ..recurrenceIndex = (f[7]  as int)
      ..dayOfMonth      = (f[8]  as int)
      ..nextDueDate     = (f[9]  as DateTime)
      ..startDate       = (f[10] as DateTime)
      ..statusIndex     = (f[11] as int)
      ..note            = (f[12] as String?);
  }

  @override
  void write(BinaryWriter writer, SubscriptionModel obj) {
    writer.writeByte(13);
    writer..writeByte(0)..write(obj.id)
          ..writeByte(1)..write(obj.title)
          ..writeByte(2)..write(obj.categoryId)
          ..writeByte(3)..write(obj.categoryLabel)
          ..writeByte(4)..write(obj.categoryIcon)
          ..writeByte(5)..write(obj.categoryColor)
          ..writeByte(6)..write(obj.amount)
          ..writeByte(7)..write(obj.recurrenceIndex)
          ..writeByte(8)..write(obj.dayOfMonth)
          ..writeByte(9)..write(obj.nextDueDate)
          ..writeByte(10)..write(obj.startDate)
          ..writeByte(11)..write(obj.statusIndex)
          ..writeByte(12)..write(obj.note);
  }

  @override bool operator ==(Object other) =>
      identical(this, other) || other is SubscriptionModelAdapter &&
      runtimeType == other.runtimeType && typeId == other.typeId;
  @override int get hashCode => typeId.hashCode;
}