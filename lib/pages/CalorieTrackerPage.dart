import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class CalorieTrackerPage extends StatefulWidget {
  @override
  _CalorieTrackerPageState createState() => _CalorieTrackerPageState();
}

class _CalorieTrackerPageState extends State<CalorieTrackerPage> {
  final TextEditingController _controller = TextEditingController();
  String? nutritionInfo;

  void fetchFoodInfo(String query) async {
    if (query.isEmpty) {
      setState(() {
        nutritionInfo = null;
      });
      return;
    }

    final response = await http.get(
        Uri.parse('https://yourserver.com/search-food?query=$query'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer your_token_here'
        }
    );

    if (response.statusCode == 200) {
      setState(() {
        nutritionInfo = response.body; // assuming response is already well-formatted
      });
    } else {
      setState(() {
        nutritionInfo = "Failed to fetch data";
      });
    }
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
            ),
          ),
          Expanded(
            child: nutritionInfo == null ? Center(child: Text("Search for a food item")) : SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(nutritionInfo!, style: TextStyle(fontSize: 16)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
