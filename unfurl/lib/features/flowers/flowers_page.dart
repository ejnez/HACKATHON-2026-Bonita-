import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:unfurl/features/tasks/task_provider.dart';
import 'package:unfurl/shared/theme.dart';
import 'package:unfurl/shared/widgets/app_drawer.dart';

class EarnedFlower {
  final String filename;
  final String tier;

  const EarnedFlower({
    required this.filename,
    required this.tier,
  });

  String get assetPath => 'assets/flowers/$filename';
  String get displayName => filename.replaceAll(RegExp(r'\.(svg|png|jpg|jpeg)$', caseSensitive: false), '');

  static String normalizeFileName(String raw) {
    var value = raw.trim();
    if (value.isEmpty) return '';
    value = value.replaceAll('\\', '/');
    value = value.split('/').last;
    value = value.trim();

    // Backend/data may contain historical spellings that don't match asset filenames.
    const aliases = {
      'Judicious Jonquil.svg': 'Judicious Jonquuil.svg',
      'Persevering Pear.svg': 'Perservering Pear.svg',
      'Persevering Poppy.svg': 'Perservering Poppy.svg',
    };
    return aliases[value] ?? value;
  }
}

class _FlowerPlacement {
  final EarnedFlower flower;
  final double dx;
  final double dy;
  final double size;
  final double rotation;

  const _FlowerPlacement({
    required this.flower,
    required this.dx,
    required this.dy,
    required this.size,
    required this.rotation,
  });
}

class _RowDef {
  final int slots;
  final double radiusFraction;

  const _RowDef({
    required this.slots,
    required this.radiusFraction,
  });
}

List<_FlowerPlacement> _buildPlacements(
  List<EarnedFlower> flowers,
  double bouquetWidth,
{
  required double originX,
  required double originY,
}) {
  // Stable pseudo-random seed from bouquet contents:
  // random-looking arrangement that doesn't jump on rebuild.
  final seed = flowers.fold<int>(
    flowers.length * 97,
    (acc, f) => (acc * 31) ^ '${f.filename}|${f.tier}'.toLowerCase().hashCode,
  );
  final rng = Random(seed);
  final placements = <_FlowerPlacement>[];

  double sizeForTier(String tier) {
    switch (tier.toUpperCase()) {
      case 'EXCELLENT':
        return bouquetWidth * 0.17;
      case 'MEDIUM':
        return bouquetWidth * 0.145;
      case 'SMALL':
        return bouquetWidth * 0.12;
      case 'MICRO':
      default:
        return bouquetWidth * 0.10;
    }
  }

  const rows = [
    _RowDef(slots: 1, radiusFraction: 0.00),
    _RowDef(slots: 3, radiusFraction: 0.14),
    _RowDef(slots: 5, radiusFraction: 0.26),
    _RowDef(slots: 7, radiusFraction: 0.38),
    _RowDef(slots: 9, radiusFraction: 0.50),
    _RowDef(slots: 11, radiusFraction: 0.62),
  ];

  var index = 0;
  for (final row in rows) {
    if (index >= flowers.length) break;

    final radius = bouquetWidth * row.radiusFraction * 1.12;
    final slots = row.slots;
    final count = min(flowers.length - index, slots);

    for (var i = 0; i < count; i++) {
      double angle;
      if (slots == 1) {
        angle = -pi / 2;
      } else {
        const arcSpread = pi * 0.94;
        final step = arcSpread / (slots - 1);
        final start = -pi / 2 - arcSpread / 2;
        final offset = (slots - count) / 2;
        angle = start + (i + offset) * step;
      }

      // Row-level and per-flower angle variation so bouquets feel organic.
      angle += (rng.nextDouble() - 0.5) * 0.22;

      final jitter = bouquetWidth * 0.018;
      final dx = originX + radius * cos(angle) + (rng.nextDouble() - 0.5) * jitter;
      final dy = originY + radius * sin(angle) + (rng.nextDouble() - 0.5) * jitter;

      placements.add(
        _FlowerPlacement(
          flower: flowers[index],
          dx: dx,
          dy: dy,
          size: sizeForTier(flowers[index].tier),
          rotation: (rng.nextDouble() - 0.5) * 0.30,
        ),
      );
      index++;
    }
  }

  return placements;
}

class FlowersPage extends StatefulWidget {
  const FlowersPage({super.key});

  @override
  State<FlowersPage> createState() => _FlowersPageState();
}

