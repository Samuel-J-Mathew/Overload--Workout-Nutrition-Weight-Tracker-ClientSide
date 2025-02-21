import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:gymapp/data/FoodData.dart';
import '../data/hive_database.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
class CalorieTrackerPage extends StatefulWidget {
  final DateTime selectedDate;
  final Function? onReturn;
  CalorieTrackerPage({required this.selectedDate,this.onReturn});

  @override
  _CalorieTrackerPageState createState() => _CalorieTrackerPageState();
}

class _CalorieTrackerPageState extends State<CalorieTrackerPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _gramController = TextEditingController();
  final HiveDatabase hiveDatabase = HiveDatabase();
  final FocusNode _searchFocusNode = FocusNode();  // Added FocusNode here
  bool _initialFocusRequested = false;
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
  double? originalCalories,
      originalProtein,
      originalFats,
      originalCarbs,
      originalServingSize = 100;
  String? selectedFoodName;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    fetchLocalFoods();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_tabController.index == 0) {
        _searchFocusNode.requestFocus();
      }
    });
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
    _searchFocusNode.dispose();
    super.dispose();
  }
  void requestFocus() {
    if (!_initialFocusRequested) {
      _searchFocusNode.requestFocus();
      _initialFocusRequested = true;
    }
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

    String adjustedCalories = (double.parse(caloriesController.text) * factor)
        .toStringAsFixed(0);
    String adjustedProtein = (double.parse(proteinController.text) * factor)
        .toStringAsFixed(2);
    String adjustedCarbs = (double.parse(carbsController.text) * factor)
        .toStringAsFixed(2);
    String adjustedFats = (double.parse(fatController.text) * factor)
        .toStringAsFixed(2);

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
              focusNode: _searchFocusNode,
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
                            SnackBar(
                                content: Text("Invalid food data structure")),
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
  Widget _buildBarcodeScan() {
    return Container(
      color: Colors.grey[900],
      padding: EdgeInsets.all(16),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton.icon(
              icon: Icon(Icons.camera_alt, color: Colors.black,),
              label: Text('Scan Barcode', style: TextStyle(color: Colors.black),),
              onPressed: _scanBarcode,
            ),
            SizedBox(height: 20),

          ],
        ),
      ),
    );
  }

  Future<void> _scanBarcode() async {
    var result = await BarcodeScanner.scan(options: ScanOptions(
      useCamera: -1, // default camera
      autoEnableFlash: false,
    ));

    if (result.type == ResultType.Barcode) {
      fetchNutritionDetailsFromBarcode(result.rawContent);
    } else if (result.type == ResultType.Error || result.type == ResultType.Cancelled) {
      _buildAddFoodTab();
    }
  }

  void fetchNutritionDetailsFromBarcode(String barcode) async {
    var url = Uri.parse('https://world.openfoodfacts.org/api/v0/product/$barcode.json');
    var response = await http.get(url);

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      if (data['status'] == 1 && data['product'] != null) {
        setState(() {
          selectedFoodName = data['product']['product_name'];
          originalServingSize = double.tryParse(data['product']['serving_quantity'] ?? '100') ?? 100;
          originalCalories = ((data['product']['nutriments']['energy-kcal_100g'] ?? 0) / 100 * originalServingSize).toDouble();
          originalProtein = ((data['product']['nutriments']['proteins_100g'] ?? 0) / 100 * originalServingSize).toDouble();
          originalFats = ((data['product']['nutriments']['fat_100g'] ?? 0) / 100 * originalServingSize).toDouble();
          originalCarbs = ((data['product']['nutriments']['carbohydrates_100g'] ?? 0) / 100 * originalServingSize).toDouble();
          _gramController.text = originalServingSize.toString();
          updateNutrition(originalServingSize!);
          print(originalServingSize);// Updates the UI with the default values calculated for 100 grams
          showNutritionSheet();
        });
      } else {
        showErrorDialog2("Product not found", "The product does not exist in the database.");
      }
    } else {
      showErrorDialog2("Error", "Failed to retrieve data.");
    }
  }


  void showErrorDialog2([String title = "Error", String message = "Failed to load nutrition data."]) {
    showDialog(
      context: context,
      builder: (ctx) =>
          AlertDialog(
            title: Text(title),
            content: Text(message),
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
                  borderSide: BorderSide(
                      color: Colors.white), // White underline when focused
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors
                      .grey[400]!), // Light grey underline when inactive
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
                  borderSide: BorderSide(
                      color: Colors.white), // White underline when focused
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors
                      .grey[400]!), // Light grey underline when inactive
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
                  borderSide: BorderSide(
                      color: Colors.white), // White underline when focused
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors
                      .grey[400]!), // Light grey underline when inactive
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
                  borderSide: BorderSide(
                      color: Colors.white), // White underline when focused
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors
                      .grey[400]!), // Light grey underline when inactive
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
                  borderSide: BorderSide(
                      color: Colors.white), // White underline when focused
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors
                      .grey[400]!), // Light grey underline when inactive
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
                  borderSide: BorderSide(
                      color: Colors.white), // White underline when focused
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors
                      .grey[400]!), // Light grey underline when inactive
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
                "Add to Database",
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

    // Combine API and local foods into one list
    final List<Map<String, dynamic>> combinedFoods = [];

    // Add local foods first
    for (var food in _localFoods) {
      combinedFoods.add({
        ...food,
        'match_score': _calculateMatchScore(query, food['food_name']),
        'is_local': true,
      });
    }

    // Add API foods
    for (var food in apiFoods) {
      combinedFoods.add({
        ...food,
        'match_score': _calculateMatchScore(query, food['food_name']),
        'is_local': false,
      });
    }

    // Deduplicate foods by their name (local foods take precedence)
    final Map<String, dynamic> uniqueFoods = {};
    for (var food in combinedFoods) {
      final foodNameKey = food['food_name'].toLowerCase();
      if (!uniqueFoods.containsKey(foodNameKey) || !food['is_local']) {
        uniqueFoods[foodNameKey] = food;
      }
    }

    // Sort by match score (descending) and prioritize API results for ties
    final sortedFoods = uniqueFoods.values.toList()
      ..sort((a, b) {
        final scoreComparison = b['match_score'].compareTo(a['match_score']);
        if (scoreComparison != 0) return scoreComparison;
        return (a['is_local'] ? 1 : 0).compareTo(b['is_local'] ? 1 : 0);
      });

    setState(() {
      _suggestions = sortedFoods;
    });
  }

