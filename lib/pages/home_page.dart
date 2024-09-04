import 'package:flutter/material.dart';
import 'package:gymapp/data/workout_data.dart';
import 'package:gymapp/workout_page.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../models/heat_map.dart';  // Import intl to format dates

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final newWorkoutNameController = TextEditingController();
  final newWorkoutDateController = TextEditingController();
  DateTime selectedDate = DateTime.now(); // Default to today, can be set by a date picker

  @override
  void initState() {
    super.initState();
    Provider.of<WorkoutData>(context, listen: false).initalizeWorkoutList();
  }
  // Navigate to the WorkoutPage with a specific workout name
  void goToWorkoutPage(String workoutName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkoutPage(workoutName: workoutName),
      ),
    );
  }

  void createNewWorkout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Create a New Workout"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: newWorkoutNameController,
              decoration: InputDecoration(labelText: 'Workout Name'),
            ),
            TextField(
              controller: newWorkoutDateController,
              decoration: InputDecoration(labelText: 'Workout Date'),
              onTap: () => _selectDate(context), // Date picker
              readOnly: true, // Prevent keyboard from appearing
            ),
          ],
        ),
        actions: [
          MaterialButton(
            onPressed: save,
            child: Text("Save"),
          ),
          MaterialButton(
            onPressed: cancel,
            child: Text("Cancel"),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        newWorkoutDateController.text = DateFormat('yyyy-MM-dd').format(picked);  // Format the date
      });
    }
  }

  void save() {
    if (newWorkoutNameController.text.isNotEmpty) {
      Provider.of<WorkoutData>(context, listen: false).addWorkout(
        newWorkoutNameController.text,
        selectedDate,
      );
      Provider.of<WorkoutData>(context, listen: false).printAllWorkoutDates(); // Print all dates
      Navigator.pop(context);
      clear();
    }
  }
  void next() {
    if (newWorkoutNameController.text.isNotEmpty) {
      // Save the workout first
      Provider.of<WorkoutData>(context, listen: false).addWorkout(
        newWorkoutNameController.text,
        selectedDate,
      );

      // Navigate to the WorkoutPage to add exercises
      goToWorkoutPage(newWorkoutNameController.text);

      clear(); // Clear input fields
      Navigator.pop(context); // Close the dialog
    }
  }
  void cancel() {
    Navigator.pop(context);
    clear();
  }

  void clear() {
    newWorkoutNameController.clear();
    newWorkoutDateController.clear();
  }

    @override
    Widget build(BuildContext context) {
      return Consumer<WorkoutData>(
        builder: (context, value, child) =>
            Scaffold(
              appBar: AppBar(
                title: const Text('Workout Tracker'),
              ),
              floatingActionButton: FloatingActionButton(
                onPressed: createNewWorkout,
                child: const Icon(Icons.add),
              ),
              backgroundColor: Colors.grey[300],
              body: Center(
                child: Column(
                  children: [

                    // Assuming HeatMap takes a parameter for data which you will supply appropriately
                    Expanded(
                      flex: 1,
                      // Adjust flex as needed to give appropriate space for the heatmap

                      child: MyHeatMap(),
                    ),
                    Expanded(
                      flex: 2, // Adjust flex to accommodate list view size
                      child: ListView.builder(
                        itemCount: value
                            .getworkoutList()
                            .length,
                        itemBuilder: (context, index) =>
                            ListTile(
                              title: Text(value.getworkoutList()[index].name),
                              trailing: IconButton(
                                icon: Icon(Icons.arrow_forward_ios),
                                onPressed: () =>
                                    goToWorkoutPage(value.getworkoutList()[index]
                                        .name),
                              ),
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      );
    }
  }