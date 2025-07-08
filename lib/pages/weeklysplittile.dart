import 'package:flutter/material.dart';

class WeeklySplitTile extends StatelessWidget {
  final List<int> muscleWorkloads;
  final int globalMaxTotalSets;

  const WeeklySplitTile({
    Key? key,
    required this.muscleWorkloads,
    required this.globalMaxTotalSets,
  }) : super(key: key);

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
    double maxAllowedHeight = 100; // max visual height
    int totalSets = sets.fold(0, (a, b) => a + b);

    double scalingFactor = globalMaxTotalSets > 0
        ? (maxAllowedHeight / globalMaxTotalSets)
        : 1;

    List<Widget> boxes = [];
    double bottomPosition = 0;

    for (int i = 0; i < sets.length; i++) {
      double boxHeight = sets[i] * scalingFactor;
      if (boxHeight > 0) {
        boxes.add(
          Positioned(
            bottom: bottomPosition,
            child: Container(
              width: 40,
              height: boxHeight,
              color: Colors.primaries[i % Colors.primaries.length],
              alignment: Alignment.center,
              child: Text(
                '${sets[i]} S',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        );
        bottomPosition += boxHeight;
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
            '$totalSets S',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
        SizedBox(height: 5),
        Container(
          width: 50,
          height: maxAllowedHeight,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: boxes,
          ),
        ),
      ],
    );
  }
}
