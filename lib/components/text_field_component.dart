// components/custom_text_field.dart
import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final String labelText;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool obscureText;
  final int? maxLines;
  final Function(String?)? onSubmitted;

  const CustomTextField({
    super.key,
    required this.labelText,
    this.controller,
    this.validator,
    this.keyboardType,
    this.obscureText = false,
    this.maxLines,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    // Default to single-line (maxLines: 1) unless maxLines is explicitly provided
    final effectiveMaxLines = maxLines ?? 1;

    // Ensure obscured fields are single-line (maxLines: 1)
    final finalMaxLines = obscureText ? 1 : effectiveMaxLines;

    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: Colors.blue),
        ),
      ),
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLines: finalMaxLines, // Use the final maxLines value
      validator: validator,
      onFieldSubmitted: onSubmitted != null ? (value) => onSubmitted!(value) : null,
    );
  }
}