import 'package:flutter/material.dart';

class WeeklySplitTile extends StatelessWidget {
  final List<int> muscleWorkloads;

  const WeeklySplitTile({Key? key, required this.muscleWorkloads}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(

      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        buildStackedBoxesWithCircle(muscleWorkloads)
      ],
    );
  }

  Widget buildStackedBoxesWithCircle(List<int> sets) {
    double maxBoxHeight = 100; // Max height for the largest set count
    double heightPerSet = maxBoxHeight / 10; // Calculate height per set
    List<Widget> boxes = [];
    double totalHeight = 0;

    // Calculate total height for all muscle groups to set the constraints box
    for (int i = 0; i < sets.length; i++) {
      totalHeight += sets[i] * heightPerSet;
    }

    double bottomPosition = 0; // Start positioning from the bottom of the stack
    int totalSets = 0; // Calculate total sets for the day

    for (int i = 0; i < sets.length; i++) {
      double boxHeight = sets[i] * heightPerSet;
      totalSets += sets[i]; // Sum of sets for the total sets indicator
      if (boxHeight > 0) { // Only add boxes for non-zero sets
        boxes.add(
          Positioned(
            bottom: bottomPosition, // Position at the current bottom
            child: Container(
              width: 40, // Fixed width for each box
              height: boxHeight, // Variable height based on the sets
              color: Colors.primaries[i % Colors.primaries.length], // Cycle through predefined colors
              alignment: Alignment.center,
              child: Text(
                '${sets[i]} S', // Display number of sets
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        );
        bottomPosition += boxHeight; // Move the position for the next box
      }
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 30,
          height: 15,
          decoration: BoxDecoration(
            color: Colors.green[700],
            borderRadius: BorderRadius.circular(5),
          ),
          alignment: Alignment.center,
          child: Text(
            '$totalSets S', // Display total sets on top
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
        SizedBox(height: 5),
        Container(
          width: 50, // Adjust width if needed
          height: totalHeight, // Total height of all boxes
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: boxes,
          ),
        ),
      ],
    );
  }
}
