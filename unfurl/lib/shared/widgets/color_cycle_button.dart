import 'package:flutter/material.dart';

class ColorCycleButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;

  const ColorCycleButton({
    super.key,
    required this.text,
    required this.onPressed,
  });

  @override
  State<ColorCycleButton> createState() => _ColorCycleButtonState();
}

class _ColorCycleButtonState extends State<ColorCycleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  final List<Color> colors = [
        Color(0xFF64FFDA), // mint
        Color(0xFFFF80AB), // pink
        Color(0xFFB388FF), // lavender
        Color(0xFFFFF176), // yellow
  ];

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color getCurrentColor() {
      double t = _controller.value * colors.length;
      int index = t.floor() % colors.length;
      int nextIndex = (index + 1) % colors.length;
      double percent = t - t.floor();

      HSVColor a = HSVColor.fromColor(colors[index]);
      HSVColor b = HSVColor.fromColor(colors[nextIndex]);

      return HSVColor.lerp(a, b, percent)!.toColor();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final currentColor = getCurrentColor();
        return OutlinedButton(
          style: OutlinedButton.styleFrom(
            backgroundColor: const Color(0xFF1A237E), // navy blue
            side: BorderSide(color: currentColor, width: 4),
            foregroundColor: currentColor,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: widget.onPressed,
          child: Text(
            widget.text,
            style: const TextStyle(
                fontWeight: FontWeight.bold, // heavier font
                fontSize: 16,               // optional: adjust size too
              ),
          ),
        );
      },
    );
  }
}