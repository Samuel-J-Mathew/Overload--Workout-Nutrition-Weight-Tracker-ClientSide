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
  }) : id = const Uuid().v4(); // Generate a unique ID for each workout
}