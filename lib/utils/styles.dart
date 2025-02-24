import 'package:flutter/material.dart';

class CustomStyles {
  static final buttonStyle = ElevatedButton.styleFrom(
    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
    backgroundColor: Colors.white,
    foregroundColor: Colors.blue,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    ),
  );

  static final inputStyle = InputDecoration(
    hintText: 'Email',
    hintStyle: const TextStyle(color: Colors.white),
    enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
    focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
  );
}