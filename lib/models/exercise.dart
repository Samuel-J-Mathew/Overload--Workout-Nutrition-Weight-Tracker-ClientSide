class Exercise{
  final String name;
   String weight;
   String reps;
   String sets;
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