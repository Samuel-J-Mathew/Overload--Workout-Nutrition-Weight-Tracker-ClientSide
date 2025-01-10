import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:gymapp/data/FoodData.dart';
import 'FoodLogPage.dart';

class CalorieTrackerPage extends StatefulWidget {
  final DateTime selectedDate;

  CalorieTrackerPage({required this.selectedDate});

  @override
  _CalorieTrackerPageState createState() => _CalorieTrackerPageState();
}

class _CalorieTrackerPageState extends State<CalorieTrackerPage> {
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _gramController = TextEditingController();
  List<dynamic> _suggestions = [];
  Map<String, dynamic>? selectedFood;
  double? originalCalories, originalProtein, originalFats, originalCarbs, originalServingSize;
  String? selectedFoodName;

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

    if (response.statusCode == 200) {
      final results = jsonDecode(response.body);
      setState(() {
        _suggestions = results['common'];
      });
    } else {
      setState(() {
        _suggestions = [];
      });
    }
  }

  void fetchNutritionDetails(String foodName) async {
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
        originalServingSize = (data['foods'][0]['serving_weight_grams'] as num?)?.toDouble() ?? 100;
        _gramController.text = originalServingSize?.toString() ?? '100';
        updateNutrition(originalServingSize ?? 100);
        showNutritionSheet();
      });
    } else {
      showErrorDialog();
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
                              labelStyle: TextStyle(
                                  color: Colors.white, fontWeight: FontWeight.bold // Sets the color of the label when it is not focused
                              ),
                              enabledBorder: OutlineInputBorder( // Use OutlineInputBorder for a full rectangle border
                                borderSide: BorderSide(color: Colors.white), // Sets the color of the border when the field is not focused
                              ),
                              focusedBorder: OutlineInputBorder( // Use OutlineInputBorder for a full rectangle border
                                borderSide: BorderSide(color: Colors.white, width: 2.0), // Sets the color of the border when the field is focused
                              ),
                              fillColor: Colors.transparent, // Ensures the background is transparent
                              filled: true,
                            ),
                            style: TextStyle(
                              color: Colors.white, // Sets the color of the text being entered
                            ),
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
                        Center(child: Column(
                          mainAxisSize: MainAxisSize.min, // Use min to fit content size
                          children: [
                            SizedBox(height: 10),
                            Text(
                              "${selectedFoodName ?? 'Selected Food'} - ${_gramController.text}g",
                              style: TextStyle(color: Colors.white,fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Calories: ${selectedFood!['Calories']} ',
                              style: TextStyle(color: Colors.white,fontSize: 16),
                            ),
                            Text(
                              'Protein: ${selectedFood!['Protein']}',
                              style: TextStyle(color: Colors.white,fontSize: 16),
                            ),
                            Text(
                              'Fats: ${selectedFood!['Fats']}',
                              style: TextStyle(color: Colors.white,fontSize: 16),
                            ),
                            Text(
                              'Carbs: ${selectedFood!['Carbs']}',
                              style: TextStyle(color: Colors.white,fontSize: 16),
                            ),
                            SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: () => logFood(),
                              child: Text("Log Food"),
                            ),
                          ],

                        )),

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
    // Then, notify the parent ExerciseLogPage to switch to FoodLogPage
    //context.findAncestorStateOfType<_ExerciseLogPageState>()?._onItemTapped(2);
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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        title: Text("Calorie Tracker", style: TextStyle(color: Colors.white)),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Container(
        color: Colors.grey[900],
        child: Column(
          children: <Widget>[
            Padding(
              padding: EdgeInsets.all(16.0),
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  labelText: 'Enter a food item', labelStyle: TextStyle(
                  color: Colors.grey[400], // Sets the color of the label to white
                ),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.search, color: Colors.white),
                    onPressed: () => fetchFoodInfo(_controller.text),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(color: Colors.grey.shade300), // Optional: sets the border color when field is not focused
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(color: Colors.grey.shade300), // Optional: sets the border color when field is focused
                  ),
                ),
                style: TextStyle(
                  color: Colors.white, // Sets the color of the text being entered
                ),
                onChanged: (value) => fetchFoodInfo(value),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _suggestions.length,
                itemBuilder: (context, index) {
                  return Column(
                    children: [
                      ListTile(
                        title: Text(
                          _suggestions[index]['food_name'],
                          style: TextStyle(color: Colors.white), // Sets the text color to white
                        ),
                        onTap: () => fetchNutritionDetails(_suggestions[index]['food_name']),
                      ),
                      Divider(color: Colors.grey[600]), // Adds a white divider line under each ListTile
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
