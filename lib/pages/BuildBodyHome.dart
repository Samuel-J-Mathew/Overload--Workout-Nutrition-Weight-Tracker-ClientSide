import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gymapp/pages/workout_page.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../data/workout_data.dart';
import '../models/workout.dart';

class BuildBodyHome extends StatelessWidget {
  final DateTime selectedDay;
  final Workout? selectedWorkout;

  const BuildBodyHome({
    Key? key,
    required this.selectedDay,
    this.selectedWorkout,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 50),
        TableCalendar<Workout>(
          firstDay: DateTime.utc(2000, 1, 1),
          lastDay: DateTime.utc(2100, 12, 31),
          focusedDay: selectedDay,
          selectedDayPredicate: (day) => isSameDay(selectedDay, day),
          eventLoader: Provider.of<WorkoutData>(context, listen: false).getWorkoutsForDate,
          onDaySelected: (selectedDay, focusedDay) {
            Navigator.push(context, MaterialPageRoute(
              builder: (context) => BuildBodyHome(
                selectedDay: selectedDay,
                selectedWorkout: Provider.of<WorkoutData>(context, listen: false)
                    .getWorkoutsForDate(selectedDay)
                    .isNotEmpty
                    ? Provider.of<WorkoutData>(context, listen: false).getWorkoutsForDate(selectedDay).first
                    : null,
              ),
            ));
          },
          calendarFormat: CalendarFormat.week,
          calendarStyle: CalendarStyle(
            defaultTextStyle: TextStyle(color: Colors.white),
            weekendTextStyle: TextStyle(color: Colors.white),
            todayTextStyle: TextStyle(color: Colors.white),
            selectedTextStyle: TextStyle(color: Colors.white),
            todayDecoration: BoxDecoration(color: Colors.black, shape: BoxShape.circle),
            selectedDecoration: BoxDecoration(color: Colors.blue[900], shape: BoxShape.circle),
            markerDecoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
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
        SizedBox(height: 6),
        Expanded(
          child: Container(
            color: Colors.grey[900],
            child: selectedWorkout != null
                ? (() {
              return WorkoutPage(
                workoutId: selectedWorkout!.id,
                workoutName: selectedWorkout!.name,
              );  // Use WorkoutPage for actual workout display
            })()
                : Center(
              child: Text('No workouts were logged for today.', style: TextStyle(color: Colors.white)),
            ),
          ),
        ),
      ],
    );
  }
}
