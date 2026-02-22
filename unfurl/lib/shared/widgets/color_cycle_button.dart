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
        Color(0xFFFF8CB9),
        Color(0xFFFFB68F),
        Color(0xFFFF7AAE),
        Color(0xFFFF9EC6),
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
            backgroundColor: const Color(0xFFFFF7FB),
            side: BorderSide(color: currentColor.withValues(alpha: 0.7), width: 2),
            foregroundColor: const Color(0xFF7D3A5B),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          onPressed: widget.onPressed,
          child: Text(
            widget.text,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
        );
      },
    );
  }
}

