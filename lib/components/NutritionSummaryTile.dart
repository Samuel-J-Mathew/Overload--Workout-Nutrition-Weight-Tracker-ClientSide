import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pie_chart/pie_chart.dart';
import '../models/NutritionalInfo.dart';
import '../data/hive_database.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';
import 'package:gymapp/data/FoodData.dart';

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
  @override
  Widget build(BuildContext context) {
    final foodData = Provider.of<FoodData>(context);
    final hiveDatabase = HiveDatabase();
    final box = Hive.box<NutritionalInfo>('nutritionBox');
    final NutritionalInfo? info = box.get('nutrition');
    final double dailyGoal = double.tryParse(info?.calories ?? "0") ?? 0;
    final double dailyGoalProtein = double.tryParse(info?.protein ?? "0") ?? 0;
    final double dailyGoalCarbs = double.tryParse(info?.carbs ?? "0") ?? 0;
    final double dailyGoalFats = double.tryParse(info?.fats ?? "0") ?? 0;
    final foodItems = foodData.getFoodForDate(widget.selectedDate);
    final double caloriesConsumedToday = foodItems.fold(0, (sum, item) => sum + (double.tryParse(item.calories) ?? 0));
    final double proteinConsumedToday = foodItems.fold(0, (sum, item) => sum + (double.tryParse(item.protein) ?? 0));
    final double carbsConsumedToday = foodItems.fold(0, (sum, item) => sum + (double.tryParse(item.carbs) ?? 0));
    final double fatsConsumedToday = foodItems.fold(0, (sum, item) => sum + (double.tryParse(item.fats) ?? 0));
    final double caloriesLeft = (dailyGoal - caloriesConsumedToday).clamp(0, double.infinity);
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Remaining section on the left
                  _statTile("Remaining", caloriesLeft, Colors.white, darkTileColor),

                  // Pie chart in the center
                  SizedBox(
                    width: 140,
                    height: 140,
                    child: PieChart(
                      dataMap: {
                        "Consumed": caloriesConsumedToday.clamp(0, dailyGoal),
                        "Remaining": (dailyGoal - caloriesConsumedToday).clamp(0, dailyGoal),
                      },
                      chartType: ChartType.ring,
                      ringStrokeWidth: 16,
                      colorList: [blue, Colors.grey[900]!],
                      chartRadius: 120,
                      centerWidget: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            caloriesConsumedToday.toStringAsFixed(0),
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

                  // Target section on the right
                  _statTile("Target", dailyGoal, Colors.white, darkTileColor),
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
              icon: 	MdiIcons.foodSteak,
              value: proteinConsumedToday,
              label: "P",
              color: red,
              iconColor: red,
              iconSize: iconSize,
            ),
            _macroTile(
              icon: MdiIcons.breadSlice,
              value: carbsConsumedToday,
              label: "C",
              color: orange,
              iconColor: orange,
              iconSize: iconSize,
            ),
            _macroTile(
              icon: Icons.opacity,
              value: fatsConsumedToday,
              label: "F",
              color: green,
              iconColor: green,
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