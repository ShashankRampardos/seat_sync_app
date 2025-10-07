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
  bool paymentStatus;
  bool isHumanPresent;
  bool isObjectPresent;

  Seat({
    required this.id,
    Color? color,
    this.isBooked = false,
    this.bookedBy,
    this.otp,
    this.bookedAt,
    this.duration,
    this.status = SeatStatus.available,
    this.isFree = true,
    this.paymentStatus = false,
    this.isHumanPresent = false,
    this.isObjectPresent = false,
  }) : color = color ?? SeatStatus.available.colorCode;

  Seat copyWith({
    int? id,
    Color? color,
    bool? isBooked,
    String? bookedBy,
    String? otp,
    DateTime? bookedAt,
    Duration? duration,
    SeatStatus? status,
    bool? isFree,
    bool? paymentStatus,
    bool? isHumanPresent,
    bool? isObjectPresent,
  }) {
    return Seat(
      id: id ?? this.id,
      color: color ?? this.color,
      isBooked: isBooked ?? this.isBooked,
      bookedBy: bookedBy ?? this.bookedBy,
      otp: otp ?? this.otp,
      bookedAt: bookedAt ?? this.bookedAt,
      duration: duration ?? this.duration,
      status: status ?? this.status,
      isFree: isFree ?? this.isFree,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      isHumanPresent: isHumanPresent ?? this.isHumanPresent,
      isObjectPresent: isObjectPresent ?? this.isObjectPresent,
    );
  }
}
