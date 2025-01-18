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
    // Sort logs by date in ascending order
    logs.sort((a, b) => a.date.compareTo(b.date));
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

    // Sort the filtered logs in ascending order by date
    filteredLogs.sort((a, b) => a.date.compareTo(b.date));

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
    TextStyle weightChangeStyle = TextStyle(color: iconColor, fontSize: 14);  // Default grey text if no change

    // Adjust to use previous log for comparison
    if (index > 0) {  // Ensure there's a previous log to compare with
      final prevLog = logs[index - 1];  // Get the previous log in the list
      double change = log.weight - prevLog.weight;  // Calculate the weight difference

      if (change > 0) {
        icon = Icons.arrow_upward;  // Up arrow for weight gain
        iconColor = Colors.green;  // Green for gain
        weightChange = "+${change.toStringAsFixed(1)} lbs";  // Format gain as positive
        weightChangeStyle = TextStyle(color: Colors.white, fontSize: 14);  // Green text for weight gain
      } else if (change < 0) {
        icon = Icons.arrow_downward;  // Down arrow for weight loss
        iconColor = Colors.red;  // Red for loss
        weightChange = "${change.toStringAsFixed(1)} lbs";  // Format loss as negative
        weightChangeStyle = TextStyle(color: Colors.white, fontSize: 14);  // Red text for weight loss
      }
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
            DateFormat('EEE, MMM d').format(log.date),
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
        backgroundColor: isSelected ? Colors.white : Color.fromRGBO(31, 31, 31, 1),  // Toggle color based on selection
        padding: EdgeInsets.symmetric(horizontal: 16),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(20, 20, 20, 1),
      appBar: AppBar(
        backgroundColor: Color.fromRGBO(31, 31, 31, 1),
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
              color: Color.fromRGBO(31, 31, 31, 1),// Grey color for the container
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
                color: Color.fromRGBO(31, 31, 31, 1), // Lighter grey background
                borderRadius: BorderRadius.circular(15), // Rounded edges
              ),
              child: ListView.separated(
                padding: EdgeInsets.all(8), // Ensures padding inside the container
                itemCount: logs.length,
                itemBuilder: (context, index) {
                  final log = logs[logs.length - 1 - index];
                  return _buildWeightItem(log, logs.length - 1 - index);
                },
                separatorBuilder: (context, index) => Divider(color: Colors.grey[700]),  // Adjust the divider color for better contrast
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
    // Initialize with today's date, but let user change it in the dialog
    DateTime selectedDate = DateTime.now();
    final result = await _showWeightInputDialog(selectedDate);

    if (result != null && result['weight'].isNotEmpty) {
      final db = Provider.of<HiveDatabase>(context, listen: false);
      final log = WeightLog(date: result['date'], weight: double.parse(result['weight']));
      db.saveWeightLog(log);
      _fetchLogs();  // Refresh logs after adding
    }
  }

  Future<Map<String, dynamic>?> _showWeightInputDialog(DateTime initialDate) async {
    TextEditingController controller = TextEditingController();
    DateTime selectedDate = initialDate;

    Future<void> _changeDate(BuildContext dialogContext) async {
      DateTime? newDate = await showDatePicker(
        context: dialogContext,
        initialDate: selectedDate,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
      );
      if (newDate != null && newDate != selectedDate) {
        selectedDate = newDate;
        (dialogContext as Element).markNeedsBuild(); // Force rebuild of the dialog
      }
    }

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext dialogContext, StateSetter setState) {
            return AlertDialog(
              title: GestureDetector(
                onTap: () => _changeDate(dialogContext),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, size: 20),
                    SizedBox(width: 8),
                    Text(DateFormat('yyyy-MM-dd').format(selectedDate)),  // Display selected date
                  ],
                ),
              ),
              content: TextField(
                controller: controller,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: 'Weight (lbs)'),
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
                    Navigator.of(context).pop({
                      'weight': controller.text,
                      'date': selectedDate
                    });
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

}
