import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
// If you want date formatting, add intl package, otherwise we use basic toString
// import 'package:intl/intl.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _auth = FirebaseAuth.instance;

  // List to store the data
  List<Map<String, dynamic>> _seatHistory = [];
  // Variable to show loading spinner
  bool _isLoading = true;

  Future<void> getSeatHistory() async {
    final user = _auth.currentUser;

    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      QuerySnapshot query = await FirebaseFirestore.instance
          .collection('seat_info')
          .where(
            'user_id',
            isEqualTo: user.uid,
          ) // FIX: Use .uid (String), not the User object
          .get();

      final List<Map<String, dynamic>> loadedData = [];

      for (final doc in query.docs) {
        loadedData.add(doc.data() as Map<String, dynamic>);
      }

      // UPDATE UI: We must call setState to trigger a rebuild
      if (mounted) {
        setState(() {
          _seatHistory = loadedData;
          _isLoading = false;
        });
      }
    } catch (err, st) {
      debugPrint(err.toString());
      debugPrint(st.toString());
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    // You can call this directly in initState, addPostFrameCallback is also fine
    getSeatHistory();
  }

  @override
  Widget build(context) {
    // 1. Check if user is logged in
    if (_auth.currentUser == null) {
      return const Center(
        child: Text(
          'Please login first',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      );
    }

    // 2. Show loading spinner while fetching
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // 3. Show message if no history found
    if (_seatHistory.isEmpty) {
      return const Center(child: Text('No booking history found.'));
    }

    // 4. Show the ListView
    return ListView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: _seatHistory.length,
      itemBuilder: (ctx, index) {
        return BookingHistoryItem(bookingData: _seatHistory[index]);
      },
    );
  }
}

// ---------------------------------------------------------
// The Booking History Item Widget
// ---------------------------------------------------------
class BookingHistoryItem extends StatelessWidget {
  final Map<String, dynamic> bookingData;

  const BookingHistoryItem({super.key, required this.bookingData});

  @override
  Widget build(BuildContext context) {
    // Extract data safely
    final seatId = bookingData['seat_id'] ?? 'Unknown Seat';
    final duration = bookingData['duration_seconds'] ?? 0;

    // Handle Timestamp conversion
    final Timestamp? timestamp = bookingData['start_time'];
    final DateTime date = timestamp != null
        ? timestamp.toDate()
        : DateTime.now();

    // Simple Date formatting (Or use Intl package if you have it)
    final String dateString = "${date.day}/${date.month}/${date.year}";
    final String timeString =
        "${date.hour}:${date.minute.toString().padLeft(2, '0')}";

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 5),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blueAccent.withOpacity(0.2),
          child: const Icon(Icons.event_seat, color: Colors.blueAccent),
        ),
        title: Text(
          seatId,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 5),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                const SizedBox(width: 5),
                Text("$dateString at $timeString"),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(Icons.timer, size: 14, color: Colors.grey),
                const SizedBox(width: 5),
                Text("${(duration ~/ 60)} minutes"),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
