import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/NutritionalInfo.dart';

class NutritionProvider with ChangeNotifier {
  NutritionalInfo? currentInfo;

  void loadNutritionalInfo() async {
    var box = await Hive.openBox<NutritionalInfo>('nutritionBox');
    currentInfo = box.get('nutrition');
    notifyListeners();
  }

  void saveNutritionalInfo(String calories, String protein) async {
    var box = await Hive.openBox<NutritionalInfo>('nutritionBox');
    final nutritionalInfo = NutritionalInfo(calories: calories, protein: protein);
    await box.put('nutrition', nutritionalInfo);
    loadNutritionalInfo();
  }
}
