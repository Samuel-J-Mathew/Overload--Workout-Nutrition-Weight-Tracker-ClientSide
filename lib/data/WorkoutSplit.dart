// Define the ExerciseDetail class to store details about each exercise.
class ExerciseDetail {
  String name;
  int reps;
  int sets;
  double weight;

  ExerciseDetail({required this.name, required this.reps, required this.sets, required this.weight});

  // Method to create an instance from a map
  factory ExerciseDetail.fromMap(Map<String, dynamic> map) {
    return ExerciseDetail(
      name: map['name'] as String,
      reps: map['reps'] as int,
      sets: map['sets'] as int,
      weight: (map['weight'] as num).toDouble(), // Convert to double safely
    );
  }
}

// Define the MuscleGroupSplit class to store exercises under a muscle group.
class MuscleGroupSplit {
  String muscleGroupName;
  List<ExerciseDetail> exercises;

  MuscleGroupSplit({required this.muscleGroupName, required this.exercises});
  // Method to create an instance from a map
  factory MuscleGroupSplit.fromMap(Map<String, dynamic> map) {
    return MuscleGroupSplit(
      muscleGroupName: map['muscleGroupName'] as String,
      exercises: List<ExerciseDetail>.from(
          map['exercises'].map((x) => ExerciseDetail.fromMap(x as Map<String, dynamic>))
      ),
    );
  }
}

// Define the WorkoutSplit class to store all muscle groups under a specific day.
class WorkoutSplit {
  String day;
  List<MuscleGroupSplit> muscleGroups;

  WorkoutSplit({required this.day, required this.muscleGroups});
  factory WorkoutSplit.fromMap(Map<String, dynamic> map) {
    return WorkoutSplit(
      day: map['day'] as String,
      muscleGroups: List<MuscleGroupSplit>.from(
          map['muscleGroups'].map((x) => MuscleGroupSplit.fromMap(x as Map<String, dynamic>))
      ),
    );
  }
}
