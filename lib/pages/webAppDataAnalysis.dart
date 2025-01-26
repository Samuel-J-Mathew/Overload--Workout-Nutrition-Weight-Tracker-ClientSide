import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class webAppDataAnalysisPage extends StatefulWidget {
  const webAppDataAnalysisPage({super.key});

  @override
  _webAppDataAnalysisPageState createState() => _webAppDataAnalysisPageState();
}

class _webAppDataAnalysisPageState extends State<webAppDataAnalysisPage> {
  String? selectedExercise;
  List<String> exerciseNames = [];
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadExerciseNames();
    });
  }

  void loadExerciseNames() async {
    User? user = _auth.currentUser;
    if (user != null) {
      var snapshot = await _firestore.collection('workouts').doc(user.uid).get();
      if (snapshot.exists) {
        var data = snapshot.data() as Map<String, dynamic>;
        setState(() {
          exerciseNames = List<String>.from(data['exerciseNames']);
          if (exerciseNames.isNotEmpty) {
            selectedExercise = exerciseNames.first;
          }
        });
      } else {
        print("No document found for user ${user.uid}");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    User? user = _auth.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Exercise Data Analysis"),
        ),
        body: const Center(
          child: Text("Please log in to view your data."),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Exercise Data Analysis"),
      ),
      body: Column(
        children: [
          if (exerciseNames.isNotEmpty)
            DropdownButton<String>(
              value: selectedExercise,
              onChanged: (value) {
                setState(() {
                  selectedExercise = value;
                });
              },
              items: exerciseNames.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: _firestore.collection('workouts').doc(user.uid).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.data!.exists) {
                  return const Center(child: Text("No data available."));
                }

                var data = snapshot.data!.data() as Map<String, dynamic>?;
                if (data == null || selectedExercise == null || !data.containsKey(selectedExercise!)) {
                  return const Center(child: Text("No data available for this exercise."));
                }

                List<Map<String, dynamic>> weightData = List<Map<String, dynamic>>.from(data[selectedExercise!]);
                print("Weight Data for $selectedExercise: $weightData");
                List<FlSpot> spots = weightData.asMap().entries.map((entry) {
                  double x = entry.key.toDouble();
                  double y = (entry.value['weight'] as num).toDouble();
                  return FlSpot(x, y);
                }).toList();

                return spots.isNotEmpty
                    ? LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      getDrawingHorizontalLine: (value) {
                        return const FlLine(
                          color: Color(0xff37434d),
                          strokeWidth: 1,
                        );
                      },
                      drawVerticalLine: true,
                      getDrawingVerticalLine: (value) {
                        return const FlLine(
                          color: Color(0xff37434d),
                          strokeWidth: 1,
                        );
                      },
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: Border.all(color: const Color(0xff37434d), width: 1),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        barWidth: 5,
                        belowBarData: BarAreaData(
                          show: false,
                        ),
                      ),
                    ],
                    titlesData: const FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: false,
                        ),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: false,
                        ),
                      ),
                    ),
                  ),
                )
                    : const Center(child: Text("No data available for this exercise"));
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: _firestore.collection('workouts').doc(user.uid).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.data!.exists) {
                  return const Center(child: Text("No data available."));
                }

                var data = snapshot.data!.data() as Map<String, dynamic>?;
                if (data == null || selectedExercise == null || !data.containsKey(selectedExercise!)) {
                  return const Center(child: Text("No data available for this exercise."));
                }

                List<Map<String, dynamic>> exerciseDetails = List<Map<String, dynamic>>.from(data[selectedExercise!]);
                print("Exercise Details for $selectedExercise: $exerciseDetails");

                return ListView(
                  children: exerciseDetails.map((detail) {
                    return ListTile(
                      title: Text(detail['name']),
                      subtitle: Text('Sets: ${detail['sets']}, Reps: ${detail['reps']}, Weight: ${detail['weight']}'),
                      trailing: Text(DateFormat('yyyy-MM-dd').format(detail['date'].toDate())), // Display the date of the exercise
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}