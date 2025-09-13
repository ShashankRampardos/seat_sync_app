import 'package:flutter/material.dart';
import 'package:seat_sync/screens/seat_map.dart';

class TabsScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _TabsScreenState();
  }
}

class _TabsScreenState extends State<TabsScreen> {
  final int _selectedPageIndex = 0;
  final Widget _page = SeatMapScreen();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Seat Sync'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _page,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedPageIndex,
        onTap: (index) {
          setState(() {});
        },
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.chair), label: 'Seats'),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'Bookings',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'My'),
        ],
      ),
    );
  }
}
