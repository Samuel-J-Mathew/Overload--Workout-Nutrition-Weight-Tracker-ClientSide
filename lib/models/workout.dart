import 'package:intl/intl.dart';

import 'exercise.dart';
import 'package:uuid/uuid.dart';
class Workout {
  final String id; // Unique identifier for each workout
  DateTime date;
  final String name;
  final List<Exercise> exercises;

  Workout({
    required this.name,
    required this.exercises,
    required this.date
  }) : id = DateFormat('yyyy-MM-dd').format(date); // ID generated based on the date
}