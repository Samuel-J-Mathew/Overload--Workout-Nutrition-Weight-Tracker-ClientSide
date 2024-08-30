class Exercise{
  final String name;
  final String weight;
  final String reps;
  final String sets;
  final String musclegroup;
  bool isCompleted;

  Exercise({
    required this.name,
    required this.weight,
    required this.reps,
    required this.sets,
    required this.musclegroup,
    this.isCompleted = false,
   });
}