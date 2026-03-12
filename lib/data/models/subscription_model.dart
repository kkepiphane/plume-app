// lib/data/models/subscription_model.dart
import 'package:hive/hive.dart';
import '../../domain/entities/subscription_entity.dart';

part 'subscription_model.g.dart';

@HiveType(typeId: 4)
class SubscriptionModel extends HiveObject {
  @HiveField(0)  late String id;
  @HiveField(1)  late String title;
  @HiveField(2)  late String categoryId;
  @HiveField(3)  late String categoryLabel;
  @HiveField(4)  late String categoryIcon;
  @HiveField(5)  late int    categoryColor;
  @HiveField(6)  late double amount;
  @HiveField(7)  late int    recurrenceIndex;
  @HiveField(8)  late int    dayOfMonth;
  @HiveField(9)  late DateTime nextDueDate;
  @HiveField(10) late DateTime startDate;
  @HiveField(11) late int    statusIndex;
  @HiveField(12) String?     note;

  SubscriptionModel();

  factory SubscriptionModel.fromEntity(SubscriptionEntity e) =>
      SubscriptionModel()
        ..id              = e.id
        ..title           = e.title
        ..categoryId      = e.categoryId
        ..categoryLabel   = e.categoryLabel
        ..categoryIcon    = e.categoryIcon
        ..categoryColor   = e.categoryColor
        ..amount          = e.amount
        ..recurrenceIndex = e.recurrence.index
        ..dayOfMonth      = e.dayOfMonth
        ..nextDueDate     = e.nextDueDate
        ..startDate       = e.startDate
        ..statusIndex     = e.status.index
        ..note            = e.note;

  SubscriptionEntity toEntity() => SubscriptionEntity(
    id:            id,
    title:         title,
    categoryId:    categoryId,
    categoryLabel: categoryLabel,
    categoryIcon:  categoryIcon,
    categoryColor: categoryColor,
    amount:        amount,
    recurrence:    RecurrenceType.values[recurrenceIndex],
    dayOfMonth:    dayOfMonth,
    nextDueDate:   nextDueDate,
    startDate:     startDate,
    status:        SubStatus.values[statusIndex],
    note:          note,
  );
}