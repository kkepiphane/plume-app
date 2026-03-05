
import 'package:hive/hive.dart';
part 'transaction_model.g.dart';

@HiveType(typeId: 1)
class CategoryModel extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String label;

  @HiveField(2)
  late String icon;

  @HiveField(3)
  late int color;

  @HiveField(4)
  late bool isExpense;

  @HiveField(5)
  late bool isCustom;

  CategoryModel();

  factory CategoryModel.fromEntity(CategoryEntity entity) {
    return CategoryModel()
      ..id = entity.id
      ..label = entity.label
      ..icon = entity.icon
      ..color = entity.color
      ..isExpense = entity.isExpense
      ..isCustom = entity.isCustom;
  }

  CategoryEntity toEntity() {
    return CategoryEntity(
      id: id,
      label: label,
      icon: icon,
      color: color,
      isExpense: isExpense,
      isCustom: isCustom,
    );
  }
}