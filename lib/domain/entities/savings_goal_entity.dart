// lib/domain/entities/savings_goal_entity.dart
enum GoalStatus { active, achieved, paused, cancelled }

class SavingsGoalEntity {
  final String      id;
  final String      title;
  final String      emoji;       // ex: "📱", "🏠", "✈️"
  final double      targetAmount;
  final double      savedAmount;
  final DateTime    deadline;
  final DateTime    createdAt;
  final GoalStatus  status;
  final int         color;       // ARGB

  const SavingsGoalEntity({
    required this.id,
    required this.title,
    required this.emoji,
    required this.targetAmount,
    required this.savedAmount,
    required this.deadline,
    required this.createdAt,
    this.status = GoalStatus.active,
    this.color  = 0xFF6C63FF,
  });

  double get progressPercent =>
      targetAmount > 0 ? (savedAmount / targetAmount * 100).clamp(0, 100) : 0;

  double get remaining => (targetAmount - savedAmount).clamp(0, double.infinity);

  bool get isAchieved => savedAmount >= targetAmount;

  int get daysLeft => deadline.difference(DateTime.now()).inDays;

  /// Monthly saving needed to reach goal in time
  double get monthlyNeeded {
    final months = deadline.difference(DateTime.now()).inDays / 30;
    if (months <= 0) return remaining;
    return remaining / months;
  }

  SavingsGoalEntity copyWith({
    String? title, String? emoji, double? targetAmount,
    double? savedAmount, DateTime? deadline, GoalStatus? status, int? color,
  }) => SavingsGoalEntity(
    id:           id,
    title:        title         ?? this.title,
    emoji:        emoji         ?? this.emoji,
    targetAmount: targetAmount  ?? this.targetAmount,
    savedAmount:  savedAmount   ?? this.savedAmount,
    deadline:     deadline      ?? this.deadline,
    createdAt:    createdAt,
    status:       status        ?? this.status,
    color:        color         ?? this.color,
  );
}