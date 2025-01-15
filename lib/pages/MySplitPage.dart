import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:gymapp/pages/weeklysplittile.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import '../data/WorkoutSplit.dart';
import '../data/hive_database.dart';
import '../models/NutritionalInfo.dart';
import '../models/SingleExercise.dart';
import '../data/exercise_list.dart'; // Import the exercise_list.dart file\
import 'package:collection/collection.dart';
class MySplitPage extends StatefulWidget {
  const MySplitPage({super.key});

  @override
  _MySplitPageState createState() => _MySplitPageState();
}

class _MySplitPageState extends State<MySplitPage> {
  List<WorkoutSplit> weeklySplits = [];
  HiveDatabase db = HiveDatabase();
String _averageCals = "0";
String _averageProtein = "0";
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
  void saveNutritionalInfo(String calories, String protein) {
    final nutritionalInfo = NutritionalInfo(calories: calories, protein: protein);
    final box = Hive.box<NutritionalInfo>('nutritionBox');
    box.put('nutrition', nutritionalInfo);
    loadNutritionalInfo(); // Reload to update the UI
  }

  void loadNutritionalInfo() {
    final box = Hive.box<NutritionalInfo>('nutritionBox');
    NutritionalInfo? info = box.get('nutrition');

    if (info != null) {
      setState(() {
        _averageCals = info.calories;
        _averageProtein = info.protein;
      });
    }
  }
  void _showEditNutritionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final TextEditingController calorieController = TextEditingController(text: _averageCals);
        final TextEditingController proteinController = TextEditingController(text: _averageProtein);

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
                saveNutritionalInfo(calorieController.text, proteinController.text);
                Navigator.of(context).pop();
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
        backgroundColor: Colors.grey[900],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.black87,
            height: 400,
            child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                color: Colors.grey[850],
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 19.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center, // Center vertically
                    crossAxisAlignment: CrossAxisAlignment.center, // Center horizontally
                    children: [
                      SizedBox(height: 40),
                      Align(
                        alignment: Alignment.centerLeft, // Aligns the child to the left of the available space.
                        child: Text("Workout Program", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                      ),

                      SizedBox(height: 10,),
                      Row(

                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children:
                        daysOfWeek.map((day) => buildDaySplit(day)).toList(),
                      ),
                      SizedBox(height: 20),
                      Divider(
                        color: Colors.grey[100],
                        height: 1,
                        // Set minimal height to reduce space
                        thickness: .75, // Minimal visual thickness
                      ),
                      SizedBox(height:5),
                      ElevatedButton.icon(
                        onPressed: () => _showEditSplitDialog(context),
                        icon: Icon(Icons.edit, color: Colors.white,),  // Icon for editing
                        label: Text("Edit Program"),  // Text label
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white, backgroundColor: Colors.grey[800],  // Text and icon color
                        ),
                      ),
                    ],
                  ),
                )
            ),


          ),
          Container(

            color: Colors.grey[900],
            width: MediaQuery.of(context).size.width * 1, // 90% of screen width
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              color: Colors.grey[850],
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
                        SizedBox(width: 30,),
                        Column(
                          children: [
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: "${(_averageProtein)} ", // Step count
                                    style: TextStyle(
                                      color: Colors.white, // Color for the step count
                                      fontSize: 28, // Larger font size for the step count
                                      fontWeight: FontWeight.bold, // Optional: Make it bold
                                    ),
                                  ),
                                  TextSpan(
                                    text: "g", // "steps" label
                                    style: TextStyle(
                                      color: Colors.grey, // Different color for the "steps" text
                                      fontSize: 15, // Smaller font size for the "steps" text
                                    ),
                                  ),
                                ],
                              ),

                            ),
                            Text(" Protein", style: TextStyle(color: Colors.grey, fontSize: 18)),
                          ],

                        )

                      ],

                    ),
                    SizedBox(height: 10),
                    Divider(
                      color: Colors.grey[600],
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
          Container(
            color: Colors.grey[900],
            height: 79,
          ),
        ],

      ),
    );
  }

  void _showEditSplitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[850], // Set the background color here
          title: const Text('Edit Split', style: TextStyle(color: Colors.white) ,),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Day Selector
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: daysOfWeek.map((day) {
                        return ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                            selectedDay == day ? Colors.white : Colors.grey[900],
                            foregroundColor: selectedDay == day ? Colors.black : Colors.white, // Text color
                            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                            fixedSize: Size(50, 30), // Fixed size of the button
                            elevation: 2, // Elevation for shadow
                          ),
                          onPressed: () {
                            setState(() {
                              selectedDay = day;
                              if (!daySplitData.containsKey(day)) {
                                daySplitData[day] = {};
                              }
                              selectedMuscleGroups =
                                  daySplitData[selectedDay]?.keys.toList() ?? [];
                            });
                          },
                          child: Text(day),
                        );
                      }).toList(),
                    ),
                  ),
                  // Muscle Group Selector
                  DropdownButtonHideUnderline(
                    child: DropdownButton2<String>(
                      isExpanded: true,
                      hint: const Text('Select Muscle Groups', style: TextStyle(color: Colors.white),),
                      items: allMuscleGroups
                          .map((item) => DropdownMenuItem<String>(
                        value: item,
                        child: Row(
                          children: [
                            Checkbox(
                              value: selectedMuscleGroups.contains(item),
                              onChanged: (bool? value) {
                                setState(() {
                                  if (value == true) {
                                    selectedMuscleGroups.add(item);
                                    daySplitData[selectedDay]![item] ??= [];
                                  } else {
                                    selectedMuscleGroups.remove(item);
                                    daySplitData[selectedDay]!.remove(item);
                                  }
                                });
                              },
                              checkColor: Colors.white, // Color of the tick
                              activeColor: Colors.blue, // Background color of the checkbox
                            ),
                            Text(item),
                          ],
                        ),
                      ))
                          .toList(),
                      onChanged: (_) {},

                    ),
                  ),
                  // Exercise Inputs
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: selectedMuscleGroups.map((muscleGroup) {
                          return _buildMuscleGroupSection(muscleGroup, setState);
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.white),),
            ),
            ElevatedButton(
              onPressed: () {
                _saveSplit(
                  selectedDay,
                  selectedMuscleGroups,
                  daySplitData[selectedDay]!,
                );
                Navigator.pop(context);
              },
              child: const Text('Save Split',style: TextStyle(color: Colors.black),),
            ),
          ],
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
          Text(
            muscleGroup,
            style: const TextStyle(color: Colors.white, fontSize: 18),
          ),
          const SizedBox(height: 8.0),
          ...daySplitData[selectedDay]![muscleGroup]!.map((exercise) {
            return ListTile(
              title: Text(
                exercise.name,
                style: const TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                '${exercise.sets} sets x ${exercise.reps} reps at ${exercise.weight} lbs',
                style: const TextStyle(color: Colors.grey),
              ),
            );
          }),
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
            dropdownDecoratorProps: const DropDownDecoratorProps(
              dropdownSearchDecoration: InputDecoration(labelText: 'Exercise', labelStyle: TextStyle(color: Colors.white)),
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
          TextField(
            controller: setsController,
            decoration: const InputDecoration(labelText: 'Sets',labelStyle: TextStyle(color: Colors.white)),
            keyboardType: TextInputType.number,
          ),
          TextField(
            controller: repsController,
            decoration: const InputDecoration(labelText: 'Reps',labelStyle: TextStyle(color: Colors.white)),
            keyboardType: TextInputType.number,
          ),
          TextField(
            controller: weightController,
            decoration: const InputDecoration(labelText: 'Weight (lbs)',labelStyle: TextStyle(color: Colors.white)),
            keyboardType: TextInputType.number,
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
            child: const Text('Add Exercise', style: TextStyle(color: Colors.black),),
          ),
        ],
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
