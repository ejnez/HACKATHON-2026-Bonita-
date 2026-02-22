import 'package:flutter/material.dart';
import 'package:unfurl/features/tasks/task_provider.dart';
import 'package:unfurl/shared/theme.dart';
import 'package:unfurl/shared/widgets/app_drawer.dart';

class ChatbotPage extends StatefulWidget {
  const ChatbotPage({super.key});

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
    static const String _demoUserId = 'demo-user';
    static const String _demoSessionId = 'demo-session';
    final TaskProvider _provider = TaskProvider();
    final TextEditingController _controller = TextEditingController();
    bool _loading = false;
    String _status = 'Paste your brain dump and press send.';
    List<Map<String, dynamic>> _generatedTasks = const [];

    @override
    void dispose() {
      _controller.dispose();
      super.dispose();
    }

    Future<void> _send() async {
      final text = _controller.text.trim();
      if (text.isEmpty) {
        setState(() {
          _status = 'Please type your brain dump first.';
        });
        return;
      }

      setState(() {
        _loading = true;
        _status = 'Sending...';
      });

      try {
        final res = await _provider.sendBrainDump(
          sessionId: _demoSessionId,
          userId: _demoUserId,
          message: text,
        );
        final ready = res['list_ready'] == true;
        final tasks = (res['tasks'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .toList(growable: false);
        final count = tasks.length;
        setState(() {
          _generatedTasks = ready ? tasks : const [];
          _status = ready
              ? 'Task list ready. Saved $count tasks.'
              : (res['reply']?.toString() ?? 'Agent replied.');
        });
      } catch (e) {
        setState(() {
          _generatedTasks = const [];
          _status = 'Request failed: $e';
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
            appBar: AppBar(
                title: const Text("Unload My Brain"),
            ),
            drawer: const AppDrawer(currentRoute: '/chatbot'),
            body: Container(
                decoration: const BoxDecoration(gradient: blossomBackground),
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 560),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.88),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFFFC9E0)),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.auto_awesome, size: 32, color: blossomPink),
                          const SizedBox(height: 8),
                          Text(
                            'Tell Unfurl everything on your mind.',
                            style: Theme.of(context).textTheme.titleMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _controller,
                            minLines: 5,
                            maxLines: 9,
                            decoration: const InputDecoration(
                              labelText: 'Brain dump',
                              hintText: 'Study chapter 4, reply to emails, clean room...',
                            ),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _loading ? null : _send,
                              icon: const Icon(Icons.send_rounded),
                              label: Text(_loading ? 'Sending...' : 'Send to AI'),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _status,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          if (_generatedTasks.isNotEmpty) ...[
                            const SizedBox(height: 14),
                            const Divider(),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Your task list',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ..._generatedTasks.map((task) {
                              final rank = task['priority_rank']?.toString() ?? '-';
                              final name = task['task_name']?.toString() ?? 'Untitled task';
                              final mins = task['estimated_time']?.toString() ?? '?';
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('$rank. '),
                                    Expanded(child: Text('$name ($mins min)')),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
    }
}

