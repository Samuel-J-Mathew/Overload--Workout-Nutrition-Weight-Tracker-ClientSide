import 'package:flutter/material.dart';

class ExerciseTile extends StatelessWidget {
  final String exerciseName;
  final String weight;
  final String reps;
  final String sets;
  final bool isCompleted;
  final VoidCallback onDelete; // Callback for delete action

  const ExerciseTile({
    super.key,
    required this.exerciseName,
    required this.weight,
    required this.reps,
    required this.sets,
    required this.isCompleted,
    required this.onDelete, // Accept the onDelete callback
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[300],
      child: ListTile(
        title: Text(exerciseName),
        subtitle: Row(
          children: [
            Chip(label: Text("$sets sets")),
            Chip(label: Text("$reps reps")),
            Chip(label: Text("$weight lbs")),
          ],
        ),
        trailing: IconButton(
          icon: Icon(Icons.delete),
          onPressed: onDelete, // Use the onDelete callback when pressed
          color: Colors.red,
        ),
      ),
    );
  }
}
