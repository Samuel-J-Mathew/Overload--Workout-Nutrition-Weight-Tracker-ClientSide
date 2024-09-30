import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../data/workout_data.dart';
import '../models/heat_map.dart';
import '../models/calender.dart';
import '../models/workout.dart';
import 'DataAnalysisPage.dart';
import 'MySplitPage.dart';
import 'workout_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final ValueNotifier<List<Workout>> _selectedEvents; // Now holds list of workouts
  final newWorkoutNameController = TextEditingController();
  DateTime selectedDate = DateTime.now(); // Default to today
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  int _selectedIndex = 0;
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
  List<Workout> _getEventsForDay(DateTime day) {
    final workoutData = Provider.of<WorkoutData>(context, listen: false);
    final Map<DateTime, List<Workout>> workoutsByDay = _getWorkoutsByDay(workoutData);
    return workoutsByDay[day] ?? [];
  }

  // Map workout dates to a format usable by the calendar
  Map<DateTime, List<Workout>> _getWorkoutsByDay(WorkoutData workoutData) {
    Map<DateTime, List<Workout>> workoutMap = {};

    for (var workout in workoutData.getworkoutList()) {
      final workoutDate = DateTime(workout.date.year, workout.date.month, workout.date.day);

      if (workoutMap.containsKey(workoutDate)) {
        workoutMap[workoutDate]!.add(workout);
      } else {
        workoutMap[workoutDate] = [workout];
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
  String formatDateTimeWithSuffix(DateTime dateTime) {
    var day = dateTime.day;
    var suffix = getDaySuffix(day);
    return DateFormat('MMMM').format(dateTime) + ' ' + day.toString() + suffix;
  }
  String getDaySuffix(int day) {
    if ((day % 10 == 1) && (day != 11)) {
      return 'st';
    } else if ((day % 10 == 2) && (day != 12)) {
      return 'nd';
    } else if ((day % 10 == 3) && (day != 13)) {
      return 'rd';
    }
    return 'th';
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
          title: Align( // Align the text widget within the AlertDialog title
            alignment: Alignment.center,
            child: Text(
              "Log Workout for ${formatDateTimeWithSuffix(selectedDay)}",
              style: const TextStyle(
                fontStyle: FontStyle.italic, // Apply italic style to the text
                fontWeight: FontWeight.bold, // Make the text bold
              ),
              textAlign: TextAlign.center, // Center the text horizontally
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...workouts.map((workout) => ListTile(
                title: Text(workout.name),
                subtitle: Text(DateFormat('yyyy-MM-dd').format(workout.date)),
                onTap: () => _goToWorkoutPage(workout.id, workout.name),
              )),
            ],
          ),
          actions: [
            MaterialButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Close"),
            ),
            MaterialButton(
              onPressed: () {
                Navigator.pop(context);
                createNewWorkout(selectedDay);
              },
              child: const Text("Add Workout"),
            ),
          ],
        ),
      );
    }
  }

  // Show dialog to add a new workout for the selected day
  void createNewWorkout(DateTime selectedDay) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Log Workout for\n${formatDateTimeWithSuffix(selectedDay)}",
          style: const TextStyle(
            fontStyle: FontStyle.italic, // Apply italic style to the text
            fontWeight: FontWeight.bold, // Make the text bold
          ),
          textAlign: TextAlign.center, // Center the text horizontally
        ),
        content: TextField(
          controller: newWorkoutNameController,
          decoration: const InputDecoration(labelText: 'Workout Name'),
        ),
        actions: [
          MaterialButton(
            onPressed: () {
              final workoutName = newWorkoutNameController.text;
              if (workoutName.isNotEmpty) {
                // Add the workout for the selected day and save it
                final workoutId = Provider.of<WorkoutData>(context, listen: false)
                    .addWorkout(workoutName, selectedDay);

                // Clear input field after saving
                newWorkoutNameController.clear();

                // Close the dialog after adding the workout
                Navigator.pop(context);

                // Navigate to the workout page for the newly created workout
                _goToWorkoutPage(workoutId, workoutName);
              }
            },
            child: const Text("Next"),
          ),
          MaterialButton(
            onPressed: () {
              // Clear input field if cancelled
              newWorkoutNameController.clear();
              Navigator.pop(context);
            },
            child: const Text("Cancel"),
          ),
        ],
      ),
    );
  }

  // Navigate to the WorkoutPage with a specific workout ID
  void _goToWorkoutPage(String workoutId, String workoutName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkoutPage(workoutId: workoutId, workoutName: workoutName),
      ),
    );
  }
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return buildHomePageBody();
      case 1:
        return MySplitPage();  // Assume this is another widget for "My Split"
      case 2:
        return DataAnalysisPage();      // Assume this is another widget for "Log"
      default:
        return buildHomePageBody();
    }
  }
  Widget buildHomePageBody() {
    return Stack(
      children: [
        Column(
          children: [
            // Display HeatMap first
            Expanded(
              flex: 1,
              child: MyHeatMap(), // Ensure this shows your heatmap
            ),
            // Calendar to display the week and allow adding workouts
            Expanded(
              flex: 1,
              child: TableCalendar<Workout>(
                firstDay: DateTime.utc(2000, 1, 1),
                lastDay: DateTime.utc(2100, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                eventLoader: (day) => _getEventsForDay(day),
                onDaySelected: _onDaySelected,
                calendarFormat: CalendarFormat.week,
                calendarStyle: const CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  markerDecoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            // List of selected events (workouts) for the selected day
            Expanded(
              flex: 2,
              child: ValueListenableBuilder<List<Workout>>(
                valueListenable: _selectedEvents,
                builder: (context, workouts, _) {
                  return ListView.builder(
                    itemCount: workouts.length,
                    itemBuilder: (context, index) {
                      final workout = workouts[index];
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
                          title: Text(workout.name),
                          subtitle: Text(DateFormat('yyyy-MM-dd').format(workout.date)),
                          onTap: () => _goToWorkoutPage(workout.id, workout.name),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
        Positioned(
          bottom: 20,
          right: 20,
          child: FloatingActionButton(
            onPressed: () => createNewWorkout(DateTime.now()),
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final workoutData = Provider.of<WorkoutData>(context);
    final Map<DateTime, List<Workout>> workoutsByDay = _getWorkoutsByDay(workoutData);

    return Consumer<WorkoutData>(
      builder: (context, value, child) => Scaffold(
        appBar: AppBar(
          title: const Text('Workout Tracker'),
          actions: <Widget>[

          ],
        ),

        backgroundColor: Colors.grey[300],
        body: _buildBody(),


        bottomNavigationBar: BottomNavigationBar(items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'home'),
          BottomNavigationBarItem(icon: Icon(Icons.edit_note ), label: 'My Split'),
          BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'Log'),
        ],
          currentIndex: _selectedIndex, // Highlight the selected item
          onTap: _onItemTapped, // Call _onItemTapped when an item is tapped
        )
      ),



    );
  }
}
// workout not getting saved to heatmap and db database