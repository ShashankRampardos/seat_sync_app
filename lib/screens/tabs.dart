import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:seat_sync_v2/screens/booking.dart';
import 'package:seat_sync_v2/screens/profile.dart';
import 'package:seat_sync_v2/screens/seat_map.dart';

class TabsScreen extends StatefulWidget {
  const TabsScreen({super.key});

  @override
  State<StatefulWidget> createState() {
    return _TabsScreenState();
  }
}

class _TabsScreenState extends State<TabsScreen> {
  int _selectedPageIndex = 0;
  String _profileName = "profileName";
  final List<String> _titles = ['Seat Map', 'Bookings', 'My Profile'];
  final List<Widget> _page = [
    SeatMapScreen(),
    BookingScreen(),
    ProfileScreen(),
  ];

  void _initializeProfile() async {
    var uid = FirebaseAuth.instance.currentUser!.uid;

    var snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    setState(() {
      _profileName = snapshot['username'];
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedPageIndex == 2 &&
        FirebaseAuth.instance.currentUser != null &&
        _profileName == "profileName") {
      _initializeProfile();
    }
    return Scaffold(
      appBar: _selectedPageIndex != 2
          ? AppBar(
              title: Text(_titles[_selectedPageIndex]),
              backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            )
          : AppBar(
              toolbarHeight: 150,
              backgroundColor: Theme.of(context).colorScheme.inversePrimary,
              actions: [
                Expanded(
                  child: Stack(
                    children: [
                      // Settings icon top-right
                      Align(
                        alignment: Alignment.topRight,
                        child: IconButton(
                          onPressed: () {},
                          icon: Icon(Icons.settings),
                        ),
                      ),
                      // Person icon center-right
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundImage: AssetImage(
                                'assets/profile_image.png',
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              _profileName,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
      body: _page[_selectedPageIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedPageIndex,
        onTap: (index) {
          setState(() {
            _selectedPageIndex = index;
          });
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
