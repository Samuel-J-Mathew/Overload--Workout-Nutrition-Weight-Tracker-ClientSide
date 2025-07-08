import 'WorkoutSplit.dart';

class DefaultSplits {
  static List<WorkoutSplit> ppl() {
    return [
      WorkoutSplit(
        day: 'Monday',
        muscleGroups: [
          MuscleGroupSplit(muscleGroupName: 'Chest', exercises: [
            ExerciseDetail(name: 'Incline Smith Bench', sets: 3, reps: 6, weight: 0),
            ExerciseDetail(name: 'Pec Deck', sets: 3, reps: 6, weight: 0),
          ]),
          MuscleGroupSplit(muscleGroupName: 'Shoulders', exercises: [
            ExerciseDetail(name: 'Machine Shoulder Press', sets: 3, reps: 6, weight: 0),
            ExerciseDetail(name: 'Cable Lateral Raise', sets: 3, reps: 6, weight: 0),
          ]),
          MuscleGroupSplit(muscleGroupName: 'Triceps', exercises: [
            ExerciseDetail(name: 'Cable Pushdowns', sets: 3, reps: 6, weight: 0),
            ExerciseDetail(name: 'Tricep overhead extension', sets: 3, reps: 6, weight: 0),
          ]),
        ],
      ),
      WorkoutSplit(
        day: 'Tuesday',
        muscleGroups: [
          MuscleGroupSplit(muscleGroupName: 'Back', exercises: [
            ExerciseDetail(name: 'Lat Pulldowns', sets: 3, reps: 6, weight: 0),
            ExerciseDetail(name: 'Seated Rows', sets: 3, reps: 6, weight: 0),
          ]),
          MuscleGroupSplit(muscleGroupName: 'Biceps', exercises: [
            ExerciseDetail(name: 'DB Preacher Curls', sets: 3, reps: 6, weight: 0),
            ExerciseDetail(name: 'Cable Bayesian Curl', sets: 3, reps: 6, weight: 0),
          ]),
        ],
      ),
      WorkoutSplit(
        day: 'Wednesday',
        muscleGroups: [
          MuscleGroupSplit(muscleGroupName: 'Legs', exercises: [
            ExerciseDetail(name: 'Hack Squats', sets: 3, reps: 6, weight: 0),
            ExerciseDetail(name: 'Leg Curls', sets: 2, reps: 6, weight: 0),
            ExerciseDetail(name: 'Leg Extensions', sets: 2, reps: 6, weight: 0),
          ]),
          MuscleGroupSplit(muscleGroupName: 'Abs', exercises: [
            ExerciseDetail(name: 'Leg Raises', sets: 3, reps: 6, weight: 0),
            ExerciseDetail(name: 'Cable Crunches', sets: 3, reps: 6, weight: 0),
          ]),
        ],
      ),
    ];
  }

  static List<WorkoutSplit> arnold() {
    return [
      WorkoutSplit(
        day: 'Monday',
        muscleGroups: [
          MuscleGroupSplit(muscleGroupName: 'Chest', exercises: [
            ExerciseDetail(name: 'Incline Smith Bench', sets: 3, reps: 6, weight: 0),
            ExerciseDetail(name: 'Pec Deck', sets: 3, reps: 6, weight: 0),
          ]),
          MuscleGroupSplit(muscleGroupName: 'Back', exercises: [
            ExerciseDetail(name: 'Lat Pulldowns', sets: 3, reps: 6, weight: 0),
            ExerciseDetail(name: 'Seated Rows', sets: 3, reps: 6, weight: 0),
          ]),
        ],
      ),
      WorkoutSplit(
        day: 'Tuesday',
        muscleGroups: [
          MuscleGroupSplit(muscleGroupName: 'Shoulders', exercises: [
            ExerciseDetail(name: 'Machine Shoulder Press', sets: 3, reps: 6, weight: 0),
            ExerciseDetail(name: 'Cable Lateral Raise', sets: 3, reps: 6, weight: 0),
          ]),
          MuscleGroupSplit(muscleGroupName: 'Biceps', exercises: [
            ExerciseDetail(name: 'DB Preacher Curls', sets: 3, reps: 6, weight: 0),
            ExerciseDetail(name: 'Cable Bayesian Curl', sets: 3, reps: 6, weight: 0),
          ]),
          MuscleGroupSplit(muscleGroupName: 'Triceps', exercises: [
            ExerciseDetail(name: 'Cable Pushdowns', sets: 3, reps: 6, weight: 0),
            ExerciseDetail(name: 'Tricep overhead extension', sets: 3, reps: 6, weight: 0),
          ]),
        ],
      ),
      WorkoutSplit(
        day: 'Wednesday',
        muscleGroups: [
          MuscleGroupSplit(muscleGroupName: 'Legs', exercises: [
            ExerciseDetail(name: 'Hack Squats', sets: 3, reps: 6, weight: 0),
            ExerciseDetail(name: 'Leg Curls', sets: 2, reps: 6, weight: 0),
            ExerciseDetail(name: 'Leg Extensions', sets: 2, reps: 6, weight: 0),
          ]),
        ],
      ),
    ];
  }