class _FlowersPageState extends State<FlowersPage> {
  static const String _demoUserId = 'demo-user';

  final TaskProvider _provider = TaskProvider();
  bool _loading = true;
  String? _error;
  int _streakDays = 0;
  List<EarnedFlower> _todayFlowers = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  int _asInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    return int.tryParse('${value ?? ''}') ?? fallback;
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final bouquet = await _provider.fetchTodayBouquet(userId: _demoUserId);
      final streak = await _provider.fetchFlowerStreak(userId: _demoUserId);

      final rawFlowers = (bouquet['flowers'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .toList(growable: false);

      final parsedFlowers = <EarnedFlower>[];
      for (final item in rawFlowers) {
        final raw = (item['flower_type_id'] ?? '').toString();
        final filename = EarnedFlower.normalizeFileName(raw);
        if (filename.isEmpty || !filename.toLowerCase().endsWith('.svg')) {
          continue;
        }
        parsedFlowers.add(
          EarnedFlower(
            filename: filename,
            tier: (item['tier'] ?? 'SMALL').toString().toUpperCase(),
          ),
        );
      }

      if (!mounted) return;
      setState(() {
        _todayFlowers = parsedFlowers;
        _streakDays = _asInt(streak['current_streak_days']);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final flowersCount = _todayFlowers.length;
    return Scaffold(
      appBar: AppBar(title: const Text('My Unfurl Garden')),
      drawer: const AppDrawer(currentRoute: '/flowers'),
      body: Stack(
        children: [
          Container(color: const Color(0xFFF4EFE6)),
          Positioned(
            top: -90,
            left: -80,
            child: Container(
              width: 340,
              height: 340,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFA8C5AB).withValues(alpha: 0.22),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: -100,
            bottom: -110,
            child: Container(
              width: 380,
              height: 380,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFC9A84C).withValues(alpha: 0.14),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(_error!),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        children: [
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final wide = constraints.maxWidth >= 920;
                              if (wide) {
                                return SizedBox(
                                  height: 500,
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        flex: 6,
                                        child: _todayFlowers.isEmpty
                                            ? _emptyBouquetCard()
                                            : _BouquetCard(flowers: _todayFlowers),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        flex: 5,
                                        child: _rightPanel(flowersCount),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              return Column(
                                children: [
                                  if (_todayFlowers.isNotEmpty) _BouquetCard(flowers: _todayFlowers),
                                  if (_todayFlowers.isEmpty) _emptyBouquetCard(),
                                  const SizedBox(height: 12),
                                  _rightPanel(flowersCount),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
        ],
      ),
    );
  }

  Widget _emptyBouquetCard() {
    return Container(
      height: 460,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFDBEAE2)),
      ),
      child: const Center(
        child: Text('No flowers earned yet today.'),
      ),
    );
  }

  Widget _rightPanel(int flowersCount) {
    return Container(
      height: 500,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFD7E7DE)),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(34, 61, 50, 0.08),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F8F4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFDCEAE2)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE7F2EC),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.local_florist_rounded, color: sageGreen),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Today's Garden", style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 4),
                      const Text('Every completed task blooms into something beautiful.'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _statTile(
                  icon: Icons.spa_rounded,
                  title: 'Blooms Today',
                  value: '$flowersCount',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _statTile(
                  icon: Icons.local_fire_department_rounded,
                  title: 'Streak',
                  value: '$_streakDays day${_streakDays == 1 ? '' : 's'}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF7F2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _streakDays > 0
                  ? 'Keep earning at least one flower daily to maintain your streak.'
                  : 'Earn a flower today to start your streak.',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF5E7B70),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (_streakDays > 0)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: List.generate(
                _streakDays.clamp(1, 21),
                (_) => Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6F2EB),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Icon(
                    Icons.local_florist_rounded,
                    size: 14,
                    color: sageGreen,
                  ),
                ),
              ),
            ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/'),
                  icon: const Icon(Icons.task_alt_rounded),
                  label: const Text('Tasks'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/focus'),
                  icon: const Icon(Icons.timer_outlined),
                  label: const Text('Focus'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF7F2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFD7E9DD)),
            ),
            child: const Text(
              'You are building momentum one bloom at a time. Keep going.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF576A61),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD6E7DE)),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(35, 61, 50, 0.07),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF4EE),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: sageGreen),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF678278))),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BouquetCard extends StatelessWidget {
  final List<EarnedFlower> flowers;

  const _BouquetCard({required this.flowers});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 460,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFDBEAE2)),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(35, 63, 52, 0.10),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Bouquet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF36594B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${flowers.length} bloom${flowers.length == 1 ? '' : 's'} arranged for today',
            style: const TextStyle(color: Color(0xFF5F7A70), fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFFFFF5EA).withValues(alpha: 0.75),
                    const Color(0xFFEAF5EE).withValues(alpha: 0.95),
                  ],
                ),
                border: Border.all(color: const Color(0xFFD9EADF)),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final bouquetHeight = (constraints.maxHeight * 0.97).clamp(0.0, 390.0);
                  final bouquetWidth = (constraints.maxWidth * 0.76).clamp(0.0, 340.0);

                  return Center(
                    child: SizedBox(
                      width: bouquetWidth,
                      height: bouquetHeight,
                      child: _BouquetStack(
                        flowers: flowers,
                        bouquetWidth: bouquetWidth,
                        bouquetHeight: bouquetHeight,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BouquetStack extends StatelessWidget {
  final List<EarnedFlower> flowers;
  final double bouquetWidth;
  final double bouquetHeight;

  const _BouquetStack({
    required this.flowers,
    required this.bouquetWidth,
    required this.bouquetHeight,
  });

  @override
  Widget build(BuildContext context) {
    const double paperAspect = 2296 / 1080;
    const double leavesAspect = 993 / 913;
    const double paperOpeningRatioY = 573 / 2296; // y-position of cone opening in paper.svg

    // Size paper by height first to avoid top-cropping that breaks opening alignment.
    final paperH = (bouquetHeight * 0.84).clamp(0.0, bouquetHeight);
    final paperW = (paperH / paperAspect).clamp(0.0, bouquetWidth);
    final paperLeft = (bouquetWidth - paperW) / 2;
    final paperTop = bouquetHeight - paperH;
    final coneOpeningY = paperTop + (paperH * paperOpeningRatioY);

    final renderedLeavesW = paperW * 1.20;
    final renderedLeavesH = (renderedLeavesW / leavesAspect) * 1.42;
    final leavesTopY = coneOpeningY - renderedLeavesH * 0.54;
    final leavesLeft = (bouquetWidth - renderedLeavesW) / 2;

    final originX = bouquetWidth / 2;
    final originY = leavesTopY + renderedLeavesH * 0.64;

    final placements = _buildPlacements(
      flowers,
      bouquetWidth,
      originX: originX,
      originY: originY,
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: bouquetWidth * 0.12,
          right: bouquetWidth * 0.12,
          bottom: 0,
          child: Container(
            height: 22,
            decoration: BoxDecoration(
              color: const Color(0xFFB8D5C6).withValues(alpha: 0.38),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
        Positioned(
          left: paperLeft,
          top: paperTop,
          width: paperW,
          height: paperH,
          child: SvgPicture.asset(
            'assets/flowers/paper.svg',
            fit: BoxFit.contain,
          ),
        ),
        Positioned(
          left: leavesLeft,
          top: leavesTopY,
          width: renderedLeavesW,
          height: renderedLeavesH,
          child: SvgPicture.asset(
            'assets/flowers/stemsleaves.svg',
            fit: BoxFit.contain,
          ),
        ),
        Positioned(
          left: leavesLeft - 2,
          top: leavesTopY + renderedLeavesH * 0.12,
          width: renderedLeavesW,
          height: renderedLeavesH,
          child: Opacity(
            opacity: 0.55,
            child: SvgPicture.asset(
              'assets/flowers/stemsleaves.svg',
              fit: BoxFit.contain,
            ),
          ),
        ),
        ..._sortedPlacements(placements).map((p) {
          return Positioned(
            left: p.dx - p.size / 2,
            top: p.dy - p.size / 2,
            width: p.size,
            height: p.size,
            child: Transform.rotate(
              angle: p.rotation,
              child: SvgPicture.asset(
                p.flower.assetPath,
                fit: BoxFit.contain,
              ),
            ),
          );
        }),
      ],
    );
  }

  List<_FlowerPlacement> _sortedPlacements(List<_FlowerPlacement> placements) {
    const order = {'MICRO': 0, 'SMALL': 1, 'MEDIUM': 2, 'EXCELLENT': 3};
    return [...placements]
      ..sort((a, b) => (order[a.flower.tier] ?? 0).compareTo(order[b.flower.tier] ?? 0));
  }
}
