import 'package:flutter/material.dart';

class SeatMapScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _SeatMapScreenState();
}

class _SeatMapScreenState extends State<SeatMapScreen> {
  final int rows = 5;
  final int cols = 4;

  late List<Color> cellColors;

  @override
  void initState() {
    super.initState();
    cellColors = List.generate(rows * cols, (index) => Colors.grey); // default
  }

  void changeColor(int index, Color color) {
    setState(() {
      cellColors[index] = color;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            childAspectRatio: 1, // square cells
            crossAxisSpacing: 5,
            mainAxisSpacing: 5,
          ),
          itemCount: rows * cols,
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () => changeColor(index, Colors.green),
              child: Container(
                decoration: BoxDecoration(
                  color: cellColors[index],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.black, width: 0.5),
                ),
                child: Center(
                  child: Text(
                    'Seat ${index + 1}',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
