import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/workout_data.dart';

class BigHeatMap extends StatelessWidget {
  const BigHeatMap({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final workoutData = Provider.of<WorkoutData>(context);
    final Map<DateTime, int> heatMapData = workoutData.getWorkoutDatesForHeatMap();

    // Get all unique years in the dataset and sort them in descending order
    final years = heatMapData.keys.map((date) => date.year).toSet().toList()..sort((a, b) => b.compareTo(a));

    // Calculate total streak (days logged in a row)
    int streak = _calculateStreak(heatMapData);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Gym Logging",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.grey[850],
        iconTheme: IconThemeData(color: Colors.white),
      ),
      backgroundColor: Colors.grey[900],
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 15),
            // Streak Title and Days
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                children: [
                  Text(
                    "Streak",
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: "    $streak",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 39,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(
                          text: "  days",
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            ...years.map((year) {
              // Generate dates for the current year
              DateTime startOfYear = DateTime(year, 1, 1);
              DateTime endOfYear = DateTime(year, 12, 31);
              List<DateTime> allDatesOfYear = List.generate(
                endOfYear.difference(startOfYear).inDays + 1,
                    (index) => startOfYear.add(Duration(days: index)),
              );

              // Group dates into weeks (rows) and days (columns)
              List<List<DateTime>> weeks = [];
              for (int i = 0; i < allDatesOfYear.length; i += 7) {
                weeks.add(allDatesOfYear.sublist(
                    i, i + 7 > allDatesOfYear.length ? allDatesOfYear.length : i + 7));
              }

              // Heatmap dimensions
              const double boxSize = 3.7;

              // Total days logged for the year
              int totalDaysLogged = allDatesOfYear
                  .where((date) => heatMapData[date] != null && heatMapData[date]! > 0)
                  .length;

              return Column(
                children: [
                  SizedBox(height: 15),
                  // Total days logged
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Text(
                      "$year | Total Days: $totalDaysLogged",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Heatmap
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: weeks.map((week) {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: week.map((date) {
                          int? activityLevel = heatMapData[date];
                          return Container(
                            margin: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: activityLevel != null && activityLevel > 0
                                  ? Colors.blue[400]
                                  : Colors.grey[700],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            width: boxSize,
                            height: boxSize,
                          );
                        }).toList(),
                      );
                    }).toList(),
                  ),
                  // Month labels
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Row(
                      children: [
                        Text(
                          "Jan    Feb    Mar    Apr    May    Jun    Jul    Aug    Sep    Oct    Nov    Dec",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        )
                      ],
                    ),
                  ),
                  Divider(color: Colors.grey[700], thickness: 1),
                ],
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  int _calculateStreak(Map<DateTime, int> heatMapData) {
    List<DateTime> sortedDates = heatMapData.keys.toList()..sort();
    int streak = 0;
    DateTime? lastDate;

    for (DateTime date in sortedDates) {
      if (heatMapData[date]! > 0) {
        if (lastDate == null || date.difference(lastDate).inDays == 1) {
          streak++;
        } else {
          streak = 1;
        }
        lastDate = date;
      }
    }
    return streak;
  }
}
