import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:seat_sync_v2/models/seat_info.dart';
import 'package:seat_sync_v2/models/seat_status.dart';
import 'package:seat_sync_v2/providers/revel_paid_unpaid.dart';
import 'package:seat_sync_v2/providers/row_and_col.dart';
import 'package:seat_sync_v2/providers/seat_matrix.dart';

import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:seat_sync_v2/utils/utils.dart';
import 'package:seat_sync_v2/widgets/countdown_time.dart';

import 'dart:convert';

class SeatMapScreen extends ConsumerStatefulWidget {
  const SeatMapScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _SeatMapScreenState();
}

class _SeatMapScreenState extends ConsumerState<SeatMapScreen> {
  late MqttServerClient client;
  final _auth = FirebaseAuth.instance;
  String? _receivedOtp;
  bool _otpAuthenticated = false;

  int _extractSeatIndexFromTopic(String topic) {
    final parts = topic.split('/');
    if (parts.length > 1) {
      return int.tryParse(parts[1]) ?? -1;
    }
    return -1;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setupMQTT();
    });
  }

  Future<void> setupMQTT() async {
    final row = ref.read(rowAndCol)[0];
    final col = ref.read(rowAndCol)[1];
    final totalSeats = row * col;

    client = MqttServerClient(
      'broker.hivemq.com',
      'flutter_${DateTime.now().millisecondsSinceEpoch}',
    );

    try {
      print('Connecting to MQTT...');
      await client.connect();
      print('MQTT connected');
    } catch (e) {
      print('MQTT connection failed: $e');
      if (client.connectionStatus?.returnCode !=
          MqttConnectReturnCode.connectionAccepted) {
        client.disconnect();
      }
    }

    // SUBSCRIPTIONS (Hold restored)
    for (int i = 0; i < totalSeats; i++) {
      client.subscribe('seat/$i/status', MqttQos.atLeastOnce);
      client.subscribe('seat/$i/otp', MqttQos.atLeastOnce);
      client.subscribe('seat/$i/hold', MqttQos.atLeastOnce); // ✔ HOLD restored
    }

    // LISTENER
    client.updates!.listen((List<MqttReceivedMessage<MqttMessage>> messages) {
      final recMess = messages[0].payload as MqttPublishMessage;
      final payload = MqttPublishPayload.bytesToStringAsString(
        recMess.payload.message,
      );
      final topic = messages[0].topic;

      debugPrint('[$topic] → $payload');

      if (topic.contains('/status')) {
        handleSeatStatus(topic, payload);
      } else if (topic.contains('/otp')) {
        if (payload == "null" && !_otpAuthenticated) {
          Utils.showToast("Otp expired");
        } else {
          setState(() {
            _receivedOtp = payload;
          });
        }
      }
      // ✔ HOLD ACK HANDLING
      else if (topic.contains('/hold')) {
        final index = _extractSeatIndexFromTopic(topic);
        final seatNotifier = ref.read(seatMatrixProvider.notifier);

        if (payload == "0") {
          Utils.showToast("Seat Hold Applied");
          seatNotifier.updateSeat(seatId: index, status: SeatStatus.onHold);
        } else if (payload == "1") {
          Utils.showToast("Unauthorized Hold Attempt");
        }
      }
    });
  }

  // ---------------- STATUS HANDLER ----------------
  void handleSeatStatus(String topic, String payload) {
    final seatIndex = int.parse(topic.split('/')[1]);
    final seatNotifier = ref.read(seatMatrixProvider.notifier);

    SeatStatus ss = SeatStatus.available;

    if (payload == '0')
      ss = SeatStatus.available;
    else if (payload == '1')
      ss = SeatStatus.occupied;
    else if (payload == '2')
      ss = SeatStatus.onHold;
    else if (payload == '3')
      ss = SeatStatus.unauthorizedOccupied;
    else if (payload == '4')
      ss = SeatStatus.bookingInProgress;
    else if (payload == '5')
      ss = SeatStatus.reserved;
    else if (payload == '6')
      ss = SeatStatus.blocked;
    else if (payload == '7')
      ss = SeatStatus.occupiedByObject;

    seatNotifier.updateSeat(seatId: seatIndex, status: ss);
  }

  // ---------------- HOLD DIALOG (UI unchanged) ----------------
  void _putSeatOnHold(int index, BuildContext context) {
    final seatList = ref.read(seatMatrixProvider);

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
          content: SizedBox(
            height: 200,
            width: MediaQuery.of(context).size.width,
            child: CupertinoTimerPicker(
              mode: CupertinoTimerPickerMode.ms,
              initialTimerDuration: selectedDuration,
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

            // APPLY HOLD
            ElevatedButton(
              onPressed: () {
                if (selectedDuration > Duration(minutes: 10)) {
                  Utils.showToast("Duration must be less than 10 minutes");
                  return;
                }

                final topic = 'seat/$index/hold';
                final builder = MqttClientPayloadBuilder();

                builder.addString(
                  jsonEncode({
                    "uid": _auth.currentUser!.uid, // REAL UID
                    "duration": selectedDuration.inSeconds, // seconds
                  }),
                );

                client.publishMessage(
                  topic,
                  MqttQos.atLeastOnce,
                  builder.payload!,
                );

                Utils.showToast("Sending Hold Request…");
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Set'),
            ),

            // ✔ STOP HOLD OPTION
            TextButton(
              onPressed: () {
                final topic = 'seat/$index/hold';
                final builder = MqttClientPayloadBuilder();

                builder.addString(
                  jsonEncode({
                    "uid": _auth.currentUser!.uid,
                    "duration": 0, // ✔ STOP HOLD
                  }),
                );

                client.publishMessage(
                  topic,
                  MqttQos.atLeastOnce,
                  builder.payload!,
                );

                Utils.showToast("Stopping Hold…");
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Stop Hold'),
            ),
          ],
        );
      },
    );
  }

  // ---------------- OTP GET SEAT ----------------
  void getSeat(int index, BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        bool isOtpReqSent = false;
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
                      TextField(
                        decoration: InputDecoration(labelText: 'otp'),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        onChanged: (value) {
                          if (value.length == 4) {
                            if (value == _receivedOtp) {
                              final topic = 'seat/$index/otp_request';
                              final builder = MqttClientPayloadBuilder();
                              builder.addString(_auth.currentUser!.uid);
                              client.publishMessage(
                                topic,
                                MqttQos.atLeastOnce,
                                builder.payload!,
                              );

                              Utils.showToast(
                                "OTP matched. Please take your seat.",
                              );

                              setModalState(() {
                                _otpAuthenticated = true;
                              });

                              Navigator.pop(context);
                            }
                          }
                        },
                      ),
                      SizedBox(height: 20),
                      Text(
                        'Get Seat ${index + 1}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: isOtpReqSent
                            ? null
                            : () async {
                                final topic = 'seat/$index/otp_request';
                                final builder = MqttClientPayloadBuilder();
                                builder.addString("guest");
                                client.publishMessage(
                                  topic,
                                  MqttQos.atLeastOnce,
                                  builder.payload!,
                                );
                                Utils.showToast('OTP request sent');
                                setModalState(() {
                                  isOtpReqSent = true;
                                });
                                await Future.delayed(
                                  Duration(milliseconds: 10000),
                                );
                                setModalState(() {
                                  isOtpReqSent = false;
                                });
                              },
                        child: Text('Get OTP on seat'),
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

  // ---------------- BOOK SEAT ----------------
  void bookSeat(int index) {
    if (_auth.currentUser == null) {
      Utils.showToast('Its a paid seat, please login first');
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
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d{0,3}$'),
                          ),
                        ],
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
                        '🛠️Under Development, coming soon!',
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

  // ---------------- UI BUILD ----------------
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
            childAspectRatio: 1,
            crossAxisSpacing: 5,
            mainAxisSpacing: 5,
          ),
          itemCount: rows * cols,
          itemBuilder: (context, index) {
            return GestureDetector(
              onLongPress: () {
                if (seats[index].status == SeatStatus.occupied ||
                    seats[index].status == SeatStatus.onHold) {
                  _putSeatOnHold(index, context);
                } else {
                  Utils.showToast('Please occupy the seat first.');
                }
              },
              onTap: () {
                if (seats[index].isFree) {
                  if (seats[index].status == SeatStatus.available) {
                    getSeat(index, context);
                  } else {
                    Utils.showToast('This seat already occupied.');
                  }
                } else {
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
                            ? (seats[index].isFree ? 'Free' : 'Paid')
                            : 'Seat ${index + 1}',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: toRevelPaidUnpaid
                              ? (seats[index].isFree
                                    ? FontWeight.normal
                                    : FontWeight.bold)
                              : FontWeight.normal,
                          fontSize: toRevelPaidUnpaid
                              ? (seats[index].isFree ? 15 : 20)
                              : 17,
                        ),
                      ),
                      if (!toRevelPaidUnpaid)
                        Text(
                          seats[index].status.label,
                          style: TextStyle(fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
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
