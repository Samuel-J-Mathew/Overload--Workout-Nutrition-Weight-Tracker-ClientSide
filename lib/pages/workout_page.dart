import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gymapp/components/exercise_tile.dart';
import 'package:gymapp/data/workout_data.dart';
import 'package:gymapp/data/exercise_list.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../models/SingleExercise.dart';
class WorkoutPage extends StatefulWidget{
  final String workoutName;
  final String workoutId;  // Add workoutId
  final bool openDialog;
  const WorkoutPage({super.key,required this.workoutId, required this.workoutName,  this.openDialog = false });
  @override
  State<WorkoutPage> createState() => _MyWidgetState();
}
class _MyWidgetState extends State<WorkoutPage>{

  @override
  void initState() {
    super.initState();
    if (widget.openDialog) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        createNewExercise(); // Make sure this method is callable like this
      });
    }
  }

  List<SingleExercise> filteredExercises = exerciseList;
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
          title: const Text('Add a new exercise'),
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
                compareFn: (item1, item2) => item1.name == item2.name && item1.muscleGroup == item2.muscleGroup, // Comparison function
                selectedItem: SingleExercise(name: "Select an Exercise", muscleGroup: ""),
              ),
              //sets
              TextField(
                controller: setsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Sets'),
              ),

              //reps
              TextField(
                controller: repsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Reps'),
              ),

              //weight
              TextField(
                controller: weightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Weight'),
              ),


            ],
          ),
          actions: [
            //save button
            MaterialButton(
              onPressed: cancel,
              child: const Text ("cancel"),
            ),
            //cancel button

            MaterialButton(
              onPressed: save,
              child: const Text ("save"),
            ),
          ],
        )
    );
  }
  // save workout
  void save() {
    // Validate that all fields are filled
    if (exerciseNameController.text.isEmpty ||
        setsController.text.isEmpty ||
        repsController.text.isEmpty ||
        weightController.text.isEmpty) {
      // Show a snackbar or alert dialog to inform the user to fill all fields
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please fill in all fields before saving.'),
            backgroundColor: Colors.red,
          )
      );
      return; // Stop the function if validation fails
    }
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

   final User? user = FirebaseAuth.instance.currentUser;
    DateTime workoutDate = DateFormat('yyyy-MM-dd').parse(widget.workoutId);
    addExercise(
        user!.uid,
        workoutDate, // Or use a specific workout date if applicable
        newExerciseName,
        sets,
        reps,
        weight
    );
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
  Future<void> addExercise(String userId, DateTime workoutDate, String exerciseName, String sets, String reps, String weight) async {
    var workoutFormattedDate = DateFormat('yyyyMMdd').format(workoutDate);
    var workoutDocRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('workouts')
        .doc(workoutFormattedDate);

    // Ensure the workout document is initialized
    await workoutDocRef.set({
      'date': workoutFormattedDate  // Setting a field to ensure the document exists
    }, SetOptions(merge: true));

    var exerciseCollection = workoutDocRef.collection('exercises');

    await exerciseCollection.add({
      'name': exerciseName,
      'sets': sets,
      'reps': reps,
      'weight': weight
    });
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
        int totalSets = 0;
        int totalReps = 0;
        double totalWeight = 0.00;
        for (var exercise in workout.exercises) {
          totalSets += int.parse(exercise.sets);
          totalReps += int.parse(exercise.reps)* int.parse(exercise.sets);
          totalWeight += (double.tryParse(exercise.weight) ?? 0.0) * (int.tryParse(exercise.sets) ?? 0);
        }
        return Scaffold(
          body: Column(
            children: [

              Expanded(
                child: Container(
                  margin: EdgeInsets.zero,
                  color: Color.fromRGBO(20, 20, 20, 1),
                  padding: EdgeInsets.only(left: 40, right: 14,),
                  child: workout.exercises.isEmpty ?  // Check if the exercises list is empty
                  Center(  // Center widget to center the message
                    child:
                    InkWell(  // InkWell to make the text clickable
                      onTap: createNewExercise,  // Call the function to add a new exercise when tapped
                      child: Text(
                        "No Workout logged for this day. Tap to Add.",
                        style: TextStyle(color: Colors.white, fontSize: 16),  // Styling for the text
                      ),
                    ),
                  ) : ListView.builder(
                    itemCount: workout.exercises.length + 1, // Adding 1 for the header
                    itemBuilder: (context, index) {
                      if (index == 0) { // Header
                        return Padding(
                          padding: EdgeInsets.symmetric( vertical: 5),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,

                            children: [
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: "${(totalSets.toInt())} ",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.normal, // Optional: Make it bold
                                      ),
                                    ),
                                    WidgetSpan(
                                      child: Icon(MdiIcons.alphaSCircle, color: Colors.white, size: 18), // Fire icon with adjustable color and size
                                    ),
                                  ],
                                ),
                              ),
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: "${(totalReps.toInt())} ",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.normal, // Optional: Make it bold
                                      ),
                                    ),
                                    WidgetSpan(
                                      child: Icon(MdiIcons.alphaRCircle, color: Colors.white, size: 18), // Fire icon with adjustable color and size
                                    ),
                                  ],
                                ),
                              ),
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: "${totalWeight.toStringAsFixed(2)} ",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.normal, // Optional: Make it bold
                                      ),
                                    ),

                                    WidgetSpan(
                                      child: Icon(MdiIcons.weightPound, color: Colors.white, size: 18), // Fire icon with adjustable color and size
                                    ),
                                  ],
                                ),
                              ),

                            ],

                          ),
                        );
                      } else { // Exercise tiles
                        var exercise = workout.exercises[index - 1]; // Adjust index for header
                        return ExerciseTile(
                          exerciseName: exercise.name,
                          weight: exercise.weight,
                          reps: exercise.reps,
                          sets: exercise.sets,
                          isCompleted: exercise.isCompleted,
                          onDelete: () => _deleteExercise(index - 1, value),
                        );
                      }
                    },
                  ),
                ),
              ),
              Container(
                constraints: BoxConstraints(
                  maxHeight: 55, // Maximum height
                ),
                color: Color.fromRGBO(25, 25, 25, 1),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: InkWell(
                    onTap: () {
                      createNewExercise();  // The action you want to perform on tap
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Color.fromRGBO(40, 40, 40, 1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.search, color: Colors.white),
                            onPressed: () {
                              createNewExercise();
                            },
                          ),
                          SizedBox(width: 9),
                          Text(
                            'Search for an exercise',
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),


            ],
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