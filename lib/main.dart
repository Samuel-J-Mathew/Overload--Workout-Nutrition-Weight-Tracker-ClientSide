import 'package:flutter/material.dart';
import 'package:gymapp/data/hive_database.dart';
import 'package:gymapp/data/workout_data.dart';
import 'package:gymapp/pages/CalorieTrackerPage.dart';
import 'package:gymapp/pages/DataAnalysisPage.dart';
import 'package:gymapp/pages/ExerciseLogPage.dart';
import 'package:gymapp/pages/FoodLogPage.dart';
import 'package:gymapp/pages/MySplitPage.dart';
import 'package:gymapp/pages/SearchPage.dart';
import 'package:gymapp/pages/StepCounterPage.dart';
import 'package:gymapp/pages/TestClassPage.dart';
import 'package:gymapp/pages/WeightLogPage.dart';
import 'package:gymapp/pages/home_page.dart';
import 'package:gymapp/pages/newUpdatedHome.dart';
import 'package:gymapp/pages/updatedHome.dart';
import 'package:gymapp/pages/workout_page.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'models/step_log.dart';
import 'models/weight_log.dart';
import 'package:gymapp/data/FoodData.dart';
import 'package:gymapp/data/FoodItemDatabase.dart';
import 'pages/FoodLogPage.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  Hive.registerAdapter(WeightLogAdapter());  // Register adapter
  Hive.registerAdapter(StepLogAdapter());
  Hive.registerAdapter(FoodItemDatabaseAdapter()); // Registering the adapter
  await Hive.openBox("workout_database");
  await Hive.openBox<WeightLog>('weight_logs');
  await Hive.openBox<StepLog>('stepLogs');
  await Hive.openBox<FoodItemDatabase>('food_items');


  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => WorkoutData()),
        ChangeNotifierProvider(create: (context) => FoodData(HiveDatabase())),
        Provider(create: (context) => HiveDatabase()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: ExerciseLogPage(),
       //home:CalorieTrackerPage(),
      ),
    );
  }
}
