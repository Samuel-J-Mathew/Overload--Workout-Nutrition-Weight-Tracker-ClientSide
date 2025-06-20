import 'package:intl/intl.dart';
import '../models/SingleExercise.dart';
import '../models/workout.dart';
import '../data/hive_database.dart';
import '../data/exercise_list.dart';
import 'package:collection/collection.dart';

class WorkoutAnalyzer {
  final HiveDatabase hiveDb;

  WorkoutAnalyzer(this.hiveDb);

  /// Returns map like { "Chest": +12.5, "Back": -5.2 }
  Future<Map<String, double>> calculateStrengthImprovementPerGroup() async {
    final now = DateTime.now();
    final cutoffDate = now.subtract(Duration(days: 30));// pull improvment from the past 30 days
    final workouts = hiveDb.readFromDatabase();

    final Map<String, List<MapEntry<DateTime, double>>> groupVolumes = {};

    for (var workout in workouts) {
      if (workout.date.isBefore(cutoffDate)) continue;

      for (var ex in workout.exercises) {
        final name = ex.name.trim();
        final sets = int.tryParse(ex.sets) ?? 1;
        final reps = int.tryParse(ex.reps) ?? 1;
        final weight = double.tryParse(ex.weight) ?? 0.0;

        final volume = sets * reps * weight;

        final matched = exerciseList.firstWhereOrNull(
              (e) => e.name.toLowerCase() == name.toLowerCase(),
        );
        final muscleGroup = matched?.muscleGroup ?? ex.musclegroup;

        if (muscleGroup == "Unknown" || muscleGroup.isEmpty) continue;

        groupVolumes.putIfAbsent(muscleGroup, () => []);
        groupVolumes[muscleGroup]!.add(MapEntry(workout.date, volume));
      }
    }

    final Map<String, double> improvementMap = {};

    for (var entry in groupVolumes.entries) {
      final logs = entry.value;
      logs.sort((a, b) => a.key.compareTo(b.key));

      if (logs.length < 2) continue;

      final first = logs.first.value;
      final last = logs.last.value;

      if (first > 0) {
        final percentChange = ((last - first) / first) * 100;
        improvementMap[entry.key] = percentChange;
      }
    }

    return improvementMap;
  }
  Future<double> getOverallStrengthChange() async {
    final improvements = await calculateStrengthImprovementPerGroup();
    if (improvements.isEmpty) return 0.0;
    return improvements.values.reduce((a, b) => a + b) / improvements.length;
  }

  Future<MapEntry<String, double>?> getMostImprovedMuscleGroup() async {
    final improvements = await calculateStrengthImprovementPerGroup();
    if (improvements.isEmpty) return null;
    return improvements.entries.reduce((a, b) => a.value > b.value ? a : b);
  }


}
