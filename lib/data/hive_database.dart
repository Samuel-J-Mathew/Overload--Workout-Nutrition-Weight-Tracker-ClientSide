import 'dart:io';

import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:gymapp/data/FoodItemDatabase.dart';
import 'package:gymapp/datetime/date_time.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/FoodDay.dart';
import '../models/exercise.dart';
import '../models/step_log.dart';
import '../models/weight_log.dart';
import '../models/workout.dart';
import 'WorkoutSplit.dart';

class HiveDatabase {
  //reference our hive box
  final _myBox = Hive.box("workout_database");
 final Box<FoodItemDatabase> foodBox = Hive.box<FoodItemDatabase>('food_items');
  final Box<WeightLog> box = Hive.box<WeightLog>('weight_logs');
  final Box<StepLog> stepBox = Hive.box<StepLog>('stepLogs');
  //check if there is already data stored, if not , record the start date
  bool previousDataExists(){
    if(_myBox.isEmpty){
      print("previous object does NOT exists");
      _myBox.put("START_DATE", todaysDateYYYYMMDD());
      return false;
    }else{
      print("previous data does exists");
      return true;
    }

  }
  Future<void> openFile(String filePath) async {
    final Uri fileUri = Uri.file(filePath);
    if (await canLaunchUrl(fileUri)) {
      await launchUrl(fileUri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not open file at $filePath';
    }
  }
  // return start date as yyymmdd
  String getStartDate(){
    return _myBox.get("START_DATE");
  }
  Future<Map<DateTime, int>> getWorkoutDataForHeatMap() async {
    Map<DateTime, int> result = {};
    // Assuming `_myBox` is a Hive box that already has all necessary data loaded
    List<Workout> workouts = _myBox.get('workouts', defaultValue: []);
    for (Workout workout in workouts) {
      DateTime workoutDate = workout.date;
      result[workoutDate] = (result[workoutDate] ?? 0) + 1;
    }
    return Future.value(result); // Convert the result to a Future
  }
  List<FoodItemDatabase> getAllFoodItems() {
    return foodBox.values.toList();
  }
  // Method to fetch all food items and print them
  void printAllFoodItems() {
    List<FoodItemDatabase> allFoodItems = foodBox.values.toList();
    if (allFoodItems.isEmpty) {
      print("No food items found in the database.");
    } else {
      print("Listing all food items:");
      for (FoodItemDatabase item in allFoodItems) {
        print("ID: ${item.id}, Name: ${item.name}, Calories: ${item.calories}, Protein: ${item.protein}, Carbs: ${item.carbs}, Fats: ${item.fats}, Date: ${item.date}");
      }
    }
  }
  void deleteFoodItem(String id) {
    // Find the key by matching the `id` of the food item
    final key = foodBox.keys.firstWhere(
          (k) {
        final foodItem = foodBox.get(k);
        return foodItem != null && foodItem.id == id;
      },
      orElse: () => null, // Return null if no match is found
    );

    // If a key was found, delete the item
    if (key != null) {
      foodBox.delete(key);
      print("Food item with ID $id deleted successfully.");
    } else {
      print("No food item found with ID $id.");
    }
  }
// Method to export data to an Excel file
  Future<String> exportDataToExcel() async {
    var excel = Excel.createExcel();
    // 1. Gym Logs Sheet
    var gymSheet = excel['Gym Logs'];
    gymSheet.appendRow(['Date', 'Workout Name', 'Reps', 'Sets', 'Weight', 'Muscle Group', 'Total Sets']);

    List<Workout> workouts = readFromDatabase();
    workouts.sort((a, b) => a.date.compareTo(b.date)); // Sort by date

    DateTime? lastGymDate;
    int dailySets = 0;
    bool hasEntriesForDate = false; // Track if entries exist for a given date

    for (var workout in workouts) {
      if (lastGymDate != null && !isSameDay(lastGymDate, workout.date)) {
        if (hasEntriesForDate) {
          // Add total sets row for the previous day
          gymSheet.appendRow(['', '', '', '', '', 'Total Sets:', dailySets.toString()]);
          gymSheet.appendRow([]); // Add empty row to separate days
        }
        dailySets = 0; // Reset daily sets count
        hasEntriesForDate = false; // Reset flag for the new day
      }

      lastGymDate = workout.date;

      for (var exercise in workout.exercises) {
        dailySets += int.tryParse(exercise.sets) ?? 0;
        hasEntriesForDate = true; // Mark that there are entries for the day

        gymSheet.appendRow([
          workout.date.toIso8601String().split('T').first,
          exercise.name,
          exercise.reps,
          exercise.sets,
          exercise.weight,
          exercise.musclegroup,
          '', // Placeholder for Total Sets
        ]);
      }
    }

// Add total sets for the last day if entries exist
    if (hasEntriesForDate) {
      gymSheet.appendRow(['', '', '', '', '', 'Total Sets:', dailySets.toString()]);
    }

    // 2. Step Logs Sheet
    var stepSheet = excel['Step Logs'];
    stepSheet.appendRow(['Date', 'Steps']);
    List<StepLog> stepLogs = getStepLogs();
    for (var stepLog in stepLogs) {
      stepSheet.appendRow([stepLog.date.toIso8601String().split('T').first, stepLog.steps]);
    }

    // 3. Food Logs Sheet

    var foodSheet = excel['Food Logs'];
    foodSheet.appendRow(['Date', 'Food Name', 'Calories', 'Protein', 'Carbs', 'Fats', 'Total Calories']);

    List<FoodItemDatabase> foodLogs = getFoodLogs();
    foodLogs.sort((a, b) => a.date.compareTo(b.date)); // Sort by date

    DateTime? lastFoodDate;
    double dailyCalories = 0;

    for (var foodLog in foodLogs) {
      if (lastFoodDate != null && !isSameDay(lastFoodDate, foodLog.date)) {
        // Add total calories for the previous day
        foodSheet.appendRow(['', '', '', '', '', 'Total:', dailyCalories.toStringAsFixed(0)]);
        foodSheet.appendRow([]); // Add empty row to separate days
        dailyCalories = 0; // Reset daily calories
      }
      lastFoodDate = foodLog.date;

      dailyCalories += double.tryParse(foodLog.calories) ?? 0;

      foodSheet.appendRow([
        foodLog.date.toIso8601String().split('T').first,
        foodLog.name,
        foodLog.calories,
        foodLog.protein,
        foodLog.carbs,
        foodLog.fats,
        '', // Placeholder for Total Calories (will be added after the loop)
      ]);
    }

    // Add total calories for the last day
    if (dailyCalories > 0) {
      foodSheet.appendRow(['', '', '', '', '', 'Total:', dailyCalories.toStringAsFixed(0)]);
    }

    // 4. Weight Logs Sheet
    var weightSheet = excel['Weight Logs'];
    weightSheet.appendRow(['Date', 'Weight']);
    List<WeightLog> weightLogs = getWeightLogs();
    for (var weightLog in weightLogs) {
      weightSheet.appendRow([weightLog.date.toIso8601String().split('T').first, weightLog.weight]);
    }

    // Save the Excel file to temporary storage
    Directory downloadsDir = Directory('/storage/emulated/0/Download');
    String timestamp = DateTime.now().toIso8601String().replaceAll(':', '-'); // Ensure valid file name
    String filePath = '${downloadsDir.path}/GymAppData_$timestamp.xlsx';
    File file = File(filePath);

    file.createSync(recursive: true);
    file.writeAsBytesSync(excel.encode()!);

    print('File created at: $filePath');
    return filePath;
  }
  void addFoodItem(String name, String calories, String protein, String carbs, String fats, DateTime date) {
    print("Adding Food Item: $name");
    final foodItem = FoodItemDatabase(
      id: DateTime.now().toString(), // Consider using a UUID or similar
      name: name,
      calories: calories,
      protein: protein,
      carbs: carbs,
      fats: fats,
      date: date,
    );
    foodBox.add(foodItem);
    print("Food item added. Current count: ${foodBox.length}");
  }

  List<FoodItemDatabase> getFoodForDate(DateTime date) {
    return foodBox.values
        .where((item) => isSameDay(item.date, date))
        .toList();
  }
  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && date1.month == date2.month && date1.day == date2.day;
  }
  //write data
  void saveToDatebase(List<Workout>workouts){
    //convert workout objects into lists of strings so that we can save into hive
    final workoutList = convertObjectToWorkoutList(workouts);
    final exerciseList = convertObjectToExerciseList(workouts);
    final dateList = convertObjectToDateList(workouts);
    /*
    check if any exercises have been done
    we will put a 0 or 1 foe each yyymmdd date
     */
//prob dont need this
    if(exerciseCompleted(workouts)){
      _myBox.put("COMPLETION_STATUS${todaysDateYYYYMMDD()}", 1);
    }else{
      _myBox.put("COMPLETION_STATUS${todaysDateYYYYMMDD()}", 0);
    }
    //save into hive
    _myBox.put("WORKOUTS", workoutList);
    _myBox.put("EXERCISES", exerciseList);
    _myBox.put("DATE", dateList);
  }
  void saveToDatebaseFood(List<FoodDay>FoodDays){
    //convert workout objects into lists of strings so that we can save into hive
    final workoutList = convertObjectToFoodDayList(FoodDays);
    final exerciseList = convertObjectToFoodList(FoodDays);
    final dateList = convertObjectToFoodDateList(FoodDays);
    /*
    check if any exercises have been done
    we will put a 0 or 1 foe each yyymmdd date
     */
//prob dont need this

    //save into hive
    //_FoodBox2.put("FOODDAYS", workoutList);
   // _FoodBox2.put("FOOD", exerciseList);
   // _FoodBox2.put("DATE", dateList);
  }
  List<FoodItemDatabase> getFoodLogs() {
    return foodBox.values.toList();
  }
  void saveWeightLog(WeightLog log) {
    box.add(log);
  }

