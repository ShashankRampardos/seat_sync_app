import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:seat_sync_v2/models/seat_info.dart';
import 'package:seat_sync_v2/models/seat_status.dart';
import 'package:seat_sync_v2/providers/row_and_col.dart';

// Remove top-level usage of ref

class SeatMatrix extends StateNotifier<List<Seat>> {
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
    // --- CORE LOGIC: PART 1 ---
    // Check if the seat is currently on hold and this is a status update from MQTT.
    final currentSeat = state.firstWhere((s) => s.id == seatId);
    if (currentSeat.holdStartTime != null &&
        currentSeat.seatOnHoldTime != null) {
      final holdEndTime = currentSeat.holdStartTime!.add(
        currentSeat.seatOnHoldTime!,
      );
      // If the hold is still active AND this update is trying to change the status...
      if (DateTime.now().isBefore(holdEndTime) && status != null) {
        debugPrint('Seat $seatId is on hold. Ignoring status update.');
        return; // ...then ignore this update and exit the function.
      }
    }
    state = [
      for (final seat in state)
        if (seat.id == seatId)
          seat.copyWith(
            color: color,
            isBooked: isBooked,
            bookedBy: bookedBy,
            otp: otp,
            bookedAt: bookedAt,
            duration: status != SeatStatus.available ? null : duration,
            seatOnHoldTime: seatOnHoldTime,
            holdStartTime: holdStartTime,
            status: status,
            isFree: isFree,
            paymentStatus: paymentStatus,
            isHumanPresent: isHumanPresent,
            isObjectPresent: isObjectPresent,
          )
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
