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
  final TextEditingController _servingsController = TextEditingController();
  final TextEditingController _gramsController = TextEditingController();
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

  // FatSecret API credentials
  static const String clientId = '8a6e7daf65c041cbb904ae833f29efdb';
  static const String clientSecret = '584603b00aae4e0fb34fe4bc39389cd8';
  static const String tokenUrl = 'https://oauth.fatsecret.com/connect/token';
  static const String apiBaseUrl = 'https://platform.fatsecret.com/rest';

  String? _accessToken;
  DateTime? _tokenExpiry;

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
    _getAccessToken(); // Get initial access token
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
    _servingsController.dispose();
    _gramsController.dispose();
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

          updateNutrition(originalServingSize!);
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

    // Ensure we have a valid token
    if (!await _ensureValidToken()) {
      print('Failed to get valid access token');
      return;
    }

    try {
      // Use FatSecret autocomplete API
      final response = await http.post(
        Uri.parse('$apiBaseUrl/server.api'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Authorization': 'Bearer $_accessToken',
        },
        body: Uri(queryParameters: {
          'method': 'foods.autocomplete.v2',
          'expression': query,
          'max_results': '10',
          'format': 'json',
        }).query,
      );

      print('FatSecret API Response Status: ${response.statusCode}');
      print('FatSecret API Response Body: ${response.body}');

      List<Map<String, dynamic>> apiFoods = [];

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Parsed JSON data: $data');

        // Parse FatSecret autocomplete response
        if (data['suggestions'] != null) {
          var suggestionsData = data['suggestions'];
          print('Suggestions data: $suggestionsData');

          // Handle both single suggestion and multiple suggestions
          List<dynamic> suggestions = [];
          if (suggestionsData['suggestion'] is List) {
            suggestions = suggestionsData['suggestion'];
          } else if (suggestionsData['suggestion'] is String) {
            suggestions = [suggestionsData['suggestion']];
          }

          print('Found ${suggestions.length} suggestions');

          // For each suggestion, we need to get detailed nutrition info
          for (var suggestion in suggestions) {
            print('Processing suggestion: $suggestion');
            String foodName = suggestion.toString();
            if (foodName.isNotEmpty) {
              apiFoods.add({
                'food_name': foodName.toLowerCase(),
                'food_id': null, // We'll need to get this from search
                'is_local': false,
              });
            }
          }
        } else {
          print('No suggestions found in response');
        }
      } else {
        print('FatSecret API error: ${response.statusCode}');
        print('Response: ${response.body}');
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
      final Map<String, Map<String, dynamic>> uniqueFoods = {};
      for (var food in combinedFoods) {
        final foodNameKey = food['food_name'].toLowerCase();
        if (!uniqueFoods.containsKey(foodNameKey) || !food['is_local']) {
          uniqueFoods[foodNameKey] = food;
        }
      }

      // Sort by match score (descending) and prioritize API results for ties
      final sortedFoods = uniqueFoods.values.toList()
        ..sort((a, b) {
          final int scoreA = a['match_score'] ?? 0;
          final int scoreB = b['match_score'] ?? 0;
          final int scoreComparison = scoreB.compareTo(scoreA);

          if (scoreComparison != 0) return scoreComparison;
          return (a['is_local'] ? 1 : 0).compareTo(b['is_local'] ? 1 : 0);
        });

      setState(() {
        _suggestions = sortedFoods;
      });
    } catch (e) {
      print('Error fetching food info: $e');
    }
  }


