import 'dart:math';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/NutritionalInfo.dart';
import '../data/hive_database.dart';

class CalorieTile extends StatefulWidget {
  const CalorieTile({Key? key}) : super(key: key);

  @override
  _CalorieTileState createState() => _CalorieTileState();
}

class _CalorieTileState extends State<CalorieTile> {
  final HiveDatabase hiveDatabase = HiveDatabase();
  double _caloriesLeft = 0;
  double _caloriesConsumedToday = 0;
  double _dailyGoal = 0;

  @override
  void initState() {
    super.initState();
    loadNutritionalInfo();
  }

  void loadNutritionalInfo() async {
    var box = await Hive.openBox<NutritionalInfo>('nutritionBox');
    NutritionalInfo? info = box.get('nutrition');
    if (info != null) {
      _dailyGoal = double.tryParse(info.calories) ?? 0;
      calculateCalories();
    }
  }

  void calculateCalories() {
    DateTime today = DateTime.now();
    var foodItems = hiveDatabase.getFoodForDate(today);
    _caloriesConsumedToday = foodItems.fold(0, (sum, item) {
      return sum + (double.tryParse(item.calories) ?? 0);
    });

    setState(() {
      _caloriesLeft = max(0, _dailyGoal - _caloriesConsumedToday);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: Colors.grey[800],
      elevation: 4,
      margin: const EdgeInsets.all(0),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 1, horizontal: 1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Daily Nutrition",
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNutritionData("${_caloriesLeft.toStringAsFixed(0)}", "Remaining"),
                _buildNutritionData("${_caloriesConsumedToday.toStringAsFixed(0)}", "Consumed"),
                _buildNutritionData("${_dailyGoal.toStringAsFixed(0)}", "Target"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionData(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: label == "Consumed" ? 35 : 25,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
