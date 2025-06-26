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
  Widget _buildMacroProgressBar(double consumed, double goal, Color color, String label) {
    double progressValue = 0;
    if (goal > 0) {
      progressValue = min(1.0, max(0, consumed / goal));
    }

    return Expanded(
      child: Column(
        children: [
          Text(
            "$label ${max(0, (goal - consumed).round())} left",
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4), // Add some space between the label and the progress bar
          LinearProgressIndicator(
            value: progressValue,
            backgroundColor: Colors.grey[500],
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8, // Specify the height of the progress bar if needed
          ),
          SizedBox(height: 10), // Space after the bar, before the next element
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: Color.fromRGBO(42, 42, 42, 1),
      elevation: 4,
      margin: const EdgeInsets.all(0),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        child: SingleChildScrollView(
          physics: NeverScrollableScrollPhysics(),
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
              SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNutritionData("${_caloriesLeft.toStringAsFixed(0)}", "Remaining"),
                  _buildPieChart(),
                  _buildNutritionData("${_dailyGoal.toStringAsFixed(0)}", "Target"),
                ],
              ),
              SizedBox(height: 5),
              Divider(
                color: Colors.grey[700],
                thickness: 1,
                height: 20,
              ),
              Row(
                children: [
                  _buildMacroProgressBar(_proteinConsumedToday, _dailyGoalprotein, Colors.red, "P"), // Protein
                  SizedBox(width: 10), // Spacing between bars
                  _buildMacroProgressBar(_carbsConsumedToday, _dailyGoalcarbs, Colors.green, "C"), // Carbs
                  SizedBox(width: 10), // Spacing between bars
                  _buildMacroProgressBar(_fatsConsumedToday, _dailyGoalfats, Colors.blue, "F"), // Fats
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildNutritionData(String value, String label) {
    return Column(
      children: [
        Text(
          max(0, double.tryParse(value) ?? 0).toStringAsFixed(0),
          style: TextStyle(
            color: Colors.white,
            fontSize: 25,
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

  Widget _buildPieChart() {
    Map<String, double> dataMap = {
      "Consumed": max(0, _caloriesConsumedToday),
      "Remaining": max(0, _dailyGoal - _caloriesConsumedToday),
    };
    return Expanded(
      child: PieChart(
        dataMap: dataMap,
        animationDuration: Duration(milliseconds: 800),
        chartLegendSpacing: 32,
        chartRadius: MediaQuery.of(context).size.width / 3.5,
        colorList: [Colors.blue, Colors.blueGrey[200]!],
        initialAngleInDegree: 0,
        chartType: ChartType.ring,
        ringStrokeWidth: 12,
        centerText: "", // Clear this to use a custom widget
        centerWidget: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "${_caloriesConsumedToday.toStringAsFixed(0)}",
              style: TextStyle(
                fontSize: 38, // Larger font size for calories
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              "Consumed",
              style: TextStyle(
                fontSize: 12, // Smaller font size for "Consumed"
                color: Colors.grey,
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