import 'package:flutter/material.dart';
import 'package:gymapp/pages/CalorieTrackerPage.dart';
import 'package:gymapp/pages/FoodLogPage.dart';
import 'package:gymapp/pages/SearchPage.dart';
import 'package:gymapp/pages/updatedHome.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../data/workout_data.dart';
import '../models/workout.dart';
import 'DataAnalysisPage.dart';
import 'MySplitPage.dart';
import 'WeightLogPage.dart';
import 'workout_page.dart';  // Assuming this has the required UI components for displaying workouts
import '../data/FoodData.dart';
import '../data/FoodItemDatabase.dart';
class ExerciseLogPage extends StatefulWidget {

  const ExerciseLogPage({super.key});

  @override
  State<ExerciseLogPage> createState() => _ExerciseLogPageState();
}
String todayDateString = DateFormat('yyyy-MM-dd').format(DateTime.now());
class _ExerciseLogPageState extends State<ExerciseLogPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Workout? _selectedWorkout;  // Store selected workout for display
  int _selectedIndex = 0;
  String todayDateString = DateFormat('yyyy-MM-dd').format(DateTime.now());
  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();  // Set today's date
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

  void _selectTodayWorkout() {
    final todayWorkouts = _getEventsForDay(_selectedDay!);  // Ensure this method normalizes the date properly
    print("Workouts for today: ${todayWorkouts.length}");
    if (todayWorkouts.isNotEmpty) {
      setState(() {
        _selectedWorkout = todayWorkouts.first;  // Set the first workout of today as the selected workout
        print("Selected workout ID: ${_selectedWorkout!.id}"); // This will now reflect the correct workout
      });
    }
  }
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
  List<Workout> _getEventsForDay(DateTime day) {
    final workoutData = Provider.of<WorkoutData>(context, listen: false);
    DateTime normalizedDay = DateTime(day.year, day.month, day.day);  // This normalizes the date to the beginning of the day
    return workoutData.getWorkoutsForDate(normalizedDay);
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
      _selectedWorkout = _getEventsForDay(selectedDay).isNotEmpty ? _getEventsForDay(selectedDay).first : null;
    });
  }
  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return UpdatedHome();
      case 1:
        return SearchPage(workoutId: todayDateString, workoutName: todayDateString);  // Assume this is another widget for "My Split"
      case 2:
      // return const MySplitPage();// Assume this is another widget for "Log"
        return  FoodLogPage();
      case 3:
      // return const MySplitPage();// Assume this is another widget for "Log"
        return  MySplitPage();
      default:
        return UpdatedHome();
    }
  }
  Widget buildBodyHome(){
    return Column(

      children: [

        SizedBox(height: 50,),

        TableCalendar<Workout>(
          firstDay: DateTime.utc(2000, 1, 1),
          lastDay: DateTime.utc(2100, 12, 31),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          eventLoader: _getEventsForDay,
          onDaySelected: _onDaySelected,
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


        SizedBox(height: 6,),
        Expanded(
          child: Container(
            color: Colors.grey[900],
            child: _selectedWorkout != null
                ? (() {
              print('workoutID dumbdumb: ${_selectedWorkout!.id}');
              print('workoutName dumbdumb: ${_selectedWorkout!.name}');
              return WorkoutPage(workoutId: _selectedWorkout!.id, workoutName: _selectedWorkout!.name);  // Pass selected workout details to WorkoutPage

            })()
                : (() {
              print('No workouts were logged for today.');  // Print this when no workout is selected
              //return Center(child: Text('No workouts were logged yet.', style: TextStyle(color: Colors.white)));
              createNewWorkout(_selectedDay!);

            })(),
          ),
        ),

        //SizedBox(height: 10),


        //SizedBox(height: 10,),
      ],

    );
  }
  @override
  Widget build(BuildContext context) {
    final workoutData = Provider.of<WorkoutData>(context);

    return Scaffold(
      backgroundColor: Colors.grey[850],
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.fitness_center), label: 'Exercise Log'),
          BottomNavigationBarItem(icon: Icon(Icons.apple), label: 'Food Log'),
          BottomNavigationBarItem(icon: Icon(Icons.moving_rounded), label: 'Strategy'),
        ],
        currentIndex: _selectedIndex, // Highlight the selected item
        onTap: _onItemTapped, // Call _onItemTapped when an item is tapped
        backgroundColor: Colors.grey[900],
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white,
        type: BottomNavigationBarType.fixed,
      ),
      body: _buildBody(),
    );
  }
}
