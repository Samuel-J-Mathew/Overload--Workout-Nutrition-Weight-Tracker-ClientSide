import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'journalPage.dart';

class Jounral2 extends StatefulWidget {
  @override
  _Jounral2AppState createState() => _Jounral2AppState();
}

class _Jounral2AppState extends State<Jounral2> {
  int _selectedIndex = 0;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  String _selectedFilter = "This Week";
  List<Map<String, String>> _journalEntries = [];
  List<Map<String, String>> _filteredEntries = [];
  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _fetchJournalEntries();
  }

  void _fetchJournalEntries() {
    // Placeholder: Replace with database call to fetch journal entries
    setState(() {
      _journalEntries = [
        {"date": "2025-01-07", "entry": "Had a productive day at work!"},
        {"date": "2025-01-06", "entry": "Spent quality time with family."},
        {"date": "2025-01-01", "entry": "Set my goals for the new year!"},
      ];
      _applyFilter();
    });
  }

  void _applyFilter() {
    DateTime now = DateTime.now();
    setState(() {
      if (_selectedFilter == "This Week") {
        DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        DateTime endOfWeek = startOfWeek.add(Duration(days: 6));
        _filteredEntries = _journalEntries.where((entry) {
          DateTime entryDate = DateTime.parse(entry['date']!);
          return entryDate.isAfter(startOfWeek.subtract(Duration(days: 1))) &&
              entryDate.isBefore(endOfWeek.add(Duration(days: 1)));
        }).toList();
      } else if (_selectedFilter == "This Month") {
        _filteredEntries = _journalEntries.where((entry) {
          DateTime entryDate = DateTime.parse(entry['date']!);
          return entryDate.month == now.month && entryDate.year == now.year;
        }).toList();
      } else if (_selectedFilter == "This Year") {
        _filteredEntries = _journalEntries.where((entry) {
          DateTime entryDate = DateTime.parse(entry['date']!);
          return entryDate.year == now.year;
        }).toList();
      }
    });
  }

  static List<Widget> _widgetOptions = <Widget>[
    JournalPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: JournalPage(),
    );
  }
}
