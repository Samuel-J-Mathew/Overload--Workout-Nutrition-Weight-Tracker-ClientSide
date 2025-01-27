import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class DataAnalysisPage extends StatefulWidget {
  @override
  _DataAnalysisPageState createState() => _DataAnalysisPageState();
}

class _DataAnalysisPageState extends State<DataAnalysisPage> {
  final TextEditingController _emailController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, dynamic> _userData = {};
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Data Analysis"),
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Enter Email',
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () => _fetchUserData(_emailController.text),
                ),
              ),
            ),
            SizedBox(height: 20),
            _isLoading
                ? CircularProgressIndicator()
                : _userData.isEmpty
                ? Text("No data available or user not found.")
                : _buildDataDisplay(),
          ],
        ),
      ),
    );
  }

  Widget _buildDataDisplay() {
    return Column(
      children: [
        if (_userData.containsKey('weightLogs'))
          Text("Weight Logs: ${_userData['weightLogs'].toString()}"),
        if (_userData.containsKey('foodLogs'))
          Text("Food Logs: ${_userData['foodLogs'].toString()}"),
        if (_userData.containsKey('workoutLogs'))
          Text("Workout Logs: ${_userData['workoutLogs'].toString()}"),
        if (_userData.containsKey('stepLogs'))
          Text("Step Logs: ${_userData['stepLogs'].toString()}"),
      ],
    );
  }

  Future<void> _fetchUserData(String email) async {
    setState(() => _isLoading = true);
    String? userId = await _getUserIdByEmail(email);
    if (userId == null) {
      setState(() {
        _isLoading = false;
        _userData = {};
      });
      return;
    }

    DateTime now = DateTime.now();
    DateTime startOfWeek = DateTime(now.year, now.month, now.day - now.weekday + 1);
    DateTime endOfWeek = startOfWeek.add(Duration(days: 6));

    var userData = {
      'weightLogs': await fetchLogs(userId, startOfWeek, endOfWeek, 'weightLogs'),
      'foodLogs': await fetchLogs(userId, startOfWeek, endOfWeek, 'foods', subCollection: 'entries'),
      'workoutLogs': await fetchLogs(userId, startOfWeek, endOfWeek, 'workouts', subCollection: 'exercises'),
      'stepLogs': await fetchLogs(userId, startOfWeek, endOfWeek, 'steps'),
    };
    setState(() {
      _userData = userData;
      _isLoading = false;
    });
  }

  Future<String?> _getUserIdByEmail(String email) async {
    var usersCollection = _firestore.collection('users');
    var querySnapshot = await usersCollection.where('email', isEqualTo: email).get();
    if (querySnapshot.docs.isNotEmpty) {
      return querySnapshot.docs.first.id;
    }
    return null;
  }

  Future<List<dynamic>> fetchLogs(String userId, DateTime start, DateTime end, String collection, {String subCollection = ''}) async {
    var collectionRef = _firestore.collection('users').doc(userId).collection(collection);

    List<dynamic> allLogs = [];
    // Asynchronously fetch logs for each day within the range
    for (var date = start; date.isBefore(end.add(Duration(days: 1))); date = date.add(Duration(days: 1))) {
      var formattedDate = DateFormat('yyyyMMdd').format(date);
      if (subCollection.isNotEmpty) {
        // Fetch from sub-collection if specified
        var dayDoc = await collectionRef.doc(formattedDate).collection(subCollection).get();
        dayDoc.docs.forEach((doc) {
          var data = doc.data();
          data['date'] = date; // Append the date to each log for reference
          allLogs.add(data);
        });
      } else {
        // Fetch directly from the document
        var doc = await collectionRef.doc(formattedDate).get();
        if (doc.exists) {
          var data = doc.data() as Map<String, dynamic>;
          data['date'] = date; // Append the date to each log for reference
          allLogs.add(data);
        }
      }
    }
    return allLogs;
  }

}
