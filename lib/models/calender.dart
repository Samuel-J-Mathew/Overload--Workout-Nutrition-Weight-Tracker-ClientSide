import 'package:flutter/material.dart';
import 'package:gymapp/models/workout.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart'; // For accessing WorkoutData provider
import '../data/workout_data.dart'; // Import your workout data
import '../models/utils.dart';// Import the updated utils.dart with workout events

class TableEventsExample extends StatefulWidget {
  @override
  _TableEventsExampleState createState() => _TableEventsExampleState();
}

class _TableEventsExampleState extends State<TableEventsExample> {
  late final ValueNotifier<List<WorkoutEvent>> _selectedEvents;
  CalendarFormat _calendarFormat = CalendarFormat.week;
  RangeSelectionMode _rangeSelectionMode = RangeSelectionMode.toggledOff;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;

  @override
  void initState() {
    super.initState();

    _selectedDay = _focusedDay;

    // Fetch workout data and populate the events
    final workoutData = Provider.of<WorkoutData>(context, listen: false);
    _mapWorkoutsToDays(workoutData.getworkoutList());

    _selectedEvents = ValueNotifier(_getWorkoutsForDay(_selectedDay!));
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    super.dispose();
  }

  // Get workouts (events) for a specific day
  List<WorkoutEvent> _getWorkoutsForDay(DateTime day) {
    return kWorkoutEvents[day] ?? [];
  }

  // Map workout data to specific days
  void _mapWorkoutsToDays(List<Workout> workouts) {
    for (var workout in workouts) {
      final workoutDate = DateTime(workout.date.year, workout.date.month, workout.date.day);
      if (kWorkoutEvents.containsKey(workoutDate)) {
        kWorkoutEvents[workoutDate]!.add(WorkoutEvent(workout.name));
      } else {
        kWorkoutEvents[workoutDate] = [WorkoutEvent(workout.name)];
      }
    }
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
        _rangeStart = null; // Clear range selection
        _rangeEnd = null;
        _rangeSelectionMode = RangeSelectionMode.toggledOff;
      });

      _selectedEvents.value = _getWorkoutsForDay(selectedDay);
    }

    // Show the dialog to add a new workout
    _showAddWorkoutDialog(selectedDay);
  }

  // Show a dialog for adding a workout
  void _showAddWorkoutDialog(DateTime selectedDay) {
    final newWorkoutNameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Add Workout for ${selectedDay.toLocal()}"),
        content: TextField(
          controller: newWorkoutNameController,
          decoration: InputDecoration(labelText: 'Workout Name'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Add the new workout to the selected date
              if (newWorkoutNameController.text.isNotEmpty) {
                final newWorkout = WorkoutEvent(newWorkoutNameController.text);

                // Add the workout event to the calendar for the selected day
                setState(() {
                  if (kWorkoutEvents.containsKey(selectedDay)) {
                    kWorkoutEvents[selectedDay]!.add(newWorkout);
                  } else {
                    kWorkoutEvents[selectedDay] = [newWorkout];
                  }

                  // Notify WorkoutData provider (if necessary, for saving in database)
                  Provider.of<WorkoutData>(context, listen: false).addWorkout(
                    newWorkoutNameController.text,
                    selectedDay,
                  );

                  // Update the selected events to reflect the new workout
                  _selectedEvents.value = _getWorkoutsForDay(selectedDay);
                });

                Navigator.pop(context); // Close the dialog
              }
            },
            child: Text('Save'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close the dialog without saving
            },
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _onRangeSelected(DateTime? start, DateTime? end, DateTime focusedDay) {
    setState(() {
      _selectedDay = null;
      _focusedDay = focusedDay;
      _rangeStart = start;
      _rangeEnd = end;
      _rangeSelectionMode = RangeSelectionMode.toggledOn;
    });

    if (start != null && end != null) {
      _selectedEvents.value = _getWorkoutsForRange(start, end);
    } else if (start != null) {
      _selectedEvents.value = _getWorkoutsForDay(start);
    } else if (end != null) {
      _selectedEvents.value = _getWorkoutsForDay(end);
    }
  }

  // Get workouts for a range of days
  List<WorkoutEvent> _getWorkoutsForRange(DateTime start, DateTime end) {
    final days = daysInRange(start, end);
    return [
      for (final d in days) ..._getWorkoutsForDay(d),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Workout Calendar'),
      ),
      body: Column(
        children: [
          TableCalendar<WorkoutEvent>(
            firstDay: kFirstDay,
            lastDay: kLastDay,
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            rangeStartDay: _rangeStart,
            rangeEndDay: _rangeEnd,
            calendarFormat: _calendarFormat,
            rangeSelectionMode: _rangeSelectionMode,
            eventLoader: _getWorkoutsForDay, // Load workouts for each day
            startingDayOfWeek: StartingDayOfWeek.monday,
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              markersMaxCount: 1, // Show one dot per day with workouts
              markerDecoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
            ),
            onDaySelected: _onDaySelected,
            onRangeSelected: _onRangeSelected,
            onFormatChanged: (format) {
              if (_calendarFormat != format) {
                setState(() {
                  _calendarFormat = format;
                });
              }
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
          ),
          const SizedBox(height: 8.0),
          Expanded(
            child: ValueListenableBuilder<List<WorkoutEvent>>(
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
                        title: Text(value[index].workoutName),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
