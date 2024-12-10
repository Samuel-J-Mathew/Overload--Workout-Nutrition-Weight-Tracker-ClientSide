import 'package:flutter/material.dart';
import 'package:gymapp/data/WorkoutSplit.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../data/workout_data.dart';
import '../models/heat_map.dart';
import '../models/workout.dart';
import 'DataAnalysisPage.dart';
import 'MySplitPage.dart';
import 'workout_page.dart';
// Alias this import
import 'package:gymapp/data/WorkoutSplit.dart' as split;
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
  late String today;
  late WorkoutSplit todaysWorkout;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // No need to pass 'today' as an argument
      WorkoutSplit todaysSplit = Provider.of<WorkoutData>(context, listen: false).getTodaysSplit();
      setState(() {
        // Assume you have a state variable to hold today's split for displaying in the widget
        todaysWorkout = todaysSplit;
      });

      Provider.of<WorkoutData>(context, listen: false).initalizeWorkoutList();
      _selectedDay = _focusedDay;
      _selectedEvents = ValueNotifier(_getEventsForDay(_selectedDay!));
    });
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

  // Assuming you have a method in WorkoutData that correctly fetches today's split based on day of the week
  Widget buildTodaysWorkout() {
    // Access your provider
    var workoutData = Provider.of<WorkoutData>(context, listen: false);
    split.WorkoutSplit todaysSplit = workoutData.getTodaysSplit(); // Using the aliased import
    // Check if the split has any muscle groups; if not, show a message
    if (todaysSplit.muscleGroups.isEmpty) {
      return const Center(
        child: Text("No workout planned for today."),
      );
    }

    // Generate a string of muscle group names separated by commas
    String muscleGroupsNames = todaysSplit.muscleGroups.map((mg) => mg.muscleGroupName).join(', ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text("Today's Workout: $muscleGroupsNames", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ),
        ...todaysSplit.muscleGroups.expand((mg) => mg.exercises.map((exercise) => ListTile(
          title: Text(exercise.name),
          subtitle: Text('Sets: ${exercise.sets}, Reps: ${exercise.reps}, Weight: ${exercise.weight} lb'),
          trailing: IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // Here we use the ExerciseDetail from WorkoutSplit.dart directly
              workoutData.logExercise(exercise);
            },
          ),
        ))),
      ],
    );
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
    return '${DateFormat('MMMM').format(dateTime)} $day$suffix';
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
        title:Text(
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
              final String  datestring = selectedDay.toString();
              String workoutName = datestring.split(' ')[0]; // Splits the string by space and takes the first part
              print("workout name: " + workoutName);
                // Add the workout for the selected day and save it
                final workoutId = Provider.of<WorkoutData>(context, listen: false)
                    .addWorkout(workoutName, selectedDay);

                // Clear input field after saving
                newWorkoutNameController.clear();

                // Close the dialog after adding the workout
                Navigator.pop(context);

                // Navigate to the workout page for the newly created workout
                _goToWorkoutPage(workoutId, workoutName);

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
        return const MySplitPage();  // Assume this is another widget for "My Split"
      case 2:
        return const DataAnalysisPage();      // Assume this is another widget for "Log"
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
            const MyHeatMap(), // Removed Expanded to prevent it from taking extra space

            // Calendar to display the week and allow adding workouts
            TableCalendar<Workout>(
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

            // List of selected events (workouts) for the selected day
            if (_selectedEvents.value.isNotEmpty) // Only show if there are selected events
              ...[
                const SizedBox(height: 10), // Small gap for separation
                ListView.builder(
                  shrinkWrap: true, // Allows it to take only necessary space
                  physics: const NeverScrollableScrollPhysics(), // Prevent scrolling within this list
                  itemCount: _selectedEvents.value.length,
                  itemBuilder: (context, index) {
                    final workout = _selectedEvents.value[index];
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
                ),
              ],

            // Display Today's Workout at the bottom
            const SizedBox(height: 10), // Add some space before Today's Workout
            buildTodaysWorkout(),
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
          actions: const <Widget>[

          ],
        ),

        backgroundColor: Colors.grey[300],
        body: _buildBody(),


        bottomNavigationBar: BottomNavigationBar(items: const [
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
