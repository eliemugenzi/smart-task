// components/custom_button.dart
import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? textColor;
  final double? fontSize;
  final EdgeInsets? padding;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.backgroundColor = Colors.blue,
    this.textColor = Colors.white,
    this.fontSize = 16.0,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        padding: padding ?? const EdgeInsets.symmetric(vertical: 12.0, horizontal: 24.0),
        disabledBackgroundColor: backgroundColor?.withOpacity(0.5),
      ),
      child: isLoading
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.0),
                ),
                SizedBox(width: 8.0),
                Text(
                  'Loading',
                  style: TextStyle(color: Colors.white, fontSize: 16.0),
                ),
              ],
            )
          : Text(
              text,
              style: TextStyle(color: textColor, fontSize: fontSize),
            ),
    );
  }
}