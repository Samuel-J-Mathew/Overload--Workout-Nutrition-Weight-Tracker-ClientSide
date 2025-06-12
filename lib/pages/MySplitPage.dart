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
import '../data/exercise_list.dart'; // Import the exercise_list.dart file\
import 'package:collection/collection.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
class MySplitPage extends StatefulWidget {
  const MySplitPage({super.key});

  @override
  _MySplitPageState createState() => _MySplitPageState();
}

class _MySplitPageState extends State<MySplitPage>  {
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
    'Abs'
  ];

  Map<String, Map<String, List<ExerciseDetail>>> daySplitData = {};
  List<String> selectedMuscleGroups = [];

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
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Strategy',
          style: TextStyle(fontSize: 29, color: Colors.white),
        ),
        backgroundColor: Color.fromRGBO(20, 20, 20, 1),
      ),
      body: Column(
        children: [
          Container(
            color: Color.fromRGBO(20, 20, 20, 1),
            height: 400,
            child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                color: Color.fromRGBO(31, 31, 31, 1),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 19.0),
                  child: LayoutBuilder( // Use LayoutBuilder to get the available space for centering content
                    builder: (BuildContext context, BoxConstraints constraints) {
                      return SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight, // Ensure the container takes at least the full height of the viewport
                          ),
                          child: IntrinsicHeight( // Ensures the content can size itself properly within the available space
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center, // Center vertically
                              crossAxisAlignment: CrossAxisAlignment.center, // Center horizontally
                              children: [
                                SizedBox(height: 2),
                                Align(
                                  alignment: Alignment.centerLeft, // Aligns the child to the left of the available space.
                                  child: Text("Workout Program", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                                ),

                                SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: daysOfWeek.map((day) => buildDaySplit(day)).toList(),
                                ),
                                SizedBox(height: 20),
                                Divider(
                                  color: Colors.grey[500],
                                  height: 1,
                                  // Set minimal height to reduce space
                                  thickness: .75, // Minimal visual thickness
                                ),
                                SizedBox(height: 10),
                                // Horizontal Key for muscle groups
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
                                                color: Colors.primaries[i % Colors.primaries.length], // Color for the muscle group
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              allMuscleGroups[i],
                                              style: TextStyle(color: Colors.white, fontSize: 14),
                                            ),
                                            SizedBox(width: 16), // Space between each key item
                                          ],
                                        ),
                                    ],
                                  ),
                                ),
                                SizedBox(height:5),
                                ElevatedButton.icon(
                                  onPressed: () => _showEditSplitDialog(context),
                                  icon: Icon(Icons.edit, color: Colors.white,),  // Icon for editing
                                  label: Text("Edit Split"),  // Text label
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: Colors.white, backgroundColor: Colors.grey[800],  // Text and icon color
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                )

            ),


          ),
          Container(

            color: Color.fromRGBO(20, 20, 20, 1),
            width: MediaQuery.of(context).size.width * 1, // 90% of screen width
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              color: Color.fromRGBO(31, 31, 31, 1),
              child: Padding(
                padding:  const EdgeInsets.symmetric(horizontal: 19.0, vertical: 18),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft, // Aligns the child to the left of the available space.
                      child: Text("Food Macros", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                    ),
                    SizedBox(height: 20,),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Column(

                          children: [

                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: "${(_averageCals)} ", // Step count
                                    style: TextStyle(
                                      color: Colors.white, // Color for the step count
                                      fontSize: 28, // Larger font size for the step count
                                      fontWeight: FontWeight.bold, // Optional: Make it bold
                                    ),
                                  ),
                                  WidgetSpan(
                                    child: Icon(Icons.local_fire_department, color: Colors.white, size: 18), // Fire icon with adjustable color and size
                                  ),
                                ],
                              ),
                            ),
                            Text(" Total Calories", style: TextStyle(color: Colors.grey, fontSize: 18)),
                          ],
                        ),
                        SizedBox(width: 20,),
                        Column(
                          children: [
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: "${(_averageProtein)} ", // Step count
                                    style: TextStyle(
                                      color: Colors.white, // Color for the step count
                                      fontSize: 24, // Larger font size for the step count
                                      fontWeight: FontWeight.bold, // Optional: Make it bold
                                    ),
                                  ),
                                  TextSpan(
                                    text: "g", // "steps" label
                                    style: TextStyle(
                                      color: Colors.grey, // Different color for the "steps" text
                                      fontSize: 11, // Smaller font size for the "steps" text
                                    ),
                                  ),
                                ],
                              ),

                            ),
                            Text(" Protein", style: TextStyle(color: Colors.grey, fontSize: 18)),
                          ],

                        ),
                        SizedBox(width: 20,),
                        Column(
                          children: [
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: "${(_averageCarbs)} ", // Step count
                                    style: TextStyle(
                                      color: Colors.white, // Color for the step count
                                      fontSize: 24, // Larger font size for the step count
                                      fontWeight: FontWeight.bold, // Optional: Make it bold
                                    ),
                                  ),
                                  TextSpan(
                                    text: "g", // "steps" label
                                    style: TextStyle(
                                      color: Colors.grey, // Different color for the "steps" text
                                      fontSize: 11, // Smaller font size for the "steps" text
                                    ),
                                  ),
                                ],
                              ),

                            ),
                            Text(" Carbs", style: TextStyle(color: Colors.grey, fontSize: 18)),
                          ],

                        ),
                        SizedBox(width: 20,),
                        Column(
                          children: [
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: "${(_averageFats)} ", // Step count
                                    style: TextStyle(
                                      color: Colors.white, // Color for the step count
                                      fontSize: 24, // Larger font size for the step count
                                      fontWeight: FontWeight.bold, // Optional: Make it bold
                                    ),
                                  ),
                                  TextSpan(
                                    text: "g", // "steps" label
                                    style: TextStyle(
                                      color: Colors.grey, // Different color for the "steps" text
                                      fontSize: 11, // Smaller font size for the "steps" text
                                    ),
                                  ),
                                ],
                              ),

                            ),
                            Text(" Fats", style: TextStyle(color: Colors.grey, fontSize: 18)),
                          ],

                        )

                      ],

                    ),
                    SizedBox(height: 10),
                    Divider(
                      color: Colors.grey[500],
                      height: 1, // Set minimal height to reduce space
                      thickness: .75, // Minimal visual thickness
                    ),
                    SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: () => _showEditNutritionDialog(),
                      icon: Icon(Icons.edit, color: Colors.white,),  // Icon for editing
                      label: Text("Edit Program"),  // Text label
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white, backgroundColor: Colors.grey[800],  // Text and icon color
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              color: Color.fromRGBO(20, 20, 20, 1),
              height: 79,
            ),
          ),
        ],

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
      backgroundColor: Colors.grey[900],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          builder: (_, controller) {
            return StatefulBuilder(
              builder: (context, setState) {
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Column(
                    children: [
                      Container(
                        height: 5,
                        width: 50,
                        margin: EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey[700],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      Text("Edit Split", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                      SizedBox(height: 10),
                      Expanded(
                        child: SingleChildScrollView(
                          controller: controller,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 8.0,
                                children: daysOfWeek.map((day) {
                                  return ChoiceChip(
                                    label: Text(day),
                                    selected: selectedDay == day,
                                    onSelected: (bool selected) {
                                      setState(() {
                                        selectedDay = day;
                                        selectedMuscleGroups = daySplitData[day]?.keys.toList() ?? [];
                                      });
                                    },
                                    selectedColor: Colors.blue,
                                    labelStyle: TextStyle(color: Colors.white),
                                    backgroundColor: Colors.grey[800],
                                  );
                                }).toList(),
                              ),
                              SizedBox(height: 10),
                              Text("Muscle Groups", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              Wrap(
                                spacing: 10.0,
                                children: allMuscleGroups.map((item) {
                                  final isSelected = selectedMuscleGroups.contains(item);
                                  return FilterChip(
                                    label: Text(item),
                                    selected: isSelected,
                                    onSelected: (bool value) {
                                      setState(() {
                                        if (value) {
                                          selectedMuscleGroups.add(item);
                                          daySplitData[selectedDay]![item] ??= [];
                                        } else {
                                          selectedMuscleGroups.remove(item);
                                          daySplitData[selectedDay]!.remove(item);
                                        }
                                      });
                                    },
                                    selectedColor: Colors.blue,
                                    backgroundColor: Colors.grey[800],
                                    labelStyle: TextStyle(color: Colors.white),
                                  );
                                }).toList(),
                              ),
                              SizedBox(height: 20),
                              ...selectedMuscleGroups.map((mg) => _buildMuscleGroupSection(mg, setState)).toList(),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('Cancel', style: TextStyle(color: Colors.white)),
                          ),
                          SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              _saveAllSplits();
                              saveWorkoutSplitToFirestore();
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                            child: Text('Save Split'),
                          )
                        ],
                      )
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget buildDaySplit(String day) {
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
          child: WeeklySplitTile(muscleWorkloads: muscleWorkloads),
        ),
        SizedBox(height: 4),
        Text(dayLabel, style: TextStyle(color: Colors.white, fontSize: 12)) // Display day label beneath each tile
      ],
    );
  }

  Widget _buildMuscleGroupSection(String muscleGroup, StateSetter setState) {
    // Controllers for the text fields
    final TextEditingController setsController = TextEditingController();
    final TextEditingController repsController = TextEditingController();
    final TextEditingController weightController = TextEditingController();
    SingleExercise? selectedExercise;

    // Check if the muscle group still exists in the data structure
    if (!daySplitData[selectedDay]!.containsKey(muscleGroup)) {
      return Container();  // Return an empty container if the muscle group has been deleted
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                muscleGroup,
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
              IconButton(
                icon: Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text("Confirm Deletion"),
                        content: Text("Are you sure you want to delete the muscle group '$muscleGroup'?"),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text("Cancel"),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                daySplitData[selectedDay]!.remove(muscleGroup);
                                selectedMuscleGroups.remove(muscleGroup);
                                Navigator.of(context).pop();
                              });
                            },
                            child: const Text("Delete"),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 8.0),
          ...daySplitData[selectedDay]![muscleGroup]!.map((exercise) {
            return Dismissible(
              key: ValueKey(exercise.name + exercise.sets.toString() + exercise.reps.toString() + exercise.weight.toString()),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: EdgeInsets.symmetric(horizontal: 20),
                color: Colors.red,
                child: Icon(Icons.delete, color: Colors.white),
              ),
              onDismissed: (_) {
                setState(() {
                  daySplitData[selectedDay]![muscleGroup]!.remove(exercise);
                });
              },
              child: Column(
                children: [
                  ListTile(
                    title: Text(
                      exercise.name,
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      '${exercise.sets} sets x ${exercise.reps} reps at ${exercise.weight} lbs',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                  Divider(
                    color: Colors.grey[700],
                    thickness: 0.8,
                    height: 1,
                  ),
                ],
              ),
            );


          }).toList(),
          const SizedBox(height: 8.0),
          DropdownSearch<SingleExercise>(
            popupProps: PopupProps.menu(
              showSelectedItems: true,
              showSearchBox: true, // Enables search
              itemBuilder: (context, item, isSelected) => ListTile(
                title: Text(item.name),
                subtitle: Text(item.muscleGroup),
              ),
            ),
            items: exerciseList,
            dropdownDecoratorProps: DropDownDecoratorProps(
              dropdownSearchDecoration: InputDecoration(
                labelText: 'Add an Exercise',
                labelStyle: TextStyle(color: Colors.white), // This is for the label
                filled: true, // Optional: adds a fill color to the dropdown
                fillColor: Colors.grey[900], // Optional: sets the fill color
                hintStyle: TextStyle(color: Colors.grey), // Optional: style for hint text if you have it
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10), // Optional: border styling
                  borderSide: BorderSide(color: Colors.white),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade800),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.blue),
                ),
              ),
              baseStyle: TextStyle(color: Colors.white, fontSize: 16), // Style for text inside dropdown
            ),
            selectedItem: selectedExercise,
            onChanged: (SingleExercise? selected) {
              if (selected != null) {
                selectedExercise = selected;
              }
            },
            itemAsString: (item) => item.name,
            compareFn: (item1, item2) => item1.name == item2.name && item1.muscleGroup == item2.muscleGroup,
          ),
          const SizedBox(height: 8.0),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                buildTextField('Sets', setsController, width: 90),
                buildTextField('Reps', repsController, width: 90),
                buildTextField('Weight', weightController, width: 110),
              ],
            ),
          ),
          const SizedBox(height: 8.0),
          ElevatedButton(
            onPressed: () {
              if (selectedExercise != null &&
                  setsController.text.isNotEmpty &&
                  repsController.text.isNotEmpty &&
                  weightController.text.isNotEmpty) {
                final int sets = int.tryParse(setsController.text) ?? 0;
                final int reps = int.tryParse(repsController.text) ?? 0;
                final double weight = double.tryParse(weightController.text) ?? 0;

                if (sets > 0 && reps > 0 && weight > 0) {
                  setState(() {
                    daySplitData[selectedDay]![muscleGroup]!.add(
                      ExerciseDetail(
                        name: selectedExercise!.name,
                        sets: sets,
                        reps: reps,
                        weight: weight,
                      ),
                    );

                    // Reset the input fields
                    selectedExercise = null;
                    setsController.clear();
                    repsController.clear();
                    weightController.clear();
                  });
                }
              }
            },
            child: const Text('Add Exercise', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }


  Container buildTextField(String label, TextEditingController controller, {double width = 85}) {
    return Container(
      width: width,
      margin: EdgeInsets.only(right: 10),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white),
          filled: true,
          fillColor: Colors.grey[850],
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey[700]!),
            borderRadius: BorderRadius.circular(10),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.blue),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        keyboardType: TextInputType.number,
        style: TextStyle(color: Colors.white, fontSize: 12),
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
}
