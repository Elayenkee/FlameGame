import 'package:flutter/material.dart';

class FirstTheme {
  static const Color buttonColor = Color(0xFF00A994);
  static ShapeDecoration borderDecoration() {
    return ShapeDecoration(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: BorderSide(width: 1, color: FirstTheme.buttonColor)));
  }
}