  List<WeightLog> getWeightLogs() {
    return box.values.toList();
  }


  void saveStepLog(StepLog log) {
    stepBox.add(log);
  }

  List<StepLog> getStepLogs() {
    return stepBox.values.toList();
  }


  StepLog? getMostRecentStepLog() {
    if (stepBox.isEmpty) return null;
    return stepBox.values.reduce((a, b) => a.date.isAfter(b.date) ? a : b);
  }
  // Function to get the most recent weight log
  WeightLog? getMostRecentWeightLog() {
    if (box.isEmpty) return null;
    // Assuming WeightLog entries are stored in a box and each log has a 'date' field
    return box.values.reduce((a, b) => a.date.isAfter(b.date) ? a : b);
  }
  //read data, and return a list of workouts
  List<Workout> readFromDatabase() {
    List<Workout> mySavedWorkouts = [];

    // Here we fetch the data safely, ensuring it's not null and is properly cast
    List<dynamic> workoutNames = _myBox.get("WORKOUTS", defaultValue: []);
    List<dynamic> dateNames = _myBox.get("DATE", defaultValue: []);
    final exerciseDetails = _myBox.get("EXERCISES", defaultValue: []);

    // Check and convert dateNames to List<DateTime>
    List<DateTime> dates = dateNames.map((date) =>
    DateTime.tryParse(date.toString()) ?? DateTime.now() // Using DateTime.now() as fallback
    ).toList();

    for (int i = 0; i < workoutNames.length; i++) {
      List<Exercise> exercisesInEachWorkout = [];
      for (int j = 0; j < exerciseDetails[i].length; j++) {
        exercisesInEachWorkout.add(
          Exercise(
            name: exerciseDetails[i][j][0],
            weight: exerciseDetails[i][j][1],
            reps: exerciseDetails[i][j][2],
            sets: exerciseDetails[i][j][3],
            musclegroup: exerciseDetails[i][j][4],
          ),
        );
      }

      // Safely assign dates ensuring we do not exceed the list's range
      DateTime workoutDate = i < dates.length ? dates[i] : DateTime.now();  // Use DateTime.now() as fallback

      // Create individual workout
      Workout workout = Workout(
        name: workoutNames[i],
        exercises: exercisesInEachWorkout,
        date: workoutDate,
      );

      // Add individual workout to overall list
      mySavedWorkouts.add(workout);
    }
    return mySavedWorkouts;
  }



