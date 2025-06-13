import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:gymapp/components/exercise_tile.dart';
import 'package:gymapp/data/workout_data.dart';
import 'package:gymapp/pages/workout_page.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

import '../models/SingleExercise.dart';
import '../models/workout.dart';
import '../components/ExerciseLogSummaryTile.dart';

class SearchPage extends StatefulWidget {
  final String workoutName;
  final String workoutId;
  const SearchPage({super.key, required this.workoutId, required this.workoutName});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Workout? _selectedWorkout;
  int _selectedIndex = 0;

  final exerciseNameController = TextEditingController();
  final weightController = TextEditingController();
  final repsController = TextEditingController();
  final setsController = TextEditingController();
  final musclegroupController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _onDaySelected(_selectedDay!, _focusedDay); // Automatically select and load today's workout
    });
  }

  WorkoutPage createNewWorkout(DateTime selectedDay){
    final String  datestring = selectedDay.toString();
    String workoutName = datestring.split(' ')[0];
    final workoutId = Provider.of<WorkoutData>(context, listen: false)
        .addWorkout(workoutName, selectedDay);
    return WorkoutPage(workoutId: workoutId, workoutName: workoutName);
  }
  WorkoutPage goToNewWorkout(DateTime selectedDay){
    final String  datestring = selectedDay.toString();
    String workoutName = datestring.split(' ')[0];
    return WorkoutPage(workoutId: workoutName, workoutName: workoutName);
  }


  WorkoutPage goToWorkout(){
    DateTime now = DateTime.now();
    String selectedDay = DateFormat('yyyy-MM-dd').format(now);
    final String  datestring = selectedDay.toString();
    String workoutName = datestring.split(' ')[0];
    print('workout name popop : ' + workoutName);
    return WorkoutPage(workoutId: workoutName, workoutName: workoutName);

  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
      _selectedWorkout = Provider.of<WorkoutData>(context, listen: false).getWorkoutsForDate(selectedDay).isNotEmpty
          ? Provider.of<WorkoutData>(context, listen: false).getWorkoutsForDate(selectedDay).first
          : null;
    });
  }

  void createNewExercise() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add a new exercise'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownSearch<SingleExercise>(
              popupProps: PopupProps.menu(
                showSelectedItems: true,
                showSearchBox: true,
                itemBuilder: (context, item, isSelected) => ListTile(
                  title: Text(item.name),
                  subtitle: Text(item.muscleGroup),
                ),
              ),
              items: Provider.of<WorkoutData>(context, listen: false).getAllExerciseNames().map((e) => SingleExercise(name: e, muscleGroup: "Unknown")).toList(),
              onChanged: (SingleExercise? selectedItem) {
                if (selectedItem != null) {
                  exerciseNameController.text = selectedItem.name;
                  musclegroupController.text = selectedItem.muscleGroup; // Here you might want to properly handle muscle group logic if available
                }
              },
              itemAsString: (SingleExercise? item) => item?.name ?? '',
              compareFn: (item1, item2) => item1.name == item2.name && item1.muscleGroup == item2.muscleGroup,
              selectedItem: SingleExercise(name: "Select an Exercise", muscleGroup: ""),
            ),
            TextField(controller: setsController, decoration: const InputDecoration(labelText: 'Sets')),
            TextField(controller: repsController, decoration: const InputDecoration(labelText: 'Reps')),
            TextField(controller: weightController, decoration: const InputDecoration(labelText: 'Weight')),
          ],
        ),
        actions: [
          MaterialButton(onPressed: save, child: const Text("Save")),
          MaterialButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
        ],
      ),
    );
  }

  void save() {
    Provider.of<WorkoutData>(context, listen: false).addExercise(
      widget.workoutId,
      exerciseNameController.text,
      weightController.text,
      repsController.text,
      setsController.text,
      musclegroupController.text,
    );
    Navigator.pop(context);
    clear();
  }

  void clear() {
    exerciseNameController.clear();
    repsController.clear();
    weightController.clear();
    setsController.clear();
    musclegroupController.clear();
  }

  Widget buildBody() {
    if (_selectedWorkout == null) {
      return Center(child: Text("Please select the day you want to view", style: TextStyle(color: Colors.white)));
    } else {
      return ListView.builder(
        itemCount: _selectedWorkout!.exercises.length,
        itemBuilder: (context, index) {
          var exercise = _selectedWorkout!.exercises[index];
          return ExerciseTile(
            exerciseName: exercise.name,
            weight: exercise.weight,
            reps: exercise.reps,
            sets: exercise.sets,
            isCompleted: exercise.isCompleted,
            onDelete: () => Provider.of<WorkoutData>(context, listen: false).deleteExercise(widget.workoutId, index),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(31, 31, 31, 1),

      body: Column(
        children: [
          SizedBox(height: 50),
          TableCalendar<Workout>(
            firstDay: DateTime.utc(2000, 1, 1),
            lastDay: DateTime.utc(2100, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            eventLoader: (day) => Provider.of<WorkoutData>(context, listen: false).getWorkoutsForDate(day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
                _selectedWorkout = Provider.of<WorkoutData>(context, listen: false)
                    .getWorkoutsForDate(selectedDay)
                    .isNotEmpty
                    ? Provider.of<WorkoutData>(context, listen: false).getWorkoutsForDate(selectedDay).first
                    : null;
              });
            },
            calendarFormat: CalendarFormat.week,
            calendarStyle: CalendarStyle(
              defaultTextStyle: TextStyle(color: Colors.white),
              weekendTextStyle: TextStyle(color: Colors.white),
              todayTextStyle: TextStyle(color: Colors.white),
              selectedTextStyle: TextStyle(color: Colors.white),
              todayDecoration: BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.blue[900],
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            headerStyle: HeaderStyle(
              titleTextStyle: TextStyle(color: Colors.white),
              formatButtonTextStyle: TextStyle(color: Colors.white),
              leftChevronIcon: Icon(Icons.chevron_left, color: Colors.white),
              rightChevronIcon: Icon(Icons.chevron_right, color: Colors.white),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: TextStyle(color: Colors.white),
              weekendStyle: TextStyle(color: Colors.white),
            ),
          ),
          ExerciseLogSummaryTile(selectedDate: _selectedDay ?? DateTime.now()),
          SizedBox(height: 6),
          Expanded(
            child: Container(
              color: Colors.grey[900],
              child: Builder(
                builder: (context) {
                  if (_selectedWorkout != null) {

                    // Show the existing workout
                    return WorkoutPage(
                      workoutId: _selectedWorkout!.id,
                      workoutName: _selectedWorkout!.name,
                    );
                  } else {
                    // Create a new workout if none exists for the selected day
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      // Create the new workout
                      var newWorkout = createNewWorkout(_selectedDay!);

                      // Update the state to reflect the newly created workout
                      setState(() {
                        _selectedWorkout = Provider.of<WorkoutData>(context, listen: false)
                            .getWorkoutsForDate(_selectedDay!)
                            .firstWhere((workout) => workout.id == newWorkout.workoutId);
                      });
                    });
                    return Center(
                      child: Text(
                        "Creating a new workout...",
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  }
                },
              ),
            ),
          ),

        ],
      ),

    );
  }
}
