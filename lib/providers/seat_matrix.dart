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
          index = index + 1;
          final isSeatFree = (index % 4 == 1 || index % 4 == 0);
          return Seat(id: index + 1, isFree: isSeatFree ? false : true);
        }),
      );

  void updateSeat(int seatId, String payload) {
    state = [
      for (final seat in state)
        if (seat.id ==
            seatId) //badme switch case lagana padega to select different states
          seat.copyWith(
            status: payload == "1" ? SeatStatus.occupied : SeatStatus.available,
            color: payload == "1"
                ? SeatStatus.occupied.colorCode
                : SeatStatus.available.colorCode,
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
