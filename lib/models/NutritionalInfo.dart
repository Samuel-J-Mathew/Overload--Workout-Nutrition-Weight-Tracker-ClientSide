import 'package:hive/hive.dart';
part 'NutritionalInfo.g.dart';
@HiveType(typeId: 5)
class NutritionalInfo extends HiveObject {
  @HiveField(0)
  String calories;

  @HiveField(1)
  String protein;

  NutritionalInfo({required this.calories, required this.protein});
}
