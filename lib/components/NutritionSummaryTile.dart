import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pie_chart/pie_chart.dart';
import '../models/NutritionalInfo.dart';
import '../data/hive_database.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/cupertino.dart';

class NutritionSummaryTile extends StatefulWidget {
  final DateTime selectedDate;

  const NutritionSummaryTile({
    Key? key,
    required this.selectedDate,
  }) : super(key: key);

  @override
  _NutritionSummaryTileState createState() => _NutritionSummaryTileState();
}

class _NutritionSummaryTileState extends State<NutritionSummaryTile> {
  final HiveDatabase hiveDatabase = HiveDatabase();
  double _caloriesLeft = 0;
  double _caloriesConsumedToday = 0;
  double _proteinConsumedToday = 0;
  double _carbsConsumedToday = 0;
  double _fatsConsumedToday = 0;
  double _dailyGoal = 0;
  double _dailyGoalfats = 0;
  double _dailyGoalprotein = 0;
  double _dailyGoalcarbs = 0;

  @override
  void initState() {
    super.initState();
    loadNutritionalInfo();
  }

  @override
  void didUpdateWidget(NutritionSummaryTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDate != widget.selectedDate) {
      calculateCalories();
      calculateMacros();
    }
  }

  void loadNutritionalInfo() async {
    var box = await Hive.openBox<NutritionalInfo>('nutritionBox');
    NutritionalInfo? info = box.get('nutrition');
    if (info != null) {
      _dailyGoal = double.tryParse(info.calories ?? "0") ?? 0;
      _dailyGoalprotein = double.tryParse(info.protein ?? "0") ?? 0;
      _dailyGoalcarbs = double.tryParse(info.carbs ?? "0") ?? 0;
      _dailyGoalfats = double.tryParse(info.fats ?? "0") ?? 0;
      calculateCalories();
      calculateMacros();
    }
  }

  void calculateCalories() {
    var foodItems = hiveDatabase.getFoodForDate(widget.selectedDate);
    _caloriesConsumedToday = foodItems.fold(0, (sum, item) {
      return sum + (double.tryParse(item.calories) ?? 0);
    });
    setState(() {
      _caloriesLeft = (_dailyGoal - _caloriesConsumedToday).clamp(0, double.infinity);
    });
  }

  void calculateMacros() {
    var foodItems = hiveDatabase.getFoodForDate(widget.selectedDate);
    _proteinConsumedToday = 0;
    _carbsConsumedToday = 0;
    _fatsConsumedToday = 0;
    foodItems.forEach((item) {
      _proteinConsumedToday += double.tryParse(item.protein) ?? 0;
      _carbsConsumedToday += double.tryParse(item.carbs) ?? 0;
      _fatsConsumedToday += double.tryParse(item.fats) ?? 0;
    });
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final darkTileColor = Color(0xFF121212);
    final blue = Color(0xFF1DA1F2);
    final orange = Color(0xFFFF9100);
    final green = Color(0xFF00C853);
    final red = Color(0xFFFF5252);
    final iconSize = 22.0;
    return Column(
      children: [
        // Pie chart in its own tile
        Container(
          decoration: BoxDecoration(
            color: darkTileColor,
            borderRadius: BorderRadius.circular(18),
          ),
          padding: EdgeInsets.symmetric(vertical: 18, horizontal: 0),
          margin: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
          child: Column(
            children: [
              SizedBox(
                width: 140,
                height: 140,
                child: PieChart(
                  dataMap: {
                    "Consumed": _caloriesConsumedToday.clamp(0, _dailyGoal),
                    "Remaining": (_dailyGoal - _caloriesConsumedToday).clamp(0, _dailyGoal),
                  },
                  chartType: ChartType.ring,
                  ringStrokeWidth: 16,
                  colorList: [blue, Colors.grey[900]!],
                  chartRadius: 120,
                  centerWidget: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _caloriesConsumedToday.toStringAsFixed(0),
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 32,
                        ),
                      ),
                      Text(
                        "consumed",
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  legendOptions: LegendOptions(showLegends: false),
                  chartValuesOptions: ChartValuesOptions(showChartValues: false),
                ),
              ),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _statTile("Remaining", _caloriesLeft, Colors.white, darkTileColor),
                  _statTile("Consumed", _caloriesConsumedToday, blue, darkTileColor),
                  _statTile("Target", _dailyGoal, Colors.white, darkTileColor),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: 18),
        // Macro tiles row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _macroTile(
              icon: Icons.flash_on,
              value: _proteinConsumedToday,
              label: "P",
              color: green,
              iconColor: green,
              iconSize: iconSize,
            ),
            _macroTile(
              icon: Icons.grain,
              value: _carbsConsumedToday,
              label: "C",
              color: orange,
              iconColor: orange,
              iconSize: iconSize,
            ),
            _macroTile(
              icon: Icons.local_fire_department,
              value: _fatsConsumedToday,
              label: "F",
              color: red,
              iconColor: red,
              iconSize: iconSize,
            ),
          ],
        ),
      ],
    );
  }

  Widget _statTile(String label, double value, Color valueColor, Color bgColor) {
    return Container(
      width: 90,
      padding: EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
          ),
          SizedBox(height: 4),
          Text(
            value.toStringAsFixed(0),
            style: TextStyle(
              color: valueColor,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _macroTile({
    required IconData icon,
    required double value,
    required String label,
    required Color color,
    required Color iconColor,
    required double iconSize,
  }) {
    return Container(
      width: 90,
      padding: EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Color(0xFF121212),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor, size: iconSize),
          SizedBox(height: 6),
          Text(
            value.toStringAsFixed(0),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
} 