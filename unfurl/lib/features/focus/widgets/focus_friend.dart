import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:unfurl/shared/theme.dart';

class FocusFriend extends StatefulWidget {
  final bool timerRunning;
  final Map<String, dynamic>? awardResponse;
  final bool awardError;

  const FocusFriend({
    super.key,
    required this.timerRunning,
    required this.awardResponse,
    required this.awardError,
  });

  @override
  State<FocusFriend> createState() => _FocusFriendState();
}

class _FocusFriendState extends State<FocusFriend> {
  static const List<String> _searchingLines = [
    'I am looking for a flower for you.',
    "I'm out looking for your flower...",
    "Don't give up, I'm still searching!",
    'Almost there, keep going!',
  ];

  static const List<Alignment> _beePath = [
    Alignment(-0.9, 0.45),
    Alignment(-0.25, -0.2),
    Alignment(0.45, 0.3),
    Alignment(0.88, -0.15),
    Alignment(0.2, 0.5),
    Alignment(-0.65, -0.05),
  ];

  int _lineIndex = 0;
  int _beeStep = 0;
  Timer? _rotationTimer;
  Timer? _beeMoveTimer;

  bool get _isSearching =>
      widget.timerRunning && widget.awardResponse == null && !widget.awardError;

  bool get _isFound => widget.awardResponse != null;

  @override
  void initState() {
    super.initState();
    _syncTimers();
  }

  @override
  void didUpdateWidget(covariant FocusFriend oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncTimers();
  }

  @override
  void dispose() {
    _rotationTimer?.cancel();
    _beeMoveTimer?.cancel();
    super.dispose();
  }

  void _syncTimers() {
    if (_isSearching) {
      _rotationTimer ??= Timer.periodic(const Duration(seconds: 30), (_) {
        if (!mounted) return;
        setState(() {
          _lineIndex = (_lineIndex + 1) % _searchingLines.length;
        });
      });
      _beeMoveTimer ??= Timer.periodic(const Duration(seconds: 4), (_) {
        if (!mounted) return;
        setState(() {
          _beeStep = (_beeStep + 1) % _beePath.length;
        });
      });
    } else {
      _rotationTimer?.cancel();
      _rotationTimer = null;
      _beeMoveTimer?.cancel();
      _beeMoveTimer = null;
    }
  }

  String _tierLine(String tier) {
    switch (tier.toUpperCase()) {
      case 'EXCELLENT':
        return 'I had to climb really high for this one!';
      case 'MEDIUM':
        return 'This one was worth the search!';
      case 'SMALL':
        return 'Found it! Every flower counts!';
      case 'MICRO':
        return 'Quick but beautiful!';
      default:
        return 'Found one for you!';
    }
  }

  @override
  Widget build(BuildContext context) {
    String line;
    Widget visual;
    bool showWanderingScene = false;

    if (_isFound) {
      final flowerName = (widget.awardResponse?['selected_flower'] ?? '').toString();
      final tier = (widget.awardResponse?['tier'] ?? '').toString();
      line = _tierLine(tier);
      visual = _foundVisual(flowerName);
    } else if (widget.awardError) {
      line = "I couldn't find one this time, but I'll keep looking!";
      visual = _friendAvatar(icon: Icons.sentiment_dissatisfied_rounded, beeHappy: false);
    } else {
      line = _searchingLines[_lineIndex];
      showWanderingScene = true;
      visual = _friendAvatar(icon: Icons.travel_explore_rounded, searching: true, beeHappy: false);
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD8E8E0)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showWanderingScene) ...[
            SizedBox(
              height: 84,
              width: double.infinity,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F9F6),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFDCEBE3)),
                      ),
                    ),
                  ),
                  AnimatedAlign(
                    duration: const Duration(seconds: 4),
                    curve: Curves.easeInOut,
                    alignment: _beePath[_beeStep],
                    child: _beeImage(48, false),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              visual,
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  line,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _friendAvatar({
    required IconData icon,
    bool searching = false,
    bool beeHappy = false,
  }) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 44,
          height: 44,
          child: CircularProgressIndicator(
            value: searching ? null : 1,
            strokeWidth: 3,
            color: sageGreen.withValues(alpha: 0.75),
            backgroundColor: const Color(0xFFE6EFE9),
          ),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: _beeImage(28, beeHappy, fallbackIcon: icon),
        ),
      ],
    );
  }

  Widget _foundVisual(String flowerName) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _friendAvatar(icon: Icons.local_florist_rounded, beeHappy: true),
        const SizedBox(width: 6),
        _flowerVisual(flowerName),
      ],
    );
  }

  Widget _flowerVisual(String flowerName) {
    if (flowerName.trim().isEmpty) {
      return _friendAvatar(icon: Icons.local_florist_rounded, beeHappy: true);
    }

    final assetPath = 'assets/flowers/$flowerName';
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 56,
        height: 56,
        padding: const EdgeInsets.all(4),
        color: const Color(0xFFF1F7F3),
        child: SvgPicture.asset(
          assetPath,
          fit: BoxFit.contain,
          placeholderBuilder: (context) => const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
    );
  }

  Widget _beeImage(double size, bool happy, {IconData? fallbackIcon}) {
    final path = happy ? 'assets/flowers/happy_bee.jpg' : 'assets/flowers/search_bee.png';
    return Image.asset(
      path,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (context, _, __) => Icon(
        fallbackIcon ?? Icons.emoji_nature_rounded,
        color: sageGreen,
        size: size * 0.8,
      ),
    );
  }
}
