import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TrainingPage extends StatefulWidget {
  final String uid;

  TrainingPage({required this.uid});

  @override
  _TrainingPageState createState() => _TrainingPageState();
}

class _TrainingPageState extends State<TrainingPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<String> workoutDates = []; // List to store workout dates
  TextEditingController searchController = TextEditingController();
  String searchQuery = '';
  List<String> allExerciseNames = []; // List to store distinct exercise names
  List<Map<String, dynamic>> selectedExerciseDetails =
      []; // Details of the selected exercise
  String selectedExercise = ''; // Currently selected exercise name
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    loadWorkoutDates();
    fetchAllExercises();
  }

  // Function to fetch workout dates
  void loadWorkoutDates() async {
    print("Attempting to load workout dates for UID: ${widget.uid}");
    // Construct the reference to the workouts collection
    CollectionReference workoutsRef = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.uid)
        .collection('workouts');

    print("Firestore path being queried: ${workoutsRef.path}");

    try {
      QuerySnapshot snapshot = await workoutsRef.get();
      if (snapshot.docs.isNotEmpty) {
        List<String> dates = snapshot.docs.map((doc) => doc.id).toList();
        setState(() {
          workoutDates = dates;
        });
        print("Workout dates loaded successfully: $workoutDates");
      } else {
        print(
            "No workout dates found for user ${widget.uid}. Path: ${workoutsRef.path}");
        // Additional debug to check if there are any docs at all
        var userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.uid)
            .get();
        if (!userDoc.exists) {
          print("User document itself does not exist.");
        } else {
          print("User document exists, but no workouts sub-collection found.");
        }
      }
    } catch (e) {
      print("Error fetching workout dates: $e");
    }
  }

  void fetchAllExercises() async {
    Set<String> exercises = {};
    var snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.uid)
        .collection('workouts')
        .get();
    for (var doc in snapshot.docs) {
      var exerciseSnapshot = await doc.reference.collection('exercises').get();
      for (var exerciseDoc in exerciseSnapshot.docs) {
        exercises.add(exerciseDoc.data()['name'] ?? 'Unnamed Exercise');
      }
    }
    setState(() {
      allExerciseNames = exercises.toList();
    });
  }

  void fetchExerciseDetails(String exerciseName) async {
    List<Map<String, dynamic>> exerciseLogs = [];
    var workoutsSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.uid)
        .collection('workouts')
        .get();

    for (var workoutDoc in workoutsSnapshot.docs) {
      var exerciseSnapshot = await workoutDoc.reference
          .collection('exercises')
          .where('name', isEqualTo: exerciseName)
          .get();

      for (var exerciseDoc in exerciseSnapshot.docs) {
        var data = exerciseDoc.data();
        exerciseLogs.add({
          'date': workoutDoc.id,
          'sets': data['sets'],
          'reps': data['reps'],
          'weight': data['weight']
        });
      }
    }

    setState(() {
      selectedExerciseDetails = exerciseLogs;
      selectedExercise = exerciseName;
    });
  }

  List<FlSpot> _getSpotsFromLogs(List<Map<String, dynamic>> logs) {
    List<FlSpot> spots = [];
    int index = 0;
    for (var log in logs) {
      double weight = double.tryParse(log['weight'].toString()) ?? 0;
      spots.add(FlSpot(index.toDouble(), weight));
      index++;
    }
    return spots;
  }

  LineChartData _mainChartData() {
    final spots = _getSpotsFromLogs(selectedExerciseDetails);
    final DateFormat formatter =
        DateFormat('MM/dd'); // Customize date format as needed

    return LineChartData(
      gridData: FlGridData(show: false),
      titlesData: FlTitlesData(
        show: true,
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 1, // Show every title, adjust based on your data
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index < spots.length) {
                String date = formatter.format(
                    DateTime.parse(selectedExerciseDetails[index]['date']));
                return SideTitleWidget(
                  child: Text(date,
                      style: TextStyle(color: Colors.black, fontSize: 10)),
                  axisSide: meta.axisSide,
                );
              }
              return const Text('');
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              // Display left axis labels with more natural numbers
              if (value % 10 == 0) {
                return Text('${value.toInt()}',
                    style: TextStyle(color: Colors.black, fontSize: 10));
              }
              return Text('');
            },
            interval: 10, // Adjust this interval to scale appropriately
          ),
        ),
        topTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        rightTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border(
          bottom: BorderSide(color: Colors.black, width: 2),
          left: BorderSide(color: Colors.black, width: 2),
        ),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: Colors.blue,
          barWidth: 2,
          dotData: FlDotData(show: false),
          belowBarData: BarAreaData(show: false),
        ),
      ],
    );
  }

  Widget buildExerciseHistoryTab() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.all(8.0),
                child: TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    labelText: 'Search Exercises',
                    suffixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value;
                    });
                  },
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: allExerciseNames.length,
                  itemBuilder: (context, index) {
                    if (allExerciseNames[index]
                        .toLowerCase()
                        .contains(searchQuery)) {
                      return ListTile(
                        title: Text(allExerciseNames[index]),
                        onTap: () {
                          fetchExerciseDetails(allExerciseNames[index]);
                        },
                      );
                    } else {
                      return Container();
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 3,
          child: Column(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  margin: EdgeInsets.all(8),
                  padding: EdgeInsets.all(8),
                  child: selectedExercise.isEmpty
                      ? Center(
                          child: Text("Select an exercise to see the chart"))
                      : LineChart(_mainChartData()),
                ),
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  margin: EdgeInsets.all(8),
                  padding: EdgeInsets.all(8),
                  child: selectedExercise.isEmpty
                      ? Center(child: Text("Select an exercise to see details"))
                      : ListView.builder(
                          itemCount: selectedExerciseDetails.length,
                          itemBuilder: (context, index) {
                            var log = selectedExerciseDetails[index];

                            return ListTile(
                              title:
                                  Text("${log['date']}: ${log['weight']} lbs"),
                              subtitle: Text(
                                  "Sets: ${log['sets']}, Reps: ${log['reps']}"),
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void showExerciseDetails(BuildContext context, String date) async {
    // Fetch exercises for the selected date
    QuerySnapshot exerciseSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.uid)
        .collection('workouts')
        .doc(date)
        .collection('exercises')
        .get();

    List<Map<String, dynamic>> exercises = exerciseSnapshot.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .toList();

    // Display the exercises in a modal bottom sheet
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize
                .min, // This ensures the sheet is only as tall as its content
            children: [
              SizedBox(
                height: 20,
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: Text("Workout For: $date", // Display the date at the top
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    )),
              ),
              Expanded(
                child: Center(
                  child: ListView.builder(
                    itemCount: exercises.length,
                    itemBuilder: (context, index) {
                      return Center(
                        child: ListTile(
                          title: Center(
                              child: Text(
                            exercises[index]['name'],
                            style: TextStyle(fontWeight: FontWeight.bold),
                          )),
                          subtitle: Center(
                            child: Text(
                                'Sets: ${exercises[index]['sets']}, Reps: ${exercises[index]['reps']}, Weight: ${exercises[index]['weight']}lbs'),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void selectExercise(String exerciseName) {
    // Logic to fetch data and update UI for selected exercise
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Training Page"),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: Icon(Icons.history), text: "Exercise History"),
            Tab(
                icon: Icon(Icons.check_circle_outline),
                text: "Completed Workouts"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          buildExerciseHistoryTab(), // Updated exercise history tab // Placeholder for exercise history tab
          buildCompletedWorkoutsTab(), // Method to build the completed workouts tab
        ],
      ),
    );
  }

  // Widget to build the completed workouts tab
  Widget buildCompletedWorkoutsTab() {
    return ListView.builder(
      itemCount: workoutDates.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(workoutDates[index]), // Display the workout date
          onTap: () => showExerciseDetails(context, workoutDates[index]),
        );
      },
    );
  }
}
