import 'package:gymapp/data/FoodItemDatabase.dart';
import 'package:intl/intl.dart';

import '../data/FoodData.dart';
import 'package:uuid/uuid.dart';
class FoodDay {
  final String id; // Unique identifier for each workout
  DateTime date;
  final String name;
  final List<FoodItemDatabase> Food;

  FoodDay({
    required this.name,
    required this.Food,
    required this.date
  }) : id = DateFormat('yyyy-MM-dd').format(date); // ID generated based on the date
}