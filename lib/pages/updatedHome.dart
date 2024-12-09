import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // For WorkoutData
import '../data/workout_data.dart'; // Import your WorkoutData class
import '../models/heat_map.dart';
import '../models/heat_map_2.dart';

class UpdatedHome extends StatefulWidget {
  @override
  _UpdatedHomeState createState() => _UpdatedHomeState();
}

class _UpdatedHomeState extends State<UpdatedHome> {
  // Track expanded muscle groups
  final Set<String> expandedMuscleGroups = {};
IconData testicon = Icons.add;
bool iconBool = true;
bool click = true;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final workoutData = Provider.of<WorkoutData>(context, listen: false);
      workoutData.initalizeWorkoutList(); // Initialize workout list from database
    });
  }
  Widget build(BuildContext context) {
    // Fetch today's workout split dynamically
    var workoutData = Provider.of<WorkoutData>(context, listen: false);
    final todaysSplit = Provider.of<WorkoutData>(context, listen: false).getTodaysSplit();
    final workoutsThisWeek = Provider.of<WorkoutData>(context, listen: false).getThisWeekWorkoutCount();
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Dashboard',
          style: TextStyle(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.grey[850],
        elevation: 0,
      ),

      backgroundColor: Colors.grey[850],
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              color: Colors.grey[800],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Today\'s Workout',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Divider(color: Colors.grey[600]),
                    if (todaysSplit.muscleGroups.isEmpty)
                      Center(
                        child: Text(
                          'No workout planned for today.',
                          style: TextStyle(color: Colors.grey[400]),
                        ),

                      )

                    else
                      for (var muscleGroup in todaysSplit.muscleGroups) ...[
                        ListTile(
                          title: Text(
                            muscleGroup.muscleGroupName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 18,
                            ),
                          ),
                          leading: Icon(Icons.fitness_center, color: Colors.blue[400]),
                          trailing: CircleAvatar(
                            backgroundColor: Colors.blue[800],
                            child: Text(
                              '${muscleGroup.exercises.length}',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),

                          onTap: () {
                            setState(() {
                              if (expandedMuscleGroups.contains(muscleGroup.muscleGroupName)) {
                                expandedMuscleGroups.remove(muscleGroup.muscleGroupName);
                              } else {
                                expandedMuscleGroups.add(muscleGroup.muscleGroupName);
                              }
                            });
                          },
                        ),
                        Divider(color: Colors.grey[600]),
                        if (expandedMuscleGroups.contains(muscleGroup.muscleGroupName)) ...[
                          for (var exercise in muscleGroup.exercises) ...[
                            Padding(
                              padding: const EdgeInsets.only(left: 16.0),
                              child: ListTile(
                                leading: Icon(Icons.check_circle_outline, color: Colors.white),
                                title: Text(
                                  exercise.name,
                                  style: TextStyle(color: Colors.white),
                                ),
                                subtitle: Text(
                                  '${exercise.sets} sets x ${exercise.reps} reps at ${exercise.weight} lbs',
                                  style: TextStyle(color: Colors.grey[400]),
                                ),
                                trailing: IconButton(
                                  icon: Icon(click ? Icons.add : Icons.check, color: Colors.white),
                                  onPressed: click ? () {
                                    setState(() {
                                      click = false;  // Update state to reflect icon change
                                    });
                                    workoutData.logExercise(exercise);
                                    setState(() {});// Pass the correct ExerciseDetail object
                                  } : null,  // Disable button after one click
                                ),
                              ),
                            ),
                            Divider(color: Colors.grey[500]),
                          ],
                        ],
                      ],
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 25.0),
          ),
          Expanded(
            child: Container(
              padding: EdgeInsets.all(20),
              color: Colors.grey[900],
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Insights & Analytics',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        height: 165,
                        width: 185,
                        child: Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          color: Colors.grey[800],
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 19.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 10),
                                Text(
                                  'Gym Logging',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  'Last 30 Days',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[400],
                                  ),
                                ),
                                MyHeatMap2(),
                                SizedBox(height: 5),
                                Divider(color: Colors.grey[600]),
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 2),
                                  child: RichText(
                                    text: TextSpan(
                                      children: [
                                        TextSpan(
                                          text: '$workoutsThisWeek/7 ',
                                          style: TextStyle(
                                            fontSize: 17,
                                            color: Colors.grey[300], // Color for the numbers
                                          ),
                                        ),
                                        TextSpan(
                                          text: 'this week',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[500], // Different color for the text
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Container(
                        height: 165,
                        width: 185,
                        child: Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          color: Colors.grey[800],
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 19.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 10),
                                Text(
                                  'Weight Trend',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  'Last 7 Days',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[400]),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[850],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.all(8),
                    child: Row(
                      children: [
                        Icon(Icons.search, color: Colors.white),
                        SizedBox(width: 9),
                        Text(
                          'Search for an exercise',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
