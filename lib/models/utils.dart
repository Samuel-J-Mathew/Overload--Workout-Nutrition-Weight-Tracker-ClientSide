import 'dart:collection';
import 'package:table_calendar/table_calendar.dart';
import '../data/workout_data.dart'; // Import your workout data

/// Workout event class.
class WorkoutEvent {
  final String workoutName;

  const WorkoutEvent(this.workoutName);

  @override
  String toString() => workoutName;
}

/// Workout events using a [LinkedHashMap].
final kWorkoutEvents = LinkedHashMap<DateTime, List<WorkoutEvent>>(
  equals: isSameDay,
  hashCode: getHashCode,
);

int getHashCode(DateTime key) {
  return key.day * 1000000 + key.month * 10000 + key.year;
}

/// Returns a list of [DateTime] objects from [first] to [last], inclusive.
List<DateTime> daysInRange(DateTime first, DateTime last) {
  final dayCount = last.difference(first).inDays + 1;
  return List.generate(
    dayCount,
        (index) => DateTime.utc(first.year, first.month, first.day + index),
  );
}

final kToday = DateTime.now();
final kFirstDay = DateTime(kToday.year - 1, kToday.month, kToday.day);
final kLastDay = DateTime(kToday.year + 1, kToday.month, kToday.day);
