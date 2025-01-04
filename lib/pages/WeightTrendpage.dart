import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/hive_database.dart';
import '../models/weight_log.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

enum TimeView { week, month, sixMonth, year, all }

class WeightTrendPage extends StatefulWidget {
  @override
  _WeightTrendPageState createState() => _WeightTrendPageState();
}

class _WeightTrendPageState extends State<WeightTrendPage> {
  List<WeightLog> logs = [];
  TimeView? _selectedTimeView;  // Variable to track the selected time view
  double minY = 0;
  double maxY = 0;

  @override
  void initState() {
    super.initState();
    _fetchLogs();
    _selectedTimeView = null;  // Initialize with no selection
  }

  void _fetchLogs() {
    final db = Provider.of<HiveDatabase>(context, listen: false);
    logs = db.getWeightLogs();
    // Sort logs by date in descending order
    logs.sort((a, b) => b.date.compareTo(a.date));
    if (logs.isEmpty) {
      setState(() {});  // Refresh UI if no data is found
    } else {
      setState(() {});  // Ensure the UI is updated with the sorted logs
    }
  }
  double calculateInterval(double maxY, double minY) {
    if (maxY == minY) {
      // To avoid a zero interval, provide a default value when maxY equals minY
      return 1;  // Or any other reasonable default for your dataset
    } else {
      return (maxY - minY) / 2;  // Adjust this divisor as needed
    }
  }
  void _updateTimeView(TimeView view) {
    setState(() {
      _selectedTimeView = view;  // Update the selected time view on button press
    });
    DateTime now = DateTime.now();
    DateTime startDate;

    switch (view) {
      case TimeView.week:
        startDate = now.subtract(Duration(days: 7));
        break;
      case TimeView.month:
        startDate = DateTime(now.year, now.month - 1, now.day);
        break;
      case TimeView.sixMonth:
        startDate = DateTime(now.year, now.month - 6, now.day);
        break;
      case TimeView.year:
        startDate = DateTime(now.year - 1, now.month, now.day);
        break;
      case TimeView.all:
        startDate = DateTime(2000);
        break;
    }

    final db = Provider.of<HiveDatabase>(context, listen: false);
    List<WeightLog> filteredLogs = db.getWeightLogs().where((log) {
      return log.date.isAfter(startDate) && log.date.isBefore(now);
    }).toList();

    setState(() {
      logs = filteredLogs;
    });
  }

  List<FlSpot> _getSpots() {
    return logs.map((log) {
      return FlSpot(
        log.date.millisecondsSinceEpoch.toDouble(),
        log.weight,
      );
    }).toList();
  }