// Helper function to calculate match score
  int _calculateMatchScore(String query, String? foodName) {
    if (foodName == null) return 0;

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
        // If local food doesn't have serving size info, default to 100g
        originalServingSize = food.containsKey('serving_size') ? double.parse(food['serving_size']) : 100.0;

        updateNutrition(originalServingSize!);
        showNutritionSheet();
      });
    } else {
      fetchNutritionDetailsFromApi(food['food_name']);
    }
  }


  void fetchNutritionDetailsFromApi(String foodName) async {
    selectedFoodName = foodName;

    // Ensure we have a valid token
    if (!await _ensureValidToken()) {
      showErrorDialog();
      return;
    }

    try {
      // First, search for the food to get its ID
      final searchResponse = await http.post(
        Uri.parse('$apiBaseUrl/server.api'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Authorization': 'Bearer $_accessToken',
        },
        body: Uri(queryParameters: {
          'method': 'foods.search',
          'search_expression': foodName,
          'max_results': '1',
          'format': 'json',
        }).query,
      );

      print('FatSecret Search Response Status: ${searchResponse.statusCode}');
      print('FatSecret Search Response Body: ${searchResponse.body}');

      if (searchResponse.statusCode == 200) {
        var searchData = jsonDecode(searchResponse.body);
        print('Parsed search data: $searchData');

        // Check if the response contains an error
        if (searchData['error'] != null) {
          print('Search API error: ${searchData['error']}');
          showErrorDialog('API Error', 'Failed to search for food: ${searchData['error']['message']}');
          return;
        }

        if (searchData['foods'] != null && searchData['foods']['food'] != null) {
          var foodItem = searchData['foods']['food'];
          String? foodId = foodItem['food_id'];
          print('Found food ID: $foodId');

          if (foodId != null) {
            // Now get detailed nutrition information
            final nutritionResponse = await http.post(
              Uri.parse('$apiBaseUrl/server.api'),
              headers: {
                'Content-Type': 'application/x-www-form-urlencoded',
                'Authorization': 'Bearer $_accessToken',
              },
              body: Uri(queryParameters: {
                'method': 'food.get.v2',
                'food_id': foodId,
                'format': 'json',
              }).query,
            );

            print('FatSecret Nutrition Response Status: ${nutritionResponse.statusCode}');
            print('FatSecret Nutrition Response Body: ${nutritionResponse.body}');

            if (nutritionResponse.statusCode == 200) {
              var nutritionData = jsonDecode(nutritionResponse.body);
              print('Parsed nutrition data: $nutritionData');

              // Check if the response contains an error
              if (nutritionData['error'] != null) {
                print('Nutrition API error: ${nutritionData['error']}');
                showErrorDialog('API Error', 'Failed to get nutrition data: ${nutritionData['error']['message']}');
                return;
              }

              if (nutritionData['food'] != null) {
                var food = nutritionData['food'];
                var servings = food['servings'];
                print('Food servings: $servings');

                if (servings != null && servings['serving'] != null) {
                  var servingData = servings['serving'];
                  print('Serving data: $servingData');

                  // Handle both single serving (object) and multiple servings (array)
                  Map<String, dynamic> serving;
                  if (servingData is List) {
                    // Multiple servings - prefer 100g serving or use first one
                    List<Map<String, dynamic>> servingList = List<Map<String, dynamic>>.from(servingData);
                    serving = servingList.firstWhere(
                          (s) => s['metric_serving_amount'] == '100.000' || s['metric_serving_amount'] == 100.0,
                      orElse: () => servingList.first,
                    );
                    print('Selected serving from multiple: $serving');
                  } else {
                    // Single serving
                    serving = Map<String, dynamic>.from(servingData);
                    print('Single serving: $serving');
                  }

                  setState(() {
                    // Extract nutrition values per 100g (convert strings to numbers)
                    var calories = double.tryParse(serving['calories'].toString()) ?? 0.0;
                    var protein = double.tryParse(serving['protein'].toString()) ?? 0.0;
                    var fat = double.tryParse(serving['fat'].toString()) ?? 0.0;
                    var carbs = double.tryParse(serving['carbohydrate'].toString()) ?? 0.0;
                    var servingSize = double.tryParse(serving['metric_serving_amount'].toString()) ?? 100.0;

                    print('Raw nutrition values - Calories: $calories, Protein: $protein, Fat: $fat, Carbs: $carbs, Serving Size: $servingSize');

                    // Convert to per 100g values
                    double factor = 100 / servingSize;
                    originalCalories = (calories * factor);
                    originalProtein = (protein * factor);
                    originalFats = (fat * factor);
                    originalCarbs = (carbs * factor);
                    originalServingSize = 100; // Default to 100g

                    print('Converted to per 100g - Calories: $originalCalories, Protein: $originalProtein, Fat: $originalFats, Carbs: $originalCarbs');

                    updateNutrition(originalServingSize!);
                    showNutritionSheet();
                  });
                  return;
                }
              }
            }
          }
        }
      }

      // If we get here, something went wrong
      showErrorDialog();
    } catch (e) {
      print('Error fetching nutrition details: $e');
      showErrorDialog();
    }
  }



  void updateNutrition(double amount) {
    print('updateNutrition called with amount: $amount');
    print('originalCalories: $originalCalories, originalProtein: $originalProtein, originalFats: $originalFats, originalCarbs: $originalCarbs');

    double factor = amount / originalServingSize!;

    selectedFood = {
      'Calories': (originalCalories! * factor).toStringAsFixed(0),
      'Protein': (originalProtein! * factor).toStringAsFixed(2),
      'Fats': (originalFats! * factor).toStringAsFixed(2),
      'Carbs': (originalCarbs! * factor).toStringAsFixed(2),
    };

    print('Updated selectedFood: $selectedFood');
  }

  void showNutritionSheet() {
    _servingsController.text = '1';
    _gramsController.text = originalServingSize!.toStringAsFixed(0);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            final calories = double.tryParse(selectedFood?['Calories'] ?? '0') ?? 0;
            final protein = double.tryParse(selectedFood?['Protein'] ?? '0') ?? 0;
            final fats = double.tryParse(selectedFood?['Fats'] ?? '0') ?? 0;
            final carbs = double.tryParse(selectedFood?['Carbs'] ?? '0') ?? 0;
            final totalMacros = protein + fats + carbs;

            return Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Color(0xFF1F1F1F),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          selectedFoodName ?? 'Selected Food',
                          style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField('Servings', _servingsController, () {
                          final servings = double.tryParse(_servingsController.text) ?? 0;
                          final newGrams = (servings * originalServingSize!).toStringAsFixed(0);
                          _gramsController.text = newGrams;
                          updateNutrition(double.parse(newGrams));
                          setModalState(() {});
                        }),
                      ),
                      SizedBox(width: 20),
                      Expanded(
                        child: _buildTextField('Grams', _gramsController, () {
                          final grams = double.tryParse(_gramsController.text) ?? 0;
                          final newServings = (grams / originalServingSize!).toStringAsFixed(1);
                          _servingsController.text = newServings;
                          updateNutrition(grams);
                          setModalState(() {});
                        }),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Nutritional Information (per 100g)',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ),
                  SizedBox(height: 10),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    childAspectRatio: 1.5,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    children: [
                      _buildNutritionStatCircle('Calories', calories, 'kcal', Color(0xFFE91E63), calories / 2000),
                      _buildNutritionStatCircle('Protein', protein, 'g', Color(0xFF3F51B5), totalMacros > 0 ? protein / totalMacros : 0),
                      _buildNutritionStatCircle('Fats', fats, 'g', Color(0xFFFF9800), totalMacros > 0 ? fats / totalMacros : 0),
                      _buildNutritionStatCircle('Carbs', carbs, 'g', Color(0xFF4CAF50), totalMacros > 0 ? carbs / totalMacros : 0),
                    ],
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => logFood(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF424242),
                      minimumSize: Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: Text("Log Food", style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, VoidCallback onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey, fontSize: 14)),
        SizedBox(height: 5),
        TextField(
          controller: controller,
          style: TextStyle(color: Colors.white, fontSize: 16),
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            filled: true,
            fillColor: Color(0xFF333333),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
          ),
          onChanged: (value) => onChanged(),
        ),
      ],
    );
  }

  Widget _buildNutritionStatCircle(String name, double value, String unit, Color color, double progress) {
    return Container(
      padding: EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 5,
                    backgroundColor: Colors.grey.withOpacity(0.3),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      value.toStringAsFixed(name == 'Calories' ? 0 : 1),
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 5),
          Text('$name ($unit)', style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
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

  void showErrorDialog([String title = "Error", String message = "Failed to load nutrition data."]) {
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

  // FatSecret OAuth 2.0 token management
  Future<void> _getAccessToken() async {
    try {
      // Create Basic Auth header
      String basicAuth = 'Basic ' + base64Encode(utf8.encode('$clientId:$clientSecret'));

      final response = await http.post(
        Uri.parse(tokenUrl),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Authorization': basicAuth,
        },
        body: Uri(queryParameters: {
          'grant_type': 'client_credentials',
          'scope': 'basic premier',
        }).query,
      );

      print('Token Response Status: ${response.statusCode}');
      print('Token Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _accessToken = data['access_token'];
        _tokenExpiry = DateTime.now().add(Duration(seconds: data['expires_in']));
        print('Access token obtained successfully: $_accessToken');
      } else {
        print('Failed to get access token: ${response.statusCode}');
        print('Response: ${response.body}');
      }
    } catch (e) {
      print('Error getting access token: $e');
    }
  }

  Future<bool> _ensureValidToken() async {
    if (_accessToken == null || _tokenExpiry == null || DateTime.now().isAfter(_tokenExpiry!)) {
      await _getAccessToken();
    }
    return _accessToken != null;
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