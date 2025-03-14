import 'package:hive/hive.dart';

part 'NutritionalInfo.g.dart';

@HiveType(typeId: 5)
class NutritionalInfo extends HiveObject {
  @HiveField(0)
  String? calories;  // Made nullable

  @HiveField(1)
  String? protein;   // Made nullable

  @HiveField(2)
  String? carbs;     // Made nullable

  @HiveField(3)
  String? fats;      // Made nullable

  NutritionalInfo({
    this.calories,
    this.protein,
    this.carbs,
    this.fats,
  });
}
