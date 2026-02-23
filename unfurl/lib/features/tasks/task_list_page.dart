import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:unfurl/features/tasks/task_model.dart';
import 'package:unfurl/features/tasks/task_provider.dart';
import 'package:unfurl/features/tasks/widgets/task_card.dart';
import 'package:unfurl/features/focus/focus_page.dart';
import 'package:unfurl/shared/theme.dart';
import 'package:unfurl/shared/widgets/app_drawer.dart';
import 'package:unfurl/shared/widgets/focus_button.dart';
import 'package:unfurl/shared/widgets/color_cycle_button.dart';

class TaskListPage extends StatefulWidget {
  const TaskListPage({super.key});

  @override
  State<TaskListPage> createState() => _TaskListPageState();
}

class _TaskListPageState extends State<TaskListPage> with SingleTickerProviderStateMixin {
  static const String _demoUserId = 'demo-user';
  final TaskProvider _provider = TaskProvider();
  late final AnimationController _listIntroController;
  List<Task> _tasks = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _listIntroController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _loadTasks();
  }

  @override
  void dispose() {
    _listIntroController.dispose();
    super.dispose();
  }

  Future<void> _loadTasks() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final tasks = await _provider.fetchTasks(_demoUserId);
      setState(() {
        _tasks = tasks;
      });
      _listIntroController
        ..reset()
        ..forward();
    } catch (e) {
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

  Future<void> _openFocusForTask(Task task) async {
    if (task.isDone) return;
    await Navigator.pushNamed(
      context,
      '/focus',
      arguments: FocusSessionArgs(
        taskId: task.id,
        taskName: task.name,
        estimatedMinutes: task.estimatedMinutes,
      ),
    );
    if (mounted) {
      await _loadTasks();
    }
  }

  Future<void> _openChatbotAndRefresh() async {
    await Navigator.pushNamed(context, '/chatbot');
    if (mounted) {
      await _loadTasks();
    }
  }

  //build page UI code
  @override
  Widget build(BuildContext context) {
    final totalTasks = _tasks.length;
    final doneTasks = _tasks.where((t) => t.isDone).length;
    final completion = totalTasks == 0 ? 0.0 : doneTasks / totalTasks;

    return Scaffold(
      appBar: AppBar(title: const Text("Today's Unfurl")),
      drawer: const AppDrawer(currentRoute: '/'),
      body: Container(
        decoration: const BoxDecoration(gradient: blossomBackground),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                color: Colors.white.withValues(alpha: 0.85),
                border: Border.all(color: const Color(0xFFD4E5DC)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hi flower friend',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF2D3A2E),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Complete tasks, earn blooms, grow your garden.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 14),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF3D6B42).withValues(alpha: 0.22),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: SizedBox(
                        height: 10,
                        child: Stack(
                          children: [
                            Container(color: const Color(0xFFE4ECE5)),
                            FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: completion,
                              child: Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Color(0xFF3D6B42), Color(0xFF7A9E7E)],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _inlineStat(
                          label: 'Tasks',
                          value: '$totalTasks',
                          bg: const Color(0xFFE8F3EC),
                          fg: const Color(0xFF3D6B42),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _inlineStat(
                          label: 'Done',
                          value: '$doneTasks',
                          bg: const Color(0xFFF7EED7),
                          fg: const Color(0xFF8C6E23),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF4F1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFD9E6DE)),
                        ),
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(color: Color(0xFF50645A)),
                            children: [
                              const TextSpan(
                                text: 'Progress ',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              TextSpan(
                                text: '${(completion * 100).round()}%',
                                style: const TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF3D6B42),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: FocusButton(
                          text: "Focus Mode",
                          onPressed: () => Navigator.pushNamed(context, '/focus'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ColorCycleButton(
                          text: "Unload Brain",
                          onPressed: _openChatbotAndRefresh,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
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
                          onRefresh: _loadTasks,
                          child: _tasks.isEmpty
                              ? ListView(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  children: [
                                    const SizedBox(height: 140),
                                    Icon(
                                      Icons.local_florist_rounded,
                                      size: 58,
                                      color: blossomPink.withValues(alpha: 0.7),
                                    ),
                                    const SizedBox(height: 12),
                                    Center(
                                      child: Text(
                                        'No tasks yet. Use "Unload Brain" to generate your first list.',
                                        textAlign: TextAlign.center,
                                        style: Theme.of(context).textTheme.bodyLarge,
                                      ),
                                    ),
                                  ],
                               )
                              : ListView.builder(
                                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 96),
                                   itemCount: _tasks.length,
                                   itemBuilder: (context, index) {
                                     final task = _tasks[index];
                                     return _StaggeredTaskItem(
                                       controller: _listIntroController,
                                       index: index,
                                       child: Padding(
                                         padding: EdgeInsets.only(bottom: index == _tasks.length - 1 ? 0 : 12),
                                         child: TaskCard(
                                           task: task,
                                           onTap: task.isDone ? null : () => _openFocusForTask(task),
                                         ),
                                       ),
                                     );
                                   },
                                 ),
                         ),
            ),
          ],
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF3D6B42), Color(0xFF7A9E7E)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF3D6B42).withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: _loadTasks,
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.refresh, color: Colors.white),
        ),
      ),
    );
  }

  Widget _inlineStat({
    required String label,
    required String value,
    required Color bg,
    required Color fg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: fg.withValues(alpha: 0.9),
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _StaggeredTaskItem extends StatelessWidget {
  final AnimationController controller;
  final int index;
  final Widget child;

  const _StaggeredTaskItem({
    required this.controller,
    required this.index,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final begin = (index * 0.10).clamp(0.0, 0.9);
    final end = (begin + 0.32).clamp(begin + 0.01, 1.0);
    final animation = CurvedAnimation(
      parent: controller,
      curve: Interval(begin, end, curve: Curves.easeOutCubic),
    );
    final slide = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(animation);
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(position: slide, child: child),
    );
  }
}

