import 'dart:math';
import 'package:flutter/material.dart';
import 'package:gymapp/data/FoodItemDatabase.dart';
import 'package:gymapp/data/FoodData.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../components/food_tile.dart';
import '../data/hive_database.dart';
import '../models/NutritionalInfo.dart';
import 'CalorieTrackerPage.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
class FoodLogPage extends StatefulWidget {
  @override
  _FoodLogPageState createState() => _FoodLogPageState();
}

class _FoodLogPageState extends State<FoodLogPage> {
  final HiveDatabase hiveDatabase = HiveDatabase();
  double _caloriesLeft = 0;
  double _caloriesConsumedToday = 0;
  double _proteinConsumedToday = 0;
  double _carbsConsumedToday = 0;
  double _fatsConsumedToday = 0;
  double _dailyGoal = 0;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<FoodItemDatabase>? _selectedDayFoods;

  final TextEditingController _foodNameController = TextEditingController();
  final TextEditingController _caloriesController = TextEditingController();
  final TextEditingController _proteinController = TextEditingController();
  final TextEditingController _carbsController = TextEditingController();
  final TextEditingController _fatsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadNutritionalInfo();
    _selectedDay = _focusedDay;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFoodsForSelectedDay(_selectedDay!);
    });
  }
  void loadNutritionalInfo() async {
    var box = await Hive.openBox<NutritionalInfo>('nutritionBox');
    NutritionalInfo? info = box.get('nutrition');
    if (info != null) {
      _dailyGoal = double.tryParse(info.calories) ?? 0;
      calculateCalories();
    }
  }

  void calculateCalories() {
    DateTime today = DateTime.now();
    var foodItems = hiveDatabase.getFoodForDate(_selectedDay ?? DateTime.now());  // Use _selectedDay, fallback to today if null
    _caloriesConsumedToday = foodItems.fold(0, (sum, item) {
      return sum + (double.tryParse(item.calories) ?? 0);
    });
    _proteinConsumedToday = foodItems.fold(0, (sum, item) {
      return sum + (double.tryParse(item.protein) ?? 0);
    });
    _carbsConsumedToday = foodItems.fold(0, (sum, item) {
      return sum + (double.tryParse(item.carbs) ?? 0);
    });
    _fatsConsumedToday = foodItems.fold(0, (sum, item) {
      return sum + (double.tryParse(item.fats) ?? 0);
    });
    setState(() {
      _caloriesLeft = max(0, _dailyGoal - _caloriesConsumedToday);
    });
  }
  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });
    _loadFoodsForSelectedDay(selectedDay);
    calculateCalories();  // Call this here to recalculate with the new selected day
  }

  void _loadFoodsForSelectedDay(DateTime date) {
    var foodData = Provider.of<FoodData>(context, listen: false);
    // Filter out foods with the placeholder date (DateTime(2000, 1, 1))
    _selectedDayFoods = foodData.getFoodForDate(date).where((food) {
      return food.date != DateTime(2000, 1, 1); // Exclude placeholder date
    }).toList();



    if (_selectedDayFoods != null && _selectedDayFoods!.isNotEmpty) {
      print("Foods on ${DateFormat('yyyy-MM-dd').format(date)}:");
      for (var food in _selectedDayFoods!) {
        print("${food.name}: ${food.calories} calories, ${food.protein}g protein, ${food.carbs}g carbs, ${food.fats}g fats");
      }
    } else {
      print("No foods logged for ${DateFormat('yyyy-MM-dd').format(date)}.");
    }

    setState(() {}); // This ensures the UI updates with the new data
  }

  void _addFoodDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add New Food'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _foodNameController,
                decoration: InputDecoration(labelText: 'Food Name'),
              ),
              TextField(
                controller: _caloriesController,
                decoration: InputDecoration(labelText: 'Calories'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _proteinController,
                decoration: InputDecoration(labelText: 'Protein'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _carbsController,
                decoration: InputDecoration(labelText: 'Carbs'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _fatsController,
                decoration: InputDecoration(labelText: 'Fats'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _addFoodItem();
            },
            child: Text('Add'),
          ),
        ],
      ),
    );
  }


  void _addFoodItem() {
    // Check if all fields are filled
    if (_foodNameController.text.isEmpty ||
        _caloriesController.text.isEmpty ||
        _proteinController.text.isEmpty ||
        _carbsController.text.isEmpty ||
        _fatsController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Please fill in all fields before adding.'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    // Retrieve input data
    final String name = _foodNameController.text.trim();
    final String calories = _caloriesController.text.trim();
    final String protein = _proteinController.text.trim();
    final String carbs = _carbsController.text.trim();
    final String fats = _fatsController.text.trim();
    final DateTime date = _selectedDay ?? DateTime.now();

    // Use the FoodData provider to add the food item
    Provider.of<FoodData>(context, listen: false)
        .addFood(name, calories, protein, carbs, fats, date);

    // Clear the text fields after adding
    _foodNameController.clear();
    _caloriesController.clear();
    _proteinController.clear();
    _carbsController.clear();
    _fatsController.clear();

    // Reload the food items for the selected day to update the UI
    _loadFoodsForSelectedDay(date);
  }


  void refreshFoodLog() {
    _loadFoodsForSelectedDay(_selectedDay!);
    calculateCalories();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(31, 31, 31, 1),
      body: Column(
        children: [
          SizedBox(height: 50),
          TableCalendar(
            firstDay: DateTime.utc(2000, 1, 1),
            lastDay: DateTime.utc(2100, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            eventLoader: (day) => Provider.of<FoodData>(context, listen: false).getFoodForDate(day),
            onDaySelected: _onDaySelected,
            calendarFormat: CalendarFormat.week,
            calendarStyle: CalendarStyle(
              defaultTextStyle: TextStyle(color: Colors.white),
              weekendTextStyle: TextStyle(color: Colors.white),
              todayTextStyle: TextStyle(color: Colors.white),
              selectedTextStyle: TextStyle(color: Colors.white),
              todayDecoration: BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.blue[900],
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            headerStyle: HeaderStyle(
              titleTextStyle: TextStyle(color: Colors.white),
              formatButtonTextStyle: TextStyle(color: Colors.white),
              leftChevronIcon: Icon(Icons.chevron_left, color: Colors.white),
              rightChevronIcon: Icon(Icons.chevron_right, color: Colors.white),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: TextStyle(color: Colors.white),
              weekendStyle: TextStyle(color: Colors.white),
            ),
          ),
          SizedBox(height: 6,),
          Expanded(
            child: Container(
              color: Color.fromRGBO(20, 20, 20, 1),
              padding: EdgeInsets.only(left: 40, right: 14,),
              child: _selectedDayFoods == null || _selectedDayFoods!.isEmpty
                  ? Center(
                child: Text(
                  'No foods logged for this day. Tap to add.',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              )
                  : ListView.builder(
                itemCount: (_selectedDayFoods?.isEmpty ?? true) ? 1 : _selectedDayFoods!.length + 1, // Adjust the count to include the header text
                itemBuilder: (context, index) {
                  if (index == 0 && (_selectedDayFoods?.isEmpty ?? true)) {
                    // This is the header or message when no food items are available
                    return Center(
                      child: Text(
                        'No foods logged for this day. Tap to add.',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    );
                  } else if (index == 0) {
                    // This is the header when items are available
                    return Padding(
                      padding: EdgeInsets.symmetric( vertical: 5),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,

                        children: [
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: "${(_caloriesConsumedToday.toInt())} ",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.normal, // Optional: Make it bold
                                  ),
                                ),
                                WidgetSpan(
                                  child: Icon(Icons.local_fire_department, color: Colors.white, size: 18), // Fire icon with adjustable color and size
                                ),
                              ],
                            ),
                          ),
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: "${(_proteinConsumedToday.toInt())} ",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.normal, // Optional: Make it bold
                                  ),
                                ),
                                WidgetSpan(
                                  child: Icon(MdiIcons.alphaPCircle, color: Colors.white, size: 18), // Fire icon with adjustable color and size
                                ),
                              ],
                            ),
                          ),
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: "${(_fatsConsumedToday.toInt())} ",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.normal, // Optional: Make it bold
                                  ),
                                ),
                                WidgetSpan(
                                  child: Icon(MdiIcons.alphaFCircle, color: Colors.white, size: 18), // Fire icon with adjustable color and size
                                ),
                              ],
                            ),
                          ),
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: "${(_carbsConsumedToday.toInt())} ",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.normal, // Optional: Make it bold
                                  ),
                                ),
                                WidgetSpan(
                                  child: Icon(MdiIcons.alphaCCircle, color: Colors.white, size: 18), // Fire icon with adjustable color and size
                                ),
                              ],
                            ),
                          ),

                        ],

                      ),
                    );
                  } else {
                    // Return FoodTile
                    var food = _selectedDayFoods![index - 1]; // Adjust index because of the added header
                    return FoodTile(
                      foodName: food.name,
                      calories: double.parse(food.calories).toInt().toString(),
                      protein: double.parse(food.protein.replaceAll("g", "")).toInt().toString(),
                      carbs: double.parse(food.carbs.replaceAll("g", "")).toInt().toString(),
                      fats: double.parse(food.fats.replaceAll("g", "")).toInt().toString(),
                      isCompleted: false, // Replace with actual logic if needed
                      onDelete: () {
                        // Pass the correct identifier (e.g., 'id') to deleteFood
                        Provider.of<FoodData>(context, listen: false).deleteFood(food.id);
                        calculateCalories();
                        _loadFoodsForSelectedDay(_selectedDay!); // Refresh the list
                      },
                    );
                  }
                },
              ),
            ),
          ),
          Container(

            constraints: BoxConstraints(
              maxHeight: 55, // Maximum height
            ),
            color: Color.fromRGBO(25, 25, 25, 1),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => CalorieTrackerPage(selectedDate: _selectedDay ?? DateTime.now(), onReturn: refreshFoodLog, )),
                  );  // The action you want to perform on tap
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Color.fromRGBO(40, 40, 40, 1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.search, color: Colors.white),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => CalorieTrackerPage(selectedDate: _selectedDay ?? DateTime.now(),onReturn: refreshFoodLog,)),
                          );
                        },
                      ),
                      SizedBox(width: 9),
                      Text(
                        'Search for a food',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],

      ),



    );
  }
}
