import 'package:flutter/material.dart';

class TextInput extends StatelessWidget {
  final String? hintText;
  final IconData? prefixIcon;
  final bool obscureText;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final TextStyle? textStyle;
  final Color? fillColor;
  final Color? focusColor;
  final double elevation;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final Function(String)? onChanged;
  const TextInput(
      {super.key,
      this.hintText,
      this.prefixIcon,
      this.obscureText = false,
      this.keyboardType,
      this.textStyle,
      this.fillColor,
      this.focusColor = Colors.blue,
      this.elevation = 2.0,
      this.borderRadius = 10.0,
      this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      this.controller,
      this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: elevation,
      borderRadius: BorderRadius.circular(borderRadius),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType ?? TextInputType.text,
        style: textStyle ?? const TextStyle(fontSize: 16.0),
        onChanged: onChanged,
        obscureText: obscureText,
        decoration: InputDecoration(
          filled: true,
          fillColor: fillColor,
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey[600]),
          prefixIcon: prefixIcon != null
              ? Icon(prefixIcon, color: Colors.grey[700])
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: BorderSide(color: focusColor!, width: 2.0),
          ),
          contentPadding: padding,
        ),
      ),
    );
  }
}
