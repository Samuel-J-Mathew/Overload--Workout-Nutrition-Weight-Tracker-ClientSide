//import 'package:fl_chart/fl_chart.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:gymapp/data/hive_database.dart';
import 'package:intl/intl.dart';

import '../models/exercise.dart';
import '../models/exercisedetail.dart';
import '../models/workout.dart';

class WorkoutData extends ChangeNotifier{
  final db = HiveDatabase();

  List<Workout> workoutList = [
    Workout(
      name: "Chest",
      date:  DateTime(2024, 9, 1),
      exercises: [
        Exercise(
          name: "BB Bench",
          weight: "10",
          reps: "10",
          sets: "6",
          musclegroup: "Chest",

        ),
        Exercise(
          name: "DB Bench",
          weight: "10",
          reps: "8",
          sets: "7",
          musclegroup: "Chest",

        ),
      ],
    ),
    Workout(
      name: "Arms",
      date:  DateTime(2024, 9, 3),
      exercises: [
        Exercise(
            name: "Bicep Curls",
            weight: "10",
            reps: "10",
            sets: "3",
            musclegroup: "Biceps",
        ),
      ],
    )
  ];

  //if there are wrokouts alreadyt in database, then get that workout list, otherwise use defaul workouts
  //otherwise use defaults workouts
  void initalizeWorkoutList(){
    if(db.previousDataExists()){
      workoutList = db.readFromDatabase();
    }else{
      db.saveToDatebase(workoutList);
    }
  }


  // get the list of workouts
  List<Workout> getworkoutList (){
    return workoutList;
  }
  // Method to get workouts for a specific date
  List<Workout> getWorkoutsForDate(DateTime date) {
    return workoutList.where((workout) {
      return workout.date.year == date.year &&
          workout.date.month == date.month &&
          workout.date.day == date.day;
    }).toList();
  }
  // Get workout by ID
  Workout getWorkoutById(String workoutId) {
    return workoutList.firstWhere((workout) => workout.id == workoutId);
  }
  List<String> getAllExerciseNames() {
    Set<String> exerciseNames = {};
    for (var workout in workoutList) {
      for (var exercise in workout.exercises) {
        exerciseNames.add(exercise.name);
      }
    }
    return exerciseNames.toList();
  }
  List<ExerciseDetail> getExercisesByName(String exerciseName) {
    List<ExerciseDetail> filteredExercises = [];
    for (var workout in workoutList) {
      for (var exercise in workout.exercises) {
        if (exercise.name == exerciseName) {
          filteredExercises.add(ExerciseDetail(exercise, workout.date));
        }
      }
    }
    return filteredExercises;
  }

  List<Workout> getWorkoutsByMonth(int year, int month) {
    return workoutList.where((workout) =>
    workout.date.year == year && workout.date.month == month
    ).toList();
  }
  // This method will return a map of dates and workout counts
  Map<DateTime, int> getWorkoutDatesForHeatMap() {
    Map<DateTime, int> heatMapData = {};

    for (var workout in workoutList) {
      DateTime workoutDate = DateTime(workout.date.year, workout.date.month, workout.date.day); // normalize to remove time
      if (heatMapData.containsKey(workoutDate)) {
        heatMapData[workoutDate] = heatMapData[workoutDate]! + 1;
      } else {
        heatMapData[workoutDate] = 1;
      }
    }

    return heatMapData;
  }
  //get length of a given workout
  int numberofExercisesInWorkout(String workoutName){
    Workout relevantWorkout = getRelevantWorkout(workoutName);
    return relevantWorkout.exercises.length;
  }
  // add a workout
  // Method to add a new workout, and return the workout's unique ID
  String addWorkout(String workoutName, DateTime date) {
    final newWorkout = Workout(
      name: workoutName,
      exercises: [],  // Start with an empty list of exercises
      date: date,
    );
    workoutList.add(newWorkout);
    notifyListeners();
    return newWorkout.id;  // Return the unique ID of the newly added workout
  }

  // New method to print all workout dates
  void printAllWorkoutDates() {
    for (var workout in workoutList) {
      print(DateFormat('yyyy-MM-dd').format(workout.date));
    }
  }