  // check if any exercises have been done
  // prob dont need this
  bool exerciseCompleted(List<Workout>workouts) {
    // go through each workout
    for (var workout in workouts) {
      //go through each exercise in each workout
      for (var exercise in workout.exercises) {
        if (exercise.isCompleted) {
          return true;
        }
      }
    }
      return false;
  }
  // Save Workout Splits
  void saveWorkoutSplits(List<WorkoutSplit> splits) {
    List<Map> storedSplits = splits.map((split) => {
      'day': split.day,
      'muscleGroups': split.muscleGroups.map((mg) => {
        'muscleGroupName': mg.muscleGroupName,
        'exercises': mg.exercises.map((exercise) => {
          'name': exercise.name,
          'reps': exercise.reps,
          'sets': exercise.sets,
          'weight': exercise.weight,
        }).toList()
      }).toList(),
    }).toList();

    _myBox.put('workout_splits', storedSplits);
  }

  // Load Workout Splits
  List<WorkoutSplit> loadWorkoutSplits() {
    var storedSplits = _myBox.get('workout_splits', defaultValue: []);
    return storedSplits.map<WorkoutSplit>((split) => WorkoutSplit(
      day: split['day'],
      muscleGroups: (split['muscleGroups'] as List).map<MuscleGroupSplit>((mg) => MuscleGroupSplit(
        muscleGroupName: mg['muscleGroupName'],
        exercises: (mg['exercises'] as List).map<ExerciseDetail>((ex) => ExerciseDetail(
          name: ex['name'],
          reps: ex['reps'],
          sets: ex['sets'],
          weight: ex['weight'],
        )).toList(),
      )).toList(),
    )).toList();
  }
// return completion status of a given date yyyymmdd
int getCompletionStatus(String yyyymmdd){
    //returns 0 or 1, if null then return 0
    int completionStatus = _myBox.get("COMPLETION_STATUS$yyyymmdd") ?? 0;
    return completionStatus;
}
}


  //converts workout objects into a list -> eg [Back bi, Arms]
