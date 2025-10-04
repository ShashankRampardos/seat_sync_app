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

  String get colorCode {
    switch (this) {
      case SeatStatus.available:
        return "#00FF00"; // Green
      case SeatStatus.occupied:
        return "#FF0000"; // Red
      case SeatStatus.onHold:
        return "#FFA500"; // Orange
      case SeatStatus.unauthorizedOccupied:
        return "#FF1493"; // Pink/Alert
      case SeatStatus.bookingInProgress:
        return "#FFFF00"; // Yellow
      case SeatStatus.reserved:
        return "#0000FF"; // Blue
      case SeatStatus.blocked:
        return "#808080"; // Grey
    }
  }
}
