class CategoryEntity {
  final String id;
  final String label;
  final String icon;
  final int color;
  final bool isExpense;
  final bool isCustom;

  const CategoryEntity({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
    required this.isExpense,
    this.isCustom = false,
  });

  CategoryEntity copyWith({
    String? id,
    String? label,
    String? icon,
    int? color,
    bool? isExpense,
    bool? isCustom,
  }) {
    return CategoryEntity(
      id: id ?? this.id,
      label: label ?? this.label,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isExpense: isExpense ?? this.isExpense,
      isCustom: isCustom ?? this.isCustom,
    );
  }
}