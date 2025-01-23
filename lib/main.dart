import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gymapp/data/hive_database.dart';
import 'package:gymapp/data/workout_data.dart';
import 'package:gymapp/pages/CalorieTrackerPage.dart';
import 'package:gymapp/pages/DataAnalysisPage.dart';
import 'package:gymapp/pages/ExerciseLogPage.dart';
import 'package:gymapp/pages/ExportPage.dart';
import 'package:gymapp/pages/FoodLogPage.dart';
import 'package:gymapp/pages/MySplitPage.dart';
import 'package:gymapp/pages/SearchPage.dart';
import 'package:gymapp/pages/StepCounterPage.dart';
import 'package:gymapp/pages/TestClassPage.dart';
import 'package:gymapp/pages/WeightLogPage.dart';
import 'package:gymapp/pages/auth_page.dart';
import 'package:gymapp/pages/home_page.dart';
import 'package:gymapp/pages/newUpdatedHome.dart';
import 'package:gymapp/pages/testExample.dart';
import 'package:gymapp/pages/updatedHome.dart';
import 'package:gymapp/pages/weeklysplittile.dart';
import 'package:gymapp/pages/workout_page.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'data/NutritionProvider.dart';
import 'models/NutritionalInfo.dart';
import 'models/step_log.dart';
import 'models/weight_log.dart';
import 'package:gymapp/data/FoodData.dart';
import 'package:gymapp/data/FoodItemDatabase.dart';
import 'pages/FoodLogPage.dart';
import 'models/JournalProvider.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if(kIsWeb){
    await Firebase.initializeApp(options: FirebaseOptions( apiKey: "AIzaSyB_JQeM5PzMDIG8pvwY9fPL_beApfoThyE",
        authDomain: "gymapp-2d58a.firebaseapp.com",
        projectId: "gymapp-2d58a",
        storageBucket: "gymapp-2d58a.firebasestorage.app",
        messagingSenderId: "644555737003",
        appId: "1:644555737003:web:93fb96fa62f41c2984b4ee",
        measurementId: "G-DCQ9BNHJG9"));
  }else{
    await Firebase.initializeApp();
  }


  await Hive.initFlutter();
  Hive.registerAdapter(WeightLogAdapter()); // Register adapter
  Hive.registerAdapter(StepLogAdapter());
  Hive.registerAdapter(FoodItemDatabaseAdapter()); // Registering the adapter
  Hive.registerAdapter(NutritionalInfoAdapter());
  await Hive.openBox("workout_database");
  await Hive.openBox<WeightLog>('weight_logs');
  await Hive.openBox<StepLog>('stepLogs');
  await Hive.openBox<FoodItemDatabase>('food_items');
  await Hive.openBox<NutritionalInfo>('nutritionBox');
  await Hive.openBox<Map>('journalBox'); // Open the journalBox
  await Hive.openBox<Map<String, dynamic>>('journal_entries');
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
        ChangeNotifierProvider(
            create: (context) => NutritionProvider()..loadNutritionalInfo()),
        ChangeNotifierProvider(
            create: (context) => JournalProvider()
              ..fetchJournalEntries()), // Add JournalProvider
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: AuthPage(),
        //home:CalorieTrackerPage(),
      ),
    );
  }
}
