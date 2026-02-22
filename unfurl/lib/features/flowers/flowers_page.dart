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
    return value.trim();
  }
}

class _FlowerPlacement {
  final EarnedFlower flower;
  final double x;
  final double y;
  final double size;
  final double rotation;

  const _FlowerPlacement({
    required this.flower,
    required this.x,
    required this.y,
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
  double originX,
  double originY,
) {
  final rng = Random(42);
  final placements = <_FlowerPlacement>[];

  double sizeForTier(String tier) {
    switch (tier.toUpperCase()) {
      case 'EXCELLENT':
        return bouquetWidth * 0.20;
      case 'MEDIUM':
        return bouquetWidth * 0.17;
      case 'SMALL':
        return bouquetWidth * 0.14;
      case 'MICRO':
      default:
        return bouquetWidth * 0.12;
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

    final radius = bouquetWidth * row.radiusFraction;
    final slots = row.slots;
    final count = min(flowers.length - index, slots);

    for (var i = 0; i < count; i++) {
      double angle;
      if (slots == 1) {
        angle = -pi / 2;
      } else {
        const arcSpread = pi * 0.85;
        final step = arcSpread / (slots - 1);
        final start = -pi / 2 - arcSpread / 2;
        final offset = (slots - count) / 2;
        angle = start + (i + offset) * step;
      }

      final jitter = bouquetWidth * 0.012;
      final x = originX + radius * cos(angle) + (rng.nextDouble() - 0.5) * jitter;
      final y = originY + radius * sin(angle) + (rng.nextDouble() - 0.5) * jitter;

      placements.add(
        _FlowerPlacement(
          flower: flowers[index],
          x: x,
          y: y,
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
    return Scaffold(
      appBar: AppBar(title: const Text('My Unfurl Garden')),
      drawer: const AppDrawer(currentRoute: '/flowers'),
      body: Container(
        decoration: const BoxDecoration(gradient: blossomBackground),
        child: _loading
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
                      padding: const EdgeInsets.all(16),
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: const Color(0xFFD7E7DE)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Today's Garden", style: Theme.of(context).textTheme.titleLarge),
                              const SizedBox(height: 6),
                              const Text('Every completed task blooms into something beautiful.'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: const Color(0xFFD6E7DE)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.local_fire_department_rounded, color: sageGreen),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Flower Streak: $_streakDays day${_streakDays == 1 ? '' : 's'}',
                                      style: Theme.of(context).textTheme.titleMedium,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _streakDays > 0
                                          ? 'Keep earning at least one flower daily to maintain it.'
                                          : 'Earn a flower today to start your streak.',
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_streakDays > 0)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: List.generate(
                                _streakDays.clamp(1, 21),
                                (_) => const Icon(
                                  Icons.local_florist_rounded,
                                  size: 18,
                                  color: sageGreen,
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 8),
                        if (_todayFlowers.isEmpty)
                          Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFDBEAE2)),
                            ),
                            child: const Text('No flowers earned yet today.'),
                          )
                        else
                          _BouquetCard(flowers: _todayFlowers),
                      ],
                    ),
                  ),
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
      height: 420,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFDBEAE2)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          final placements = _buildPlacements(
            flowers,
            width * 0.80,
            width * 0.50,
            height * 0.75,
          );

          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: width * 0.12,
                top: height * 0.62,
                width: width * 0.76,
                child: Opacity(
                  opacity: 0.95,
                  child: SvgPicture.asset(
                    'assets/flowers/paper.svg',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              ...placements.map(
                (p) => Positioned(
                  left: p.x - p.size / 2,
                  top: p.y - p.size / 2,
                  width: p.size,
                  height: p.size,
                  child: Transform.rotate(
                    angle: p.rotation,
                    child: SvgPicture.asset(
                      p.flower.assetPath,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
