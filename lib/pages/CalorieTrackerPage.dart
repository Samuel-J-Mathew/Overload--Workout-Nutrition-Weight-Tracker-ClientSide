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
import 'FoodLogPage.dart';
import 'package:url_launcher/url_launcher.dart';
class CalorieTrackerPage extends StatefulWidget {
  final DateTime selectedDate;
  final Function? onReturn;
  final VoidCallback? onLogFoodsPressed;
  CalorieTrackerPage({required this.selectedDate, this.onReturn, this.onLogFoodsPressed});

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
  final FocusNode _searchFocusNode = FocusNode(); // Added FocusNode here
  bool _initialFocusRequested = false;
  // Controllers for the "Add Food" form
  final TextEditingController foodNameController = TextEditingController();
  final TextEditingController servingWeightController = TextEditingController();
  final TextEditingController caloriesController = TextEditingController();
  final TextEditingController carbsController = TextEditingController();
  final TextEditingController proteinController = TextEditingController();
  final TextEditingController fatController = TextEditingController();
  bool _isSheetOpen = false;
  String? servingDescription;
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

  // Add FocusNode and state for grams input
  final FocusNode _gramsFocusNode = FocusNode();
  bool _isGramsFocused = false;
  // Add FocusNode and state for servings input
  final FocusNode _servingsFocusNode = FocusNode();
  bool _isServingsFocused = false;

