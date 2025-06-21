import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

// Main Page displaying the list of check-in forms
class JournalPage extends StatefulWidget {
  const JournalPage({super.key});

  @override
  State<JournalPage> createState() => _JournalPageState();
}

class _JournalPageState extends State<JournalPage> {
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  Stream<QuerySnapshot<Map<String, dynamic>>> _getAssignedFormsStream() {
    if (_currentUser == null) {
      return const Stream.empty();
    }
    return FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUser!.uid)
        .collection('assignedForms')
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(25, 25, 25, 1),
      appBar: AppBar(
        title: const Text('Check-Ins', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color.fromRGBO(25, 25, 25, 1),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: _currentUser == null
          ? const Center(
          child: Text(
            "Please log in to see your check-ins.",
            style: TextStyle(color: Colors.white70),
          ))
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _getAssignedFormsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
                child: Text('Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red)));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
                child: Text('No assigned check-ins found.',
                    style: TextStyle(color: Colors.white70)));
          }

          final forms = snapshot.data!.docs;
          return ListView.builder(
            itemCount: forms.length,
            itemBuilder: (context, index) {
              final form = forms[index];
              return CheckInTile(form: form);
            },
          );
        },
      ),
    );
  }
}

// Tile for a single check-in form, showing its name and schedule completion
class CheckInTile extends StatefulWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> form;

  const CheckInTile({super.key, required this.form});

  @override
  State<CheckInTile> createState() => _CheckInTileState();
}

class _CheckInTileState extends State<CheckInTile> {
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  final Map<int, bool> _completionStatus = {};

  @override
  void initState() {
    super.initState();
    _fetchCompletionStatus();
  }

  Future<void> _fetchCompletionStatus() async {
    if (_currentUser == null) return;

    final today = DateTime.now();
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    final completedForms = await FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUser!.uid)
        .collection('CompletedForms')
        .where('formId', isEqualTo: widget.form.id)
        .where('submittedAt',
        isGreaterThanOrEqualTo: Timestamp.fromDate(startOfWeek))
        .where('submittedAt', isLessThanOrEqualTo: Timestamp.fromDate(endOfWeek))
        .get();

    for (var i = 1; i <= 7; i++) {
      _completionStatus[i] = false;
    }

    for (final doc in completedForms.docs) {
      final submittedAt = (doc['submittedAt'] as Timestamp).toDate();
      _completionStatus[submittedAt.weekday] = true;
    }

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final formName = widget.form.data()['formName'] as String? ?? 'Unnamed Form';
    final schedule = widget.form.data()['schedule'] as String? ?? 'Manual';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FillFormPage(form: widget.form),
          ),
        ).then((_) => _fetchCompletionStatus());
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: const Color.fromRGBO(40, 40, 40, 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(formName,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500)),
            ),
            Row(
              children: [
                ..._buildDayIndicators(schedule),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_ios,
                    color: Colors.white54, size: 16),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildDayIndicators(String schedule) {
    const dayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final today = DateTime.now();

    bool isDue(int weekday) {
      switch (schedule.toLowerCase()) {
        case 'daily':
          return true;
        case 'weekly':
          return weekday == DateTime.sunday; // Sunday
        case 'monthly':
          final assignedAt =
          (widget.form.data()['assignedAt'] as Timestamp?)?.toDate();
          return assignedAt != null && today.day == assignedAt.day;
        default: // Manual
          return false;
      }
    }

    return List.generate(7, (index) {
      final weekday = index + 1;
      final isCompleted = _completionStatus[weekday] ?? false;
      final bool isDueDay = isDue(weekday);

      // Determine background color
      Color getBackgroundColor() {
        if (isCompleted) {
          return Colors.blue; // Completed tasks are blue
        }
        if (isDueDay) {
          return Colors.white38; // Due tasks are highlighted
        }
        return Colors.transparent; // Default
      }

      // Determine text color
      Color getTextColor() {
        if (isCompleted || isDueDay) {
          return Colors.white; // Active text is white
        }
        return Colors.white38; // Inactive text is dim
      }

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 2.5),
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: getBackgroundColor(),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            dayLetters[index],
            style: TextStyle(
              color: getTextColor(),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      );
    });
  }
}

