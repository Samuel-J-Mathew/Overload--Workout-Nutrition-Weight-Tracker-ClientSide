import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:gymapp/models/journalHeatMap.dart';
import 'package:gymapp/pages/Jounral2.dart';
import 'package:gymapp/pages/StepCounterPage.dart';
import 'package:gymapp/pages/workout_page.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart'; // For WorkoutData
import '../components/CalorieTile.dart';
import '../data/GlobalState.dart';
import '../data/NutritionProvider.dart';
import '../data/WorkoutAnalyzer.dart';
import '../data/hive_database.dart';
import '../data/_LineChartPainterDown.dart';
import '../data/_LineChartPainterUp.dart';
import '../data/workout_data.dart'; // Import your WorkoutData class
import '../models/heat_map.dart';
import '../models/heat_map_2.dart';
import '../models/step_log.dart';
import '../models/weight_log.dart';
import '../models/workout.dart';
import 'BuildBodyHome.dart';
import 'MySplitPage.dart';
import 'SearchPage.dart';
import 'WeightLogPage.dart';
import 'WeightTrendpage.dart';
import 'bigHeatMap.dart';
import 'journalPage.dart';

class UpdatedHome extends StatefulWidget {
  @override
  _UpdatedHomeState createState() => _UpdatedHomeState();
}

