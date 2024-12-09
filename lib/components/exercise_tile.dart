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

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Container(
        padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
        Row(children: [
          Icon(Icons.favorite),
          SizedBox(
            width:30 ,
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              //title
              Text(exerciseName,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.white
                ),),
              SizedBox(
                height: 1,
              ),
              Text('$sets x $reps x $weight lbs',
                  style: TextStyle(
                      fontWeight: FontWeight.normal,
                      fontSize: 15,
                      color: Colors.white
                  )
              )
            ],
          ),
        ],
        ),
      IconButton(
      icon: const Icon(Icons.delete),
      onPressed: onDelete, // Use the onDelete callback when pressed
      color: Colors.white,
      ),
      ]),
      ),
    );
  }
}
