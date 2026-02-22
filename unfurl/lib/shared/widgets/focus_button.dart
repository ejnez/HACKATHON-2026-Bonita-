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
        backgroundColor: const Color(0xFFF4FFF9),
        foregroundColor: green,
        side: BorderSide(color: green.withValues(alpha: 0.45), width: 2),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      onPressed: onPressed,
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 15,
        ),
      ),
    );
  }
}

