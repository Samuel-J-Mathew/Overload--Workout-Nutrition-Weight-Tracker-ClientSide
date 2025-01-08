import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/hive_database.dart';
import '../models/step_log.dart';  // Ensure StepLog is correctly modeled
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

class StepCounterPage extends StatefulWidget {
  @override
  _StepCounterPageState createState() => _StepCounterPageState();

  static Widget buildStepChart(BuildContext context) {
    final db = Provider.of<HiveDatabase>(context, listen: false);
    List<StepLog> logs = db.getStepLogs();  // Fetch Step logs
    if (logs.isEmpty) {
      return Center(child: Text("No step data available"));
    }
    List<FlSpot> spots = logs.map((log) {
      return FlSpot(
        log.date.millisecondsSinceEpoch.toDouble(),
        log.steps.toDouble(),  // Assuming 'steps' is an int
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
            color: Colors.green[300],  // Choose a different color if you like
            belowBarData: BarAreaData(show: false),
            dotData: FlDotData(show: true),
          ),
        ],
        minX: logs.map((log) => log.date.millisecondsSinceEpoch.toDouble()).reduce(min),
        maxX: logs.map((log) => log.date.millisecondsSinceEpoch.toDouble()).reduce(max),
        minY: logs.map((log) => log.steps.toDouble()).reduce(min),
        maxY: logs.map((log) => log.steps.toDouble()).reduce(max),
      ),
    );
  }
}

class _StepCounterPageState extends State<StepCounterPage> {
  List<StepLog> logs = [];

  void _fetchLogs() {
    final db = Provider.of<HiveDatabase>(context, listen: false);
    logs = db.getStepLogs();  // Fetch logs from database
    if (logs.isEmpty) {
      setState(() {});  // To refresh and show "No data" message if needed
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchLogs();  // Initial fetch
  }

  Future<void> _addStepLog() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      final String? steps = await _showStepInputDialog();
      if (steps != null && steps.isNotEmpty) {
        final db = Provider.of<HiveDatabase>(context, listen: false);
        final log = StepLog(date: pickedDate, steps: int.parse(steps));
        db.saveStepLog(log);
        _fetchLogs();  // Refresh logs after adding
        setState(() {});  // Trigger rebuild with updated logs
      }
    }
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
                Navigator.of(context).pop(controller.text);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildChart() {
    if (logs.isEmpty) {
      return Center(child: Text("Log your steps, no data available"));
    }
    return StepCounterPage.buildStepChart(context);  // Use static method to build chart
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: Text("Step Counter", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.grey[900],
      ),
      body: Column(
        children: [
          SizedBox(height: 20),
          Container(
            height: 200, // Increased height for better visibility
            child: _buildChart(),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: logs.length,
              itemBuilder: (context, index) {
                final log = logs[index];
                return ListTile(
                  title: Text("${log.steps} steps", style: TextStyle(color: Colors.white)),
                  subtitle: Text(DateFormat('MM-dd-yyyy').format(log.date), style: TextStyle(color: Colors.grey[700])),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addStepLog,
        child: Icon(Icons.add),
        tooltip: 'Log Steps',
      ),
    );
  }
}
