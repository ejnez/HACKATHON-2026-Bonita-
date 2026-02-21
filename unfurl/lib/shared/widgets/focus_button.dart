import 'package:flutter/material.dart';

class FocusButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final double borderRadius;

  const FocusButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.borderRadius = 8, // slightly rounded
  });

  @override
  Widget build(BuildContext context) {
    final green = Theme.of(context).colorScheme.secondary;

    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: green,
        side: BorderSide(color: green, width: 4),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
      onPressed: onPressed,
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w900, // heavier font
          fontSize: 18,
        ),
      ),
    );
  }
}