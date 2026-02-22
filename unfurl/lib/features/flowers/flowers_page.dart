import 'package:flutter/material.dart';
import 'package:unfurl/features/tasks/task_provider.dart';
import 'package:unfurl/shared/theme.dart';
import 'package:unfurl/shared/widgets/app_drawer.dart';

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
  List<Map<String, dynamic>> _todayFlowers = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  int _asInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    return int.tryParse('${value ?? ''}') ?? fallback;
  }

  String _flowerNameFromAsset(String? assetPath) {
    final raw = (assetPath ?? '').trim();
    if (raw.isEmpty) return 'Flower';
    final noPrefix = raw.replaceFirst(RegExp(r'^assets/flowers/'), '');
    final noExt = noPrefix.replaceAll(
      RegExp(r'\.(svg|png|jpg|jpeg)$', caseSensitive: false),
      '',
    );
    return noExt.replaceAll('_', ' ').trim();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final bouquet = await _provider.fetchTodayBouquet(userId: _demoUserId);
      final streak = await _provider.fetchFlowerStreak(userId: _demoUserId);
      if (!mounted) return;
      setState(() {
        _todayFlowers = (bouquet['flowers'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .toList(growable: false);
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
                              Text(
                                "Today's Garden",
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Every completed task blooms into something beautiful.',
                              ),
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
                              const Icon(
                                Icons.local_fire_department_rounded,
                                color: sageGreen,
                              ),
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
                        const SizedBox(height: 12),
                        if (_todayFlowers.isEmpty)
                          Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFDBEAE2)),
                            ),
                            child: const Text('No flowers earned yet today.'),
                          ),
                        ..._todayFlowers.map(
                          (bloom) => Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFDBEAE2)),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.local_florist_rounded,
                                  size: 26,
                                  color: sageGreen,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _flowerNameFromAsset(
                                          bloom['flower_type_id']?.toString(),
                                        ),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        (bloom['tier'] ?? '').toString(),
                                        style: const TextStyle(
                                          color: Color(0xFF5B7568),
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.auto_awesome, color: blossomPink),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }
}
