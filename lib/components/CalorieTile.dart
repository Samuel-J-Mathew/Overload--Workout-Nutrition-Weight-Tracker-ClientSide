import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pie_chart/pie_chart.dart';
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
    DateTime today = DateTime.now();
    var foodItems = hiveDatabase.getFoodForDate(today);
    _caloriesConsumedToday = foodItems.fold(0, (sum, item) {
      return sum + (double.tryParse(item.calories) ?? 0);
    });

    setState(() {
      _caloriesLeft = max(0, _dailyGoal - _caloriesConsumedToday);
    });
  }
  void calculateMacros() {
    DateTime today = DateTime.now();
    var foodItems = hiveDatabase.getFoodForDate(today);
    foodItems.forEach((item) {
      _proteinConsumedToday += double.tryParse(item.protein) ?? 0;
      _carbsConsumedToday += double.tryParse(item.carbs) ?? 0;
      _fatsConsumedToday += double.tryParse(item.fats) ?? 0;
    });

    setState(() {});
  }
  Widget _buildMacroProgressBar(double consumed, double goal, Color color, String label, double barHeight, double fontSize) {
    double progressValue = 0;
    if (goal > 0) {
      progressValue = min(1.0, max(0, consumed / goal));
    }

    return Expanded(
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              "$label ${max(0, (goal - consumed).round())} left",
              style: TextStyle(
                color: Colors.white,
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(height: barHeight * 0.25),
          LinearProgressIndicator(
            value: progressValue,
            backgroundColor: Colors.grey[500],
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: barHeight, // Responsive height
          ),
          SizedBox(height: barHeight * 0.7),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final pieChartRadius = screenWidth * 0.22;
    final macroBarHeight = screenWidth * 0.04;
    final macroBarFontSize = screenWidth * 0.035;
    final macroBarSpacing = screenWidth * 0.025;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(screenWidth * 0.04)),
      color: Color.fromRGBO(42, 42, 42, 1),
      elevation: 4,
      margin: const EdgeInsets.all(0),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: screenWidth * 0.03, horizontal: screenWidth * 0.03),
        child: SingleChildScrollView(
          physics: NeverScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  "Daily Nutrition",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: screenWidth * 0.06,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: screenWidth * 0.012),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNutritionData("${_caloriesLeft.toStringAsFixed(0)}", "Remaining", screenWidth),
                  _buildPieChart(screenWidth, pieChartRadius),
                  _buildNutritionData("${_dailyGoal.toStringAsFixed(0)}", "Target", screenWidth),
                ],
              ),
              SizedBox(height: screenWidth * 0.012),
              Divider(
                color: Colors.grey[700],
                thickness: 1,
                height: screenWidth * 0.05,
              ),
              Row(
                children: [
                  _buildMacroProgressBar(_proteinConsumedToday, _dailyGoalprotein, Colors.red, "P", macroBarHeight, macroBarFontSize),
                  SizedBox(width: macroBarSpacing),
                  _buildMacroProgressBar(_carbsConsumedToday, _dailyGoalcarbs, Colors.green, "C", macroBarHeight, macroBarFontSize),
                  SizedBox(width: macroBarSpacing),
                  _buildMacroProgressBar(_fatsConsumedToday, _dailyGoalfats, Colors.blue, "F", macroBarHeight, macroBarFontSize),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildNutritionData(String value, String label, double screenWidth) {
    return Column(
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            max(0, double.tryParse(value) ?? 0).toStringAsFixed(0),
            style: TextStyle(
              color: Colors.white,
              fontSize: screenWidth * 0.07,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey,
              fontSize: screenWidth * 0.032,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPieChart(double screenWidth, double pieChartRadius) {
    Map<String, double> dataMap = {
      "Consumed": max(0, _caloriesConsumedToday),
      "Remaining": max(0, _dailyGoal - _caloriesConsumedToday),
    };
    return Expanded(
      child: PieChart(
        dataMap: dataMap,
        animationDuration: Duration(milliseconds: 800),
        chartLegendSpacing: screenWidth * 0.08,
        chartRadius: pieChartRadius,
        colorList: [Colors.blue, Colors.blueGrey[200]!],
        initialAngleInDegree: 0,
        chartType: ChartType.ring,
        ringStrokeWidth: pieChartRadius * 0.18,
        centerText: "",
        centerWidget: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                "${_caloriesConsumedToday.toStringAsFixed(0)}",
                style: TextStyle(
                  fontSize: pieChartRadius * 0.25,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                "Consumed",
                style: TextStyle(
                  fontSize: pieChartRadius * 0.11,
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
        legendOptions: LegendOptions(
          showLegends: false,
        ),
        chartValuesOptions: ChartValuesOptions(
          showChartValueBackground: true,
          showChartValues: false,
          showChartValuesInPercentage: false,
          showChartValuesOutside: false,
        ),
      ),
    );
  }
}