List<String> convertObjectToWorkoutList(List<Workout> workouts) {
  List<String> workoutList = [
    // eg. [ upperbody, lowerbody ]
  ];
  for (int i = 0; i < workouts. length; i++) {
    // in each workout, add the name, followed by lists of exercises
    workoutList.add(
      workouts[i].name,
    );
  }
    return workoutList;
  }
List<String> convertObjectToFoodDayList(List<FoodDay> workouts) {
  List<String> workoutList = [
    // eg. [ upperbody, lowerbody ]
  ];
  for (int i = 0; i < workouts. length; i++) {
    // in each workout, add the name, followed by lists of exercises
    workoutList.add(
      workouts[i].name,
    );
  }
  return workoutList;
}

List<DateTime> convertObjectToDateList(List<Workout> workouts) {
  List<DateTime> DateList = [

  ];
  for (int i = 0; i < workouts. length; i++) {
    // in each workout, add the name, followed by lists of exercises
    DateList.add(
      workouts[i].date,
    );
  }
  return DateList;
}
List<DateTime> convertObjectToFoodDateList(List<FoodDay> workouts) {
  List<DateTime> DateList = [

  ];
  for (int i = 0; i < workouts. length; i++) {
    // in each workout, add the name, followed by lists of exercises
    DateList.add(
      workouts[i].date,
    );
  }
  return DateList;
}
  // converts the exercises in a workout object into a list of strings
List<List<List<String>>> convertObjectToExerciseList (List<Workout> workouts) {
  List<List<List<String>>> exerciseList = [
        /*
        [
        Upper Body
        [ [biceps, 10kg, 10reps, 3sets], [triceps, 20kg, 10reps, 3sets] ],
        Lower Body
        [ [squats, 25kg, 10reps, 3sets], [legraise, 30kg, 10reps, 3sets], [calf, 10kg, 10reps, 3sets],
        ]
         */
  ];
  // go through each workout
  for (int i = 0; i < workouts. length; i++) {
    // get exercises from each workout
    List<Exercise> exercisesInWorkout = workouts [i]. exercises;

    List<List<String>> individualWorkout = [
      // Upper Body
    // [ [biceps, 10kg, 10reps, 3sets], [triceps, 20kg, 10reps, 3sets] ],
  ];
    // go through each exercise in exerciseList
    for (int j = 0; j < exercisesInWorkout. length; j++) {
      List<String> individualExercise = [
        // [biceps, 10kg, 10reps, 3sets]
      ];
      individualExercise.addAll(
        [
          exercisesInWorkout[j].name,
          exercisesInWorkout[j].weight,
          exercisesInWorkout[j].reps,
          exercisesInWorkout[j].sets,
          exercisesInWorkout[j].musclegroup,
          ],
      );
      individualWorkout. add (individualExercise);
    }
      exerciseList.add(individualWorkout);
  }
  return exerciseList;
}
List<List<List<String>>> convertObjectToFoodList (List<FoodDay> workouts) {
  List<List<List<String>>> exerciseList = [
    /*
        [
        Upper Body
        [ [biceps, 10kg, 10reps, 3sets], [triceps, 20kg, 10reps, 3sets] ],
        Lower Body
        [ [squats, 25kg, 10reps, 3sets], [legraise, 30kg, 10reps, 3sets], [calf, 10kg, 10reps, 3sets],
        ]
         */
  ];
  // go through each workout
  for (int i = 0; i < workouts. length; i++) {
    // get exercises from each workout
    List<FoodItemDatabase> exercisesInWorkout = workouts [i].Food;

    List<List<String>> individualWorkout = [
      // Upper Body
      // [ [biceps, 10kg, 10reps, 3sets], [triceps, 20kg, 10reps, 3sets] ],
    ];
    // go through each exercise in exerciseList
    for (int j = 0; j < exercisesInWorkout. length; j++) {
      List<String> individualExercise = [
        // [biceps, 10kg, 10reps, 3sets]
      ];
      individualExercise.addAll(
        [
          exercisesInWorkout[j].name,
          exercisesInWorkout[j].calories,
          exercisesInWorkout[j].protein,
          exercisesInWorkout[j].fats,
          exercisesInWorkout[j].carbs,
        ],
      );
      individualWorkout. add (individualExercise);
    }
    exerciseList.add(individualWorkout);
  }
  return exerciseList;
}