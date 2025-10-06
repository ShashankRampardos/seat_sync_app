import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:seat_sync_v2/models/seat_info.dart';
import 'package:seat_sync_v2/providers/revel_paid_unpaid.dart';
import 'package:seat_sync_v2/providers/row_and_col.dart';
import 'package:seat_sync_v2/providers/seat_matrix.dart';

import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:seat_sync_v2/utils/utils.dart';

class SeatMapScreen extends ConsumerStatefulWidget {
  const SeatMapScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _SeatMapScreenState();
}

class _SeatMapScreenState extends ConsumerState<SeatMapScreen> {
  @override
  void initState() {
    super.initState();
    //cellColors = List.generate(rows * cols, (index) => Colors.grey); // default
  }

  void changeColor(int index, Color color) {
    setState(() {
      //cellColors[index] = color;
    });
  }

  final _auth = FirebaseAuth.instance;
  void bookSeat(int index) {
    if (_auth.currentUser == null) {
      Utils.showToast('Its a paid seat, please login to book this seat');
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(20),
                  height: 400,
                  child: Column(
                    children: [
                      TextField(decoration: InputDecoration(labelText: 'otp')),
                      SizedBox(height: 20),
                      TextField(
                        decoration: InputDecoration(
                          labelText: 'Duration (minutes)',
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          // Only allow numbers up to 180 (3 hours)
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d{0,3}$'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value.isNotEmpty) {
                            final int? minutes = int.tryParse(value);
                            if (minutes != null &&
                                (minutes < 1 || minutes > 180)) {
                              // Show error or clear field
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Please enter a duration between 1 and 180 minutes.',
                                  ),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          }
                        },
                      ),
                      SizedBox(height: 20),
                      Text(
                        'Book Seat ${index + 1}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          changeColor(index, Colors.red);
                          Navigator.pop(context);
                        },
                        child: Text('Confirm Booking'),
                      ),
                      SizedBox(height: 20),
                      Text(
                        '🛠️Under Development, comming soon!',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final int rows = ref.watch(rowAndCol)[0];
    final int cols = ref.watch(rowAndCol)[1];
    final List<Seat> seats = ref.watch(seatMatrixProvider);
    final bool toRevelPaidUnpaid = ref.watch(toRevelPaidUnpaidProvider);

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
              onTap: () => seats[index].isFree ? null : bookSeat(index),
              child: Container(
                decoration: BoxDecoration(
                  color: seats[index].color,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.black, width: 0.5),
                ),
                child: Center(
                  child: Text(
                    toRevelPaidUnpaid
                        ? (seats[index].isFree
                              ? 'Free'
                              : 'Paid') //either show paid or free status or the seat index one each cell
                        : 'Seat ${index + 1}',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: toRevelPaidUnpaid
                          ? seats[index].isFree
                                ? FontWeight.normal
                                : FontWeight.bold
                          : FontWeight.normal,
                      fontSize: toRevelPaidUnpaid
                          ? seats[index].isFree
                                ? 15
                                : 20
                          : 17,
                    ),
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
