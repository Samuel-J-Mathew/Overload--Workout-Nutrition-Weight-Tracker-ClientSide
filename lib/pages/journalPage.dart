import 'package:flutter/material.dart';

import '../models/heat_map_2.dart';

class JournalPage extends StatefulWidget {
  @override
  _JournalPageState createState() => _JournalPageState();
}

class _JournalPageState extends State<JournalPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  String _selectedFilter = "This Week";
  List<Map<String, String>> _journalEntries = [];
  List<Map<String, String>> _filteredEntries = [];

  final List<String> _prompts = [
    "What made you happy today?",
    "Describe a challenge you faced today.",
    "What are you grateful for?",
    "What did you learn today?",
    "How are you feeling right now?",
  ];

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
        _filteredEntries = _journalEntries
            .where((entry) {
          DateTime entryDate = DateTime.parse(entry['date']!);
          return entryDate.isAfter(startOfWeek.subtract(Duration(days: 1))) &&
              entryDate.isBefore(endOfWeek.add(Duration(days: 1)));
        })
            .toList();
      } else if (_selectedFilter == "This Month") {
        _filteredEntries = _journalEntries
            .where((entry) {
          DateTime entryDate = DateTime.parse(entry['date']!);
          return entryDate.month == now.month && entryDate.year == now.year;
        })
            .toList();
      } else if (_selectedFilter == "This Year") {
        _filteredEntries = _journalEntries
            .where((entry) {
          DateTime entryDate = DateTime.parse(entry['date']!);
          return entryDate.year == now.year;
        })
            .toList();
      }
    });
  }

  void _createJournalEntry() async {
    String? selectedPrompt = await showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text("Choose a Prompt"),
        children: _prompts
            .map((prompt) => SimpleDialogOption(
          onPressed: () => Navigator.pop(context, prompt),
          child: Text(prompt),
        ))
            .toList(),
      ),
    );

    if (selectedPrompt != null) {
      TextEditingController controller = TextEditingController();
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(selectedPrompt),
          content: TextField(
            controller: controller,
            maxLines: 10,
            decoration: InputDecoration(hintText: "Write your journal entry..."),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  setState(() {
                    _journalEntries.add({
                      "date": DateTime.now().toIso8601String().split('T').first,
                      "entry": controller.text,
                    });
                  });
                  _applyFilter();
                }
                Navigator.pop(context);
              },
              child: Text("Save"),
            ),
          ],
        ),
      );
    }
  }

  void _showFullEntry(String date, String entry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Journal Entry - $date"),
        content: SingleChildScrollView(
          child: Text(entry),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Close"),
          ),
        ],
      ),
    );
  }

  Widget _buildHeatMap() {
    // Replace this with your actual heatmap logic
    return Container(
      height: 200,
      child: Center(
        child: Text("30-Day Heat Map Placeholder"),
      ),
      color: Colors.grey[900],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Journal Entries", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),),
        centerTitle: true,
        backgroundColor: Colors.grey[900],
        iconTheme: IconThemeData(color: Colors.white),
      ),

      body: Column(

        children: [
          SizedBox(height: 10),
          Container(
            height: 50,
            width: 185,
            child: MyHeatMap2(),
          ),
          SizedBox(height: 15),

          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                DropdownButton<String>(
                  value: _selectedFilter,
                  items: ["This Week", "This Month", "This Year", ]
                      .map((filter) => DropdownMenuItem<String>(
                    value: filter,
                    child: Text(filter),
                  ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedFilter = value!;
                      _applyFilter();
                    });
                  },
                ),
                ElevatedButton(
                  onPressed: _createJournalEntry,
                  child: Text("Create Entry"),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredEntries.length,
              itemBuilder: (context, index) {
                var entry = _filteredEntries[index];
                return ListTile(
                  title: Text(
                    entry['entry']!.length > 50
                        ? entry['entry']!.substring(0, 50) + "..."
                        : entry['entry']!,
                    style: TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    entry['date']!,
                    style: TextStyle(color: Colors.grey),
                  ),
                  onTap: () => _showFullEntry(entry['date']!, entry['entry']!),
                );
              },
            ),

          ),

        ],

      ),
      backgroundColor: Colors.grey[850],
    );
  }
}
