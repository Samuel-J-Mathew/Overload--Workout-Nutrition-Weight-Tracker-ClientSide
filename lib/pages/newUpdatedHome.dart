import 'package:flutter/material.dart';
import 'package:gymapp/pages/workout_page.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart'; // For WorkoutData
import '../data/hive_database.dart';
import '../data/workout_data.dart'; // Import your WorkoutData class
import '../models/heat_map.dart';
import '../models/heat_map_2.dart';
import 'BuildBodyHome.dart';
import 'MySplitPage.dart';
import 'SearchPage.dart';
import 'WeightLogPage.dart';
import 'bigHeatMap.dart';
import 'package:intl/intl.dart';

class NewUpdatedHome extends StatefulWidget {
  @override
  _NewUpdatedHomeState createState() => _NewUpdatedHomeState();
}

class _NewUpdatedHomeState extends State<NewUpdatedHome> {
  int _selectedIndex = 0;
  final Set<String> expandedMuscleGroups = {};
  String todayDateString = DateFormat('yyyy-MM-dd').format(DateTime.now());
  IconData testicon = Icons.add;
  bool iconBool = true;
  bool click = true;
  double? mostRecentWeight;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final workoutData = Provider.of<WorkoutData>(context, listen: false);
      final db = Provider.of<HiveDatabase>(context, listen: false); // Get the Hive database instance
      workoutData.initalizeWorkoutList(); // Initialize workout list from database
      // Fetch the most recent weight and update the state
      final latestLog = db.getMostRecentWeightLog();
      if (latestLog != null) {
        setState(() {
          mostRecentWeight = latestLog.weight;
        });
      }
    });
  }
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
 Widget buildBodyHome(){
   var workoutData = Provider.of<WorkoutData>(context, listen: false);
   final todaysSplit = Provider.of<WorkoutData>(context, listen: false).getTodaysSplit();
   final workoutsThisWeek = Provider.of<WorkoutData>(context, listen: false).getThisWeekWorkoutCount();

   return Column(

     children: [
       SizedBox(height: 45),
       Container(
         padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
         decoration: BoxDecoration(
             color: Colors.grey[850],
             borderRadius: BorderRadius.circular(10)
         ),
         alignment: Alignment.centerLeft,
         child: Column(
           crossAxisAlignment: CrossAxisAlignment.start,  // Aligns children to the start of the main-axis
           children: [
             Text(
               DateFormat('EEEE, MMMM d').format(DateTime.now()).toUpperCase(),  // Formats and converts date to upper case
               style: TextStyle(
                 color: Colors.grey[500],  // Dark grey color for the date
                 fontSize: 13,  // Smaller font size for the date
               ),
             ),
             Text(
               'Dashboard',
               style: TextStyle(
                 color: Colors.white,
                 fontSize: 35,
                 fontWeight: FontWeight.bold,
               ),
             ),
           ],
         ),
       ),
       Padding(
         padding: const EdgeInsets.symmetric(horizontal: 16.0),
         child:
         Card(
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
                         Builder(
                           builder: (context) {
                             // Attempt to fetch most recent exercise details
                             var recentExercise = Provider.of<WorkoutData>(context, listen: false).getMostRecentExerciseDetails(exercise.name);
                             var displaySets = recentExercise?.sets ?? exercise.sets;
                             var displayReps = recentExercise?.reps ?? exercise.reps;
                             var displayWeight = recentExercise?.weight ?? exercise.weight;

                             return Padding(
                               padding: const EdgeInsets.only(left: 16.0),
                               child: ListTile(
                                 leading: Icon(Icons.check_circle_outline, color: Colors.white),
                                 title: Text(
                                   exercise.name,
                                   style: TextStyle(color: Colors.white),
                                 ),
                                 subtitle: Text(
                                   '$displaySets sets x $displayReps reps at $displayWeight lbs',
                                   style: TextStyle(color: Colors.grey[400]),
                                 ),
                                 trailing: IconButton(
                                   icon: Icon(click ? Icons.add : Icons.check, color: Colors.white),
                                   onPressed: click ? () {
                                     setState(() {
                                       click = false;
                                     });
                                     workoutData.logExercise(exercise);
                                     setState(() {});
                                   } : null,
                                 ),
                               ),
                             );
                           },
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
                             SizedBox(height: 8),
                             Divider(
                               color: Colors.grey[600],
                               height: 1,  // Set minimal height to reduce space
                               thickness: 0.5,  // Minimal visual thickness
                             ),
                             Container(
                               padding: EdgeInsets.zero,  // Ensures no extra padding
                               child: Row(
                                 mainAxisAlignment: MainAxisAlignment.spaceBetween,  // Ensures spacing between the text and the icon
                                 children: [
                                   Flexible(  // Allows the text to resize dynamically
                                     child: RichText(
                                       overflow: TextOverflow.ellipsis,  // Prevents text overflow by using ellipsis
                                       text: TextSpan(
                                         children: [
                                           TextSpan(
                                             text: '$workoutsThisWeek/7 ',
                                             style: TextStyle(
                                               fontSize: 17,
                                               color: Colors.grey[300],  // Color for the numbers
                                             ),
                                           ),
                                           TextSpan(
                                             text: 'this week',
                                             style: TextStyle(
                                               fontSize: 12,
                                               color: Colors.grey[500],  // Different color for the text
                                             ),
                                           ),
                                         ],
                                       ),
                                     ),
                                   ),
                                   //SizedBox(width: 10,),
                                   IconButton(
                                     icon: Icon(Icons.arrow_forward_ios, size: 15, color: Colors.white),  // Reduced icon size
                                     onPressed: () {
                                       Navigator.push(
                                         context,
                                         MaterialPageRoute(builder: (context) => const BigHeatMap()),
                                       );
                                     },
                                   ),
                                 ],
                               ),
                             )


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
                             SizedBox(height: 10,),
                             SizedBox(
                               height: 30,
                               width: 185,
                               child: WeightLogPage.buildWeightChart(context),
                             ),
                             SizedBox(height: 13,),
                             Divider(
                               color: Colors.grey[600],
                               height: 1,  // Set minimal height to reduce space
                               thickness: 1,  // Minimal visual thickness
                             ),
                             Container(
                               padding: EdgeInsets.zero,  // Ensures no extra padding
                               child: Row(
                                 mainAxisAlignment: MainAxisAlignment.spaceBetween,  // Ensures spacing between the text and the icon
                                 children: [
                                   Flexible(  // Allows the text to resize dynamically
                                     child: RichText(
                                       overflow: TextOverflow.ellipsis,  // Prevents text overflow by using ellipsis
                                       text: TextSpan(
                                         children: [
                                           TextSpan(
                                             text: '$mostRecentWeight ',
                                             style: TextStyle(
                                               fontSize: 17,
                                               color: Colors.grey[300],  // Color for the numbers
                                             ),
                                           ),
                                           TextSpan(
                                             text: 'lbs',
                                             style: TextStyle(
                                               fontSize: 12,
                                               color: Colors.grey[500],  // Different color for the text
                                             ),
                                           ),
                                         ],
                                       ),
                                     ),
                                   ),
                                   //SizedBox(width: 10,),
                                   IconButton(
                                     icon: Icon(Icons.arrow_forward_ios, size: 15, color: Colors.white),  // Reduced icon size
                                     onPressed: () {
                                       // Use Navigator to push WeightLogPage onto the navigation stack
                                       Navigator.of(context).push(
                                         MaterialPageRoute(builder: (context) => WeightLogPage()),
                                       );
                                     },
                                   ),
                                 ],
                               ),
                             )
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
                 child: Row(
                   children: [
                     IconButton(
                       icon: Icon(Icons.search, color: Colors.white),
                       onPressed: () {
                         showModalBottomSheet(
                           context: context,
                           isScrollControlled: true,
                           backgroundColor: Colors.transparent,
                           builder: (BuildContext context) {
                             return DraggableScrollableSheet(

                               initialChildSize: 0.8, // initially cover 80% of the screen
                               maxChildSize: 0.95, // when dragged to full, cover 95% of the screen
                               minChildSize: 0.5, // minimum size of the sheet when collapsed
                               expand: false, // Set this to false if you don't want the sheet to expand to full screen
                               builder: (BuildContext context, ScrollController scrollController) {
                                 return Container(

                                   decoration: BoxDecoration(
                                     color: Colors.grey[900],
                                     borderRadius: BorderRadius.only(
                                       topLeft: Radius.circular(20),
                                       topRight: Radius.circular(20),
                                     ),
                                   ),
                                     child: Container(
                                       margin: EdgeInsets.only(top: 60),
                                       decoration: BoxDecoration(
                                         color: Colors.grey[900], // Set the color here within the decoration
                                         borderRadius: BorderRadius.only(
                                           topLeft: Radius.circular(20),
                                           topRight: Radius.circular(20),
                                         ), // Circular edges at the top
                                       ),
                                      // padding: EdgeInsets.only(top: 30), // Padding to push the content down
                                       child: WorkoutPage(
                                         workoutId: todayDateString,
                                         workoutName: todayDateString,
                                         openDialog: true,
                                       ),
                                     ),
                                 );
                               },
                             );
                           },
                         );
                       },
                     ),
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
   );

 }
  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return buildBodyHome(); // Placeholder for home content
      case 1:

        return SearchPage(
            workoutId: DateFormat('yyyy-MM-dd').format(DateTime.now()),
            workoutName: "Search Exercises"
        );
      case 2:
        return MySplitPage(); // Placeholder for MySplitPage content
      default:
        return buildBodyHome();
    }

  }
  Widget build(BuildContext context) {

    var workoutData = Provider.of<WorkoutData>(context, listen: false);
    final todaysSplit = Provider.of<WorkoutData>(context, listen: false).getTodaysSplit();
    final workoutsThisWeek = Provider.of<WorkoutData>(context, listen: false).getThisWeekWorkoutCount();

    return Scaffold(

      backgroundColor: Colors.grey[850],
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.fitness_center), label: 'Exercise Log'),
          BottomNavigationBarItem(icon: Icon(Icons.moving_rounded), label: 'Strategy'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: Colors.grey[900],
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey[400],
        type: BottomNavigationBarType.fixed,
      ),
      body: _buildBody(),
    );
  }

}
