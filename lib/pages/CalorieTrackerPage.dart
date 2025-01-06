import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class CalorieTrackerPage extends StatefulWidget {
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
    selectedFoodName = foodName; // Store the selected food name
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
        originalServingSize = (data['foods'][0]['serving_weight_grams'] as num?)?.toDouble() ?? 100;  // Default to 100g if not specified
        _gramController.text = originalServingSize.toString();
        updateNutrition(originalServingSize!);
      });
    }
  }


  void updateNutrition(double grams) {
    setState(() {
      selectedFood = {
        'Calories': (originalCalories! / originalServingSize! * grams).toStringAsFixed(0),
        'Protein': (originalProtein! / originalServingSize! * grams).toStringAsFixed(2) + 'g',
        'Fats': (originalFats! / originalServingSize! * grams).toStringAsFixed(2) + 'g',
        'Carbs': (originalCarbs! / originalServingSize! * grams).toStringAsFixed(2) + 'g',
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Calorie Tracker"),
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: EdgeInsets.all(16.0),
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Enter a food item',
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () => fetchFoodInfo(_controller.text),
                ),
              ),
              onChanged: (value) => fetchFoodInfo(value),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _suggestions.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_suggestions[index]['food_name']),
                  onTap: () => fetchNutritionDetails(_suggestions[index]['food_name']),
                );
              },
            ),
          ),
          if (selectedFood != null) ...[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _gramController,
                decoration: InputDecoration(
                  labelText: 'Grams',
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) => updateNutrition(double.tryParse(value) ?? originalServingSize!),
              ),
            ),
            Text(
              "${selectedFoodName ?? 'Selected Food'} - ${_gramController.text}g",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              'Calories: ${selectedFood!['Calories']} kcal',
              style: TextStyle(fontSize: 16),
            ),
            Text(
              'Protein: ${selectedFood!['Protein']}',
              style: TextStyle(fontSize: 16),
            ),
            Text(
              'Fats: ${selectedFood!['Fats']}',
              style: TextStyle(fontSize: 16),
            ),
            Text(
              'Carbs: ${selectedFood!['Carbs']}',
              style: TextStyle(fontSize: 16),
            ),
          ]
        ],
      ),
    );
  }
}
