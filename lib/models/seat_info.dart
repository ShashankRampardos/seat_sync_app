import 'package:flutter/material.dart';
import 'package:seat_sync_v2/models/seat_status.dart';

class Seat {
  final int id; // seat number or id
  Color color; // UI color
  bool isBooked; // booking status
  String? bookedBy; // user id or name
  String? otp; // OTP assigned for authentication
  DateTime? bookedAt; // booking timestamp
  Duration? duration; // how long it is reserved
  SeatStatus status; // e.g., "available", "occupied", "reserved"
  bool isFree; // free hai ya paid hai
  bool isHumanPresent;
  bool isObjectPresent;

  Seat({
    required this.id,
    this.color = Colors.grey,
    this.isBooked = false,
    this.bookedBy,
    this.otp,
    this.bookedAt,
    this.duration,
    this.status = SeatStatus.available,
    this.isFree = true,
    this.isHumanPresent = false,
    this.isObjectPresent = false,
  });

  copyWith({required status, required MaterialColor color}) {}
}
