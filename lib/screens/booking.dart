import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class BookingScreen extends StatelessWidget {
  BookingScreen({super.key});
  final _auth = FirebaseAuth.instance;
  @override
  Widget build(context) {
    return Center(
      child: _auth.currentUser == null
          ? Text(
              'Please login first',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            )
          : Text(
              '🛠️ Bookings Screen Coming Soon',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
    );
  }
}
