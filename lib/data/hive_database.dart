import 'package:gymapp/datetime/date_time.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/exercise.dart';
import '../models/workout.dart';

class HiveDatabase {
  //reference our hive box
  final _myBox = Hive.box("workout_database");
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
  // return start date as yyymmdd
  String getStartDate(){
    return _myBox.get("START_DATE");
  }

  //write data
  void saveToDatebase(List<Workout>workouts){
    //convert workout objects into lists of strings so that we can save into hive
    final workoutList = convertObjectToWorkoutList(workouts);
    final exerciseList = convertObjectToExerciseList(workouts);
    /*
    check if any exercises have been done
    we will put a 0 or 1 foe each yyymmdd date
     */
//prob dont need this
    if(exerciseCompleted(workouts)){
      _myBox.put("COMPLETION_STATUS"+ todaysDateYYYYMMDD(), 1);
    }else{
      _myBox.put("COMPLETION_STATUS"+ todaysDateYYYYMMDD(), 0);
    }
    //save into hive
    _myBox.put("WORKOUTS", workoutList);
    _myBox.put("EXERCISES", exerciseList);
  }



  //read data, and return a list of workouts
  List<Workout> readFromDatabase(){
    List<Workout> mySavedWorkouts = [];

    List<String> workoutNames = _myBox.get("WORKOUTS");
    final exerciseDetails = _myBox.get("EXERCISES");
    // create wrokout object
    for(int i = 0; i< workoutNames.length;i++){
      //each workout can have multiple exercises
      List<Exercise> exercisesInEachWorkout = [];
      for(int j=0; j<exerciseDetails[i].length;j++){
        //add each exercise into list
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
    // create individual workout
      Workout workout =
          Workout(name: workoutNames[i], exercises: exercisesInEachWorkout);
      //add individual workout to overall list
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
// last time 32:50