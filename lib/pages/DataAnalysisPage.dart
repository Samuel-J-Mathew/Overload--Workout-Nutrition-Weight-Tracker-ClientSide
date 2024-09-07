import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/workout_data.dart';

class DataAnalysisPage extends StatefulWidget {
  @override
  _DataAnalysisPageState createState() => _DataAnalysisPageState();
}

class _DataAnalysisPageState extends State<DataAnalysisPage> {
  String? selectedExercise;
  List<String> exerciseNames = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadExerciseNames();
    });
  }

  void loadExerciseNames() {
    exerciseNames = Provider.of<WorkoutData>(context, listen: false).getAllExerciseNames();
    if (exerciseNames.isNotEmpty) {
      selectedExercise = exerciseNames.first;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    var workoutData = Provider.of<WorkoutData>(context);
    List<Map<String, dynamic>> weightData = selectedExercise != null ? workoutData.getWeightDataForExercise(selectedExercise!) : [];
    List<FlSpot> spots = weightData.asMap().entries.map((entry) => FlSpot(entry.key.toDouble(), entry.value['weight'])).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text("Exercise Data Analysis"),
      ),
      body: Column(
        children: [
          if (exerciseNames.isNotEmpty) DropdownButton<String>(
            value: selectedExercise,
            onChanged: (value) {
              setState(() {
                selectedExercise = value;
              });
            },
            items: exerciseNames.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
          Expanded(
            child: spots.isNotEmpty ? LineChart(
              LineChartData(
                gridData: FlGridData(show: true),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) => Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(value.toInt().toString()), // Display index on x-axis
                      ),
                      interval: 1,
                    ),
                  ),

                ),

                lineBarsData: [LineChartBarData(spots: spots)],



              ),
            ) : Center(child: Text("No data available for this exercise")),
          ),
          Expanded(
            child: ListView(
              children: workoutData.getExercisesByName(selectedExercise!).map((detail) {
                return ListTile(
                  title: Text(detail.exercise.name),
                  subtitle: Text('Sets: ${detail.exercise.sets}, Reps: ${detail.exercise.reps}, Weight: ${detail.exercise.weight}'),
                  trailing: Text(DateFormat('yyyy-MM-dd').format(detail.date)), // Display the date of the exercise
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
