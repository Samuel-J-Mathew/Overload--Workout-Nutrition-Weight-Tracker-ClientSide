import 'package:flutter/material.dart';
import 'package:gymapp/data/hive_database.dart';
import 'package:gymapp/data/workout_data.dart';
import 'package:gymapp/pages/ExerciseLogPage.dart';
import 'package:gymapp/pages/WeightLogPage.dart';
import 'package:gymapp/pages/home_page.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'models/weight_log.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  Hive.registerAdapter(WeightLogAdapter());  // Register adapter
  await Hive.openBox("workout_database");
  await Hive.openBox<WeightLog>('weight_logs');

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => WorkoutData()),
        Provider(create: (context) => HiveDatabase()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: ExerciseLogPage(),
        //home: HomePage(),// old home page
      ),
    );
  }
}
