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

    @override
    void dispose() {
      _controller.dispose();
      super.dispose();
    }

    Future<void> _send() async {
      final text = _controller.text.trim();
      if (text.isEmpty) return;

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
        final count = (res['tasks'] as List<dynamic>? ?? const []).length;
        setState(() {
          _status = ready
              ? 'Task list ready. Saved $count tasks. Go to Tasks screen and refresh.'
              : (res['reply']?.toString() ?? 'Agent replied.');
        });
      } catch (e) {
        setState(() {
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
                            'Tell Bouquet everything on your mind.',
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
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
    }
}

