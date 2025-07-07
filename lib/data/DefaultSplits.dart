import '../models/SingleExercise.dart';
import '../data/exercise_list.dart';

class DefaultSplits {
  static Map<String, List<SingleExercise>> getDefaultSplit(String splitName) {
    switch (splitName.toLowerCase()) {
      case 'ppl':
        return {
          'Push': exerciseList.where((e) => ['Chest', 'Shoulders', 'Triceps'].contains(e.muscleGroup)).toList(),
          'Pull': exerciseList.where((e) => ['Back', 'Biceps'].contains(e.muscleGroup)).toList(),
          'Legs': exerciseList.where((e) => ['Legs'].contains(e.muscleGroup)).toList(),
        };
      case 'arnold split':
        return {
          'Chest/Back': exerciseList.where((e) => ['Chest', 'Back'].contains(e.muscleGroup)).toList(),
          'Shoulders/Arms': exerciseList.where((e) => ['Shoulders', 'Biceps', 'Triceps'].contains(e.muscleGroup)).toList(),
          'Legs': exerciseList.where((e) => ['Legs'].contains(e.muscleGroup)).toList(),
        };
      case 'full body':
        return {
          'Full Body': exerciseList,
        };
      case 'bro split':
        return {
          'Chest': exerciseList.where((e) => e.muscleGroup == 'Chest').toList(),
          'Back': exerciseList.where((e) => e.muscleGroup == 'Back').toList(),
          'Legs': exerciseList.where((e) => e.muscleGroup == 'Legs').toList(),
          'Shoulders': exerciseList.where((e) => e.muscleGroup == 'Shoulders').toList(),
          'Arms': exerciseList.where((e) => ['Biceps', 'Triceps'].contains(e.muscleGroup)).toList(),
        };
      case 'upper lower':
        return {
          'Upper': exerciseList.where((e) => ['Chest', 'Back', 'Shoulders', 'Biceps', 'Triceps'].contains(e.muscleGroup)).toList(),
          'Lower': exerciseList.where((e) => e.muscleGroup == 'Legs').toList(),
        };
      default:
        return {};
    }
  }
}
