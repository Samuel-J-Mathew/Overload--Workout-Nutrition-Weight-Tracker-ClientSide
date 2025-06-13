import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/workout_data.dart';
import '../models/workout.dart';

class ExerciseLogSummaryTile extends StatelessWidget {
  final DateTime selectedDate;
  const ExerciseLogSummaryTile({Key? key, required this.selectedDate}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<Workout> workouts = Provider.of<WorkoutData>(context, listen: false).getWorkoutsForDate(selectedDate);
    int totalSets = 0;
    double totalVolume = 0;
    Set<String> uniqueExercises = {};

    for (var workout in workouts) {
      for (var exercise in workout.exercises) {
        int sets = int.tryParse(exercise.sets) ?? 0;
        int reps = int.tryParse(exercise.reps) ?? 0;
        double weight = double.tryParse(exercise.weight) ?? 0;
        totalSets += sets;
        totalVolume += sets * weight;
        uniqueExercises.add(exercise.name);
      }
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      padding: EdgeInsets.symmetric(vertical: 24, horizontal: 0),
      decoration: BoxDecoration(
        color: Color(0xFF121212),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _statColumn(Icons.view_module, totalSets, 'sets', Colors.blue),
          _statColumn(Icons.fitness_center, uniqueExercises.length, 'exercises', Colors.greenAccent),
          _statColumnDouble(Icons.bar_chart, totalVolume, 'volume', Colors.purpleAccent),
        ],
      ),
    );
  }

  Widget _statColumn(IconData icon, int value, String label, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 32),
        SizedBox(height: 6),
        Text(
          value.toString(),
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _statColumnDouble(IconData icon, double value, String label, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 32),
        SizedBox(height: 6),
        Text(
          value % 1 == 0 ? value.toInt().toString() : value.toStringAsFixed(1),
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}