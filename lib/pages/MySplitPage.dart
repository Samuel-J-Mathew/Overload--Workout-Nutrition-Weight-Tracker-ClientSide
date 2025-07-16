import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:gymapp/pages/weeklysplittile.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import '../data/GlobalState.dart';
import '../data/WorkoutSplit.dart';
import '../data/hive_database.dart';
import '../models/NutritionalInfo.dart';
import '../models/SingleExercise.dart';
import '../data/exercise_list.dart';
import 'package:collection/collection.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:auto_size_text/auto_size_text.dart';

class MySplitPage extends StatefulWidget {
  const MySplitPage({super.key});

  @override
  _MySplitPageState createState() => _MySplitPageState();
}

class _MySplitPageState extends State<MySplitPage>  {
  Map<String, SingleExercise?> selectedExercises = {};
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<WorkoutSplit> weeklySplits = [];
  HiveDatabase db = HiveDatabase();
  String _averageCals = "0";
  String _averageProtein = "0";
  String _averageCarbs = "0";
  String _averageFats = "0";
  final List<String> daysOfWeek = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];
  String selectedDay = 'Monday';
  List<String> allMuscleGroups = [
    'Chest',
    'Back',
    'Legs',
    'Biceps',
    'Shoulders',
    'Triceps',
    'Abs',
    'Rest Day'
  ];

  Map<String, Map<String, List<ExerciseDetail>>> daySplitData = {};
  List<String> selectedMuscleGroups = [];
  int _currentMuscleGroupIndex = 0;
  late PageController _muscleGroupPageController;

  // Persistent text field controllers for each muscle group
  Map<String, TextEditingController> _setsControllers = {};
  Map<String, TextEditingController> _repsControllers = {};
  Map<String, TextEditingController> _weightControllers = {};

  // Add scroll controller and focus nodes for modal sheet
  final ScrollController _modalScrollController = ScrollController();
  final Map<String, FocusNode> _setsFocusNodes = {};
  final Map<String, FocusNode> _repsFocusNodes = {};
  final Map<String, FocusNode> _weightFocusNodes = {};

  // --- Weight Goal State ---
  int? goalWeight;
  double? goalRate;
  int? maintenanceCalories;
  int? calculatedCalories;
  String? projectedEndDate;
  double? currentWeight;

  @override
  void initState() {
    super.initState();
    initHive();
    loadNutritionalInfo();
    weeklySplits = db.loadWorkoutSplits();
    // Initialize daySplitData for all days
    for (String day in daysOfWeek) {
      daySplitData[day] ??= {};
    }

    // Populate daySplitData from saved splits
    for (var split in weeklySplits) {
      daySplitData[split.day] = {
        for (var mg in split.muscleGroups)
          mg.muscleGroupName: mg.exercises,
      };
    }

    saveWorkoutSplitToFirestore();
    loadWorkoutSplitsFromFirestore();
    loadMacrosFromFirestore();
    _muscleGroupPageController = PageController();
    _loadWeightGoalData();
  }
  void saveWorkoutSplitToFirestore() {
    User? user = _auth.currentUser;
    if (user != null) {
      // Save workout program
      List<Map<String, dynamic>> workoutProgram = weeklySplits.map((split) {
        return {
          "day": split.day,
          "muscleGroups": split.muscleGroups.map((mg) {
            return {
              "muscleGroupName": mg.muscleGroupName,
              "exercises": mg.exercises.map((exercise) {
                return {
                  "name": exercise.name,
                  "sets": exercise.sets,
                  "reps": exercise.reps,
                  "weight": exercise.weight
                };
              }).toList()
            };
          }).toList()
        };
      }).toList();

      _firestore.collection('users').doc(user.uid).collection('split').doc('workoutProgram')
          .set({"splits": workoutProgram})
          .then((value) => print("Workout Program Saved"))
          .catchError((error) => print("Failed to save workout program: $error"));

      // Save macros
      Map<String, dynamic> macros = {
        "calories": _averageCals,
        "protein": _averageProtein,
        "carbs": _averageCarbs,
        "fats": _averageFats
      };

      _firestore.collection('users').doc(user.uid).collection('macros').doc('dailyMacros')
          .set(macros)
          .then((value) => print("Macros Saved"))
          .catchError((error) => print("Failed to save macros: $error"));
    }
  }
  void loadWorkoutSplitsFromFirestore() {
    User? user = _auth.currentUser;
    if (user != null) {
      _firestore.collection('users').doc(user.uid).collection('split').doc('workoutProgram')
          .snapshots().listen((snapshot) {
        if (snapshot.exists) {
          List<dynamic> splits = snapshot.data()?['splits'];
          setState(() {
            weeklySplits = List<WorkoutSplit>.from(splits.map((model) => WorkoutSplit.fromMap(model)));
          });
          db.saveWorkoutSplits(weeklySplits); // Update Hive with the latest data from Firestore
        }
      });
    }
  }
  void loadMacrosFromFirestore() {
    User? user = _auth.currentUser;
    if (user != null) {
      _firestore.collection('users').doc(user.uid).collection('macros').doc('dailyMacros')
          .snapshots().listen((snapshot) {
        if (snapshot.exists) {
          Map<String, dynamic> macros = snapshot.data()!;
          setState(() {
            _averageCals = macros['calories'] ?? "0";
            _averageProtein = macros['protein'] ?? "0";
            _averageCarbs = macros['carbs'] ?? "0";
            _averageFats = macros['fats'] ?? "0";
          });
          saveNutritionalInfo(_averageCals, _averageProtein, _averageCarbs, _averageFats);
        }
      });
    }
  }
  void initHive() async {
    if (!Hive.isAdapterRegistered(NutritionalInfoAdapter().typeId)) {
      Hive.registerAdapter(NutritionalInfoAdapter());
    }
    if (!Hive.isBoxOpen('nutritionBox')) {
      await Hive.openBox<NutritionalInfo>('nutritionBox');
    }
    loadNutritionalInfo();
  }
  void saveNutritionalInfo(String calories, String protein, String carbs, String fats) {
    final nutritionalInfo = NutritionalInfo(calories: calories, protein: protein, carbs: carbs, fats: fats);
    final box = Hive.box<NutritionalInfo>('nutritionBox');
    box.put('nutrition', nutritionalInfo);
    loadNutritionalInfo(); // Reload to update the UI
  }

  void loadNutritionalInfo() {
    final box = Hive.box<NutritionalInfo>('nutritionBox');
    NutritionalInfo? info = box.get('nutrition');

    if (info != null) {
      setState(() {
        _averageCals = info.calories ?? "0";
        _averageProtein = info.protein ?? "0";
        _averageCarbs = info.carbs ?? "0";
        _averageFats = info.fats ?? "0";
      });
    }
  }
  void _showEditNutritionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final TextEditingController calorieController = TextEditingController(text: _averageCals);
        final TextEditingController proteinController = TextEditingController(text: _averageProtein);
        final TextEditingController carbsController = TextEditingController(text: _averageCarbs);
        final TextEditingController fatsController = TextEditingController(text: _averageFats);

        return AlertDialog(
          title: Text('Edit Nutrition'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: calorieController,
                decoration: InputDecoration(labelText: 'Calories'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: proteinController,
                decoration: InputDecoration(labelText: 'Protein (g)'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: carbsController,
                decoration: InputDecoration(labelText: 'Carbs (g)'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: fatsController,
                decoration: InputDecoration(labelText: 'Fats (g)'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Save'),
              onPressed: () {
                saveNutritionalInfo(calorieController.text, proteinController.text,carbsController.text, fatsController.text );
                Navigator.of(context).pop();
                saveWorkoutSplitToFirestore();
                loadNutritionalInfo();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {

    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    final double tileHeight = screenHeight * 0.38; // Responsive height for both tiles
    final double tileWidth = screenWidth * 0.95; // Responsive width for both tiles
    int globalMaxTotalSets = weeklySplits.map((split) {
      return split.muscleGroups
          .map((mg) => mg.exercises.fold(0, (a, e) => a + e.sets))
          .fold(0, (a, b) => a > b ? a : b);
    }).fold(0, (a, b) => a > b ? a : b);

    return Scaffold(
      backgroundColor: Color.fromRGBO(20, 20, 20, 1),
      appBar: AppBar(
        title: const Padding(
          padding: EdgeInsets.only(top: 10.0),
          child: Text(
            'Strategy',
            style: TextStyle(fontSize: 29, color: Colors.white),
          ),
        ),
        backgroundColor: Color.fromRGBO(20, 20, 20, 1),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            width: double.infinity,
            color: Color.fromRGBO(20, 20, 20, 1),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: tileWidth,
                    // Remove fixed height to allow dynamic sizing
                    // height: tileHeight, // <-- Remove this line
                    margin: const EdgeInsets.only(bottom: 20), // Add margin for separation
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      color: Color.fromRGBO(31, 31, 31, 1),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        child: LayoutBuilder(
                          builder: (BuildContext context, BoxConstraints constraints) {
                            return Column(
                              mainAxisSize: MainAxisSize.min, // Let the tile size to its content
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                SizedBox(height: 2),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      "Workout Program",
                                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 10),
                                SizedBox(
                                  height: tileHeight * 0.5, // This can remain for the horizontal scroll, or you can use a fixed height if needed
                                  width: double.infinity,
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: daysOfWeek.map((day) => buildDaySplit(day, globalMaxTotalSets)).toList(),

                                    ),
                                  ),
                                ),
                                SizedBox(height: 20),
                                Divider(
                                  color: Colors.grey[500],
                                  height: 1,
                                  thickness: .75,
                                ),
                                SizedBox(height: 10),
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: [
                                      for (int i = 0; i < allMuscleGroups.length; i++)
                                        Row(
                                          children: [
                                            Container(
                                              width: 20,
                                              height: 20,
                                              decoration: BoxDecoration(
                                                color: Colors.primaries[i % Colors.primaries.length],
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              allMuscleGroups[i],
                                              style: TextStyle(color: Colors.white, fontSize: 14),
                                            ),
                                            SizedBox(width: 16),
                                          ],
                                        ),
                                    ],
                                  ),
                                ),
                                SizedBox(height:5),
                                ElevatedButton.icon(
                                  onPressed: () => _showEditSplitDialog(context),
                                  icon: Icon(Icons.edit, color: Colors.white,),
                                  label: Text("Edit Split"),
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: Colors.white, backgroundColor: Colors.grey[800],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Container(
                    width: tileWidth,
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(screenWidth * 0.05),
                      ),
                      color: Color.fromRGBO(31, 31, 31, 1),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.03,
                          vertical: screenHeight * 0.02,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  "Food Macros",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: screenWidth * 0.05,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.025),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Flexible(
                                  child: Column(
                                    children: [
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: RichText(
                                          text: TextSpan(
                                            children: [
                                              TextSpan(
                                                text: "${(_averageCals)} ",
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: screenWidth * 0.07,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              WidgetSpan(
                                                child: Icon(Icons.local_fire_department, color: Colors.white, size: screenWidth * 0.045),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          " Total Calories",
                                          style: TextStyle(color: Colors.grey, fontSize: screenWidth * 0.045),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: screenWidth * 0.025),
                                Flexible(
                                  child: Column(
                                    children: [
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: RichText(
                                          text: TextSpan(
                                            children: [
                                              TextSpan(
                                                text: "${(_averageProtein)} ",
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: screenWidth * 0.06,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              TextSpan(
                                                text: "g",
                                                style: TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: screenWidth * 0.028,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          " Protein",
                                          style: TextStyle(color: Colors.grey, fontSize: screenWidth * 0.045),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: screenWidth * 0.025),
                                Flexible(
                                  child: Column(
                                    children: [
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: RichText(
                                          text: TextSpan(
                                            children: [
                                              TextSpan(
                                                text: "${(_averageCarbs)} ",
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: screenWidth * 0.06,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              TextSpan(
                                                text: "g",
                                                style: TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: screenWidth * 0.028,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          " Carbs",
                                          style: TextStyle(color: Colors.grey, fontSize: screenWidth * 0.045),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: screenWidth * 0.025),
                                Flexible(
                                  child: Column(
                                    children: [
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: RichText(
                                          text: TextSpan(
                                            children: [
                                              TextSpan(
                                                text: "${(_averageFats)} ",
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: screenWidth * 0.06,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              TextSpan(
                                                text: "g",
                                                style: TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: screenWidth * 0.028,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          " Fats",
                                          style: TextStyle(color: Colors.grey, fontSize: screenWidth * 0.045),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: screenHeight * 0.012),
                            Divider(
                              color: Colors.grey[500],
                              height: 1,
                              thickness: .75,
                            ),
                            SizedBox(height: screenHeight * 0.012),
                            ElevatedButton.icon(
                              onPressed: () => _showEditNutritionDialog(),
                              icon: Icon(Icons.edit, color: Colors.white, size: screenWidth * 0.045),
                              label: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  "Edit Program",
                                  style: TextStyle(fontSize: screenWidth * 0.04),
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: Colors.grey[800],
                                padding: EdgeInsets.symmetric(
                                  horizontal: screenWidth * 0.04,
                                  vertical: screenHeight * 0.012,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(screenWidth * 0.02),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                // --- Weight Goal Tile ---
                Center(
                  child: Container(
                    width: tileWidth,
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(screenWidth * 0.05),
                      ),
                      color: Color.fromRGBO(31, 31, 31, 1),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.03,
                          vertical: screenHeight * 0.02,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  "Weight Goal",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: screenWidth * 0.05,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.025),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          "Goal Weight",
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: screenWidth * 0.04,
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: screenHeight * 0.005),
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          goalWeight != null ? "${goalWeight} lbs" : "-- lbs",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: screenWidth * 0.055,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: screenWidth * 0.04),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          "Goal Rate",
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: screenWidth * 0.04,
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: screenHeight * 0.005),
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          goalRate != null ? "${goalRate!.toStringAsFixed(2)} lbs/week" : "-- lbs/week",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: screenWidth * 0.055,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: screenHeight * 0.025),
                            Divider(color: Colors.grey[500], height: 1, thickness: .75),
                            SizedBox(height: screenHeight * 0.012),
                            Center(
                              child: ElevatedButton.icon(
                                onPressed: () => _showEditGoalDialog(),
                                icon: Icon(Icons.edit, color: Colors.white, size: screenWidth * 0.045),
                                label: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    "Edit Goal",
                                    style: TextStyle(fontSize: screenWidth * 0.04),
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor: Colors.grey[800],
                                  padding: EdgeInsets.symmetric(
                                    horizontal: screenWidth * 0.04,
                                    vertical: screenHeight * 0.012,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(screenWidth * 0.02),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
  void _saveAllSplits() {
    List<WorkoutSplit> newWeeklySplits = [];

    daySplitData.forEach((day, exercises) {
      List<MuscleGroupSplit> muscleGroupSplits = exercises.entries.map((entry) {
        return MuscleGroupSplit(
          muscleGroupName: entry.key,
          exercises: entry.value,
        );
      }).toList();

      newWeeklySplits.add(WorkoutSplit(
        day: day,
        muscleGroups: muscleGroupSplits,
      ));
    });

    setState(() {
      weeklySplits = newWeeklySplits;
      db.saveWorkoutSplits(weeklySplits);
    });
  }

  void _showEditSplitDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (_, controller) {
            return StatefulBuilder(
              builder: (context, setState) {
                return Container(
                  decoration: BoxDecoration(
                    color: Color.fromRGBO(20, 20, 20, 1),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
                  ),
                  child: SafeArea(
                    child: SingleChildScrollView(
                      controller: _modalScrollController,
                      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                      child: Column(
                        children: [
                          // Handle bar
                          Container(
                            height: 5,
                            width: 50,
                            margin: EdgeInsets.only(top: 12, bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.grey[700],
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          // Header
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Edit Workout Split",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => Navigator.pop(context),
                                  icon: Icon(Icons.close, color: Colors.white, size: 24),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 20),
                          // Day selector
                          Container(
                            margin: EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                'M', 'T', 'W', 'T', 'F', 'S', 'S'
                              ].asMap().entries.map((entry) {
                                final index = entry.key;
                                final dayAbbr = entry.value;
                                final day = daysOfWeek[index];
                                final isSelected = selectedDay == day;
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      selectedDay = day;
                                      selectedMuscleGroups = daySplitData[day]?.keys.toList() ?? [];
                                    });
                                  },
                                  child: AnimatedContainer(
                                    duration: Duration(milliseconds: 200),
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: isSelected ? Colors.blue : Colors.grey[800],
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: isSelected ? [
                                        BoxShadow(
                                          color: Colors.blue.withOpacity(0.3),
                                          blurRadius: 6,
                                          offset: Offset(0, 2),
                                        )
                                      ] : null,
                                    ),
                                    child: Center(
                                      child: Text(
                                        dayAbbr,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          SizedBox(height: 20),
                          // Muscle groups section (no Expanded)
                          Column(
                            children: [
                              // Muscle group selector
                              Container(
                                margin: EdgeInsets.symmetric(horizontal: 20),
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[900],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          "Muscle Groups",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          "${selectedMuscleGroups.length}/7",
                                          style: TextStyle(
                                            color: Colors.grey[400],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 8),
                                    // Compact muscle group grid
                                    Wrap(
                                      spacing: 6.0,
                                      runSpacing: 6.0,
                                      children: allMuscleGroups.map((item) {
                                        final isSelected = selectedMuscleGroups.contains(item);
                                        return GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              if (isSelected) {
                                                selectedMuscleGroups.remove(item);
                                                daySplitData[selectedDay]!.remove(item);
                                              } else {
                                                selectedMuscleGroups.add(item);
                                                daySplitData[selectedDay]![item] ??= [];
                                              }
                                            });
                                          },
                                          child: AnimatedContainer(
                                            duration: Duration(milliseconds: 200),
                                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: isSelected ? Colors.blue : Colors.grey[800],
                                              borderRadius: BorderRadius.circular(16),
                                              border: isSelected ? Border.all(color: Colors.blue[300]!, width: 1) : null,
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                if (isSelected) ...[
                                                  Icon(
                                                    Icons.check_circle,
                                                    color: Colors.white,
                                                    size: 12,
                                                  ),
                                                  SizedBox(width: 4),
                                                ],
                                                Text(
                                                  item,
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 20),
                              // Muscle group tabs and content
                              if (selectedMuscleGroups.isNotEmpty) ...[
                                // Tab indicators
                                Container(
                                  margin: EdgeInsets.symmetric(horizontal: 20),
                                  child: Row(
                                    children: selectedMuscleGroups.asMap().entries.map((entry) {
                                      final index = entry.key;
                                      final muscleGroup = entry.value;
                                      final isSelected = index == _currentMuscleGroupIndex;
                                      return Expanded(
                                        child: GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _currentMuscleGroupIndex = index;
                                            });
                                            _muscleGroupPageController.animateToPage(
                                              index,
                                              duration: Duration(milliseconds: 300),
                                              curve: Curves.easeInOut,
                                            );
                                          },
                                          child: Container(
                                            height: 32,
                                            margin: EdgeInsets.symmetric(horizontal: 1),
                                            decoration: BoxDecoration(
                                              color: isSelected ? Colors.blue : Colors.grey[800],
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Center(
                                              child: Text(
                                                muscleGroup,
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                                  fontSize: 10,
                                                ),
                                                textAlign: TextAlign.center,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                                SizedBox(height: 16),
                                // Swipeable muscle group content
                                SizedBox(
                                  height: 400, // Fixed height for the PageView
                                  child: PageView.builder(
                                    controller: _muscleGroupPageController,
                                    onPageChanged: (index) {
                                      setState(() {
                                        _currentMuscleGroupIndex = index;
                                      });
                                    },
                                    itemCount: selectedMuscleGroups.length,
                                    itemBuilder: (context, index) {
                                      final muscleGroup = selectedMuscleGroups[index];
                                      return _buildModernMuscleGroupSection(muscleGroup, setState, controller);
                                    },
                                  ),
                                ),
                              ] else ...[
                                // Empty state
                                Container(
                                  height: 200,
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.fitness_center,
                                          color: Colors.grey[600],
                                          size: 64,
                                        ),
                                        SizedBox(height: 16),
                                        Text(
                                          "Select muscle groups above",
                                          style: TextStyle(
                                            color: Colors.grey[400],
                                            fontSize: 16,
                                          ),
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          "Then swipe between them to add exercises",
                                          style: TextStyle(
                                            color: Colors.grey[500],
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          // Save button
                          Container(
                            padding: EdgeInsets.all(20),
                            child: Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      _saveAllSplits();
                                      saveWorkoutSplitToFirestore();
                                      Navigator.pop(context);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Text(
                                      'Save Split',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget buildDaySplit(String day, int globalMaxTotalSets) {
    WorkoutSplit? split = weeklySplits.firstWhereOrNull((s) => s.day == day);
    List<int> muscleWorkloads = List.generate(allMuscleGroups.length, (index) => 0); // Initialize with zeros

    if (split != null) {
      for (var muscleGroup in split.muscleGroups) {
        int index = allMuscleGroups.indexOf(muscleGroup.muscleGroupName);
        if (index != -1) {
          muscleWorkloads[index] = muscleGroup.exercises.fold(0, (total, curr) => total + curr.sets);
        }
      }
    }
    // Assuming a simple mapping of days to single character labels
    String dayLabel = day.substring(0, 1); // Simplified, assumes first letter is adequate
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0), // Control horizontal spacing here if needed
          child: WeeklySplitTile(
            muscleWorkloads: muscleWorkloads,
            globalMaxTotalSets: globalMaxTotalSets,
          ),
        ),
        SizedBox(height: 4),
        Text(dayLabel, style: TextStyle(color: Colors.white, fontSize: 12)) // Display day label beneath each tile
      ],
    );
  }

  Widget _buildModernMuscleGroupSection(String muscleGroup, StateSetter setState, ScrollController controller) {
    // Ensure there's an entry for this muscle group in the map
    selectedExercises.putIfAbsent(muscleGroup, () => null);

    if (!daySplitData[selectedDay]!.containsKey(muscleGroup)) {
      return Container(); // Return empty if deleted
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with muscle group name and delete button
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[850],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.fitness_center,
                        color: Colors.blue[400],
                        size: 16,
                      ),
                      SizedBox(width: 8),
                      Text(
                        muscleGroup,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 8),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "${daySplitData[selectedDay]![muscleGroup]!.length} exercises",
                          style: TextStyle(
                            color: Colors.blue[300],
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: Colors.red[400], size: 18),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          backgroundColor: Colors.grey[900],
                          title: Text(
                            "Remove $muscleGroup?",
                            style: TextStyle(color: Colors.white),
                          ),
                          content: Text(
                            "This will remove all exercises for this muscle group.",
                            style: TextStyle(color: Colors.grey[300]),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text('Cancel', style: TextStyle(color: Colors.grey[400])),
                            ),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  daySplitData[selectedDay]!.remove(muscleGroup);
                                  selectedMuscleGroups.remove(muscleGroup);
                                  selectedExercises.remove(muscleGroup);
                                });
                                Navigator.of(context).pop();
                              },
                              child: Text('Remove', style: TextStyle(color: Colors.red[400])),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            SizedBox(height: 16),

            // Existing exercises list
            if (daySplitData[selectedDay]![muscleGroup]!.isNotEmpty) ...[
              ...daySplitData[selectedDay]![muscleGroup]!.map((exercise) => Dismissible(
                key: ValueKey(exercise.name + exercise.sets.toString() + exercise.reps.toString() + exercise.weight.toString()),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.red[400],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) {
                  setState(() => daySplitData[selectedDay]![muscleGroup]!.remove(exercise));
                },
                child: Container(
                  margin: EdgeInsets.only(bottom: 8),
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[850],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              exercise.name,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '${exercise.sets} sets ◊ ${exercise.reps} reps @ ${exercise.weight} lbs',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.fitness_center, color: Colors.blue[400], size: 20),
                    ],
                  ),
                ),
              )).toList(),

              SizedBox(height: 16),
            ],

            // Add new exercise section
            _buildExerciseInputCard(muscleGroup, setState, controller),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseInputCard(String muscleGroup, StateSetter setState, ScrollController controller) {
    // Get or create persistent controllers for this muscle group
    _setsControllers[muscleGroup] ??= TextEditingController();
    _repsControllers[muscleGroup] ??= TextEditingController();
    _weightControllers[muscleGroup] ??= TextEditingController();
    // Add focus nodes and attach listeners
    _setsFocusNodes[muscleGroup] ??= FocusNode();
    _repsFocusNodes[muscleGroup] ??= FocusNode();
    _weightFocusNodes[muscleGroup] ??= FocusNode();
    void scrollToBottomOnFocus(FocusNode node) {
      if (node.hasFocus) {
        Future.delayed(Duration(milliseconds: 300), () {
          if (_modalScrollController.hasClients) {
            _modalScrollController.animateTo(
              _modalScrollController.position.maxScrollExtent,
              duration: Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
        });
      }
    }
    _setsFocusNodes[muscleGroup]!.removeListener(() {}); // Remove any previous
    _repsFocusNodes[muscleGroup]!.removeListener(() {});
    _weightFocusNodes[muscleGroup]!.removeListener(() {});
    _setsFocusNodes[muscleGroup]!.addListener(() => scrollToBottomOnFocus(_setsFocusNodes[muscleGroup]!));
    _repsFocusNodes[muscleGroup]!.addListener(() => scrollToBottomOnFocus(_repsFocusNodes[muscleGroup]!));
    _weightFocusNodes[muscleGroup]!.addListener(() => scrollToBottomOnFocus(_weightFocusNodes[muscleGroup]!));
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[700]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Exercise dropdown
          Container(
            padding: EdgeInsets.all(12),
            child: DropdownSearch<SingleExercise>(
              popupProps: PopupProps.menu(
                showSelectedItems: true,
                showSearchBox: true,
                constraints: BoxConstraints(maxHeight: 300),
                containerBuilder: (context, popupWidget) => Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: popupWidget,
                ),
                searchFieldProps: TextFieldProps(
                  decoration: InputDecoration(
                    hintText: "Search exercises...",
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                    filled: true,
                    fillColor: Colors.grey[900],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: TextStyle(color: Colors.white),
                ),
                itemBuilder: (context, item, isSelected) => Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.grey[900],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        item.muscleGroup,
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              items: exerciseList,
              selectedItem: selectedExercises[muscleGroup],
              onChanged: (SingleExercise? selected) {
                setState(() {
                  selectedExercises[muscleGroup] = selected;
                });
              },
              dropdownDecoratorProps: DropDownDecoratorProps(
                dropdownSearchDecoration: InputDecoration(
                  labelText: 'Select Exercise',
                  labelStyle: TextStyle(color: Colors.grey[400]),
                  filled: true,
                  fillColor: Colors.grey[900],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[700]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.blue, width: 2),
                  ),
                ),
                baseStyle: TextStyle(color: Colors.white, fontSize: 16),
              ),
              itemAsString: (item) => item.name,
              compareFn: (a, b) => a.name == b.name && a.muscleGroup == b.muscleGroup,
              filterFn: (SingleExercise item, String filter) {
                final query = filter.toLowerCase();
                return item.name.toLowerCase().contains(query) ||
                    item.muscleGroup.toLowerCase().contains(query);
              },
            ),
          ),

          // Sets, Reps, Weight inputs in a horizontal layout
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: _buildModernTextField(
                    'Sets',
                    _setsControllers[muscleGroup]!,
                    focusNode: _setsFocusNodes[muscleGroup]!,
                    keyboardType: TextInputType.number,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: _buildModernTextField(
                    'Reps',
                    _repsControllers[muscleGroup]!,
                    focusNode: _repsFocusNodes[muscleGroup]!,
                    keyboardType: TextInputType.number,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: _buildModernTextField(
                    'Weight',
                    _weightControllers[muscleGroup]!,
                    focusNode: _weightFocusNodes[muscleGroup]!,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
          ),

          // Add button
          Container(
            padding: EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  final selected = selectedExercises[muscleGroup];
                  if (selected != null &&
                      _setsControllers[muscleGroup]!.text.isNotEmpty &&
                      _repsControllers[muscleGroup]!.text.isNotEmpty &&
                      _weightControllers[muscleGroup]!.text.isNotEmpty) {
                    final int sets = int.tryParse(_setsControllers[muscleGroup]!.text) ?? 0;
                    final int reps = int.tryParse(_repsControllers[muscleGroup]!.text) ?? 0;
                    final double weight = double.tryParse(_weightControllers[muscleGroup]!.text) ?? 0;

                    if (sets > 0 && reps > 0 && weight > 0) {
                      setState(() {
                        daySplitData[selectedDay]![muscleGroup]!.add(
                          ExerciseDetail(name: selected.name, sets: sets, reps: reps, weight: weight),
                        );

                        // Clear input
                        _setsControllers[muscleGroup]!.clear();
                        _repsControllers[muscleGroup]!.clear();
                        _weightControllers[muscleGroup]!.clear();
                        selectedExercises[muscleGroup] = null;
                      });
                    }
                  }
                },
                icon: Icon(Icons.add, color: Colors.white, size: 18),
                label: Text(
                  'Add Exercise',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernTextField(String label, TextEditingController controller, {
    TextInputType? keyboardType,
    FocusNode? focusNode,
  }) {
    return Container(
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: keyboardType,
        autofocus: false,
        enableInteractiveSelection: true,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
          filled: true,
          fillColor: Colors.grey[900],
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey[700]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.blue, width: 2),
          ),
        ),
        style: TextStyle(color: Colors.white, fontSize: 16),
      ),
    );
  }

  void _saveSplit(String day, List<String> muscleGroups,
      Map<String, List<ExerciseDetail>> exercises) {
    setState(() {
      daySplitData[day] = exercises;
      final muscleGroupSplits = muscleGroups.map((mg) {
        return MuscleGroupSplit(
          muscleGroupName: mg,
          exercises: exercises[mg] ?? [],
        );
      }).toList();
      final existingSplitIndex =
      weeklySplits.indexWhere((split) => split.day == day);
      if (existingSplitIndex != -1) {
        weeklySplits[existingSplitIndex] = WorkoutSplit(
          day: day,
          muscleGroups: muscleGroupSplits,
        );
      } else {
        weeklySplits.add(WorkoutSplit(
          day: day,
          muscleGroups: muscleGroupSplits,
        ));
      }
      db.saveWorkoutSplits(weeklySplits);
    });
  }

  @override
  void dispose() {
    // Dispose all text field controllers
    _setsControllers.values.forEach((controller) => controller.dispose());
    _repsControllers.values.forEach((controller) => controller.dispose());
    _weightControllers.values.forEach((controller) => controller.dispose());
    _setsFocusNodes.values.forEach((node) => node.dispose());
    _repsFocusNodes.values.forEach((node) => node.dispose());
    _weightFocusNodes.values.forEach((node) => node.dispose());
    _modalScrollController.dispose();
    _muscleGroupPageController.dispose();
    super.dispose();
  }

  void _loadWeightGoalData() async {
    User? user = _auth.currentUser;
    if (user == null) return;
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final data = userDoc.data() ?? {};

    int? loadedMaintenanceCalories;
    int? loadedGoalWeight;
    double? loadedGoalRate;
    double? loadedCurrentWeight;

    // Parse maintenanceCalories
    var mc = data['maintenanceCalories'];
    if (mc is int) {
      loadedMaintenanceCalories = mc;
    } else if (mc is String) {
      loadedMaintenanceCalories = int.tryParse(mc);
    }

    // Parse goalWeight
    var gw = data['goalWeight'];
    if (gw is int) {
      loadedGoalWeight = gw;
    } else if (gw is String) {
      loadedGoalWeight = int.tryParse(gw);
    }

    // Parse goalRate
    var gr = data['goalRate'];
    if (gr is double) {
      loadedGoalRate = gr;
    } else if (gr is int) {
      loadedGoalRate = gr.toDouble();
    } else if (gr is String) {
      loadedGoalRate = double.tryParse(gr);
    }

    // Fetch current weight from Firestore weightLogs (most recent)
    double? firestoreWeight;
    try {
      final logsSnap = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('weightLogs')
          .orderBy('date', descending: true)
          .limit(1)
          .get();
      if (logsSnap.docs.isNotEmpty) {
        final log = logsSnap.docs.first.data();
        if (log['weight'] is num) firestoreWeight = (log['weight'] as num).toDouble();
        else if (log['weight'] is String) firestoreWeight = double.tryParse(log['weight']);
      }
    } catch (_) {}
    // Fallback to weightPounds field
    if (firestoreWeight == null) {
      var wp = data['weightPounds'];
      if (wp is int) firestoreWeight = wp.toDouble();
      else if (wp is String) firestoreWeight = double.tryParse(wp);
    }

    setState(() {
      maintenanceCalories = loadedMaintenanceCalories;
      goalWeight = loadedGoalWeight ?? firestoreWeight?.round();
      goalRate = loadedGoalRate ?? -1.0;
      currentWeight = firestoreWeight;
    });
    _recalculateGoalFields();
  }

  void _saveWeightGoalData(int newGoalWeight, double newGoalRate) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    // Calculate the new calorie budget
    int? newCalorieBudget;
    if (maintenanceCalories != null) {
      newCalorieBudget = (maintenanceCalories! + (newGoalRate * 500)).round();
    }

    // Update goal weight and rate
    await _firestore.collection('users').doc(user.uid).set({
      'goalWeight': newGoalWeight,
      'goalRate': newGoalRate,
    }, SetOptions(merge: true));

    // Update macros in Firebase if calorie budget was calculated
    if (newCalorieBudget != null) {
      await _firestore.collection('users').doc(user.uid).collection('macros').doc('dailyMacros').set({
        'calories': newCalorieBudget.toString(),
        'protein': _averageProtein,
        'carbs': _averageCarbs,
        'fats': _averageFats,
      }, SetOptions(merge: true));

      // Update local state
      setState(() {
        _averageCals = newCalorieBudget.toString();
        goalWeight = newGoalWeight;
        goalRate = newGoalRate;
      });
    } else {
      setState(() {
        goalWeight = newGoalWeight;
        goalRate = newGoalRate;
      });
    }

    _recalculateGoalFields();
  }

  void _recalculateGoalFields({int? customGoalWeight, double? customGoalRate}) {
    final int? mCals = maintenanceCalories;
    final double? cWeight = currentWeight;
    final int? tWeight = customGoalWeight ?? goalWeight;
    final double? gRate = customGoalRate ?? goalRate;
    if (mCals == null || gRate == null || cWeight == null || tWeight == null) return;
    // Fix calculation: calories = maintenanceCalories + (goalRate * 500)
    calculatedCalories = (mCals + (gRate * 500)).round();
    // Projected end date
    double weightDifference = tWeight - cWeight;
    if (gRate.abs() > 0.01) {
      double weeksNeeded = weightDifference / gRate;
      if (weeksNeeded.isFinite && weeksNeeded.abs() < 1000) {
        final endDate = DateTime.now().add(Duration(days: (weeksNeeded * 7).round()));
        projectedEndDate = DateFormat('MMM d, yyyy').format(endDate);
      } else {
        projectedEndDate = '-';
      }
    } else {
      projectedEndDate = '-';
    }
  }

  void _showEditGoalDialog() {
    int tempGoalWeight = goalWeight ?? currentWeight?.round() ?? 150;
    double tempGoalRate = goalRate ?? -1.0;
    _recalculateGoalFields(customGoalWeight: tempGoalWeight, customGoalRate: tempGoalRate);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            void updateFields() {
              setModalState(() {
                _recalculateGoalFields(customGoalWeight: tempGoalWeight, customGoalRate: tempGoalRate);
              });
            }

            // Calculate initial values for display
            int? tempCalculatedCalories;
            String? tempProjectedEndDate;

            void calculateTempValues() {
              final int? mCals = maintenanceCalories;
              final double? cWeight = currentWeight;
              if (mCals == null || tempGoalRate == null || cWeight == null || tempGoalWeight == null) return;

              tempCalculatedCalories = (mCals + (tempGoalRate * 500)).round();

              double weightDifference = tempGoalWeight - cWeight;
              if (tempGoalRate.abs() > 0.01) {
                double weeksNeeded = weightDifference / tempGoalRate;
                if (weeksNeeded.isFinite && weeksNeeded.abs() < 1000) {
                  final endDate = DateTime.now().add(Duration(days: (weeksNeeded * 7).round()));
                  tempProjectedEndDate = DateFormat('MMM d, yyyy').format(endDate);
                } else {
                  tempProjectedEndDate = '-';
                }
              } else {
                tempProjectedEndDate = '-';
              }
            }

            // Initialize temp values
            calculateTempValues();
            String rateLabel;
            double absRate = tempGoalRate.abs();
            if (absRate <= 0.4) {
              rateLabel = 'Slower';
            } else if (absRate <= 2.3) {
              rateLabel = 'Standard';
            } else {
              rateLabel = 'Faster (use caution)';
            }
            bool tooLowCalories = maintenanceCalories != null && calculatedCalories != null && (maintenanceCalories! - calculatedCalories!) > 1000;
            return Container(
              decoration: BoxDecoration(
                color: Color.fromRGBO(31, 31, 31, 1),
                borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
              ),
              padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Edit Goal', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Color.fromRGBO(20, 20, 20, 1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${tempCalculatedCalories ?? '--'} kcal', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)),
                              SizedBox(height: 2),
                              Text('initial daily budget', style: TextStyle(color: Colors.grey[400], fontSize: 14)),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Color.fromRGBO(20, 20, 20, 1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(tempProjectedEndDate ?? '--', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)),
                              SizedBox(height: 2),
                              Text('projected end date', style: TextStyle(color: Colors.grey[400], fontSize: 14)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),
                  Text('What is your target weight?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                  SizedBox(height: 8),
                  Center(
                    child: Text('${tempGoalWeight} lbs', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)),
                  ),
                  Slider(
                    value: tempGoalWeight.toDouble(),
                    min: (currentWeight ?? 150) - 50,
                    max: (currentWeight ?? 150) + 50,
                    divisions: 100,
                    label: tempGoalWeight.toString(),
                    onChanged: (v) {
                      setModalState(() {
                        tempGoalWeight = v.round();
                        calculateTempValues();
                      });
                    },
                  ),
                  SizedBox(height: 16),
                  Text('What is your target goal rate?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: rateLabel == 'Faster (use caution)' ? Colors.red[700] : Colors.green[700],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(rateLabel, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Center(
                    child: Text('${tempGoalRate.toStringAsFixed(2)} lbs/week', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)),
                  ),
                  Slider(
                    value: tempGoalRate,
                    min: -3.0,
                    max: 3.0,
                    divisions: 60,
                    label: tempGoalRate.toStringAsFixed(2),
                    onChanged: (v) {
                      setModalState(() {
                        tempGoalRate = double.parse(v.toStringAsFixed(2));
                        calculateTempValues();
                      });
                    },
                  ),
                  SizedBox(height: 16),
                  if (tooLowCalories)
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[900],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning, color: Colors.yellow, size: 24),
                          SizedBox(width: 8),
                          Expanded(child: Text('Calorie target is more than 1000 kcal below maintenance. This is not recommended.', style: TextStyle(color: Colors.white))),
                        ],
                      ),
                    ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: tooLowCalories ? null : () {
                            _saveWeightGoalData(tempGoalWeight, tempGoalRate);
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: tooLowCalories ? Colors.grey[700] : Colors.blue,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text('Save', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
