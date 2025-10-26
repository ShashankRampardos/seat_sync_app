import 'dart:async';
import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:seat_sync_v2/models/seat_info.dart';
import 'package:seat_sync_v2/models/seat_status.dart';
import 'package:seat_sync_v2/providers/row_and_col.dart';

// Remove top-level usage of ref

class SeatMatrix extends StateNotifier<List<Seat>> {
  // A map to store active timers for each seat on hold.
  final Map<int, Duration?> holdTimers = {};
  final Map<int, Duration?> occupancyTime = {}; //seatId, duratino

  SeatMatrix(int rows, int cols)
    : super(
        List.generate(rows * cols, (index) {
          final int i = index + 1;
          final isSeatFree = (i % 4 == 1 || i % 4 == 0);
          return Seat(id: index, isFree: isSeatFree ? false : true);
        }),
      );

  void updateSeat({
    required int seatId,
    Color? color,
    bool? isBooked,
    String? bookedBy,
    String? otp,
    DateTime? bookedAt,
    Duration? duration,
    Duration? seatOnHoldTime,
    DateTime? holdStartTime,
    SeatStatus? status,
    bool? isFree,
    bool? paymentStatus,
    bool? isHumanPresent,
    bool? isObjectPresent,
  }) {
    state = [
      for (final seat in state)
        if (seat.id == seatId)
          () {
            Duration? finalDuration;

            // THIS IS THE CORRECTED LOGIC
            //  Check if the status is actually being updated in this call.
            if (status != null) {
              //  If it is, and it's not 'available', then clear the duration.
              if (status != SeatStatus.available) {
                finalDuration = null;
              } else {
                // If status is being set to 'available', keep the duration.
                finalDuration = duration ?? seat.duration;
              }
            } else {
              //If status is NOT being updated, just use the duration that was passed in.
              // This is what happens in setExpectedHoldTime.
              finalDuration = duration ?? seat.duration;
            }
            final _auth = FirebaseAuth.instance;
            if (status == SeatStatus.occupied) {
              if ((!seat.isFree && !seat.paymentStatus) ||
                  (seat.bookedBy != null)) {
                //-------- may be un online database say kar na padega check bookedBy status
                status = SeatStatus.unauthorizedOccupied;
              }
            }
            return seat.copyWith(
              id: seatId,
              color: status == null ? color : status!.colorCode,
              isBooked: isBooked,
              bookedBy: bookedBy,
              otp: otp,
              bookedAt: bookedAt,
              duration: finalDuration,
              seatOnHoldTime: seatOnHoldTime,
              status: status,
              isFree: isFree,
              paymentStatus: paymentStatus,
              isHumanPresent: isHumanPresent,
              isObjectPresent: isObjectPresent,
            );
          }()
        else
          seat,
    ];
  }
}

// Example provider to use with Riverpod
final seatMatrixProvider = StateNotifierProvider<SeatMatrix, List<Seat>>((ref) {
  final rowAndColValues = ref.watch(rowAndCol);
  final rows = rowAndColValues[0];
  final cols = rowAndColValues[1];
  return SeatMatrix(rows, cols);
});