  // add exercise to a workout
  void addExercise(String workoutId, String name, String weight, String reps, String sets, String muscleGroup) {
    Workout workout = getWorkoutById(workoutId);

    // Ensure that the required muscleGroup argument is passed when creating a new Exercise
    workout.exercises.add(Exercise(
      name: name,
      weight: weight,
      reps: reps,
      sets: sets,
      musclegroup: muscleGroup,  // Add the missing musclegroup argument
    ));

    notifyListeners();
  }
  // check off exercise
  void checkOffExercise(String workoutName, String exerciseName){
    //find relevant exercise in that workout
    Exercise relevantExercise = getRelevantExercise(workoutName, exerciseName);

    // check off boolean to show user completed the workout
    relevantExercise.isCompleted =!relevantExercise.isCompleted;
    print('tapped');
    notifyListeners();
    //save to database
    db.saveToDatebase(workoutList);
  }
// Get weight data and respective dates for plotting
  List<Map<String, dynamic>> getWeightDataForExercise(String exerciseName) {
    List<Map<String, dynamic>> dataPoints = [];
    DateTime startDate = workoutList.isNotEmpty ? workoutList.first.date : DateTime.now();
    for (var workout in workoutList) {
      for (var exercise in workout.exercises) {
        if (exercise.name == exerciseName) {
          double days = workout.date.difference(startDate).inDays.toDouble();
          int weight = int.tryParse(exercise.weight) ?? 0;
          dataPoints.add({
            "days": days,
            "weight": weight.toDouble(),
            "date": workout.date
          });
        }
      }
    }
    return dataPoints;
  }
  void deleteExercise(String workoutName, int index) {
    // Find the workout and remove the exercise by index
    var workout = workoutList.firstWhere((w) => w.name == workoutName);
    workout.exercises.removeAt(index);
    notifyListeners(); // Notify listeners to update the UI
  }
  // return relevant workout object, given a workout name
  Workout getRelevantWorkout(String workoutName){
    Workout relevantWorkout =
    workoutList.firstWhere((workout) =>workout.name == workoutName);

    return relevantWorkout;
  }
  // return relevant exercise object, given a workout name + exercise name
  Exercise getRelevantExercise(String workoutName, String exerciseName){
    // find relevant workout first
    Workout relevantWorkout = getRelevantWorkout(workoutName);
    // then find the relevant exercise in that workout
    Exercise relevantExercise =
        relevantWorkout.exercises.firstWhere((exercise) => exercise.name == exerciseName);
    return relevantExercise;
  }
  // Find the highest weight and its corresponding reps for a given exercise across all workouts
  Map<String, int> findHighestWeightAndRepsForExercise(String exerciseName) {
    int maxWeight = 0; // Initialize the maximum weight to zero
    int maxReps = 0; // Initialize the reps at maximum weight to zero

    for (Workout workout in workoutList) {
      for (Exercise exercise in workout.exercises) {
        if (exercise.name == exerciseName) {
          int currentWeight = int.tryParse(exercise.weight) ?? 0; // Convert string weight to int
          if (currentWeight > maxWeight) {
            maxWeight = currentWeight; // Update maxWeight if currentWeight is higher
            maxReps = int.tryParse(exercise.reps) ?? 0; // Update maxReps to reps at current max weight
          }
        }
      }
    }
    return {'weight': maxWeight, 'reps': maxReps}; // Return highest weight and its reps as integers
  }
  //Access the weight or reps by doing this:
  //Map<String, String> highestWeightAndReps = findHighestWeightAndRepsForExercise("Bicep Curls");
  // int highestWeight = highestWeightAndReps['weight'];
  // int highestReps = highestWeightAndReps['reps'];


  // Count the total amount of sets in a given muscle group
  int totalMusclegroupSets(String musclegroup) {
    int count = 0; // Initialize the count to zero
    for (Workout workout in workoutList) {
      for (Exercise exercise in workout.exercises) {
        if (exercise.musclegroup == musclegroup) {
          int currentSets = int.tryParse(exercise.sets) ?? 0; // Convert string weight to int
          count = count + currentSets;
        }
      }
    }
    return count;
  }
}