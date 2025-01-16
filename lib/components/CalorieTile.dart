import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../data/hive_database.dart';
import 'dart:math';
class CalorieTile extends StatefulWidget {
  final String averageCalories; // Passed from MySplitPage
  const CalorieTile({Key? key, required this.averageCalories}) : super(key: key);

  @override
  _CalorieTileState createState() => _CalorieTileState();
}

class _CalorieTileState extends State<CalorieTile> {
  final HiveDatabase hiveDatabase = HiveDatabase();
  double _caloriesLeft = 0;
  double _caloriesConsumedToday = 0;

  @override
  void initState() {
    super.initState();
    _calculateCalories();
  }

  void _calculateCalories() {
    final today = DateTime.now();
    // Get consumed calories for today
    final foodItems = hiveDatabase.getFoodForDate(today);
    _caloriesConsumedToday = foodItems.fold(0, (sum, item) {
      return sum + (double.tryParse(item.calories) ?? 0);
    });

    // Calculate remaining calories
    double dailyGoal = double.tryParse(widget.averageCalories) ?? 0;
    setState(() {
      _caloriesLeft = max(0, dailyGoal - _caloriesConsumedToday);

    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: Colors.grey[850],
      elevation: 4,
      margin: const EdgeInsets.all(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Calories Left Today",
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              "${_caloriesLeft.toStringAsFixed(0)} kcal",
              style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            Text(
              "Consumed: ${_caloriesConsumedToday.toStringAsFixed(0)} kcal",
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
