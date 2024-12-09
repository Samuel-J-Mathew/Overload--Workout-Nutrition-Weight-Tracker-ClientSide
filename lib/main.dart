import 'package:flutter/material.dart';
import 'package:gymapp/data/workout_data.dart';
import 'package:gymapp/pages/ExerciseLogPage.dart';
import 'package:gymapp/pages/home_page.dart';
import 'package:gymapp/pages/updatedHome.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
void main() async {
  //initalize hive
  await Hive.initFlutter();

  //open hive box
  await Hive.openBox("workout_database");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => WorkoutData(),
      child:  MaterialApp(
      debugShowCheckedModeBanner: false,
      //home: HomePage(), //old home page
        home: ExerciseLogPage(), // default new main home page

    ),
    );
  }
}
