import 'package:flutter/material.dart';
import 'package:gymapp/data/FoodItemDatabase.dart';
import 'package:gymapp/data/FoodData.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

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
    _loadFoodsForSelectedDay(selectedDay);
  }

  void _loadFoodsForSelectedDay(DateTime date) {
    var foodData = Provider.of<FoodData>(context, listen: false);
    _selectedDayFoods = foodData.getFoodForDate(date);
    setState(() {});
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

    final String name = _foodNameController.text;
    final String calories = (_caloriesController.text);
    final String protein = (_proteinController.text);
    final String carbs = (_carbsController.text);
    final String fats = (_fatsController.text);
    final DateTime date = _selectedDay ?? DateTime.now();

    Provider.of<FoodData>(context, listen: false)
        .addFood(name, calories, protein, carbs, fats, date);
    _foodNameController.clear();
    _caloriesController.clear();
    _proteinController.clear();
    _carbsController.clear();
    _fatsController.clear();
    _loadFoodsForSelectedDay(_selectedDay!);  // Reload the day's data to reflect the new addition
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[850],
      body: Column(
        children: [
          SizedBox(height: 20),
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
                color: Colors.blue[400],
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.blue[900],
                shape: BoxShape.circle,
              ),
            ),
            headerStyle: HeaderStyle(
              titleTextStyle: TextStyle(color: Colors.white),
              leftChevronIcon: Icon(Icons.chevron_left, color: Colors.white),
              rightChevronIcon: Icon(Icons.chevron_right, color: Colors.white),
            ),
          ),
          Expanded(
            child: Container(
              color: Colors.grey[900],
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
                  return ListTile(
                    title: Text(food.name, style: TextStyle(color: Colors.white)),
                    subtitle: Text(
                        '${food.calories} calories, ${food.protein}g protein, ${food.carbs}g carbs, ${food.fats}g fats',
                        style: TextStyle(color: Colors.grey)),
                    onTap: () {},  // Optionally, expand this to edit or view more details
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addFoodDialog,
        tooltip: 'Add Food',
        child: Icon(Icons.add),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
      ),
    );
  }
}
