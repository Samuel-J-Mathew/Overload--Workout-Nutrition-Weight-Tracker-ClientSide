import 'package:flutter/material.dart';
import 'package:gymapp/components/exercise_tile.dart';
import 'package:gymapp/data/workout_data.dart';
import 'package:gymapp/data/exercise_list.dart';
import 'package:provider/provider.dart';
import 'package:dropdown_search/dropdown_search.dart';

import '../models/SingleExercise.dart';
class WorkoutPage extends StatefulWidget{
  final String workoutName;
  final String workoutId;  // Add workoutId
  const WorkoutPage({super.key,required this.workoutId, required this.workoutName});
  @override
  State<WorkoutPage> createState() => _MyWidgetState();
}
  class _MyWidgetState extends State<WorkoutPage>{


  //text controllers
    final exerciseNameController = TextEditingController();
    final weightController = TextEditingController();
    final repsController = TextEditingController();
    final setsController = TextEditingController();
    final musclegroupController = TextEditingController();

  //create a new exercise
    void createNewExercise(){
      showDialog(
          context: context,
          builder: (context)=> AlertDialog(
            title: Text('Add a new exercise'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                //drop down exercise name
                DropdownSearch<SingleExercise>(
                  popupProps: PopupProps.menu(
                    showSelectedItems: true,
                    showSearchBox: true,
                    itemBuilder: (context, item, isSelected) => ListTile(
                      title: Text(item.name),
                      subtitle: Text(item.muscleGroup),
                    ),
                  ),
                  items: exerciseList,
                  onChanged: (SingleExercise? selectedItem) {
                    if (selectedItem != null) {
                      exerciseNameController.text = selectedItem.name;
                      musclegroupController.text = selectedItem.muscleGroup; // Store muscle group
                    }
                  },
                  itemAsString: (SingleExercise? item) => item?.name ?? '',
                  compareFn: (item1, item2) => item1?.name == item2?.name && item1?.muscleGroup == item2?.muscleGroup, // Comparison function
                  selectedItem: SingleExercise(name: "Select an Exercise", muscleGroup: ""),
                ),
                //sets
                TextField(
                  controller: setsController,
                  decoration: InputDecoration(labelText: 'Sets'),
                ),

                //reps
                TextField(
                  controller: repsController,
                  decoration: InputDecoration(labelText: 'Reps'),
                ),

                //weight
                TextField(
                  controller: weightController,
                  decoration: InputDecoration(labelText: 'Weight'),
                ),


              ],
            ),
            actions: [
              //save button
              MaterialButton(
                onPressed: save,
                child: Text ("save"),
              ),
              //cancel button

              MaterialButton(
                onPressed: cancel,
                child: Text ("cancel"),
              ),
            ],
          )
      );
    }
    // save workout
    void save() {
      // get exercise name from text controller
      String newExerciseName = exerciseNameController.text;
      String weight = weightController.text;
      String reps = repsController.text;
      String sets = setsController.text;
      String musclegroup = musclegroupController.text;
      // add exercise to workout
      Provider.of<WorkoutData>(context,listen: false).addExercise(
          widget.workoutId,
          newExerciseName,
          weight,
          reps,
          sets,
          musclegroup,);

      //pop dialog box
      Navigator.pop(context);
      clear();
    }

    //cancel
    void cancel() {
      //pop diolog box
      Navigator.pop(context);
      clear();
    }

    //clear controllers
    void clear(){
      exerciseNameController.clear();
      repsController.clear();
      weightController.clear();
      setsController.clear();
      musclegroupController.clear();
    }
    @override
    Widget build(BuildContext context) {
      return Consumer<WorkoutData>(
        builder: (context, value, child) {
          var workout = value.getWorkoutById(widget.workoutId);  // Fetch workout using workoutId
          return Scaffold(
            appBar: AppBar(
              title: Text(widget.workoutName),
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: createNewExercise,
              child: const Icon(Icons.add),
            ),
            body: ListView.builder(
              itemCount: workout.exercises.length,  // Use workout fetched by ID
              itemBuilder: (context, index) {
                var exercises = workout.exercises;
                return ExerciseTile(
                  exerciseName: exercises[index].name,
                  weight: exercises[index].weight,
                  reps: exercises[index].reps,
                  sets: exercises[index].sets,
                  isCompleted: exercises[index].isCompleted,
                  onDelete: () => _deleteExercise(index, value),  // Pass the callback for deletion
                );
              },
            ),
          );
        },
      );
    }

    // Delete exercise
    void _deleteExercise(int index, WorkoutData workoutData) {
      workoutData.deleteExercise(widget.workoutId, index);  // Delete using workoutId
    }
  }