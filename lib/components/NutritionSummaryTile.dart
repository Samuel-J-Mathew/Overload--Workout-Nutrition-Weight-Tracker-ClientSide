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
    final iconSize = MediaQuery.of(context).size.width * 0.055;
    final screenWidth = MediaQuery.of(context).size.width;
    final statTileWidth = screenWidth * 0.22;
    final macroTileWidth = screenWidth * 0.22;
    final pieChartSize = screenWidth * 0.36;
    return Column(
      children: [
        // Pie chart in its own tile
        Container(
          decoration: BoxDecoration(
            color: darkTileColor,
            borderRadius: BorderRadius.circular(18),
          ),
          padding: EdgeInsets.symmetric(vertical: screenWidth * 0.045, horizontal: 0),
          margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.02, vertical: 0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Remaining section on the left
                  _statTile("Remaining", caloriesLeft, Colors.white, darkTileColor, statTileWidth, context),
                  // Pie chart in the center
                  SizedBox(
                    width: pieChartSize,
                    height: pieChartSize,
                    child: PieChart(
                      dataMap: {
                        "Consumed": caloriesConsumedToday.clamp(0, dailyGoal),
                        "Remaining": (dailyGoal - caloriesConsumedToday).clamp(0, dailyGoal),
                      },
                      chartType: ChartType.ring,
                      ringStrokeWidth: pieChartSize * 0.12,
                      colorList: [blue, Colors.grey[900]!],
                      chartRadius: pieChartSize,
                      centerWidget: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              caloriesConsumedToday.toStringAsFixed(0),
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: pieChartSize * 0.23,
                              ),
                            ),
                          ),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              "consumed",
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: pieChartSize * 0.10,
                              ),
                            ),
                          ),
                        ],
                      ),
                      legendOptions: LegendOptions(showLegends: false),
                      chartValuesOptions: ChartValuesOptions(showChartValues: false),
                    ),
                  ),
                  // Target section on the right
                  _statTile("Target", dailyGoal, Colors.white, darkTileColor, statTileWidth, context),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: screenWidth * 0.045),
        // Macro tiles row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _macroTile(
              icon: MdiIcons.foodSteak,
              value: proteinConsumedToday,
              label: "P",
              color: red,
              iconColor: red,
              iconSize: iconSize,
              width: macroTileWidth,
              context: context,
            ),
            _macroTile(
              icon: MdiIcons.breadSlice,
              value: carbsConsumedToday,
              label: "C",
              color: orange,
              iconColor: orange,
              iconSize: iconSize,
              width: macroTileWidth,
              context: context,
            ),
            _macroTile(
              icon: Icons.opacity,
              value: fatsConsumedToday,
              label: "F",
              color: green,
              iconColor: green,
              iconSize: iconSize,
              width: macroTileWidth,
              context: context,
            ),
          ],
        ),
      ],
    );
  }

  Widget _statTile(String label, double value, Color valueColor, Color bgColor, double width, BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Container(
      width: width,
      padding: EdgeInsets.symmetric(vertical: screenWidth * 0.03),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: screenWidth * 0.035,
              ),
            ),
          ),
          SizedBox(height: screenWidth * 0.01),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value.toStringAsFixed(0),
              style: TextStyle(
                color: valueColor,
                fontWeight: FontWeight.bold,
                fontSize: screenWidth * 0.05,
              ),
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
    required double width,
    required BuildContext context,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Container(
      width: width,
      padding: EdgeInsets.symmetric(vertical: screenWidth * 0.035),
      decoration: BoxDecoration(
        color: Color(0xFF121212),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor, size: iconSize),
          SizedBox(height: screenWidth * 0.015),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value.toStringAsFixed(0),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: screenWidth * 0.045,
              ),
            ),
          ),
          SizedBox(height: screenWidth * 0.005),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: screenWidth * 0.035,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 