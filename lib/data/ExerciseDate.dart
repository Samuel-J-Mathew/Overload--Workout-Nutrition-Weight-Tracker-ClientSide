class ExerciseData {
  static final List<ExerciseModel> predefinedExercises = [
    ExerciseModel(name: "Bench Press", muscleGroup: "Chest"),
    ExerciseModel(name: "Bicep Curl", muscleGroup: "Biceps"),
    // Add more predefined exercises here
  ];

  static List<ExerciseModel> getExercises() {
    return predefinedExercises;
  }

  static void addExercise(ExerciseModel exercise) {
    if (!predefinedExercises.any((ex) => ex.name == exercise.name)) {
      predefinedExercises.add(exercise);
    }
  }
}
