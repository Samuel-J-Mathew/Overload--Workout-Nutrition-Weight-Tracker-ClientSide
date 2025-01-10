import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/hive_database.dart';
import '../models/step_log.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

enum TimeView { week, month, sixMonth, year, all }

class StepCounterPage extends StatefulWidget {
  @override
  _StepCounterPageState createState() => _StepCounterPageState();

  static Future<double> fetchAndCalculateAverageSteps(BuildContext context) async {
    final db = Provider.of<HiveDatabase>(context, listen: false);
    List<StepLog> logs = await db.getStepLogs();
    DateTime now = DateTime.now();
    DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    DateTime endOfWeek = startOfWeek.add(Duration(days: 6));

    List<StepLog> weekLogs = logs.where((log) {
      return log.date.isAfter(startOfWeek.subtract(Duration(days: 1))) && log.date.isBefore(endOfWeek.add(Duration(days: 1)));
    }).toList();

    if (weekLogs.isEmpty) return 0.0;
    double totalSteps = weekLogs.fold(0, (sum, log) => sum + log.steps);
    return totalSteps / weekLogs.length;
  }
  static Widget buildMiniStepChart(BuildContext context, List<StepLog> logs) {
    DateTime now = DateTime.now();
    int currentWeekday = now.weekday;
    DateTime startOfWeek = now.subtract(Duration(days: currentWeekday - 1));
    DateTime endOfWeek = startOfWeek.add(Duration(days: 6));

    // Filter logs for the current week
    List<StepLog> weekLogs = logs.where((log) {
      return log.date.isAfter(startOfWeek.subtract(Duration(days: 1))) && log.date.isBefore(endOfWeek.add(Duration(days: 1)));
    }).toList();

    weekLogs.sort((a, b) => a.date.compareTo(b.date));  // Sort logs by date

    // Calculate the maximum number of steps to dynamically adjust the chart's maxY
    double maxY = weekLogs.fold(0, (prev, log) => log.steps > prev ? log.steps.toDouble() : prev);
    maxY = maxY == 0 ? 10 : maxY + maxY * 0.2;  // Adding 20% buffer to the maximum steps, ensure non-zero maxY

    // Calculate bar width dynamically based on the number of logs
    double barWidth = weekLogs.length > 1 ? 8 : 16;  // Wider bars for fewer logs

    final barGroups = weekLogs.map((log) {
      return BarChartGroupData(
        x: weekLogs.indexOf(log),
        barRods: [
          BarChartRodData(
            toY: log.steps?.toDouble() ?? 0,
            color: Colors.green[300] ?? Colors.green,
            width: barWidth,
            borderRadius: BorderRadius.zero,  // Make bars rectangular
          ),
        ],
      );
    }).toList();

    return BarChart(
      BarChartData(
        maxY: maxY,
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(
          show: false,
        ),
        borderData: FlBorderData(show: false),
        barGroups: barGroups,
        alignment: BarChartAlignment.spaceBetween,
        barTouchData: BarTouchData(enabled: false),
      ),
    );
  }

