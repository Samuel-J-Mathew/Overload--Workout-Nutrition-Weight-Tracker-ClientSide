class FoodItem {
  final String name;
  final double calories; // per 100g
  final double protein;  // grams per 100g
  final double fats;     // grams per 100g
  final double carbs;    // grams per 100g

  FoodItem(this.name, this.calories, this.protein, this.fats, this.carbs);

  Map<String, double> getNutrients(double weight) {
    return {
      'calories': (calories * weight) / 100,
      'protein': (protein * weight) / 100,
      'fats': (fats * weight) / 100,
      'carbs': (carbs * weight) / 100,
    };
  }
}
