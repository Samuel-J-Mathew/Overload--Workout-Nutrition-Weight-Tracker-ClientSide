import 'package:flutter/material.dart';
import 'package:gymapp/pages/updatedHome.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../data/workout_data.dart';
import '../models/workout.dart';
import 'DataAnalysisPage.dart';
import 'MySplitPage.dart';
import 'workout_page.dart';  // Assuming this has the required UI components for displaying workouts

class ExerciseLogPage extends StatefulWidget {
  const ExerciseLogPage({super.key});

  @override
  State<ExerciseLogPage> createState() => _ExerciseLogPageState();
}

class _ExerciseLogPageState extends State<ExerciseLogPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Workout? _selectedWorkout;  // Store selected workout for display
  int _selectedIndex = 0;
  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
  List<Workout> _getEventsForDay(DateTime day) {
    final workoutData = Provider.of<WorkoutData>(context, listen: false);
    return workoutData.getWorkoutsForDate(day);
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
        return buildBodyHome();  // Assume this is another widget for "My Split"
      case 2:
        return const MySplitPage();      // Assume this is another widget for "Log"
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
                ? WorkoutPage(workoutId: _selectedWorkout!.id, workoutName: _selectedWorkout!.name)  // Pass selected workout details to WorkoutPage
                : Center(child: Text('No workouts were logged yet.', style: TextStyle(color: Colors.white))),
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
