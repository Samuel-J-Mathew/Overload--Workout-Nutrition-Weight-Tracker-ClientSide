import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class JournalProvider with ChangeNotifier {
  List<Map<String, String>> _journalEntries = [];

  List<Map<String, String>> get journalEntries => _journalEntries;

  Future<void> fetchJournalEntries() async {
    var box = await Hive.openBox<Map>('journalBox');
    _journalEntries = box.values.map((entry) {
      return Map<String, String>.from(entry);
    }).toList();
    notifyListeners();
  }

  Future<void> addJournalEntry(Map<String, String> entry) async {
    var box = await Hive.openBox<Map>('journalBox');
    await box.add(entry);
    await fetchJournalEntries();
  }

  Map<DateTime, int> getJournalDatesForHeatMap() {
    Map<DateTime, int> heatMapData = {};
    for (var entry in _journalEntries) {
      DateTime date = DateTime.parse(entry['date']!);
      DateTime normalizedDate = DateTime(date.year, date.month, date.day);
      if (heatMapData.containsKey(normalizedDate)) {
        heatMapData[normalizedDate] = heatMapData[normalizedDate]! + 1;
      } else {
        heatMapData[normalizedDate] = 1;
      }
    }
    return heatMapData;
  }
}
