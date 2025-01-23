import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import '../models/JournalProvider.dart';

class JournalPage extends StatefulWidget {
  @override
  _JournalPageState createState() => _JournalPageState();
}

class _JournalPageState extends State<JournalPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  String _selectedFilter = "This Week";

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
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
      backgroundColor: Color.fromRGBO(25, 25, 25, 1),
      appBar: AppBar(
        title: Text('Journaling', style: TextStyle(color: Colors.white)),
        backgroundColor: Color.fromRGBO(25, 25, 25, 1),
        iconTheme: IconThemeData(color: Colors.white),
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
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold),
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
                          color: Color.fromRGBO(40, 40, 40, 1),
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
        backgroundColor: Color.fromRGBO(40, 40, 40, 1),
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
            onPressed: () async {
              if (_entryController.text.isNotEmpty) {
                await Provider.of<JournalProvider>(context, listen: false)
                    .addJournalEntry({
                  "date": DateTime.now().toIso8601String().split('T').first,
                  "entry": _entryController.text,
                });
                Navigator.pop(context);
              }
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
      backgroundColor: Color.fromRGBO(25, 25, 25, 1),
      appBar: AppBar(
        title: Text('Journey', style: TextStyle(color: Colors.white)),
        backgroundColor: Color.fromRGBO(25, 25, 25, 1),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Consumer<JournalProvider>(
        builder: (context, journalProvider, child) {
          var journalEntries = journalProvider.journalEntries;
          return ListView.builder(
            itemCount: journalEntries.length,
            itemBuilder: (context, index) {
              var entry = journalEntries[index];
              return ListTile(
                title:
                Text(entry['date']!, style: TextStyle(color: Colors.white)),
                subtitle: Text(entry['entry']!,
                    style: TextStyle(color: Colors.white70)),
              );
            },
          );
        },
      ),
    );
  }
}
