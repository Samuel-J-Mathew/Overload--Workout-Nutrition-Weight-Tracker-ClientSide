import 'exercise.dart';

class Workout {
  DateTime date;
  final String name;
  final List<Exercise> exercises;

  Workout({required this.name, required this.exercises, required this.date});
}