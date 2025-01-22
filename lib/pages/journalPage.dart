import 'package:flutter/material.dart';


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
  List<Map<String, dynamic>> categories = [
    {
      'title': 'Productivity',
      'prompts': [
        'Think back to this time last year, how did you feel?',
        'What are your main goals today?',
      ],
    },
    {
      'title': 'Happiness',
      'prompts': [
        'What made you smile today?',
        'Name three things you are grateful for today.',
      ],
    },
    {
      'title': 'Self-Discovery',
      'prompts': [
        'What is one thing you discovered about yourself today?',
        'Describe a recent situation that made you proud of yourself.',
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Journaling', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
      ),
      body: ListView.builder(
        itemCount: categories.length,
        itemBuilder: (context, index) {
          var category = categories[index];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  category['title'],
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: category['prompts'].length,
                  itemBuilder: (context, idx) {
                    return GestureDetector(
                      onTap: () {
                        _createJournalEntry(category['prompts'][idx]);
                      },
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.8,
                        margin: EdgeInsets.symmetric(horizontal: 8),
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[850],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            category['prompts'][idx],
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _createJournalEntry(String prompt) {
    TextEditingController _entryController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(prompt, style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        content: TextField(
          controller: _entryController,
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "Write your journal entry here...",
            hintStyle: TextStyle(color: Colors.white70),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.amber),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.amber),
            ),
          ),
          maxLines: null,
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (_entryController.text.isNotEmpty) {
                setState(() {
                  _journalEntries.add({
                    "date": DateTime.now().toIso8601String().split('T').first,
                    "entry": _entryController.text,
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

class JourneyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Journey', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
      ),
      body: Center(
        child: Text(
          'Implement the Journey view here',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
