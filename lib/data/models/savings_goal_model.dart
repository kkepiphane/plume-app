// lib/data/models/savings_goal_model.dart
import 'package:hive/hive.dart';
import '../../domain/entities/savings_goal_entity.dart';

part 'savings_goal_model.g.dart';

@HiveType(typeId: 3)
class SavingsGoalModel extends HiveObject {
  @HiveField(0) late String id;
  @HiveField(1) late String title;
  @HiveField(2) late String emoji;
  @HiveField(3) late double targetAmount;
  @HiveField(4) late double savedAmount;
  @HiveField(5) late DateTime deadline;
  @HiveField(6) late DateTime createdAt;
  @HiveField(7) late int statusIndex;
  @HiveField(8) late int color;

  SavingsGoalModel();

  factory SavingsGoalModel.fromEntity(SavingsGoalEntity e) => SavingsGoalModel()
    ..id           = e.id
    ..title        = e.title
    ..emoji        = e.emoji
    ..targetAmount = e.targetAmount
    ..savedAmount  = e.savedAmount
    ..deadline     = e.deadline
    ..createdAt    = e.createdAt
    ..statusIndex  = e.status.index
    ..color        = e.color;

  SavingsGoalEntity toEntity() => SavingsGoalEntity(
    id:           id,
    title:        title,
    emoji:        emoji,
    targetAmount: targetAmount,
    savedAmount:  savedAmount,
    deadline:     deadline,
    createdAt:    createdAt,
    status:       GoalStatus.values[statusIndex],
    color:        color,
  );
}