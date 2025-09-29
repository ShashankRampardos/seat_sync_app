import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class Utils {
  static void showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG, // SHORT ya LONG
      gravity: ToastGravity.BOTTOM, // TOP, CENTER, ya BOTTOM
      backgroundColor: const Color.fromARGB(255, 255, 71, 71),
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }
}