// Page for filling out a specific check-in form
class FillFormPage extends StatefulWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> form;

  const FillFormPage({super.key, required this.form});

  @override
  State<FillFormPage> createState() => _FillFormPageState();
}

class _FillFormPageState extends State<FillFormPage> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, dynamic> _answers = {};
  bool _isLoading = false;

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() {
        _isLoading = true;
      });

      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) throw Exception("User not logged in");

        final formName =
            widget.form.data()['formName'] as String? ?? 'Unnamed Form';

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('CompletedForms')
            .add({
          'formId': widget.form.id,
          'formName': formName,
          'submittedAt': Timestamp.now(),
          'answers': _answers,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Check-in submitted successfully!'),
                backgroundColor: Colors.green),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Failed to submit: $e'),
                backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final formName =
        widget.form.data()['formName'] as String? ?? 'Unnamed Form';
    final questions = List<Map<String, dynamic>>.from(
        widget.form.data()['questions'] ?? []);

    return Scaffold(
      backgroundColor: const Color.fromRGBO(25, 25, 25, 1),
      appBar: AppBar(
        title: Text(formName, style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color.fromRGBO(25, 25, 25, 1),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: questions.length,
                itemBuilder: (context, index) {
                  final question = questions[index];
                  return _buildQuestionWidget(question);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Submit',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionWidget(Map<String, dynamic> question) {
    final questionText = question['questionText'] as String? ?? '';
    final isRequired = question['required'] as bool? ?? false;
    final responseType =
    (question['responseType'] as String? ?? 'text').toLowerCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(40, 40, 40, 1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              text: questionText,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              children: [
                if (isRequired)
                  const TextSpan(
                    text: ' *',
                    style: TextStyle(color: Colors.blue, fontSize: 16),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildResponseWidget(questionText, responseType, isRequired),
        ],
      ),
    );
  }

  Widget _buildResponseWidget(
      String questionText, String responseType, bool isRequired) {
    switch (responseType) {
      case 'number':
      case 'text':
      case 'textarea':
        return TextFormField(
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Your answer here...',
            hintStyle: const TextStyle(color: Colors.white54),
            filled: true,
            fillColor: const Color.fromRGBO(25, 25, 25, 1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
          keyboardType: responseType == 'number'
              ? TextInputType.number
              : TextInputType.multiline,
          maxLines: responseType == 'textarea' ? 4 : 1,
          validator: (value) {
            if (isRequired && (value == null || value.isEmpty)) {
              return 'This field is required.';
            }
            return null;
          },
          onSaved: (value) {
            _answers[questionText] = value;
          },
        );
      case 'boolean':
        return SwitchListTile(
          title: const Text('Select', style: TextStyle(color: Colors.white)),
          value: _answers[questionText] ?? false,
          onChanged: (bool value) {
            setState(() {
              _answers[questionText] = value;
            });
          },
          activeColor: Colors.blue,
          contentPadding: EdgeInsets.zero,
        );
      case 'rating':
      case 'scale':
        final num currentValue = _answers[questionText] ?? 5.0;
        return Column(
          children: [
            Slider(
              value: currentValue.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              label: currentValue.toStringAsFixed(0),
              activeColor: Colors.blue,
              inactiveColor: Colors.white30,
              onChanged: (double value) {
                setState(() {
                  _answers[questionText] = value;
                });
              },
            ),
            Text(currentValue.toStringAsFixed(0),
                style: const TextStyle(color: Colors.white))
          ],
        );
      default:
        return Text('Unsupported question type: $responseType',
            style: const TextStyle(color: Colors.red));
    }
  }
}
