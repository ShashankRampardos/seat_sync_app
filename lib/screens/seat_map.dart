import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/src/framework.dart';
import 'package:seat_sync_v2/models/pair.dart';

import 'package:seat_sync_v2/models/seat_info.dart';
import 'package:seat_sync_v2/models/seat_status.dart';
import 'package:seat_sync_v2/providers/revel_paid_unpaid.dart';
import 'package:seat_sync_v2/providers/row_and_col.dart';
import 'package:seat_sync_v2/providers/seat_matrix.dart';

import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:seat_sync_v2/utils/utils.dart';
import 'package:seat_sync_v2/widgets/countdown_time.dart';

class SeatMapScreen extends ConsumerStatefulWidget {
  const SeatMapScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _SeatMapScreenState();
}

class _SeatMapScreenState extends ConsumerState<SeatMapScreen> {
  late MqttServerClient client;
  final _auth = FirebaseAuth.instance;
  @override
  void initState() {
    super.initState();
    //cellColors = List.generate(rows * cols, (index) => Colors.grey); // default
    setupMQTT();
  }

  Future<void> setupMQTT() async {
    final row = ref.read(rowAndCol)[0];
    final col = ref.read(rowAndCol)[1];
    final totalSeats = row * col;

    client = MqttServerClient(
      'broker.hivemq.com',
      'flutter_${DateTime.now().millisecondsSinceEpoch}',
    );
    await client.connect();
    print('MQTT connected');

    // subscribe all seats
    for (int i = 0; i < totalSeats; i++) {
      //0 to n seats sub ko subscribe karlo, phir jho update de us sa update lo
      final topic = 'seat/$i/status';
      client.subscribe(topic, MqttQos.atLeastOnce);
    }

    client.updates!.listen((List<MqttReceivedMessage<MqttMessage>> messages) {
      final recMess = messages[0].payload as MqttPublishMessage;
      final payload = MqttPublishPayload.bytesToStringAsString(
        recMess.payload.message,
      );
      final topic = messages[0].topic;
      debugPrint('[$topic] → $payload');
      handleSeatStatus(topic, payload);
    });
  }

  void handleSeatStatus(String topic, String payload) {
    final seatIndex = int.parse(topic.split('/')[1]); //0 based index
    final seatNotifier = ref.read(seatMatrixProvider.notifier);
    final seat = ref.read(seatMatrixProvider)[seatIndex];

    SeatStatus ss = SeatStatus.available;
    if (payload == '0') {
      ss = SeatStatus.available;
    } else if (payload == '1') {
      ss = SeatStatus.occupied;
    } else if (payload == '2') {
      ss = SeatStatus.occupiedByObject;
    }
    debugPrint(ss.label);

    DateTime? bookingTimestamp;
    // If the seat is becoming occupied and wasn't already, set the timestamp.
    if (ss == SeatStatus.occupied && seat.status != SeatStatus.occupied) {
      bookingTimestamp = DateTime.now();
    }

    seatNotifier.updateSeat(
      seatId: seatIndex,
      status: ss,
      bookedAt: bookingTimestamp,
    ); //in updateSeat will use ss.colorCode
    _publishColorCommand(seatIndex, ss.colorCode);
  }

  void _publishColorCommand(int seatIndex, Color color) {
    final topic = 'seat/$seatIndex/command'; // The new command topic

    // Format the payload as a simple "R,G,B" string
    final payload = '${color.red},${color.green},${color.blue}';

    final builder = MqttClientPayloadBuilder();
    builder.addString(payload);

    client.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);

    debugPrint('PUBLISHED: [$topic] → $payload');
  }

  //if seat is occupied then only user can set time
  //if seat.status[index] != SeatStatus.available then duration will become null again.
  void setExpectedHoldTime(int index, BuildContext context) {
    final seatNotifier = ref.watch(seatMatrixProvider.notifier);
    final seatList = ref.read(seatMatrixProvider);

    // This variable will hold the duration selected in the picker.
    // It's declared here so it's available for the 'Set' button.
    Duration selectedDuration = seatList[index].duration ?? Duration.zero;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text(
            'Set Seat Occupancy Duration (optional but helpful)',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18),
          ),
          // We give the content a fixed size to prevent layout errors.
          content: SizedBox(
            height: 200,
            width: MediaQuery.of(
              context,
            ).size.width, // screen width use karne ka lia
            child: CupertinoTimerPicker(
              mode: CupertinoTimerPickerMode.hm,
              initialTimerDuration: selectedDuration,
              // This callback updates the variable as the user scrolls.
              onTimerDurationChanged: (Duration newDuration) {
                selectedDuration = newDuration;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // Update the state with the final selected duration.
                seatNotifier.updateSeat(
                  seatId: index,
                  duration: selectedDuration,
                  bookedAt: DateTime.now(),
                );
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Set'),
            ),
          ],
        );
      },
    );
  }

  void _putSeatOnHold(int index, BuildContext context) {
    final seatNotifier = ref.watch(seatMatrixProvider.notifier);
    final seatList = ref.read(seatMatrixProvider);

    // This variable will hold the duration selected in the picker.
    // It's declared here so it's available for the 'Set' button.
    Duration selectedDuration = seatList[index].duration ?? Duration.zero;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text(
            'Set Seat Hold Duration (max 10 minutes)',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18),
          ),
          // We give the content a fixed size to prevent layout errors.
          content: SizedBox(
            height: 200,
            width: MediaQuery.of(
              context,
            ).size.width, // screen width use karne ka lia
            child: CupertinoTimerPicker(
              mode: CupertinoTimerPickerMode.ms,
              initialTimerDuration: selectedDuration,
              // This callback updates the variable as the user scrolls.
              onTimerDurationChanged: (Duration newDuration) {
                selectedDuration = newDuration;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // Update the state with the final selected duration.
                if (selectedDuration > Duration(minutes: 10)) {
                  Utils.showToast('Duration should be lesser than 10');
                  Navigator.of(dialogContext).pop();
                  return;
                }
                seatNotifier.updateSeat(
                  seatId: index,
                  seatOnHoldTime: selectedDuration,
                  status: SeatStatus.onHold,
                );
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Set'),
            ),
          ],
        );
      },
    );
  }

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
              onLongPress: () {
                if (seats[index].status == SeatStatus.occupied) {
                  _putSeatOnHold(index, context);
                } else {
                  Utils.showToast(
                    'Please occupy the seat first, seat hold time.',
                  );
                }
              },
              onTap: () {
                if (seats[index].isFree) {
                  if (seats[index].status == SeatStatus.occupied) {
                    //seats[index].status == SeatStatus.occupied
                    setExpectedHoldTime(index, context);
                  } else {
                    Utils.showToast(
                      'Please occupy the seat first, to set occupancy time.',
                    );
                  }
                } else {
                  // seat is paid
                  bookSeat(index);
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: seats[index].color,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.black, width: 0.5),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Text(
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
                      if (!toRevelPaidUnpaid)
                        Text(
                          seats[index].status.label,
                          style: TextStyle(fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      // Conditionally display the countdown timer
                      if (seats[index].status == SeatStatus.occupied &&
                          seats[index].duration != null &&
                          seats[index].bookedAt != null &&
                          seats[index].duration! > Duration.zero)
                        CountdownTimerWidget(
                          bookedAt: seats[index].bookedAt!,
                          totalDuration: seats[index].duration!,
                        ),
                    ],
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
