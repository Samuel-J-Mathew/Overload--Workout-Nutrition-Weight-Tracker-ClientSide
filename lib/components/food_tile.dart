import 'package:flutter/material.dart';

class FoodTile extends StatelessWidget {
  final String foodName;
  final String calories;
  final String protein;
  final String carbs;
  final String fats;
  final bool isCompleted;
  final VoidCallback onDelete; // Callback for delete action

  const FoodTile({
    super.key,
    required this.foodName,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
    required this.isCompleted,
    required this.onDelete, // Accept the onDelete callback
  });

  @override
  Widget build(BuildContext context) {

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Container(
        height: 65,
        //padding: EdgeInsets.all(16),
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Color.fromRGBO(31, 31, 31, 1),
          borderRadius: BorderRadius.circular(16),
        ),

        child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [

              Row(children: [
                SizedBox(width: 15,),
                Icon(Icons.restaurant),
                SizedBox(
                  width:30 ,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    //title
                    Text(foodName,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.white
                      ),),
                    SizedBox(
                      height: 0,
                    ),
                    Text('$calories cal  $protein P  $fats F  $carbs C',
                        style: TextStyle(
                          fontWeight: FontWeight.normal,
                          fontSize: 15,
                          color: Colors.grey[400],
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
