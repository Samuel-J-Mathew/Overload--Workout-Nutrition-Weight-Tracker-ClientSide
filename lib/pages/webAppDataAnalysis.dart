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
  String _result = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('USDA FoodData Central API Test'),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _foodController,
              decoration: InputDecoration(
                labelText: 'Enter Food Name',
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () {
                    if (_foodController.text.isNotEmpty) {
                      fetchNutrients(_foodController.text);
                    }
                  },
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _gramsController,
              decoration: InputDecoration(
                labelText: 'Enter Serving Size in Grams',
              ),
              keyboardType: TextInputType.number,
            ),
          ),
          Expanded(
            child: Center(
              child: Text(_result.isEmpty ? 'Search results will appear here' : _result),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> fetchNutrients(String foodName) async {
    String apiKey = '24V4GrHFYLOgDagrASb3VTRg8CrbzQVAu4Ew42wD';
    final Uri uri = Uri.parse('https://api.nal.usda.gov/fdc/v1/foods/search?api_key=$apiKey&query=$foodName');

    final http.Response response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['foods'] != null && data['foods'].isNotEmpty) {
        final firstFood = data['foods'][0];
        double grams = double.tryParse(_gramsController.text) ?? 100.0;
        double factor = grams / 100.0;

        _result = "Food: ${firstFood['description']}\n" +
          "Calories: ${firstFood['foodNutrients'].firstWhere((nutrient) => nutrient['nutrientName'] == 'Energy')['value'] * factor} kcal\n" +
          "Protein: ${firstFood['foodNutrients'].firstWhere((nutrient) => nutrient['nutrientName'] == 'Protein')['value'] * factor} g\n" +
          "Fat: ${firstFood['foodNutrients'].firstWhere((nutrient) => nutrient['nutrientName'] == 'Total lipid (fat)')['value'] * factor} g\n" +
          "Carbs: ${firstFood['foodNutrients'].firstWhere((nutrient) => nutrient['nutrientName'] == 'Carbohydrate, by difference')['value'] * factor} g";
      } else {
        _result = "No foods found in response";
      }
    } else {
      _result = 'Error fetching data: ${response.statusCode}\n${response.body}';
    }

    setState(() {});
  }
}
