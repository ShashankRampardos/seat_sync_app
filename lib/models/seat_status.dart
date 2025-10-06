import 'package:flutter/material.dart';

enum SeatStatus {
  available, // 1. Seat Available
  occupied, // 2. Seat Occupied
  onHold, // 3. Seat Occupied but Put on Hold by Someone
  unauthorizedOccupied, // 4. Unauthorized Seat Occupied
  bookingInProgress, // 5. Seat Booking in Progress (OTP Displayed, Awaiting Authentication)
  reserved, // 6. Reserved Seat (Not for General Public)
  blocked, // 7. Blocked Seat (Damaged / Sensor Fault / Battery Dead)
}

extension SeatStatusExtension on SeatStatus {
  String get label {
    switch (this) {
      case SeatStatus.available:
        return "Seat Available";
      case SeatStatus.occupied:
        return "Seat Occupied";
      case SeatStatus.onHold:
        return "On Hold";
      case SeatStatus.unauthorizedOccupied:
        return "Unauthorized Occupied";
      case SeatStatus.bookingInProgress:
        return "Booking in Progress";
      case SeatStatus.reserved:
        return "Reserved Seat";
      case SeatStatus.blocked:
        return "Blocked Seat";
    }
  }

  Color get colorCode {
    switch (this) {
      case SeatStatus.available:
        return Colors.blueGrey; // Green
      case SeatStatus.occupied:
        return Colors.green; // Red
      case SeatStatus.onHold:
        return Colors.blue; // Orange
      case SeatStatus.unauthorizedOccupied:
        return Colors.redAccent; // Pink/Alert
      case SeatStatus.bookingInProgress:
        return Colors.deepPurpleAccent; // Yellow
      case SeatStatus.reserved:
        return Colors.yellow; // Blue
      case SeatStatus.blocked:
        return Colors.black; // Grey
    }
  }
}
