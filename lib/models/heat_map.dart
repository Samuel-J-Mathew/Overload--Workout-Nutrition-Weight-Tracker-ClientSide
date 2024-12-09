import 'package:flutter/material.dart';
import 'package:flutter_heatmap_calendar/flutter_heatmap_calendar.dart';
import 'package:provider/provider.dart';
import '../data/workout_data.dart';

class MyHeatMap extends StatefulWidget {
  const MyHeatMap({Key? key}) : super(key: key);

  @override
  _MyHeatMapState createState() => _MyHeatMapState();
}

class _MyHeatMapState extends State<MyHeatMap> {
  @override
  Widget build(BuildContext context) {
    final workoutData = Provider.of<WorkoutData>(context);
    final Map<DateTime, int> heatMapData = workoutData.getWorkoutDatesForHeatMap();

    return Container(
      width: MediaQuery.of(context).size.width,
      height: 120, // Adjusted for better control
      child: HeatMap(
        datasets: heatMapData,
        size: MediaQuery.of(context).size.width / 3 / 19,  // Adjust for three columns
        startDate: DateTime.now().subtract(Duration(days: 200)),
        endDate: DateTime.now(),
        colorMode: ColorMode.opacity,
        showText: false,
        scrollable: false,
        colorsets: const {
          1: Color.fromARGB(20, 2, 179, 8),
          2: Color.fromARGB(40, 2, 179, 8),
          3: Color.fromARGB(60, 2, 179, 8),
          4: Color.fromARGB(80, 2, 179, 8),
          5: Color.fromARGB(100, 2, 179, 8),
          6: Color.fromARGB(120, 2, 179, 8),
          7: Color.fromARGB(150, 2, 179, 8),
          8: Color.fromARGB(180, 2, 179, 8),
          9: Color.fromARGB(220, 2, 179, 8),
          10: Color.fromARGB(255, 2, 179, 8),
        },
        //textColor: Colors.transparent,  // Hide day labels by setting them to transparent
        showColorTip: false,
      ),
    );
  }
}