  static List<WorkoutSplit> fullBody() {
    return [
      WorkoutSplit(
        day: 'Monday',
        muscleGroups: [
          MuscleGroupSplit(muscleGroupName: 'Chest', exercises: [
            ExerciseDetail(name: 'Incline Smith Bench', sets: 3, reps: 6, weight: 0),
            ExerciseDetail(name: 'Pec Deck', sets: 3, reps: 6, weight: 0),
          ]),
          MuscleGroupSplit(muscleGroupName: 'Back', exercises: [
            ExerciseDetail(name: 'Lat Pulldowns', sets: 3, reps: 6, weight: 0),
            ExerciseDetail(name: 'Seated Rows', sets: 3, reps: 6, weight: 0),
          ]),
          MuscleGroupSplit(muscleGroupName: 'Legs', exercises: [
            ExerciseDetail(name: 'Hack Squats', sets: 3, reps: 6, weight: 0),
            ExerciseDetail(name: 'Leg Curls', sets: 2, reps: 6, weight: 0),
            ExerciseDetail(name: 'Leg Extensions', sets: 2, reps: 6, weight: 0),
          ]),
        ],
      ),
      WorkoutSplit(
        day: 'Wednesday',
        muscleGroups: [
          MuscleGroupSplit(muscleGroupName: 'Shoulders', exercises: [
            ExerciseDetail(name: 'Machine Shoulder Press', sets: 3, reps: 6, weight: 0),
            ExerciseDetail(name: 'Cable Lateral Raise', sets: 3, reps: 6, weight: 0),
          ]),
          MuscleGroupSplit(muscleGroupName: 'Biceps', exercises: [
            ExerciseDetail(name: 'DB Preacher Curls', sets: 3, reps: 6, weight: 0),
            ExerciseDetail(name: 'Cable Bayesian Curl', sets: 3, reps: 6, weight: 0),
          ]),
          MuscleGroupSplit(muscleGroupName: 'Triceps', exercises: [
            ExerciseDetail(name: 'Cable Pushdowns', sets: 3, reps: 6, weight: 0),
            ExerciseDetail(name: 'Tricep overhead extension', sets: 3, reps: 6, weight: 0),
          ]),
        ],
      ),
      WorkoutSplit(
        day: 'Friday',
        muscleGroups: [
          MuscleGroupSplit(muscleGroupName: 'Chest', exercises: [
            ExerciseDetail(name: 'Incline Smith Bench', sets: 3, reps: 6, weight: 0),
            ExerciseDetail(name: 'Pec Deck', sets: 3, reps: 6, weight: 0),
          ]),
          MuscleGroupSplit(muscleGroupName: 'Back', exercises: [
            ExerciseDetail(name: 'Lat Pulldowns', sets: 3, reps: 6, weight: 0),
            ExerciseDetail(name: 'Seated Rows', sets: 3, reps: 6, weight: 0),
          ]),
          MuscleGroupSplit(muscleGroupName: 'Legs', exercises: [
            ExerciseDetail(name: 'Hack Squats', sets: 3, reps: 6, weight: 0),
            ExerciseDetail(name: 'Leg Curls', sets: 2, reps: 6, weight: 0),
            ExerciseDetail(name: 'Leg Extensions', sets: 2, reps: 6, weight: 0),
          ]),
        ],
      ),
    ];
  }

  static List<WorkoutSplit> broSplit() {
    return [
      WorkoutSplit(
        day: 'Monday',
        muscleGroups: [
          MuscleGroupSplit(muscleGroupName: 'Chest', exercises: [
            ExerciseDetail(name: 'Incline Smith Bench', sets: 3, reps: 6, weight: 0),
            ExerciseDetail(name: 'Pec Deck', sets: 3, reps: 6, weight: 0),
          ]),
        ],
      ),
      WorkoutSplit(
        day: 'Tuesday',
        muscleGroups: [
          MuscleGroupSplit(muscleGroupName: 'Back', exercises: [
            ExerciseDetail(name: 'Lat Pulldowns', sets: 3, reps: 6, weight: 0),
            ExerciseDetail(name: 'Seated Rows', sets: 3, reps: 6, weight: 0),
          ]),
        ],
      ),
      WorkoutSplit(
        day: 'Wednesday',
        muscleGroups: [
          MuscleGroupSplit(muscleGroupName: 'Shoulders', exercises: [
            ExerciseDetail(name: 'Machine Shoulder Press', sets: 3, reps: 6, weight: 0),
            ExerciseDetail(name: 'Cable Lateral Raise', sets: 3, reps: 6, weight: 0),
          ]),
        ],
      ),
      WorkoutSplit(
        day: 'Thursday',
        muscleGroups: [
          MuscleGroupSplit(muscleGroupName: 'Biceps', exercises: [
            ExerciseDetail(name: 'DB Preacher Curls', sets: 3, reps: 6, weight: 0),
            ExerciseDetail(name: 'Cable Bayesian Curl', sets: 3, reps: 6, weight: 0),
          ]),
          MuscleGroupSplit(muscleGroupName: 'Triceps', exercises: [
            ExerciseDetail(name: 'Cable Pushdowns', sets: 3, reps: 6, weight: 0),
            ExerciseDetail(name: 'Tricep overhead extension', sets: 3, reps: 6, weight: 0),
          ]),
        ],
      ),
      WorkoutSplit(
        day: 'Friday',
        muscleGroups: [
          MuscleGroupSplit(muscleGroupName: 'Legs', exercises: [
            ExerciseDetail(name: 'Hack Squats', sets: 3, reps: 6, weight: 0),
            ExerciseDetail(name: 'Leg Curls', sets: 2, reps: 6, weight: 0),
            ExerciseDetail(name: 'Leg Extensions', sets: 2, reps: 6, weight: 0),
          ]),
        ],
      ),
    ];
  }
}
