import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:barcode_scan2/barcode_scan2.dart';

void main() {
  runApp(MaterialApp(
    home: TestExample(),
  ));
}

class TestExample extends StatefulWidget {
  @override
  _TestExampleState createState() => _TestExampleState();
}

class _TestExampleState extends State<TestExample> {
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _weightController = TextEditingController(); // Dynamic default serving size
  Map<String, dynamic> _nutritionData = {};
  String _productName = '';
  String _servingSize = '100'; // Fallback serving size

  void _searchFood(String query) async {
    var url = Uri.parse('https://world.openfoodfacts.org/api/v0/product/$query.json');
    var response = await http.get(
      url,
      headers: {
        "User-Agent": "YourAppName - Flutter - Version 1.0 - yourappwebsite.com"
      },
    );

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      if (data['status'] == 1 && data['product'] != null) {
        setState(() {
          _nutritionData = data['product']['nutriments'] ?? {};
          _productName = data['product']['product_name'] ?? 'Unknown Product';
          _servingSize = data['product']['serving_quantity'] ?? '100';
          _weightController.text = _servingSize; // Set default weight to serving size
        });
      } else {
        _showDialog('Product not found', 'The product does not exist in the database.');
      }
    } else {
      _showDialog('Error', 'Failed to retrieve data.');
    }
  }

  Future<void> _scanBarcode() async {
    var result = await BarcodeScanner.scan(options: ScanOptions(
      useCamera: -1, // default camera
      autoEnableFlash: false,
    ));

    if (result.type == ResultType.Barcode) {
      _controller.text = result.rawContent;
      _searchFood(result.rawContent);
    } else if (result.type == ResultType.Error) {
      _showDialog('Scan Error', result.rawContent);
    } else if (result.type == ResultType.Cancelled) {
      _showDialog('Scan Cancelled', 'You have cancelled the scan.');
    }
  }

  void _showDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: <Widget>[
          TextButton(
            child: Text('OK'),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }

  double _calculateNutrient(String nutrientKey) {
    double amountPer100g = 0.0;
    if (_nutritionData.containsKey(nutrientKey) && _nutritionData[nutrientKey] != null) {
      amountPer100g = double.tryParse(_nutritionData[nutrientKey].toString()) ?? 0.0;
    }
    double weight = double.tryParse(_weightController.text) ?? double.tryParse(_servingSize) ?? 100.0;
    return (amountPer100g / 100.0) * weight;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Open Food Facts Search'),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Enter or scan food barcode',
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: Icon(Icons.search),
                      onPressed: () => _searchFood(_controller.text),
                    ),
                    IconButton(
                      icon: Icon(Icons.camera_alt),
                      onPressed: _scanBarcode,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _weightController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Enter weight in grams (default is serving size)',
              ),
            ),
          ),
          Expanded(
            child: ListView(
              children: <Widget>[
                ListTile(
                  title: Text('Product Name'),
                  subtitle: Text(_productName),
                ),
                ListTile(
                  title: Text('Calories for specified weight'),
                  subtitle: Text('${_calculateNutrient('energy-kcal_100g').toStringAsFixed(2)} kcal'),
                ),
                ListTile(
                  title: Text('Protein for specified weight'),
                  subtitle: Text('${_calculateNutrient('proteins_100g').toStringAsFixed(2)} g'),
                ),
                ListTile(
                  title: Text('Carbs for specified weight'),
                  subtitle: Text('${_calculateNutrient('carbohydrates_100g').toStringAsFixed(2)} g'),
                ),
                ListTile(
                  title: Text('Fats for specified weight'),
                  subtitle: Text('${_calculateNutrient('fat_100g').toStringAsFixed(2)} g'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