class _UpdatedHomeState extends State<UpdatedHome> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();
  // Track expanded muscle groups
  final Set<String> expandedMuscleGroups = {};
  final averageCals = GlobalState().averageCals;
  String todayDateString = DateFormat('yyyy-MM-dd').format(DateTime.now());
  IconData testicon = Icons.add;
  bool iconBool = true;
  bool click = true;
  double? overallStrengthChange;
  double? mostRecentWeight;
  double? _weeklyWeightTrend;
  double? getAverageSteps;
  Map<String, bool> exerciseClickStatus = {};
  String? mostImprovedGroup;
  double? mostImprovedPercent;
  final ScrollController _scrollController = ScrollController();
  double _workoutCardHeight = 320; // Default height
  bool _showSearchBar =
  true; // This will control the visibility of the search bar.
  List<StepLog> _stepLogs = [];
  void _fetchStepLogs() async {
    final db = Provider.of<HiveDatabase>(context, listen: false);
    _stepLogs = db
        .getStepLogs(); // Adjust this method according to your actual data fetching logic
    setState(() {});
  }
  Future<void> _loadImprovementData() async {
    final db = Provider.of<HiveDatabase>(context, listen: false);
    final analyzer = WorkoutAnalyzer(db);
    final result = await analyzer.getMostImprovedMuscleGroup();

    if (result != null && mounted) {
      setState(() {
        mostImprovedGroup = result.key;
        mostImprovedPercent = result.value;
      });
    }
  }
  Future<void> _calculateWeightTrend() async {
    final db = Provider.of<HiveDatabase>(context, listen: false);
    final List<WeightLog> logs = db.getWeightLogs();

    final cutoff = DateTime.now().subtract(Duration(days: 30));
    final filteredLogs = logs
        .where((log) => log.date.isAfter(cutoff))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    if (filteredLogs.length < 2) return;

    final startWeight = filteredLogs.first.weight;
    final endWeight = filteredLogs.last.weight;

    final durationDays =
        filteredLogs.last.date.difference(filteredLogs.first.date).inDays;

    if (durationDays == 0) return;

    final double weightChange = endWeight - startWeight;
    final double lbsPerWeek = weightChange / (durationDays / 7);

    setState(() {
      _weeklyWeightTrend = lbsPerWeek;
    });
  }

  Future<void> _loadStrengthData() async {
    final db = Provider.of<HiveDatabase>(context, listen: false);
    final analyzer = WorkoutAnalyzer(db);
    final change = await analyzer.getOverallStrengthChange();

    if (mounted) {
      setState(() {
        overallStrengthChange = change;
      });
    }
  }
  void _fetchAverageSteps() async {
    double averageSteps =
    await StepCounterPage.fetchAndCalculateAverageSteps(context);
    if (mounted) {
      setState(() {
        getAverageSteps = averageSteps;
      });
    }
  }
  void signUserOut() {
    FirebaseAuth.instance.signOut();
  }
  @override
  void initState() {
    super.initState();
    _loadImprovementData();
    _loadStrengthData();
    _calculateWeightTrend();
    _fetchStepLogs();
    _fetchAverageSteps();
    Provider.of<NutritionProvider>(context, listen: false)
        .loadNutritionalInfo();
    // Fetching today's split and adjusting height dynamically
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final todaysSplit =
      Provider.of<WorkoutData>(context, listen: false).getTodaysSplit();
      if (todaysSplit != null) {
        setState(() {
          final muscleGroupCount = todaysSplit.muscleGroups.length;
          if (muscleGroupCount == 1) {
            _workoutCardHeight = 150;
          } else if (muscleGroupCount == 2) {
            _workoutCardHeight = 220;
          } else if (muscleGroupCount == 3) {
            _workoutCardHeight = 320;
          } else if (muscleGroupCount >= 4) {
            _workoutCardHeight = 420;
          } else if (muscleGroupCount >= 5) {
            _workoutCardHeight = 520;
          } else {
            _workoutCardHeight = 120; // Default for no muscle groups
          }
          if (todaysSplit.muscleGroups.isEmpty) {
            _pageController.animateToPage(
              1,
              duration: Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            );
          }
        });
      }
    });
    _scrollController.addListener(() {
      if (_scrollController.position.userScrollDirection ==
          ScrollDirection.reverse) {
        if (_showSearchBar) setState(() => _showSearchBar = false);
      } else if (_scrollController.position.userScrollDirection ==
          ScrollDirection.forward) {
        if (!_showSearchBar) setState(() => _showSearchBar = true);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final workoutData = Provider.of<WorkoutData>(context, listen: false);
      final db = Provider.of<HiveDatabase>(context,
          listen: false); // Get the Hive database instance
      workoutData
          .initalizeWorkoutList(); // Initialize workout list from database
      // Fetch the most recent weight and update the state
      final latestLog = db.getMostRecentWeightLog();
      if (latestLog != null) {
        setState(() {
          mostRecentWeight = latestLog.weight;
        });
      }
    });
  }

  // Widget to build each exercise tile
  double _calculateHeight(int muscleGroupCount) {
    if (muscleGroupCount == 1) {
      return 150;
    } else if (muscleGroupCount == 2) {
      return 220;
    } else {
      return 320; // Default maximum height
    }
  }

  void _openSearchSheet(BuildContext context) {
    Workout todayWorkout =
    Provider.of<WorkoutData>(context, listen: false).ensureTodayWorkout();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8, // initially cover 80% of the screen
          maxChildSize: 0.95, // when dragged to full, cover 95% of the screen
          minChildSize: 0.5, // minimum size of the sheet when collapsed
          expand:
          false, // Set this to false if you don't want the sheet to expand to full screen
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
                  color: Colors
                      .grey[900], // Set the color here within the decoration
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ), // Circular edges at the top
                ),
                child: WorkoutPage(
                  workoutId: todayWorkout.id,
                  workoutName: todayWorkout.name,
                  openDialog: true,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget buildWorkoutCard(String title, String message) {
    var workoutData = Provider.of<WorkoutData>(context, listen: false);
    final todaysSplit =
    Provider.of<WorkoutData>(context, listen: false).getTodaysSplit();
    if (todaysSplit == null || todaysSplit.muscleGroups.isEmpty) {
      return Center(
        child: Text(
          'No workout scheduled for today',
          style: TextStyle(color: Colors.grey[400]),
        ),
      );
    }
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      color: Color.fromRGBO(42, 42, 42, 1),
      child: Container(
        height: _workoutCardHeight,
        child: SingleChildScrollView(
          physics: ClampingScrollPhysics(),
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
                          if (expandedMuscleGroups
                              .contains(muscleGroup.muscleGroupName)) {
                            expandedMuscleGroups
                                .remove(muscleGroup.muscleGroupName);
                          } else {
                            expandedMuscleGroups.add(muscleGroup.muscleGroupName);
                          }

                          // Calculate the new height based on which muscle groups are currently expanded
                          int totalExpandedExercises =
                          expandedMuscleGroups.fold(0, (sum, groupName) {
                            final group = todaysSplit.muscleGroups
                                .firstWhere((g) => g.muscleGroupName == groupName);
                            // Return null if not found to prevent exceptions

                            return sum + (group?.exercises.length ?? 0);
                          });

                          const double baseHeight =
                          300; // Base height when no muscle groups are expanded
                          const double extraHeightPerExercise =
                          65; // Additional height per expanded exercise

                          if (totalExpandedExercises > 0) {
                            _workoutCardHeight = baseHeight +
                                (totalExpandedExercises * extraHeightPerExercise);
                          } else {
                            // Revert to the initial sizing based on muscle group counts
                            final muscleGroupCount =
                                todaysSplit.muscleGroups.length;
                            if (muscleGroupCount == 1) {
                              _workoutCardHeight = 150;
                            } else if (muscleGroupCount == 2) {
                              _workoutCardHeight = 220;
                            } else if (muscleGroupCount == 3) {
                              _workoutCardHeight = 320;
                            } else if (muscleGroupCount >= 4) {
                              _workoutCardHeight = 420;
                            } else {
                              _workoutCardHeight =
                              120; // Default for no muscle groups
                            }
                          }
                        });
                      },
                    ),
                    Divider(color: Colors.grey[600]),
                    if (expandedMuscleGroups
                        .contains(muscleGroup.muscleGroupName)) ...[
                      for (var exercise in muscleGroup.exercises) ...[
                        Builder(
                          builder: (context) {
                            // Attempt to fetch most recent exercise details
                            var recentExercise =
                            Provider.of<WorkoutData>(context, listen: false)
                                .getMostRecentExerciseDetails(exercise.name);
                            var displaySets = recentExercise?.sets ?? exercise.sets;
                            var displayReps = recentExercise?.reps ?? exercise.reps;
                            var displayWeight =
                                recentExercise?.weight ?? exercise.weight;

                            return Padding(
                              padding: const EdgeInsets.only(left: 16.0),
                              child: ListTile(
                                leading: Icon(Icons.check_circle_outline,
                                    color: Colors.white),
                                title: Text(
                                  exercise.name,
                                  style: TextStyle(color: Colors.white),
                                ),
                                subtitle: Text(
                                  '$displaySets sets x $displayReps reps at $displayWeight lbs',
                                  style: TextStyle(color: Colors.grey[400]),
                                ),
                                trailing: IconButton(
                                  icon: Icon(
                                      exerciseClickStatus[exercise.name] ?? false
                                          ? Icons.check
                                          : Icons.add,
                                      color: Colors.white),
                                  onPressed: () {
                                    setState(() {
                                      exerciseClickStatus[exercise.name] =
                                      true; // Set the status to true when clicked
                                    });
                                    workoutData.logExercise(exercise);
                                  },
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
    );
  }

  Widget buildCustomCard(String title, String content) {
    return Card(
      margin: const EdgeInsets.all(0),
      color: Color.fromRGBO(42, 42, 42, 1),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment
              .center, // Centers vertically in the available space
          crossAxisAlignment: CrossAxisAlignment
              .stretch, // Centers horizontally in the available space
          children: [
            Expanded(
              child: CalorieTile(),
            ),
          ],
        ),
      ),
    );
  }

  double calculateDynamicHeight(dynamic todaysSplit) {
    // Default height when no data is present
    if (todaysSplit == null || todaysSplit.muscleGroups.isEmpty) {
      return 300; // Default height
    }

    // Calculate base height and add extra height for each exercise
    const double baseHeight = 400;
    const double extraHeightPerExercise = 50;

    // Count the total number of exercises
    int totalExercises = todaysSplit.muscleGroups.fold(
      0,
          (sum, group) => sum + group.exercises.length,
    );

    // Calculate total height
    return baseHeight + (totalExercises * extraHeightPerExercise);
  }

  @override
  Widget build(BuildContext context) {
    final workoutsThisWeek = Provider.of<WorkoutData>(context, listen: false)
        .getThisWeekWorkoutCount();
    final todaysSplit =
    Provider.of<WorkoutData>(context, listen: false).getTodaysSplit();
    // Track the current page index

    return Scaffold(
      backgroundColor: Color.fromRGBO(31, 31, 31, 1),

      body: Stack(
        children: [
          ListView(
            controller: _scrollController, // Attach the controller here.
            children: <Widget>[
              SizedBox(height: 20),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                    color: Color.fromRGBO(31, 31, 31, 1),
                    borderRadius: BorderRadius.circular(10)),
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment
                      .start, // Aligns children to the start of the main-axis
                  children: [
                    Text(
                      DateFormat('EEEE, MMMM d')
                          .format(DateTime.now())
                          .toUpperCase(), // Formats and converts date to upper case
                      style: TextStyle(
                        color: Colors.grey[600], // Dark grey color for the date
                        fontSize: 14, // Smaller font size for the date
                      ),
                    ),
                    Text(
                      'My Hub',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Column(
                  children: [
                    // Add padding or header if needed
                    SizedBox(height: 1),
                    SizedBox(
                      height:
                      _workoutCardHeight, // Dynamically adjust height based on the state
                      child: PageView(
                        controller: _pageController,
                        onPageChanged: (index) {
                          setState(() {
                            _currentIndex =
                                index; // Update the current index to reflect the new page
                            if (index == 1) {
                              // If the second page is visible
                              _workoutCardHeight =
                              260; // Set height to 220 when on the second page
                            } else {
                              // Fetch the today's split again to determine muscle group count
                              final todaysSplit = Provider.of<WorkoutData>(
                                  context,
                                  listen: false)
                                  .getTodaysSplit();
                              if (todaysSplit != null) {
                                int muscleGroupCount =
                                    todaysSplit.muscleGroups.length;
                                if (muscleGroupCount == 1) {
                                  _workoutCardHeight = 150;
                                } else if (muscleGroupCount == 2) {
                                  _workoutCardHeight = 220;
                                } else if (muscleGroupCount == 3) {
                                  _workoutCardHeight = 320;
                                } else if (muscleGroupCount >= 4) {
                                  _workoutCardHeight = 420;
                                }
                              } else {
                                _workoutCardHeight =
                                120; // Default for no muscle groups if no split found
                              }
                            }
                          });
                        },
                        children: [
                          buildWorkoutCard(
                            'Today\'s Workout',
                            todaysSplit == null
                                ? 'No workout data available.'
                                : todaysSplit.muscleGroups.isEmpty
                                ? 'No workout planned for today.'
                                : '',
                          ),
                          Center(
                              child: buildCustomCard(
                                  'Card 2', 'This is the second card.')),
                        ],
                      ),
                    ),

                    SizedBox(
                      height: 3,
                    ),
                    // Optionally add dots or indicators for pages
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        2,
                            (index) => AnimatedContainer(
                          duration: Duration(milliseconds: 300),
                          margin: EdgeInsets.symmetric(horizontal: 4),
                          width: _currentIndex == index ? 12 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _currentIndex == index
                                ? Colors.blue
                                : Colors.grey,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 1),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 10.0),
              ),
              // --- Improvement Section Start ---
              Container(
                padding: EdgeInsets.all(20),
                color: Color.fromRGBO(20, 20, 20, 1),
                child: Column(
                  children: [
                    // --- Improvement Section Start ---
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Improvement',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 10),
                          Row(
                            children: [
                              // Left column: Biceps (large, full height)
                              Expanded(
                                flex: 1,
                                child: _improvementTile(
                                  title: mostImprovedGroup ?? "Loading...",
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          SizedBox(
                                            width: 90,
                                            height: 90,
                                            child: CircularProgressIndicator(
                                              value: ((mostImprovedPercent ?? 0) / 100).clamp(0.0, 1.0),
                                              backgroundColor: Colors.grey[800],
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
                                              strokeWidth: 8,
                                            ),
                                          ),
                                          Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                "${(mostImprovedPercent ?? 0).toStringAsFixed(0)}%",
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 22,
                                                ),
                                              ),
                                              Text(
                                                "Increase",
                                                style: TextStyle(
                                                  color: Colors.white60,
                                                  fontSize: 10,
                                                  fontStyle: FontStyle.italic,
                                                ),
                                              ),
                                            ],
                                          ),

                                        ],
                                      ),
                                      SizedBox(height: 12),
                                      Divider(color: Colors.white70, thickness: 0.75, height: 1),
                                      SizedBox(height: 6),
                                      Text(
                                        "Past Month",
                                        style: TextStyle(
                                          color: Colors.white60,
                                          fontSize: 12,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                  ),
                                  big: true,
                                  doubleHeight: true,
                                ),



                              ),
                              SizedBox(width: 12),
                              // Right column: Strength and Weight stacked
                              Expanded(
                                flex: 1,
                                child: Column(
                                  children: [
                                    _improvementTile(
                                      title: "Overall Strength",
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min, // ← This prevents overflow
                                        children: [
                                          SizedBox(height: 2),
                                          SizedBox(
                                            height: 20, // reduced from 24
                                            child: CustomPaint(
                                              size: Size(60, 20),
                                              painter: overallStrengthChange == null
                                                  ? null
                                                  : overallStrengthChange! >= 0
                                                  ? LineChartPainterUp()
                                                  : LineChartPainterDown(),
                                            ),
                                          ),
                                          SizedBox(height: 2),
                                          Divider(
                                            color: Colors.white70,
                                            height: 2,
                                            thickness: 0.75,
                                          ),
                                          Text(
                                            overallStrengthChange == null
                                                ? "Loading..."
                                                : "${overallStrengthChange! >= 0 ? '+' : ''}${overallStrengthChange!.toStringAsFixed(1)}% ${overallStrengthChange! >= 0 ? 'increase' : 'decrease'} in the past month",
                                            style: TextStyle(
                                              color: Colors.white60,
                                              fontSize: 10,
                                              fontStyle: FontStyle.italic,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                      halfHeight: true,
                                    ),



                                    SizedBox(height: 12),
                                    _improvementTile(
                                      title: "Weight (lbs)",
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Divider(
                                            color: Colors.white70,
                                            height: 8,
                                            thickness: 0.75,
                                          ),
                                          _weeklyWeightTrend == null
                                              ? Text(
                                            "Loading...",
                                            style: TextStyle(
                                              color: Colors.white60,
                                              fontStyle: FontStyle.italic,
                                              fontSize: 13,
                                            ),
                                          )
                                              : Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                _weeklyWeightTrend! < 0
                                                    ? Icons.arrow_downward
                                                    : Icons.arrow_upward,
                                                color: _weeklyWeightTrend! < 0 ? Colors.blue : Colors.blue,
                                                size: 20,
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                "${_weeklyWeightTrend! > 0 ? '+' : ''}${_weeklyWeightTrend!.toStringAsFixed(1)} lbs/week",
                                                style: TextStyle(
                                                  color: _weeklyWeightTrend! < 0
                                                      ? Colors.white
                                                      : Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      halfHeight: true,
                                    ),

                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // --- Improvement Section End ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Metrics & Trends',
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
                            color: Color.fromRGBO(31, 31, 31, 1),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 19.0),
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
                                    color: Colors.white70,
                                    height:
                                    1, // Set minimal height to reduce space
                                    thickness:
                                    .75, // Minimal visual thickness
                                  ),
                                  Container(
                                    padding: EdgeInsets
                                        .zero, // Ensures no extra padding
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment
                                          .spaceBetween, // Ensures spacing between the text and the icon
                                      children: [
                                        Flexible(
                                          // Allows the text to resize dynamically
                                          child: RichText(
                                            overflow: TextOverflow
                                                .ellipsis, // Prevents text overflow by using ellipsis
                                            text: TextSpan(
                                              children: [
                                                TextSpan(
                                                  text:
                                                  '$workoutsThisWeek/7 ',
                                                  style: TextStyle(
                                                    fontSize: 17,
                                                    color: Colors.grey[
                                                    300], // Color for the numbers
                                                  ),
                                                ),
                                                TextSpan(
                                                  text: 'this week',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[
                                                    500], // Different color for the text
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        //SizedBox(width: 10,),
                                        IconButton(
                                          icon: Icon(Icons.arrow_forward_ios,
                                              size: 15,
                                              color: Colors
                                                  .white), // Reduced icon size
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                  const BigHeatMap()),
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
                            color: Color.fromRGBO(31, 31, 31, 1),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 19.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 10),
                                  Text(
                                    'Scale Weight',
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
                                  SizedBox(
                                    height: 10,
                                  ),
                                  SizedBox(
                                    height: 30,
                                    width: 185,
                                    child: WeightLogPage.buildWeightChart(
                                        context),
                                  ),
                                  SizedBox(
                                    height: 13,
                                  ),
                                  Divider(
                                    color: Colors.white54,
                                    height:
                                    1, // Set minimal height to reduce space
                                    thickness:
                                    .75, // Minimal visual thickness
                                  ),
                                  Container(
                                    padding: EdgeInsets
                                        .zero, // Ensures no extra padding
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment
                                          .spaceBetween, // Ensures spacing between the text and the icon
                                      children: [
                                        Flexible(
                                          // Allows the text to resize dynamically
                                          child: RichText(
                                            overflow: TextOverflow
                                                .ellipsis, // Prevents text overflow by using ellipsis
                                            text: TextSpan(
                                              children: [
                                                TextSpan(
                                                  text: '${mostRecentWeight ?? 0} ',
                                                  style: TextStyle(
                                                    fontSize: 17,
                                                    color: Colors.grey[
                                                    300], // Color for the numbers
                                                  ),
                                                ),
                                                TextSpan(
                                                  text: 'lbs',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[
                                                    500], // Different color for the text
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        //SizedBox(width: 10,),
                                        IconButton(
                                          icon: Icon(Icons.arrow_forward_ios,
                                              size: 15,
                                              color: Colors
                                                  .white), // Reduced icon size
                                          onPressed: () {
                                            // Use Navigator to push WeightLogPage onto the navigation stack
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      WeightTrendPage()),
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
                            color: Color.fromRGBO(31, 31, 31, 1),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 19.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 10),
                                  Text(
                                    'Step Logging',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    'Last 7 Days avg. ',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[400]),
                                  ),
                                  SizedBox(
                                    height: 10,
                                  ),
                                  SizedBox(
                                    height: 30,
                                    width: 185,
                                    child: StepCounterPage.buildMiniStepChart(
                                        context, _stepLogs),
                                  ),
                                  SizedBox(
                                    height: 13,
                                  ),
                                  Divider(
                                    color: Colors.white54,
                                    height:
                                    1, // Set minimal height to reduce space
                                    thickness:
                                    .75, // Minimal visual thickness
                                  ),
                                  Container(
                                    padding: EdgeInsets
                                        .zero, // Ensures no extra padding
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment
                                          .spaceBetween, // Ensures spacing between the text and the icon
                                      children: [
                                        Flexible(
                                          // Allows the text to resize dynamically
                                          child: RichText(
                                            overflow: TextOverflow
                                                .ellipsis, // Prevents text overflow by using ellipsis
                                            text: TextSpan(
                                              children: [
                                                TextSpan(
                                                  text:
                                                  '${getAverageSteps?.toStringAsFixed(0)} ',
                                                  style: TextStyle(
                                                    fontSize: 17,
                                                    color: Colors.grey[
                                                    300], // Color for the numbers
                                                  ),
                                                ),
                                                TextSpan(
                                                  text: 'steps',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[
                                                    500], // Different color for the text
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        //SizedBox(width: 10,),
                                        IconButton(
                                          icon: Icon(Icons.arrow_forward_ios,
                                              size: 15,
                                              color: Colors
                                                  .white), // Reduced icon size
                                          onPressed: () {
                                            // Use Navigator to push WeightLogPage onto the navigation stack
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      StepCounterPage()),
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
                            color: Color.fromRGBO(31, 31, 31, 1),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 19.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 10),
                                  Text(
                                    'Check-In Entries',
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
                                  JournalHeatMap(),
                                  SizedBox(height: 8),
                                  Divider(
                                    color: Colors.white70,
                                    height:
                                    1, // Set minimal height to reduce space
                                    thickness:
                                    .75, // Minimal visual thickness
                                  ),
                                  Container(
                                    padding: EdgeInsets
                                        .zero, // Ensures no extra padding
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment
                                          .spaceBetween, // Ensures spacing between the text and the icon
                                      children: [
                                        Flexible(
                                          // Allows the text to resize dynamically
                                          child: RichText(
                                            overflow: TextOverflow
                                                .ellipsis, // Prevents text overflow by using ellipsis
                                            text: TextSpan(
                                              children: [
                                                TextSpan(
                                                  text:
                                                  '$workoutsThisWeek/7 ',
                                                  style: TextStyle(
                                                    fontSize: 17,
                                                    color: Colors.grey[
                                                    300], // Color for the numbers
                                                  ),
                                                ),
                                                TextSpan(
                                                  text: 'this week',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[
                                                    500], // Different color for the text
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        //SizedBox(width: 10,),
                                        IconButton(
                                          icon: Icon(Icons.arrow_forward_ios,
                                              size: 15,
                                              color: Colors
                                                  .white), // Reduced icon size
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      Jounral2()),
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
                  ],
                ),
              ),
              // --- Improvement Section End ---
            ],
          ),
          Positioned(
            top: 40, // Adjust the positioning based on your UI design
            right: 16, // Distance from the right edge
            child: IconButton(
              icon: Icon(Icons.logout, color: Colors.white),
              onPressed: signUserOut,
            ),
          ),

        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    // Don't forget to dispose the controller.
    super.dispose();
  }

  Widget _improvementTile({required String title, required Widget child, bool big = false, bool doubleHeight = false, bool halfHeight = false}) {
    double height = 90;
    if (big) height = 120;
    if (doubleHeight) height = 192;
    if (halfHeight) height = 90;
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: Color(0xFF232323),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: EdgeInsets.all(12),
      margin: big || doubleHeight ? EdgeInsets.only(bottom: 0) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          Spacer(),
          Center(child: child),
          Spacer(),
        ],
      ),
    );
  }
}

// Simple static line chart painter for Strength
class _LineChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.purple
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final path = Path();
    path.moveTo(0, size.height * 0.8);
    path.lineTo(size.width * 0.2, size.height * 0.6);
    path.lineTo(size.width * 0.4, size.height * 0.7);
    path.lineTo(size.width * 0.6, size.height * 0.4);
    path.lineTo(size.width * 0.8, size.height * 0.5);
    path.lineTo(size.width, size.height * 0.2);
    canvas.drawPath(path, paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
