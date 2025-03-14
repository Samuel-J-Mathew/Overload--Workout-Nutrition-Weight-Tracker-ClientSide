import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/NutritionalInfo.dart';

class NutritionProvider with ChangeNotifier {
  NutritionalInfo? currentInfo;

  void loadNutritionalInfo() async {
    var box = await Hive.openBox<NutritionalInfo>('nutritionBox');
    currentInfo = box.get('nutrition');
    // Handling potential null values with defaults
    if (currentInfo == null) {
      currentInfo = NutritionalInfo(calories: "0", protein: "0", carbs: "0", fats: "0");
    }
    notifyListeners();
  }
  void saveNutritionalInfo(String calories, String protein, String carbs, String fats) async {
    var box = await Hive.openBox<NutritionalInfo>('nutritionBox');
    final nutritionalInfo = NutritionalInfo(calories: calories, protein: protein, carbs: carbs, fats:fats);
    await box.put('nutrition', nutritionalInfo);
    loadNutritionalInfo();
  }
}
