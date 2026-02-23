import 'package:flutter/material.dart';

class ColorCycleButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const ColorCycleButton({
    super.key,
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(14);
    return OutlinedButton(
      style: ButtonStyle(
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: radius),
        ),
        side: WidgetStateProperty.resolveWith((states) {
          final hovered = states.contains(WidgetState.hovered);
          return BorderSide(
            color: const Color(0xFF3D6B42).withValues(alpha: hovered ? 0.95 : 0.75),
            width: hovered ? 1.9 : 1.6,
          );
        }),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          final hovered = states.contains(WidgetState.hovered);
          return hovered ? const Color(0xFFF4FAF6) : Colors.white;
        }),
        foregroundColor: WidgetStateProperty.all(const Color(0xFF3D6B42)),
        overlayColor: WidgetStateProperty.all(
          const Color(0xFF3D6B42).withValues(alpha: 0.08),
        ),
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        ),
        elevation: WidgetStateProperty.all(0),
      ),
      onPressed: onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.auto_awesome_rounded, size: 18),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
        ],
      ),
    );
  }
}