  static Widget buildStepChart(BuildContext context, List<StepLog> logs) {
    logs.sort((a, b) => a.date.compareTo(b.date));

    final barGroups = logs.asMap().map((index, log) {
      return MapEntry(index, BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: log.steps?.toDouble() ?? 0.0,
            color: Colors.green[300] ?? Colors.green,
            width: 14,
            borderRadius: BorderRadius.zero,
          ),
        ],
      ));
    }).values.toList();

    return BarChart(
      BarChartData(
        gridData: FlGridData(show: true, drawVerticalLine: false,),
        titlesData: FlTitlesData(
          show: true,
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 60,
              getTitlesWidget: (double value, TitleMeta meta) {
                return Text(
                  NumberFormat('#,###').format(value.toInt()), // Format the number with commas
                  style: TextStyle(color: Colors.white, fontSize: 10),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    DateFormat('MM/dd').format(logs[value.toInt()].date),
                    style: TextStyle(color: Colors.white, fontSize: 10),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: barGroups,
        alignment: BarChartAlignment.spaceAround,
        barTouchData: BarTouchData(enabled: false),
        groupsSpace: 1,
      ),
    );
  }
}

class _StepCounterPageState extends State<StepCounterPage> {
  List<StepLog> logs = [];
  TimeView _selectedTimeView = TimeView.week;
  double _averageSteps = 0;
  @override
  void initState() {
    super.initState();
    _fetchLogs();
  }

  void _fetchLogs() {
    final db = Provider.of<HiveDatabase>(context, listen: false);
    logs = db.getStepLogs();
    _updateFilteredLogs();
  }



  void _updateFilteredLogs() {
    final db = Provider.of<HiveDatabase>(context, listen: false);
    DateTime now = DateTime.now();
    DateTime startDate;
    DateTime endDate = now.add(Duration(days: 1));  // Includes all of today

    switch (_selectedTimeView) {
      case TimeView.week:
        startDate = now.subtract(Duration(days: now.weekday - 1));  // Start from Monday
        endDate = startDate.add(Duration(days: 6));  // End on Sunday
        break;
      case TimeView.month:
        startDate = DateTime(now.year, now.month, 1);  // Start of the month
        endDate = DateTime(now.year, now.month + 1, 0);  // End of the month
        break;
      case TimeView.sixMonth:
        startDate = DateTime(now.year, now.month - 6, 1);  // Start 6 months ago
        endDate = DateTime(now.year, now.month + 1, 0);  // End of the current month
        break;
      case TimeView.year:
        startDate = DateTime(now.year - 1, now.month, 1);  // Start of last year
        endDate = DateTime(now.year, now.month + 1, 0);  // End of the current month
        break;
      case TimeView.all:
        startDate = DateTime(2000);  // Arbitrary start date
        endDate = DateTime.now();  // Up to now
        break;
    }

    logs = db.getStepLogs().where((log) {
      return log.date.isAfter(startDate.subtract(Duration(days: 1))) && log.date.isBefore(endDate);
    }).toList();
    if (logs.isNotEmpty) {
      _averageSteps = logs.map((log) => log.steps).reduce((a, b) => a + b) / logs.length;
    } else {
      _averageSteps = 0;
    }

    setState(() {});
  }


  void _updateTimeView(TimeView view) {
    setState(() {
      _selectedTimeView = view;
    });
    _updateFilteredLogs();
  }

  Future<void> _addStepLog() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      final Map<String, dynamic>? result = await _showStepOrDistanceInputDialog();
      if (result != null && result['steps'] != null) {
        final db = Provider.of<HiveDatabase>(context, listen: false);
        final log = StepLog(date: pickedDate, steps: result['steps']);
        db.saveStepLog(log);
        _fetchLogs(); // Refresh logs
      }
    }
  }
  Future<Map<String, dynamic>?> _showStepOrDistanceInputDialog() async {
    final TextEditingController stepsController = TextEditingController();
    final TextEditingController distanceController = TextEditingController();

    void updateSteps(String distance) {
      final double? miles = double.tryParse(distance);
      if (miles != null) {
        final int steps = ((miles * 5280) / 2.5).round();
        stepsController.text = steps.toString();
      }
    }

    void updateDistance(String steps) {
      final int? stepsValue = int.tryParse(steps);
      if (stepsValue != null) {
        final double miles = (stepsValue * 2.5) / 5280;
        distanceController.text = miles.toStringAsFixed(2);
      }
    }

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Enter Steps or Distance'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: stepsController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Steps'),
                onChanged: (value) => updateDistance(value),
              ),
              TextField(
                controller: distanceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Distance (miles)'),
                onChanged: (value) => updateSteps(value),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Save'),
              onPressed: () {
                final int? steps = int.tryParse(stepsController.text);
                Navigator.of(context).pop({'steps': steps});
              },
            ),
          ],
        );
      },
    );
  }


  Future<void> _chooseStepOrDistance() async {
    // Prompt the user to choose between steps or distance
    final selectedOption = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Steps or Distance'),
          content: Text('Would you like to add steps or distance?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop('steps'),
              child: Text('Steps'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop('distance'),
              child: Text('Distance'),
            ),
          ],
        );
      },
    );

    if (selectedOption == 'steps') {
      // Call existing method to add steps
      await _addStepLog();
    } else if (selectedOption == 'distance') {
      // Handle adding distance
      await _addDistanceLog();
    }
  }
  Future<void> _addDistanceLog() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      final String? distance = await _showDistanceInputDialog();
      if (distance != null && distance.isNotEmpty) {
        final double miles = double.tryParse(distance) ?? 0;
        final int steps = ((miles * 5280) / 2.5).round(); // Convert distance to steps
        final db = Provider.of<HiveDatabase>(context, listen: false);
        final log = StepLog(date: pickedDate, steps: steps);
        db.saveStepLog(log);
        _fetchLogs(); // Refresh logs
      }
    }
  }
  Future<String?> _showDistanceInputDialog() async {
    TextEditingController controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Enter Distance'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: 'Distance (miles)'),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Save'),
              onPressed: () {
                Navigator.of(context).pop(controller.text);
              },
            ),
          ],
        );
      },
    );
  }



  Future<String?> _showStepInputDialog() async {
    TextEditingController controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Enter your steps'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: 'Steps'),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Save'),
              onPressed: () {
                Navigator.of(context). pop(controller.text);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildChart() {
    if (logs.isEmpty) {
      return Center(child: Text("No step data available"));
    }
    return StepCounterPage.buildStepChart(context, logs);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        iconTheme: IconThemeData(color: Colors.white),
        title: Align(
          alignment: Alignment.centerLeft, // Align the title to the left
          child: Text(
            "Step Counter",
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
      body: Column(
        children: [
      Container(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(" Average", style: TextStyle(color: Colors.grey[600], fontSize: 18)),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: "${NumberFormat.decimalPattern().format(_averageSteps.toInt())} ", // Step count
                  style: TextStyle(
                    color: Colors.white, // Color for the step count
                    fontSize: 28, // Larger font size for the step count
                    fontWeight: FontWeight.bold, // Optional: Make it bold
                  ),
                ),
                TextSpan(
                  text: "steps", // "steps" label
                  style: TextStyle(
                    color: Colors.grey, // Different color for the "steps" text
                    fontSize: 15, // Smaller font size for the "steps" text
                  ),
                ),
              ],
            ),
          )
        ],
      )),
          Container(
            height: 200,
            child: _buildChart(),
          ),
          Container(
            margin: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(30),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 1),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _timeButton("1W", TimeView.week),
                  _timeButton("1M", TimeView.month),
                  _timeButton("6M", TimeView.sixMonth),
                  _timeButton("1Y", TimeView.year),
                  _timeButton("ALL", TimeView.all),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: logs.length,
              itemBuilder: (context, index) {
                final reversedIndex = logs.length - 1 - index;
                final log = logs[reversedIndex];
                return ListTile(
                  title: Text("${log.steps} steps", style: TextStyle(color: Colors.white)),
                  trailing: Text(
                    DateFormat('EEE, MMM d').format(log.date),
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                );
              },
              separatorBuilder: (context, index) => Divider(color: Colors.grey[700]),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addStepLog,
        child: Icon(Icons.add),
        backgroundColor: Colors.white,
        foregroundColor: Colors.blue,
      ),
    );
  }

  Widget _timeButton(String text, TimeView view) {
    bool isSelected = _selectedTimeView == view;  // Check if this button is selected
    return TextButton(
      onPressed: () => _updateTimeView(view),
      child: Text(
        text,
        style: TextStyle(
          color: isSelected ? Colors.grey[800] : Colors.white,  // Text color changes with selection
        ),
      ),
      style: TextButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),  // Rounded borders
        ),
        backgroundColor: isSelected ? Colors.white : Colors.grey[800],  // Background color toggles based on selection
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),  // Horizontal padding and consistent vertical padding
      ),
    );
  }

}
