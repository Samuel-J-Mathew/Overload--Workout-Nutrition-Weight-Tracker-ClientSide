// Define the ExerciseDetail class to store details about each exercise.
class ExerciseDetail {
  String name;
  int reps;
  int sets;
  double weight;

  ExerciseDetail({required this.name, required this.reps, required this.sets, required this.weight});
}

// Define the MuscleGroupSplit class to store exercises under a muscle group.
class MuscleGroupSplit {
  String muscleGroupName;
  List<ExerciseDetail> exercises;

  MuscleGroupSplit({required this.muscleGroupName, required this.exercises});
}

// Define the WorkoutSplit class to store all muscle groups under a specific day.
class WorkoutSplit {
  String day;
  List<MuscleGroupSplit> muscleGroups;

  WorkoutSplit({required this.day, required this.muscleGroups});
}
