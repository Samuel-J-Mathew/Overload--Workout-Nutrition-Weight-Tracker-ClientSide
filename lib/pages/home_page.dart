import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

import '../data/workout_data.dart';
import '../models/heat_map.dart';
import '../models/calender.dart';
import '../workout_page.dart'; // Import the heatmap

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final ValueNotifier<List<String>> _selectedEvents;
  final newWorkoutNameController = TextEditingController();
  DateTime selectedDate = DateTime.now(); // Default to today
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    Provider.of<WorkoutData>(context, listen: false).initalizeWorkoutList();
    _selectedDay = _focusedDay;
    _selectedEvents = ValueNotifier(_getEventsForDay(_selectedDay!));
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    super.dispose();
  }

  // Get events (workouts) for a specific day
  List<String> _getEventsForDay(DateTime day) {
    final workoutData = Provider.of<WorkoutData>(context, listen: false);
    final Map<DateTime, List<String>> workoutsByDay = _getWorkoutsByDay(workoutData);
    return workoutsByDay[day] ?? [];
  }

  // Map workout dates to a format usable by the calendar
  Map<DateTime, List<String>> _getWorkoutsByDay(WorkoutData workoutData) {
    Map<DateTime, List<String>> workoutMap = {};

    for (var workout in workoutData.getworkoutList()) {
      final workoutDate = DateTime(workout.date.year, workout.date.month, workout.date.day);

      if (workoutMap.containsKey(workoutDate)) {
        workoutMap[workoutDate]!.add(workout.name);
      } else {
        workoutMap[workoutDate] = [workout.name];
      }
    }

    return workoutMap;
  }

  // Handle day selection and allow adding a new workout
  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });

    // Update the selected events for the selected day
    _selectedEvents.value = _getEventsForDay(selectedDay);

    // Show dialog to view or add workouts for the selected day
    _showWorkoutsForDay(selectedDay);
  }

  // Show dialog with workouts or add a new workout for the selected day
  void _showWorkoutsForDay(DateTime selectedDay) {
    final workoutData = Provider.of<WorkoutData>(context, listen: false);
    final workouts = workoutData.getWorkoutsForDate(selectedDay);

    if (workouts.isEmpty) {
      // No workouts, show add dialog
      createNewWorkout(selectedDay);
    } else {
      // Show list of workouts for that day
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Workouts for ${DateFormat('yyyy-MM-dd').format(selectedDay)}"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...workouts.map((workout) => ListTile(
                title: Text(workout.name),
                onTap: () => _goToWorkoutPage(workout.name),
              )),
            ],
          ),
          actions: [
            MaterialButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Close"),
            ),
            MaterialButton(
              onPressed: () {
                Navigator.pop(context);
                createNewWorkout(selectedDay);
              },
              child: Text("Add Workout"),
            ),
          ],
        ),
      );
    }
  }

  // Show dialog to add a new workout for the selected day
  void createNewWorkout(DateTime selectedDay) {
    final newWorkoutNameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Create a New Workout for ${DateFormat('yyyy-MM-dd').format(selectedDay)}"),
        content: TextField(
          controller: newWorkoutNameController,
          decoration: InputDecoration(labelText: 'Workout Name'),
        ),
        actions: [
          MaterialButton(
            onPressed: () {
              if (newWorkoutNameController.text.isNotEmpty) {
                // Add the workout for the selected day
                Provider.of<WorkoutData>(context, listen: false).addWorkout(
                  newWorkoutNameController.text,
                  selectedDay,
                );
                Provider.of<WorkoutData>(context, listen: false).notifyListeners(); // Notify listeners
                Navigator.pop(context); // Close the dialog after adding the workout

                // Update events for the selected day
                _selectedEvents.value = _getEventsForDay(selectedDay);
              }
            },
            child: Text("Save"),
          ),
          MaterialButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
        ],
      ),
    );
  }

  // Navigate to the WorkoutPage with a specific workout name
  void _goToWorkoutPage(String workoutName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkoutPage(workoutName: workoutName),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final workoutData = Provider.of<WorkoutData>(context);
    final Map<DateTime, List<String>> workoutsByDay = _getWorkoutsByDay(workoutData);

    return Consumer<WorkoutData>(
      builder: (context, value, child) => Scaffold(
        appBar: AppBar(
          title: const Text('Workout Tracker'),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => createNewWorkout(DateTime.now()),
          child: const Icon(Icons.add),
        ),
        backgroundColor: Colors.grey[300],
        body: Column(
          children: [
            // Display HeatMap first
            Expanded(
              flex: 1,
              child: MyHeatMap(), // Ensure this shows your heatmap
            ),
           // Expanded(
             // flex: 1,
              //child: , // Ensure this shows your heatmap
           //),
            // Calendar to display the week and allow adding workouts
            Expanded(
              flex: 1,
              child: TableCalendar<String>(
                firstDay: DateTime.utc(2000, 1, 1),
                lastDay: DateTime.utc(2100, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                eventLoader: (day) => _getEventsForDay(day),
                onDaySelected: _onDaySelected,
                calendarFormat: CalendarFormat.week,
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  markerDecoration: BoxDecoration(
                    color: Colors.blue, // Blue dot for workout days
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            // List of selected events (workouts) for the selected day
            Expanded(
              flex: 2,
              child: ValueListenableBuilder<List<String>>(
                valueListenable: _selectedEvents,
                builder: (context, value, _) {
                  return ListView.builder(
                    itemCount: value.length,
                    itemBuilder: (context, index) {
                      return Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12.0,
                          vertical: 4.0,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: ListTile(
                          title: Text(value[index]),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
