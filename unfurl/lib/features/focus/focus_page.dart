import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:unfurl/features/tasks/task_provider.dart';
import 'package:unfurl/shared/theme.dart';
import 'package:unfurl/shared/widgets/app_drawer.dart';

class FocusSessionArgs {
  final String? taskId;
  final String taskName;
  final int? estimatedMinutes;

  const FocusSessionArgs({
    required this.taskId,
    required this.taskName,
    required this.estimatedMinutes,
  });
}

class FocusPage extends StatefulWidget {
  const FocusPage({super.key});

  @override
  State<FocusPage> createState() => _FocusPageState();
}

class _FocusPageState extends State<FocusPage> {
  static const String _demoUserId = 'demo-user';

  final TaskProvider _provider = TaskProvider();
  Timer? _timer;
  bool _running = false;
  bool _finishing = false;
  int _baseMinutes = 25;
  int _totalSeconds = 25 * 60;
  int _remainingSeconds = 25 * 60;
  Map<String, dynamic>? _awardResponse;
  bool _awardError = false;

  FocusSessionArgs? _args;
  bool _argsLoaded = false;
  bool _hydratingFromBackend = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_argsLoaded) return;
    final routeArgs = ModalRoute.of(context)?.settings.arguments;
    if (routeArgs is FocusSessionArgs) {
      _args = routeArgs;
      _baseMinutes = routeArgs.estimatedMinutes != null && routeArgs.estimatedMinutes! > 0
          ? routeArgs.estimatedMinutes!
          : 25;
      _totalSeconds = _baseMinutes * 60;
      _remainingSeconds = _totalSeconds;
      unawaited(_hydrateTimerFromBackend());
    }
    _argsLoaded = true;
  }

  @override
  void dispose() {
    if (_running) {
      unawaited(_pauseBackendTimerSilently());
    }
    _timer?.cancel();
    super.dispose();
  }

  double get _progress {
    if (_totalSeconds <= 0) return 0;
    return ((_totalSeconds - _remainingSeconds) / _totalSeconds).clamp(0.0, 1.0);
  }

  int get _elapsedSeconds => _totalSeconds - _remainingSeconds;

  int _asInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    return int.tryParse('${value ?? ''}') ?? fallback;
  }

  String _normalizeAwardFlowerFile(String raw) {
    var value = raw.trim();
    if (value.isEmpty) return '';
    value = value.replaceAll('\\', '/').split('/').last.trim();
    if (!value.toLowerCase().endsWith('.svg')) {
      value = '$value.svg';
    }

    // Keep award names compatible with current local asset filenames.
    const aliases = {
      'Judicious Jonquil.svg': 'Judicious Jonquuil.svg',
      'Persevering Pear.svg': 'Perservering Pear.svg',
      'Persevering Poppy.svg': 'Perservering Poppy.svg',
      'Productive Poinsettia.svg': 'Productive poinsettia.svg',
    };
    return aliases[value] ?? value;
  }

  String _formatClock(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _pauseBackendTimerSilently() async {
    final taskId = _args?.taskId;
    if (taskId == null || taskId.isEmpty) return;
    try {
      await _provider.pauseTaskTimer(taskId: taskId);
    } catch (_) {
      // best-effort on navigation away
    }
  }

  void _startLocalTicker() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!mounted) return;
      if (_remainingSeconds <= 1) {
        timer.cancel();
        setState(() {
          _remainingSeconds = 0;
          _running = false;
        });
        await _finishSession();
        return;
      }
      setState(() => _remainingSeconds -= 1);
    });
  }

  Future<void> _hydrateTimerFromBackend() async {
    if (_hydratingFromBackend) return;
    final taskId = _args?.taskId;
    if (taskId == null || taskId.isEmpty) return;

    _hydratingFromBackend = true;
    try {
      final task = await _provider.fetchTaskById(userId: _demoUserId, taskId: taskId);
      if (!mounted || task == null) return;

      final spentMinutes = _asInt(task['time_spent_minutes'], fallback: 0);
      final spentSecondsStored = _asInt(task['time_spent_seconds'], fallback: spentMinutes * 60);
      final isActive = task['is_active'] == true;
      final startedAtRaw = task['timer_started_at']?.toString();

      var spentSeconds = spentSecondsStored;
      if (isActive && startedAtRaw != null && startedAtRaw.isNotEmpty) {
        try {
          final startedAt = DateTime.parse(startedAtRaw);
          final now = DateTime.now().toUtc();
          final startedUtc = startedAt.toUtc();
          spentSeconds += now.difference(startedUtc).inSeconds.clamp(0, 86400 * 3);
        } catch (_) {
          // Keep accumulated minutes if timestamp format is unexpected.
        }
      }

      final remaining = (_totalSeconds - spentSeconds).clamp(0, _totalSeconds);
      setState(() {
        _remainingSeconds = remaining;
        _running = isActive && remaining > 0;
      });

      if (_running) {
        _startLocalTicker();
      }
    } catch (_) {
      // If fetch fails, continue with local initial timer.
    } finally {
      _hydratingFromBackend = false;
    }
  }

  Future<bool> _syncTimerStateWithBackend({required bool start}) async {
    final taskId = _args?.taskId;
    if (taskId == null || taskId.isEmpty) return true;

    try {
      if (start) {
        final isResume = _elapsedSeconds > 0;
        if (isResume) {
          await _provider.resumeTaskTimer(taskId: taskId);
        } else {
          await _provider.startTaskTimer(taskId: taskId);
        }
      } else {
        await _provider.pauseTaskTimer(taskId: taskId);
      }
      return true;
    } catch (e) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Timer sync failed: $e')),
      );
      return false;
    }
  }

  void _startOrPause() async {
    if (_finishing) return;
    if (_running) {
      final ok = await _syncTimerStateWithBackend(start: false);
      if (!ok) return;
      _timer?.cancel();
      setState(() => _running = false);
      return;
    }

    final ok = await _syncTimerStateWithBackend(start: true);
    if (!ok) return;

    setState(() {
      _running = true;
      _awardResponse = null;
      _awardError = false;
    });
    _startLocalTicker();
  }

  void _extendByFive() {
    if (_finishing) return;
    setState(() {
      _totalSeconds += 5 * 60;
      _remainingSeconds += 5 * 60;
    });
  }

  Future<void> _finishSession() async {
    final taskId = _args?.taskId;
    if (taskId == null || taskId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Focus session finished. No task selected for awarding.')),
      );
      return;
    }

    setState(() => _finishing = true);
    try {
      final actualMinutes = ((_elapsedSeconds) / 60).ceil().clamp(1, 720);
      final result = await _provider.completeTaskAndAward(
        taskId: taskId,
        userId: _demoUserId,
        actualTimeSpentMinutes: actualMinutes,
      );
      final award = (result['award'] as Map<String, dynamic>? ?? const {});
      setState(() {
        _awardResponse = Map<String, dynamic>.from(award);
        _awardError = false;
      });
      final flower = _normalizeAwardFlowerFile(award['selected_flower']?.toString() ?? '');
      final flowerDisplayName = flower.isEmpty ? 'Flower' : flower.replaceAll('.svg', '');
      final message = award['congrats_message']?.toString() ?? 'Great work.';
      final flowerAssetPath = flower.isEmpty ? null : 'assets/flowers/$flower';

      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            title: const Text('Unfurl Reward Earned'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (flowerAssetPath != null)
                  Container(
                    width: 110,
                    height: 110,
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F8F4),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFD6E8DF)),
                    ),
                    child: SvgPicture.asset(
                      flowerAssetPath,
                      fit: BoxFit.contain,
                      placeholderBuilder: (context) => const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                Text(
                  flowerDisplayName,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Back to tasks'),
              ),
            ],
          );
        },
      );
      if (!mounted) return;
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop(true);
      } else {
        Navigator.of(context).pushReplacementNamed('/');
      }
    } catch (e) {
      setState(() {
        _awardResponse = null;
        _awardError = true;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not complete/award: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _finishing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final taskName = _args?.taskName ?? 'General Focus Session';
    return Scaffold(
      appBar: AppBar(title: const Text('Unfurl Focus')),
      drawer: const AppDrawer(currentRoute: '/focus'),
      body: Container(
        decoration: const BoxDecoration(gradient: blossomBackground),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.84),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFD8E8E0)),
                    ),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: _AnimatedBloomGarden(
                            progress: _progress,
                            running: _running,
                            awardResponse: _awardResponse,
                            awardError: _awardError,
                          ),
                        ),
                        Positioned(
                          top: 16,
                          left: 16,
                          right: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.92),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFD8E8E0)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.task_alt_rounded, color: sageGreen, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    taskName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _formatClock(_remainingSeconds),
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          left: 16,
                          right: 16,
                          bottom: 16,
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7FBF8).withValues(alpha: 0.94),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFD6E8DF)),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color.fromRGBO(32, 56, 45, 0.08),
                                  blurRadius: 14,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                LinearProgressIndicator(
                                  value: _progress,
                                  minHeight: 10,
                                  backgroundColor: const Color(0xFFE6EEE9),
                                  color: sageGreen,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: (_running || _finishing) ? null : _finishSession,
                                        icon: const Icon(Icons.done_rounded),
                                        label: const Text('Finish now'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: const Color(0xFF35584A),
                                          side: const BorderSide(color: Color(0xFFBFD8CC)),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: _finishing ? null : _extendByFive,
                                        icon: const Icon(Icons.add_alarm_rounded),
                                        label: const Text('+5 min'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: const Color(0xFF35584A),
                                          side: const BorderSide(color: Color(0xFFBFD8CC)),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: _finishing ? null : _startOrPause,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF6FAF98),
                                      foregroundColor: Colors.white,
                                    ),
                                    icon: _finishing
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : Icon(
                                            _running
                                                ? Icons.pause_circle_filled_rounded
                                                : Icons.play_circle_fill_rounded,
                                          ),
                                    label: Text(
                                      _finishing
                                          ? 'Awarding flower...'
                                          : (_running ? 'Pause focus' : 'Start focus'),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedBloomGarden extends StatefulWidget {
  final double progress;
  final bool running;
  final Map<String, dynamic>? awardResponse;
  final bool awardError;

  const _AnimatedBloomGarden({
    required this.progress,
    required this.running,
    required this.awardResponse,
    required this.awardError,
  });

  @override
  State<_AnimatedBloomGarden> createState() => _AnimatedBloomGardenState();
}

class _AnimatedBloomGardenState extends State<_AnimatedBloomGarden>
    with SingleTickerProviderStateMixin {
  late final AnimationController _cloudController;

  @override
  void initState() {
    super.initState();
    _cloudController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    )..repeat();
  }

  @override
  void dispose() {
    _cloudController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _cloudController,
      builder: (context, _) {
        final t = _cloudController.value * 2 * math.pi;
        final leftCloudDx = 20 * math.sin(t);
        final rightCloudDx = 24 * math.sin(t + 1.2);
        return Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFFFFEDD5),
                      Colors.white,
                    ],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: const _GardenBackdrop(),
            ),
            Positioned(
              top: 46,
              left: 30 + leftCloudDx,
              child: _cloud(94, 0.84),
            ),
            Positioned(
              top: 88,
              right: 36 - rightCloudDx,
              child: _cloud(112, 0.80),
            ),
            // Keep the center clear for timer text and bee orbit.
            Positioned.fill(
              child: IgnorePointer(
                child: Center(
                  child: Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.72),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: _WanderingBee(
                  searching: widget.running && widget.awardResponse == null && !widget.awardError,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _cloud(double width, double opacity) {
    return IgnorePointer(
      child: Opacity(
        opacity: opacity,
        child: SizedBox(
          width: width,
          height: width * 0.46,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: width * 0.12,
                right: width * 0.14,
                bottom: 0,
                child: Container(
                  height: width * 0.22,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Positioned(
                left: width * 0.04,
                bottom: width * 0.08,
                child: Container(
                  width: width * 0.28,
                  height: width * 0.28,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                left: width * 0.24,
                bottom: width * 0.14,
                child: Container(
                  width: width * 0.34,
                  height: width * 0.34,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                right: width * 0.10,
                bottom: width * 0.10,
                child: Container(
                  width: width * 0.30,
                  height: width * 0.30,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
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

class _GardenBackdrop extends StatefulWidget {
  const _GardenBackdrop();

  @override
  State<_GardenBackdrop> createState() => _GardenBackdropState();
}

class _GardenBackdropState extends State<_GardenBackdrop>
    with TickerProviderStateMixin {
  late final AnimationController _leftSwayController;
  late final AnimationController _rightSwayController;

  @override
  void initState() {
    super.initState();
    _leftSwayController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _rightSwayController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _leftSwayController.dispose();
    _rightSwayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_leftSwayController, _rightSwayController]),
      builder: (context, _) {
        final leftSway = math.sin(_leftSwayController.value * 2 * math.pi) * 0.022;
        final rightSway = math.sin(_rightSwayController.value * 2 * math.pi) * 0.018;
        return Stack(
          children: [
            // Back layer: two leafy mounds that create a central dip/valley.
            Positioned(
              left: -36,
              bottom: -58,
              child: Opacity(
                opacity: 0.70,
                child: SvgPicture.asset(
                  'assets/flowers/stemsleaves.svg',
                  width: 300,
                  fit: BoxFit.contain,
                  colorFilter: const ColorFilter.mode(Color(0xFFDCFCE7), BlendMode.modulate),
                ),
              ),
            ),
            Positioned(
              right: -38,
              bottom: -62,
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.rotationY(math.pi),
                child: Opacity(
                  opacity: 0.70,
                  child: SvgPicture.asset(
                    'assets/flowers/stemsleaves.svg',
                    width: 286,
                    fit: BoxFit.contain,
                    colorFilter: const ColorFilter.mode(Color(0xFFDCFCE7), BlendMode.modulate),
                  ),
                ),
              ),
            ),
            // Soft cluster shadows.
            _clusterShadow(const Alignment(-0.48, 0.90), 230, 64),
            _clusterShadow(const Alignment(0.56, 0.92), 210, 56),

            // Left hero cluster (Front): Gerbera + Rose + Freesia.
            Align(
              alignment: const Alignment(-0.46, 0.84),
              child: Transform.rotate(
                angle: -0.03 + leftSway,
                child: SizedBox(
                  width: 352,
                  height: 252,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // stems
                      Positioned(
                        left: 34,
                        bottom: 0,
                        child: _stem(94, -0.10),
                      ),
                      Positioned(
                        left: 156,
                        bottom: 0,
                        child: _stem(108, 0.01),
                      ),
                      Positioned(
                        left: 286,
                        bottom: 2,
                        child: _stem(90, 0.10),
                      ),
                      Positioned(
                        left: 122,
                        bottom: 20,
                        child: _svgFlower('assets/flowers/Grand Gerbera.svg', 154, 1.0, const Color(0xFFFEF9C3)),
                      ),
                      Positioned(
                        left: -8,
                        bottom: 18,
                        child: _svgFlower('assets/flowers/Remarkable Rose.svg', 126, 1.0, const Color(0xFFFFEDD5)),
                      ),
                      Positioned(
                        left: 270,
                        bottom: 52,
                        child: _svgFlower('assets/flowers/Focused Freesia.svg', 80, 0.74, const Color(0xFFDCFCE7)),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Right support cluster (Front): Hydrangea + Gardenia, lower/smaller.
            Align(
              alignment: const Alignment(0.60, 0.88),
              child: Transform.rotate(
                angle: 0.04 - rightSway,
                child: SizedBox(
                  width: 312,
                  height: 220,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        right: 156,
                        bottom: 2,
                        child: _stem(100, -0.02),
                      ),
                      Positioned(
                        right: 16,
                        bottom: 6,
                        child: _stem(84, 0.12),
                      ),
                      Positioned(
                        right: 108,
                        bottom: 18,
                        child: _svgFlower('assets/flowers/Hardworking Hydrangea.svg', 126, 1.0, const Color(0xFFDCFCE7)),
                      ),
                      Positioned(
                        right: -6,
                        bottom: 30,
                        child: _svgFlower('assets/flowers/Growing Gardenia.svg', 86, 0.78, const Color(0xFFFFEDD5)),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Foreground leaf overlays so flowers tuck into greenery.
            Positioned(
              left: -28,
              bottom: -44,
              child: Opacity(
                opacity: 0.72,
                child: SvgPicture.asset(
                  'assets/flowers/stemsleaves.svg',
                  width: 220,
                  fit: BoxFit.contain,
                  colorFilter: const ColorFilter.mode(Color(0xFFDCFCE7), BlendMode.modulate),
                ),
              ),
            ),
            Positioned(
              right: -24,
              bottom: -46,
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.rotationY(math.pi),
                child: Opacity(
                  opacity: 0.70,
                  child: SvgPicture.asset(
                    'assets/flowers/stemsleaves.svg',
                    width: 204,
                    fit: BoxFit.contain,
                    colorFilter: const ColorFilter.mode(Color(0xFFDCFCE7), BlendMode.modulate),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _clusterShadow(Alignment alignment, double width, double height) {
    return Align(
      alignment: alignment,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.05),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _svgFlower(String asset, double width, double opacity, Color tint) {
    return Opacity(
      opacity: opacity,
      child: SvgPicture.asset(
        asset,
        width: width,
        fit: BoxFit.contain,
        colorFilter: ColorFilter.mode(
          tint,
          BlendMode.modulate,
        ),
      ),
    );
  }

  Widget _stem(double height, double angle) {
    return Transform.rotate(
      angle: angle,
      child: Container(
        width: 11,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFF92C7A0),
          borderRadius: BorderRadius.circular(999),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.05),
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
      ),
    );
  }
}
class _WanderingBee extends StatefulWidget {
  final bool searching;

  const _WanderingBee({required this.searching});

  @override
  State<_WanderingBee> createState() => _WanderingBeeState();
}

class _WanderingBeeState extends State<_WanderingBee> with SingleTickerProviderStateMixin {
  static const List<String> _lines = [
    'I am looking for a flower for you.',
    'You work hard, I will find the best one.',
    'Keep going, I am still searching!',
    'Almost there, stay focused!',
  ];

  int _lineIndex = 0;
  Timer? _lineTimer;
  late final AnimationController _wanderController;

  @override
  void initState() {
    super.initState();
    _wanderController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 28),
    )..repeat();
    _sync();
  }

  @override
  void didUpdateWidget(covariant _WanderingBee oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  @override
  void dispose() {
    _wanderController.dispose();
    _lineTimer?.cancel();
    super.dispose();
  }

  void _sync() {
    if (widget.searching) {
      _lineTimer ??= Timer.periodic(const Duration(seconds: 20), (_) {
        if (!mounted) return;
        setState(() {
          _lineIndex = (_lineIndex + 1) % _lines.length;
        });
      });
    } else {
      _lineTimer?.cancel();
      _lineTimer = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bubbleText = widget.searching ? _lines[_lineIndex] : 'Press Start Focus when ready.';

    return AnimatedBuilder(
      animation: _wanderController,
      builder: (context, _) {
        final t = _wanderController.value * 2 * math.pi;
        final alignment = widget.searching
            ? Alignment(
                0.58 + 0.18 * math.sin(t) + 0.06 * math.sin(2.2 * t),
                0.20 + 0.10 * math.cos(t) + 0.03 * math.sin(3.1 * t),
              )
            : Alignment(
                0.72,
                0.34 + 0.015 * math.sin(t * 1.2),
              );
        final tilt = widget.searching ? 0.01 * math.sin(t * 1.6) : 0.004 * math.sin(t * 1.2);

        return Align(
          alignment: alignment,
          child: Transform.rotate(
            angle: tilt,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  constraints: const BoxConstraints(maxWidth: 190),
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.94),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFD8E8E0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    bubbleText,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                Container(
                  width: 104,
                  height: 104,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.78),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFD8E8E0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.10),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/flowers/search_bee.png',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.emoji_nature_rounded,
                        color: sageGreen,
                        size: 50,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