  Widget _buildChart() {
    if (logs.isEmpty) {
      return Center(child: Text("No weight data available"));
    }
    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true, drawVerticalLine: false,),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                // You can further format the value or style it as needed
                return Text(
                  value.toString(),
                  style: TextStyle(color: Colors.white, fontSize: 12),
                  textAlign: TextAlign.right,
                );
              },
              reservedSize: 40,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: _getSpots(),
            isCurved: false,
            barWidth: 4,
            color: Colors.purpleAccent,
            belowBarData: BarAreaData(show: false),
            dotData: FlDotData(show: true),

          ),

        ],

        minX: logs.map((log) => log.date.millisecondsSinceEpoch.toDouble()).reduce(min),
        maxX: logs.map((log) => log.date.millisecondsSinceEpoch.toDouble()).reduce(max),
        minY: logs.map((log) => log.weight).reduce(min),
        maxY: logs.map((log) => log.weight).reduce(max),
      ),
    );
  }
  Widget _buildWeightItem(WeightLog log, int index) {
    IconData icon = Icons.horizontal_rule;  // Default icon for no change
    Color iconColor = Colors.grey;  // Default color for no change
    String weightChange = '';  // Initialize an empty string for weight change
    TextStyle weightChangeStyle;  // Define a style for the weight change text

    if (index < logs.length - 1) {  // Ensure there's a next log to compare with
      final nextLog = logs[index + 1];  // Get the next log in the list
      double change = log.weight - nextLog.weight;  // Calculate the weight difference

      if (change > 0) {
        icon = Icons.arrow_upward;  // Up arrow for weight gain
        iconColor = Colors.purple.shade300;  // Green for gain
        weightChange = "+${change.toStringAsFixed(1)} lbs";  // Format gain as positive
        weightChangeStyle = TextStyle(color: Colors.grey[400], fontSize: 14);  // Green text for weight gain
      } else if (change < 0) {
        icon = Icons.arrow_downward;  // Down arrow for weight loss
        iconColor = Colors.purple.shade300;  // Red for loss
        weightChange = "${change.toStringAsFixed(1)} lbs";  // Format loss as negative
        weightChangeStyle = TextStyle(color: Colors.grey[400], fontSize: 14);  // Red text for weight loss
      } else {
        weightChangeStyle = TextStyle(color: iconColor, fontSize: 14);  // Default grey text if no change
      }
    } else {
      weightChangeStyle = TextStyle(color: iconColor, fontSize: 14);  // Ensure there is always a style even if no change
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "${log.weight} lbs",
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          Row(
            children: [
              Icon(icon, color: iconColor),
              SizedBox(width: 8),  // Space between the icon and the text
              Text(weightChange, style: weightChangeStyle)  // Apply the defined text style here
            ],
          ),
          Text(
            DateFormat('EEE, MMM d').format(log.date),  // 'EEE' for abbreviated day of the week, 'MMM' for abbreviated month, 'd' for day of the month without leading zeros
            style: TextStyle(color: Colors.grey[400], fontSize: 16),
          ),
        ],
      ),
    );
  }


  Widget _timeButton(String text, TimeView timeView) {
    bool isSelected = _selectedTimeView == timeView;  // Check if this button is selected
    return TextButton(
      onPressed: () => _updateTimeView(timeView),
      child: Text(text, style: TextStyle(color: isSelected ? Colors.grey[800] : Colors.white)),
      style: TextButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        backgroundColor: isSelected ? Colors.white : Colors.grey[800],  // Toggle color based on selection
        padding: EdgeInsets.symmetric(horizontal: 16),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        title: Text("Scale Weight", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),),
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          SizedBox(height: 50),
          Container(
            height:250,   // Gives 5 times more space to the chart than to the buttons
            child: _buildChart(),
          ),

          Container(
            margin: EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.grey[800], // Grey color for the container
              borderRadius: BorderRadius.circular(30), // Circular borders
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
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[850], // Lighter grey background
                borderRadius: BorderRadius.circular(15), // Rounded edges
              ),
              child: ListView.separated(
                padding: EdgeInsets.all(8), // Ensures padding inside the container
                itemCount: logs.length,
                itemBuilder: (context, index) {
                  final log = logs[index];
                  return _buildWeightItem(log, index);
                },
                separatorBuilder: (context, index) => Divider(color: Colors.grey[500]),  // Adjust the divider color for better contrast
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addWeightLog,
        child: Icon(Icons.add),
        tooltip: 'Log Weight',
      ),
    );
  }


  Future<void> _addWeightLog() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      final String? weight = await _showWeightInputDialog();
      if (weight != null && weight.isNotEmpty) {
        final db = Provider.of<HiveDatabase>(context, listen: false);
        final log = WeightLog(date: pickedDate, weight: double.parse(weight));
        db.saveWeightLog(log);
        _fetchLogs();
        setState(() {});
      }
    }
  }

  Future<String?> _showWeightInputDialog() async {
    TextEditingController controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Enter your weight'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: 'Weight (lbs)'),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Save'),
              onPressed: () => Navigator.of(context).pop(controller.text),
            ),
          ],
        );
      },
    );
  }
}
