import 'package:flutter/material.dart';
import 'FoodItemDatabase.dart';
import 'hive_database.dart';


class FoodData with ChangeNotifier {
  final HiveDatabase db;

  FoodData(this.db);  // Make sure this instance is correctly initialized and shared

  List<FoodItemDatabase> getFoodForDate(DateTime date) {
    var foods = db.getFoodForDate(date);
    return foods;
  }

  void addFood(String name, String calories, String protein, String carbs, String fats, DateTime date) {
    db.addFoodItem(name, calories, protein, carbs, fats, date);
    notifyListeners();
  }

  void deleteFood(String id) {
    db.deleteFoodItem(id);
    notifyListeners();
  }
}
