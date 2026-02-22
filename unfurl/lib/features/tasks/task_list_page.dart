import 'package:flutter/material.dart';
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

class _TaskListPageState extends State<TaskListPage> {
  static const String _demoUserId = 'demo-user';
  final TaskProvider _provider = TaskProvider();
  List<Task> _tasks = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTasks();
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
    return Scaffold(
      appBar: AppBar(title: const Text("Today's Unfurl")),
      drawer: const AppDrawer(currentRoute: '/'),
      body: Container(
        decoration: const BoxDecoration(gradient: blossomBackground),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.fromLTRB(14, 8, 14, 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                color: Colors.white.withValues(alpha: 0.8),
                border: Border.all(color: const Color(0xFFD4E5DC)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hi flower friend',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Complete tasks, earn blooms, grow your garden.',
                    style: Theme.of(context).textTheme.bodyMedium,
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
                                  children: [
                                    const SizedBox(height: 140),
                                    Icon(
                                      Icons.local_florist_rounded,
                                      size: 54,
                                      color: blossomPink.withValues(alpha: 0.7),
                                    ),
                                    const SizedBox(height: 12),
                                    const Center(child: Text('No tasks yet.')),
                                  ],
                               )
                              : ListView.builder(
                                  padding: const EdgeInsets.fromLTRB(0, 10, 0, 96),
                                   itemCount: _tasks.length,
                                   itemBuilder: (context, index) {
                                     final task = _tasks[index];
                                     return TaskCard(
                                       task: task,
                                       onTap: task.isDone ? null : () => _openFocusForTask(task),
                                     );
                                   },
                                 ),
                         ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadTasks,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}

