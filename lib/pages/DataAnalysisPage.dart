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
    exerciseNames = Provider.of<WorkoutData>(context, listen: false).getAllExerciseNames();
    selectedExercise = exerciseNames.isNotEmpty ? exerciseNames.first : null;
  }

  @override
  Widget build(BuildContext context) {
    var workoutData = Provider.of<WorkoutData>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text("Exercise Data Analysis"),
      ),
      body: Column(
        children: [
          DropdownButton<String>(
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
