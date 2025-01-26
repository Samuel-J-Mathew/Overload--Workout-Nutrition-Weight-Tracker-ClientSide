import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String uid;

  DatabaseService({required this.uid});

  Future<void> addFoodLog(Map<String, dynamic> foodLog) async {
    await _db.collection('users').doc(uid).collection('food_logs').add(foodLog);
  }

  Stream<List<Map<String, dynamic>>> getFoodLogs() {
    return _db.collection('users').doc(uid).collection('food_logs').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => doc.data()).toList());
  }

// Similarly, create methods for weight logs, exercise logs, and step logs
}