  // Unit selection for grams/oz
  String _selectedUnit = 'g';

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
    // Listen for grams focus changes
    _gramsFocusNode.addListener(_handleGramsFocusChange);
    // Listen for servings focus changes
    _servingsFocusNode.addListener(_handleServingsFocusChange);
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
    // Dispose grams focus node
    _gramsFocusNode.removeListener(_handleGramsFocusChange);
    _gramsFocusNode.dispose();
    // Dispose servings focus node
    _servingsFocusNode.removeListener(_handleServingsFocusChange);
    _servingsFocusNode.dispose();
    super.dispose();
  }

  void _handleGramsFocusChange() {
    setState(() {
      _isGramsFocused = _gramsFocusNode.hasFocus;
    });
  }

  void _handleServingsFocusChange() {
    setState(() {
      _isServingsFocused = _servingsFocusNode.hasFocus;
    });
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
            child: Row(
              children: [
                Expanded(
                  flex: 7,
                  child: TextField(
                    controller: _controller,
                    focusNode: _searchFocusNode,
                    decoration: InputDecoration(
                      labelText: 'Enter a food item',
                      labelStyle: TextStyle(color: Colors.grey[400]),
                      prefixIcon: Icon(Icons.search, color: Colors.white),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(color: Colors.white, width: 2),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(color: Colors.white, width: 2),
                      ),
                      contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                      filled: true,
                      fillColor: Colors.transparent,
                    ),
                    style: TextStyle(color: Colors.white, fontSize: 18),
                    onChanged: (value) => fetchFoodInfo(value),
                  ),
                ),
                SizedBox(width: 12),
                Container(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      if (widget.onLogFoodsPressed != null) {
                        widget.onLogFoodsPressed!();
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 0,
                      padding: EdgeInsets.symmetric(horizontal: 24),
                    ),
                    child: Text('Log Foods', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
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
        setState(() {
          _tabController.index = 2; // Switch to Add Food tab
        });
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
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16.0,
          right: 16.0,
          top: 16.0,
        ),
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
            SizedBox(height: 16),
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
            SizedBox(height: 16),
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
            SizedBox(height: 16),
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
            SizedBox(height: 16),
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
            SizedBox(height: 16),
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
            SizedBox(height: 32),
            ElevatedButton(
              onPressed: addFoodToDatabase,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                minimumSize: Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                "Add to Database",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 20), // Extra padding at bottom for safety
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



  void fetchNutritionDetails(Map<String, dynamic> food) async {
    if (food['is_local'] == true) {
      setState(() {
        selectedFoodName = food['food_name'];
        originalCalories = double.parse(food['calories']);
        originalProtein = double.parse(food['protein']);
        originalFats = double.parse(food['fats']);
        originalCarbs = double.parse(food['carbs']);
        originalServingSize = food.containsKey('serving_size') ? double.parse(food['serving_size']) : 100.0;
      });

      // ?? Add spinner before showing sheet
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      await Future.delayed(Duration(milliseconds: 300));
      Navigator.of(context).pop(); // Remove spinner

      updateNutrition(originalServingSize!);
      showNutritionSheet();
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
                    List<Map<String, dynamic>> servingList = List<Map<String, dynamic>>.from(servingData);

                    // Use default serving if available
                    serving = servingList.firstWhere(
                          (s) => s['is_default'] == '1' || s['is_default'] == 1,
                      orElse: () => servingList.first,
                    );
                  } else {
                    serving = Map<String, dynamic>.from(servingData);
                  }


                  setState(() {
                    var calories = double.tryParse(serving['calories'].toString()) ?? 0.0;
                    var protein = double.tryParse(serving['protein'].toString()) ?? 0.0;
                    var fat = double.tryParse(serving['fat'].toString()) ?? 0.0;
                    var carbs = double.tryParse(serving['carbohydrate'].toString()) ?? 0.0;
                    var servingSize = double.tryParse(serving['metric_serving_amount'].toString()) ?? 100.0;

                    servingDescription = serving['serving_description']?.toString();

                    originalCalories = calories;
                    originalProtein = protein;
                    originalFats = fat;
                    originalCarbs = carbs;
                    originalServingSize = servingSize;

                    updateNutrition(servingSize);
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
    if (_isSheetOpen) return;
    _isSheetOpen = true;

    _servingsController.text = '1';
    _gramsController.text = originalServingSize!.toStringAsFixed(0);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;
        final inputBoxHeight = screenHeight * 0.065;
        final inputFontSize = screenWidth * 0.045;
        final buttonWidth = screenWidth * 0.15;
        final buttonHeight = inputBoxHeight;
        final buttonFontSize = screenWidth * 0.045;
        return WillPopScope(
          onWillPop: () async {
            _isSheetOpen = false;
            return true;
          },
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setModalState) {
              final calories = double.tryParse(selectedFood?['Calories'] ?? '0') ?? 0;
              final protein = double.tryParse(selectedFood?['Protein'] ?? '0') ?? 0;
              final fats = double.tryParse(selectedFood?['Fats'] ?? '0') ?? 0;
              final carbs = double.tryParse(selectedFood?['Carbs'] ?? '0') ?? 0;
              final totalMacros = protein + fats + carbs;

              // Use SingleChildScrollView and dynamic padding when grams or servings is focused
              final bool isInputFocused = _isGramsFocused || _isServingsFocused;
              return SingleChildScrollView(
                padding: EdgeInsets.only(
                  bottom: isInputFocused ? MediaQuery.of(context).viewInsets.bottom : 0,
                  top: isInputFocused ? 40 : 0,
                ),
                child: Container(
                  padding: EdgeInsets.all(screenWidth * 0.05),
                  decoration: BoxDecoration(
                    color: Color(0xFF1F1F1F),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(screenWidth * 0.05),
                      topRight: Radius.circular(screenWidth * 0.05),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                selectedFoodName ?? 'Selected Food',
                                style: TextStyle(color: Colors.white, fontSize: screenWidth * 0.065, fontWeight: FontWeight.bold),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close, color: Colors.white, size: screenWidth * 0.07),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      SizedBox(height: screenHeight * 0.025),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: _buildTextField(
                              servingDescription != null
                                  ? 'Servings ($servingDescription = ${originalServingSize?.toStringAsFixed(0)}g)'
                                  : 'Servings',

                              _servingsController,
                                  () {
                                final servings = double.tryParse(_servingsController.text) ?? 0;
                                final newGrams = (servings * originalServingSize!).toStringAsFixed(0);
                                _gramsController.text = newGrams;
                                updateNutrition(double.parse(newGrams));
                                setModalState(() {});
                              },
                              focusNode: _servingsFocusNode,
                              height: inputBoxHeight,
                              fontSize: inputFontSize,
                            ),
                          ),

                          SizedBox(width: screenWidth * 0.04),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        setModalState(() {
                                          _selectedUnit = 'g';
                                          double val = double.tryParse(_gramsController.text) ?? 0;
                                          if (_selectedUnit == 'oz') {
                                            val = val * 28.3;
                                          }
                                          _gramsController.text = val.toStringAsFixed(0);
                                          updateNutrition(val);
                                        });
                                      },
                                      child: Container(
                                        width: buttonWidth,
                                        height: buttonHeight,
                                        decoration: BoxDecoration(
                                          color: _selectedUnit == 'g' ? Colors.white : Color(0xFF232323),
                                          borderRadius: BorderRadius.circular(buttonHeight * 0.5),
                                          border: Border.all(color: Colors.grey[700]!, width: 1),
                                        ),
                                        child: Center(
                                          child: Text(
                                            'g',
                                            style: TextStyle(
                                              color: _selectedUnit == 'g' ? Colors.black : Colors.white,
                                              fontSize: buttonFontSize,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: screenWidth * 0.02),
                                    GestureDetector(
                                      onTap: () {
                                        setModalState(() {
                                          _selectedUnit = 'oz';
                                          double val = double.tryParse(_gramsController.text) ?? 0;
                                          if (_selectedUnit == 'g') {
                                            val = val / 28.3;
                                          }
                                          _gramsController.text = val.toStringAsFixed(1);
                                          updateNutrition(val * 28.3);
                                        });
                                      },
                                      child: Container(
                                        width: buttonWidth,
                                        height: buttonHeight,
                                        decoration: BoxDecoration(
                                          color: _selectedUnit == 'oz' ? Colors.white : Color(0xFF232323),
                                          borderRadius: BorderRadius.circular(buttonHeight * 0.5),
                                          border: Border.all(color: Colors.grey[700]!, width: 1),
                                        ),
                                        child: Center(
                                          child: Text(
                                            'oz',
                                            style: TextStyle(
                                              color: _selectedUnit == 'oz' ? Colors.black : Colors.white,
                                              fontSize: buttonFontSize,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: screenHeight * 0.01),
                                SizedBox(
                                  height: inputBoxHeight,
                                  child: TextField(
                                    controller: _gramsController,
                                    focusNode: _gramsFocusNode,
                                    style: TextStyle(color: Colors.white, fontSize: inputFontSize),
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: Color(0xFF333333),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(screenWidth * 0.025),
                                        borderSide: BorderSide.none,
                                      ),
                                      contentPadding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: inputBoxHeight * 0.25),
                                      suffixText: _selectedUnit,
                                      suffixStyle: TextStyle(
                                        color: Colors.grey[300],
                                        fontWeight: FontWeight.bold,
                                        fontSize: inputFontSize,
                                      ),
                                    ),
                                    onChanged: (value) {
                                      double val = double.tryParse(value) ?? 0;
                                      if (_selectedUnit == 'oz') {
                                        updateNutrition(val * 28.3);
                                      } else {
                                        updateNutrition(val);
                                      }
                                      setModalState(() {});
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: screenHeight * 0.025),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Nutritional Information (per 100g)',
                          style: TextStyle(color: Colors.grey, fontSize: screenWidth * 0.035),
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.012),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        childAspectRatio: 1.5,
                        mainAxisSpacing: screenWidth * 0.025,
                        crossAxisSpacing: screenWidth * 0.025,
                        children: [
                          _buildNutritionStatCircle('Calories', calories, 'kcal', Color(0xFFE91E63), calories / 2000, screenWidth),
                          _buildNutritionStatCircle('Protein', protein, 'g', Color(0xFF3F51B5), totalMacros > 0 ? protein / totalMacros : 0, screenWidth),
                          _buildNutritionStatCircle('Fats', fats, 'g', Color(0xFFFF9800), totalMacros > 0 ? fats / totalMacros : 0, screenWidth),
                          _buildNutritionStatCircle('Carbs', carbs, 'g', Color(0xFF4CAF50), totalMacros > 0 ? carbs / totalMacros : 0, screenWidth),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Center( // <-- changed from Align to Center
                          child: GestureDetector(
                            onTap: () async {
                              final url = Uri.parse('https://www.nal.usda.gov/fnic/dri-calculator/');
                              if (await canLaunchUrl(url)) {
                                await launchUrl(url, mode: LaunchMode.externalApplication);
                              }
                            },
                            child: Text(
                              'Based on USDA Dietary Guidelines',
                              style: TextStyle(
                                color: Colors.grey[300],
                                fontSize: screenWidth * 0.035,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.025),
                      ElevatedButton(
                        onPressed: () => logFood(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF424242),
                          minimumSize: Size(double.infinity, inputBoxHeight * 1.1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(screenWidth * 0.04),
                          ),
                        ),
                        child: Text("Log Food", style: TextStyle(color: Colors.white, fontSize: inputFontSize)),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    ).whenComplete(() {
      _isSheetOpen = false;
    });
  }

  Widget _buildTextField(String label, TextEditingController controller, VoidCallback onChanged, {FocusNode? focusNode, double? height, double? fontSize}) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey, fontSize: fontSize ?? screenWidth * 0.035)),
        SizedBox(height: 5),
        SizedBox(
          height: height ?? 48,
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            style: TextStyle(color: Colors.white, fontSize: fontSize ?? screenWidth * 0.045),
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              filled: true,
              fillColor: Color(0xFF333333),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(screenWidth * 0.025),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: (height ?? 48) * 0.25),
            ),
            onChanged: (value) => onChanged(),
          ),
        ),
      ],
    );
  }

  Widget _buildNutritionStatCircle(String name, double value, String unit, Color color, double progress, double screenWidth) {
    final circleSize = screenWidth * 0.16;
    final fontSize = screenWidth * 0.045;
    return Container(
      padding: EdgeInsets.all(screenWidth * 0.02),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: circleSize,
            height: circleSize,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: circleSize,
                  height: circleSize,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: circleSize * 0.08,
                    backgroundColor: Colors.grey.withOpacity(0.3),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        value.toStringAsFixed(name == 'Calories' ? 0 : 1),
                        style: TextStyle(color: Colors.white, fontSize: fontSize, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: screenWidth * 0.01),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text('$name ($unit)', style: TextStyle(color: Colors.grey, fontSize: fontSize * 0.8)),
          ),
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

    // Call the onReturn callback before popping
    if (widget.onReturn != null) {
      widget.onReturn!();
    }

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