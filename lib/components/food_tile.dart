import 'package:flutter/material.dart';

class FoodTile extends StatelessWidget {
  final String foodName;
  final String calories;
  final String protein;
  final String carbs;
  final String fats;
  final bool isCompleted;
  final VoidCallback onDelete;
  final bool isSelected;
  final VoidCallback? onTap;

  const FoodTile({
    super.key,
    required this.foodName,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
    required this.isCompleted,
    required this.onDelete,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final tileHeight = screenWidth * 0.15; // Responsive height
    final iconSize = screenWidth * 0.055;
    final fontSizeTitle = screenWidth * 0.042;
    final fontSizeSubtitle = screenWidth * 0.035;
    return Padding(
      padding: EdgeInsets.only(bottom: screenWidth * 0.03),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: tileHeight.clamp(44.0, 70.0),
          padding: EdgeInsets.symmetric(vertical: screenWidth * 0.02, horizontal: screenWidth * 0.04),
          decoration: BoxDecoration(
            color: isSelected ? Color.fromRGBO(40, 60, 120, 0.4) : Color.fromRGBO(31, 31, 31, 1),
            borderRadius: BorderRadius.circular(screenWidth * 0.04),
            border: isSelected ? Border.all(color: Colors.blue, width: 2) : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    if (isSelected)
                      Icon(Icons.check_circle, color: Colors.blue, size: iconSize),
                    if (!isSelected)
                      SizedBox(width: iconSize),
                    SizedBox(width: screenWidth * 0.02),
                    Icon(Icons.restaurant, size: iconSize),
                    SizedBox(width: screenWidth * 0.07),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                foodName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: fontSizeTitle.clamp(13.0, 18.0),
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '$calories cal  $protein P  $fats F  $carbs C',
                              style: TextStyle(
                                fontSize: fontSizeSubtitle.clamp(11.0, 15.0),
                                color: Colors.grey[400],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.delete, color: Colors.white, size: iconSize),
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
