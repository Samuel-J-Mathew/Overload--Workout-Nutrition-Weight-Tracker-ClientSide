import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:gymapp/data/FoodData.dart';
import '../data/hive_database.dart';

class CalorieTrackerPage extends StatefulWidget {
  final DateTime selectedDate;

  CalorieTrackerPage({required this.selectedDate});

  @override
  _CalorieTrackerPageState createState() => _CalorieTrackerPageState();
}

class _CalorieTrackerPageState extends State<CalorieTrackerPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _gramController = TextEditingController();
  final HiveDatabase hiveDatabase = HiveDatabase();

  // Controllers for the "Add Food" form
  final TextEditingController foodNameController = TextEditingController();
  final TextEditingController servingWeightController = TextEditingController();
  final TextEditingController caloriesController = TextEditingController();
  final TextEditingController carbsController = TextEditingController();
  final TextEditingController proteinController = TextEditingController();
  final TextEditingController fatController = TextEditingController();

  List<dynamic> _suggestions = [];
  List<dynamic> _localFoods = [];
  Map<String, dynamic>? selectedFood;
  double? originalCalories, originalProtein, originalFats, originalCarbs, originalServingSize = 100;
  String? selectedFoodName;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchLocalFoods();
  }

  @override
  void dispose() {
    _tabController.dispose();
    foodNameController.dispose();
    servingWeightController.dispose();
    caloriesController.dispose();
    carbsController.dispose();
    proteinController.dispose();
    fatController.dispose();
    _controller.dispose();
    _gramController.dispose();
    super.dispose();
  }

  void fetchLocalFoods() {
    setState(() {
      _localFoods = hiveDatabase.getAllFoodItems().map((foodItem) {
        return {
          'food_name': foodItem.name,
          'calories': foodItem.calories,
          'protein': foodItem.protein,
          'carbs': foodItem.carbs,
          'fats': foodItem.fats,
          'is_local': true,
        };
      }).toList();
    });
  }

  void addFoodToDatabase() {
    if (foodNameController.text.isEmpty ||
        servingWeightController.text.isEmpty ||
        caloriesController.text.isEmpty ||
        proteinController.text.isEmpty ||
        carbsController.text.isEmpty ||
        fatController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please fill in all required fields")),
      );
      return;
    }

    // Convert serving size and adjust stats to 100g
    double servingSize = double.tryParse(servingWeightController.text) ?? 100;
    double factor = 100 / servingSize;

    String adjustedCalories = (double.parse(caloriesController.text) * factor).toStringAsFixed(0);
    String adjustedProtein = (double.parse(proteinController.text) * factor).toStringAsFixed(2);
    String adjustedCarbs = (double.parse(carbsController.text) * factor).toStringAsFixed(2);
    String adjustedFats = (double.parse(fatController.text) * factor).toStringAsFixed(2);

    // Add the new food item to the Hive database for future searches
    hiveDatabase.addFoodItem(
      foodNameController.text,
      adjustedCalories,
      adjustedProtein,
      adjustedCarbs,
      adjustedFats,
      DateTime(2000, 1, 1), // Use the current date for record-keeping
    );

    fetchLocalFoods();

    // Clear the form fields
    foodNameController.clear();
    servingWeightController.clear();
    caloriesController.clear();
    carbsController.clear();
    proteinController.clear();
    fatController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Food added successfully")),
    );
  }

  Widget _buildSearchTab() {
    return Container(
      color: Colors.grey[900],
      child: Column(
        children: <Widget>[
          Padding(
            padding: EdgeInsets.all(16.0),
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Enter a food item',
                labelStyle: TextStyle(color: Colors.grey[400]),
                suffixIcon: IconButton(
                  icon: Icon(Icons.search, color: Colors.white),
                  onPressed: () => fetchFoodInfo(_controller.text),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              style: TextStyle(color: Colors.white),
              onChanged: (value) => fetchFoodInfo(value),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _suggestions.length,
              itemBuilder: (context, index) {
                final food = _suggestions[index];
                return Column(
                  children: [
                    ListTile(
                      title: Text(
                        food['food_name'] ?? 'Unknown',
                        style: TextStyle(color: Colors.white),
                      ),
                      onTap: () {
                        if (food is Map<String, dynamic>) {
                          fetchNutritionDetails(food);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Invalid food data structure")),
                          );
                        }
                      },
                    ),
                    Divider(color: Colors.grey[600]),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddFoodTab() {

    return Container(
      color: Colors.grey[900],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: foodNameController,
              decoration: InputDecoration(
                labelText: "Food Name",
                labelStyle: TextStyle(
                  color: Colors.grey[400], // Light grey label when inactive
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white), // White underline when focused
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey[400]!), // Light grey underline when inactive
                ),
              ),
              style: TextStyle(
                color: Colors.white, // White text when typing
              ),
            ),
            TextField(
              controller: servingWeightController,
              decoration: InputDecoration(
                labelText: "Serving Weight (g)",
                labelStyle: TextStyle(
                  color: Colors.grey[400], // Light grey label when inactive
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white), // White underline when focused
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey[400]!), // Light grey underline when inactive
                ),
              ),
              style: TextStyle(
                color: Colors.white,
              ),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: caloriesController,
              decoration: InputDecoration(
                labelText: "Calories",
                labelStyle: TextStyle(
                  color: Colors.grey[400],
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white), // White underline when focused
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey[400]!), // Light grey underline when inactive
                ),
              ),
              style: TextStyle(
                color: Colors.white,
              ),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: carbsController,
              decoration: InputDecoration(
                labelText: "Carbs",
                labelStyle: TextStyle(
                  color: Colors.grey[400],
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white), // White underline when focused
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey[400]!), // Light grey underline when inactive
                ),
              ),
              style: TextStyle(
                color: Colors.white,
              ),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: proteinController,
              decoration: InputDecoration(
                labelText: "Protein",
                labelStyle: TextStyle(
                  color: Colors.grey[400],
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white), // White underline when focused
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey[400]!), // Light grey underline when inactive
                ),
              ),
              style: TextStyle(
                color: Colors.white,
              ),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: fatController,
              decoration: InputDecoration(
                labelText: "Fat",
                labelStyle: TextStyle(
                  color: Colors.grey[400],
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white), // White underline when focused
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey[400]!), // Light grey underline when inactive
                ),
              ),
              style: TextStyle(
                color: Colors.white,
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: addFoodToDatabase,
              child: Text(
                "Create and Add",
                style: TextStyle(
                  color: Colors.black, // Set text color to black
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> fetchFoodInfo(String query) async {
    if (query.isEmpty) {
      setState(() {
        _suggestions = [];
        selectedFood = null;
      });
      return;
    }

    const apiUrl = 'https://trackapi.nutritionix.com/v2/search/instant';
    final response = await http.get(
      Uri.parse('$apiUrl?query=$query'),
      headers: {
        'x-app-id': '818d2279',
        'x-app-key': 'baf378585b8375b3ea09b50f3a226104',
      },
    );

    List<dynamic> apiFoods = [];
    if (response.statusCode == 200) {
      final results = jsonDecode(response.body);
      apiFoods = results['common'];
    }

    setState(() {
      _suggestions = [
        ..._localFoods.where((food) =>
            food['food_name'].toLowerCase().contains(query.toLowerCase())),
        ...apiFoods,
      ];
    });
  }

  void fetchNutritionDetails(Map<String, dynamic> food) {
    if (food['is_local'] == true) {
      setState(() {
        selectedFoodName = food['food_name'];
        originalCalories = double.parse(food['calories']);
        originalProtein = double.parse(food['protein']);
        originalFats = double.parse(food['fats']);
        originalCarbs = double.parse(food['carbs']);
        originalServingSize = 100;
        _gramController.text = '100';
        updateNutrition(100);
        showNutritionSheet();
      });
    } else {
      fetchNutritionDetailsFromApi(food['food_name']);
    }
  }

  void fetchNutritionDetailsFromApi(String foodName) async {
    selectedFoodName = foodName;
    const apiUrl = 'https://trackapi.nutritionix.com/v2/natural/nutrients';
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        'Content-Type': 'application/json',
        'x-app-id': '818d2279',
        'x-app-key': 'baf378585b8375b3ea09b50f3a226104',
        'x-remote-user-id': '0'
      },
      body: jsonEncode({'query': foodName}),
    );

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      setState(() {
        originalCalories = (data['foods'][0]['nf_calories'] as num).toDouble();
        originalProtein = (data['foods'][0]['nf_protein'] as num).toDouble();
        originalFats = (data['foods'][0]['nf_total_fat'] as num).toDouble();
        originalCarbs = (data['foods'][0]['nf_total_carbohydrate'] as num).toDouble();
        originalServingSize = 100;
        _gramController.text = '100';
        updateNutrition(100);
        showNutritionSheet();
      });
    } else {
      showErrorDialog();
    }
  }

  void updateNutrition(double grams) {
    if (originalCalories != null && originalProtein != null && originalFats != null && originalCarbs != null) {
      setState(() {
        selectedFood = {
          'Calories': ((originalCalories! / originalServingSize!) * grams).toStringAsFixed(0),
          'Protein': ((originalProtein! / originalServingSize!) * grams).toStringAsFixed(2),
          'Fats': ((originalFats! / originalServingSize!) * grams).toStringAsFixed(2),
          'Carbs': ((originalCarbs! / originalServingSize!) * grams).toStringAsFixed(2),
        };
      });
    }
  }

  void showNutritionSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          maxChildSize: 0.94,
          minChildSize: 0.5,
          expand: false,
          builder: (BuildContext context, ScrollController scrollController) {
            return StatefulBuilder(
              builder: (BuildContext context, StateSetter setModalState) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  padding: EdgeInsets.all(20),
                  child: ListView(
                    controller: scrollController,
                    children: [
                      SizedBox(height: 50),
                      if (selectedFood != null) ...[
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: TextField(
                            controller: _gramController,
                            decoration: InputDecoration(
                              labelText: 'grams',
                              labelStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.white),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.white, width: 2.0),
                              ),
                              fillColor: Colors.transparent,
                              filled: true,
                            ),
                            style: TextStyle(color: Colors.white),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              double grams = double.tryParse(value) ?? originalServingSize!;
                              setState(() {
                                updateNutrition(grams);
                              });
                              setModalState(() {});
                            },
                          ),
                        ),
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(height: 10),
                              Text(
                                "${selectedFoodName ?? 'Selected Food'} - ${_gramController.text}g",
                                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'Calories: ${selectedFood!['Calories']}',
                                style: TextStyle(color: Colors.white, fontSize: 16),
                              ),
                              Text(
                                'Protein: ${selectedFood!['Protein']}g',
                                style: TextStyle(color: Colors.white, fontSize: 16),
                              ),
                              Text(
                                'Fats: ${selectedFood!['Fats']}g',
                                style: TextStyle(color: Colors.white, fontSize: 16),
                              ),
                              Text(
                                'Carbs: ${selectedFood!['Carbs']}g',
                                style: TextStyle(color: Colors.white, fontSize: 16),
                              ),
                              SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: () => logFood(),
                                child: Text("Log Food"),
                              ),
                            ],
                          ),
                        ),
                      ]
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void logFood() {
    if (selectedFood == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No food selected'), backgroundColor: Colors.red),
      );
      return;
    }

    Provider.of<FoodData>(context, listen: false).addFood(
      selectedFoodName!,
      selectedFood!['Calories'],
      selectedFood!['Protein'],
      selectedFood!['Carbs'],
      selectedFood!['Fats'],
      widget.selectedDate,
    );

    Navigator.pop(context);
  }

  void showErrorDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Error"),
        content: Text("Failed to load nutrition data."),
        actions: <Widget>[
          TextButton(
            child: Text('Okay'),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.grey[900],
          title: Text("Calorie Tracker", style: TextStyle(color: Colors.white),),
          bottom: TabBar(
            controller: _tabController,
            labelColor: Colors.white, // Color for selected tab text
            unselectedLabelColor: Colors.grey[500], // Dark grey for unselected tabs
            indicatorColor: Colors.white, // White underline for the selected tab
            tabs: [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search, size: 16), // Smaller icon
                    SizedBox(width: 8), // Spacing between icon and text
                    Text("Search"),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.format_list_bulleted_add, size: 16), // Smaller icon
                    SizedBox(width: 8), // Spacing between icon and text
                    Text("Add Food"),
                  ],
                ),
              ),
            ],
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildSearchTab(),
            _buildAddFoodTab(),
          ],
        ),
      ),
    );
  }
}
