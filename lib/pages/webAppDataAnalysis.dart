import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class WebAppDataAnalysis extends StatefulWidget {
  @override
  _WebAppDataAnalysisState createState() => _WebAppDataAnalysisState();
}

class _WebAppDataAnalysisState extends State<WebAppDataAnalysis> {
  final TextEditingController _foodController = TextEditingController();
  final TextEditingController _gramsController = TextEditingController();
  List<dynamic> _foods = [];
  String _result = '';

  Future<void> fetchNutrients(String foodName) async {
    const apiUrl = 'https://trackapi.nutritionix.com/v2/natural/nutrients';
    try {
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
        final data = jsonDecode(response.body);
        setState(() {
          _foods = data['foods'];
          updateCalories();
        });
      } else {
        setState(() {
          _result = 'Error fetching nutrition data: ${response.body}';
        });
      }
    } catch (e) {
      setState(() {
        _result = 'Failed to load nutrition data: $e';
      });
    }
  }

  void updateCalories() {
    if (_foods.isNotEmpty && _gramsController.text.isNotEmpty) {
      // Parsing the grams input safely, ensuring it is treated as a double.
      double grams = double.tryParse(_gramsController.text) ?? 100.0; // Ensuring default is also a double.

      setState(() {
        _result = _foods.map((food) {
          // Ensure all numeric values are treated as double for consistent arithmetic operations.
          double originalGrams = (food['serving_weight_grams'] as num).toDouble() ?? 100.0;
          double caloriesPerGram = (food['nf_calories'] as num).toDouble() / originalGrams;
          double adjustedCalories = caloriesPerGram * grams;

          return "${food['food_name']} - ${adjustedCalories.toStringAsFixed(2)} calories for $grams g";
        }).join("\n");
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Calorie Tracker'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _foodController,
              decoration: InputDecoration(
                labelText: 'Enter a food item',
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () => fetchNutrients(_foodController.text),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _gramsController,
              decoration: InputDecoration(
                labelText: 'Enter grams',
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) => updateCalories(),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(_result.isEmpty ? 'Enter a food item and grams to get started.' : _result),
            ),
          ),
        ],
      ),
    );
  }
}
