import 'dart:async';

import 'package:flutter/material.dart';

class CountdownTimerWidget extends StatefulWidget {
  final DateTime bookedAt;
  final Duration totalDuration;

  const CountdownTimerWidget({
    super.key,
    required this.bookedAt,
    required this.totalDuration,
  });

  @override
  State<CountdownTimerWidget> createState() => _CountdownTimerWidgetState();
}

class _CountdownTimerWidgetState extends State<CountdownTimerWidget> {
  late Timer _timer;
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    // Start the timer as soon as the widget is created.
    _startTimer();
  }

  @override
  void dispose() {
    // IMPORTANT: Cancel the timer when the widget is removed to prevent memory leaks.
    _timer.cancel();
    super.dispose();
  }

  void _startTimer() {
    // Calculate the initial remaining time.
    final endTime = widget.bookedAt.add(widget.totalDuration);
    _remaining = endTime.difference(DateTime.now());

    // Create a timer that fires every second.
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        // Recalculate the remaining time on each tick.
        _remaining = endTime.difference(DateTime.now());
      });

      // If the countdown is finished, stop the timer.
      if (_remaining.isNegative) {
        timer.cancel();
      }
    });
  }

  String _formatDuration(Duration duration) {
    if (duration.isNegative) {
      return '00:00'; // Show 00:00 when time is up.
    }
    // This formats the duration into MM:SS format for the countdown.
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _formatDuration(_remaining),
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 14,
      ),
    );
  }
}
