import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NutritionPage extends StatefulWidget {
  final String uid;

  NutritionPage({required this.uid});

  @override
  _NutritionPageState createState() => _NutritionPageState();
}

class _NutritionPageState extends State<NutritionPage> {
  late Map<DateTime, List<Map<String, dynamic>>> _dailyNutrition;
  DateTime _focusedDay = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _dailyNutrition = {};
    fetchWeeklyData(_focusedDay);
  }

  void fetchWeeklyData(DateTime focusedDay) {
    setState(() {
      _isLoading = true;
    });

    var startOfWeek = DateTime(focusedDay.year, focusedDay.month,
        focusedDay.day - (focusedDay.weekday - 1));
    var endOfWeek = startOfWeek.add(Duration(days: 6));
    var uid = widget.uid;

    if (uid == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    // Initialize or clear previous data
    Map<DateTime, List<Map<String, dynamic>>> newNutritionData = {};
    int daysFetched = 0;

    // Fetch for each day in the week
    for (DateTime day = startOfWeek;
        day.isBefore(endOfWeek.add(Duration(days: 1)));
        day = day.add(Duration(days: 1))) {
      var dayKey = DateFormat('yyyyMMdd').format(day);
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('foods')
          .doc(dayKey)
          .collection('entries')
          .get()
          .then((snapshot) {
        var dailyData = snapshot.docs.map((doc) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          // Convert string data to double, handling potential null or incorrect formats
          return {
            'calories':
                double.tryParse(data['calories']?.toString() ?? '0') ?? 0,
            'protein': double.tryParse(data['protein']?.toString() ?? '0') ?? 0,
            'carbs': double.tryParse(data['carbs']?.toString() ?? '0') ?? 0,
            'fats': double.tryParse(data['fats']?.toString() ?? '0') ?? 0,
            'date': day // Optionally store the date for reference
          };
        }).toList();

        if (dailyData.isNotEmpty) {
          newNutritionData[day] = dailyData;
        }

        daysFetched++;
        if (daysFetched == 7) {
          // Update state once all data has been fetched
          setState(() {
            _dailyNutrition =
                new Map<DateTime, List<Map<String, dynamic>>>.from(
                    newNutritionData);
            _isLoading = false;
          });
        }
      }).catchError((error) {
        print("Error fetching data: $error");
        setState(() {
          _isLoading = false;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.only(top: 16.0, bottom: 16.0),
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : Container(
                      decoration: BoxDecoration(
                        color: Colors
                            .white, // Optional: set a background color for the container
                        borderRadius: BorderRadius.circular(
                            20), // Adjust the radius for more or less curve
                        boxShadow: [
                          BoxShadow(
                            color:
                                Colors.grey.withOpacity(0.3), // Color of shadow
                            spreadRadius: 2, // Spread radius
                            blurRadius: 7, // Blur radius
                            offset: Offset(0, 3), // changes position of shadow
                          ),
                        ],
                      ),
                      margin: EdgeInsets.only(top: 0, left: 30, right: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(
                            45.0), // Optional padding inside the container
                        child: _buildGraph(),
                      ),
                    ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors
                        .white, // Optional: set a background color for the container
                    borderRadius: BorderRadius.circular(
                        20), // Adjust the radius for more or less curve
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3), // Color of shadow
                        spreadRadius: 2, // Spread radius
                        blurRadius: 7, // Blur radius
                        offset: Offset(0, 3), // changes position of shadow
                      ),
                    ],
                  ),
                  margin: EdgeInsets.all(8),
                  child: Padding(
                    padding: const EdgeInsets.all(
                        8.0), // Optional padding inside the container
                    child: _buildCalendar(),
                  ),
                ),
                SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors
                        .white, // Set the background color of the container
                    borderRadius: BorderRadius.circular(
                        12), // Rounded corners for a soft, modern look
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(
                            0.3), // Shadow color with some transparency
                        spreadRadius: 0, // Spread radius
                        blurRadius: 6, // Blur radius to give a soft shadow
                        offset: Offset(0,
                            3), // Offset in Y direction for a slight elevation effect
                      ),
                    ],
                  ),
                  margin: EdgeInsets.all(
                      8), // Margin to keep some distance from other UI elements
                  padding: EdgeInsets.all(
                      16), // Padding inside the container for spacing around content
                  child:
                      _buildMacrosBreakdown(), // Your method that builds the macros breakdown content
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGraph() {
    List<FlSpot> caloriesSpots = [];
    List<FlSpot> proteinSpots = [];
    List<FlSpot> carbsSpots = [];
    List<FlSpot> fatsSpots = [];

    _dailyNutrition.forEach((date, nutritionData) {
      double dayIndex = date
          .difference(
              _focusedDay.subtract(Duration(days: _focusedDay.weekday - 1)))
          .inDays
          .toDouble();
      double totalCalories = 0;
      double totalProtein = 0;
      double totalCarbs = 0;
      double totalFats = 0;

      nutritionData.forEach((data) {
        totalCalories += data['calories'];
        totalProtein += data['protein'];
        totalCarbs += data['carbs'];
        totalFats += data['fats'];
      });

      caloriesSpots.add(FlSpot(dayIndex, totalCalories.roundToDouble()));
      proteinSpots.add(FlSpot(dayIndex, totalProtein.roundToDouble()));
      carbsSpots.add(FlSpot(dayIndex, totalCarbs.roundToDouble()));
      fatsSpots.add(FlSpot(dayIndex, totalFats.roundToDouble()));
    });
    // Handle the scenario where there is no data
    bool hasData = caloriesSpots.isNotEmpty;
    double maxX = hasData
        ? caloriesSpots.map((e) => e.x).reduce(max)
        : 6; // Assume a week display if no data
    double maxY = hasData
        ? [caloriesSpots, proteinSpots, carbsSpots, fatsSpots]
                .expand((x) => x)
                .map((e) => e.y)
                .reduce(max) *
            1.1
        : 1; // Just to ensure non-zero scale

    // Define the DateFormatter
    DateFormat dateFormatter = DateFormat.Md();

    // Function to convert dayIndex back to a DateTime and format it
    String getTitle(double value) {
      DateTime baseDate =
          _focusedDay.subtract(Duration(days: _focusedDay.weekday - 1));
      DateTime date = baseDate.add(Duration(days: value.toInt()));
      return dateFormatter.format(date);
    }

    // Calculate interval to show exactly 7 labels
    double interval = (maxX / (7 - 1)); // Distribute 7 labels across the range

    return LineChart(
      LineChartData(
        lineTouchData: LineTouchData(
          enabled: true,
          getTouchedSpotIndicator:
              (LineChartBarData bar, List<int> spotIndexes) {
            return spotIndexes.map((index) {
              return TouchedSpotIndicatorData(
                FlLine(color: Colors.blue, strokeWidth: 4),
                FlDotData(show: true),
              );
            }).toList();
          },
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (List<LineBarSpot> touchedSpots) {
              return touchedSpots.map((touchedSpot) {
                final textStyle = TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                );
                String label;
                switch (touchedSpot.barIndex) {
                  case 0:
                    label = "Calories: ";
                    break;
                  case 1:
                    label = "Protein: ";
                    break;
                  case 2:
                    label = "Carbs: ";
                    break;
                  case 3:
                    label = "Fats: ";
                    break;
                  default:
                    label = "";
                }
                return LineTooltipItem(
                  '$label${touchedSpot.y.toInt()}',
                  textStyle,
                );
              }).toList();
            },
            //tooltipBgColor: Colors.black54, // Correctly apply color if available
            fitInsideHorizontally: true,
            fitInsideVertically: true,
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false, // Disable vertical grid lines
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey
                  .withOpacity(0.1), // Set a lighter color for horizontal lines
              strokeWidth: 1.0, // Adjust stroke width as needed
            );
          },
          horizontalInterval:
              200, // Adjust the interval for less frequent horizontal lines
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                // Check if value is close to an interval to avoid off-point labels
                if ((value % interval).abs() < 0.1 ||
                    (interval - (value % interval)).abs() < 0.1) {
                  final text = getTitle(value);
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    space: 8.0, // Add spacing if needed
                    child: Text(text,
                        style: TextStyle(color: Colors.black, fontSize: 10)),
                  );
                } else {
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    space: 0,
                    child: Text(''), // Empty text for non-label points
                  );
                }
              },
              reservedSize: 40,
            ),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false), // Disable right titles
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 160, // Increase interval for fewer left axis titles
              getTitlesWidget: (double value, TitleMeta meta) {
                if (value % 10 == 0) {
                  // Adjust this condition to control title frequency
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    space: 8.0,
                    child: Text(value.toString(),
                        style: TextStyle(color: Colors.black, fontSize: 10)),
                  );
                } else {
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    space: 0,
                    child: Text(''), // Empty text for non-label points
                  );
                }
              },
              reservedSize: 40,
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: maxX,
        minY: 0,
        maxY: maxY * 1.1, // Adding a 10% padding to avoid clipping at the top
        lineBarsData: hasData
            ? [
                LineChartBarData(
                  spots: caloriesSpots,
                  isCurved: true,
                  color: Colors.red,
                  barWidth: 2,
                  isStrokeCapRound: true,
                  dotData: FlDotData(show: false),
                  belowBarData: BarAreaData(show: false),
                ),
                LineChartBarData(
                  spots: proteinSpots,
                  isCurved: true,
                  color: Colors.blue,
                  barWidth: 2,
                  isStrokeCapRound: true,
                  dotData: FlDotData(show: false),
                  belowBarData: BarAreaData(show: false),
                ),
                LineChartBarData(
                  spots: carbsSpots,
                  isCurved: true,
                  color: const Color.fromARGB(255, 37, 182, 97),
                  barWidth: 2,
                  isStrokeCapRound: true,
                  dotData: FlDotData(show: false),
                  belowBarData: BarAreaData(show: false),
                ),
                LineChartBarData(
                  spots: fatsSpots,
                  isCurved: true,
                  color: const Color.fromARGB(255, 193, 64, 197),
                  barWidth: 2,
                  isStrokeCapRound: true,
                  dotData: FlDotData(show: false),
                  belowBarData: BarAreaData(show: false),
                ),
              ]
            : [
                LineChartBarData(
                    spots: [FlSpot(0, 0), FlSpot(maxX, 0)],
                    isCurved: false,
                    color: Colors.red),
              ],
      ),
    );
  }

  Widget _buildCalendar() {
    return TableCalendar(
      firstDay: DateTime.utc(2010, 10, 16),
      lastDay: DateTime.utc(2030, 3, 14),
      focusedDay: _focusedDay,
      calendarFormat: CalendarFormat.week,
      startingDayOfWeek: StartingDayOfWeek.monday, // Set week start to Monday
      onPageChanged: (focusedDay) {
        setState(() {
          _focusedDay = focusedDay;
          fetchWeeklyData(_focusedDay);
        });
      },
      // Customizing the appearance of the days of the week
      daysOfWeekStyle: DaysOfWeekStyle(
        weekdayStyle: TextStyle(fontWeight: FontWeight.bold),
        weekendStyle: TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
      // Use calendar builders to customize the individual date cells
      calendarBuilders: CalendarBuilders(
        markerBuilder: (context, date, events) {
          // Check if the day has data
          bool hasData = _dailyNutrition[date] != null &&
              _dailyNutrition[date]!.isNotEmpty;
          if (hasData) {
            return Positioned(
              bottom: 4,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue,
                ),
                width: 5,
                height: 5,
              ),
            );
          }
          return null;
        },
        defaultBuilder: (context, date, focusedDay) {
          // Customize default day cell style
          return Container(
            alignment: Alignment.center,
            child: Text(
              '${date.day}',
              style:
                  TextStyle(fontWeight: FontWeight.w200), // Bold for all days
            ),
          );
        },
      ),
      // Other properties as required
      calendarStyle: CalendarStyle(
        // Apply style for today
        todayDecoration: BoxDecoration(
          color: const Color.fromARGB(255, 88, 100, 212),
          shape: BoxShape.circle,
        ),
        // Apply style for selected day
        selectedDecoration: BoxDecoration(
          color: Colors.blue[400],
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Widget _buildMacrosBreakdown() {
    double totalCalories = 0;
    double totalProteins = 0;
    double totalCarbs = 0;
    double totalFats = 0;
    int daysCounted = _dailyNutrition.keys.length;

    // Sum up the values from the nutrition data
    _dailyNutrition.forEach((_, nutritionData) {
      nutritionData.forEach((data) {
        totalCalories += data['calories'];
        totalProteins += data['protein'];
        totalCarbs += data['carbs'];
        totalFats += data['fats'];
      });
    });

    // Ensure division by zero does not occur
    double avgCalories = daysCounted > 0 ? totalCalories / daysCounted : 0;
    double avgProteins = daysCounted > 0 ? totalProteins / daysCounted : 0;
    double avgCarbs = daysCounted > 0 ? totalCarbs / daysCounted : 0;
    double avgFats = daysCounted > 0 ? totalFats / daysCounted : 0;

    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Macros Breakdown",
              style: TextStyle(
                  fontWeight: FontWeight.normal,
                  fontSize: 16,
                  color: Colors.black),
            ),
          ),
          Divider(
            thickness: 1,
            color: Colors.grey[400],
          ),
          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween, // Adjusts space distribution
            children: [
              // First Column: Macro names
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Macro',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text('Calories'),
                    SizedBox(height: 8),
                    Text('Protein'),
                    SizedBox(height: 8),
                    Text('Carbs'),
                    SizedBox(height: 8),
                    Text('Fat'),
                  ],
                ),
              ),
              // Second Column: Average values
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: 8),
                    Text('Avg', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text('${avgCalories.toStringAsFixed(0)} '),
                    SizedBox(height: 8),
                    Text('${avgProteins.toStringAsFixed(0)} '),
                    SizedBox(height: 8),
                    Text('${avgCarbs.toStringAsFixed(0)} '),
                    SizedBox(height: 8),
                    Text('${avgFats.toStringAsFixed(0)} '),
                    SizedBox(height: 8),
                  ],
                ),
              ),
              // Third Column: Total values
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Total',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text('${totalCalories.toStringAsFixed(0)} '),
                    SizedBox(height: 8),
                    Text('${totalProteins.toStringAsFixed(0)} '),
                    SizedBox(height: 8),
                    Text('${totalCarbs.toStringAsFixed(0)} '),
                    SizedBox(height: 8),
                    Text('${totalFats.toStringAsFixed(0)} '),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
