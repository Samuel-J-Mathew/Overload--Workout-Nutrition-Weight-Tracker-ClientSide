import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MetricsPage extends StatefulWidget {
  final String uid; // User ID is needed to fetch specific user data

  MetricsPage({required this.uid});

  @override
  _MetricsPageState createState() => _MetricsPageState();
}

class _MetricsPageState extends State<MetricsPage> {
  List<Map<String, dynamic>> weightLogs = [];

  @override
  void initState() {
    super.initState();
    fetchWeightLogs();
  }

  void fetchWeightLogs() async {
    var logsCollection = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.uid)
        .collection('weightLogs');
    var snapshot = await logsCollection.get();

    List<Map<String, dynamic>> logs = [];
    for (var doc in snapshot.docs) {
      var data = doc.data();
      var docDate = doc.id; // Document ID as date

      // Debugging: Print the docDate to check format
      print("Document date: $docDate");

      if (data != null && data['weight'] != null) {
        logs.add({'date': docDate, 'weight': data['weight'].toString()});
      }
    }
    setState(() {
      weightLogs = logs;
    });
  }

  List<FlSpot> getSpots() {
    List<FlSpot> spots = [];
    for (int i = 0; i < weightLogs.length; i++) {
      double x = i.toDouble(); // Use index for x-axis to avoid parsing issues
      double y = double.tryParse(weightLogs[i]['weight'].toString()) ?? 0.0;
      spots.add(FlSpot(x, y));
      print("Added spot: X=$x, Y=$y"); // Debugging
    }
    return spots;
  }

  LineChartData mainChartData() {
    return LineChartData(
        gridData: FlGridData(show: true),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                if (value.toInt() < weightLogs.length) {
                  // Use a simple formatter for the date
                  String formattedDate = weightLogs[value.toInt()]['date'];
                  return Text(
                      formattedDate.substring(4, 6) +
                          '/' +
                          formattedDate.substring(6, 8),
                      style: TextStyle(color: Colors.black, fontSize: 10));
                }
                return Text('');
              },
              interval: 1,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) => Text('${value.toInt()} lb',
                  style: TextStyle(color: Colors.black, fontSize: 10)),
              interval: 10,
            ),
          ),
        ),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: getSpots(),
            isCurved: true,
            color: Colors.blue,
            barWidth: 2,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(show: false),
          )
        ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Weight Metrics"),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            flex: 1,
            child: Container(
              margin: EdgeInsets.all(8.0),
              child: LineChart(mainChartData()),
            ),
          ),
          Expanded(
            flex: 1,
            child: ListView.builder(
              itemCount: weightLogs.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text("${weightLogs[index]['weight']} lb"),
                  subtitle: Text("${weightLogs[index]['date']}"),
                  trailing: Text("Value"),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
