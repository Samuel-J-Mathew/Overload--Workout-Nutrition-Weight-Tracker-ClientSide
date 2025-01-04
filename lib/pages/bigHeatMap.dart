import 'package:flutter/material.dart';

import '../models/heat_map.dart';

class BigHeatMap extends StatefulWidget {
  const BigHeatMap({Key? key}) : super(key: key);

  @override
  _BigHeatMapState createState() => _BigHeatMapState();
}

class _BigHeatMapState extends State<BigHeatMap> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        title: Text('Big Heat Map',style: TextStyle(
          color: Colors.white,
        ),),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Container(
        color: Colors.grey[900],
        child: Column(
          children: [
            const MyHeatMap(),
          ],
        ),
      ),
    );
  }
}
