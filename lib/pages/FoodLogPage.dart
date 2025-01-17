import 'package:flutter/material.dart';
import 'package:gymapp/data/FoodItemDatabase.dart';
import 'package:gymapp/data/FoodData.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../components/food_tile.dart';
import 'CalorieTrackerPage.dart';
class FoodLogPage extends StatefulWidget {
  @override
  _FoodLogPageState createState() => _FoodLogPageState();
}

class _FoodLogPageState extends State<FoodLogPage> {
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
    _selectedDay = _focusedDay;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFoodsForSelectedDay(_selectedDay!);
    });
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });
    _loadFoodsForSelectedDay(selectedDay);  // Ensure this method updates the UI correctly.
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
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[850],
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
              color: Colors.grey[900],
              padding: EdgeInsets.only(left: 40, right: 14,),
              child: _selectedDayFoods == null || _selectedDayFoods!.isEmpty
                  ? Center(
                child: Text(
                  'No foods logged for this day. Tap to add.',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              )
                  : ListView.builder(
                itemCount: _selectedDayFoods!.length,
                itemBuilder: (context, index) {
                  var food = _selectedDayFoods![index];
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
                      _loadFoodsForSelectedDay(_selectedDay!); // Refresh the list
                    },
                  );
                },
              ),
            ),
          ),
          Container(

            constraints: BoxConstraints(
              maxHeight: 55, // Maximum height
            ),
            color: Colors.grey[900],
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
                    color: Colors.grey[850],
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
                        'Search for an exercise',
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
