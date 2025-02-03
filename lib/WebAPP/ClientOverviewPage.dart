import 'package:flutter/material.dart';
import 'TrainingPage.dart';
import 'NutritionPage.dart';
import 'MetricsPage.dart';

class ClientOverviewPage extends StatelessWidget {
  final String clientId;
  final String clientName;
  final String clientEmail;

  ClientOverviewPage(
      {Key? key,
      required this.clientId,
      required this.clientName,
      required this.clientEmail})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(clientName),
          backgroundColor: const Color.fromARGB(255, 255, 255, 255),
          bottom: TabBar(
            tabs: [
              Tab(text: "Overview"),
              Tab(text: "Training"),
              Tab(text: "Nutrition"),
              Tab(text: "Metrics"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildOverviewTab(),
            TrainingPage(),
            NutritionPage(),
            MetricsPage(),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text("Name: $clientName", style: TextStyle(fontSize: 20)),
          SizedBox(height: 10),
          Text("Email: $clientEmail", style: TextStyle(fontSize: 20)),
          SizedBox(height: 20),
          Text("UID: $clientId",
              style: TextStyle(fontSize: 16, color: Colors.grey)),
        ],
      ),
    );
  }
}