// Helper function to calculate match score
  int _calculateMatchScore(String query, String foodName) {
    final lowerQuery = query.toLowerCase();
    final lowerFoodName = foodName.toLowerCase();

    if (lowerQuery == lowerFoodName) return 3; // Exact match
    if (lowerFoodName.contains(lowerQuery)) return 2; // Partial match
    if (lowerQuery.split(' ').any((word) => lowerFoodName.contains(word))) {
      return 1; // Contains part of the query
    }
    return 0; // No match
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
        originalCarbs =
            (data['foods'][0]['nf_total_carbohydrate'] as num).toDouble();
        originalServingSize = 100;
        _gramController.text = '100';
        updateNutrition(100);
        showNutritionSheet();
      });
    } else {
      showErrorDialog();
    }
  }

  void updateNutrition(double amount) {
    double factor = _isUsingGrams ? 100.0 / originalServingSize! : originalServingSize!;
    selectedFood = {
      'Calories': ((originalCalories! * amount) / factor).toStringAsFixed(0),
      'Protein': ((originalProtein! * amount) / factor).toStringAsFixed(2),
      'Fats': ((originalFats! * amount) / factor).toStringAsFixed(2),
      'Carbs': ((originalCarbs! * amount) / factor).toStringAsFixed(2),
    };
  }

  bool _isUsingGrams = false;  // Default to grams

  void setMeasurementMode(bool usingGrams) {
    setState(() {
      _isUsingGrams = usingGrams;
    });
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


                      SizedBox(height: 10),
                      Center(
                        child: Text(
                          "${selectedFoodName ?? 'Selected Food'} ",
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      SizedBox(height: 10),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: TextField(
                          controller: _gramController,
                          decoration: InputDecoration(
                            labelText: _isUsingGrams ? 'Servings' : 'Grams',
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
                            double input = double.tryParse(value) ?? 0;
                            setModalState(() {
                              updateNutrition(input);
                            });
                          },
                        ),
                      ),
                      SizedBox(height: 8),
                      Center(
                        child: ToggleButtons(
                          isSelected: [_isUsingGrams, !_isUsingGrams],
                          renderBorder: false,
                          fillColor: Colors.transparent,
                          splashColor: Colors.transparent,  // Removes the splash effect
                          highlightColor: Colors.transparent,  // Removes the highlight effect

                          children: <Widget>[
                            Container(
                              margin: EdgeInsets.only(right: 12),
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                  color: _isUsingGrams ? Colors.white : Color.fromRGBO(20, 20, 20, 1), // Darker when selected, lighter when not
                                  borderRadius: BorderRadius.circular(30)
                              ),
                              child: Center(
                                child: Text(
                                  'servings',
                                  style: TextStyle(color: _isUsingGrams ? Colors.black : Colors.white),
                                ),
                              ),
                            ),

                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                  color: !_isUsingGrams ? Colors.white : Color.fromRGBO(20, 20, 20, 1), // Darker when selected, lighter when not
                                  borderRadius: BorderRadius.circular(30)
                              ),
                              child: Center(
                                child: Text(
                                  'grams',
                                  style: TextStyle(color: !_isUsingGrams ? Colors.black : Colors.white),
                                ),
                              ),
                            ),
                          ],
                          onPressed: (int index) {
                            setModalState(() {
                              _isUsingGrams = index == 0;
                              updateNutrition(double.tryParse(_gramController.text) ?? 0);
                            });
                          },
                        ),
                      ),
                      if (selectedFood != null) ...[
                        SizedBox(height: 10),
                        Center(
                          child: Text(
                            'Calories: ${selectedFood!['Calories']}',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ),
                        Center(
                          child: Text(
                            'Protein: ${selectedFood!['Protein']}g',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ),
                        Center(
                          child: Text(
                            'Fats: ${selectedFood!['Fats']}g',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ),
                        Center(
                          child: Text(
                            'Carbs: ${selectedFood!['Carbs']}g',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ),
                        SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () => logFood(),
                          child: Text("Log Food",
                            style: TextStyle(color: Colors.black),),
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
        SnackBar(
            content: Text('No food selected'), backgroundColor: Colors.red),
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
    final User? user = FirebaseAuth.instance.currentUser;
    addFood(
        user!.uid,
        widget.selectedDate,
        selectedFoodName!,
        selectedFood!['Calories'],
        selectedFood!['Protein'],
        selectedFood!['Carbs'],
        selectedFood!['Fats'],
    );

    Navigator.pop(context);
  }
  Future<void> addFood(String userId, DateTime date, String name, String calories, String protein, String carbs, String fats) async {
    var dateFormatted = DateFormat('yyyyMMdd').format(date);
    var foodsCollection = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('foods')
        .doc(dateFormatted)
        .collection('entries');

    try {
      await foodsCollection.add({
        'name': name,
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fats': fats,
        'timestamp': Timestamp.fromDate(date)
      });
      print("Food added successfully!");
    } catch (e) {
      print("Failed to add food: $e");
    }
  }

  void showErrorDialog() {
    showDialog(
      context: context,
      builder: (ctx) =>
          AlertDialog(
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
    return WillPopScope(
      onWillPop: () async {
        // Call the callback function before popping
        if (widget.onReturn != null) {
          widget.onReturn!();
        }
        return true; // Return true to allow pop to happen
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.grey[900],
          title: Text(
            "Calorie Tracker", style: TextStyle(color: Colors.white),),
          bottom: TabBar(
            controller: _tabController,
            labelColor: Colors.white,
            // Color for selected tab text
            unselectedLabelColor: Colors.grey[500],
            // Dark grey for unselected tabs
            indicatorColor: Colors.white,
            // White underline for the selected tab
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
                    Icon(MdiIcons.barcodeScan, size: 16), // Smaller icon
                    SizedBox(width: 8), // Spacing between icon and text
                    Text("Scan"),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.format_list_bulleted_add, size: 16),
                    // Smaller icon
                    SizedBox(width: 8),
                    // Spacing between icon and text
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
            _buildBarcodeScan(),
            _buildAddFoodTab(),
          ],
        ),
      ),
    );
  }
}