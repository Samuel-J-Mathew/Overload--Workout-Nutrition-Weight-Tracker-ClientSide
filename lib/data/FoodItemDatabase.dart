class FoodItemDatabase {
  final String id;
  final String name;
  final String calories;
  final String protein;
  final String carbs;
  final String fats;
  final DateTime date;

  FoodItemDatabase({
    required this.id,
    required this.name,
    required this.calories,
    required this.protein,
    required this.fats,
    required this.carbs,
    required this.date,
  });
}
