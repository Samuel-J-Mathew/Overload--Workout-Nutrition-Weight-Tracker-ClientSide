import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/hive_database.dart';
import '../models/weight_log.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

class WeightLogPage extends StatefulWidget {
  @override
  _WeightLogPageState createState() => _WeightLogPageState();

  static Widget buildWeightChart(BuildContext context) {
    final db = Provider.of<HiveDatabase>(context, listen: false);
    List<WeightLog> logs = db.getWeightLogs();

    List<FlSpot> spots = logs.map((log) {
      return FlSpot(
        log.date.millisecondsSinceEpoch.toDouble(),
        log.weight,
      );
    }).toList();

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: false,
            barWidth: 3,
            color: Colors.purple[300],
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
}

class _WeightLogPageState extends State<WeightLogPage> {
  List<WeightLog> logs = [];

  void _fetchLogs() {
    final db = Provider.of<HiveDatabase>(context, listen: false);
    logs = db.getWeightLogs();  // Fetch logs from database
  }
  List<FlSpot> _getSpots() {
    return logs.map((log) {
      return FlSpot(
        log.date.millisecondsSinceEpoch.toDouble(),
        log.weight,
      );
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _fetchLogs();  // Initial fetch
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
        _fetchLogs();  // Refresh logs after adding
        setState(() {});  // Trigger rebuild with updated logs
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

  Widget _buildChart() {
    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: _getSpots(),
            isCurved: false,
            barWidth: 3,
            color: Colors.blue,
            belowBarData: BarAreaData(show: false),
            dotData: FlDotData(show: true, ),
          ),
        ],
        minX: logs.map((log) => log.date.millisecondsSinceEpoch.toDouble()).reduce(min),
        maxX: logs.map((log) => log.date.millisecondsSinceEpoch.toDouble()).reduce(max),
        minY: logs.map((log) => log.weight).reduce(min),
        maxY: logs.map((log) => log.weight).reduce(max),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Weight Log"),
      ),
      body: Column(
        children: [
          SizedBox(height: 100,),
          Container(
            height: 100,
            // Set a fixed height for the chart
            child: _buildChart(),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: logs.length,
              itemBuilder: (context, index) {
                final log = logs[index];
                return ListTile(
                  title: Text("${log.weight} lbs"),
                  subtitle: Text(DateFormat('MM-dd-yyyy').format(log.date)),
                );
              },
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

}
